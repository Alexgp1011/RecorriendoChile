
extends AnimatedSprite3D

# ==========================================
# REY PALOMO - CONTROLADOR DE ANIMACIONES
# No modifica combate, fisicas ni misiones
# ==========================================

@export var duracion_hurt: float = 0.45

@onready var jefe: Node3D = (
	get_parent() as Node3D
)

var vida_anterior: int = -1
var tiempo_hurt: float = 0.0
var animacion_muerte_creada: bool = false


# ==========================================
# INICIAR CONTROLADOR
# ==========================================

func _ready() -> void:

	if jefe == null:

		push_error(
            "REY PALOMO: Debe ser hijo de DonPalomo"
		)

		set_process(false)
		return

	if sprite_frames == null:

		push_error(
            "REY PALOMO: Faltan los SpriteFrames"
		)

		set_process(false)
		return

	vida_anterior = int(
		jefe.get("vida_actual")
	)

	# La esfera original solo se oculta
	# visualmente. Conservamos su colision.
	var malla: MeshInstance3D = (
		jefe.get_node_or_null(
            "MeshInstance3D"
		) as MeshInstance3D
	)

	if malla != null:

		malla.hide()

	# Asegurar animaciones de una sola vez
	if sprite_frames.has_animation("hurt"):

		sprite_frames.set_animation_loop(
			"hurt",
			false
		)

	if sprite_frames.has_animation("death"):

		sprite_frames.set_animation_loop(
			"death",
			false
		)

	reproducir_animacion("idle")

	print(
        "REY PALOMO: Controlador visual conectado"
	)


# ==========================================
# REVISAR ESTADO DEL JEFE
# ==========================================

func _process(delta: float) -> void:

	if not is_instance_valid(jefe):
		return

	# ======================================
	# MUERTE DEL JEFE
	# ======================================

	if jefe.get("derrotado") == true:

		if not animacion_muerte_creada:

			animacion_muerte_creada = true

			crear_animacion_muerte()

		return

	# ======================================
	# DETECTAR DISPAROS
	# ======================================

	var vida_actual: int = int(
		jefe.get("vida_actual")
	)

	if vida_actual < vida_anterior:

		tiempo_hurt = maxf(
			duracion_hurt,
			0.1
		)

		reproducir_animacion("hurt")

		# Reiniciar desde el primer frame
		frame = 0

		print(
            "REY PALOMO: Animacion HURT"
		)

	vida_anterior = vida_actual

	# ======================================
	# COMBATE INACTIVO
	# ======================================

	if jefe.get("combate_activo") != true:
		return

	# ======================================
	# PRIORIDAD DE ANIMACION HURT
	# ======================================

	if tiempo_hurt > 0.0:

		tiempo_hurt -= delta
		return

	# ======================================
	# ANIMACION SEGUN ESTADO
	# ======================================

	var estado: int = int(
		jefe.get("estado_actual")
	)

	match estado:

		# HACIA_CRUZ
		# VOLANDO
		# AVISO_PICADA
		# EN_PICADA
		1, 3, 7, 8:

			reproducir_animacion("fly")

		# RAFAGA_NORMAL
		# LLUVIA_MASIVA
		4, 5:

			reproducir_animacion("attack")

		# SOBRE_CRUZ
		# VULNERABLE
		2, 6:

			reproducir_animacion("idle")

		_:

			reproducir_animacion("idle")


# ==========================================
# REPRODUCIR ANIMACIONES
# ==========================================

func reproducir_animacion(
	nombre: StringName
) -> void:

	if sprite_frames == null:
		return

	if not sprite_frames.has_animation(
		nombre
	):

		return

	# Evitar reiniciar cada fotograma
	if animation != nombre:

		play(nombre)

	elif not is_playing():

		# Las animaciones en bucle pueden
		# reanudarse si quedaron detenidas.
		if sprite_frames.get_animation_loop(
			nombre
		):

			play(nombre)


# ==========================================
# CREAR ANIMACION DE MUERTE
# ==========================================

func crear_animacion_muerte() -> void:

	if sprite_frames == null:
		return

	if not sprite_frames.has_animation(
        "death"
	):

		return

	var escena: Node = (
		get_tree().current_scene
	)

	if escena == null:
		return

	# DonPalomo se oculta inmediatamente
	# al perder toda su salud.
	# Creamos una copia visual independiente
	# para poder mostrar su muerte.

	var visual_muerte: AnimatedSprite3D = (
		AnimatedSprite3D.new()
	)

	visual_muerte.name = (
        "MuerteReyPalomo"
	)

	visual_muerte.sprite_frames = sprite_frames

	# Copiar configuracion visual
	visual_muerte.pixel_size = pixel_size
	visual_muerte.billboard = billboard
	visual_muerte.texture_filter = texture_filter
	visual_muerte.alpha_cut = alpha_cut
	visual_muerte.shaded = shaded
	visual_muerte.centered = centered
	visual_muerte.offset = offset
	visual_muerte.modulate = modulate
	visual_muerte.axis = axis

	escena.add_child(
		visual_muerte
	)

	# Mantener la posicion exacta
	# donde Don Palomo fue derrotado.
	visual_muerte.global_transform = (
		global_transform
	)

	visual_muerte.play("death")

	print(
        "REY PALOMO: Animacion DEATH"
	)

	# Eliminar solo la copia visual cuando
	# termine la animacion.
	visual_muerte.animation_finished.connect(
		visual_muerte.queue_free,
		CONNECT_ONE_SHOT
	)

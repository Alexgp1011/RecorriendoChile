
extends AnimatedSprite3D

# ==========================================
# REFERENCIAS
# ==========================================

@onready var policia: CharacterBody3D = get_parent() as CharacterBody3D


# ==========================================
# INICIAR ANIMACIONES
# ==========================================

func _ready() -> void:

	if policia == null:
		push_error("AnimatedSprite3D debe ser hijo de Policia")
		set_process(false)
		return

	if sprite_frames == null:
		push_error("Falta configurar SpriteFrames")
		set_process(false)
		return

	# Comprobar las animaciones
	for nombre in [&"idle", &"walk", &"chase", &"arrest"]:

		if not sprite_frames.has_animation(nombre):
			push_error("Falta la animacion: " + str(nombre))
			set_process(false)
			return

	# La detencion no debe repetirse
	sprite_frames.set_animation_loop(&"arrest", false)

	play(&"idle")


# ==========================================
# ACTUALIZAR ANIMACIONES
# ==========================================

func _process(_delta: float) -> void:

	if not is_instance_valid(policia):
		return

	# Leer el estado actual de policia.gd
	var estado: int = int(policia.get("estado_actual"))

	var nueva_animacion: StringName = &"idle"

	# ======================================
	# ESTADO 0: PATRULLA
	# ======================================

	if estado == 0:

		var velocidad_horizontal: float = Vector2(
			policia.velocity.x,
			policia.velocity.z
		).length_squared()

		if velocidad_horizontal > 0.01:
			nueva_animacion = &"walk"
		else:
			nueva_animacion = &"idle"

	# ======================================
	# ESTADO 1: ALERTA
	# ======================================

	elif estado == 1:
		nueva_animacion = &"idle"

	# ======================================
	# ESTADO 2: PERSECUCION
	# ======================================

	elif estado == 2:
		nueva_animacion = &"chase"

	# ======================================
	# ESTADO 3: DETENCION
	# ======================================

	elif estado == 3:
		nueva_animacion = &"arrest"

	# ======================================
	# REPRODUCIR ANIMACION
	# ======================================

	if animation != nueva_animacion:
		play(nueva_animacion)

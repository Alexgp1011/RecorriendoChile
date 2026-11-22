
extends CharacterBody3D

# ==========================================
# PALOMA PEQUENA - PLAZA DE ARMAS
# PERSECUCION, PICOTAZO Y MUERTE
# ==========================================

@export var vida_maxima: int = 2
@export var velocidad_vuelo: float = 5.0

@export var altura_sobre_jugador: float = 1.2
@export var radio_orbita: float = 0.6

@export var rango_ataque: float = 2.0
@export var dano_picotazo: int = 8
@export var intervalo_ataque: float = 1.8

@export var radio_maximo_arena: float = 23.0


# ==========================================
# REFERENCIAS
# ==========================================

@onready var colision: CollisionShape3D = (
	$CollisionShape3D
)

@onready var visual: MeshInstance3D = (
	$MeshInstance3D
)

# Sprite opcional para cuando preparemos
# las animaciones definitivas.
@onready var sprite: AnimatedSprite3D = (
	get_node_or_null("AnimatedSprite3D")
	as AnimatedSprite3D
)


# ==========================================
# VARIABLES
# ==========================================

var jugador: CharacterBody3D = null

var centro_arena: Vector3 = Vector3.ZERO
var arena_configurada: bool = false

var vida_actual: int = 2
var muerto: bool = false

var tiempo_vuelo: float = 0.0
var reloj_ataque: float = 0.8

var angulo_orbita: float = 0.0


# ==========================================
# INICIAR PALOMA
# ==========================================

func _ready() -> void:

	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

	add_to_group("palomas_pequenas")

	vida_actual = maxi(vida_maxima, 1)

	buscar_jugador()

	angulo_orbita = randf_range(
		0.0,
		TAU
	)

	preparar_visual()

	print("PALOMA PEQUENA: Aparecio")


# ==========================================
# CONFIGURAR DESDE EL INVOCADOR
# ==========================================

func configurar(
	objetivo: CharacterBody3D,
	centro: Vector3
) -> void:

	jugador = objetivo
	centro_arena = centro

	arena_configurada = true


# ==========================================
# BUSCAR JUGADOR
# ==========================================

func buscar_jugador() -> void:

	var encontrado: Node = (
		get_tree().get_first_node_in_group("jugador")
	)

	if encontrado == null:

		encontrado = (
			get_tree().get_first_node_in_group("player")
		)

	if encontrado == null:

		encontrado = (
			get_tree().get_first_node_in_group("Player")
		)

	jugador = encontrado as CharacterBody3D


# ==========================================
# PREPARAR APARIENCIA
# ==========================================

func preparar_visual() -> void:

	# Si mas adelante agregamos AnimatedSprite3D,
	# utilizaremos sus animaciones.
	if sprite != null:

		if sprite.sprite_frames != null:

			visual.hide()
			sprite.show()

			reproducir_animacion("fly")
			return

	# Aspecto provisional gris
	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)

	material.albedo_color = Color(
		0.65,
		0.69,
		0.72
	)

	material.roughness = 1.0

	visual.material_override = material


# ==========================================
# MOVIMIENTO PRINCIPAL
# ==========================================

func _physics_process(delta: float) -> void:

	if muerto:
		return

	if not is_instance_valid(jugador):

		buscar_jugador()

	if not is_instance_valid(jugador):

		velocity = Vector3.ZERO
		return

	if jugador.get("dead") == true:

		velocity = Vector3.ZERO
		return

	# No atacar mientras el protagonista
	# esta usando una tienda o Pepito.
	if jugador.process_mode == Node.PROCESS_MODE_DISABLED:

		velocity = Vector3.ZERO
		return

	tiempo_vuelo += delta

	reloj_ataque = maxf(
		reloj_ataque - delta,
		0.0
	)

	# Evitar perseguir fuera de la plaza
	if arena_configurada:

		var distancia_arena: Vector3 = (
			jugador.global_position - centro_arena
		)

		distancia_arena.y = 0.0

		if distancia_arena.length() > radio_maximo_arena:

			regresar_a_la_plaza()
			move_and_slide()
			return

	perseguir_jugador()

	move_and_slide()

	comprobar_ataque()


# ==========================================
# PERSEGUIR VOLANDO
# ==========================================

func perseguir_jugador() -> void:

	# Movimiento lateral suave para que
	# no vuele en linea perfectamente recta.
	var angulo: float = (
		tiempo_vuelo * 1.8 + angulo_orbita
	)

	var desplazamiento: Vector3 = Vector3(
		cos(angulo) * radio_orbita,
		sin(tiempo_vuelo * 3.0) * 0.2,
		sin(angulo) * radio_orbita
	)

	var destino: Vector3 = (
		jugador.global_position
		+ Vector3.UP * altura_sobre_jugador
		+ desplazamiento
	)

	mover_hacia(destino)


# ==========================================
# REGRESAR SI SALE DE LA PLAZA
# ==========================================

func regresar_a_la_plaza() -> void:

	var destino: Vector3 = (
		centro_arena + Vector3.UP * 2.0
	)

	mover_hacia(destino)


# ==========================================
# MOVIMIENTO FISICO
# ==========================================

func mover_hacia(destino: Vector3) -> void:

	var direccion: Vector3 = (
		destino - global_position
	)

	if direccion.length() <= 0.12:

		velocity = Vector3.ZERO
		return

	velocity = (
		direccion.normalized()
		* velocidad_vuelo
	)


# ==========================================
# COMPROBAR PICOTAZO
# ==========================================

func comprobar_ataque() -> void:

	if reloj_ataque > 0.0:
		return

	if not is_instance_valid(jugador):
		return

	var posicion_objetivo: Vector3 = (
		jugador.global_position + Vector3.UP
	)

	var distancia: float = (
		global_position.distance_to(
			posicion_objetivo
		)
	)

	if distancia > rango_ataque:
		return

	aplicar_picotazo()


# ==========================================
# HACER DANO AL JUGADOR
# ==========================================

func aplicar_picotazo() -> void:

	# Reiniciar antes de aplicar dano,
	# para evitar varios golpes seguidos.
	reloj_ataque = maxf(
		intervalo_ataque,
		0.2
	)

	reproducir_animacion("attack")

	var salud: Node = (
		jugador.get_node_or_null("Salud")
	)

	if salud != null:

		if salud.has_method("recibir_dano"):

			salud.call(
				"recibir_dano",
				dano_picotazo
			)

			print(
				"PALOMA PEQUENA: Picotazo de ",
				dano_picotazo,
                " puntos"
			)

	# Mantener el movimiento despues
	# del ataque.
	reproducir_animacion("fly")


# ==========================================
# ANIMACIONES OPCIONALES
# ==========================================

func reproducir_animacion(
	nombre: String
) -> void:

	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(
		nombre
	):

		return

	if sprite.animation != nombre:

		sprite.play(nombre)

	elif not sprite.is_playing():

		sprite.play(nombre)


# ==========================================
# RECIBIR DISPAROS DEL JUGADOR
# ==========================================

func kill() -> void:

	if muerto:
		return

	vida_actual = maxi(
		vida_actual - 1,
		0
	)

	print(
		"PALOMA PEQUENA: Vida ",
		vida_actual,
		"/",
		vida_maxima
	)

	if vida_actual <= 0:

		morir()
		return

	# Pequeña reaccion visual
	if visual.visible:

		visual.scale = Vector3(
			1.2,
			1.2,
			1.2
		)

		var tween: Tween = create_tween()

		tween.tween_property(
			visual,
			"scale",
			Vector3.ONE,
			0.18
		)


# ==========================================
# MORIR
# ==========================================

func morir() -> void:

	if muerto:
		return

	muerto = true

	velocity = Vector3.ZERO

	# Ya no cuenta entre las palomas activas
	remove_from_group("palomas_pequenas")

	collision_layer = 0
	collision_mask = 0

	colision.set_deferred(
		"disabled",
		true
	)

	set_physics_process(false)

	if sprite != null:

		if sprite.sprite_frames != null:

			if sprite.sprite_frames.has_animation(
                "death"
			):

				sprite.play("death")

				await get_tree().create_timer(
					0.5
				).timeout

				if is_inside_tree():

					queue_free()

				return

	queue_free()


# ==========================================
# DESAPARECER AL TERMINAR EL COMBATE
# ==========================================

func desaparecer() -> void:

	if muerto:
		return

	muerto = true

	remove_from_group("palomas_pequenas")

	queue_free()

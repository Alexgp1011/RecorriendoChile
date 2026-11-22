
extends CharacterBody3D

# ==========================================
# CONFIGURACION
# ==========================================

@export var velocidad_patrulla: float = 1.2
@export var distancia_patrulla: float = 4.0
@export var velocidad_persecucion: float = 3.0
@export var distancia_detencion: float = 1.5
@export var distancia_ataque: float = 1.9
@export var intervalo_ataque: float = 1.5
@export var dano_golpe: int = 20

# ==========================================
# REFERENCIAS
# ==========================================

@onready var area_deteccion: Area3D = $AreaDeteccion
@onready var animacion: AnimatedSprite3D = $AnimatedSprite3D

# ==========================================
# VARIABLES
# ==========================================

var jugador: CharacterBody3D = null
var persiguiendo: bool = false
var atacando: bool = false
var golpe_aplicado: bool = false
var tiempo_ataque: float = 0.0

var punto_a: Vector3 = Vector3.ZERO
var punto_b: Vector3 = Vector3.ZERO
var hacia_b: bool = true

var gravedad: float = float(
	ProjectSettings.get_setting("physics/3d/default_gravity")
)


# ==========================================
# INICIAR MANIFESTANTE
# ==========================================

func _ready() -> void:

	punto_a = global_position

	punto_b = (
		global_position + Vector3(distancia_patrulla, 0.0, 0.0)
	)

	area_deteccion.monitoring = true

	if animacion.sprite_frames == null:
		push_error("Falta SpriteFrames en AnimatedSprite3D")
		set_physics_process(false)
		return

	for nombre in [&"idle", &"walk", &"chase", &"punch"]:
		if not animacion.sprite_frames.has_animation(nombre):
			push_error("Falta la animacion: " + str(nombre))
			set_physics_process(false)
			return

	animacion.sprite_frames.set_animation_loop(&"punch", false)

	animacion.frame_changed.connect(al_cambiar_frame)
	animacion.animation_finished.connect(al_terminar_animacion)

	animacion.play(&"idle")


# ==========================================
# MOVIMIENTO PRINCIPAL
# ==========================================

func _physics_process(delta: float) -> void:

	actualizar_deteccion()

	tiempo_ataque = maxf(tiempo_ataque - delta, 0.0)

	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravedad * delta
	else:
		velocity.y = 0.0

	# Comprobar si debe perseguir al jugador
	var debe_perseguir: bool = (
		is_instance_valid(jugador)
		and not EstadoJuego.cartel_visible
	)

	if debe_perseguir != persiguiendo:

		persiguiendo = debe_perseguir

		if persiguiendo:
			print("MANIFESTANTE: Persiguiendo")
		else:
			print("MANIFESTANTE: Patrullando")

	# Cancelar golpe si el jugador levanta el cartel
	if not persiguiendo and atacando:
		atacando = false
		golpe_aplicado = false

	# Decidir comportamiento
	if atacando:
		detener_movimiento()

	elif persiguiendo:
		perseguir_jugador()

	else:
		patrullar()

	# Aplicar movimiento
	move_and_slide()

	# Intentar golpear
	if persiguiendo and not atacando:
		intentar_atacar()

	# Actualizar sprites
	actualizar_animacion()


# ==========================================
# DETECTAR AL JUGADOR
# ==========================================

func actualizar_deteccion() -> void:

	var encontrado: CharacterBody3D = null

	for cuerpo in area_deteccion.get_overlapping_bodies():

		if cuerpo is CharacterBody3D and cuerpo.is_in_group("jugador"):

			encontrado = cuerpo as CharacterBody3D
			break

	jugador = encontrado


# ==========================================
# PATRULLAR LA CALLE
# ==========================================

func patrullar() -> void:

	var destino: Vector3 = punto_b if hacia_b else punto_a

	mover_hacia(
		destino,
		velocidad_patrulla,
		0.35
	)

	# Cambiar direccion al llegar al destino
	if distancia_horizontal(destino) <= 0.35:
		hacia_b = not hacia_b


# ==========================================
# PERSEGUIR AL JUGADOR
# ==========================================

func perseguir_jugador() -> void:

	if not is_instance_valid(jugador):
		detener_movimiento()
		return

	mover_hacia(
		jugador.global_position,
		velocidad_persecucion,
		distancia_detencion
	)


# ==========================================
# INICIAR ATAQUE
# ==========================================

func intentar_atacar() -> void:

	if not is_instance_valid(jugador):
		return

	if tiempo_ataque > 0.0:
		return

	if distancia_horizontal(jugador.global_position) > distancia_ataque:
		return

	# Preparar golpe
	tiempo_ataque = intervalo_ataque

	atacando = true
	golpe_aplicado = false

	detener_movimiento()

	# Reproducir animacion de golpe
	animacion.play(&"punch")


# ==========================================
# APLICAR DANO DURANTE LA ANIMACION
# ==========================================

func al_cambiar_frame() -> void:

	if not atacando or golpe_aplicado:
		return

	# El tercer frame representa el impacto
	if animacion.animation != &"punch" or animacion.frame != 2:
		return

	golpe_aplicado = true

	# Comprobar jugador
	if not persiguiendo or not is_instance_valid(jugador):
		return

	# El cartel protege al protagonista
	if EstadoJuego.cartel_visible:
		return

	# Comprobar distancia
	if distancia_horizontal(jugador.global_position) > distancia_ataque:
		return

	# Buscar sistema de salud
	var salud: Node = jugador.get_node_or_null("Salud")

	if salud != null and salud.has_method("recibir_dano"):

		salud.call("recibir_dano", dano_golpe)

		print("MANIFESTANTE: Golpe al jugador")

	else:
		push_warning("No se encontro Salud dentro de Player")


# ==========================================
# FINALIZAR ANIMACION DE GOLPE
# ==========================================

func al_terminar_animacion() -> void:

	if animacion.animation == &"punch":

		atacando = false
		golpe_aplicado = false

		actualizar_animacion()


# ==========================================
# ACTUALIZAR ANIMACIONES
# ==========================================

func actualizar_animacion() -> void:

	if atacando:
		return

	var moviendose: bool = (
		Vector2(velocity.x, velocity.z).length_squared() > 0.01
	)

	var nombre: StringName = &"idle"

	# Seleccionar animacion correspondiente
	if moviendose:

		if persiguiendo:
			nombre = &"chase"
		else:
			nombre = &"walk"

	if animacion.animation != nombre or not animacion.is_playing():
		animacion.play(nombre)


# ==========================================
# MOVER HACIA UNA POSICION
# ==========================================

func mover_hacia(
	destino: Vector3,
	rapidez: float,
	distancia_minima: float
) -> void:

	var direccion: Vector3 = destino - global_position

	direccion.y = 0.0

	if direccion.length() <= distancia_minima:

		detener_movimiento()
		return

	direccion = direccion.normalized()

	velocity.x = direccion.x * rapidez
	velocity.z = direccion.z * rapidez


# ==========================================
# DETENER MOVIMIENTO
# ==========================================

func detener_movimiento() -> void:

	velocity.x = 0.0
	velocity.z = 0.0


# ==========================================
# CALCULAR DISTANCIA HORIZONTAL
# ==========================================

func distancia_horizontal(destino: Vector3) -> float:

	var diferencia: Vector3 = destino - global_position

	diferencia.y = 0.0

	return diferencia.length()

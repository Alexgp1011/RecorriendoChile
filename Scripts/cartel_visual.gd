
extends Control

# ==========================================
# CONFIGURACION DEL CARTEL
# ==========================================

@export var escala_cartel: float = 0.65
@export var margen_inferior: float = 60.0
@export var tiempo_subida: float = 0.35
@export var tiempo_bajada: float = 0.25

# ==========================================
# NODOS
# ==========================================

@onready var cartel_sprite: Sprite2D = $CartelSprite
@onready var arma: CanvasItem = get_node_or_null(
    "../Gunbase"
) as CanvasItem

# ==========================================
# VARIABLES
# ==========================================

var cartel_arriba: bool = false
var arma_visible_antes: bool = true

var tween_movimiento: Tween
var tween_balanceo: Tween


# ==========================================
# INICIAR
# ==========================================

func _ready() -> void:

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	cartel_sprite.scale = Vector2.ONE * escala_cartel
	cartel_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cartel_sprite.visible = false

	resized.connect(actualizar_posicion)

	cartel_arriba = (
		EstadoJuego.cartel_visible
		and EstadoJuego.carteles_recogidos > 0
	)

	if cartel_arriba:
		levantar_cartel(true)
	else:
		cartel_sprite.position = posicion_oculta()


# ==========================================
# DETECTAR SI LEVANTAMOS O GUARDAMOS
# ==========================================

func _process(_delta: float) -> void:

	var nuevo_estado: bool = (
		EstadoJuego.cartel_visible
		and EstadoJuego.carteles_recogidos > 0
	)

	if nuevo_estado == cartel_arriba:
		return

	if nuevo_estado:
		levantar_cartel(false)
	else:
		guardar_cartel()


# ==========================================
# CALCULAR POSICIONES
# ==========================================

func posicion_visible() -> Vector2:

	return Vector2(
		size.x * 0.5,
		size.y - margen_inferior
	)


func posicion_oculta() -> Vector2:

	return posicion_visible() + Vector2(0, 450)


# ==========================================
# LEVANTAR CARTEL
# ==========================================

func levantar_cartel(inmediato: bool = false) -> void:

	detener_animaciones()

	# Guardar si el arma estaba visible
	if not cartel_sprite.visible and arma != null:
		arma_visible_antes = arma.visible

	cartel_arriba = true

	# Ocultar arma mientras mostramos el cartel
	if arma != null:
		arma.visible = false

	cartel_sprite.visible = true
	cartel_sprite.rotation_degrees = 0.0

	if inmediato:
		cartel_sprite.position = posicion_visible()
		iniciar_balanceo()
		return

	cartel_sprite.position = posicion_oculta()

	# Animar el cartel subiendo
	tween_movimiento = create_tween()

	tween_movimiento.tween_property(
		cartel_sprite,
		"position",
		posicion_visible(),
		tiempo_subida
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween_movimiento.finished.connect(iniciar_balanceo)


# ==========================================
# MANTENER CARTEL CON MOVIMIENTO SUAVE
# ==========================================

func iniciar_balanceo() -> void:

	if not cartel_arriba:
		return

	tween_balanceo = create_tween()
	tween_balanceo.set_loops()

	tween_balanceo.tween_property(
		cartel_sprite,
		"rotation_degrees",
		-1.2,
		0.65
	).set_trans(Tween.TRANS_SINE)

	tween_balanceo.tween_property(
		cartel_sprite,
		"rotation_degrees",
		1.2,
		0.65
	).set_trans(Tween.TRANS_SINE)


# ==========================================
# GUARDAR CARTEL
# ==========================================

func guardar_cartel() -> void:

	cartel_arriba = false

	detener_animaciones()

	cartel_sprite.rotation_degrees = 0.0

	# Animar el cartel hacia abajo
	tween_movimiento = create_tween()

	tween_movimiento.tween_property(
		cartel_sprite,
		"position",
		posicion_oculta(),
		tiempo_bajada
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween_movimiento.finished.connect(finalizar_guardado)


# ==========================================
# FINALIZAR GUARDADO
# ==========================================

func finalizar_guardado() -> void:

	if cartel_arriba:
		return

	cartel_sprite.visible = false

	# Volver a mostrar el arma
	if arma != null:
		arma.visible = arma_visible_antes


# ==========================================
# DETENER ANIMACIONES ANTERIORES
# ==========================================

func detener_animaciones() -> void:

	if tween_movimiento != null:
		if tween_movimiento.is_valid():
			tween_movimiento.kill()

	if tween_balanceo != null:
		if tween_balanceo.is_valid():
			tween_balanceo.kill()


# ==========================================
# AJUSTAR AL TAMANO DE PANTALLA
# ==========================================

func actualizar_posicion() -> void:

	if cartel_arriba:
		cartel_sprite.position = posicion_visible()
	else:
		cartel_sprite.position = posicion_oculta()

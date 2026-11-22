
extends CharacterBody3D

# ==========================================
# CONFIGURACION DEL POLICIA
# ==========================================

@export var velocidad_patrulla: float = 2.5
@export var velocidad_persecucion: float = 4.5

@export var distancia_llegada: float = 1.0
@export var espera_patrulla: float = 0.5

@export var distancia_detencion: float = 1.5
@export var tiempo_alerta: float = 2.0
@export var tiempo_perder_jugador: float = 3.0

@export var intervalo_recalculo: float = 0.35
@export var dinero_inicial: int = 3000


# ==========================================
# ESTADOS DEL POLICIA
# ==========================================

enum Estado {
	PATRULLA,
	ALERTA,
	PERSECUCION,
	DETENCION
}

var estado_actual: Estado = Estado.PATRULLA


# ==========================================
# REFERENCIAS
# ==========================================

@onready var area_deteccion: Area3D = $AreaDeteccion

@onready var agente: NavigationAgent3D = get_node_or_null(
    "NavigationAgent3D"
) as NavigationAgent3D


# ==========================================
# VARIABLES PRINCIPALES
# ==========================================

var jugador: CharacterBody3D = null
var jugador_en_area: bool = false

var puntos_patrulla: Array[Marker3D] = []
var indice_punto: int = 0

var navegacion_lista: bool = false

var espera_actual: float = 0.0
var contador_alerta: float = 0.0
var contador_perdida: float = 0.0
var contador_detencion: float = 0.0
var contador_ruta: float = 0.0
var contador_revision: float = 0.0

var contador_atasco: float = 0.0
var posicion_anterior: Vector3 = Vector3.ZERO

var reinicio_programado: bool = false


# ==========================================
# GRAVEDAD
# ==========================================

var gravedad: float = float(
	ProjectSettings.get_setting(
        "physics/3d/default_gravity"
	)
)


# ==========================================
# INICIAR POLICIA
# ==========================================

func _ready() -> void:

	# Grupo utilizado por el vendedor de Pepito
	add_to_group("policia")

	if agente == null:

		push_error("POLICIA: Falta NavigationAgent3D")
		set_physics_process(false)
		return

	# Configurar navegacion
	agente.path_desired_distance = 0.6
	agente.target_desired_distance = 0.8
	agente.avoidance_enabled = false
	agente.navigation_layers = 1

	# Activar detector
	area_deteccion.monitoring = true

	# Buscar protagonista
	var encontrado: Node = (
		get_tree().get_first_node_in_group("jugador")
	)

	if encontrado is CharacterBody3D:

		jugador = encontrado as CharacterBody3D

	else:

		push_warning("POLICIA: Jugador no encontrado")

	# Cargar puntos de patrullaje
	cargar_ruta()

	posicion_anterior = global_position

	print("POLICIA: Sistema iniciado")


# ==========================================
# CARGAR RUTA POLICIAL
# ==========================================

func cargar_ruta() -> void:

	puntos_patrulla.clear()

	var ruta: Node = (
		get_tree().get_first_node_in_group(
            "ruta_policia"
		)
	)

	# Buscar por nombre si falta el grupo
	if ruta == null:

		var escena: Node = get_tree().current_scene

		if escena != null:

			ruta = escena.get_node_or_null(
                "Rutapolicia"
			)

	if ruta == null:

		push_error(
            "POLICIA: No encuentro Rutapolicia"
		)
		return

	# Cargar todos los Marker3D
	for hijo in ruta.get_children():

		if hijo is Marker3D:

			puntos_patrulla.append(
				hijo as Marker3D
			)

	print(
		"POLICIA: Puntos encontrados: ",
		puntos_patrulla.size()
	)

	if puntos_patrulla.is_empty():

		push_error(
            "POLICIA: No hay Marker3D en la ruta"
		)


# ==========================================
# COMPROBAR NAVEGACION
# ==========================================

func comprobar_navegacion(delta: float) -> void:

	if navegacion_lista:
		return

	contador_revision -= delta

	if contador_revision > 0.0:
		return

	contador_revision = 1.0

	var mapa: RID = agente.get_navigation_map()

	var iteracion: int = (
		NavigationServer3D.map_get_iteration_id(mapa)
	)

	if iteracion == 0:

		print("POLICIA: Esperando navegacion...")
		return

	var regiones: Array[RID] = (
		NavigationServer3D.map_get_regions(mapa)
	)

	if regiones.is_empty():

		print("POLICIA: No hay regiones de navegacion")
		return

	if puntos_patrulla.is_empty():

		print("POLICIA: Falta ruta de patrulla")
		return

	navegacion_lista = true

	# Encontrar marcador mas cercano
	var distancia_menor: float = INF

	for i in range(puntos_patrulla.size()):

		var distancia: float = distancia_horizontal(
			puntos_patrulla[i].global_position
		)

		if distancia < distancia_menor:

			distancia_menor = distancia
			indice_punto = i

	print("POLICIA: Navegacion disponible")
	print("POLICIA: Regiones: ", regiones.size())

	# Asignar primer destino
	asignar_destino_patrulla()


# ==========================================
# DETECTAR AL JUGADOR
# ==========================================

func actualizar_deteccion() -> void:

	jugador_en_area = false

	for cuerpo in area_deteccion.get_overlapping_bodies():

		if cuerpo is CharacterBody3D:

			if cuerpo.is_in_group("jugador"):

				jugador = cuerpo as CharacterBody3D

				jugador_en_area = true

				break


# ==========================================
# PROCESO PRINCIPAL
# ==========================================

func _physics_process(delta: float) -> void:

	actualizar_deteccion()

	comprobar_navegacion(delta)

	# Aplicar gravedad
	if not is_on_floor():

		velocity.y -= gravedad * delta

	else:

		velocity.y = 0.0

	# Ejecutar comportamiento
	match estado_actual:

		Estado.PATRULLA:

			patrullar(delta)

		Estado.ALERTA:

			comprobar_alerta(delta)

		Estado.PERSECUCION:

			perseguir(delta)

		Estado.DETENCION:

			detener_jugador(delta)

	move_and_slide()


# ==========================================
# PATRULLAR EL MAPA
# ==========================================

func patrullar(delta: float) -> void:

	# Solo sospechar si el cartel esta levantado
	if jugador_en_area and EstadoJuego.cartel_visible:

		cambiar_estado(Estado.ALERTA)
		return

	if not navegacion_lista:

		detener_movimiento()
		return

	if puntos_patrulla.is_empty():

		detener_movimiento()
		return

	# Esperar en cada marcador
	if espera_actual > 0.0:

		espera_actual -= delta

		detener_movimiento()
		return

	var destino: Vector3 = (
		puntos_patrulla[indice_punto].global_position
	)

	# Llegada al punto actual
	if distancia_horizontal(destino) <= distancia_llegada:

		siguiente_punto()
		return

	# Seguir navegacion
	seguir_camino(velocidad_patrulla)

	# Detectar si el policia se atasca
	var desplazamiento: float = (
		global_position.distance_to(posicion_anterior)
	)

	if desplazamiento < 0.01:

		contador_atasco += delta

	else:

		contador_atasco = 0.0

	posicion_anterior = global_position

	if contador_atasco >= 3.0:

		print(
			"POLICIA: No puedo llegar a ",
			puntos_patrulla[indice_punto].name
		)

		contador_atasco = 0.0

		siguiente_punto()


# ==========================================
# SIGUIENTE PUNTO DE PATRULLA
# ==========================================

func siguiente_punto() -> void:

	if puntos_patrulla.is_empty():
		return

	indice_punto += 1

	if indice_punto >= puntos_patrulla.size():

		indice_punto = 0

	espera_actual = espera_patrulla
	contador_atasco = 0.0

	asignar_destino_patrulla()

	print(
		"POLICIA: Voy hacia ",
		puntos_patrulla[indice_punto].name
	)


# ==========================================
# ASIGNAR DESTINO DE PATRULLA
# ==========================================

func asignar_destino_patrulla() -> void:

	if not navegacion_lista:
		return

	if puntos_patrulla.is_empty():
		return

	agente.target_position = (
		puntos_patrulla[indice_punto].global_position
	)

	print(
		"POLICIA: Destino asignado: ",
		agente.target_position
	)


# ==========================================
# SEGUIR CAMINO
# ==========================================

func seguir_camino(rapidez: float) -> void:

	if not navegacion_lista:

		detener_movimiento()
		return

	# Obtener siguiente punto de navegacion
	var siguiente: Vector3 = (
		agente.get_next_path_position()
	)

	if agente.is_navigation_finished():

		detener_movimiento()
		return

	var direccion: Vector3 = (
		siguiente - global_position
	)

	direccion.y = 0.0

	if direccion.length_squared() < 0.01:

		detener_movimiento()
		return

	direccion = direccion.normalized()

	velocity.x = direccion.x * rapidez
	velocity.z = direccion.z * rapidez


# ==========================================
# ALERTA POLICIAL
# ==========================================

func comprobar_alerta(delta: float) -> void:

	detener_movimiento()

	# Si el jugador escondio el cartel,
	# cancelar inmediatamente la sospecha
	if not EstadoJuego.cartel_visible:

		print(
            "POLICIA: Cartel guardado. "
			+ "Alerta cancelada."
		)

		cambiar_estado(Estado.PATRULLA)
		return

	# Si el jugador salio del area, cancelar
	if not jugador_en_area:

		print("POLICIA: Jugador fuera del area")

		cambiar_estado(Estado.PATRULLA)
		return

	# Aumentar sospecha
	contador_alerta += delta

	if contador_alerta >= tiempo_alerta:

		cambiar_estado(Estado.PERSECUCION)


# ==========================================
# PERSEGUIR AL JUGADOR
# ==========================================

func perseguir(delta: float) -> void:

	# ======================================
	# CORRECCION PRINCIPAL
	# ======================================
	# Si el jugador guarda el cartel con Q,
	# abandonar inmediatamente la persecucion.

	if not EstadoJuego.cartel_visible:

		print(
            "POLICIA: El jugador guardo el cartel."
		)

		print(
            "POLICIA: Cancelando persecucion."
		)

		detener_movimiento()

		cambiar_estado(Estado.PATRULLA)
		return

	# ======================================
	# COMPROBAR JUGADOR
	# ======================================

	if not is_instance_valid(jugador):

		cambiar_estado(Estado.PATRULLA)
		return

	if not navegacion_lista:

		detener_movimiento()
		return

	# ======================================
	# JUGADOR DENTRO DEL AREA
	# ======================================

	if jugador_en_area:

		contador_perdida = 0.0

		# Verificar distancia de detencion
		if distancia_horizontal(
			jugador.global_position
		) <= distancia_detencion:

			cambiar_estado(Estado.DETENCION)
			return

		# Seguir al jugador
		actualizar_ruta_persecucion(
			jugador.global_position,
			delta
		)

	# ======================================
	# JUGADOR FUERA DEL AREA
	# ======================================

	else:

		contador_perdida += delta

		# Si se aleja demasiado, regresar
		if contador_perdida >= tiempo_perder_jugador:

			print("POLICIA: Perdi al jugador")

			cambiar_estado(Estado.PATRULLA)
			return

	seguir_camino(velocidad_persecucion)


# ==========================================
# ACTUALIZAR RUTA DE PERSECUCION
# ==========================================

func actualizar_ruta_persecucion(
	destino: Vector3,
	delta: float
) -> void:

	contador_ruta -= delta

	if contador_ruta <= 0.0:

		agente.target_position = destino

		contador_ruta = intervalo_recalculo


# ==========================================
# DETENER AL JUGADOR
# ==========================================

func detener_jugador(delta: float) -> void:

	detener_movimiento()

	contador_detencion -= delta

	if contador_detencion <= 0.0:

		completar_detencion()


# ==========================================
# REINICIAR PARTIDA
# ==========================================

func completar_detencion() -> void:

	if reinicio_programado:
		return

	reinicio_programado = true

	detener_movimiento()

	print("POLICIA: ALTO! QUEDA DETENIDO!")
	print("POLICIA: Reiniciando nivel...")

	# Restaurar variables globales
	if EstadoJuego.has_method("reiniciar_partida"):

		EstadoJuego.call("reiniciar_partida")

	else:

		EstadoJuego.cartel_visible = false
		EstadoJuego.carteles_recogidos = 0
		EstadoJuego.dinero = dinero_inicial

	# Reiniciar escena
	get_tree().call_deferred(
        "reload_current_scene"
	)


# ==========================================
# CAMBIAR ESTADO
# ==========================================

func cambiar_estado(nuevo_estado: Estado) -> void:

	if estado_actual == nuevo_estado:
		return

	estado_actual = nuevo_estado

	# Reiniciar contadores
	contador_alerta = 0.0
	contador_perdida = 0.0
	contador_ruta = 0.0
	contador_atasco = 0.0

	match estado_actual:

		# ==================================
		# VOLVER A PATRULLAR
		# ==================================

		Estado.PATRULLA:

			detener_movimiento()

			espera_actual = 0.0

			posicion_anterior = global_position

			# Recuperar ruta de marcadores
			asignar_destino_patrulla()

			print(
                "POLICIA: Regresando a patrullar"
			)

		# ==================================
		# SOSPECHA
		# ==================================

		Estado.ALERTA:

			detener_movimiento()

			print(
                "POLICIA: Sospechando del jugador"
			)

		# ==================================
		# PERSECUCION
		# ==================================

		Estado.PERSECUCION:

			print(
                "POLICIA: Iniciando persecucion!"
			)

			if is_instance_valid(jugador) and navegacion_lista:

				agente.target_position = (
					jugador.global_position
				)

		# ==================================
		# DETENCION
		# ==================================

		Estado.DETENCION:

			detener_movimiento()

			contador_detencion = 0.5

			print(
                "POLICIA: Deteniendo al jugador"
			)


# ==========================================
# DETENER MOVIMIENTO
# ==========================================

func detener_movimiento() -> void:

	velocity.x = 0.0
	velocity.z = 0.0


# ==========================================
# DISTANCIA HORIZONTAL
# ==========================================

func distancia_horizontal(destino: Vector3) -> float:

	var diferencia: Vector3 = (
		destino - global_position
	)

	diferencia.y = 0.0

	return diferencia.length()

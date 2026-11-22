
extends Node3D

# ==========================================
# VENDEDOR PEPITO - PASEO AHUMADA
# HUIDA Y REAPARICION AUTOMATICA
# ==========================================

# DETECCION POLICIAL
@export var radio_alerta: float = 7.0
@export var intervalo_revision: float = 0.25

# TIEMPOS
@export var tiempo_escondido: float = 5.0
@export var tiempo_maximo_busqueda: float = 5.0
@export var proteccion_reaparicion: float = 10.0

# SEGURIDAD DE LAS UBICACIONES
@export var distancia_segura: float = 9.0
@export var distancia_minima_jugador: float = 2.5
@export var distancia_minima_traslado: float = 3.0


# ==========================================
# REFERENCIAS
# ==========================================

@onready var puesto: StaticBody3D = (
	get_parent() as StaticBody3D
)

@onready var detector: Area3D = (
	get_node_or_null("../DetectorPolicia") as Area3D
)


# ==========================================
# VARIABLES
# ==========================================

var ubicaciones: Array[Marker3D] = []

var escapando: bool = false

var tiempo_revision: float = 0.0
var tiempo_oculto_restante: float = 0.0
var tiempo_busqueda_restante: float = 0.0
var tiempo_protegido: float = 0.0

var capa_original: int = 1
var mascara_original: int = 1

var cantidad_huidas: int = 0

var ultimo_punto: Marker3D = null

var aviso_sin_lugar: bool = false


# ==========================================
# INICIAR VENDEDOR
# ==========================================

func _ready() -> void:

	if puesto == null:

		push_error(
            "VENDEDOR: Debe ser hijo de PuestoPepito"
		)

		set_physics_process(false)
		return

	# Guardar configuracion original
	capa_original = puesto.collision_layer
	mascara_original = puesto.collision_mask

	puesto.visible = true

	if detector != null:
		detector.monitoring = true

	# Buscar ubicaciones de Pepito
	cargar_ubicaciones()

	print("================================")
	print("VENDEDOR PEPITO INICIADO")

	print(
		"Ubicaciones encontradas: ",
		ubicaciones.size()
	)

	print("================================")


# ==========================================
# BUSCAR UBICACIONES
# ==========================================

func cargar_ubicaciones() -> void:

	ubicaciones.clear()

	var contenedor: Node = (
		get_tree().get_first_node_in_group(
            "puntos_pepito"
		)
	)

	# Buscar tambien por nombre
	if contenedor == null:

		var escena: Node = get_tree().current_scene

		if escena != null:

			contenedor = escena.find_child(
				"PuntosPepito",
				true,
				false
			)

	if contenedor == null:

		push_warning(
            "VENDEDOR: No existe PuntosPepito"
		)

		return

	for hijo in contenedor.get_children():

		if hijo is Marker3D:

			ubicaciones.append(
				hijo as Marker3D
			)

	if ubicaciones.size() < 2:

		push_warning(
            "VENDEDOR: Se recomiendan "
			+ "al menos dos ubicaciones"
		)


# ==========================================
# PROCESO PRINCIPAL
# ==========================================

func _physics_process(delta: float) -> void:

	if not is_instance_valid(puesto):
		return

	# ======================================
	# SI EL VENDEDOR ESTA ESCONDIDO
	# ======================================

	if escapando:

		actualizar_huida(delta)
		return

	# ======================================
	# PROTECCION TRAS REAPARECER
	# ======================================

	if tiempo_protegido > 0.0:

		tiempo_protegido = maxf(
			tiempo_protegido - delta,
			0.0
		)

		return

	# ======================================
	# REVISION PERIODICA DE POLICIAS
	# ======================================

	tiempo_revision -= delta

	if tiempo_revision > 0.0:
		return

	tiempo_revision = maxf(
		intervalo_revision,
		0.05
	)

	if detectar_policia():

		iniciar_huida()


# ==========================================
# DETECTAR POLICIAS
# ==========================================

func detectar_policia() -> bool:

	# Comprobar los cuerpos del detector
	if detector != null:

		for cuerpo in detector.get_overlapping_bodies():

			if cuerpo.is_in_group("policia"):

				var distancia: float = (
					distancia_horizontal(
						cuerpo.global_position,
						puesto.global_position
					)
				)

				if distancia <= radio_alerta:
					return true

	# Comprobar tambien por distancia
	# para no depender solo del Area3D
	for nodo in get_tree().get_nodes_in_group(
        "policia"
	):

		var policia: Node3D = nodo as Node3D

		if not is_instance_valid(policia):
			continue

		var distancia: float = (
			distancia_horizontal(
				policia.global_position,
				puesto.global_position
			)
		)

		if distancia <= radio_alerta:

			return true

	return false


# ==========================================
# COMENZAR HUIDA
# ==========================================

func iniciar_huida() -> void:

	if escapando:
		return

	# Intentar recuperar los puntos si faltan
	if ubicaciones.is_empty():

		cargar_ubicaciones()

	# No hacer desaparecer el puesto
	# si no existen ubicaciones configuradas
	if ubicaciones.is_empty():

		push_warning(
            "VENDEDOR: No puedo huir "
			+ "porque faltan ubicaciones"
		)

		return

	escapando = true

	cantidad_huidas += 1

	# Preparar los temporizadores
	tiempo_oculto_restante = maxf(
		tiempo_escondido,
		0.0
	)

	tiempo_busqueda_restante = maxf(
		tiempo_maximo_busqueda,
		0.0
	)

	aviso_sin_lugar = false

	print("================================")

	print(
		"VENDEDOR: HUIDA NUMERO ",
		cantidad_huidas
	)

	print("VENDEDOR: LOS PACOS! ARRANCA!")

	# Cancelar ronda y devolver apuesta pendiente
	if puesto.has_method(
        "interrumpir_por_policia"
	):

		puesto.call(
            "interrumpir_por_policia"
		)

	# Ocultar mesa, conos y vendedor
	puesto.visible = false

	# Desactivar colision temporalmente
	puesto.collision_layer = 0
	puesto.collision_mask = 0

	if detector != null:

		detector.set_deferred(
			"monitoring",
			false
		)

	print("VENDEDOR: Puesto escondido")
	print("================================")


# ==========================================
# CONTROLAR TIEMPO DE HUIDA
# ==========================================

func actualizar_huida(delta: float) -> void:

	# Primera etapa: permanecer escondido
	if tiempo_oculto_restante > 0.0:

		tiempo_oculto_restante = maxf(
			tiempo_oculto_restante - delta,
			0.0
		)

		return

	# Segunda etapa: buscar un lugar seguro
	var destino: Marker3D = (
		buscar_ubicacion_segura()
	)

	if destino != null:

		reinstalar_puesto(
			destino,
			false
		)

		return

	# Todavia no se encontro un lugar seguro
	if not aviso_sin_lugar:

		aviso_sin_lugar = true

		print(
            "VENDEDOR: Todas las ubicaciones "
			+ "estan vigiladas"
		)

		print(
            "VENDEDOR: Esperando un lugar seguro"
		)

	tiempo_busqueda_restante -= delta

	# No esperar indefinidamente
	if tiempo_busqueda_restante > 0.0:

		return

	# Buscar el lugar menos peligroso
	var alternativa: Marker3D = (
		buscar_ubicacion_alternativa()
	)

	if alternativa != null:

		reinstalar_puesto(
			alternativa,
			true
		)

	else:

		# Si todos los marcadores fallaron,
		# recuperar el puesto en la misma
		# posicion antes que dejarlo invisible
		push_warning(
            "VENDEDOR: No se encontro destino. "
			+ "Restaurando puesto actual."
		)

		reinstalar_puesto(
			null,
			true
		)


# ==========================================
# BUSCAR UBICACION SEGURA
# ==========================================

func buscar_ubicacion_segura() -> Marker3D:

	var disponibles: Array[Marker3D] = []

	for punto in ubicaciones:

		if not is_instance_valid(punto):
			continue

		# Evitar reaparecer en el mismo lugar
		var distancia_actual: float = (
			distancia_horizontal(
				punto.global_position,
				puesto.global_position
			)
		)

		if distancia_actual < distancia_minima_traslado:
			continue

		if not punto_es_seguro(punto):
			continue

		disponibles.append(punto)

	if disponibles.is_empty():

		return null

	# Elegir aleatoriamente
	var indice: int = randi_range(
		0,
		disponibles.size() - 1
	)

	return disponibles[indice]


# ==========================================
# COMPROBAR SEGURIDAD
# ==========================================

func punto_es_seguro(punto: Marker3D) -> bool:

	# Comprobar policias
	for nodo in get_tree().get_nodes_in_group(
        "policia"
	):

		var policia: Node3D = nodo as Node3D

		if not is_instance_valid(policia):
			continue

		var distancia: float = (
			distancia_horizontal(
				punto.global_position,
				policia.global_position
			)
		)

		if distancia < distancia_segura:

			return false

	# Comprobar jugador
	var jugador: Node3D = obtener_jugador()

	if jugador != null:

		var distancia_jugador: float = (
			distancia_horizontal(
				punto.global_position,
				jugador.global_position
			)
		)

		if distancia_jugador < distancia_minima_jugador:

			return false

	return true


# ==========================================
# BUSCAR DESTINO ALTERNATIVO
# ==========================================

func buscar_ubicacion_alternativa() -> Marker3D:

	var mejor_punto: Marker3D = null

	var mejor_puntuacion: float = -INF

	for punto in ubicaciones:

		if not is_instance_valid(punto):
			continue

		# Preferir un destino distinto
		var distancia_actual: float = (
			distancia_horizontal(
				punto.global_position,
				puesto.global_position
			)
		)

		if distancia_actual < distancia_minima_traslado:
			continue

		# Calcular distancia al policia mas cercano
		var distancia_policia: float = 10000.0

		for nodo in get_tree().get_nodes_in_group(
            "policia"
		):

			var policia: Node3D = nodo as Node3D

			if not is_instance_valid(policia):
				continue

			var distancia: float = (
				distancia_horizontal(
					punto.global_position,
					policia.global_position
				)
			)

			distancia_policia = minf(
				distancia_policia,
				distancia
			)

		# Preferir la zona mas alejada
		var puntuacion: float = distancia_policia

		# Penalizar lugares encima del jugador
		var jugador: Node3D = obtener_jugador()

		if jugador != null:

			var distancia_jugador: float = (
				distancia_horizontal(
					punto.global_position,
					jugador.global_position
				)
			)

			if distancia_jugador < distancia_minima_jugador:

				puntuacion -= 1000.0

		if puntuacion > mejor_puntuacion:

			mejor_puntuacion = puntuacion
			mejor_punto = punto

	return mejor_punto


# ==========================================
# OBTENER JUGADOR
# ==========================================

func obtener_jugador() -> Node3D:

	var encontrado: Node = (
		get_tree().get_first_node_in_group(
            "jugador"
		)
	)

	if encontrado == null:

		encontrado = (
			get_tree().get_first_node_in_group(
                "player"
			)
		)

	return encontrado as Node3D


# ==========================================
# REINSTALAR EL PUESTO
# ==========================================

func reinstalar_puesto(
	destino: Marker3D,
	reaparicion_forzada: bool
) -> void:

	if not is_instance_valid(puesto):
		return

	if destino != null:

		# Conservar altura del puesto original.
		# Cambiar solo las coordenadas X y Z
		# para evitar que la mesa quede enterrada.
		var nueva_posicion: Vector3 = (
			puesto.global_position
		)

		nueva_posicion.x = (
			destino.global_position.x
		)

		nueva_posicion.z = (
			destino.global_position.z
		)

		puesto.global_position = nueva_posicion

		# Ajustar orientacion horizontal
		var nueva_rotacion: Vector3 = (
			puesto.global_rotation
		)

		nueva_rotacion.y = (
			destino.global_rotation.y
		)

		puesto.global_rotation = nueva_rotacion

		# Evitar interpolacion desde el
		# puesto anterior hasta el nuevo
		puesto.reset_physics_interpolation()

		ultimo_punto = destino

	# Recuperar colisiones originales
	puesto.collision_layer = capa_original
	puesto.collision_mask = mascara_original

	# Mostrar todo el puesto nuevamente
	puesto.visible = true

	if detector != null:

		detector.set_deferred(
			"monitoring",
			true
		)

	# Finalizar huida
	escapando = false

	tiempo_oculto_restante = 0.0
	tiempo_busqueda_restante = 0.0

	tiempo_revision = maxf(
		intervalo_revision,
		0.05
	)

	# Evitar otra huida inmediata
	tiempo_protegido = maxf(
		proteccion_reaparicion,
		0.0
	)

	aviso_sin_lugar = false

	print("================================")

	if reaparicion_forzada:

		print(
            "VENDEDOR: Reaparicion de emergencia"
		)

	else:

		print(
            "VENDEDOR: Ubicacion segura encontrada"
		)

	if destino != null:

		print(
			"VENDEDOR: Nuevo lugar: ",
			destino.name
		)

	print(
		"VENDEDOR: Posicion: ",
		puesto.global_position
	)

	print(
		"VENDEDOR: Proteccion: ",
		tiempo_protegido,
        " segundos"
	)

	print("VENDEDOR: Puesto instalado")
	print("================================")


# ==========================================
# DISTANCIA HORIZONTAL
# ==========================================

func distancia_horizontal(
	origen: Vector3,
	destino: Vector3
) -> float:

	var diferencia: Vector3 = (
		destino - origen
	)

	diferencia.y = 0.0

	return diferencia.length()

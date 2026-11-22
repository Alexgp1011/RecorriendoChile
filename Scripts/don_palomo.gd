
extends StaticBody3D

# ==========================================
# DON PALOMO - COMBATE AEREO AVANZADO
# ATAQUE NORMAL + LLUVIA MASIVA + PICADA
# ==========================================

signal fase_cambiada(nueva_fase: int)


# ==========================================
# VIDA
# ==========================================

@export var vida_maxima: int = 8
@export var capa_impacto: int = 1
@export var solo_dano_vulnerable: bool = false


# ==========================================
# VELOCIDADES DE VUELO
# ==========================================

@export var velocidad_vuelo: float = 8.0
@export var velocidad_vuelo_fase_2: float = 10.5
@export var velocidad_vuelo_fase_3: float = 13.5

@export var velocidad_hacia_cruz: float = 9.0
@export var velocidad_picada: float = 15.0


# ==========================================
# TIEMPOS DE MOVIMIENTO
# ==========================================

@export var tiempo_espera_aire: float = 1.1
@export var espera_aire_fase_2: float = 0.9
@export var espera_aire_fase_3: float = 0.75

@export var tiempo_vulnerable: float = 0.65

@export var tiempo_percha_cruz: float = 2.2
@export var tiempo_aviso_picada: float = 0.85
@export var tiempo_vulnerable_picada: float = 1.3


# ==========================================
# ATAQUE NORMAL DESDE DON PALOMO
# ==========================================

@export var activar_bombardeo: bool = true
@export var escena_excremento: PackedScene

@export var bombas_fase_1: int = 3
@export var bombas_fase_2: int = 4
@export var bombas_fase_3: int = 6

@export var intervalo_entre_bombas: float = 0.3

@export var advertencia_normal: float = 0.85
@export var tiempo_caida_normal: float = 0.75


# ==========================================
# LLUVIA MASIVA EN PLAZA DE ARMAS
# ==========================================

@export var activar_lluvia: bool = true

@export var ancho_plaza: float = 34.0
@export var largo_plaza: float = 34.0

@export var cantidad_lluvia_fase_1: int = 10
@export var cantidad_lluvia_fase_2: int = 18
@export var cantidad_lluvia_fase_3: int = 26

@export var separacion_marcas: float = 2.8

@export var altura_proyectiles: float = 13.0
@export var advertencia_lluvia: float = 1.6
@export var tiempo_caida_lluvia: float = 0.7

# FRECUENCIA DE LLUVIA ADICIONAL
@export var lluvia_cada_paradas_fase_1: int = 2
@export var lluvia_cada_paradas_fase_2: int = 1
@export var lluvia_cada_paradas_fase_3: int = 1

@export var descanso_lluvia_fase_1: float = 8.0
@export var descanso_lluvia_fase_2: float = 6.0
@export var descanso_lluvia_fase_3: float = 4.5

# DETECCION DEL SUELO
@export_flags_3d_physics var mascara_suelo: int = 1
@export var tolerancia_altura_suelo: float = 1.2


# ==========================================
# CATEDRAL
# ==========================================

@export var punto_cruz_catedral: Marker3D
@export var paradas_entre_cruces: int = 3


# ==========================================
# ATAQUE EN PICADA
# ==========================================

@export var activar_picada: bool = true
@export var paradas_entre_picadas: int = 2

@export var altura_picada: float = 1.7
@export var radio_dano_picada: float = 2.0
@export var dano_picada: int = 20


# ==========================================
# NODOS
# ==========================================

@onready var colision: CollisionShape3D = (
	$CollisionShape3D
)

@onready var centro_arena: Node3D = (
	get_parent() as Node3D
)


# ==========================================
# ESTADOS DEL JEFE
# ==========================================

enum Estado {
	OCULTO,
	HACIA_CRUZ,
	SOBRE_CRUZ,
	VOLANDO,
	RAFAGA_NORMAL,
	LLUVIA_MASIVA,
	VULNERABLE,
	AVISO_PICADA,
	EN_PICADA,
	DERROTADO
}

enum Fase {
	FASE_1,
	FASE_2,
	FASE_3
}


# ==========================================
# VARIABLES PRINCIPALES
# ==========================================

var estado_actual: Estado = Estado.OCULTO
var fase_actual: Fase = Fase.FASE_1

var vida_actual: int = 8

var combate_activo: bool = false
var derrotado: bool = false

var jugador: CharacterBody3D = null


# ==========================================
# MOVIMIENTO
# ==========================================

var puntos_vuelo: Array[Marker3D] = []
var indice_vuelo: int = -1

var tiempo_estado: float = 0.0

var paradas_desde_cruz: int = 0
var paradas_desde_picada: int = 0
var paradas_desde_lluvia: int = 0


# ==========================================
# ATAQUES
# ==========================================

var bombas_pendientes: int = 0

var reloj_bombas: float = 0.0
var tiempo_desde_lluvia: float = 999.0

var lluvia_desde_cruz: bool = false

var destino_picada: Vector3 = Vector3.ZERO
var golpe_picada_registrado: bool = false


# ==========================================
# INTERFAZ
# ==========================================

var capa_interfaz: CanvasLayer
var panel_vida: PanelContainer
var barra_vida: ProgressBar

var etiqueta_fase: Label
var etiqueta_ataque: Label


# ==========================================
# READY
# ==========================================

func _ready() -> void:

	randomize()

	vida_actual = maxi(vida_maxima, 1)

	buscar_jugador()
	cargar_puntos_vuelo()
	crear_interfaz()

	desactivar_jefe()

	if not GestorMisiones.etapa_cambiada.is_connected(
		al_cambiar_etapa
	):

		GestorMisiones.etapa_cambiada.connect(
			al_cambiar_etapa
		)

	if (
		GestorMisiones.obtener_etapa_actual()
		== int(
			GestorMisiones.Etapa.DERROTAR_DON_PALOMO
		)
	):

		activar_jefe()

	print("DON PALOMO: Sistema avanzado preparado")


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
# CARGAR PUNTOS DE VUELO
# ==========================================

func cargar_puntos_vuelo() -> void:

	puntos_vuelo.clear()

	var contenedor: Node3D = (
		get_node_or_null("../PuntosVueloPalomo") as Node3D
	)

	if contenedor == null:

		push_warning(
            "DON PALOMO: Falta PuntosVueloPalomo"
		)

		return

	for hijo in contenedor.get_children():

		if hijo is Marker3D:

			puntos_vuelo.append(
				hijo as Marker3D
			)

	print(
		"DON PALOMO: Puntos de vuelo: ",
		puntos_vuelo.size()
	)


# ==========================================
# CAMBIO DE MISION
# ==========================================

func al_cambiar_etapa(nueva_etapa: int) -> void:

	if (
		nueva_etapa
		== int(
			GestorMisiones.Etapa.DERROTAR_DON_PALOMO
		)
	):

		activar_jefe()


# ==========================================
# ACTIVAR COMBATE
# ==========================================

func activar_jefe() -> void:

	if combate_activo or derrotado:
		return

	combate_activo = true

	vida_actual = maxi(vida_maxima, 1)
	fase_actual = Fase.FASE_1

	indice_vuelo = -1

	paradas_desde_cruz = 0
	paradas_desde_picada = 0
	paradas_desde_lluvia = 0

	bombas_pendientes = 0
	reloj_bombas = 0.0

	tiempo_estado = 0.0
	tiempo_desde_lluvia = 999.0

	buscar_jugador()

	visible = true

	collision_layer = capa_impacto
	collision_mask = 1

	colision.set_deferred(
		"disabled",
		false
	)

	panel_vida.show()
	actualizar_interfaz_vida()

	fase_cambiada.emit(
		int(fase_actual)
	)

	if is_instance_valid(punto_cruz_catedral):

		estado_actual = Estado.HACIA_CRUZ

		print(
            "DON PALOMO: SUBIENDO A LA CATEDRAL!"
		)

	else:

		elegir_siguiente_punto()

	print(
        "DON PALOMO: COMIENZA EL COMBATE!"
	)


# ==========================================
# DESACTIVAR
# ==========================================

func desactivar_jefe() -> void:

	combate_activo = false

	estado_actual = Estado.OCULTO
	bombas_pendientes = 0

	visible = false

	collision_layer = 0
	collision_mask = 0

	colision.set_deferred(
		"disabled",
		true
	)

	if panel_vida != null:

		panel_vida.hide()


# ==========================================
# PROCESO FISICO
# ==========================================

func _physics_process(delta: float) -> void:

	if not combate_activo or derrotado:
		return

	tiempo_desde_lluvia += delta

	match estado_actual:

		Estado.HACIA_CRUZ:

			volar_hacia_cruz(delta)

		Estado.SOBRE_CRUZ:

			esperar_en_cruz(delta)

		Estado.VOLANDO:

			volar_hacia_punto(delta)

		Estado.RAFAGA_NORMAL:

			procesar_rafaga_normal(delta)

		Estado.LLUVIA_MASIVA:

			procesar_espera_lluvia(delta)

		Estado.VULNERABLE:

			procesar_vulnerabilidad(delta)

		Estado.AVISO_PICADA:

			procesar_aviso_picada(delta)

		Estado.EN_PICADA:

			procesar_picada(delta)


# ==========================================
# DATOS SEGUN FASE
# ==========================================

func obtener_velocidad() -> float:

	match fase_actual:

		Fase.FASE_2:
			return velocidad_vuelo_fase_2

		Fase.FASE_3:
			return velocidad_vuelo_fase_3

	return velocidad_vuelo


func obtener_espera() -> float:

	match fase_actual:

		Fase.FASE_2:
			return espera_aire_fase_2

		Fase.FASE_3:
			return espera_aire_fase_3

	return tiempo_espera_aire


func obtener_bombas() -> int:

	match fase_actual:

		Fase.FASE_2:
			return maxi(bombas_fase_2, 1)

		Fase.FASE_3:
			return maxi(bombas_fase_3, 1)

	return maxi(bombas_fase_1, 1)


func obtener_cantidad_lluvia() -> int:

	match fase_actual:

		Fase.FASE_2:
			return maxi(cantidad_lluvia_fase_2, 1)

		Fase.FASE_3:
			return maxi(cantidad_lluvia_fase_3, 1)

	return maxi(cantidad_lluvia_fase_1, 1)


func obtener_paradas_para_lluvia() -> int:

	match fase_actual:

		Fase.FASE_2:
			return maxi(lluvia_cada_paradas_fase_2, 1)

		Fase.FASE_3:
			return maxi(lluvia_cada_paradas_fase_3, 1)

	return maxi(lluvia_cada_paradas_fase_1, 1)


func obtener_descanso_lluvia() -> float:

	match fase_actual:

		Fase.FASE_2:
			return descanso_lluvia_fase_2

		Fase.FASE_3:
			return descanso_lluvia_fase_3

	return descanso_lluvia_fase_1


func obtener_intervalo_bombas() -> float:

	var reduccion: float = (
		float(int(fase_actual)) * 0.05
	)

	return maxf(
		intervalo_entre_bombas - reduccion,
		0.16
	)


# ==========================================
# VUELO INICIAL A LA CATEDRAL
# ==========================================

func volar_hacia_cruz(delta: float) -> void:

	if not is_instance_valid(punto_cruz_catedral):

		elegir_siguiente_punto()
		return

	var llego: bool = mover_hacia(
		punto_cruz_catedral.global_position,
		velocidad_hacia_cruz,
		delta
	)

	if llego:

		paradas_desde_cruz = 0

		# Bombardeo desde la cruz
		comenzar_lluvia_masiva(true)

		print(
            "DON PALOMO: ATACANDO DESDE LA CATEDRAL!"
		)


# ==========================================
# ESPERAR EN LA CRUZ
# ==========================================

func esperar_en_cruz(delta: float) -> void:

	tiempo_estado -= delta

	if tiempo_estado <= 0.0:

		elegir_siguiente_punto()


# ==========================================
# SIGUIENTE PUNTO DE VUELO
# ==========================================

func elegir_siguiente_punto() -> void:

	if puntos_vuelo.is_empty():

		estado_actual = Estado.VULNERABLE
		tiempo_estado = 99999.0

		push_warning(
            "DON PALOMO: No hay marcadores de vuelo"
		)

		return

	if puntos_vuelo.size() == 1:

		indice_vuelo = 0

	elif indice_vuelo < 0:

		indice_vuelo = randi_range(
			0,
			puntos_vuelo.size() - 1
		)

	else:

		var salto: int = randi_range(
			1,
			puntos_vuelo.size() - 1
		)

		indice_vuelo = (
			indice_vuelo + salto
		) % puntos_vuelo.size()

	estado_actual = Estado.VOLANDO

	if etiqueta_ataque != null:
		etiqueta_ataque.text = ""

	print(
		"DON PALOMO: Volando hacia ",
		puntos_vuelo[indice_vuelo].name
	)


# ==========================================
# VUELO ENTRE MARCADORES
# ==========================================

func volar_hacia_punto(delta: float) -> void:

	if puntos_vuelo.is_empty():
		return

	var destino: Vector3 = (
		puntos_vuelo[indice_vuelo].global_position
	)

	var llego: bool = mover_hacia(
		destino,
		obtener_velocidad(),
		delta
	)

	if llego:

		paradas_desde_cruz += 1
		paradas_desde_picada += 1
		paradas_desde_lluvia += 1

		# Siempre realizar primero
		# el bombardeo desde Don Palomo
		comenzar_rafaga_normal()


# ==========================================
# INICIAR RAFAGA NORMAL
# ==========================================

func comenzar_rafaga_normal() -> void:

	estado_actual = Estado.RAFAGA_NORMAL

	bombas_pendientes = 0
	reloj_bombas = 0.0

	tiempo_estado = maxf(
		obtener_espera(),
		0.2
	)

	if activar_bombardeo and escena_excremento != null:

		bombas_pendientes = obtener_bombas()

		# Permitir finalizar todos los lanzamientos
		tiempo_estado = maxf(
			tiempo_estado,
			float(bombas_pendientes - 1)
			* obtener_intervalo_bombas() + 0.25
		)

	if etiqueta_ataque != null:

		etiqueta_ataque.text = (
            "¡DON PALOMO ESTA BOMBARDEANDO!"
		)

	print(
		"DON PALOMO: RAFAGA NORMAL DE ",
		bombas_pendientes,
        " PROYECTILES"
	)


# ==========================================
# LANZAR RAFAGA NORMAL
# ==========================================

func procesar_rafaga_normal(delta: float) -> void:

	tiempo_estado -= delta

	if bombas_pendientes > 0:

		reloj_bombas -= delta

		if reloj_bombas <= 0.0:

			lanzar_bomba_desde_palomo()

			bombas_pendientes -= 1

			reloj_bombas = obtener_intervalo_bombas()

	if (
		bombas_pendientes <= 0
		and tiempo_estado <= 0.0
	):

		if corresponde_lluvia_adicional():

			comenzar_lluvia_masiva(false)

		else:

			comenzar_vulnerabilidad()


# ==========================================
# BOMBA QUE SALE DE DON PALOMO
# ==========================================

func lanzar_bomba_desde_palomo() -> void:

	if not activar_bombardeo:
		return

	if not is_instance_valid(jugador):

		buscar_jugador()

	if not is_instance_valid(jugador):
		return

	if jugador.get("dead") == true:
		return

	var suelo: Dictionary = buscar_suelo(
		jugador.global_position
	)

	if suelo.is_empty():
		return

	var punto_impacto: Vector3 = (
		suelo["position"]
	)

	# DIFERENCIA IMPORTANTE:
	# El proyectil comienza donde
	# esta Don Palomo, no sobre el jugador.
	var origen: Vector3 = (
		global_position + Vector3.UP * 0.3
	)

	crear_proyectil(
		origen,
		punto_impacto,
		advertencia_normal,
		tiempo_caida_normal
	)

	print(
        "DON PALOMO: Proyectil desde mi posicion"
	)


# ==========================================
# COMPROBAR FRECUENCIA DE LLUVIA
# ==========================================

func corresponde_lluvia_adicional() -> bool:

	if not activar_lluvia:
		return false

	if escena_excremento == null:
		return false

	if (
		paradas_desde_lluvia
		< obtener_paradas_para_lluvia()
	):

		return false

	if (
		tiempo_desde_lluvia
		< obtener_descanso_lluvia()
	):

		return false

	return true


# ==========================================
# COMENZAR LLUVIA MASIVA
# ==========================================

func comenzar_lluvia_masiva(
	desde_cruz: bool
) -> void:

	estado_actual = Estado.LLUVIA_MASIVA

	lluvia_desde_cruz = desde_cruz

	tiempo_desde_lluvia = 0.0
	paradas_desde_lluvia = 0

	var tiempo_total: float = (
		maxf(advertencia_lluvia, 0.3)
		+ maxf(tiempo_caida_lluvia, 0.2)
		+ 0.2
	)

	if desde_cruz:

		tiempo_estado = maxf(
			tiempo_total,
			tiempo_percha_cruz
		)

	else:

		tiempo_estado = tiempo_total

	if etiqueta_ataque != null:

		etiqueta_ataque.text = (
            "¡LLUVIA MASIVA EN PLAZA DE ARMAS!"
		)

	if activar_lluvia:

		lanzar_lluvia_plaza()

	print(
        "DON PALOMO: LLUVIA MASIVA ACTIVADA!"
	)


# ==========================================
# GENERAR LLUVIA EN LA PLAZA
# ==========================================

func lanzar_lluvia_plaza() -> void:

	if escena_excremento == null:
		return

	if not is_instance_valid(jugador):

		buscar_jugador()

	if not is_instance_valid(jugador):
		return

	var cantidad: int = obtener_cantidad_lluvia()

	var posiciones: Array[Vector3] = []

	var mitad_x: float = maxf(
		ancho_plaza * 0.5 - 1.5,
		1.0
	)

	var mitad_z: float = maxf(
		largo_plaza * 0.5 - 1.5,
		1.0
	)

	# PRIMERA MARCA:
	# Apuntar donde esta el jugador.
	var local_jugador: Vector3 = (
		centro_arena.to_local(
			jugador.global_position
		)
	)

	if (
		absf(local_jugador.x) <= mitad_x
		and absf(local_jugador.z) <= mitad_z
	):

		var suelo_jugador: Dictionary = (
			buscar_suelo(
				jugador.global_position
			)
		)

		if not suelo_jugador.is_empty():

			posiciones.append(
				suelo_jugador["position"]
			)

	# RESTO DE MARCAS:
	# Distribuir por la explanada.
	var intentos: int = 0

	var maximo_intentos: int = maxi(
		cantidad * 45,
		150
	)

	while (
		posiciones.size() < cantidad
		and intentos < maximo_intentos
	):

		intentos += 1

		var x: float = randf_range(
			-mitad_x,
			mitad_x
		)

		var z: float = randf_range(
			-mitad_z,
			mitad_z
		)

		var muestra: Vector3 = (
			centro_arena.to_global(
				Vector3(x, 0.0, z)
			)
		)

		var suelo: Dictionary = buscar_suelo(
			muestra
		)

		if suelo.is_empty():
			continue

		var punto: Vector3 = suelo["position"]

		var cerca: bool = false

		for anterior in posiciones:

			var diferencia: Vector3 = (
				anterior - punto
			)

			diferencia.y = 0.0

			if (
				diferencia.length()
				< separacion_marcas
			):

				cerca = true
				break

		if cerca:
			continue

		posiciones.append(punto)

	# TODOS LOS CIRCULOS SE CREAN
	# EN EL MISMO PASO DE FISICA
	for punto in posiciones:

		var origen: Vector3 = Vector3(
			punto.x,
			punto.y + altura_proyectiles,
			punto.z
		)

		crear_proyectil(
			origen,
			punto,
			advertencia_lluvia,
			tiempo_caida_lluvia
		)

	print(
		"DON PALOMO: ZONAS ROJAS GENERADAS: ",
		posiciones.size()
	)


# ==========================================
# ESPERAR FINAL DE LA LLUVIA
# ==========================================

func procesar_espera_lluvia(delta: float) -> void:

	tiempo_estado -= delta

	if tiempo_estado > 0.0:
		return

	if lluvia_desde_cruz:

		# Despues de atacar desde la cruz
		# vuelve al circuito aereo.
		elegir_siguiente_punto()

	else:

		comenzar_vulnerabilidad()


# ==========================================
# CREAR PROYECTIL REUTILIZABLE
# ==========================================

func crear_proyectil(
	origen: Vector3,
	impacto: Vector3,
	tiempo_alerta: float,
	duracion_caida: float
) -> void:

	if escena_excremento == null:
		return

	if not is_instance_valid(jugador):
		return

	var nuevo: Node = (
		escena_excremento.instantiate()
	)

	if not (nuevo is Area3D):

		push_error(
            "DON PALOMO: Proyectil no es Area3D"
		)

		nuevo.free()
		return

	if not nuevo.has_method(
        "configurar_ataque"
	):

		push_error(
            "DON PALOMO: Falta configurar_ataque()"
		)

		nuevo.free()
		return

	var escena_principal: Node = (
		get_tree().current_scene
	)

	if escena_principal == null:

		nuevo.free()
		return

	escena_principal.add_child(nuevo)

	# El mismo proyectil admite los dos
	# tipos de ataque gracias al origen.
	nuevo.set(
		"tiempo_advertencia",
		maxf(tiempo_alerta, 0.2)
	)

	nuevo.set(
		"tiempo_caida",
		maxf(duracion_caida, 0.2)
	)

	nuevo.call(
		"configurar_ataque",
		origen,
		impacto,
		jugador
	)


# ==========================================
# ENCONTRAR EL SUELO
# ==========================================

func buscar_suelo(
	posicion: Vector3
) -> Dictionary:

	if centro_arena == null:
		return {}

	var altura_base: float = (
		centro_arena.global_position.y
	)

	var origen: Vector3 = Vector3(
		posicion.x,
		altura_base + 3.0,
		posicion.z
	)

	var destino: Vector3 = Vector3(
		posicion.x,
		altura_base - 5.0,
		posicion.z
	)

	var consulta: PhysicsRayQueryParameters3D = (
		PhysicsRayQueryParameters3D.create(
			origen,
			destino
		)
	)

	consulta.collision_mask = mascara_suelo
	consulta.collide_with_areas = false

	var excluidos: Array[RID] = [
		get_rid()
	]

	if is_instance_valid(jugador):

		excluidos.append(
			jugador.get_rid()
		)

	consulta.exclude = excluidos

	var resultado: Dictionary = (
		get_world_3d().direct_space_state.intersect_ray(
			consulta
		)
	)

	if resultado.is_empty():
		return {}

	var posicion_suelo: Vector3 = (
		resultado["position"]
	)

	# Evitar marcas en pisos superiores
	if (
		absf(
			posicion_suelo.y - altura_base
		) > tolerancia_altura_suelo
	):

		return {}

	return {
		"position": (
			posicion_suelo + Vector3.UP * 0.02
		)
	}


# ==========================================
# VULNERABILIDAD
# ==========================================

func comenzar_vulnerabilidad() -> void:

	estado_actual = Estado.VULNERABLE

	tiempo_estado = maxf(
		tiempo_vulnerable,
		0.1
	)

	if etiqueta_ataque != null:

		etiqueta_ataque.text = (
            "¡DON PALOMO ESTA VULNERABLE!"
		)


func procesar_vulnerabilidad(delta: float) -> void:

	tiempo_estado -= delta

	if tiempo_estado <= 0.0:

		decidir_siguiente_movimiento()


# ==========================================
# ELEGIR PROXIMA ACCION
# ==========================================

func decidir_siguiente_movimiento() -> void:

	# PICADA EN FASE 3
	if (
		fase_actual == Fase.FASE_3
		and activar_picada
		and paradas_desde_picada >= maxi(
			paradas_entre_picadas,
			1
		)
	):

		preparar_picada()
		return

	# REGRESO PERIODICO A LA CATEDRAL
	var limite_cruz: int = maxi(
		paradas_entre_cruces,
		1
	)

	if fase_actual == Fase.FASE_3:

		limite_cruz = maxi(
			limite_cruz - 1,
			1
		)

	if (
		paradas_desde_cruz >= limite_cruz
		and is_instance_valid(punto_cruz_catedral)
	):

		paradas_desde_cruz = 0

		estado_actual = Estado.HACIA_CRUZ

		if etiqueta_ataque != null:

			etiqueta_ataque.text = ""

		return

	# CONTINUAR VUELO ENTRE PUNTOS
	elegir_siguiente_punto()


# ==========================================
# PREPARAR PICADA
# ==========================================

func preparar_picada() -> void:

	if not is_instance_valid(jugador):

		buscar_jugador()

	if not is_instance_valid(jugador):

		elegir_siguiente_punto()
		return

	var local_jugador: Vector3 = (
		centro_arena.to_local(
			jugador.global_position
		)
	)

	var limite_x: float = maxf(
		ancho_plaza * 0.5 - 2.0,
		1.0
	)

	var limite_z: float = maxf(
		largo_plaza * 0.5 - 2.0,
		1.0
	)

	destino_picada = (
		centro_arena.to_global(
			Vector3(
				clampf(
					local_jugador.x,
					-limite_x,
					limite_x
				),
				altura_picada,
				clampf(
					local_jugador.z,
					-limite_z,
					limite_z
				)
			)
		)
	)

	golpe_picada_registrado = false

	estado_actual = Estado.AVISO_PICADA

	tiempo_estado = maxf(
		tiempo_aviso_picada,
		0.2
	)

	if etiqueta_ataque != null:

		etiqueta_ataque.text = (
            "¡CUIDADO! ¡DON PALOMO EN PICADA!"
		)

	print(
        "DON PALOMO: PREPARANDO PICADA!"
	)


# ==========================================
# AVISO DE PICADA
# ==========================================

func procesar_aviso_picada(delta: float) -> void:

	tiempo_estado -= delta

	if tiempo_estado <= 0.0:

		estado_actual = Estado.EN_PICADA


# ==========================================
# EJECUTAR PICADA
# ==========================================

func procesar_picada(delta: float) -> void:

	var llego: bool = mover_hacia(
		destino_picada,
		velocidad_picada,
		delta
	)

	comprobar_dano_picada()

	if llego:

		paradas_desde_picada = 0

		# No regresar al centro.
		# Queda expuesto donde termino.
		estado_actual = Estado.VULNERABLE

		tiempo_estado = maxf(
			tiempo_vulnerable_picada,
			0.1
		)

		if etiqueta_ataque != null:

			etiqueta_ataque.text = (
                "¡AHORA PUEDES ATACAR!"
			)


# ==========================================
# DANO DE LA PICADA
# ==========================================

func comprobar_dano_picada() -> void:

	if golpe_picada_registrado:
		return

	if not is_instance_valid(jugador):
		return

	var posicion_jugador: Vector3 = (
		jugador.global_position
		+ Vector3.UP * 1.0
	)

	if (
		global_position.distance_to(
			posicion_jugador
		) > radio_dano_picada
	):

		return

	golpe_picada_registrado = true

	var salud: Node = (
		jugador.get_node_or_null("Salud")
	)

	if salud != null:

		if salud.has_method("recibir_dano"):

			salud.call(
				"recibir_dano",
				dano_picada
			)


# ==========================================
# MOVER AL JEFE
# ==========================================

func mover_hacia(
	destino: Vector3,
	velocidad: float,
	delta: float
) -> bool:

	global_position = (
		global_position.move_toward(
			destino,
			maxf(velocidad, 0.01) * delta
		)
	)

	return (
		global_position.distance_to(
			destino
		) <= 0.1
	)


# ==========================================
# RECIBIR DISPAROS
# ==========================================

func kill() -> void:

	if not combate_activo or derrotado:
		return

	if solo_dano_vulnerable:

		if estado_actual != Estado.VULNERABLE:

			print(
                "DON PALOMO: NO SOY VULNERABLE!"
			)

			return

	vida_actual = maxi(
		vida_actual - 1,
		0
	)

	print(
		"DON PALOMO: VIDA ",
		vida_actual,
		"/",
		vida_maxima
	)

	if vida_actual <= 0:

		actualizar_interfaz_vida()
		derrotar_jefe()
		return

	actualizar_fase_por_vida()
	actualizar_interfaz_vida()


# ==========================================
# CAMBIAR FASE POR SALUD
# ==========================================

func actualizar_fase_por_vida() -> void:

	var porcentaje: float = (
		float(vida_actual)
		/ float(maxi(vida_maxima, 1))
	)

	var nueva_fase: Fase = Fase.FASE_1

	# 8-6: FASE 1
	# 5-3: FASE 2
	# 2-1: FASE 3

	if porcentaje >= 0.75:

		nueva_fase = Fase.FASE_1

	elif porcentaje >= 0.375:

		nueva_fase = Fase.FASE_2

	else:

		nueva_fase = Fase.FASE_3

	if nueva_fase == fase_actual:
		return

	fase_actual = nueva_fase

	print(
		"DON PALOMO: FASE ",
		int(fase_actual) + 1,
        " ACTIVADA!"
	)

	fase_cambiada.emit(
		int(fase_actual)
	)


# ==========================================
# NOMBRE DE FASE
# ==========================================

func obtener_nombre_fase() -> String:

	match fase_actual:

		Fase.FASE_1:

			return "FASE 1 - BOMBARDEO"

		Fase.FASE_2:

			return "FASE 2 - ENFURECIDO"

		Fase.FASE_3:

			return "FASE 3 - FURIA DE DON PALOMO"

	return ""


# ==========================================
# DERROTAR AL JEFE
# ==========================================

func derrotar_jefe() -> void:

	if derrotado:
		return

	derrotado = true
	combate_activo = false

	estado_actual = Estado.DERROTADO

	bombas_pendientes = 0

	visible = false

	collision_layer = 0
	collision_mask = 0

	colision.set_deferred(
		"disabled",
		true
	)

	if panel_vida != null:

		panel_vida.hide()

	limpiar_proyectiles()

	print(
        "DON PALOMO: DERROTADO!"
	)

	GestorMisiones.registrar_derrota_palomo()


# ==========================================
# LIMPIAR PROYECTILES
# ==========================================

func limpiar_proyectiles() -> void:

	for nodo in get_tree().get_nodes_in_group(
        "proyectiles_don_palomo"
	):

		if is_instance_valid(nodo):

			nodo.queue_free()


# ==========================================
# CREAR INTERFAZ
# ==========================================

func crear_interfaz() -> void:

	capa_interfaz = CanvasLayer.new()
	capa_interfaz.layer = 25

	add_child(capa_interfaz)

	panel_vida = PanelContainer.new()

	capa_interfaz.add_child(
		panel_vida
	)

	panel_vida.anchor_left = 0.5
	panel_vida.anchor_right = 0.5

	panel_vida.anchor_top = 0.0
	panel_vida.anchor_bottom = 0.0

	panel_vida.offset_left = -220.0
	panel_vida.offset_right = 220.0

	panel_vida.offset_top = 20.0
	panel_vida.offset_bottom = 145.0

	panel_vida.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	var columna: VBoxContainer = (
		VBoxContainer.new()
	)

	panel_vida.add_child(
		columna
	)

	columna.add_theme_constant_override(
		"separation",
		6
	)

	var titulo: Label = Label.new()

	titulo.text = (
        "DON PALOMO - REY DE LA PLAZA"
	)

	titulo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	columna.add_child(titulo)

	etiqueta_fase = Label.new()

	etiqueta_fase.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	columna.add_child(etiqueta_fase)

	barra_vida = ProgressBar.new()

	barra_vida.custom_minimum_size = (
		Vector2(380, 25)
	)

	barra_vida.min_value = 0

	barra_vida.max_value = maxi(
		vida_maxima,
		1
	)

	barra_vida.value = maxi(
		vida_maxima,
		1
	)

	barra_vida.show_percentage = false

	columna.add_child(barra_vida)

	etiqueta_ataque = Label.new()

	etiqueta_ataque.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	etiqueta_ataque.add_theme_color_override(
		"font_color",
		Color("#FF5252")
	)

	columna.add_child(
		etiqueta_ataque
	)

	etiqueta_ataque.text = ""

	panel_vida.hide()


# ==========================================
# ACTUALIZAR INTERFAZ
# ==========================================

func actualizar_interfaz_vida() -> void:

	if barra_vida != null:

		barra_vida.max_value = maxi(
			vida_maxima,
			1
		)

		barra_vida.value = vida_actual

	if etiqueta_fase != null:

		etiqueta_fase.text = (
			obtener_nombre_fase()
		)

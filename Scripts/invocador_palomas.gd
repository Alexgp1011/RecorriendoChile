
extends Node3D

# ==========================================
# INVOCADOR DE PALOMAS
# CONTROLA LOS REFUERZOS DE DON PALOMO
# ==========================================

@export var activar_refuerzos: bool = true

# Referencias asignadas en Inspector
@export var jefe: Node3D
@export var escena_paloma: PackedScene


# ==========================================
# CANTIDAD DE ENEMIGOS
# ==========================================

@export var maximo_simultaneas: int = 4

@export var palomas_por_oleada_fase_2: int = 2
@export var palomas_por_oleada_fase_3: int = 3


# ==========================================
# TIEMPOS ENTRE OLEADAS
# ==========================================

@export var intervalo_oleadas_fase_2: float = 14.0
@export var intervalo_oleadas_fase_3: float = 10.0


# ==========================================
# POSICIONES DE APARICION
# ==========================================

@export var radio_aparicion_minimo: float = 4.0
@export var radio_aparicion_maximo: float = 7.0

@export var altura_aparicion: float = 3.5

@export var extension_arena: float = 16.0


# ==========================================
# VARIABLES
# ==========================================

var jugador: CharacterBody3D = null

var fase_actual: int = 0

var reloj_oleadas: float = 0.0

var combate_anterior_activo: bool = false


# ==========================================
# INICIAR INVOCADOR
# ==========================================

func _ready() -> void:

	randomize()

	if jefe == null:

		jefe = (
			get_node_or_null("../DonPalomo")
			as Node3D
		)

	buscar_jugador()

	if jefe == null:

		push_error(
            "INVOCADOR: No se encontro DonPalomo"
		)

		set_physics_process(false)
		return

	if jefe.has_signal("fase_cambiada"):

		jefe.connect(
			"fase_cambiada",
			Callable(self, "al_cambiar_fase")
		)

	else:

		push_warning(
            "INVOCADOR: El jefe no tiene "
			+ "la senal fase_cambiada"
		)

	if escena_paloma == null:

		push_warning(
            "INVOCADOR: Asigna PalomaPequena.tscn "
			+ "en el Inspector"
		)

	print("INVOCADOR: Sistema preparado")


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
# PROCESO PRINCIPAL
# ==========================================

func _physics_process(delta: float) -> void:

	if not is_instance_valid(jefe):
		return

	var combate_activo: bool = (
		jefe.get("combate_activo") == true
	)

	# Si Don Palomo fue derrotado,
	# eliminar todos sus refuerzos.
	if not combate_activo:

		if combate_anterior_activo:

			limpiar_palomas()

		combate_anterior_activo = false
		fase_actual = 0
		reloj_oleadas = 0.0

		return

	combate_anterior_activo = true

	# Comprobar la fase tambien por variable
	# para no depender solamente de la senal.
	var fase_jefe: int = int(
		jefe.get("fase_actual")
	)

	if fase_jefe != fase_actual:

		al_cambiar_fase(fase_jefe)

	if not activar_refuerzos:
		return

	# Fase 1 = 0
	# Fase 2 = 1
	# Fase 3 = 2
	if fase_actual < 1:
		return

	reloj_oleadas -= delta

	if reloj_oleadas <= 0.0:

		invocar_oleada()

		reloj_oleadas = (
			obtener_intervalo_oleada()
		)


# ==========================================
# DETECTAR CAMBIO DE FASE
# ==========================================

func al_cambiar_fase(nueva_fase: int) -> void:

	fase_actual = nueva_fase

	if not activar_refuerzos:
		return

	if fase_actual < 1:
		return

	if not is_instance_valid(jefe):
		return

	if jefe.get("combate_activo") != true:
		return

	print(
		"INVOCADOR: Comenzo la fase ",
		fase_actual + 1
	)

	# Crear una oleada inmediatamente
	invocar_oleada()

	reloj_oleadas = (
		obtener_intervalo_oleada()
	)


# ==========================================
# OBTENER CONFIGURACION POR FASE
# ==========================================

func obtener_cantidad_oleada() -> int:

	if fase_actual >= 2:

		return maxi(
			palomas_por_oleada_fase_3,
			0
		)

	return maxi(
		palomas_por_oleada_fase_2,
		0
	)


func obtener_intervalo_oleada() -> float:

	if fase_actual >= 2:

		return maxf(
			intervalo_oleadas_fase_3,
			1.0
		)

	return maxf(
		intervalo_oleadas_fase_2,
		1.0
	)


# ==========================================
# CONTAR PALOMAS ACTIVAS
# ==========================================

func contar_palomas_activas() -> int:

	var cantidad: int = 0

	for nodo in get_tree().get_nodes_in_group(
        "palomas_pequenas"
	):

		if not is_instance_valid(nodo):
			continue

		if nodo.is_queued_for_deletion():
			continue

		if nodo.get("muerto") == true:
			continue

		cantidad += 1

	return cantidad


# ==========================================
# INVOCAR UNA OLEADA
# ==========================================

func invocar_oleada() -> void:

	if escena_paloma == null:
		return

	if not is_instance_valid(jugador):

		buscar_jugador()

	if not is_instance_valid(jugador):
		return

	if jugador.get("dead") == true:
		return

	var disponibles: int = maxi(
		maximo_simultaneas
		- contar_palomas_activas(),
		0
	)

	if disponibles <= 0:

		print(
            "INVOCADOR: Ya hay suficientes palomas"
		)

		return

	var cantidad: int = mini(
		obtener_cantidad_oleada(),
		disponibles
	)

	for i in range(cantidad):

		crear_paloma()


# ==========================================
# CREAR PALOMA EN EL ESCENARIO
# ==========================================

func crear_paloma() -> void:

	var nueva: Node = (
		escena_paloma.instantiate()
	)

	if not (nueva is CharacterBody3D):

		push_error(
            "INVOCADOR: PalomaPequena "
			+ "debe ser CharacterBody3D"
		)

		nueva.free()
		return

	if not nueva.has_method("configurar"):

		push_error(
            "INVOCADOR: Falta configurar() "
			+ "en paloma_pequena.gd"
		)

		nueva.free()
		return

	var escena_principal: Node = (
		get_tree().current_scene
	)

	if escena_principal == null:

		nueva.free()
		return

	escena_principal.add_child(nueva)

	# Posicionar dentro de Plaza de Armas
	nueva.global_position = (
		calcular_posicion_aparicion()
	)

	# Entregarle el jugador y el centro
	nueva.call(
		"configurar",
		jugador,
		global_position
	)

	print(
		"INVOCADOR: Nueva paloma en ",
		nueva.global_position
	)


# ==========================================
# CALCULAR LUGAR DE APARICION
# ==========================================

func calcular_posicion_aparicion() -> Vector3:

	# Convertir jugador a coordenadas locales
	# del invocador, ubicado en la plaza.
	var local_jugador: Vector3 = (
		to_local(jugador.global_position)
	)

	var angulo: float = randf_range(
		0.0,
		TAU
	)

	var distancia: float = randf_range(
		radio_aparicion_minimo,
		maxf(
			radio_aparicion_maximo,
			radio_aparicion_minimo
		)
	)

	var limite: float = maxf(
		extension_arena,
		2.0
	)

	var x: float = clampf(
		local_jugador.x + cos(angulo) * distancia,
		-limite,
		limite
	)

	var z: float = clampf(
		local_jugador.z + sin(angulo) * distancia,
		-limite,
		limite
	)

	# Aparecer unos metros por encima
	# de la altura actual del protagonista.
	var y: float = maxf(
		local_jugador.y + altura_aparicion,
		2.0
	)

	return to_global(
		Vector3(x, y, z)
	)


# ==========================================
# LIMPIAR AL DERROTAR AL JEFE
# ==========================================

func limpiar_palomas() -> void:

	for nodo in get_tree().get_nodes_in_group(
        "palomas_pequenas"
	):

		if not is_instance_valid(nodo):
			continue

		if nodo.has_method("desaparecer"):

			nodo.call("desaparecer")

		else:

			nodo.queue_free()

	print(
        "INVOCADOR: Refuerzos eliminados"
	)

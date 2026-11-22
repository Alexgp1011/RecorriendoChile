
extends Area3D

# ==========================================
# EXCREMENTO DE DON PALOMO
# ADVERTENCIA, CAIDA E IMPACTO
# ==========================================

@export var dano: int = 20
@export var radio_impacto: float = 1.5

@export var tiempo_advertencia: float = 1.1
@export var tiempo_caida: float = 0.75
@export var tiempo_marca: float = 0.4


# ==========================================
# ESTADOS
# ==========================================

enum Fase {
	INACTIVO,
	ADVERTENCIA,
	CAYENDO,
	IMPACTO
}

var fase_actual: Fase = Fase.INACTIVO

var tiempo_actual: float = 0.0

var jugador: CharacterBody3D = null

var posicion_inicial: Vector3 = Vector3.ZERO


# ==========================================
# NODOS GENERADOS
# ==========================================

var colision: CollisionShape3D
var indicador: MeshInstance3D
var proyectil: MeshInstance3D
var mancha: MeshInstance3D


# ==========================================
# INICIAR ESCENA
# ==========================================

func _ready() -> void:

	collision_layer = 0
	collision_mask = 1

	monitoring = true
	monitorable = false

	add_to_group("proyectiles_don_palomo")

	crear_colision()
	crear_indicador()
	crear_proyectil()
	crear_mancha()

	indicador.hide()
	proyectil.hide()
	mancha.hide()


# ==========================================
# CREAR COLISION
# ==========================================

func crear_colision() -> void:

	colision = CollisionShape3D.new()
	colision.name = "CollisionShape3D"

	add_child(colision)

	var esfera: SphereShape3D = SphereShape3D.new()

	esfera.radius = maxf(
		radio_impacto,
		0.1
	)

	colision.shape = esfera

	# La esfera cubre la altura del jugador
	colision.position = Vector3(0.0, 0.85, 0.0)


# ==========================================
# CREAR CIRCULO ROJO DE ADVERTENCIA
# ==========================================

func crear_indicador() -> void:

	indicador = MeshInstance3D.new()
	indicador.name = "IndicadorRojo"

	add_child(indicador)

	var disco: CylinderMesh = CylinderMesh.new()

	disco.top_radius = radio_impacto
	disco.bottom_radius = radio_impacto
	disco.height = 0.03

	indicador.mesh = disco

	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)

	material.albedo_color = Color(
		1.0,
		0.08,
		0.08,
		0.38
	)

	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)

	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	material.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)

	indicador.material_override = material

	indicador.position = Vector3(
		0.0,
		0.045,
		0.0
	)

	indicador.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)


# ==========================================
# CREAR PROYECTIL
# ==========================================

func crear_proyectil() -> void:

	proyectil = MeshInstance3D.new()
	proyectil.name = "Proyectil"

	add_child(proyectil)

	var esfera: SphereMesh = SphereMesh.new()

	esfera.radius = 0.35
	esfera.height = 0.7

	proyectil.mesh = esfera

	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)

	material.albedo_color = Color(
		0.40,
		0.37,
		0.20
	)

	material.roughness = 1.0

	proyectil.material_override = material

	proyectil.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)


# ==========================================
# CREAR MANCHA DEL IMPACTO
# ==========================================

func crear_mancha() -> void:

	mancha = MeshInstance3D.new()
	mancha.name = "ManchaImpacto"

	add_child(mancha)

	var disco: CylinderMesh = CylinderMesh.new()

	disco.top_radius = radio_impacto * 0.7
	disco.bottom_radius = radio_impacto * 0.7
	disco.height = 0.04

	mancha.mesh = disco

	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)

	material.albedo_color = Color(
		0.30,
		0.28,
		0.14,
		0.85
	)

	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)

	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	mancha.material_override = material

	mancha.position = Vector3(
		0.0,
		0.06,
		0.0
	)

	mancha.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)


# ==========================================
# CONFIGURAR NUEVO ATAQUE
# ==========================================

func configurar_ataque(
	origen: Vector3,
	destino: Vector3,
	objetivo: CharacterBody3D
) -> void:

	jugador = objetivo

	# La escena queda centrada en el
	# punto donde caera el excremento
	global_position = destino

	# Guardar el punto de partida
	# del proyectil respecto al impacto
	posicion_inicial = origen - destino

	proyectil.position = posicion_inicial

	# Detectar la capa real del jugador
	if is_instance_valid(jugador):

		collision_mask = jugador.collision_layer

	tiempo_actual = 0.0

	fase_actual = Fase.ADVERTENCIA

	indicador.show()
	proyectil.hide()
	mancha.hide()

	print(
		"PALOMO: Advertencia en ",
		destino
	)


# ==========================================
# CONTROLAR ATAQUE
# ==========================================

func _physics_process(delta: float) -> void:

	match fase_actual:

		Fase.ADVERTENCIA:

			actualizar_advertencia(delta)

		Fase.CAYENDO:

			actualizar_caida(delta)

		Fase.IMPACTO:

			actualizar_mancha(delta)


# ==========================================
# ADVERTENCIA ROJA
# ==========================================

func actualizar_advertencia(delta: float) -> void:

	tiempo_actual += delta

	# Efecto de pulso
	var pulso: float = (
		1.0 + sin(tiempo_actual * 9.0) * 0.05
	)

	indicador.scale = Vector3(
		pulso,
		1.0,
		pulso
	)

	if tiempo_actual >= tiempo_advertencia:

		tiempo_actual = 0.0

		fase_actual = Fase.CAYENDO

		proyectil.show()

		print("PALOMO: Proyectil cayendo")


# ==========================================
# CAIDA DEL PROYECTIL
# ==========================================

func actualizar_caida(delta: float) -> void:

	tiempo_actual += delta

	var progreso: float = clampf(
		tiempo_actual / maxf(tiempo_caida, 0.05),
		0.0,
		1.0
	)

	var posicion_final: Vector3 = Vector3(
		0.0,
		0.2,
		0.0
	)

	proyectil.position = posicion_inicial.lerp(
		posicion_final,
		progreso
	)

	if progreso >= 1.0:

		realizar_impacto()


# ==========================================
# IMPACTO EN EL SUELO
# ==========================================

func realizar_impacto() -> void:

	# Cambiar estado antes de aplicar dano
	# para evitar impactos repetidos
	fase_actual = Fase.IMPACTO

	tiempo_actual = 0.0

	indicador.hide()
	proyectil.hide()
	mancha.show()

	comprobar_dano()

	print("PALOMO: Impacto en el suelo")


# ==========================================
# COMPROBAR SI ALCANZO AL JUGADOR
# ==========================================

func comprobar_dano() -> void:

	if not is_instance_valid(jugador):
		return

	if jugador.get("dead") == true:
		return

	# Consultar la colision en el instante
	# exacto del impacto
	var consulta: PhysicsShapeQueryParameters3D = (
		PhysicsShapeQueryParameters3D.new()
	)

	consulta.shape = colision.shape

	consulta.transform = Transform3D(
		Basis(),
		global_position + colision.position
	)

	consulta.collision_mask = collision_mask

	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false

	var resultados: Array[Dictionary] = (
		get_world_3d().direct_space_state.intersect_shape(
			consulta,
			32
		)
	)

	var jugador_alcanzado: bool = false

	for resultado in resultados:

		if resultado.get("collider") == jugador:

			jugador_alcanzado = true
			break

	if not jugador_alcanzado:

		print("PALOMO: El jugador esquivo el ataque")
		return

	# Comprobar si existe una pared,
	# jardinera u otra cobertura
	if not hay_linea_de_impacto():

		print("PALOMO: Ataque bloqueado por cobertura")
		return

	aplicar_dano()


# ==========================================
# COMPROBAR COBERTURA
# ==========================================

func hay_linea_de_impacto() -> bool:

	if not is_instance_valid(jugador):
		return false

	var origen: Vector3 = (
		global_position + Vector3.UP * 0.55
	)

	var destino: Vector3 = (
		jugador.global_position + Vector3.UP * 0.2
	)

	if origen.distance_to(destino) < 0.35:
		return true

	var consulta: PhysicsRayQueryParameters3D = (
		PhysicsRayQueryParameters3D.create(
			origen,
			destino
		)
	)

	consulta.collide_with_areas = false

	var resultado: Dictionary = (
		get_world_3d().direct_space_state.intersect_ray(
			consulta
		)
	)

	if resultado.is_empty():
		return true

	return resultado.get("collider") == jugador


# ==========================================
# APLICAR DANO EXISTENTE
# ==========================================

func aplicar_dano() -> void:

	if not is_instance_valid(jugador):
		return

	# Reutilizar el sistema de salud
	# que usan los manifestantes
	var salud: Node = jugador.get_node_or_null(
        "Salud"
	)

	if salud == null:

		push_warning(
            "PALOMO: El jugador no tiene nodo Salud"
		)

		return

	if salud.has_method("recibir_dano"):

		salud.call(
			"recibir_dano",
			dano
		)

		print(
			"PALOMO: El jugador recibio ",
			dano,
            " puntos de dano"
		)

	else:

		push_warning(
            "PALOMO: Salud no tiene recibir_dano()"
		)


# ==========================================
# DESAPARECER DESPUES DEL IMPACTO
# ==========================================

func actualizar_mancha(delta: float) -> void:

	tiempo_actual += delta

	if tiempo_actual >= tiempo_marca:

		queue_free()

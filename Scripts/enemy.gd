
extends CharacterBody3D

# ==========================================
# LADRON DEL PASEO AHUMADA
# PERSECUCION, ROBO Y HUIDA ESTABLE
# ==========================================

@export var move_speed: float = 2.5
@export var velocidad_escape: float = 6.0
@export var attack_range: float = 1.5

# ROBO
@export_range(0.0, 1.0, 0.05) var porcentaje_robo: float = 0.35
@export var minimo_robo: int = 500
@export var maximo_robo: int = 25000
@export var unidad_redondeo: int = 500
## Segundos que el ladron mantiene la pose de embestida (animacion "robo")
## antes de salir corriendo. 0 = huye de inmediato, como antes.
@export var duracion_embestida: float = 0.35

# HUIDA
@export var distancia_llegada: float = 1.5
@export var distancia_minima_escape: float = 8.0
@export var tiempo_escondido: float = 12.0
@export var radio_reactivacion: float = 15.0

# NAVEGACION
@export var distancia_punto_ruta: float = 1.0
@export var tiempo_limite_huida: float = 15.0
@export var tiempo_atasco: float = 2.0

# DIAGNOSTICO
@export var mostrar_diagnostico: bool = false


# ==========================================
# REFERENCIAS
# ==========================================

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var death_sound = $deathsound

@onready var agente: NavigationAgent3D = get_node_or_null(
    "NavigationAgent3D"
) as NavigationAgent3D


# ==========================================
# ESTADOS
# ==========================================

enum Estado {
	PERSEGUIR,
	ESCAPAR,
	ESCONDIDO,
	MUERTO
}

var estado_actual: Estado = Estado.PERSEGUIR

var dead: bool = false
var player: CharacterBody3D = null

var gravedad: float = 9.8


# ==========================================
# VARIABLES DE HUIDA
# ==========================================

var puntos_escape: Array[Marker3D] = []

var destino_escape: Vector3 = Vector3.ZERO

var ruta_escape: PackedVector3Array = PackedVector3Array()

var indice_ruta: int = 0

var ultimo_escondite: String = ""

var contador_escape: float = 0.0
var contador_atasco: float = 0.0
var contador_escondido: float = 0.0
var contador_diagnostico: float = 0.0
var contador_embestida: float = 0.0


# ==========================================
# INTERFAZ DE ROBO
# ==========================================

var mensaje_robo: Label = null
var tiempo_mensaje: float = 0.0


# ==========================================
# INICIAR LADRON
# ==========================================

func _ready() -> void:

	gravedad = float(
		ProjectSettings.get_setting(
            "physics/3d/default_gravity"
		)
	)

	buscar_jugador()
	cargar_puntos_escape()
	crear_mensaje_robo()

	if agente != null:

		agente.avoidance_enabled = false
		agente.navigation_layers = 1

		print("LADRON: Navegacion disponible")

	else:

		push_warning(
            "LADRON: Falta NavigationAgent3D"
		)

	print("LADRON: Sistema iniciado")


# ==========================================
# BUSCAR JUGADOR
# ==========================================

func buscar_jugador() -> void:

	var encontrado: Node = (
		get_tree().get_first_node_in_group("player")
	)

	if encontrado == null:

		encontrado = (
			get_tree().get_first_node_in_group("jugador")
		)

	if encontrado is CharacterBody3D:

		player = encontrado as CharacterBody3D

	else:

		player = null

		push_warning("LADRON: Jugador no encontrado")


# ==========================================
# CARGAR ESCONDITES
# ==========================================

func cargar_puntos_escape() -> void:

	puntos_escape.clear()

	var contenedor: Node = (
		get_tree().get_first_node_in_group(
            "puntos_huida_ladron"
		)
	)

	if contenedor == null:

		var escena: Node = get_tree().current_scene

		if escena != null:

			contenedor = escena.get_node_or_null(
                "PuntosHuidaLadron"
			)

	if contenedor == null:

		push_warning(
            "LADRON: No existen puntos de huida"
		)

		return

	for hijo in contenedor.get_children():

		if hijo is Marker3D:

			puntos_escape.append(
				hijo as Marker3D
			)

	print(
		"LADRON: Escondites encontrados: ",
		puntos_escape.size()
	)


# ==========================================
# FISICA PRINCIPAL
# ==========================================

func _physics_process(delta: float) -> void:

	if dead:
		return

	if not is_instance_valid(player):
		buscar_jugador()

	# GRAVEDAD
	if not is_on_floor():

		velocity.y -= gravedad * delta

	else:

		velocity.y = 0.0

	# ESTADOS
	match estado_actual:

		Estado.PERSEGUIR:

			perseguir_jugador()

		Estado.ESCAPAR:

			escapar_del_jugador(delta)

		Estado.ESCONDIDO:

			permanecer_escondido(delta)

		Estado.MUERTO:

			detener_movimiento()

	# GUARDAR POSICION ANTES DE MOVERSE
	var posicion_previa: Vector3 = global_position

	# MOVIMIENTO FISICO
	move_and_slide()

	# COMPROBAR SI ESTA ATASCADO
	if estado_actual == Estado.ESCAPAR:

		var avance: Vector3 = (
			global_position - posicion_previa
		)

		avance.y = 0.0

		if avance.length() < 0.02:

			contador_atasco += delta

		else:

			contador_atasco = 0.0

		if contador_atasco >= tiempo_atasco:

			print(
                "LADRON: Obstaculo detectado. "
				+ "Buscando otra ruta."
			)

			contador_atasco = 0.0

			elegir_ruta_escape()

	# DIAGNOSTICO
	if mostrar_diagnostico:

		contador_diagnostico += delta

		if contador_diagnostico >= 1.0:

			contador_diagnostico = 0.0

			print(
				"LADRON: Estado ",
				Estado.keys()[estado_actual]
			)

			print(
				"Posicion: ",
				global_position
			)

			print(
				"Velocidad: ",
				velocity
			)


# ==========================================
# PROCESO DE INTERFAZ
# ==========================================

func _process(delta: float) -> void:

	if tiempo_mensaje > 0.0:

		tiempo_mensaje -= delta

		if tiempo_mensaje <= 0.0:

			if mensaje_robo != null:

				mensaje_robo.hide()


# ==========================================
# PERSEGUIR JUGADOR
# ==========================================

func perseguir_jugador() -> void:

	if not is_instance_valid(player):

		detener_movimiento()
		return

	if player.get("dead") == true:

		detener_movimiento()
		reproducir_idle()
		return

	# No interferir con Pepito o la tienda
	if player.process_mode == Node.PROCESS_MODE_DISABLED:

		detener_movimiento()
		reproducir_idle()
		return

	var distancia: float = distancia_horizontal(
		player.global_position
	)

	# INTENTAR ROBAR
	if distancia <= attack_range:

		if puede_robar():

			realizar_robo()
			return

	# PERSECUCION DIRECTA
	# Conserva el sistema que ya funciona
	var direccion: Vector3 = (
		player.global_position - global_position
	)

	direccion.y = 0.0

	if direccion.length_squared() > 0.01:

		direccion = direccion.normalized()

		velocity.x = direccion.x * move_speed
		velocity.z = direccion.z * move_speed

		reproducir_movimiento(false)

	else:

		detener_movimiento()


# ==========================================
# COMPROBAR SI PUEDE ROBAR
# ==========================================

func puede_robar() -> bool:

	if not is_instance_valid(player):
		return false

	if distancia_horizontal(
		player.global_position
	) > attack_range:

		return false

	var altura: Vector3 = Vector3.UP

	var consulta: PhysicsRayQueryParameters3D = (
		PhysicsRayQueryParameters3D.create(
			global_position + altura,
			player.global_position + altura
		)
	)

	consulta.exclude = [get_rid()]

	var resultado: Dictionary = (
		get_world_3d().direct_space_state.intersect_ray(
			consulta
		)
	)

	if resultado.is_empty():
		return false

	return resultado.get("collider") == player


# ==========================================
# REALIZAR ROBO
# ==========================================

func realizar_robo() -> void:

	var dinero: int = maxi(
		EstadoJuego.dinero,
		0
	)

	var robado: int = 0

	if dinero > 0:

		var unidad: int = maxi(
			unidad_redondeo,
			1
		)

		var calculado: int = (
			roundi(
				float(dinero)
				* porcentaje_robo
				/ float(unidad)
			) * unidad
		)

		var limite_minimo: int = mini(
			minimo_robo,
			dinero
		)

		var limite_maximo: int = maxi(
			limite_minimo,
			mini(maximo_robo, dinero)
		)

		robado = clampi(
			calculado,
			limite_minimo,
			limite_maximo
		)

		EstadoJuego.dinero -= robado

		mostrar_mensaje(
            "TE ROBARON $"
			+ formatear_pesos(robado)
			+ "!"
		)

		print("LADRON: Robo $", robado)

	else:

		mostrar_mensaje(
            "EL LADRON NO ENCONTRO DINERO!"
		)

	actualizar_mision_dinero()

	# COMENZAR HUIDA (tras la pose de embestida, si hay animacion "robo")
	comenzar_escape()
	reproducir_embestida()


# ==========================================
# ACTUALIZAR MISION
# ==========================================

func actualizar_mision_dinero() -> void:

	if (
		GestorMisiones.obtener_etapa_actual()
		== GestorMisiones.Etapa.COMPRAR_PISTOLA
	):

		if EstadoJuego.dinero < GestorMisiones.precio_pistola:

			GestorMisiones.cambiar_etapa(
				GestorMisiones.Etapa.CONSEGUIR_DINERO
			)


# ==========================================
# INICIAR HUIDA
# ==========================================

func comenzar_escape() -> void:

	estado_actual = Estado.ESCAPAR

	contador_escape = 0.0
	contador_atasco = 0.0

	# LIMPIAR RUTA ANTERIOR
	ruta_escape.clear()
	indice_ruta = 0

	# CALCULAR UNA RUTA ESTABLE
	elegir_ruta_escape()

	print("LADRON: ARRANCA A TODA VELOCIDAD!")


# ==========================================
# COMPROBAR MAPA DE NAVEGACION
# ==========================================

func obtener_mapa_navegacion() -> RID:

	if agente == null:
		return RID()

	var mapa: RID = agente.get_navigation_map()

	if NavigationServer3D.map_get_iteration_id(mapa) == 0:
		return RID()

	if NavigationServer3D.map_get_regions(mapa).is_empty():
		return RID()

	return mapa


# ==========================================
# ELEGIR RUTA DE ESCAPE
# ==========================================

func elegir_ruta_escape() -> void:

	ruta_escape.clear()
	indice_ruta = 0

	var mapa: RID = obtener_mapa_navegacion()

	var mejor_punto: Marker3D = null
	var mejor_ruta: PackedVector3Array = (
		PackedVector3Array()
	)

	var mejor_puntuacion: float = -INF

	# BUSCAR ENTRE LOS ESCONDITES EXISTENTES
	for punto in puntos_escape:

		if not is_instance_valid(punto):
			continue

		if punto.name == ultimo_escondite:
			continue

		var distancia_ladron: float = (
			distancia_entre(
				global_position,
				punto.global_position
			)
		)

		if distancia_ladron < distancia_minima_escape:
			continue

		var candidata: PackedVector3Array = (
			PackedVector3Array()
		)

		# CALCULAR CAMINO SOLO EN ESTE MOMENTO
		if mapa.is_valid():

			candidata = NavigationServer3D.map_get_path(
				mapa,
				global_position,
				punto.global_position,
				true,
				1
			)

			# DESCARTAR RUTAS SIN CAMINO UTIL
			if candidata.size() < 2:
				continue

			# COMPROBAR QUE EL FINAL SEA ALCANZABLE
			var final_ruta: Vector3 = (
				candidata[candidata.size() - 1]
			)

			if distancia_entre(
				final_ruta,
				punto.global_position
			) > 2.5:

				continue

		# PREFERIR DESTINOS LEJANOS DEL JUGADOR
		var puntuacion: float = distancia_ladron

		if is_instance_valid(player):

			puntuacion = distancia_entre(
				player.global_position,
				punto.global_position
			)

		if puntuacion > mejor_puntuacion:

			mejor_puntuacion = puntuacion

			mejor_punto = punto

			mejor_ruta = candidata

	# ======================================
	# SI ENCONTRO UNA RUTA
	# ======================================

	if mejor_punto != null:

		destino_escape = mejor_punto.global_position

		ultimo_escondite = mejor_punto.name

		ruta_escape = mejor_ruta

		# El primer punto suele ser el origen.
		if ruta_escape.size() >= 2:

			indice_ruta = 1

		else:

			indice_ruta = 0

		print(
			"LADRON: Huyendo hacia ",
			mejor_punto.name
		)

		print(
			"LADRON: Puntos de ruta: ",
			ruta_escape.size()
		)

		return

	# ======================================
	# SI NO ENCONTRO RUTA VALIDA
	# ======================================

	# Evitar que se quede cambiando de
	# direccion constantemente.
	var direccion: Vector3 = Vector3.FORWARD

	if is_instance_valid(player):

		direccion = (
			global_position - player.global_position
		)

		direccion.y = 0.0

	if direccion.length_squared() < 0.01:
		direccion = Vector3.FORWARD

	destino_escape = (
		global_position
		+ direccion.normalized() * 12.0
	)

	print(
        "LADRON: Sin ruta navegable. "
		+ "Usando escape directo."
	)


# ==========================================
# ESCAPAR SIN OSCILACIONES
# ==========================================

func escapar_del_jugador(delta: float) -> void:

	# POSE DE EMBESTIDA: quieto un instante antes de correr
	if contador_embestida > 0.0:

		contador_embestida -= delta
		contador_atasco = 0.0
		detener_movimiento()
		return

	contador_escape += delta

	# LLEGADA AL DESTINO
	if distancia_horizontal(
		destino_escape
	) <= distancia_llegada:

		llegar_al_escondite()
		return

	# EVITAR UNA HUIDA INTERMINABLE
	if contador_escape >= tiempo_limite_huida:

		print("LADRON: Finalizo intento de escape")

		llegar_al_escondite()
		return

	var siguiente: Vector3 = destino_escape

	# ======================================
	# RECORRER RUTA YA CALCULADA
	# ======================================

	if ruta_escape.size() > 0:

		var tolerancia: float = maxf(
			distancia_punto_ruta,
			velocidad_escape * delta * 1.5
		)

		# AVANZAR POR LOS PUNTOS EN ORDEN
		while indice_ruta < ruta_escape.size():

			var punto: Vector3 = (
				ruta_escape[indice_ruta]
			)

			if distancia_entre(
				global_position,
				punto
			) <= tolerancia:

				indice_ruta += 1

			else:

				break

		# UTILIZAR EL SIGUIENTE PUNTO FIJO
		if indice_ruta < ruta_escape.size():

			siguiente = ruta_escape[indice_ruta]

		else:

			# Ultimo punto de navegacion alcanzado
			if distancia_horizontal(
				destino_escape
			) <= 3.0:

				llegar_al_escondite()
				return

	# ======================================
	# MOVERSE EN UNA DIRECCION ESTABLE
	# ======================================

	var direccion: Vector3 = (
		siguiente - global_position
	)

	direccion.y = 0.0

	if direccion.length_squared() <= 0.01:

		detener_movimiento()
		return

	direccion = direccion.normalized()

	velocity.x = direccion.x * velocidad_escape
	velocity.z = direccion.z * velocidad_escape

	reproducir_movimiento(true)


# ==========================================
# LLEGAR AL ESCONDITE
# ==========================================

func llegar_al_escondite() -> void:

	estado_actual = Estado.ESCONDIDO

	contador_escondido = tiempo_escondido

	contador_escape = 0.0
	contador_atasco = 0.0

	ruta_escape.clear()

	detener_movimiento()
	reproducir_idle()

	print("LADRON: Llegue al escondite")


# ==========================================
# PERMANECER ESCONDIDO
# ==========================================

func permanecer_escondido(delta: float) -> void:

	detener_movimiento()
	reproducir_idle()

	if contador_escondido > 0.0:

		contador_escondido -= delta
		return

	if not is_instance_valid(player):
		return

	if player.get("dead") == true:
		return

	if player.process_mode == Node.PROCESS_MODE_DISABLED:
		return

	if distancia_horizontal(
		player.global_position
	) <= radio_reactivacion:

		estado_actual = Estado.PERSEGUIR

		print("LADRON: Volviendo a perseguir")


# ==========================================
# ANIMACIONES
# ==========================================

func reproducir_movimiento(escapando: bool) -> void:

	if dead:
		return

	if animated_sprite_3d.sprite_frames == null:
		return

	var nombre: String = "walk"

	if escapando:

		if animated_sprite_3d.sprite_frames.has_animation(
            "run"
		):

			nombre = "run"

	if not animated_sprite_3d.sprite_frames.has_animation(
		nombre
	):

		return

	if animated_sprite_3d.animation != nombre:

		animated_sprite_3d.play(nombre)

	elif not animated_sprite_3d.is_playing():

		animated_sprite_3d.play(nombre)


## Muestra la pose de embestida del robo durante duracion_embestida.
## Sin animacion "robo" o con duracion 0, no hace nada y huye de inmediato.
func reproducir_embestida() -> void:

	contador_embestida = 0.0

	if dead or duracion_embestida <= 0.0:
		return

	if animated_sprite_3d.sprite_frames == null:
		return

	if not animated_sprite_3d.sprite_frames.has_animation("robo"):
		return

	contador_embestida = duracion_embestida
	animated_sprite_3d.play("robo")


func reproducir_idle() -> void:

	if dead:
		return

	if animated_sprite_3d.sprite_frames == null:
		return

	if animated_sprite_3d.sprite_frames.has_animation(
        "idle"
	):

		if animated_sprite_3d.animation != "idle":

			animated_sprite_3d.play("idle")

	else:

		animated_sprite_3d.stop()


# ==========================================
# DETENER MOVIMIENTO
# ==========================================

func detener_movimiento() -> void:

	velocity.x = 0.0
	velocity.z = 0.0


# ==========================================
# DISTANCIAS HORIZONTALES
# ==========================================

func distancia_horizontal(destino: Vector3) -> float:

	return distancia_entre(
		global_position,
		destino
	)


func distancia_entre(
	origen: Vector3,
	destino: Vector3
) -> float:

	var diferencia: Vector3 = destino - origen

	diferencia.y = 0.0

	return diferencia.length()


# ==========================================
# CREAR MENSAJE DE ROBO
# ==========================================

func crear_mensaje_robo() -> void:

	var capa: CanvasLayer = CanvasLayer.new()
	capa.layer = 30

	add_child(capa)

	mensaje_robo = Label.new()

	capa.add_child(mensaje_robo)

	mensaje_robo.anchor_left = 0.5
	mensaje_robo.anchor_right = 0.5
	mensaje_robo.anchor_top = 0.0
	mensaje_robo.anchor_bottom = 0.0

	mensaje_robo.offset_left = -260.0
	mensaje_robo.offset_right = 260.0
	mensaje_robo.offset_top = 95.0
	mensaje_robo.offset_bottom = 145.0

	mensaje_robo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	mensaje_robo.add_theme_font_size_override(
		"font_size",
		25
	)

	mensaje_robo.add_theme_color_override(
		"font_color",
		Color("#FF4545")
	)

	mensaje_robo.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	mensaje_robo.hide()


# ==========================================
# MOSTRAR MENSAJE
# ==========================================

func mostrar_mensaje(texto: String) -> void:

	if mensaje_robo == null:
		return

	mensaje_robo.text = texto
	mensaje_robo.show()

	tiempo_mensaje = 3.0


# ==========================================
# FORMATEAR DINERO
# ==========================================

func formatear_pesos(cantidad: int) -> String:

	var texto: String = str(cantidad)
	var resultado: String = ""
	var contador: int = 0

	for i in range(texto.length() - 1, -1, -1):

		if contador > 0 and contador % 3 == 0:

			resultado = "." + resultado

		resultado = texto.substr(i, 1) + resultado

		contador += 1

	return resultado


# ==========================================
# MUERTE DEL LADRON
# ==========================================

func kill() -> void:

	if dead:
		return

	dead = true

	estado_actual = Estado.MUERTO

	velocity = Vector3.ZERO

	ruta_escape.clear()

	if death_sound != null:
		death_sound.play()

	if animated_sprite_3d.sprite_frames != null:

		if animated_sprite_3d.sprite_frames.has_animation(
            "death"
		):

			animated_sprite_3d.play("death")

	var colision: CollisionShape3D = get_node_or_null(
        "CollisionShape3D"
	) as CollisionShape3D

	if colision != null:

		colision.set_deferred(
			"disabled",
			true
		)

	print("LADRON: Eliminado")

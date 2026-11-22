
extends StaticBody3D

# ==========================================
# PEPITO PAGA DOBLE
# APUESTAS MANUALES Y PREMIOS REDONDOS
# ==========================================

@export var apuesta_minima: int = 500
@export var apuesta_maxima: int = 250000
@export var apuesta_sugerida: int = 1000

@export var multiplicador_premio: float = 2

# Redondear los premios al millar mas cercano
@export var unidad_redondeo: int = 1000

# Dificultad progresiva
@export var mezclas_base: int = 7
@export var maximo_mezclas: int = 16

@export var velocidad_base: float = 0.48
@export var velocidad_minima: float = 0.20

@export var tiempo_pelota_base: float = 0.9
@export var tiempo_pelota_minimo: float = 0.35

# 0 = sin limite de victorias
@export var max_victorias_antes_de_cerrar: int = 0


# ==========================================
# REFERENCIAS
# ==========================================

@onready var camara: Camera3D = $CamaraPepito
@onready var interfaz: Control = $Interfaz/Minijuego
@onready var pelota: MeshInstance3D = $Pelota

@onready var conos: Array[MeshInstance3D] = [
	$Cono0,
	$Cono1,
	$Cono2
]


# ==========================================
# ESTADO DEL MINIJUEGO
# ==========================================

var posiciones_x: Array[float] = [-0.65, 0.0, 0.65]
var orden_conos: Array[int] = [0, 1, 2]

var abierto: bool = false
var ocupado: bool = false
var puede_elegir: bool = false

var cono_ganador: int = 1

var apuesta_actual: int = 0
var apuesta_pendiente: bool = false
var numero_ronda: int = 0

var victorias_consecutivas: int = 0
var victorias_totales: int = 0
var rondas_jugadas: int = 0

var mezclas_actuales: int = 7
var velocidad_actual: float = 0.48
var tiempo_pelota_actual: float = 0.9

var animacion_actual: Tween = null


# ==========================================
# JUGADOR Y CAMARA
# ==========================================

var jugador: CharacterBody3D = null

var modo_anterior: Node.ProcessMode = (
	Node.PROCESS_MODE_INHERIT
)

var camara_anterior: Camera3D = null
var mouse_anterior: int = Input.MOUSE_MODE_CAPTURED

var hud: CanvasLayer = null
var hud_visible_anterior: bool = true


# ==========================================
# INTERFAZ
# ==========================================

var texto_saldo: Label
var texto_mensaje: Label
var texto_apuesta: LineEdit

var boton_jugar: Button
var boton_salir: Button
var botones_elegir: Array[Button] = []


# ==========================================
# INICIAR
# ==========================================

func _ready() -> void:

	randomize()

	interfaz.visible = false

	camara.look_at(
		global_position + Vector3(0.0, 1.15, 0.0),
		Vector3.UP
	)

	preparar_pelota()
	crear_interfaz()
	reiniciar_conos()

	print("PEPITO: Puesto preparado")


# ==========================================
# PREPARAR PELOTA AMARILLA
# ==========================================

func preparar_pelota() -> void:

	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)

	material.albedo_color = Color("#FFD21A")

	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	pelota.material_override = material

	pelota.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)

	pelota.visible = false


# ==========================================
# INTERACTUAR CON TECLA E
# ==========================================

func interactuar() -> void:

	if abierto or not visible:
		return

	abierto = true

	camara_anterior = get_viewport().get_camera_3d()
	mouse_anterior = Input.mouse_mode

	jugador = get_tree().get_first_node_in_group(
        "jugador"
	) as CharacterBody3D

	if jugador != null:

		modo_anterior = jugador.process_mode

		jugador.velocity = Vector3.ZERO
		jugador.process_mode = Node.PROCESS_MODE_DISABLED

		hud = jugador.get_node_or_null(
            "CanvasLayer"
		) as CanvasLayer

		if hud != null:

			hud_visible_anterior = hud.visible
			hud.visible = false

	camara.make_current()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	interfaz.visible = true

	texto_mensaje.text = (
        "Ya papito, con platita baila el mono"
	)

	actualizar_interfaz()


# ==========================================
# CREAR INTERFAZ
# ==========================================

func crear_interfaz() -> void:

	interfaz.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	var panel: PanelContainer = PanelContainer.new()
	interfaz.add_child(panel)

	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0

	panel.offset_left = -350.0
	panel.offset_right = 350.0
	panel.offset_top = -260.0
	panel.offset_bottom = -15.0

	var margen: MarginContainer = MarginContainer.new()
	panel.add_child(margen)

	margen.add_theme_constant_override(
		"margin_left", 15
	)

	margen.add_theme_constant_override(
		"margin_right", 15
	)

	margen.add_theme_constant_override(
		"margin_top", 10
	)

	margen.add_theme_constant_override(
		"margin_bottom", 10
	)

	var columna: VBoxContainer = VBoxContainer.new()
	margen.add_child(columna)

	columna.add_theme_constant_override(
		"separation", 8
	)

	var titulo: Label = Label.new()

	titulo.text = "PEPITO PAGA DOBLE"
	titulo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	columna.add_child(titulo)

	texto_saldo = Label.new()

	texto_saldo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	columna.add_child(texto_saldo)

	texto_mensaje = Label.new()

	texto_mensaje.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	columna.add_child(texto_mensaje)

	# ======================================
	# APUESTA MANUAL
	# ======================================

	var fila_apuesta: HBoxContainer = HBoxContainer.new()
	columna.add_child(fila_apuesta)

	var etiqueta: Label = Label.new()
	etiqueta.text = "TU APUESTA: $"

	fila_apuesta.add_child(etiqueta)

	texto_apuesta = LineEdit.new()

	texto_apuesta.text = str(apuesta_sugerida)
	texto_apuesta.placeholder_text = "Ejemplo: 10000"
	texto_apuesta.max_length = 9

	texto_apuesta.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	fila_apuesta.add_child(texto_apuesta)

	texto_apuesta.text_changed.connect(
		al_cambiar_apuesta
	)

	# ======================================
	# BOTONES DE CONOS
	# ======================================

	var fila_conos: HBoxContainer = HBoxContainer.new()
	columna.add_child(fila_conos)

	for i in range(3):

		var boton: Button = Button.new()

		boton.text = [
			"IZQUIERDA",
			"CENTRO",
            "DERECHA"
		][i]

		boton.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

		boton.disabled = true

		fila_conos.add_child(boton)
		botones_elegir.append(boton)

	botones_elegir[0].pressed.connect(
		elegir_izquierda
	)

	botones_elegir[1].pressed.connect(
		elegir_centro
	)

	botones_elegir[2].pressed.connect(
		elegir_derecha
	)

	# ======================================
	# APOSTAR Y SALIR
	# ======================================

	var acciones: HBoxContainer = HBoxContainer.new()
	columna.add_child(acciones)

	boton_jugar = Button.new()
	boton_jugar.text = "APOSTAR"

	boton_jugar.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	boton_jugar.pressed.connect(iniciar_ronda)
	acciones.add_child(boton_jugar)

	boton_salir = Button.new()
	boton_salir.text = "SALIR"

	boton_salir.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	boton_salir.pressed.connect(cerrar_minijuego)
	acciones.add_child(boton_salir)


# ==========================================
# FORMATEAR PESOS CHILENOS
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
# VALIDAR APUESTA MANUAL
# ==========================================

func obtener_apuesta() -> int:

	var entrada: String = texto_apuesta.text.strip_edges()

	entrada = entrada.replace(".", "")
	entrada = entrada.replace(" ", "")
	entrada = entrada.replace("$", "")

	if not entrada.is_valid_int():
		return 0

	var cantidad: int = int(entrada)

	if cantidad < apuesta_minima:
		return 0

	if cantidad > apuesta_maxima:
		return 0

	if cantidad > EstadoJuego.dinero:
		return 0

	return cantidad


func al_cambiar_apuesta(_texto: String) -> void:

	if not ocupado and not puede_elegir:
		actualizar_interfaz()


# ==========================================
# CALCULAR PREMIO REDONDEADO
# ==========================================

func calcular_premio(apuesta: int) -> int:

	var unidad: int = maxi(
		unidad_redondeo,
		1
	)

	var premio_original: float = (
		float(apuesta) * multiplicador_premio
	)

	var premio_redondeado: int = (
		roundi(
			premio_original / float(unidad)
		) * unidad
	)

	return maxi(premio_redondeado, 0)


# ==========================================
# ACTUALIZAR INTERFAZ
# ==========================================

func actualizar_interfaz() -> void:

	var cantidad: int = obtener_apuesta()

	texto_saldo.text = (
        "DINERO: $"
		+ formatear_pesos(EstadoJuego.dinero)
		+ " | MAXIMO: $"
		+ formatear_pesos(apuesta_maxima)
	)

	texto_apuesta.editable = (
		not ocupado and not puede_elegir
	)

	var limite_alcanzado: bool = (
		max_victorias_antes_de_cerrar > 0
		and victorias_totales >= max_victorias_antes_de_cerrar
	)

	boton_jugar.disabled = (
		ocupado
		or puede_elegir
		or cantidad == 0
		or limite_alcanzado
	)

	if cantidad > 0:

		boton_jugar.text = (
            "APOSTAR $"
			+ formatear_pesos(cantidad)
		)

	else:

		boton_jugar.text = "APUESTA NO VALIDA"

	boton_salir.disabled = ocupado or puede_elegir

	for boton in botones_elegir:
		boton.disabled = not puede_elegir


# ==========================================
# DIFICULTAD PROGRESIVA
# ==========================================

func recalcular_dificultad() -> void:

	mezclas_actuales = mini(
		maximo_mezclas,
		mezclas_base
		+ victorias_consecutivas * 2
		+ int(rondas_jugadas / 2.0)
	)

	velocidad_actual = maxf(
		velocidad_minima,
		velocidad_base
		- victorias_consecutivas * 0.06
		- rondas_jugadas * 0.015
	)

	tiempo_pelota_actual = maxf(
		tiempo_pelota_minimo,
		tiempo_pelota_base
		- victorias_consecutivas * 0.12
		- rondas_jugadas * 0.02
	)


# ==========================================
# REINICIAR CONOS
# ==========================================

func reiniciar_conos() -> void:

	orden_conos = [0, 1, 2]

	for i in range(3):

		conos[i].position = Vector3(
			posiciones_x[i],
			1.24,
			0.0
		)

	pelota.position = Vector3(
		0.0,
		1.18,
		0.0
	)

	pelota.visible = false


# ==========================================
# INICIAR RONDA
# ==========================================

func iniciar_ronda() -> void:

	if not abierto or ocupado or puede_elegir:
		return

	var cantidad: int = obtener_apuesta()

	if cantidad == 0:

		texto_mensaje.text = (
            "Revisa tu apuesta y tu dinero."
		)

		actualizar_interfaz()
		return

	if max_victorias_antes_de_cerrar > 0:

		if victorias_totales >= max_victorias_antes_de_cerrar:

			texto_mensaje.text = (
                "Uii Me echo el poollo papito"
			)

			return

	ocupado = true
	puede_elegir = false

	numero_ronda += 1

	var ronda_id: int = numero_ronda

	apuesta_actual = cantidad

	recalcular_dificultad()
	reiniciar_conos()

	# Descontar apuesta
	EstadoJuego.dinero -= apuesta_actual
	apuesta_pendiente = true

	actualizar_interfaz()

	# Elegir cono ganador
	cono_ganador = randi_range(0, 2)

	pelota.position = Vector3(
		posiciones_x[cono_ganador],
		1.18,
		0.0
	)

	pelota.visible = true

	texto_mensaje.text = "Mira bien la pelotita!"

	await mover_altura(
		conos[cono_ganador],
		1.78,
		0.25
	)

	if not ronda_valida(ronda_id):
		return

	await get_tree().create_timer(
		tiempo_pelota_actual
	).timeout

	if not ronda_valida(ronda_id):
		return

	await mover_altura(
		conos[cono_ganador],
		1.24,
		0.22
	)

	if not ronda_valida(ronda_id):
		return

	pelota.visible = false

	texto_mensaje.text = "Sigue la pelotita"

	# Mezclas progresivas
	for i in range(mezclas_actuales):

		var a: int = randi_range(0, 2)
		var b: int = randi_range(0, 2)

		while a == b:
			b = randi_range(0, 2)

		await intercambiar_conos(a, b)

		if not ronda_valida(ronda_id):
			return

		await get_tree().create_timer(0.08).timeout

		if not ronda_valida(ronda_id):
			return

	ocupado = false
	puede_elegir = true

	texto_mensaje.text = "Donde quedo la caprichosa?"

	actualizar_interfaz()


# ==========================================
# COMPROBAR RONDA
# ==========================================

func ronda_valida(id: int) -> bool:

	return (
		abierto
		and apuesta_pendiente
		and id == numero_ronda
	)


# ==========================================
# LEVANTAR Y BAJAR CONOS
# ==========================================

func mover_altura(
	cono: MeshInstance3D,
	altura: float,
	duracion: float
) -> void:

	animacion_actual = create_tween()

	animacion_actual.tween_property(
		cono,
		"position:y",
		altura,
		duracion
	).set_trans(Tween.TRANS_SINE)

	await animacion_actual.finished


# ==========================================
# MEZCLAR DOS CONOS
# ==========================================

func intercambiar_conos(a: int, b: int) -> void:

	var id_a: int = orden_conos[a]
	var id_b: int = orden_conos[b]

	var cono_a: MeshInstance3D = conos[id_a]
	var cono_b: MeshInstance3D = conos[id_b]

	var destino_a: Vector3 = Vector3(
		posiciones_x[b],
		1.24,
		-0.28
	)

	var destino_b: Vector3 = Vector3(
		posiciones_x[a],
		1.24,
		0.28
	)

	animacion_actual = create_tween()

	animacion_actual.set_parallel(true)

	animacion_actual.tween_property(
		cono_a,
		"position",
		destino_a,
		velocidad_actual
	).set_trans(Tween.TRANS_SINE)

	animacion_actual.tween_property(
		cono_b,
		"position",
		destino_b,
		velocidad_actual
	).set_trans(Tween.TRANS_SINE)

	await animacion_actual.finished

	cono_a.position = Vector3(
		posiciones_x[b],
		1.24,
		0.0
	)

	cono_b.position = Vector3(
		posiciones_x[a],
		1.24,
		0.0
	)

	orden_conos[a] = id_b
	orden_conos[b] = id_a


# ==========================================
# ELEGIR CONOS
# ==========================================

func elegir_izquierda() -> void:

	elegir_cono(0)


func elegir_centro() -> void:

	elegir_cono(1)


func elegir_derecha() -> void:

	elegir_cono(2)


# ==========================================
# COMPROBAR RESULTADO
# ==========================================

func elegir_cono(posicion_elegida: int) -> void:

	if not abierto or not puede_elegir or ocupado:
		return

	ocupado = true
	puede_elegir = false

	var ronda_id: int = numero_ronda

	actualizar_interfaz()

	var posicion_correcta: int = (
		orden_conos.find(cono_ganador)
	)

	var acerto: bool = (
		posicion_elegida == posicion_correcta
	)

	pelota.position = Vector3(
		posiciones_x[posicion_correcta],
		1.18,
		0.0
	)

	# Mostrar cono incorrecto primero
	if not acerto:

		var elegido: MeshInstance3D = (
			conos[orden_conos[posicion_elegida]]
		)

		await mover_altura(elegido, 1.78, 0.25)

		if not ronda_valida(ronda_id):
			return

		await get_tree().create_timer(0.5).timeout

		if not ronda_valida(ronda_id):
			return

		await mover_altura(elegido, 1.24, 0.2)

		if not ronda_valida(ronda_id):
			return

	# Revelar pelota
	var ganador: MeshInstance3D = conos[cono_ganador]

	await mover_altura(ganador, 1.78, 0.3)

	if not ronda_valida(ronda_id):
		return

	pelota.visible = true

	# Resultado definitivo
	apuesta_pendiente = false
	rondas_jugadas += 1

	if acerto:

		# NUEVO: Premio redondeado a miles
		var premio: int = calcular_premio(
			apuesta_actual
		)

		EstadoJuego.dinero += premio

		victorias_consecutivas += 1
		victorias_totales += 1

		texto_mensaje.text = (
            "GANASTE! Premio: $"
			+ formatear_pesos(premio)
		)

		print(
			"PEPITO: Premio entregado: $",
			formatear_pesos(premio)
		)

	else:

		victorias_consecutivas = 0

		texto_mensaje.text = (
            "PERDISTE! Estaba en el cono "
			+ str(posicion_correcta + 1)
		)

	apuesta_actual = 0
	ocupado = false

	actualizar_interfaz()


# ==========================================
# INTERRUPCION POLICIAL
# ==========================================

func interrumpir_por_policia() -> void:

	print("PEPITO: LOS PACOS! ARRANCA!")

	# Invalidar ronda
	numero_ronda += 1

	if animacion_actual != null:

		if animacion_actual.is_valid():
			animacion_actual.kill()

	# Devolver apuesta pendiente exacta
	if apuesta_pendiente:

		EstadoJuego.dinero += apuesta_actual

		print(
			"PEPITO: Apuesta devuelta: $",
			formatear_pesos(apuesta_actual)
		)

		apuesta_pendiente = false

	apuesta_actual = 0
	ocupado = false
	puede_elegir = false

	if abierto:
		finalizar_interaccion()
	else:
		reiniciar_conos()


# ==========================================
# SALIR DEL MINIJUEGO
# ==========================================

func cerrar_minijuego() -> void:

	if ocupado or puede_elegir:
		return

	finalizar_interaccion()


# ==========================================
# RESTAURAR MODO FPS
# ==========================================

func finalizar_interaccion() -> void:

	if not abierto:
		return

	abierto = false
	interfaz.visible = false

	if is_instance_valid(camara_anterior):
		camara_anterior.make_current()

	if is_instance_valid(jugador):

		jugador.velocity = Vector3.ZERO
		jugador.process_mode = modo_anterior

	if is_instance_valid(hud):
		hud.visible = hud_visible_anterior

	Input.mouse_mode = mouse_anterior

	reiniciar_conos()

	print("PEPITO: Volviendo al Paseo Ahumada")


extends StaticBody3D

# ==========================================
# VENDEDOR DE BALINES
# ==========================================

var abierto: bool = false

var jugador: CharacterBody3D = null

var modo_anterior: Node.ProcessMode = (
	Node.PROCESS_MODE_INHERIT
)

var mouse_anterior: int = Input.MOUSE_MODE_CAPTURED

var hud: CanvasLayer = null
var hud_visible_anterior: bool = true


# ==========================================
# INTERFAZ
# ==========================================

var capa_interfaz: CanvasLayer
var panel_principal: Control

var texto_dinero: Label
var texto_mensaje: Label

var boton_comprar: Button
var boton_salir: Button


# ==========================================
# INICIAR VENDEDOR
# ==========================================

func _ready() -> void:

	crear_interfaz()

	print("TIENDA: Vendedor preparado")


# ==========================================
# INTERACTUAR CON E
# ==========================================

func interactuar() -> void:

	if abierto:
		return

	abierto = true

	mouse_anterior = Input.mouse_mode

	jugador = get_tree().get_first_node_in_group(
        "jugador"
	) as CharacterBody3D

	if jugador != null:

		modo_anterior = jugador.process_mode

		jugador.velocity = Vector3.ZERO

		jugador.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)

		hud = jugador.get_node_or_null(
            "CanvasLayer"
		) as CanvasLayer

		if hud != null:

			hud_visible_anterior = hud.visible
			hud.visible = false

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	panel_principal.visible = true

	actualizar_panel()

	print("TIENDA: Jugador hablando con vendedor")


# ==========================================
# CREAR INTERFAZ
# ==========================================

func crear_interfaz() -> void:

	capa_interfaz = CanvasLayer.new()
	capa_interfaz.layer = 20

	add_child(capa_interfaz)

	panel_principal = Control.new()

	capa_interfaz.add_child(panel_principal)

	panel_principal.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	panel_principal.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	var centro: CenterContainer = CenterContainer.new()
	panel_principal.add_child(centro)

	centro.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	var panel: PanelContainer = PanelContainer.new()

	panel.custom_minimum_size = Vector2(500, 220)

	centro.add_child(panel)

	var margen: MarginContainer = MarginContainer.new()
	panel.add_child(margen)

	margen.add_theme_constant_override(
		"margin_left", 20
	)

	margen.add_theme_constant_override(
		"margin_right", 20
	)

	margen.add_theme_constant_override(
		"margin_top", 15
	)

	margen.add_theme_constant_override(
		"margin_bottom", 15
	)

	var columna: VBoxContainer = VBoxContainer.new()

	margen.add_child(columna)

	columna.add_theme_constant_override(
		"separation", 12
	)

	var titulo: Label = Label.new()

	titulo.text = "TIENDA DE BALINES - TERCER PISO"

	titulo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	columna.add_child(titulo)

	texto_dinero = Label.new()

	texto_dinero.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	columna.add_child(texto_dinero)

	texto_mensaje = Label.new()

	texto_mensaje.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	texto_mensaje.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	columna.add_child(texto_mensaje)

	var fila: HBoxContainer = HBoxContainer.new()
	columna.add_child(fila)

	boton_comprar = Button.new()

	boton_comprar.text = "COMPRAR"

	boton_comprar.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	boton_comprar.pressed.connect(
		intentar_comprar
	)

	fila.add_child(boton_comprar)

	boton_salir = Button.new()

	boton_salir.text = "SALIR"

	boton_salir.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	boton_salir.pressed.connect(
		cerrar_tienda
	)

	fila.add_child(boton_salir)

	panel_principal.visible = false


# ==========================================
# ACTUALIZAR INFORMACION
# ==========================================

func actualizar_panel() -> void:

	var precio: int = GestorMisiones.precio_pistola

	texto_dinero.text = (
        "PRECIO: $"
		+ str(precio)
		+ " | TU DINERO: $"
		+ str(EstadoJuego.dinero)
	)

	if GestorMisiones.tiene_pistola():

		texto_mensaje.text = (
            "Ya compraste la pistola, compadre. "
			+ "Cuidala!"
		)

		boton_comprar.disabled = true
		return

	var etapa: int = (
		GestorMisiones.obtener_etapa_actual()
	)

	if etapa != GestorMisiones.Etapa.COMPRAR_PISTOLA:

		if EstadoJuego.dinero < precio:

			var faltante: int = (
				precio - EstadoJuego.dinero
			)

			texto_mensaje.text = (
                "Te faltan $"
				+ str(faltante)
				+ ". Busca como conseguir dinero."
			)

		else:

			texto_mensaje.text = (
                "Primero completa los objetivos "
				+ "anteriores de la mision."
			)

		boton_comprar.disabled = true
		return

	if EstadoJuego.dinero < precio:

		texto_mensaje.text = (
            "No tienes suficiente dinero."
		)

		boton_comprar.disabled = true
		return

	texto_mensaje.text = (
        "Tienes suficiente dinero. "
		+ "Quieres comprar la pistola de balines?"
	)

	boton_comprar.disabled = false


# ==========================================
# REALIZAR COMPRA
# ==========================================

func intentar_comprar() -> void:

	if not abierto:
		return

	# GestorMisiones controla el precio,
	# el descuento y el desbloqueo.
	var compra_exitosa: bool = (
		GestorMisiones.registrar_compra_pistola()
	)

	if compra_exitosa:

		print("TIENDA: Compra completada")

		texto_mensaje.text = (
            "Listo, compadre! "
			+ "Ya tienes tu pistola de balines."
		)

		boton_comprar.disabled = true

	else:

		texto_mensaje.text = (
            "No se pudo completar la compra."
		)

	actualizar_panel()


# ==========================================
# SALIR DE LA TIENDA
# ==========================================

func cerrar_tienda() -> void:

	if not abierto:
		return

	abierto = false

	panel_principal.visible = false

	if is_instance_valid(jugador):

		jugador.velocity = Vector3.ZERO
		jugador.process_mode = modo_anterior

	if is_instance_valid(hud):

		hud.visible = hud_visible_anterior

	Input.mouse_mode = mouse_anterior

	print("TIENDA: Regresando al modo FPS")

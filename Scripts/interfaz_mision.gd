
extends Control

# ==========================================
# INTERFAZ DE MISIONES
# ==========================================

var panel_mision: PanelContainer

var etiqueta_titulo: Label
var etiqueta_descripcion: Label


# ==========================================
# INICIAR INTERFAZ
# ==========================================

func _ready() -> void:

	# La interfaz no bloqueara el mouse
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Ocupar toda la pantalla
	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# Construir la interfaz visual
	crear_interfaz()

	# Escuchar los cambios de objetivo
	GestorMisiones.objetivo_actualizado.connect(
		actualizar_objetivo
	)

	# Reiniciar las misiones al cargar el nivel
	# Esto tambien funciona al reiniciar por detencion
	GestorMisiones.iniciar_nivel_paseo_ahumada()

	actualizar_objetivo(
		GestorMisiones.obtener_titulo(),
		GestorMisiones.obtener_descripcion()
	)


# ==========================================
# CREAR PANEL DE MISION
# ==========================================

func crear_interfaz() -> void:

	panel_mision = PanelContainer.new()

	add_child(panel_mision)

	# Panel ubicado arriba a la derecha
	panel_mision.anchor_left = 1.0
	panel_mision.anchor_right = 1.0
	panel_mision.anchor_top = 0.0
	panel_mision.anchor_bottom = 0.0

	panel_mision.offset_left = -440.0
	panel_mision.offset_right = -20.0
	panel_mision.offset_top = 20.0
	panel_mision.offset_bottom = 135.0

	panel_mision.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	# Fondo oscuro semitransparente
	var estilo: StyleBoxFlat = StyleBoxFlat.new()

	estilo.bg_color = Color(
		0.06,
		0.08,
		0.11,
		0.88
	)

	estilo.corner_radius_top_left = 6
	estilo.corner_radius_top_right = 6
	estilo.corner_radius_bottom_left = 6
	estilo.corner_radius_bottom_right = 6

	estilo.border_width_left = 4

	estilo.border_color = Color("#DFB968")

	panel_mision.add_theme_stylebox_override(
		"panel",
		estilo
	)

	# Margenes interiores
	var margen: MarginContainer = MarginContainer.new()

	panel_mision.add_child(margen)

	margen.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	margen.add_theme_constant_override(
		"margin_left",
		14
	)

	margen.add_theme_constant_override(
		"margin_right",
		14
	)

	margen.add_theme_constant_override(
		"margin_top",
		10
	)

	margen.add_theme_constant_override(
		"margin_bottom",
		10
	)

	# Organizar contenido verticalmente
	var columna: VBoxContainer = VBoxContainer.new()

	margen.add_child(columna)

	columna.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	columna.add_theme_constant_override(
		"separation",
		5
	)

	# Nombre del capitulo
	var capitulo: Label = Label.new()

	capitulo.text = "CAPITULO 1 - PASEO AHUMADA"

	capitulo.add_theme_font_size_override(
		"font_size",
		12
	)

	capitulo.add_theme_color_override(
		"font_color",
		Color("#DFB968")
	)

	columna.add_child(capitulo)

	# Titulo del objetivo
	etiqueta_titulo = Label.new()

	etiqueta_titulo.add_theme_font_size_override(
		"font_size",
		18
	)

	etiqueta_titulo.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	columna.add_child(etiqueta_titulo)

	# Descripcion del objetivo
	etiqueta_descripcion = Label.new()

	etiqueta_descripcion.add_theme_font_size_override(
		"font_size",
		13
	)

	etiqueta_descripcion.add_theme_color_override(
		"font_color",
		Color("#C4CBD4")
	)

	etiqueta_descripcion.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	columna.add_child(etiqueta_descripcion)


# ==========================================
# ACTUALIZAR OBJETIVO EN PANTALLA
# ==========================================

func actualizar_objetivo(
	titulo: String,
	descripcion: String
) -> void:

	if etiqueta_titulo == null:
		return

	etiqueta_titulo.text = titulo

	etiqueta_descripcion.text = descripcion

	print(
		"INTERFAZ: Objetivo actualizado - ",
		titulo
	)

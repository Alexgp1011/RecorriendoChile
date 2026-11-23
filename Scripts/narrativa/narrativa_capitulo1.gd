extends Node
## Escenas narrativas del capitulo 1 (design/game-brief.md, seccion C).
##
## Se monta encima de la logica existente sin cambiarla: escucha la senal
## etapa_cambiada de GestorMisiones y anade dialogos, la entrega de la
## pistola, la transicion hacia Plaza de Armas, la presentacion de Rey Palomo
## y el cierre del capitulo. Las frases de Pepito y del ladron se detectan
## mirando la escena (distancia, visibilidad, dinero), sin tocar sus scripts.
##
## Los textos estan en ruta_dialogos (JSON). Cada nodo que usa se busca por su
## ruta en world.tscn; si falta, esa parte se omite con un aviso.

# ==========================================
# CONFIGURACION
# ==========================================

@export_file("*.json") var ruta_dialogos: String = "res://Asset/datos/dialogos_capitulo1.json"

## Segundos que se muestra cada linea de dialogo.
@export var segundos_por_linea: float = 3.4

## Segundos de la presentacion de Rey Palomo antes de que empiece el combate.
@export var duracion_presentacion_jefe: float = 4.5

## Pepito habla cuando el jugador esta a menos de esta distancia (m).
@export var distancia_frases_pepito: float = 6.0
## Segundos minimos entre dos frases de Pepito.
@export var pausa_frases_pepito: float = 9.0

## El ladron habla al acercarse a menos de esta distancia (m).
@export var distancia_frases_ladron: float = 7.0

## Tramo de Ahumada (coordenada z) en el que el cielo se va oscureciendo
## durante la transicion hacia la Plaza.
@export var oscurecer_desde_z: float = -60.0
@export var oscurecer_hasta_z: float = -100.0
## Fraccion de la luz que queda al llegar a la Plaza (1 = sin cambio).
@export_range(0.1, 1.0, 0.05) var luz_minima: float = 0.6

## Palomas que miran fijo al protagonista durante la transicion.
@export var cantidad_palomas_mirando: int = 10


# ==========================================
# RUTAS EN WORLD.TSCN
# ==========================================

const RUTA_DON_PALOMO := "Escenario/PlazaDeArmas/ArenaDonPalomo/DonPalomo"
const RUTA_CRUZ := "Escenario/PlazaDeArmas/Catedral/PuntoCruzCatedral"
const RUTA_PEPITO := "PuestoPepito"
const RUTA_LADRON := "Enemy"
const RUTA_ENTORNO := "WorldEnvironment"
const RUTA_SOL := "WorldEnvironment/DirectionalLight3D"
const ESCENA_PALOMA := "res://Scene/paloma_pequena.tscn"

## Estado del ladron en enemy.gd (enum Estado): PERSEGUIR = 0, ESCAPAR = 1.
const LADRON_PERSIGUE := 0
const LADRON_ESCAPA := 1
## Distancia maxima a la que un descenso del dinero cuenta como robo (m).
const DISTANCIA_ROBO := 3.0


# ==========================================
# ESTADO
# ==========================================

var dialogos: Dictionary = {}
var cola: Array = []
var tiempo_linea: float = 0.0
var hablando_historia: bool = false

var escena: Node
var jugador: Node3D
var camara_jugador: Camera3D
var don_palomo: Node3D
var cruz: Node3D
var pepito: Node3D
var ladron: Node3D
var entorno: Environment
var sol: DirectionalLight3D

var luz_sol_base: float = 1.0
var luz_ambiente_base: float = 1.0
var luz_cielo_base: float = 1.0
var luz_niebla_base: float = 1.0
var transicion_activa: bool = false
var frase_cerca_dicha: bool = false

var palomas_mirando: Array[Node3D] = []
var rey_en_la_cruz: AnimatedSprite3D

var reloj_pepito: float = 0.0
var pepito_visible_antes: bool = false
var dinero_antes: int = 0
var ladron_avisado: bool = false

# Interfaz
var capa: CanvasLayer
var panel_linea: PanelContainer
var etiqueta_quien: Label
var etiqueta_texto: Label
var titulo: Label
var subtitulo: Label


# ==========================================
# INICIAR
# ==========================================

func _ready() -> void:
	escena = get_parent()
	cargar_dialogos()
	buscar_nodos()
	crear_interfaz()

	if not GestorMisiones.etapa_cambiada.is_connected(al_cambiar_etapa):
		GestorMisiones.etapa_cambiada.connect(al_cambiar_etapa)

	dinero_antes = EstadoJuego.dinero


func cargar_dialogos() -> void:
	var archivo := FileAccess.open(ruta_dialogos, FileAccess.READ)
	if archivo == null:
		push_warning("NARRATIVA: no se pudo abrir " + ruta_dialogos)
		return
	var datos: Variant = JSON.parse_string(archivo.get_as_text())
	if datos is Dictionary:
		dialogos = datos
	else:
		push_warning("NARRATIVA: " + ruta_dialogos + " no es un JSON valido")


func buscar_nodos() -> void:
	jugador = get_tree().get_first_node_in_group("jugador") as Node3D
	if jugador != null:
		camara_jugador = jugador.get_node_or_null("Camera3D") as Camera3D
	don_palomo = buscar(RUTA_DON_PALOMO) as Node3D
	cruz = buscar(RUTA_CRUZ) as Node3D
	pepito = buscar(RUTA_PEPITO) as Node3D
	ladron = buscar(RUTA_LADRON) as Node3D
	var nodo_entorno := buscar(RUTA_ENTORNO) as WorldEnvironment
	if nodo_entorno != null:
		entorno = nodo_entorno.environment
		if entorno != null:
			luz_ambiente_base = entorno.ambient_light_energy
			luz_cielo_base = entorno.background_energy_multiplier
			luz_niebla_base = entorno.fog_light_energy
	sol = buscar(RUTA_SOL) as DirectionalLight3D
	if sol != null:
		luz_sol_base = sol.light_energy


func buscar(ruta: String) -> Node:
	var nodo := escena.get_node_or_null(ruta)
	if nodo == null:
		push_warning("NARRATIVA: no existe " + ruta + " (se omite esa parte)")
	return nodo


# ==========================================
# ETAPAS DE LA MISION
# ==========================================

func al_cambiar_etapa(etapa: int) -> void:
	# if/elif: un match no acepta como patron valores leidos de un autoload.
	if etapa == GestorMisiones.Etapa.CONSEGUIR_DINERO:
		decir("precio")
	elif etapa == GestorMisiones.Etapa.SALIR_GALERIA:
		decir("compra")
		presentar_pistola()
	elif etapa == GestorMisiones.Etapa.IR_PLAZA:
		decir("transicion")
		iniciar_transicion()
	elif etapa == GestorMisiones.Etapa.DERROTAR_DON_PALOMO:
		presentar_jefe()
	elif etapa == GestorMisiones.Etapa.COMPLETADA:
		cerrar_capitulo()


# ==========================================
# DIALOGOS
# ==========================================

## Pone en cola las lineas del grupo `clave` del JSON.
func decir(clave: String) -> void:
	var lineas: Variant = dialogos.get(clave, [])
	if not lineas is Array or lineas.is_empty():
		return
	hablando_historia = true
	for linea in lineas:
		cola.append(linea)


## Una frase al azar del grupo `clave`, solo si no hay dialogo en curso.
func frase_suelta(clave: String) -> void:
	if not cola.is_empty() or panel_linea.visible:
		return
	var lineas: Variant = dialogos.get(clave, [])
	if lineas is Array and not lineas.is_empty():
		cola.append(lineas.pick_random())


func avanzar_dialogo(delta: float) -> void:
	if panel_linea.visible:
		tiempo_linea -= delta
		if tiempo_linea > 0.0:
			return
		panel_linea.hide()
	if cola.is_empty():
		hablando_historia = false
		return
	var linea: Dictionary = cola.pop_front()
	etiqueta_quien.text = str(linea.get("quien", "")).to_upper()
	etiqueta_texto.text = str(linea.get("texto", ""))
	panel_linea.show()
	tiempo_linea = segundos_por_linea


# ==========================================
# LA PISTOLA
# ==========================================

## La pistola sube desde abajo de la pantalla la primera vez que aparece.
func presentar_pistola() -> void:
	if jugador == null:
		return
	var arma := jugador.get_node_or_null("CanvasLayer/Gunbase") as Control
	if arma == null:
		return
	var final_y: float = arma.position.y
	arma.position.y = final_y + 320.0
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(arma, "position:y", final_y, 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ==========================================
# TRANSICION HACIA PLAZA DE ARMAS
# ==========================================

func iniciar_transicion() -> void:
	transicion_activa = true
	frase_cerca_dicha = false
	poner_palomas_mirando()
	poner_rey_en_la_cruz()


## Palomas quietas a ambos lados del final de Ahumada. Son sprites que siempre
## miran a la camara: siguen al protagonista con la mirada.
func poner_palomas_mirando() -> void:
	var paquete: PackedScene = load(ESCENA_PALOMA)
	if paquete == null:
		return
	var modelo := paquete.instantiate()
	var origen := modelo.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if origen == null or origen.sprite_frames == null:
		modelo.free()
		return
	var cuadros: SpriteFrames = origen.sprite_frames
	var tamano: float = origen.pixel_size
	modelo.free()

	var animacion: StringName = &"idle" if cuadros.has_animation(&"idle") else cuadros.get_animation_names()[0]
	for i in cantidad_palomas_mirando:
		var paloma := AnimatedSprite3D.new()
		paloma.sprite_frames = cuadros
		paloma.animation = animacion
		paloma.pixel_size = tamano
		paloma.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		paloma.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		paloma.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		var lado: float = -6.8 if i % 2 == 0 else 6.8
		var z: float = lerpf(-80.0, -100.0, float(i) / maxf(cantidad_palomas_mirando - 1, 1))
		escena.add_child(paloma)
		paloma.global_position = Vector3(lado + randf_range(-0.6, 0.6), 0.25, z)
		palomas_mirando.append(paloma)


## Una copia decorativa de Rey Palomo posada en la cruz: el jugador lo ve en
## lo alto antes de que empiece el combate. Se retira al empezar.
func poner_rey_en_la_cruz() -> void:
	if don_palomo == null or cruz == null:
		return
	var visual := don_palomo.get_node_or_null("ReyPalomoVisual") as AnimatedSprite3D
	if visual == null or visual.sprite_frames == null:
		return
	rey_en_la_cruz = AnimatedSprite3D.new()
	rey_en_la_cruz.sprite_frames = visual.sprite_frames
	rey_en_la_cruz.pixel_size = visual.pixel_size
	rey_en_la_cruz.billboard = visual.billboard
	rey_en_la_cruz.texture_filter = visual.texture_filter
	rey_en_la_cruz.alpha_cut = visual.alpha_cut
	escena.add_child(rey_en_la_cruz)
	rey_en_la_cruz.global_position = cruz.global_position
	rey_en_la_cruz.global_basis = Basis.from_scale(visual.global_basis.get_scale())
	if visual.sprite_frames.has_animation(&"idle"):
		rey_en_la_cruz.play(&"idle")


## Oscurece el cielo segun lo cerca que esta el jugador de la Plaza.
func actualizar_transicion() -> void:
	if not transicion_activa or jugador == null:
		return
	var t: float = clampf(
		inverse_lerp(oscurecer_desde_z, oscurecer_hasta_z, jugador.global_position.z), 0.0, 1.0)
	aplicar_luz(lerpf(1.0, luz_minima, t))
	if t > 0.6 and not frase_cerca_dicha:
		frase_cerca_dicha = true
		decir("transicion_cerca")


func aplicar_luz(factor: float) -> void:
	if sol != null:
		sol.light_energy = luz_sol_base * factor
	if entorno != null:
		entorno.ambient_light_energy = luz_ambiente_base * factor
		entorno.background_energy_multiplier = luz_cielo_base * factor
		entorno.fog_light_energy = luz_niebla_base * factor


# ==========================================
# PRESENTACION DE REY PALOMO
# ==========================================

## Al empezar el combate: Rey Palomo en la cruz abre las alas, su titulo y una
## frase. El combate no cambia: el jefe real (que don_palomo.gd ya activo al
## recibir la misma senal) queda oculto y congelado durante la presentacion, y
## despues aparece y hace lo de siempre: subir a la Catedral y atacar.
func presentar_jefe() -> void:
	if don_palomo == null or cruz == null:
		return
	if not is_instance_valid(rey_en_la_cruz):
		poner_rey_en_la_cruz()

	var jefe_visible: bool = don_palomo.visible
	don_palomo.visible = false
	don_palomo.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(rey_en_la_cruz) and rey_en_la_cruz.sprite_frames.has_animation(&"fly"):
		rey_en_la_cruz.play(&"fly")   # abre las alas

	var modo_jugador: int = Node.PROCESS_MODE_INHERIT
	if jugador != null:
		modo_jugador = jugador.process_mode
		jugador.process_mode = Node.PROCESS_MODE_DISABLED

	var camara := Camera3D.new()
	escena.add_child(camara)
	var objetivo: Vector3 = cruz.global_position
	var desde: Vector3 = objetivo + Vector3(14.0, -12.0, 18.0)
	var hasta: Vector3 = objetivo + Vector3(5.0, -4.0, 7.0)
	camara.look_at_from_position(desde, objetivo, Vector3.UP)
	camara.make_current()
	var acercar := create_tween()
	acercar.tween_method(
		func(p: Vector3) -> void: camara.look_at_from_position(p, objetivo, Vector3.UP),
		desde, hasta, duracion_presentacion_jefe).set_trans(Tween.TRANS_SINE)

	mostrar_titulo(str(dialogos.get("jefe_titulo", "REY PALOMO")),
		str(dialogos.get("jefe_subtitulo", "")))
	# La frase del protagonista va junto al titulo, no detras de lo pendiente.
	cola.clear()
	panel_linea.hide()
	decir("jefe")

	await get_tree().create_timer(duracion_presentacion_jefe).timeout

	ocultar_titulo()
	if is_instance_valid(rey_en_la_cruz):
		rey_en_la_cruz.queue_free()
	if is_instance_valid(camara):
		camara.queue_free()
	if is_instance_valid(camara_jugador):
		camara_jugador.make_current()
	if jugador != null:
		jugador.process_mode = modo_jugador
	if is_instance_valid(don_palomo):
		don_palomo.visible = jefe_visible
		don_palomo.process_mode = Node.PROCESS_MODE_INHERIT


# ==========================================
# CIERRE DEL CAPITULO
# ==========================================

func cerrar_capitulo() -> void:
	transicion_activa = false
	for paloma in palomas_mirando:
		if is_instance_valid(paloma):
			paloma.queue_free()
	palomas_mirando.clear()
	var volver_luz := create_tween()
	volver_luz.tween_method(aplicar_luz, luz_minima, 1.0, 3.0)
	decir("victoria")
	var lineas: Variant = dialogos.get("victoria", [])
	var espera: float = segundos_por_linea * (lineas.size() if lineas is Array else 0) + 0.5
	await get_tree().create_timer(espera).timeout
	mostrar_titulo(str(dialogos.get("victoria_titulo", "")),
		str(dialogos.get("victoria_subtitulo", "")))


# ==========================================
# FRASES DE PEPITO Y DEL LADRON
# ==========================================

func actualizar_frases(delta: float) -> void:
	if jugador == null or hablando_historia:
		return
	# Con un panel abierto (el juego de Pepito, la tienda) no se habla encima.
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return
	actualizar_frases_pepito(delta)
	actualizar_frases_ladron()


func actualizar_frases_pepito(delta: float) -> void:
	if pepito == null:
		return
	var visible_ahora: bool = pepito.is_visible_in_tree() and pepito.can_process()
	var cerca: bool = distancia(pepito) <= distancia_frases_pepito
	# Estaba ahi, cerca, y desaparece en medio de la etapa del dinero: huyo.
	if pepito_visible_antes and not visible_ahora and distancia(pepito) <= distancia_frases_pepito * 2.0:
		var etapa: int = GestorMisiones.obtener_etapa_actual()
		if etapa == GestorMisiones.Etapa.CONSEGUIR_DINERO or etapa == GestorMisiones.Etapa.COMPRAR_PISTOLA:
			frase_suelta("pepito_huye")
	pepito_visible_antes = visible_ahora
	reloj_pepito -= delta
	if visible_ahora and cerca and reloj_pepito <= 0.0:
		reloj_pepito = pausa_frases_pepito
		frase_suelta("pepito")


func actualizar_frases_ladron() -> void:
	var dinero: int = EstadoJuego.dinero
	if ladron != null and ladron.is_visible_in_tree() and ladron.can_process():
		var estado: int = int(ladron.get("estado_actual"))
		var d := distancia(ladron)
		# Robo: el dinero baja con el ladron pegado al jugador (roba a 1.5 m).
		# Sin la distancia, una compra hecha mientras huye pareceria un robo.
		if dinero < dinero_antes and estado == LADRON_ESCAPA and d <= DISTANCIA_ROBO:
			frase_suelta("ladron_robo")
		if estado == LADRON_PERSIGUE and d <= distancia_frases_ladron and not ladron_avisado:
			ladron_avisado = true
			frase_suelta("ladron_acecho")
		elif d > distancia_frases_ladron * 2.0:
			ladron_avisado = false
	dinero_antes = dinero


func distancia(nodo: Node3D) -> float:
	var a := jugador.global_position
	var b := nodo.global_position
	return Vector2(a.x - b.x, a.z - b.z).length()


# ==========================================
# BUCLE
# ==========================================

func _process(delta: float) -> void:
	avanzar_dialogo(delta)
	actualizar_transicion()
	actualizar_frases(delta)


# ==========================================
# INTERFAZ
# ==========================================

func crear_interfaz() -> void:
	capa = CanvasLayer.new()
	capa.layer = 40
	capa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(capa)

	panel_linea = PanelContainer.new()
	panel_linea.anchor_left = 0.5
	panel_linea.anchor_right = 0.5
	panel_linea.anchor_top = 0.72
	panel_linea.anchor_bottom = 0.72
	panel_linea.offset_left = -380.0
	panel_linea.offset_right = 380.0
	panel_linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.04, 0.05, 0.07, 0.82)
	fondo.border_color = Color(0.85, 0.7, 0.3)
	fondo.set_border_width_all(2)
	fondo.set_content_margin_all(12)
	panel_linea.add_theme_stylebox_override("panel", fondo)
	capa.add_child(panel_linea)

	var columna := VBoxContainer.new()
	panel_linea.add_child(columna)
	etiqueta_quien = Label.new()
	etiqueta_quien.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	etiqueta_quien.add_theme_font_size_override("font_size", 16)
	columna.add_child(etiqueta_quien)
	etiqueta_texto = Label.new()
	etiqueta_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_texto.add_theme_font_size_override("font_size", 20)
	columna.add_child(etiqueta_texto)
	panel_linea.hide()

	titulo = crear_etiqueta_titulo(64, 0.28)
	subtitulo = crear_etiqueta_titulo(24, 0.38)


func crear_etiqueta_titulo(tamano: int, alto: float) -> Label:
	var etiqueta := Label.new()
	etiqueta.anchor_left = 0.0
	etiqueta.anchor_right = 1.0
	etiqueta.anchor_top = alto
	etiqueta.anchor_bottom = alto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	etiqueta.add_theme_color_override("font_outline_color", Color(0.25, 0.02, 0.02))
	etiqueta.add_theme_constant_override("outline_size", 10)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.hide()
	capa.add_child(etiqueta)
	return etiqueta


func mostrar_titulo(texto: String, debajo: String) -> void:
	titulo.text = texto
	subtitulo.text = debajo
	titulo.show()
	subtitulo.visible = not debajo.is_empty()


func ocultar_titulo() -> void:
	titulo.hide()
	subtitulo.hide()

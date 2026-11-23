
extends AnimatedSprite3D

# ==========================================
# REFERENCIAS
# ==========================================

@onready var policia: CharacterBody3D = get_parent() as CharacterBody3D


# ==========================================
# VISTAS (FRENTE / ESPALDA / LADO)
# ==========================================

## Coseno a partir del cual se usa la vista de frente o de espaldas;
## por debajo, la de lado. 0.5 = 60 grados respecto a la camara.
@export_range(0.0, 1.0, 0.05) var umbral_vista_frontal: float = 0.5

## Direccion horizontal en la que mira el policia: la de su ultimo
## movimiento. Se conserva cuando se detiene.
var direccion_mirada: Vector3 = Vector3.BACK


# ==========================================
# INICIAR ANIMACIONES
# ==========================================

func _ready() -> void:

	if policia == null:
		push_error("AnimatedSprite3D debe ser hijo de Policia")
		set_process(false)
		return

	if sprite_frames == null:
		push_error("Falta configurar SpriteFrames")
		set_process(false)
		return

	# Comprobar las animaciones
	for nombre in [&"idle", &"walk", &"chase", &"arrest"]:

		if not sprite_frames.has_animation(nombre):
			push_error("Falta la animacion: " + str(nombre))
			set_process(false)
			return

	# La detencion no debe repetirse
	sprite_frames.set_animation_loop(&"arrest", false)

	play(&"idle")


# ==========================================
# ACTUALIZAR ANIMACIONES
# ==========================================

func _process(_delta: float) -> void:

	if not is_instance_valid(policia):
		return

	# Leer el estado actual de policia.gd
	var estado: int = int(policia.get("estado_actual"))

	var nueva_animacion: StringName = &"idle"

	# ======================================
	# ESTADO 0: PATRULLA
	# ======================================

	if estado == 0:

		var velocidad_horizontal: float = Vector2(
			policia.velocity.x,
			policia.velocity.z
		).length_squared()

		if velocidad_horizontal > 0.01:
			nueva_animacion = &"walk"
		else:
			nueva_animacion = &"idle"

	# ======================================
	# ESTADO 1: ALERTA
	# ======================================

	elif estado == 1:
		nueva_animacion = &"idle"

	# ======================================
	# ESTADO 2: PERSECUCION
	# ======================================

	elif estado == 2:
		nueva_animacion = &"chase"

	# ======================================
	# ESTADO 3: DETENCION
	# ======================================

	elif estado == 3:
		nueva_animacion = &"arrest"

	# ======================================
	# ELEGIR VISTA SEGUN LA CAMARA
	# ======================================

	var movimiento: Vector3 = Vector3(policia.velocity.x, 0.0, policia.velocity.z)

	if movimiento.length_squared() > 0.01:
		direccion_mirada = movimiento.normalized()

	var vista: Dictionary = elegir_vista()

	var con_vista: StringName = StringName(
		String(nueva_animacion) + vista["sufijo"]
	)

	if sprite_frames.has_animation(con_vista):
		nueva_animacion = con_vista

	flip_h = vista["espejo"]

	# ======================================
	# REPRODUCIR ANIMACION
	# ======================================

	if animation != nueva_animacion:

		# Al cambiar solo de vista, seguir en el mismo paso
		var misma_accion: bool = (
			String(animation).get_slice("_", 0)
			== String(nueva_animacion).get_slice("_", 0)
		)

		var cuadro: int = frame
		var progreso: float = frame_progress

		play(nueva_animacion)

		if misma_accion:
			set_frame_and_progress(
				cuadro % sprite_frames.get_frame_count(nueva_animacion),
				progreso
			)


# ==========================================
# ELEGIR VISTA
# ==========================================

## Devuelve el sufijo de animacion ("" frente, "_espalda", "_lado") y si hay
## que espejar el sprite. Las vistas de lado de la hoja miran a la derecha.
func elegir_vista() -> Dictionary:

	var camara: Camera3D = get_viewport().get_camera_3d()

	if camara == null:
		return {"sufijo": "", "espejo": false}

	var hacia_camara: Vector3 = camara.global_position - global_position
	hacia_camara.y = 0.0

	if hacia_camara.length_squared() < 0.0001:
		return {"sufijo": "", "espejo": false}

	hacia_camara = hacia_camara.normalized()

	var frontal: float = direccion_mirada.dot(hacia_camara)

	if frontal >= umbral_vista_frontal:
		return {"sufijo": "", "espejo": false}

	if frontal <= -umbral_vista_frontal:
		return {"sufijo": "_espalda", "espejo": false}

	# De lado: hacia que lado de la pantalla se mueve
	var derecha_pantalla: Vector3 = camara.global_basis.x
	derecha_pantalla.y = 0.0

	return {
		"sufijo": "_lado",
		"espejo": direccion_mirada.dot(derecha_pantalla) < 0.0
	}

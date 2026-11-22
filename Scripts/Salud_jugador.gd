
extends Node

# ==========================================
# CONFIGURACION DE SALUD
# ==========================================

@export var vida_maxima: int = 100
@export var etiqueta_vida: Label
@export var efecto_golpe: ColorRect

# ==========================================
# VARIABLES
# ==========================================

var vida_actual: int = 100
var muerto: bool = false

var tween_destello: Tween


# ==========================================
# INICIAR SALUD
# ==========================================

func _ready() -> void:
	vida_actual = vida_maxima
	muerto = false

	actualizar_interfaz()

	# Preparar pantalla roja
	if is_instance_valid(efecto_golpe):
		efecto_golpe.visible = true
		efecto_golpe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		efecto_golpe.color = Color(0.9, 0.05, 0.05, 1.0)
		efecto_golpe.modulate = Color(1.0, 1.0, 1.0, 0.0)

	print("Salud inicial: ", vida_actual)


# ==========================================
# RECIBIR DANO
# ==========================================

func recibir_dano(cantidad: int) -> void:

	if muerto:
		return

	if cantidad <= 0:
		return

	vida_actual -= cantidad
	vida_actual = maxi(vida_actual, 0)

	print("El jugador recibio ", cantidad, " de dano")
	print("Vida actual: ", vida_actual)

	actualizar_interfaz()

	# Activar efecto rojo
	mostrar_efecto_golpe()

	# Comprobar muerte
	if vida_actual <= 0:
		morir()


# ==========================================
# EFECTO VISUAL DE GOLPE
# ==========================================

func mostrar_efecto_golpe() -> void:

	if not is_instance_valid(efecto_golpe):
		return

	# Detener efecto anterior si sigue activo
	if tween_destello != null:
		if tween_destello.is_valid():
			tween_destello.kill()

	# Activar destello rojo
	efecto_golpe.modulate = Color(1.0, 1.0, 1.0, 0.30)

	# Crear animacion de desaparicion
	tween_destello = create_tween()
	tween_destello.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	tween_destello.tween_property(
		efecto_golpe,
		"modulate:a",
		0.0,
		0.4
	).set_trans(Tween.TRANS_SINE)


# ==========================================
# ACTUALIZAR INTERFAZ
# ==========================================

func actualizar_interfaz() -> void:

	if is_instance_valid(etiqueta_vida):
		etiqueta_vida.text = "VIDA: " + str(vida_actual)


# ==========================================
# MUERTE DEL JUGADOR
# ==========================================

func morir() -> void:

	if muerto:
		return

	muerto = true

	print("El jugador ha muerto")

	# Utilizar la pantalla de muerte existente
	var personaje: Node = get_parent()

	if personaje.has_method("kill"):
		personaje.call("kill")
	else:
		push_warning(
            "No se encontro la funcion kill() en Player"
		)


extends Node

# ==========================================
# CONTROL VISUAL DEL ARMA
# ==========================================

@onready var arma_visual: CanvasItem = (
	get_parent() as CanvasItem
)


# ==========================================
# INICIAR
# ==========================================

func _ready() -> void:

	if arma_visual == null:

		push_error(
            "ControlArma debe ser hijo de Gunbase"
		)

		set_process(false)
		return

	actualizar_arma()


# ==========================================
# COMPROBAR COMPRA
# ==========================================

func _process(_delta: float) -> void:

	actualizar_arma()


# ==========================================
# MOSTRAR U OCULTAR ARMA
# ==========================================

func actualizar_arma() -> void:

	if arma_visual == null:
		return

	arma_visual.visible = (
		GestorMisiones.tiene_pistola()
	)

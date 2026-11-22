
extends Node

# ==========================================
# ACTIVADOR DE EVENTOS DE PASEO AHUMADA
# ACTIVA PEPITO Y EL LADRON POR MISION
# ==========================================

@export var puesto_pepito: Node3D
@export var ladron: Node3D

# Activado: permanecen disponibles despues
# de comprar la pistola.
# Desactivado: dejan de aparecer al comprarla.
@export var mantener_despues_compra: bool = true


# ==========================================
# ESTADO INTERNO
# ==========================================

var modo_original_pepito: int = (
	Node.PROCESS_MODE_INHERIT
)

var modo_original_ladron: int = (
	Node.PROCESS_MODE_INHERIT
)

var estado_inicializado: bool = false
var eventos_activos: bool = false


# ==========================================
# INICIALIZACION
# ==========================================

func _ready() -> void:

	if is_instance_valid(puesto_pepito):

		modo_original_pepito = (
			puesto_pepito.process_mode
		)

		preparar_colisiones(puesto_pepito)

	else:

		push_warning(
            "EVENTOS: Falta asignar PuestoPepito"
		)

	if is_instance_valid(ladron):

		modo_original_ladron = (
			ladron.process_mode
		)

		preparar_colisiones(ladron)

	else:

		push_warning(
            "EVENTOS: Falta asignar el ladron"
		)

	# Escuchar cambios de mision.
	if not GestorMisiones.etapa_cambiada.is_connected(
		al_cambiar_etapa
	):

		GestorMisiones.etapa_cambiada.connect(
			al_cambiar_etapa
		)

	# Comprobar la mision actual.
	# Esto tambien sirve al reiniciar.
	actualizar_activacion(
		GestorMisiones.obtener_etapa_actual()
	)


# ==========================================
# PREPARAR COLISIONES
# ==========================================

func preparar_colisiones(nodo: Node) -> void:

	var objeto: CollisionObject3D = (
		nodo as CollisionObject3D
	)

	if objeto != null:

		# Al desactivar el procesamiento,
		# Godot retirara este objeto fisico.
		objeto.disable_mode = (
			CollisionObject3D.DISABLE_MODE_REMOVE
		)

	# Incluir las colisiones de la mesa,
	# conos, detector policial y del ladron.
	for hijo in nodo.get_children():

		preparar_colisiones(hijo)


# ==========================================
# DETECTAR CAMBIO DE MISION
# ==========================================

func al_cambiar_etapa(nueva_etapa: int) -> void:

	actualizar_activacion(nueva_etapa)


# ==========================================
# COMPROBAR SI DEBEN ESTAR ACTIVOS
# ==========================================

func corresponde_activar(etapa: int) -> bool:

	if etapa == int(
		GestorMisiones.Etapa.CONSEGUIR_DINERO
	):

		return true

	if etapa == int(
		GestorMisiones.Etapa.COMPRAR_PISTOLA
	):

		return true

	# Las etapas posteriores mantienen los
	# personajes si esta opcion esta activa.
	if mantener_despues_compra:

		if etapa >= int(
			GestorMisiones.Etapa.SALIR_GALERIA
		):

			return true

	return false


# ==========================================
# APLICAR CAMBIO A LOS DOS PERSONAJES
# ==========================================

func actualizar_activacion(etapa: int) -> void:

	var activar: bool = (
		corresponde_activar(etapa)
	)

	# No repetir la activacion cuando
	# no ha cambiado el estado.
	# Esto evita interferir con las huidas
	# y reapariciones de Pepito.
	if estado_inicializado:

		if activar == eventos_activos:
			return

	estado_inicializado = true
	eventos_activos = activar

	configurar_personaje(
		puesto_pepito,
		activar,
		modo_original_pepito
	)

	configurar_personaje(
		ladron,
		activar,
		modo_original_ladron
	)

	if activar:

		print(
            "EVENTOS: Pepito y ladron ACTIVADOS"
		)

	else:

		print(
            "EVENTOS: Pepito y ladron DESACTIVADOS"
		)


# ==========================================
# MOSTRAR U OCULTAR PERSONAJE
# ==========================================

func configurar_personaje(
	personaje: Node3D,
	activar: bool,
	modo_original: int
) -> void:

	if not is_instance_valid(personaje):
		return

	if activar:

		# Restaurar su funcionamiento.
		personaje.visible = true

		personaje.set_deferred(
			"process_mode",
			modo_original
		)

	else:

		# Ocultar completamente.
		personaje.visible = false

		# Detener sus scripts y retirar las
		# colisiones heredadas.
		personaje.set_deferred(
			"process_mode",
			Node.PROCESS_MODE_DISABLED
		)

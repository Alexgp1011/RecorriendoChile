
extends Area3D

# ==========================================
# ZONAS DE MISION - PASEO AHUMADA
# ==========================================

enum TipoZona {
	ENTRADA_GALERIA,
	TIENDA_BALINES,
	SALIDA_GALERIA,
	PLAZA_DE_ARMAS
}


# ==========================================
# CONFIGURACION
# ==========================================

@export var tipo_zona: TipoZona = (
	TipoZona.ENTRADA_GALERIA
)

@export var mostrar_diagnostico: bool = true


# ==========================================
# VARIABLES
# ==========================================

var objetivo_registrado: bool = false


# ==========================================
# INICIAR ZONA
# ==========================================

func _ready() -> void:

	monitoring = true

	if not body_entered.is_connected(
		detectar_jugador
	):

		body_entered.connect(
			detectar_jugador
		)

	print(
		"ZONA PREPARADA: ",
		name,
		" | Tipo: ",
		TipoZona.keys()[int(tipo_zona)]
	)


# ==========================================
# COMPROBAR JUGADOR DENTRO DE LA ZONA
# ==========================================

func _physics_process(_delta: float) -> void:

	if objetivo_registrado:
		return

	if not monitoring:
		return

	# Revisar tambien si el jugador ya esta
	# dentro cuando cambia la mision.
	for cuerpo in get_overlapping_bodies():

		if es_jugador(cuerpo):

			intentar_completar_objetivo()
			return


# ==========================================
# DETECTAR ENTRADA DEL JUGADOR
# ==========================================

func detectar_jugador(cuerpo: Node3D) -> void:

	if not es_jugador(cuerpo):
		return

	print(
		"ZONA: Jugador entro en ",
		name
	)

	intentar_completar_objetivo()


# ==========================================
# RECONOCER AL PROTAGONISTA
# ==========================================

func es_jugador(cuerpo: Node) -> bool:

	if cuerpo == null:
		return false

	return (
		cuerpo.is_in_group("jugador")
		or cuerpo.is_in_group("player")
		or cuerpo.is_in_group("Player")
	)


# ==========================================
# ETAPA NECESARIA PARA CADA ZONA
# ==========================================

func obtener_etapa_requerida() -> int:

	match tipo_zona:

		TipoZona.ENTRADA_GALERIA:

			return int(
				GestorMisiones.Etapa.ENTRAR_GALERIA
			)

		TipoZona.TIENDA_BALINES:

			return int(
				GestorMisiones.Etapa.ENCONTRAR_TIENDA
			)

		TipoZona.SALIDA_GALERIA:

			return int(
				GestorMisiones.Etapa.SALIR_GALERIA
			)

		TipoZona.PLAZA_DE_ARMAS:

			return int(
				GestorMisiones.Etapa.IR_PLAZA
			)

	return -1


# ==========================================
# COMPLETAR OBJETIVO
# ==========================================

func intentar_completar_objetivo() -> void:

	if objetivo_registrado:
		return

	if not GestorMisiones.mision_activa:
		return

	var etapa_actual: int = (
		GestorMisiones.obtener_etapa_actual()
	)

	var etapa_requerida: int = (
		obtener_etapa_requerida()
	)

	# Solo avanzar si corresponde
	# a la mision actual.
	if etapa_actual != etapa_requerida:
		return

	if mostrar_diagnostico:

		print("================================")

		print(
			"ZONA DETECTADA: ",
			name
		)

		print(
			"TIPO: ",
			TipoZona.keys()[int(tipo_zona)]
		)

		print(
			"MISION ANTES: ",
			GestorMisiones.obtener_titulo()
		)

	# Evitar completar la misma zona
	# varias veces.
	objetivo_registrado = true

	# Informar al gestor de misiones
	GestorMisiones.registrar_zona(
		int(tipo_zona)
	)

	if mostrar_diagnostico:

		print(
			"MISION DESPUES: ",
			GestorMisiones.obtener_titulo()
		)

		print("================================")

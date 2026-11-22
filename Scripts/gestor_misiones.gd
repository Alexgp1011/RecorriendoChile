
extends Node

# ==========================================
# GESTOR DE MISIONES
# ==========================================

signal objetivo_actualizado(
	titulo: String,
	descripcion: String
)

signal etapa_cambiada(etapa: int)


# ==========================================
# ETAPAS DE LA HISTORIA
# ==========================================

enum Etapa {
	BUSCAR_CARTEL,
	ENTRAR_GALERIA,
	ENCONTRAR_TIENDA,
	CONSEGUIR_DINERO,
	COMPRAR_PISTOLA,
	SALIR_GALERIA,
	IR_PLAZA,
	DERROTAR_DON_PALOMO,
	COMPLETADA
}


# ==========================================
# ZONAS DE MISION
# ==========================================

enum Zona {
	ENTRADA_GALERIA,
	TIENDA_BALINES,
	SALIDA_GALERIA,
	PLAZA_DE_ARMAS
}


# ==========================================
# CONFIGURACION
# ==========================================

@export var precio_pistola: int = 150000


# ==========================================
# ESTADO DE LA PARTIDA
# ==========================================

var etapa_actual: Etapa = Etapa.BUSCAR_CARTEL

var mision_activa: bool = false
var pistola_comprada: bool = false


# ==========================================
# INICIAR CAPITULO
# ==========================================

func iniciar_nivel_paseo_ahumada() -> void:

	etapa_actual = Etapa.BUSCAR_CARTEL

	mision_activa = true
	pistola_comprada = false

	print("MISION: Comenzando Paseo Ahumada")

	objetivo_actualizado.emit(
		obtener_titulo(),
		obtener_descripcion()
	)


# ==========================================
# COMPROBAR OBJETIVOS
# ==========================================

func _process(_delta: float) -> void:

	if not mision_activa:
		return

	comprobar_progreso_automatico()


func comprobar_progreso_automatico() -> void:

	match etapa_actual:

		Etapa.BUSCAR_CARTEL:

			if EstadoJuego.carteles_recogidos > 0:

				cambiar_etapa(
					Etapa.ENTRAR_GALERIA
				)

		Etapa.CONSEGUIR_DINERO:

			if EstadoJuego.dinero >= precio_pistola:

				cambiar_etapa(
					Etapa.COMPRAR_PISTOLA
				)


# ==========================================
# DETECTAR ZONAS
# ==========================================

func registrar_zona(tipo: int) -> void:

	if not mision_activa:
		return

	comprobar_progreso_automatico()

	match tipo:

		Zona.ENTRADA_GALERIA:

			if etapa_actual == Etapa.ENTRAR_GALERIA:

				cambiar_etapa(
					Etapa.ENCONTRAR_TIENDA
				)

		Zona.TIENDA_BALINES:

			if etapa_actual == Etapa.ENCONTRAR_TIENDA:

				cambiar_etapa(
					Etapa.CONSEGUIR_DINERO
				)

				comprobar_progreso_automatico()

		Zona.SALIDA_GALERIA:

			if etapa_actual == Etapa.SALIR_GALERIA:

				cambiar_etapa(
					Etapa.IR_PLAZA
				)

		Zona.PLAZA_DE_ARMAS:

			if etapa_actual == Etapa.IR_PLAZA:

				if pistola_comprada:

					cambiar_etapa(
						Etapa.DERROTAR_DON_PALOMO
					)


# ==========================================
# COMPRAR PISTOLA DE BALINES
# ==========================================

func registrar_compra_pistola() -> bool:

	if not mision_activa:
		return false

	if pistola_comprada:
		return false

	if etapa_actual != Etapa.COMPRAR_PISTOLA:
		return false

	if EstadoJuego.dinero < precio_pistola:
		return false

	EstadoJuego.dinero -= precio_pistola

	pistola_comprada = true

	if EstadoJuego.get(
        "tiene_pistola_balines"
	) != null:

		EstadoJuego.set(
			"tiene_pistola_balines",
			true
		)

	print("MISION: Pistola comprada")

	cambiar_etapa(
		Etapa.SALIR_GALERIA
	)

	return true


# ==========================================
# DERROTAR A DON PALOMO
# ==========================================

func registrar_derrota_palomo() -> void:

	if not mision_activa:
		return

	if etapa_actual != Etapa.DERROTAR_DON_PALOMO:
		return

	print("MISION: DON PALOMO DERROTADO!")

	cambiar_etapa(
		Etapa.COMPLETADA
	)


# ==========================================
# CAMBIAR ETAPA
# ==========================================

func cambiar_etapa(nueva_etapa: Etapa) -> void:

	if etapa_actual == nueva_etapa:
		return

	etapa_actual = nueva_etapa

	print(
		"NUEVO OBJETIVO: ",
		obtener_titulo()
	)

	etapa_cambiada.emit(
		int(etapa_actual)
	)

	objetivo_actualizado.emit(
		obtener_titulo(),
		obtener_descripcion()
	)


# ==========================================
# TITULOS DE OBJETIVOS
# ==========================================

func obtener_titulo() -> String:

	match etapa_actual:

		Etapa.BUSCAR_CARTEL:
			return "ENCUENTRA UN CARTEL"

		Etapa.ENTRAR_GALERIA:
			return "ENTRA A LA GALERIA"

		Etapa.ENCONTRAR_TIENDA:
			return "BUSCA LA TIENDA DE BALINES"

		Etapa.CONSEGUIR_DINERO:
			return "CONSIGUE DINERO"

		Etapa.COMPRAR_PISTOLA:
			return "COMPRA LA PISTOLA"

		Etapa.SALIR_GALERIA:
			return "SAL DE LA GALERIA"

		Etapa.IR_PLAZA:
			return "DIRIGETE A PLAZA DE ARMAS"

		Etapa.DERROTAR_DON_PALOMO:
			return "DERROTA A DON PALOMO"

		Etapa.COMPLETADA:
			return "CAPITULO COMPLETADO"

	return "SIN OBJETIVO"


# ==========================================
# DESCRIPCIONES
# ==========================================

func obtener_descripcion() -> String:

	match etapa_actual:

		Etapa.BUSCAR_CARTEL:

			return (
                "Busca un cartel de protesta "
				+ "en Paseo Ahumada."
			)

		Etapa.ENTRAR_GALERIA:

			return (
                "Usa el cartel para atravesar "
				+ "el bloqueo de manifestantes."
			)

		Etapa.ENCONTRAR_TIENDA:

			return (
                "Busca la tienda de balines "
				+ "en el tercer piso."
			)

		Etapa.CONSEGUIR_DINERO:

			var faltante: int = maxi(
				precio_pistola - EstadoJuego.dinero,
				0
			)

			return (
				"Necesitas $" + str(precio_pistola)
				+ ". Te faltan $" + str(faltante)
				+ ". Busca a Pepito."
			)

		Etapa.COMPRAR_PISTOLA:

			return (
                "Regresa al tercer piso "
				+ "y compra la pistola."
			)

		Etapa.SALIR_GALERIA:

			return (
                "Ya tienes la pistola. "
				+ "Sal de la galeria."
			)

		Etapa.IR_PLAZA:

			return (
                "Las palomas estan causando caos. "
				+ "Ve a Plaza de Armas."
			)

		Etapa.DERROTAR_DON_PALOMO:

			return (
                "Enfrenta a la paloma gigante. "
				+ "Dispara para reducir su salud."
			)

		Etapa.COMPLETADA:

			return (
                "Derrotaste a Don Palomo. "
				+ "Primer capitulo completado!"
			)

	return ""


# ==========================================
# CONSULTAR PROGRESO
# ==========================================

func obtener_etapa_actual() -> int:

	return int(etapa_actual)


func tiene_pistola() -> bool:

	return pistola_comprada

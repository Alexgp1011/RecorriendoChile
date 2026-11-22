
extends Area3D

# Tipos de zonas existentes
enum TipoZona {
	MARCHA,
	POLICIA
}

# Permite elegir el tipo desde el Inspector
@export var tipo_zona: TipoZona = TipoZona.MARCHA

# Evita repetir mensajes constantemente
var estado_anterior: String = ""


func _physics_process(_delta: float) -> void:

	var jugador_dentro: bool = false

	# Comprobar si el jugador está en la zona
	for cuerpo in get_overlapping_bodies():

		if cuerpo.is_in_group("jugador"):
			jugador_dentro = true
			break

	# Si salió, reiniciar el estado
	if not jugador_dentro:
		estado_anterior = ""
		return

	var peligro: bool = false

	# Zona de manifestantes
	if tipo_zona == TipoZona.MARCHA:

		if EstadoJuego.cartel_visible:
			peligro = false
		else:
			peligro = true

	# Zona de policía
	elif tipo_zona == TipoZona.POLICIA:

		if EstadoJuego.cartel_visible:
			peligro = true
		else:
			peligro = false

	var estado_actual: String = "PELIGRO" if peligro else "SEGURO"

	# Mostrar mensajes solo si cambia el estado
	if estado_actual == estado_anterior:
		return

	estado_anterior = estado_actual

	if peligro:

		if tipo_zona == TipoZona.MARCHA:
			print("¡Los manifestantes violentos te descubrieron!")

		elif tipo_zona == TipoZona.POLICIA:
			print("¡La policía detectó tu cartel!")

	else:
		print("Puedes avanzar sin levantar sospechas.")

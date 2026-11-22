
extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mostrar_cartel") and not event.is_echo():

		if EstadoJuego.carteles_recogidos <= 0:
			print("No tienes ningún cartel")
			return

		EstadoJuego.cartel_visible = not EstadoJuego.cartel_visible

		if EstadoJuego.cartel_visible:
			print("Has levantado el cartel")
		else:
			print("Has ocultado el cartel")

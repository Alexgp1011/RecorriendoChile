
extends StaticBody3D

func interactuar() -> void:
	EstadoJuego.carteles_recogidos += 1

	print("Recogiste un cartel de protesta")
	print("Presiona Q para mostrarlo u ocultarlo")

	queue_free()

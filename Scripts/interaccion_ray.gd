
extends RayCast3D

func _ready() -> void:
	enabled = true
	target_position = Vector3(0, 0, -3)

	var jugador = get_tree().get_first_node_in_group("jugador")

	if jugador is CollisionObject3D:
		add_exception(jugador)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar") and not event.is_echo():
		force_raycast_update()

		if not is_colliding():
			return

		var objeto = get_collider()

		if objeto != null and objeto.has_method("interactuar"):
			objeto.interactuar()

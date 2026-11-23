extends SceneTree
## Walks chapter 1's narrative beats (Scripts/narrativa/narrativa_capitulo1.gd)
## by forcing mission stages, and saves one screenshot per beat. Tool only.
##
## Run windowed (never headless):
##   <godot> --path . --windowed --resolution 1280x720 -s res://tools/capture/capture_narrativa.gd -- <abs_out_dir>

var out_dir: String
var jugador: Node3D
var camara: Camera3D


func _initialize() -> void:
	out_dir = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	current_scene = null
	change_scene_to_packed(load("res://Scene/world.tscn"))
	await scene_changed
	await create_timer(1.0).timeout
	jugador = current_scene.get_node("Player") as Node3D
	camara = jugador.get_node("Camera3D") as Camera3D
	var gm := root.get_node("GestorMisiones")
	var estado := root.get_node("EstadoJuego")

	# 1. The price reveal (stage CONSEGUIR_DINERO)
	gm.cambiar_etapa(gm.Etapa.CONSEGUIR_DINERO)
	await espera(0.6)
	await foto("01-precio")

	# 2. Pepito calling the player, once the price dialogue is over
	var pepito := current_scene.get_node("PuestoPepito") as Node3D
	await espera(11.0)
	colocar(pepito.global_position + Vector3(0, 1.0, 4.0), pepito.global_position + Vector3(0, 1.0, 0))
	await espera(1.5)
	await foto("02-pepito")

	# 3. The purchase: the gun rises into view
	estado.dinero = 150000
	gm.cambiar_etapa(gm.Etapa.COMPRAR_PISTOLA)
	colocar(Vector3(0, 1.0, 0), Vector3(0, 1.0, -10))
	gm.registrar_compra_pistola()
	await espera(0.75)
	await foto("03-compra-pistola-subiendo")
	await espera(10.5)

	# 4. Transition toward the Plaza: staring pigeons, darker sky
	gm.cambiar_etapa(gm.Etapa.SALIR_GALERIA)
	gm.cambiar_etapa(gm.Etapa.IR_PLAZA)
	colocar(Vector3(0, 1.0, -78), Vector3(0, 1.0, -100))
	await espera(1.0)
	await foto("04-transicion")
	colocar(Vector3(0, 1.0, -96), Vector3(0, 1.0, -110))
	await espera(1.0)
	await foto("05-transicion-cerca")

	# 5. Rey Palomo perched on the cross, seen from the street
	var cruz := current_scene.get_node("Escenario/PlazaDeArmas/Catedral/PuntoCruzCatedral") as Node3D
	colocar(Vector3(0, 1.0, -100), cruz.global_position)
	await espera(7.0)
	await foto("06-rey-en-la-cruz")

	# 6. The boss presentation, then the fight starting
	gm.cambiar_etapa(gm.Etapa.DERROTAR_DON_PALOMO)
	await espera(1.8)
	await foto("07-presentacion-jefe")
	var palomo := current_scene.get_node("Escenario/PlazaDeArmas/ArenaDonPalomo/DonPalomo")
	print("NARRCAP durante presentacion: jefe procesa=", palomo.can_process(), " jugador procesa=", jugador.can_process())
	var cam_activa := root.get_viewport().get_camera_3d()
	print("NARRCAP camara activa=", cam_activa.name, " | jefe real visible=", palomo.is_visible_in_tree(),
		" | cruz en pantalla=", cam_activa.is_position_in_frustum(cruz.global_position))
	await espera(3.5)
	print("NARRCAP tras presentacion: jefe procesa=", palomo.can_process(), " visible=", palomo.is_visible_in_tree(),
		" jugador procesa=", jugador.can_process(), " camara jugador=", camara.current)
	await foto("08-combate-empieza")

	# 7. The chapter closing
	gm.registrar_derrota_palomo()
	await espera(8.0)
	await foto("09-capitulo-completado")
	quit()


func colocar(pos: Vector3, mirar: Vector3) -> void:
	jugador.global_position = pos
	var plano := Vector3(mirar.x, pos.y, mirar.z)
	if plano.distance_to(pos) > 0.01:
		jugador.look_at(plano, Vector3.UP)
	var ojo := camara.global_position
	var arriba := atan2(mirar.y - ojo.y, Vector2(mirar.x - ojo.x, mirar.z - ojo.z).length())
	camara.rotation.x = arriba


func espera(segundos: float) -> void:
	await create_timer(segundos).timeout


func foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := out_dir.path_join(nombre + ".png")
	root.get_texture().get_image().save_png(ruta)
	print("NARRCAP ", nombre)

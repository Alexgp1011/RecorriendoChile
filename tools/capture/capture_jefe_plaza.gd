extends SceneTree
## Starts the Rey Palomo fight, saves a screenshot of the presentation (the
## boss on the cathedral cross) and one of the fight, and lets the fight run
## so the log shows how many red marks each rain places ("ZONAS ROJAS
## GENERADAS"). The player is made invulnerable for the run. Tool only.
##
## Run windowed (never headless):
##   <godot> --path . --windowed --resolution 1280x720 -s res://tools/capture/capture_jefe_plaza.gd -- <abs_out_dir> [segundos]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var segundos: float = float(args[1]) if args.size() > 1 else 40.0
	DirAccess.make_dir_recursive_absolute(out_dir)
	current_scene = null
	change_scene_to_packed(load("res://Scene/world.tscn"))
	await scene_changed
	await create_timer(0.6).timeout

	var gm := root.get_node("GestorMisiones")
	var jugador := current_scene.get_node("Player") as Node3D
	var salud := jugador.get_node_or_null("Salud")
	var cruz := current_scene.get_node("Escenario/PlazaDeArmas/Catedral/PuntoCruzCatedral") as Node3D
	jugador.global_position = Vector3(6, 1.0, -112)
	jugador.look_at(Vector3(cruz.global_position.x, jugador.global_position.y, cruz.global_position.z), Vector3.UP)

	gm.cambiar_etapa(gm.Etapa.DERROTAR_DON_PALOMO)
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("presentacion-en-la-cruz.png"))
	print("JEFECAP presentacion")

	var fin := Time.get_ticks_msec() + segundos * 1000.0
	var foto_combate := false
	var foto_marcas := false
	var cam_arriba := Camera3D.new()
	root.add_child(cam_arriba)
	var cam_jugador := root.get_viewport().get_camera_3d()
	var cuadro := 0
	while Time.get_ticks_msec() < fin:
		cuadro += 1
		# Once a rain is on the ground, one top-down photo of the red marks
		# (they must show above the plaza pavement).
		if not foto_marcas and cuadro % 10 == 0:
			var marcas := current_scene.find_children("IndicadorRojo", "MeshInstance3D", true, false)
			if marcas.size() >= 8:
				foto_marcas = true
				cam_arriba.look_at_from_position(Vector3(-1, 26, -126), Vector3(-1, 0, -128.7), Vector3.UP)
				cam_arriba.make_current()
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(out_dir.path_join("marcas-rojas.png"))
				print("JEFECAP marcas visibles en pantalla: ", marcas.size())
				if cam_jugador != null:
					cam_jugador.make_current()
		if salud != null and salud.get("vida_actual") != null:
			salud.set("vida_actual", 100)   # invulnerable: we only observe the boss
		if not foto_combate and Time.get_ticks_msec() > fin - segundos * 1000.0 + 9000.0:
			foto_combate = true
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out_dir.path_join("combate.png"))
			print("JEFECAP combate")
		await process_frame
	quit()

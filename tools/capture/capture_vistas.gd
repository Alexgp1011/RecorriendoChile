extends SceneTree
## Checks the directional police sprites and the thief's robbery lunge in the
## real world scene. Tool only, not game code.
##
## Run windowed (never headless):
##   <godot> --path . --windowed --resolution 1280x720 -s res://tools/capture/capture_vistas.gd -- <abs_out_dir>

const RECORTE := Vector2i(420, 620)


func _initialize() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	current_scene = null
	change_scene_to_packed(load("res://Scene/world.tscn"))
	await scene_changed
	await create_timer(0.5).timeout
	var cam := Camera3D.new()
	root.add_child(cam)

	# --- Police: walking toward +X, seen from four sides -------------------
	var poli := current_scene.get_node("Policia") as CharacterBody3D
	var spr := poli.get_node("AnimatedSprite3D") as AnimatedSprite3D
	poli.process_mode = Node.PROCESS_MODE_DISABLED   # body frozen...
	spr.process_mode = Node.PROCESS_MODE_ALWAYS      # ...its visual still runs
	poli.velocity = Vector3(1.5, 0, 0)
	var p := poli.global_position
	var vistas := [
		["1-se-acerca", Vector3(4.5, 1.1, 0)],    # camera ahead of it
		["2-se-aleja", Vector3(-4.5, 1.1, 0)],    # camera behind it
		["3-cruza-a-la-derecha", Vector3(0, 1.1, 4.5)],
		["4-cruza-a-la-izquierda", Vector3(0, 1.1, -4.5)],
	]
	var tiras: Array[Image] = []
	for v in vistas:
		cam.look_at_from_position(p + v[1], p + Vector3(0, 0.9, 0), Vector3.UP)
		cam.make_current()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		tiras.append(recorte())
		print("VISTA policia %s: anim=%s flip_h=%s" % [v[0], spr.animation, spr.flip_h])
	guardar_tira(tiras, out_dir.path_join("policia-vistas.png"))

	# --- Thief: a real robbery, then the escape ----------------------------
	var ladron := current_scene.get_node("Enemy") as CharacterBody3D
	var lspr := ladron.get_node("AnimatedSprite3D") as AnimatedSprite3D
	var jugador := current_scene.get_node("Player") as Node3D
	# activate it the way activador_evento_calle.gd does: visible + processing
	ladron.visible = true
	ladron.process_mode = Node.PROCESS_MODE_INHERIT
	ladron.global_position = jugador.global_position + Vector3(0, 0.3, -1.2)
	cam.look_at_from_position(ladron.global_position + Vector3(3.5, 0.2, 1.5), ladron.global_position + Vector3(0, -0.3, 0), Vector3.UP)
	cam.make_current()
	await physics_frame
	ladron.call("realizar_robo")
	tiras.clear()
	for t in [0.05, 0.2, 0.6]:
		await create_timer(t if tiras.is_empty() else t - 0.05).timeout
		await RenderingServer.frame_post_draw
		tiras.append(recorte())
		print("VISTA ladron t=%.2fs: anim=%s estado=%s" % [t, lspr.animation, ladron.get("estado_actual")])
	guardar_tira(tiras, out_dir.path_join("ladron-robo.png"))
	quit()


func recorte() -> Image:
	var img := root.get_texture().get_image()
	var c := img.get_size() / 2
	return img.get_region(Rect2i(c.x - RECORTE.x / 2, c.y - RECORTE.y / 2, RECORTE.x, RECORTE.y))


func guardar_tira(tiras: Array[Image], ruta: String) -> void:
	var hoja := Image.create(RECORTE.x * tiras.size(), RECORTE.y, false, tiras[0].get_format())
	for i in tiras.size():
		hoja.blit_rect(tiras[i], Rect2i(Vector2i.ZERO, RECORTE), Vector2i(RECORTE.x * i, 0))
	hoja.save_png(ruta)
	print("VISTA guardada ", ruta)

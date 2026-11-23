extends SceneTree
## Renders every frame of every animation of the police officer and the thief
## in the real world scene, plus the first-person sign raised, and saves one
## contact sheet per NPC. Tool only, not game code.
##
## Run windowed (never headless):
##   <godot> --path <project> --windowed --resolution 1280x720 -s <this file> -- <abs_out_dir>

const RECORTE := Vector2i(380, 600)   # area around the NPC kept per frame


func _initialize() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	current_scene = null
	change_scene_to_packed(load("res://Scene/world.tscn"))
	await scene_changed
	await create_timer(0.5).timeout

	var cam := Camera3D.new()
	root.add_child(cam)
	for objetivo in ["Policia", "Enemy"]:
		var npc := current_scene.get_node_or_null(objetivo) as Node3D
		var spr := npc.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D if npc else null
		if spr == null:
			print("CAPNPC sin sprite en ", objetivo)
			continue
		print("CAPNPC ", objetivo, " visible=", npc.is_visible_in_tree(), " pos=", npc.global_position)
		npc.process_mode = Node.PROCESS_MODE_DISABLED   # freeze it: we pick each frame
		npc.visible = true                              # the thief starts hidden until its street event
		spr.visible = true
		# rest the body on the floor as the game does once it runs (the thief is
		# spawned hidden at y = 1.0, with its 2 m capsule partly underground)
		var forma := npc.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var capsula := forma.shape as CapsuleShape3D if forma else null
		if capsula != null:
			npc.global_position.y = 0.01 - (forma.position.y - capsula.height / 2.0)
		var p := npc.global_position
		cam.look_at_from_position(Vector3(p.x, 1.1, p.z + 4.6), Vector3(p.x, 0.9, p.z), Vector3.UP)
		cam.make_current()
		var tiras: Array[Image] = []
		var etiquetas: Array[String] = []
		for anim in spr.sprite_frames.get_animation_names():
			for f in spr.sprite_frames.get_frame_count(anim):
				spr.animation = anim
				spr.frame = f
				await process_frame
				await RenderingServer.frame_post_draw
				var img := root.get_texture().get_image()
				var c := img.get_size() / 2
				tiras.append(img.get_region(Rect2i(c.x - RECORTE.x / 2, c.y - RECORTE.y / 2, RECORTE.x, RECORTE.y)))
				etiquetas.append("%s %d" % [anim, f])
		# contact sheet: all frames side by side
		var hoja := Image.create(RECORTE.x * tiras.size(), RECORTE.y, false, tiras[0].get_format())
		for i in tiras.size():
			hoja.blit_rect(tiras[i], Rect2i(Vector2i.ZERO, RECORTE), Vector2i(RECORTE.x * i, 0))
		var ruta := out_dir.path_join("%s-todos-los-cuadros.png" % objetivo.to_lower())
		hoja.save_png(ruta)
		print("CAPNPC ", ruta, " cuadros: ", ", ".join(etiquetas))

	# first-person sign: raise it through the game state the HUD reads
	var estado := root.get_node_or_null("EstadoJuego")
	var player_cam := current_scene.get_node("Player").find_children("*", "Camera3D", true, false)
	if estado != null and not player_cam.is_empty():
		(player_cam[0] as Camera3D).make_current()
		estado.set("carteles_recogidos", 1)
		estado.set("cartel_visible", true)
		# mid-raise: the raise tween (TRANS_BACK) overshoots around here
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		var subiendo := out_dir.path_join("cartel-subiendo.png")
		root.get_texture().get_image().save_png(subiendo)
		print("CAPNPC ", subiendo)
		await create_timer(1.3).timeout
		await RenderingServer.frame_post_draw
		var ruta := out_dir.path_join("cartel-levantado.png")
		root.get_texture().get_image().save_png(ruta)
		print("CAPNPC ", ruta)
	quit()

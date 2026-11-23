extends SceneTree
## Fixed views of Plaza de Armas for before/after comparison. Tool only.
##
## Run windowed (never headless):
##   <godot> --path . --windowed --resolution 1280x720 -s res://tools/capture/capture_plaza.gd -- <abs_out_dir>

## [file name, camera position, point it looks at]
const VISTAS := [
	["01-entrada-desde-ahumada", Vector3(0, 1.7, -100), Vector3(-6, 6, -124)],
	["02-hacia-la-catedral", Vector3(10, 1.7, -122), Vector3(-21, 10, -123)],
	["03-panoramica-alta", Vector3(16, 14, -104), Vector3(-6, 0, -128)],
	["04-desde-la-catedral", Vector3(-17, 1.7, -123), Vector3(10, 4, -118)],
]


func _initialize() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	current_scene = null
	change_scene_to_packed(load("res://Scene/world.tscn"))
	await scene_changed
	await create_timer(0.6).timeout
	var cam := Camera3D.new()
	root.add_child(cam)
	for v in VISTAS:
		cam.look_at_from_position(v[1], v[2], Vector3.UP)
		cam.make_current()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out_dir.path_join(v[0] + ".png"))
		print("PLAZACAP ", v[0])
	quit()

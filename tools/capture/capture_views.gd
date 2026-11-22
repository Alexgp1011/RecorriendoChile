extends Node
## Captures fixed-camera screenshots of world.tscn for visual before/after
## comparison. Tool only: it loads the world unchanged and adds its own camera.
##
## Run (windowed, never headless):
##   <godot> --path . --windowed --resolution 1280x720 res://tools/capture/capture_views.tscn -- <out_dir>
## <out_dir> defaults to res://production/qa/evidence/capture.

## Each view: [file name, camera position, point the camera looks at].
const VIEWS := [
	["01-ahumada-inicio", Vector3(0, 1.7, 6), Vector3(0, 4, -60)],
	["02-fachadas-izquierda", Vector3(6, 1.7, -4), Vector3(-9, 5, -30)],
	["03-fachadas-derecha", Vector3(-6, 1.7, -2), Vector3(9, 5, -20)],
	["04-edificio-plaza-cercano", Vector3(-3, 1.7, -12), Vector3(-9, 5, -12)],
	["05-eurocentro-frente", Vector3(-7, 1.7, -44), Vector3(9, 5, -44)],
	["06-eurocentro-entrada", Vector3(2, 1.7, -47), Vector3(9, 2.5, -47)],
	["07-fachada-derecha-fondo", Vector3(3, 1.7, -70), Vector3(9, 5, -73)],
	["08-quiosco-farol", Vector3(-2.5, 1.7, -17), Vector3(-7.6, 1.6, -22)],
	["09-vitrina-izquierda", Vector3(4.5, 1.7, -53.5), Vector3(9, 1.9, -53.5)],
	["10-vitrina-derecha", Vector3(2.5, 1.7, -37.5), Vector3(9, 1.7, -37.5)],
]

## Frames to let the world settle before the first capture, and between views.
const WARMUP_FRAMES := 30
const SETTLE_FRAMES := 10


func _ready() -> void:
	var out_dir := "res://production/qa/evidence/capture"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	var abs_dir := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
	DirAccess.make_dir_recursive_absolute(abs_dir)

	# Load the world as the current scene, exactly as the game does: scripts
	# such as enemy.gd look nodes up through get_tree().current_scene. This
	# node stays alive as a plain child of the root, outside the scene change.
	var tree := get_tree()
	tree.current_scene = null
	tree.change_scene_to_packed(load("res://Scene/world.tscn"))
	await tree.scene_changed
	var cam := Camera3D.new()
	add_child(cam)

	for i in WARMUP_FRAMES:
		await get_tree().process_frame

	for view in VIEWS:
		cam.look_at_from_position(view[1], view[2], Vector3.UP)
		cam.make_current()
		for i in SETTLE_FRAMES:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path: String = abs_dir.path_join(view[0] + ".png")
		var err := get_viewport().get_texture().get_image().save_png(path)
		print("CAPTURE ", view[0], " -> ", path, " err=", err)

	get_tree().quit()

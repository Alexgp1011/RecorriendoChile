extends SceneTree
## Bakes NavegacionCiudad's NavigationMesh from world.tscn and saves it as a
## .tres, without touching world.tscn. Tool only (not game code): the caller
## compares the result and splices it into the scene.
##
## Run headless:
##   <godot> --headless --path . -s res://tools/navegacion/hornear_navegacion.gd -- <out.tres> [grupo_extra_nodo]
## grupo_extra_nodo: optional root-level node of world.tscn to add to the
## source-geometry group before baking (for example MobiliarioAhumada).


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("NAV: falta la ruta de salida .tres")
		quit(1)
		return
	var out_path: String = args[0]
	current_scene = null
	change_scene_to_packed(load("res://Scene/world.tscn"))
	await scene_changed
	for i in 5:
		await physics_frame

	var region := current_scene.get_node_or_null("NavegacionCiudad") as NavigationRegion3D
	if region == null or region.navigation_mesh == null:
		push_error("NAV: no encuentro NavegacionCiudad o su NavigationMesh")
		quit(1)
		return
	var nav := region.navigation_mesh
	if args.size() > 1:
		var extra := current_scene.get_node_or_null(args[1])
		if extra == null:
			push_error("NAV: no existe el nodo " + args[1])
			quit(1)
			return
		extra.add_to_group(nav.geometry_source_group_name)
		print("NAV: agregado al grupo ", nav.geometry_source_group_name, ": ", args[1])

	print("NAV: antes ", nav.get_vertices().size(), " vertices, ", nav.get_polygon_count(), " poligonos")
	region.bake_navigation_mesh(false)
	print("NAV: despues ", nav.get_vertices().size(), " vertices, ", nav.get_polygon_count(), " poligonos")
	var err := ResourceSaver.save(nav, out_path)
	print("NAV: guardado ", out_path, " err=", err)
	quit(0 if err == OK else 1)

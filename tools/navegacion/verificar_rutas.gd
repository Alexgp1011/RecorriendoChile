extends SceneTree
## Checks the navigation the NPCs rely on, against world.tscn as it is.
## Tool only (not game code). Reports observations; it changes nothing.
##
## Run headless:
##   <godot> --headless --path . -s res://tools/navegacion/verificar_rutas.gd
##
## Checks:
##   - Rutapolicia: a path from each point to the next (and last -> first)
##   - PuntosHuidaLadron: a path from several street positions to each escape
##   - Plaza de Armas: a path from the street to ArenaDonPalomo
##   - every path keeps clear of each lamp post and kiosk (MobiliarioAhumada)
## A path "reaches" when its last point is within LLEGADA m of the target,
## the same tolerance enemy.gd uses (2.5).

const LLEGADA := 2.5
const RADIO_POSTE := 0.2
const MEDIO_QUIOSCO := Vector2(1.06, 0.9)   # half extents x/z incl. counter
const HOLGURA := 0.25                         # minimum clearance to report OK

var mapa: RID
var obstaculos: Array = []   # [kind, position]
var fallos := 0


func _initialize() -> void:
	current_scene = null
	change_scene_to_packed(load("res://Scene/world.tscn"))
	await scene_changed
	for i in 20:
		await physics_frame
	var escena := current_scene as Node3D
	mapa = escena.get_world_3d().navigation_map
	print("NAVCHK: iteracion del mapa ", NavigationServer3D.map_get_iteration_id(mapa),
		", regiones ", NavigationServer3D.map_get_regions(mapa).size())

	var mob := escena.get_node_or_null("MobiliarioAhumada")
	if mob != null:
		for c in mob.get_children():
			obstaculos.append(["poste" if c.name.begins_with("Farol") else "quiosco", (c as Node3D).global_position])

	var ruta: Array = []
	for m in escena.get_node("Rutapolicia").get_children():
		ruta.append(m)
	for i in ruta.size():
		var a: Node3D = ruta[i]
		var b: Node3D = ruta[(i + 1) % ruta.size()]
		revisar("policia %s -> %s" % [a.name, b.name], a.global_position, b.global_position)

	var origenes := [Vector3(0, 0, 0), Vector3(0, 0, -20), Vector3(0, 0, -40),
		Vector3(0, 0, -60), Vector3(0, 0, -80), Vector3(0, 0, -95)]
	for e in escena.get_node("PuntosHuidaLadron").get_children():
		for o in origenes:
			revisar("ladron %s -> %s" % [o, e.name], o, (e as Node3D).global_position)
	for e1 in escena.get_node("PuntosHuidaLadron").get_children():
		for e2 in escena.get_node("PuntosHuidaLadron").get_children():
			if e1 != e2:
				revisar("ladron %s -> %s" % [e1.name, e2.name], (e1 as Node3D).global_position, (e2 as Node3D).global_position)

	var arena := escena.get_node_or_null("Escenario/PlazaDeArmas/ArenaDonPalomo") as Node3D
	if arena != null:
		revisar("calle -> Plaza (ArenaDonPalomo)", Vector3(0, 0, -90), arena.global_position)

	print("NAVCHK: resumen fallos=", fallos)
	quit()


func revisar(nombre: String, desde: Vector3, hasta: Vector3) -> void:
	var camino := NavigationServer3D.map_get_path(mapa, desde, hasta, true, 1)
	if camino.size() < 2:
		fallos += 1
		print("NAVCHK FALLA  ", nombre, ": sin camino")
		return
	var fin := camino[camino.size() - 1]
	var llega := Vector2(fin.x - hasta.x, fin.z - hasta.z).length() <= LLEGADA
	var largo := 0.0
	for i in range(1, camino.size()):
		largo += camino[i].distance_to(camino[i - 1])
	var holgura := holgura_minima(camino)
	var ok := llega and holgura >= HOLGURA
	if not ok:
		fallos += 1
	print("NAVCHK %s %s: llega=%s largo=%.1f m holgura_mobiliario=%.2f m" % [
		"OK    " if ok else "FALLA ", nombre, llega, largo, holgura])


## Smallest horizontal distance from the path (sampled every 0.1 m) to any
## lamp post surface or kiosk footprint.
func holgura_minima(camino: PackedVector3Array) -> float:
	var minimo := INF
	for i in range(1, camino.size()):
		var a := camino[i - 1]
		var b := camino[i]
		var pasos := maxi(1, int(a.distance_to(b) / 0.1))
		for k in pasos + 1:
			var p := a.lerp(b, float(k) / pasos)
			for o in obstaculos:
				var c: Vector3 = o[1]
				var d: float
				if o[0] == "poste":
					d = Vector2(p.x - c.x, p.z - c.z).length() - RADIO_POSTE
				else:
					var dx := maxf(absf(p.x - c.x) - MEDIO_QUIOSCO.x, 0.0)
					var dz := maxf(absf(p.z - c.z) - MEDIO_QUIOSCO.y, 0.0)
					d = Vector2(dx, dz).length()
				minimo = minf(minimo, d)
	return minimo

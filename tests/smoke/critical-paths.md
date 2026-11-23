# Smoke Test: Critical Paths

**Purpose**: Run these checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

The game has no main menu and no save system yet: it starts straight into
`Scene/world.tscn` (Paseo Ahumada, chapter 1). Checks for those systems are
listed at the end and do not apply until they exist.

Godot path on this machine: `engine.path` in `project.yaml`. `<godot>` below
means that executable.

## Core Stability (always run)

1. The game launches into Paseo Ahumada without a crash or `SCRIPT ERROR`:
   `<godot> --path . --windowed --resolution 1280x720 --quit-after 240`
   — the log shows `LADRON: Sistema iniciado` and `POLICIA: Sistema iniciado`.
2. The chapter 1 mission panel is on screen ("CAPITULO 1 - PASEO AHUMADA").
3. The player can move (WASD) and look around without freezing.

## Core Mechanic (update per sprint)

4. Thief: the log shows `LADRON: Escondites encontrados: 3`; a robbery shows
   "TE ROBARON $…", the lunge pose, then the thief runs to a hiding spot.
5. Police: the log shows `POLICIA: Puntos encontrados: 6`; walking, the officer
   is seen from the front, the back or the side depending on the camera.
6. Protest sign: raising it shows exactly one hand holding the sign (never the
   three extra fists), also during the raise animation.
7. The gallery entrance (Eurocentro) and the mission zones still trigger
   (`ZonaEntradaGaleria`, `ZonaTiendaBalines`, `ZonaSalidaGaleria`).

## Navigation

8. `<godot> --headless --path . -s res://tools/navegacion/verificar_rutas.gd`
   ends with `NAVCHK: resumen fallos=0` (police route, thief escapes, access to
   the Plaza de Armas, clearance around lamp posts and kiosks).

## Visual

9. `<godot> --path . --windowed --resolution 1280x720 res://tools/capture/capture_views.tscn -- res://production/qa/evidence/<folder>`
   writes 10 views with no error; compare them with the last evidence folder.

## Performance

10. No visible frame rate drops on target hardware (60 fps target) walking the
    full length of Paseo Ahumada to the Plaza de Armas.

## Not yet applicable

- Main menu: start / respond to input (no main menu yet).
- Save / load round-trip (no save system yet).
- No memory growth over 5 minutes of play (add once the full chapter loop runs).

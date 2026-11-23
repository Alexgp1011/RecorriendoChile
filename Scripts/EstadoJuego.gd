
extends Node

## Dinero con el que empieza el capitulo, y al que vuelve tras una detencion
## (decision del autor, 2026-11-22). Ver design/game-brief.md, B1.
const DINERO_INICIAL: int = 10000

var carteles_recogidos: int = 0
var cartel_visible: bool = false

var tiene_pistola_balines: bool = false
var dinero: int = DINERO_INICIAL

var policia_alertada: bool = false
var ataque_palomas_iniciado: bool = false
var jefe_derrotado: bool = false


## Devuelve la partida al estado de inicio del capitulo. La llama policia.gd
## al detener al jugador, antes de recargar la escena; las misiones las
## reinicia interfaz_mision.gd al cargar el nivel.
func reiniciar_partida() -> void:
	carteles_recogidos = 0
	cartel_visible = false
	tiene_pistola_balines = false
	dinero = DINERO_INICIAL
	policia_alertada = false
	ataque_palomas_iniciado = false
	jefe_derrotado = false

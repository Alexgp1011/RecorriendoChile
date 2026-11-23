---
status: reverse-documented
source: . (Scripts/, Scene/world.tscn) + visión del autor (2026-11-22)
date: 2026-11-22
verified-by: alexgp1011
---

# Game Brief: Recorriendo Chile — Capítulo 1: Paseo Ahumada

> **Reverse-documented from implementation** — generado por `/reverse-document`
> desde `.` el 2026-11-22, commit `51d5e27`, y completado con la visión escrita
> por el autor ese mismo día (`design/vision-del-autor.md`).
> Lo que dice el autor está sin marcar. *(inferred)* = deducido del código, no
> confirmado. `INTENT UNKNOWN` = el autor no lo ha definido. Donde este documento
> y el código no coinciden, la sección B lo señala: no asumas que el documento es
> el requisito sin revisar B.

## In your words
Texto completo del autor, sin editar: `design/vision-del-autor.md`. Su cierre:
"El objetivo final es desarrollar un FPS retro chileno con humor, personalidad,
exploración, supervivencia y una historia que transforme un simple paseo después
del trabajo en una aventura completamente inesperada."

**Pitch:** Una persona común sale del trabajo a mirar una pistola de balines en una galería de Paseo Ahumada y termina enfrentándose al Rey Palomo sobre la cruz de la Catedral de Santiago.

**Genre:** FPS retro de aventura y humor (evitar, apostar, sobrevivir; combate contra jefe al final).

**Controls:** WASD para moverse, ratón para mirar, disparar, interactuar, Q para levantar/guardar el cartel, salir y reiniciar *(inferred: nombres del mapa de entrada de project.godot; W/S y Q verificadas)*.

**Question:** ¿Un paseo cotidiano escala de forma natural y graciosa hasta un jefe absurdo, con cada etapa llevando a la siguiente, y deja al jugador con ganas del próximo capítulo?

**Hooks:** el cartel que protege de los manifestantes pero te delata ante Carabineros · Pepito paga doble, que huye cuando ve una patrulla · el ladrón que se lleva lo que ganaste · Rey Palomo esperando sobre la cruz de la Catedral.

**Intent:** payoff builds — la progresión curiosidad → tensión → exploración → frustración → riesgo → satisfacción → sorpresa → acción (you said).

## Look and references
- Look: pixel art retro inspirado en los shooters de los 90, con identidad de Santiago centro. Limpio, legible, relativamente detallado y con un toque de realismo, nunca fotorrealista ni con estilos mezclados. Fondos transparentes en sprites, fachadas y props; colores, contornos, iluminación y resolución compatibles entre todo.
- References: Doom (años 90) — la perspectiva y los sprites en un mundo 3D; lugares reales de Santiago (Paseo Ahumada, Eurocentro, Plaza de Armas, Catedral Metropolitana).
- View: 3D · Camera: primera persona. Escenario de bloques 3D con fachadas (Sprite3D/quads) y personajes AnimatedSprite3D billboard.

## First minute
El protagonista aparece en Paseo Ahumada con $10.000 y sin arma. El panel dice "CAPÍTULO 1 - PASEO AHUMADA · ENCUENTRA UN CARTEL". Más adelante, una manifestación ocupa la calle. El jugador encuentra el cartel "NO + CAE", lo recoge y aprende a levantarlo (Q): los manifestantes dejan de verlo como extraño. El gancho paga cuando ve a una patrulla y entiende que tiene que guardarlo a tiempo *(inferred: orden de los objetivos en gestor_misiones.gd)*.

## Challenge
Desde el inicio: los manifestantes golpean (20 de vida) a quien no lleve el cartel, y Carabineros persigue y detiene a quien lo vea con el cartel levantado; una detención reinicia el capítulo. A mitad del capítulo el problema pasa a ser económico: reunir $150.000 apostando con Pepito (paga el doble y cada vez mezcla más rápido) mientras el ladrón intenta robar el 35% de lo ganado. Al final, Rey Palomo en tres fases cada vez más agresivas.

## Core loop
- Observar el entorno → decidir (levantar o guardar el cartel, cuánto apostar, seguir o huir) → avanzar al siguiente objetivo.
- Apostar con Pepito → ganar o perder → proteger el dinero del ladrón → volver a apostar o ir a comprar.
- En el combate: leer las marcas del suelo → esquivar → disparar en las ventanas de vulnerabilidad → la siguiente fase sube la presión.

## Goal & fail state
- Goal: completar las 8 etapas del capítulo y derrotar a Rey Palomo ("CAPÍTULO COMPLETADO").
- Fail: la vida llega a 0 *(inferred: pantalla de muerte existente)*; o te detiene Carabineros → el capítulo vuelve al inicio con $10.000, como al empezar (decidido, B1).

## Features
- [x] Misiones del capítulo 1: 8 etapas encadenadas por zonas y eventos (`gestor_misiones.gd`)
- [x] Cartel de protesta: recoger, levantar/guardar, protege de manifestantes y alerta a Carabineros
- [x] Manifestantes con IA: patrulla, persecución y golpe; no atacan si el cartel está levantado
- [x] Carabineros con IA y navegación: patrulla, alerta, persecución, detención
- [x] Eurocentro de tres pisos con la tienda de balines en el tercero (pistola $150.000)
- [x] Pepito paga doble: tres conos, apuestas, premio x2, dificultad creciente, huye de Carabineros y reaparece
- [x] Ladrón: persigue, roba, escapa a un escondite y reaparece
- [x] Pistola de balines y disparo
- [x] Rey Palomo: tres fases, bombardeo, lluvia de proyectiles marcada, picadas, cruz de la Catedral, palomas pequeñas
- [ ] Catedral Metropolitana reconocible (prioridad visual)
- [x] Momento de la compra de la pistola con peso narrativo
- [x] Transición narrativa hacia Plaza de Armas *(sin audio todavía)*
- [x] Presentación de Rey Palomo y cierre del capítulo *(sin audio todavía)*

## Your systems
- misiones del capítulo · in the slice
- cartel, manifestantes y Carabineros · in the slice
- Pepito paga doble · in the slice
- ladrón · in the slice
- pistola de balines y combate · in the slice
- Rey Palomo y su ejército de palomas · in the slice
- otras fuentes de dinero · later
- diálogos · thin stand-in
- escenas (compra, transición, presentación del jefe, cierre) · thin stand-in
- menú principal, opciones, pantalla de inicio y créditos · later
- música definitiva y sonido ambiente · later

## Keep
- Empezar con $10.000 y sin arma · pins: EstadoJuego.dinero 10000
- El dilema del cartel: protege de los manifestantes, delata ante Carabineros
- Pepito huye al ver Carabineros y reaparece en otro lugar · pins: radio_alerta 7.0
- El ladrón escapa y reaparece; su función es poner en riesgo el dinero, no ser derrotado
- Las 8 etapas de misión y su lógica · pins: precio_pistola 150000
- El combate de Rey Palomo tal como está (movilidad, frecuencia, dificultad, tres fases); nunca una versión simplificada · pins: vida_maxima 8, velocidad_vuelo 8.0 / 10.5 / 13.5

## Avoid
- Un juego militar, o uno solo de disparar a enemigos
- Un protagonista soldado, policía o superhéroe
- Propaganda política; humor que dependa de insultos o de referencias políticas
- Carabineros como enemigo al que se dispara
- El ladrón como enemigo que se derrota disparando, mientras dura la etapa del dinero (después de la compra sigue activo y un balín lo derriba: decidido así, B3)
- Recibir la pistola gratis o conseguir dinero derrotando enemigos
- Fotorrealismo y estilos mezclados
- Simplificar o reemplazar sistemas que funcionan
- Dar por aprobadas misiones o personajes nuevos que el autor no ha aprobado

## Out of scope
- Capítulos siguientes (Metro, micros, Valparaíso): ideas, no definidas
- Menú principal, opciones, pantalla de inicio, créditos, música definitiva: pendientes, fuera de este brief
- Otras fuentes de dinero: mejora futura, no implementada
- Guardado de partida *(guessed: no existe en el código y el autor no lo nombró)*

## Build order
1. Visual: Paseo Ahumada, Eurocentro y Plaza de Armas, con una Catedral Metropolitana reconocible.
2. Lo que queda pendiente en C (audio, transeúntes).
3. Personajes secundarios y animaciones.
4. Diálogos, sonido ambiente y escenas que conectan las misiones (compra, transición, presentación y derrota del jefe).

---
**Kill condition:** INTENT UNKNOWN

**Who it's for / what they feel:** INTENT UNKNOWN *(inferred: quien reconozca el centro de Santiago y disfrute ver lo cotidiano llevado al absurdo)*

**Games you love / don't:** Doom de los años 90 (inspiración visual).

---

# Diseño narrativo — Capítulo 1

## A. Historia y mecánicas definidas o implementadas

### Premisa
Una persona común, no un soldado, ni un policía, ni un héroe, termina una jornada de trabajo y no quiere volver directo a casa. Decide pasear por el centro de Santiago y visitar el Eurocentro, la galería del centro de Santiago. Le gustan las réplicas y las pistolas de balines, y quiere mirar productos en una tienda del tercer piso. Sale con $10.000, sin arma y sin ninguna intención de pelear. El pilar del juego es el contraste entre esa persona normal y lo extraordinario que le ocurre: un paseo cotidiano que se transforma, paso a paso, en una aventura absurda.

### El capítulo, etapa por etapa

| Etapa (código) | Qué pasa en la historia | Función | Cómo avanza en el código |
|---|---|---|---|
| BUSCAR_CARTEL | Llega a Ahumada; una manifestación le bloquea el paso | Primer obstáculo: observar, no pelear | Recoger el cartel (`carteles_recogidos > 0`) |
| ENTRAR_GALERIA | Atraviesa la manifestación con el cartel, esquivando a Carabineros | El dilema del cartel | Entrar en `ZonaEntradaGaleria` |
| ENCONTRAR_TIENDA | Sube al tercer piso del Eurocentro | Exploración; el objetivo original del paseo | Entrar en `ZonaTiendaBalines` |
| CONSEGUIR_DINERO | Descubre que la pistola cuesta $150.000 y solo tiene $10.000 | Primer giro: frustración → riesgo | Aparecen Pepito y el ladrón; avanza al llegar a $150.000 |
| COMPRAR_PISTOLA | Vuelve con el dinero | Satisfacción | Comprar en el panel del vendedor |
| SALIR_GALERIA | Sale con su pistola de balines | El tono empieza a cambiar | Entrar en `ZonaSalidaGaleria` |
| IR_PLAZA | Camina hacia Plaza de Armas | Sorpresa: algo anormal pasa | Entrar en la zona de la Plaza con la pistola |
| DERROTAR_DON_PALOMO | Rey Palomo domina la Plaza desde la Catedral | Acción | Vida del jefe a 0 |
| COMPLETADA | La Plaza recupera la calma | Satisfacción; ganas del próximo capítulo | — |

### Personajes y su función
- **Manifestantes**: manifestación ficticia y exagerada, un obstáculo urbano, no política. IA de patrulla, detección, persecución y golpe (20 de vida). Con el cartel levantado no atacan.
- **Carabineros**: una autoridad que hay que evitar, no un enemigo al que se dispara (en el código no se les puede abatir). Solo sospechan si ven el cartel levantado dentro de su zona: alerta de 2 s, persecución y detención, que reinicia el capítulo.
- **Vendedor de la tienda de balines**: el motivo del paseo. Revela el precio y entrega la pistola.
- **Pepito ("Pepito paga doble")**: vendedor callejero chileno, carismático, rápido para hablar, algo sospechoso y convincente; no es un villano. Es una oportunidad arriesgada: tres conos, una pelota, apuestas de $500 a $250.000, premio x2, mezclas cada vez más rápidas. Huye al ver Carabineros (7 m) y reaparece en otra parte. Hoy es el camino principal hacia los $150.000.
- **El ladrón**: personalidad callejera exagerada. Su función es poner en riesgo lo ganado: roba el 35% (entre $500 y $25.000), se queda un instante en la pose de embestida, huye a uno de tres escondites y vuelve a buscarte.
- **Rey Palomo / Don Palomo**: paloma gigantesca, musculosa, de ojos rojos; intimida y da risa a la vez. Una leyenda absurda del centro. Tiene animaciones idle, fly, attack, hurt y death.
- **Palomas pequeñas**: su ejército. Más pequeñas y menos imponentes (2 de vida, picotazo de 8); obligan a no concentrarse solo en el jefe.

### El Eurocentro
El lugar al que el protagonista quería ir: tres pisos, escaleras y locales geek (videojuegos, anime, cartas, figuras, tecnología, ropa). La tienda de balines está en el tercer piso. Es donde la historia cambia por primera vez: de "llegar a la galería" a "conseguir el dinero y conservarlo".

### Rey Palomo: el combate (tal como está implementado)
- **Fase 1**: vuela entre puntos elevados y bombardea con excrementos que marcan el suelo antes de caer. Se esquivan usando jardineras y obstáculos.
- **Fase 2**: más rápido; invoca palomas pequeñas (2 por oleada, cada 14 s).
- **Fase 3**: más rápido y agresivo; 3 palomas por oleada cada 10 s, más bombas por ataque.
- **En todas las fases**: lluvia de proyectiles con círculos rojos en el pavimento, cada vez más frecuente y con más impactos (10 / 18 / 26). También se posa en la cruz de la Catedral, hace picadas (20 de daño) y tiene ventanas de vulnerabilidad. La lluvia en las tres fases es la versión aprobada (B4).

### Tono y humor
Comedia exagerada: sátira de lo cotidiano, exageración y toques surrealistas, con situaciones reconocibles del centro de Santiago llevadas al absurdo. Situaciones inesperadas, diálogos ingeniosos y personajes ridículos, nunca solo insultos o referencias políticas. Con momentos de tensión y combates entretenidos.

### La experiencia buscada
Curiosidad (el paseo) → tensión (manifestación) → exploración (la galería) → frustración (el precio) → riesgo (Pepito y el ladrón) → satisfacción (la compra) → sorpresa (la Plaza) → acción (Rey Palomo). Cada etapa lleva naturalmente a la siguiente. El capítulo enseña que este Santiago es familiar pero impredecible.

### Capítulos futuros (ideas, no aprobadas)
Metro de Santiago (supervivencia, estaciones, andenes), las micros (supervivencia, encuentros, conflictos caricaturescos) y, más adelante, Valparaíso y otras ciudades. Sin historia definida: cualquier misión o personaje nuevo llega como propuesta.

### Pendiente de definir por el autor
- Audio: graznido de Rey Palomo, ruidos de la transición, sonido de la entrega de la pistola
- Transeúntes que huyen de la Plaza (falta su arte)
- El paso al capítulo 2 (hoy el cierre dice "Continuará...")
- Otras fuentes de dinero
- A quién va dirigido el juego y cuándo se abandonaría (Kill condition)

## B. Inconsistencias y problemas técnicos

Resueltas el 2026-11-22 con decisión del autor; se conservan como registro.

1. **Penalización por detención — RESUELTO.** Antes, detenerte dejaba el dinero en $3.000. Decisión del autor: una detención devuelve la partida al inicio del capítulo **con $10.000**, como al empezar. `EstadoJuego.DINERO_INICIAL` es el único valor; `dinero_inicial = 3000` de `policia.gd` queda sin uso (solo era el respaldo).
2. **`reiniciar_partida()` — RESUELTO.** Ahora existe en `EstadoJuego.gd` y `policia.gd` la usa al detener: restablece dinero, cartel, pistola y las banderas `policia_alertada`, `ataque_palomas_iniciado` y `jefe_derrotado`. Las misiones las reinicia `interfaz_mision.gd` al recargar, como antes. Tests: `tests/unit/estado/estado_reiniciar_partida_test.gd` (vistos fallar antes de la corrección).
3. **El ladrón después de la compra — DECIDIDO: se mantiene.** Sigue activo tras comprar la pistola (`mantener_despues_compra = true`) y un balín lo derriba. El dinero robado no se recupera.
4. **La lluvia de círculos rojos — DECIDIDO: vale el código.** Aparece en las tres fases y crece con cada una; la descripción de la visión del autor (solo fase 3) queda superada.
5. **El nombre de la galería — DECIDIDO: Eurocentro.** Coincide con el letrero del juego y los nodos `DecoracionEurocentro`. Las marcas reales de las fachadas siguen tapadas por letreros ficticios.
6. **La revelación del precio — RESUELTO en la narrativa.** El objetivo sigue cambiando al entrar en la zona de la tienda (sin tocar la lógica), y en ese momento el vendedor dice el precio y señala a Pepito.
7. **La compra como simple botón — RESUELTO en la narrativa.** Tras comprar, el vendedor entrega la pistola con un diálogo y la pistola sube a la vista por primera vez.
8. **Atasco económico — sigue abierto.** Sin otra fuente de dinero si se pierde todo con Pepito. Mejora futura, según el autor. (Una detención ahora devuelve $10.000.)
9. **Arte — sigue abierto.** Fachadas casi fotográficas, letreros con fuente vectorial, Eurocentro, faroles y quioscos de colores planos; la Catedral no existe todavía (solo el marcador de la cruz).
10. **Reinicio manual y muerte — RESUELTO (2026-11-23).** La tecla de reiniciar y el botón de la pantalla de muerte (`player.gd`, `restart()`) ahora llaman a `EstadoJuego.reiniciar_partida()` antes de recargar: todo vuelve a como al empezar ($10.000, sin cartel, misión "Encuentra un cartel"), igual que una detención. Comprobado en el juego antes (fallaba: conservaba dinero y cartel) y después del arreglo.

## C. Propuestas

### Implementadas (2026-11-22, aprobadas por el autor)
`Scripts/narrativa/narrativa_capitulo1.gd` (nodo `NarrativaCapitulo1` en `world.tscn`) escucha `GestorMisiones.etapa_cambiada` y no cambia la lógica de misiones, combate ni físicas. Los textos están en `Asset/datos/dialogos_capitulo1.json`, editables sin tocar código.
- **El precio:** al llegar a la tienda, el vendedor dice "ciento cincuenta lucas" y señala a Pepito.
- **La compra:** diálogo del vendedor; la pistola sube a la vista por primera vez; aviso sobre las palomas de la Plaza.
- **Transición a la Plaza:** palomas de ojos rojos que siguen al protagonista con la mirada al final de Ahumada, el cielo que se oscurece al acercarse, una voz que grita "¡Bajó el Rey Palomo!", y Rey Palomo visible posado en la cruz antes del combate.
- **Presentación de Rey Palomo:** la cámara sube hacia la cruz, abre las alas, título "REY PALOMO — Dueño y señor de la Plaza de Armas" y la frase del protagonista. El combate empieza al terminar (unos 4,5 s), igual que antes.
- **Cierre del capítulo:** la luz vuelve, se van las palomas, dos frases del protagonista y "CAPÍTULO 1 COMPLETADO — Continuará...".
- **Pepito y el ladrón con voz:** Pepito invita a apostar al acercarte y grita al huir de Carabineros; el ladrón habla al acecharte y al robarte.

### Pendientes
- Audio para todo lo anterior (no hay archivos de sonido todavía).
- Transeúntes que huyen de la Plaza (falta su arte; hoy es una voz).
- La Catedral Metropolitana, que da sentido a la cruz y a la presentación.
- Otras fuentes de dinero (B8).

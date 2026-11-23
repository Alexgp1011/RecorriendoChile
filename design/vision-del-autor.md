# Visión del autor — texto original

> Texto escrito por el autor (alexgp1011) el 2026-11-22, copiado sin editar.
> Es la fuente de `design/game-brief.md`: ante cualquier duda sobre la
> intención del juego, este texto manda.

---

QUIERO EXPLICARTE EN DETALLE LA HISTORIA, LA VISIÓN CREATIVA Y LAS INTENCIONES DE MI VIDEOJUEGO

Antes de continuar desarrollando el videojuego, quiero que comprendas la historia que deseo contar, el tipo de experiencia que busco entregar al jugador y por qué hemos incorporado determinadas mecánicas.

No quiero que interpretes el proyecto únicamente a partir de su código. Muchas de las mecánicas que encontrarás tienen una intención narrativa y forman parte de una aventura más grande.

1. CONCEPTO GENERAL DEL VIDEOJUEGO

Estoy desarrollando un videojuego FPS en primera persona, inspirado visualmente en los clásicos Doom de los años 90, pero ambientado en Chile, principalmente en lugares reconocibles de Santiago.

La idea principal es crear una aventura que mezcle humor chileno, situaciones absurdas, exploración urbana, supervivencia, acción y momentos de misterio.

Quiero que el jugador sienta que está recorriendo una versión exagerada y completamente disparatada del centro de Santiago, donde situaciones que parecen cotidianas terminan convirtiéndose en acontecimientos inesperados.

No quiero crear un videojuego militar ni uno exclusivamente dedicado a disparar enemigos.

Mi intención es combinar mecánicas de FPS con aventuras, objetivos, interacciones, decisiones y eventos que tengan un sentido dentro de una historia.

El protagonista no es un soldado, un policía ni un superhéroe. Es una persona común que termina involucrada en una serie de situaciones cada vez más ridículas y peligrosas.

El contraste entre una persona normal y los acontecimientos extraordinarios que le ocurren es uno de los pilares principales del juego.

El humor debe sentirse chileno, con situaciones reconocibles, referencias urbanas, diálogos cotidianos y personajes exagerados. Sin embargo, también quiero momentos de tensión y combates entretenidos.

2. EL PROTAGONISTA Y EL COMIENZO DE LA HISTORIA

La historia comienza con nuestro protagonista terminando una jornada de trabajo.

Es una persona común que ha tenido un día laboral normal. Después de salir de su trabajo, no quiere regresar inmediatamente a su casa.

Decide aprovechar el tiempo libre y caminar por el centro de Santiago, específicamente por Paseo Ahumada.

Su intención inicial es bastante sencilla: dar una vuelta por el Aurocentro, una galería comercial inspirada en el Eurocentro de Santiago.

Al protagonista le gustan las armas, especialmente las réplicas, las pistolas de balines y los artículos relacionados con ese mundo.

Quiere visitar una tienda de la galería para mirar los productos disponibles, preguntar por sus características y averiguar qué alternativa le convendría comprar.

No sale de su trabajo con la intención de combatir, enfrentar delincuentes ni convertirse en héroe.

Simplemente quiere pasear, entrar a una galería, mirar artículos que le gustan y quizás comprarse algo.

Este punto es fundamental: toda la aventura debe comenzar como un paseo completamente normal.

El personaje comienza con $10.000 pesos chilenos.

No tiene una pistola equipada al comenzar el videojuego.

Tampoco sabe que durante las siguientes horas terminará enfrentándose a una enorme paloma monstruosa en Plaza de Armas.

Esa transformación de una salida cotidiana en una aventura completamente absurda es la esencia narrativa que quiero desarrollar.

3. PRIMER ESCENARIO: PASEO AHUMADA

El primer capítulo del videojuego se desarrolla en Paseo Ahumada.

Quiero que este escenario se parezca visualmente al centro real de Santiago, pero interpretado con una estética pixel art retro.

Los edificios deben estar inspirados en fachadas existentes, mezclando arquitectura antigua, edificios comerciales, vitrinas, bancos, farmacias y galerías.

La calle debe tener su característico pavimento peatonal, árboles, quioscos, vendedores ambulantes, letreros y elementos urbanos chilenos.

No quiero un escenario vacío donde solamente aparezcan enemigos.

Quiero que se sienta como una ciudad con personalidad, donde el jugador pueda observar detalles, reconocer lugares y descubrir situaciones inesperadas.

La calle también debe servir para desarrollar la primera parte de la historia.

El protagonista llega a Paseo Ahumada y descubre que su camino hacia la galería no será tan sencillo como imaginaba.

4. LOS MANIFESTANTES Y EL CARTEL DE PROTESTA

Mientras intenta avanzar por Paseo Ahumada, el protagonista se encuentra con una manifestación que está ocupando parte de la calle.

No estamos intentando desarrollar un videojuego de propaganda política. La manifestación es una situación urbana ficticia y exagerada que funciona como un obstáculo narrativo y jugable.

Los manifestantes tienen una inteligencia artificial que les permite patrullar, detectar al jugador, perseguirlo y atacarlo bajo determinadas condiciones.

El protagonista descubre que puede utilizar un cartel de protesta para pasar entre ellos sin levantar sospechas.

Actualmente tenemos implementado un cartel con el texto "NO + CAE".

El jugador debe encontrarlo, recogerlo y posteriormente puede levantarlo o guardarlo.

Esta mecánica tiene una intención importante.

Cuando el protagonista levanta el cartel, los manifestantes lo reconocen como alguien que aparentemente participa en la manifestación y dejan de atacarlo.

Pero existe una consecuencia.

Si Carabineros observa al protagonista utilizando el cartel, puede considerarlo parte de la manifestación y comenzar a perseguirlo.

Por lo tanto, el cartel representa un dilema sencillo pero entretenido:

Si lo utilizas frente a los manifestantes, puedes avanzar con mayor seguridad.

Si lo utilizas frente a la policía, puedes llamar su atención y terminar detenido.

Quiero que el jugador aprenda a observar su entorno, decidir cuándo levantar o guardar el cartel y evitar problemas innecesarios.

Este sistema debe mantenerse porque es parte de la identidad del primer capítulo.

No quiero que se transforme en un simple combate donde el jugador deba disparar contra todos.

El desafío principal es atravesar una situación caótica utilizando inteligencia, observación y algo de humor.

5. LA POLICÍA Y LAS DETENCIONES

En Paseo Ahumada también hay Carabineros patrullando.

La policía tiene inteligencia artificial para recorrer el escenario, detectar situaciones sospechosas, perseguir al jugador y detenerlo.

Cuando el protagonista utiliza el cartel frente a ellos, puede activar la persecución.

Quiero que estas situaciones generen tensión, especialmente cuando el jugador está intentando atravesar la manifestación o dirigirse hacia la galería.

La policía no debe sentirse simplemente como otro enemigo al que se dispara.

Debe funcionar como una autoridad que el protagonista necesita evitar cuando está haciendo algo que llama su atención.

Actualmente la mecánica de detención puede provocar que el jugador reinicie el recorrido.

Sobre el dinero, quiero aclarar algo importante.

El protagonista debe comenzar con $10.000, y considero que las pérdidas de dinero o penalizaciones por detención deben ser decisiones deliberadas de diseño, no efectos accidentales del código.

Si actualmente una detención provoca que el dinero vuelva a $3.000, quiero que revisemos ese comportamiento antes de considerarlo definitivo.

Todavía no quiero establecer que una detención deba costar exactamente $7.000.

La penalización debe ser justa y consistente con la economía del juego.

También quiero que revisemos las llamadas a funciones que no existen, como reiniciar_partida() si todavía están presentes, pero sin modificar automáticamente un sistema que funciona.

6. EL AUROCENTRO: EL OBJETIVO ORIGINAL DEL PROTAGONISTA

Después de atravesar el sector de los manifestantes y evitar problemas con la policía, el protagonista finalmente consigue llegar a la galería comercial.

Para mí, este lugar es uno de los escenarios más importantes del primer capítulo.

Está inspirado en el Eurocentro de Santiago, pero dentro de nuestro juego podemos mantener el nombre Aurocentro o definir un nombre ficticio definitivo.

Quiero que tenga una personalidad visual propia.

Debe tener varios pisos, escaleras, locales de videojuegos, anime, cartas coleccionables, figuras, tecnología, ropa y otros artículos relacionados con la cultura geek.

Ya tenemos una galería de tres pisos construida dentro del proyecto.

El objetivo inicial del protagonista es subir hasta el tercer piso, donde se encuentra una tienda que vende pistolas de balines.

Este es el motivo original por el que decidió visitar el centro de Santiago.

El protagonista se acerca al vendedor, pregunta por los productos disponibles y descubre que la pistola que le interesa cuesta $150.000 pesos chilenos.

Aquí ocurre el primer gran cambio en la historia.

El personaje solo tiene $10.000.

No posee suficiente dinero para comprarla.

En una situación normal, simplemente regresaría otro día.

Pero en nuestro videojuego, este inconveniente dará origen a una nueva cadena de acontecimientos.

7. LA NECESIDAD DE CONSEGUIR DINERO

Cuando descubre el precio de la pistola, el protagonista decide buscar una manera de conseguir el dinero que le falta.

Aquí empieza una de las mecánicas centrales del primer capítulo.

No quiero que el jugador reciba una pistola gratuitamente ni que consiga dinero simplemente derrotando enemigos.

La idea es que deba asumir riesgos, decidir cuánto dinero arriesgar y enfrentar las consecuencias de sus decisiones.

En ese momento se activan dos personajes que ya tenemos programados:

Pepito, el vendedor del juego callejero.

El ladrón que intenta robar el dinero del protagonista.

Ambas mecánicas deben aparecer cuando la misión de conseguir dinero o comprar la pistola se encuentre activa.

El objetivo es que el jugador sienta que ahora tiene un problema diferente.

Ya no se trata solamente de llegar a la galería, sino de reunir suficiente dinero y conservarlo.

8. PEPITO PAGA DOBLE: EL GRAN MINIJUEGO DEL CAPÍTULO

Pepito es uno de los personajes más importantes de Paseo Ahumada.

Quiero que represente de manera caricaturesca al típico vendedor callejero que organiza un juego de apuestas con vasos o conos.

El protagonista encuentra a Pepito ofreciendo su juego.

La mecánica consiste en apostar dinero y adivinar bajo cuál de los tres conos se encuentra una pelota después de que se mezclan.

Quiero que Pepito tenga una personalidad especialmente chilena.

Debe ser carismático, rápido para hablar, algo sospechoso y muy convincente al momento de invitar al jugador a apostar.

Su apariencia y sus expresiones deben transmitir que sabe perfectamente cómo atraer a los curiosos.

Sin embargo, no quiero que se transforme en un personaje malvado convencional.

Pepito representa una oportunidad arriesgada.

El jugador puede apostar diferentes cantidades de dinero, intentar seguir la pelota y obtener ganancias si acierta.

Actualmente ya contamos con:

- Una mesa de juego.
- Tres conos.
- Una pelota.
- Una cámara especial para el minijuego.
- Un sistema de apuestas manuales.
- Recompensas económicas.
- Una dificultad que aumenta y comienza siendo desafiante.
- La posibilidad de interrumpir el juego cuando aparece la policía.

Esta última mecánica es importante.

Pepito está realizando una actividad callejera irregular dentro del mundo ficticio del videojuego.

Cuando detecta la presencia de Carabineros, abandona rápidamente su puesto y huye.

Después de un tiempo, puede reaparecer en otra ubicación de Paseo Ahumada.

Esto genera momentos entretenidos porque el jugador puede estar a punto de apostar y, de repente, Pepito desaparece al detectar una patrulla.

Quiero conservar esa personalidad.

La intención de Pepito paga doble es generar tensión económica.

El jugador debe pensar cuánto apostar, cuánto está dispuesto a perder y cuánto necesita ganar.

En la versión actual, las apuestas son la principal manera de alcanzar el dinero necesario para la pistola.

A futuro podríamos agregar otras formas de conseguir dinero para evitar que el jugador quede atrapado si pierde demasiado, pero eso debe tratarse como una mejora futura, no como una mecánica ya implementada.

9. EL LADRÓN: EL PELIGRO DE PERDER LO CONSEGUIDO

Mientras el jugador intenta conseguir dinero con Pepito, aparece otra dificultad.

Un ladrón comienza a recorrer Paseo Ahumada buscando al protagonista.

Actualmente el ladrón tiene una inteligencia artificial capaz de perseguir al jugador.

Cuando lo alcanza, no necesariamente lo mata.

Su objetivo es quitarle dinero.

Después de robar, huye rápidamente hacia otra zona del mapa.

Esta mecánica tiene un propósito muy claro dentro de la historia.

Quiero que el jugador sienta que conseguir dinero no es suficiente: también debe cuidarlo.

Imagina que el jugador acaba de ganar una apuesta importante, está muy cerca de conseguir los $150.000 y de pronto observa que el ladrón se está acercando.

En ese momento debe decidir si continúa apostando, si escapa o si busca una ruta más segura.

Me interesa especialmente ese tipo de tensión.

El ladrón debe tener una personalidad callejera exagerada, pero no convertirse simplemente en un enemigo más que se derrota disparando.

Su función principal es aumentar la dificultad del objetivo económico.

También quiero conservar su mecánica de escapar y reaparecer posteriormente, porque evita que el personaje sea un obstáculo estático.

10. LA COMPRA DE LA PISTOLA DE BALINES

Una vez que el protagonista reúne los $150.000, puede regresar al Aurocentro y comprar la pistola.

Este momento debe sentirse como una recompensa al esfuerzo del jugador.

No quiero que sea una simple modificación de una variable.

Narrativamente, el protagonista finalmente consigue aquello que había ido a mirar después del trabajo.

El vendedor le entrega una pistola de balines, que se transforma en su primera arma utilizable.

Es importante aclarar que hablamos de una pistola de balines dentro del contexto ficticio del videojuego, no de un arma de fuego militar.

La estética debe ser la de una pistola de balines retro, coherente con nuestro FPS y con el humor del juego.

A partir de este momento, el personaje dispone de una nueva herramienta.

El sistema de combate comienza a adquirir mayor importancia.

Hasta este punto, gran parte de la experiencia consistía en explorar, evitar peligros, interactuar, apostar y cumplir objetivos.

Ahora el jugador tiene la posibilidad de defenderse frente a las amenazas extraordinarias que aparecerán más adelante.

11. LA SALIDA DEL AUROCENTRO Y EL CAMINO A PLAZA DE ARMAS

Después de comprar la pistola, el protagonista sale de la galería.

Aquí quiero que la historia comience a cambiar de tono.

Hasta ahora las situaciones eran relativamente reconocibles dentro de una versión caricaturesca del centro de Santiago.

Había manifestantes, Carabineros, vendedores callejeros, apuestas, delincuentes y locales comerciales.

Pero ahora comenzarán acontecimientos mucho más extraños.

El protagonista continúa caminando y termina llegando a Plaza de Armas.

Podemos desarrollar una transición narrativa donde escuche ruidos extraños, observe palomas comportándose de forma agresiva o vea a personas alejándose de la plaza.

Esta transición todavía no está completamente desarrollada y la considero una propuesta para mejorar la historia.

La idea es que el jugador comprenda gradualmente que algo anormal está ocurriendo.

Lo cotidiano comienza a convertirse en absurdo y peligroso.

12. PLAZA DE ARMAS Y LA CATEDRAL DE SANTIAGO

Plaza de Armas será el escenario del gran enfrentamiento del primer capítulo.

Quiero recrear una versión reconocible del lugar real.

Debe incluir el pavimento de la plaza, las jardineras, árboles, bancas, monumentos, espacios abiertos y especialmente la Catedral Metropolitana de Santiago.

La Catedral tendrá una importancia fundamental.

No quiero que sea solamente un edificio decorativo.

Quiero que sea un elemento central del combate y de la narrativa.

En lo más alto de la Catedral, sobre una cruz, estará esperando nuestro primer gran jefe.

Su nombre es Rey Palomo, también conocido como Don Palomo.

13. REY PALOMO: EL PRIMER GRAN JEFE

Rey Palomo es una paloma gigantesca, musculosa, intimidante y ridícula al mismo tiempo.

Tiene ojos rojos, una expresión amenazante y una apariencia caricaturesca de jefe final.

Hemos desarrollado una versión pixel art del personaje con animaciones de:

Idle: cuando permanece quieto o posado.

Fly: cuando vuela.

Attack: cuando realiza ataques.

Hurt: cuando recibe daño.

Death: cuando es derrotado.

La idea narrativa es que el protagonista, que solamente había salido de su trabajo para mirar una pistola de balines, termine enfrentándose al supuesto rey de las palomas de Santiago.

Ese contraste es exactamente el tipo de humor absurdo que busco.

Rey Palomo debe ser intimidante, pero también provocar sorpresa y risa.

No quiero que parezca un enemigo genérico.

Debe sentirse como un personaje memorable, casi una leyenda absurda del centro de Santiago.

Su aparición debe ser importante.

Me gustaría que el jugador pueda verlo inicialmente en lo alto de la Catedral, sobre la cruz, antes de que comience a moverse por el escenario.

El inicio del combate podría tener un momento especial donde Rey Palomo extienda sus alas, emita un grito y revele su tamaño.

Todavía podemos desarrollar esa presentación cinematográfica sin alterar el combate existente.

14. LAS TRES FASES DEL COMBATE DE REY PALOMO

Actualmente ya tenemos un combate funcional con varias mecánicas.

Quiero conservarlas.

Primera fase: Rey Palomo comienza en altura, se desplaza entre distintos puntos y bombardea al jugador lanzando excrementos desde el aire.

Estos proyectiles deben poder esquivarse.

El jugador debe aprovechar las jardineras, obstáculos y estructuras de la plaza para protegerse.

Segunda fase: Rey Palomo comienza a invocar palomas pequeñas que atacan al jugador.

Estas palomas forman parte de su ejército.

Persiguen al protagonista y hacen que el combate sea más caótico.

Tercera fase: Rey Palomo incrementa la agresividad y la frecuencia de sus ataques.

Además de continuar bombardeando desde su propia posición, puede realizar un ataque especial donde aparecen numerosos círculos rojos repartidos por el suelo de Plaza de Armas.

Estos círculos indican dónde caerán proyectiles desde el cielo.

El jugador debe observar el pavimento, anticipar los impactos y desplazarse hacia zonas seguras.

Quiero que este ataque aparezca reiteradamente y obligue al protagonista a mantenerse en movimiento.

También tenemos desplazamientos entre marcadores elevados, descensos para atacar y momentos de vulnerabilidad.

Rey Palomo no debe desplazarse lentamente ni seguir una trayectoria demasiado predecible.

Ya mejoramos su movilidad, la frecuencia de los ataques y la dificultad del combate.

El objetivo es que la batalla se sienta intensa, divertida y visualmente memorable.

No quiero reemplazar esa programación por una versión simplificada.

15. LAS PALOMAS PEQUEÑAS

Rey Palomo tiene su propio ejército de palomas.

Estas palomas pequeñas aparecen durante determinadas fases del enfrentamiento.

Ya desarrollamos sus mecánicas de movimiento, persecución y ataque.

También estamos trabajando en sus recursos visuales pixel art.

Quiero que mantengan una estética coherente con el jefe, pero sean claramente más pequeñas y menos imponentes.

Pueden tener ojos rojos, expresiones agresivas y animaciones exageradas.

Su función es impedir que el jugador se concentre exclusivamente en dispararle a Rey Palomo.

Deben obligarlo a observar su entorno y responder a varias amenazas.

16. LA DERROTA DE REY PALOMO

Cuando el protagonista consigue reducir la vida de Rey Palomo a cero, se reproduce su animación de muerte y se completa la misión del capítulo.

Esto ya funciona en la versión actual del juego.

Narrativamente, me gustaría que la derrota tenga una pequeña conclusión.

Después de un combate absurdo contra una paloma gigantesca, el protagonista finalmente consigue recuperar la tranquilidad de Plaza de Armas.

Quiero que el jugador sienta satisfacción por haber sobrevivido a una aventura que comenzó como una simple salida después del trabajo.

Sin embargo, no quiero que el juego termine definitivamente aquí.

La idea es que este sea solamente el primer capítulo de una historia mayor.

La secuencia cinematográfica de victoria, los diálogos finales y la transición hacia el siguiente nivel todavía están pendientes de diseño.

17. LA ESTRUCTURA DE MISIONES QUE YA TENEMOS

Quiero que comprendas que estas misiones representan la progresión narrativa principal del primer capítulo.

La secuencia actual incluye:

BUSCAR_CARTEL: el protagonista debe encontrar el cartel para atravesar la manifestación.

ENTRAR_GALERIA: después de superar el primer obstáculo, debe ingresar al Aurocentro.

ENCONTRAR_TIENDA: debe llegar a la tienda de pistolas de balines, ubicada en el tercer piso.

CONSEGUIR_DINERO: al descubrir que no tiene suficiente dinero, debe reunir lo necesario mediante Pepito y evitar al ladrón.

COMPRAR_PISTOLA: cuando alcanza el dinero requerido, debe regresar a comprar la pistola.

SALIR_GALERIA: debe abandonar la galería después de completar su compra.

IR_PLAZA: continúa el recorrido hacia Plaza de Armas.

DERROTAR_DON_PALOMO: debe sobrevivir al enfrentamiento contra Rey Palomo y derrotarlo.

COMPLETADA: se cierra el primer capítulo.

Estas misiones ya están implementadas y quiero conservar su funcionamiento.

Podemos enriquecerlas narrativamente mediante diálogos, efectos, animaciones, escenas y detalles visuales, pero sin reemplazar su lógica sin una razón concreta.

18. EL TIPO DE HUMOR QUE QUIERO EN EL JUEGO

Quiero desarrollar un humor que combine sátira de situaciones cotidianas, exageración y elementos surrealistas.

Algunos ejemplos de la clase de situaciones que busco:

Salir de trabajar y terminar atrapado entre una manifestación y una patrulla policial.

Tener que levantar un cartel para pasar inadvertido frente a un grupo de manifestantes y esconderlo al acercarse la policía.

Entrar a una galería comercial para mirar una pistola de balines y descubrir que cuesta una cantidad absurda para el dinero disponible.

Encontrar un vendedor callejero que promete ganancias, pero que sale corriendo cuando aparece Carabineros.

Conseguir una cantidad importante de dinero mediante apuestas y tener que escapar de un ladrón que intenta quitártelo.

Finalmente comprar la pistola y terminar utilizándola contra una paloma gigantesca que domina Plaza de Armas desde la Catedral.

Todo esto debe tener un tono de comedia exagerada.

No quiero que el humor dependa solamente de insultos o de referencias políticas.

Prefiero situaciones inesperadas, diálogos ingeniosos, personajes ridículos y acontecimientos que recuerden al centro de Santiago, pero llevados al absurdo.

19. EL MUNDO Y LOS FUTUROS CAPÍTULOS

Mi intención es que el videojuego continúe explorando escenarios reconocibles de Chile.

El primer capítulo corresponde a Paseo Ahumada, el Aurocentro y Plaza de Armas.

Después me gustaría desarrollar nuevas aventuras relacionadas con otros lugares de Santiago.

Una de mis ideas es crear un capítulo ambientado en el Metro de Santiago.

Este nivel podría tener una dinámica de supervivencia, exploración de estaciones, recorridos por andenes y situaciones inesperadas dentro del transporte público.

Otra idea es desarrollar un capítulo ambientado en las micros de Santiago.

Aquí podría incluir nuevas mecánicas de supervivencia, encuentros con personajes, conflictos urbanos caricaturescos y situaciones de peligro dentro del transporte.

También me interesa utilizar otras ciudades chilenas, como Valparaíso, en futuros escenarios.

Sin embargo, todavía no hemos definido una historia definitiva para estos capítulos.

No quiero que inventes automáticamente misiones completas ni personajes nuevos como si ya estuvieran aprobados.

Prefiero que me entregues propuestas narrativas y de jugabilidad para evaluarlas.

20. LA IDENTIDAD VISUAL DEL VIDEOJUEGO

Quiero que toda la aventura mantenga un estilo visual pixel art retro.

La inspiración principal son los shooters clásicos en primera persona, pero con una identidad visual chilena.

Estamos utilizando Godot 4.

La estructura del escenario combina bloques tridimensionales, geometría sencilla, materiales y sprites pixel art.

Las fachadas de edificios pueden representarse con Sprite3D.

Los personajes y enemigos pueden utilizar AnimatedSprite3D.

Los edificios importantes que requieren interacción, como el Aurocentro, pueden construirse con bloques 3D y decoración pixel art.

No quiero que cada escenario tenga un estilo gráfico diferente.

Todos los recursos deben compartir una estética coherente.

Busco pixel art relativamente detallado, con un toque de realismo en las texturas y proporciones, pero sin llegar al fotorrealismo.

Los sprites deben ser legibles desde la cámara del jugador.

Las imágenes utilizadas como assets deben tener fondos transparentes cuando corresponda.

Quiero mantener colores, contornos, iluminación y resolución visual compatibles entre los diferentes personajes y escenarios.

21. QUÉ QUIERO CONSEGUIR CON LA EXPERIENCIA DEL JUGADOR

Quiero que el jugador experimente una progresión clara.

Primero, curiosidad: simplemente está explorando Paseo Ahumada después del trabajo.

Después, tensión: encuentra una manifestación y debe evitar problemas.

Luego, exploración: entra a la galería buscando su tienda.

Posteriormente, frustración y desafío: descubre que no tiene suficiente dinero para comprar lo que quiere.

Después, riesgo: conoce a Pepito, comienza a apostar y debe evitar que lo robe el ladrón.

Más adelante, satisfacción: finalmente consigue comprar la pistola de balines.

Luego, sorpresa: comienza a descubrir que ocurre algo absurdo en Plaza de Armas.

Finalmente, acción: debe enfrentarse a Rey Palomo y su ejército.

Quiero que todas estas sensaciones estén conectadas.

No quiero que el jugador sienta que está haciendo misiones completamente independientes sin una razón narrativa.

Cada acontecimiento debe conducir naturalmente al siguiente.

22. QUÉ SIGNIFICA EL PRIMER CAPÍTULO PARA MÍ

El primer capítulo tiene que funcionar como una presentación del mundo y del tono del videojuego.

Debe enseñar al jugador que esta versión de Santiago es familiar, pero impredecible.

Un problema cotidiano puede convertirse en un minijuego.

Un personaje callejero puede tener una mecánica propia.

Una galería comercial puede ser un espacio de exploración.

Una paloma puede convertirse en un jefe gigantesco.

Quiero que el jugador termine el capítulo pensando que no sabe qué situación absurda encontrará en el siguiente.

Esa curiosidad es fundamental para que quiera seguir jugando.

23. RESPUESTAS DIRECTAS A TUS PREGUNTAS

Pregunta 1: ¿Pepito paga doble es el pilar del capítulo o un apoyo?

Es una mecánica importante de la parte económica y una de las principales fuentes de tensión del primer capítulo.

Actualmente es el camino principal para conseguir el dinero de la pistola.

Sin embargo, no es el tema central de toda la historia. El eje central es una salida cotidiana que se transforma progresivamente en una aventura absurda.

Pepito es uno de los episodios de esa aventura.

Pregunta 2: ¿El cartel es el dilema central o un detalle?

Es una mecánica central durante la primera sección de Paseo Ahumada.

Quiero que el jugador deba aprender a utilizarlo correctamente, observando a manifestantes y policías.

Una vez superada esa parte, la historia debe avanzar hacia nuevos problemas y mecánicas.

Pregunta 3: ¿Es intencional que el dinero vuelva a $3.000 cuando la policía detiene al jugador?

No lo considero una decisión definitiva de diseño.

El jugador comienza con $10.000.

Quiero que revisemos la penalización por detención y definamos una consecuencia justa, consistente y fácil de entender.

No des por hecho que perder $7.000 es una regla narrativa aprobada.

Pregunta 4: ¿Qué ocurre con reiniciar_partida() en policia.gd?

Quiero que quede registrado como un posible problema técnico.

Antes de modificarlo, revisa cómo funciona actualmente la detención, qué método alternativo se ejecuta y qué efectos tendría corregirlo.

No quiero que una corrección rompa las físicas, las misiones o el reinicio del capítulo.

Pregunta 5: ¿Qué viene después del capítulo 1?

Quiero continuar la aventura por otros lugares de Chile.

Las ideas principales son el Metro de Santiago y las micros, con nuevas situaciones y mecánicas de supervivencia.

Más adelante podríamos incorporar Valparaíso y otros escenarios.

Por ahora son planes, no capítulos terminados.

Respecto al alcance del brief, quiero que se concentre en el primer capítulo y que incluya una sección breve de posibles expansiones futuras.

El menú principal, las opciones, la música definitiva, la pantalla de inicio, los créditos y las configuraciones finales siguen siendo tareas pendientes que podemos planificar.

24. INSTRUCCIONES PARA CONTINUAR EL DESARROLLO

Ahora que conoces mi visión, quiero que consideres esta historia como la base narrativa del videojuego.

Tu trabajo debe respetar las mecánicas que ya hemos desarrollado.

No simplifiques ni reemplaces sistemas funcionales simplemente porque existe una forma más corta de programarlos.

Cuando encuentres inconsistencias entre la historia y el código, quiero que me las informes.

No inventes decisiones narrativas definitivas para llenar vacíos sin distinguirlas de lo que ya hemos acordado.

Separa siempre:

A. Historia y mecánicas que ya están definidas o implementadas.

B. Problemas técnicos o inconsistencias que requieren revisión.

C. Nuevas propuestas narrativas o visuales que podemos evaluar.

También quiero que sepas que estamos entrando en una etapa importante de desarrollo visual.

Mi prioridad inmediata es mejorar la apariencia de Paseo Ahumada, la galería Aurocentro y Plaza de Armas.

Especialmente quiero construir una Catedral Metropolitana reconocible, porque será el escenario desde el cual aparece Rey Palomo.

Después podemos mejorar los personajes secundarios, las animaciones, los diálogos, el sonido ambiente y las escenas que conectan las distintas misiones.

25. QUÉ NECESITO QUE HAGAS AHORA

Con toda esta información, quiero que redactes un documento de diseño narrativo completo para el videojuego.

El documento debe explicar:

La premisa general del juego.

Quién es el protagonista y qué quiere conseguir.

Por qué está recorriendo el centro de Santiago.

La historia detallada del primer capítulo.

Cómo se conectan las misiones.

La función narrativa de los manifestantes, Carabineros, Pepito, el ladrón y el vendedor de la tienda.

La importancia del Aurocentro.

La transición hacia Plaza de Armas.

El papel de Rey Palomo y sus tres fases de combate.

El tono humorístico y la identidad chilena de la aventura.

La dirección artística pixel art.

Las ideas preliminares para capítulos futuros.

Los elementos narrativos pendientes de definir.

Las contradicciones o problemas que detectes entre la intención y el código.

Primero muéstrame el documento completo para revisarlo.

No reemplaces archivos del videojuego ni modifiques las escenas o los scripts.

Cuando apruebe el documento, podrás guardarlo en design/game-brief.md para que los futuros agentes de desarrollo comprendan la visión completa del proyecto.

Quiero que a partir de ese momento este documento funcione como referencia principal para la historia, las misiones y la identidad creativa del videojuego.

El objetivo final es desarrollar un FPS retro chileno con humor, personalidad, exploración, supervivencia y una historia que transforme un simple paseo después del trabajo en una aventura completamente inesperada.

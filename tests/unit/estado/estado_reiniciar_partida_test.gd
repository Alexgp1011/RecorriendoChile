extends GdUnitTestSuite
## EstadoJuego.reiniciar_partida(): una detencion devuelve la partida al
## estado de inicio del capitulo (decision del autor, 2026-11-22: el dinero
## vuelve a $10.000, no a $3.000). policia.gd la llama al detener al jugador.

const EstadoJuegoScript := preload("res://Scripts/EstadoJuego.gd")


func _estado_en_mitad_de_partida() -> Node:
	var estado: Node = auto_free(EstadoJuegoScript.new())
	estado.dinero = 87000
	estado.carteles_recogidos = 1
	estado.cartel_visible = true
	estado.tiene_pistola_balines = true
	estado.policia_alertada = true
	estado.ataque_palomas_iniciado = true
	estado.jefe_derrotado = true
	return estado


func test_reiniciar_partida_devuelve_el_dinero_inicial_de_10000() -> void:
	# Arrange
	var estado := _estado_en_mitad_de_partida()

	# Act
	estado.reiniciar_partida()

	# Assert
	assert_int(estado.dinero).is_equal(10000)


func test_reiniciar_partida_quita_el_cartel() -> void:
	# Arrange
	var estado := _estado_en_mitad_de_partida()

	# Act
	estado.reiniciar_partida()

	# Assert
	assert_int(estado.carteles_recogidos).is_equal(0)
	assert_bool(estado.cartel_visible).is_false()


func test_reiniciar_partida_restablece_pistola_y_banderas() -> void:
	# Arrange
	var estado := _estado_en_mitad_de_partida()

	# Act
	estado.reiniciar_partida()

	# Assert
	assert_bool(estado.tiene_pistola_balines).is_false()
	assert_bool(estado.policia_alertada).is_false()
	assert_bool(estado.ataque_palomas_iniciado).is_false()
	assert_bool(estado.jefe_derrotado).is_false()


func test_estado_nuevo_empieza_con_el_mismo_dinero_que_un_reinicio() -> void:
	# Arrange
	var nuevo: Node = auto_free(EstadoJuegoScript.new())
	var reiniciado := _estado_en_mitad_de_partida()

	# Act
	reiniciado.reiniciar_partida()

	# Assert
	assert_int(reiniciado.dinero).is_equal(nuevo.dinero)

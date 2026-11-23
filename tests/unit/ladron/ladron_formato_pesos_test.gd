extends GdUnitTestSuite
## enemy.gd (ladron): formatear_pesos agrupa los miles con punto, como en el
## mensaje "TE ROBARON $3.500!".

const Ladron := preload("res://Scripts/enemy.gd")


func test_formatear_pesos_con_miles_agrupa_con_punto() -> void:
	# Arrange — auto_free: un nodo que queda vivo es un huerfano (exit 101)
	var ladron: Node = auto_free(Ladron.new())

	# Act
	var texto: String = ladron.formatear_pesos(3500)

	# Assert
	assert_str(texto).is_equal("3.500")


func test_formatear_pesos_menor_que_mil_queda_igual() -> void:
	# Arrange
	var ladron: Node = auto_free(Ladron.new())

	# Act
	var texto: String = ladron.formatear_pesos(500)

	# Assert
	assert_str(texto).is_equal("500")


func test_formatear_pesos_millones_agrupa_cada_tres_cifras() -> void:
	# Arrange
	var ladron: Node = auto_free(Ladron.new())

	# Act
	var texto: String = ladron.formatear_pesos(1234567)

	# Assert
	assert_str(texto).is_equal("1.234.567")

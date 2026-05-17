extends Control

func _ready():
	$BotonJugar.pressed.connect(_on_boton_jugar_pressed)
	$BotonRanking.pressed.connect(_on_boton_ranking_pressed)
	# La música del menú la gestiona el autoload MenuMusic; aquí solo
	# nos aseguramos de que esté sonando (no-op si ya lo está).
	MenuMusic.play()

	# Recuperar el último nombre escrito si volvemos al menú dentro de la
	# misma sesión.
	$NombreInput.text = PlayerSession.player_name
	$NombreInput.text_changed.connect(_on_nombre_changed)
	_actualizar_estado_botones()

func _on_nombre_changed(_t: String):
	_actualizar_estado_botones()

func _actualizar_estado_botones():
	# JUGAR solo se habilita cuando hay un nombre escrito.
	$BotonJugar.disabled = $NombreInput.text.strip_edges().is_empty()

func _on_boton_jugar_pressed():
	var nombre = $NombreInput.text.strip_edges()
	if nombre.is_empty():
		return
	PlayerSession.player_name = nombre
	get_tree().change_scene_to_file("res://escenas/Mundo.tscn")

func _on_boton_ranking_pressed():
	get_tree().change_scene_to_file("res://escenas/Ranking.tscn")

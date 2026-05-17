extends Control

# Muestra el top de puntuaciones obtenidas mediante SilentWolf.

const FUENTE := preload("res://fuentes/PixelifySans-VariableFont_wght.ttf")
const COLOR_FILA := Color(1, 1, 1, 1)
const COLOR_FILA_JUGADOR := Color(1, 0.9, 0.3, 1)  # destaca al jugador actual

func _ready():
	# Asegurar que la música del menú esté sonando (no-op si ya suena).
	MenuMusic.play()
	$BotonVolver.pressed.connect(_volver_al_menu)
	_cargar_ranking()

func _volver_al_menu():
	get_tree().change_scene_to_file("res://escenas/MenuPrincipal.tscn")

func _cargar_ranking():
	$PanelLista/Estado.text = "Cargando ranking..."
	$PanelLista/Estado.visible = true
	$PanelLista/ScrollLista.visible = false

	# Top 20.  Si no hay internet la señal nunca se emite, así que usamos
	# un timeout para evitar quedarnos colgados eternamente.
	SilentWolf.Scores.get_scores(20)
	var result = await PlayerSession.await_or_timeout(SilentWolf.Scores, &"sw_get_scores_complete", 8.0)
	if result == null:
		$PanelLista/Estado.text = "Sin conexión con el ranking.\nInténtalo más tarde."
		return

	# Algunas versiones devuelven el array directamente, otras lo dejan en
	# SilentWolf.Scores.scores; cubrimos los dos casos.
	var scores: Array = []
	if typeof(result) == TYPE_DICTIONARY and result.has("scores"):
		scores = result.scores
	elif typeof(result) == TYPE_ARRAY:
		scores = result
	elif "scores" in SilentWolf.Scores:
		scores = SilentWolf.Scores.scores

	if scores.is_empty():
		$PanelLista/Estado.text = "Aún no hay puntuaciones.\n¡Sé el primero!"
		return

	$PanelLista/Estado.visible = false
	$PanelLista/ScrollLista.visible = true

	var lista := $PanelLista/ScrollLista/Lista
	for c in lista.get_children():
		c.queue_free()

	# Cabecera
	lista.add_child(_fila("#", "JUGADOR", "PUNTOS", Color(0.85, 0.7, 0.3, 1), 32, true))

	var i := 1
	for s in scores:
		var name = str(s.player_name) if "player_name" in s else "??"
		var score_v = int(s.score) if "score" in s else 0
		var color = COLOR_FILA
		if name == PlayerSession.player_name:
			color = COLOR_FILA_JUGADOR
		lista.add_child(_fila(str(i) + ".", name, str(score_v), color, 26))
		i += 1

func _fila(rank: String, name: String, score: String, color: Color, font_size: int, header := false) -> Control:
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if header:
		h.add_theme_constant_override("separation", 10)

	var l_rank := _label(rank, color, font_size)
	l_rank.custom_minimum_size = Vector2(70, 0)
	l_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var l_name := _label(name, color, font_size)
	l_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var l_score := _label(score, color, font_size)
	l_score.custom_minimum_size = Vector2(180, 0)
	l_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	h.add_child(l_rank)
	h.add_child(l_name)
	h.add_child(l_score)
	return h

func _label(text: String, color: Color, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

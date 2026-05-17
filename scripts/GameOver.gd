extends Control

func _ready():
	$SonidoGameOver.play()
	$BotonReiniciar.pressed.connect(_on_reiniciar_pressed)
	$BotonRanking.pressed.connect(_on_ver_ranking_pressed)
	$BotonSalir.pressed.connect(_on_salir_pressed)

	$PuntuacionFinal.text = "Puntuación final: %d" % PlayerSession.last_score

	# Subir la puntuación al ranking y mostrar la posición conseguida.
	# Se hace de forma asíncrona; mientras llega la respuesta el label
	# muestra "Subiendo puntuación...".
	_subir_y_mostrar_posicion()

func _subir_y_mostrar_posicion():
	var nombre = PlayerSession.player_name
	var puntos = PlayerSession.last_score
	if nombre.is_empty():
		$PosicionRanking.text = "(sin nombre, puntuación no enviada)"
		return

	# Persistir la puntuación con timeout (si no hay internet la señal
	# nunca se emite y la corrutina quedaría colgada para siempre).
	SilentWolf.Scores.save_score(nombre, puntos)
	var save_res = await PlayerSession.await_or_timeout(SilentWolf.Scores, &"sw_save_score_complete", 6.0)
	if save_res == null:
		$PosicionRanking.text = "Sin conexión con el ranking"
		return

	# Pedir la posición usando el score_id de la puntuación recién guardada,
	# NO el valor numérico: si pasáramos el valor, SilentWolf nos devolvería
	# la posición de un nuevo score hipotético (siempre +1 respecto a la real).
	var score_id := ""
	if typeof(save_res) == TYPE_DICTIONARY and save_res.has("score_id"):
		score_id = str(save_res.score_id)

	if score_id == "":
		# Sin score_id no podemos pedir la posición exacta; mostramos sin posición.
		$PosicionRanking.text = "Puntuación registrada"
		return

	SilentWolf.Scores.get_score_position(score_id)
	var pos_res = await PlayerSession.await_or_timeout(SilentWolf.Scores, &"sw_get_position_complete", 6.0)
	if pos_res == null:
		$PosicionRanking.text = "Puntuación registrada (posición no disponible)"
		return

	var pos = int(pos_res.get("position", 0)) if typeof(pos_res) == TYPE_DICTIONARY else 0
	PlayerSession.last_position = pos
	if pos > 0:
		$PosicionRanking.text = "Posición en el ranking: #%d" % pos
	else:
		$PosicionRanking.text = "Puntuación registrada"

func _on_reiniciar_pressed():
	get_tree().change_scene_to_file("res://escenas/Mundo.tscn")

func _on_ver_ranking_pressed():
	get_tree().change_scene_to_file("res://escenas/Ranking.tscn")

func _on_salir_pressed():
	get_tree().change_scene_to_file("res://escenas/MenuPrincipal.tscn")

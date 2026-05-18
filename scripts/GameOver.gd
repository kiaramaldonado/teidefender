extends Control

# Pantalla de fin de partida: muestra la mejor puntuación lograda, la sube
# al ranking de SilentWolf y muestra la posición conseguida.

const TIMEOUT_RED := 6.0  # s antes de rendirnos en una llamada a SilentWolf

func _ready():
	$SonidoGameOver.play()
	$BotonReiniciar.pressed.connect(_on_reiniciar_pressed)
	$BotonRanking.pressed.connect(_on_ver_ranking_pressed)
	$BotonSalir.pressed.connect(_on_salir_pressed)

	$PuntuacionFinal.text = "Puntuación final: %d" % PlayerSession.last_score
	_subir_y_mostrar_posicion()

func _subir_y_mostrar_posicion():
	if not PlayerSession.ranking_disponible:
		$PosicionRanking.text = "(ranking no configurado)"
		return

	var nombre: String = PlayerSession.player_name
	var puntos: int = PlayerSession.last_score
	if nombre.is_empty():
		$PosicionRanking.text = "(sin nombre, puntuación no enviada)"
		return

	# 1) Guardar la puntuación. Con timeout para evitar colgarnos si no
	#    hay red (SilentWolf no emite la señal en ese caso).
	SilentWolf.Scores.save_score(nombre, puntos)
	var save_res = await PlayerSession.await_or_timeout(
		SilentWolf.Scores, &"sw_save_score_complete", TIMEOUT_RED)
	if save_res == null:
		$PosicionRanking.text = "Sin conexión con el ranking"
		return

	# 2) Pedir la posición usando el score_id de la puntuación recién guardada.
	#    Si pasamos el valor numérico nos devuelve la de un score hipotético
	#    (siempre +1 respecto a la real).
	var score_id := ""
	if typeof(save_res) == TYPE_DICTIONARY and save_res.has("score_id"):
		score_id = str(save_res.score_id)
	if score_id.is_empty():
		$PosicionRanking.text = "Puntuación registrada"
		return

	SilentWolf.Scores.get_score_position(score_id)
	var pos_res = await PlayerSession.await_or_timeout(
		SilentWolf.Scores, &"sw_get_position_complete", TIMEOUT_RED)
	if pos_res == null:
		$PosicionRanking.text = "Puntuación registrada (posición no disponible)"
		return

	var pos := int(pos_res.get("position", 0)) if typeof(pos_res) == TYPE_DICTIONARY else 0
	PlayerSession.last_position = pos
	$PosicionRanking.text = "Posición en el ranking: #%d" % pos if pos > 0 else "Puntuación registrada"

func _on_reiniciar_pressed():
	get_tree().change_scene_to_file("res://escenas/Mundo.tscn")

func _on_ver_ranking_pressed():
	get_tree().change_scene_to_file("res://escenas/Ranking.tscn")

func _on_salir_pressed():
	get_tree().change_scene_to_file("res://escenas/MenuPrincipal.tscn")

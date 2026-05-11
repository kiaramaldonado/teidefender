extends Control

func _ready():
	$SonidoGameOver.play()
	$BotonReiniciar.pressed.connect(_on_reiniciar_pressed)
	$BotonSalir.pressed.connect(_on_salir_pressed)

func _on_reiniciar_pressed():
	get_tree().change_scene_to_file("res://escenas/Mundo.tscn")

func _on_salir_pressed():
	get_tree().change_scene_to_file("res://escenas/MenuPrincipal.tscn")

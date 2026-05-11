extends Control

func _ready():
	$BotonJugar.pressed.connect(_on_boton_jugar_pressed)
	$BGM.finished.connect(func(): $BGM.play())
	$BGM.play()

func _on_boton_jugar_pressed():
	get_tree().change_scene_to_file("res://escenas/Mundo.tscn")

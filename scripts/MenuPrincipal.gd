extends Control

const COLOR_NORMAL := Color(0.23, 0.13202, 0.066700004, 1)
const COLOR_HOVER := Color(1, 1, 1, 1)

func _ready():
	$BotonJugar.pressed.connect(_on_boton_jugar_pressed)
	$BotonJugar.mouse_entered.connect(_on_jugar_hover_in)
	$BotonJugar.mouse_exited.connect(_on_jugar_hover_out)
	$BGM.finished.connect(func(): $BGM.play())
	$BGM.play()

func _on_boton_jugar_pressed():
	get_tree().change_scene_to_file("res://escenas/Mundo.tscn")

func _on_jugar_hover_in():
	$BotonJugar/Texto.label_settings.font_color = COLOR_HOVER

func _on_jugar_hover_out():
	$BotonJugar/Texto.label_settings.font_color = COLOR_NORMAL

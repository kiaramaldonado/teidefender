extends Area2D

const TIPOS := ["platano", "clipper", "papel"]

func _ready():
	$Sprite.play(TIPOS[randi() % TIPOS.size()])
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Jugador":
		get_parent().basura_recogida()
		queue_free()

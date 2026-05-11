extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(5.0).timeout.connect(queue_free)

func _on_body_entered(body):
	if body.name == "Jugador":
		get_parent().violeta_pisada()
		queue_free()

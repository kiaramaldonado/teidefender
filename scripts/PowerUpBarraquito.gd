extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("activar_barraquito"):
		body.activar_barraquito()
		queue_free()

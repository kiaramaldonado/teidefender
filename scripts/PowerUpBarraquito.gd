extends Area2D

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)
	print("Barraquito listo")

func _on_body_entered(body):
	print("Contacto detectado")
	body.activar_barraquito()
	queue_free()

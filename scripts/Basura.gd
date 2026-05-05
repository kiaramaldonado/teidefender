extends Area2D

var tipos = ["platano", "clipper", "papel"]

func _ready():
	# Elegir tipo aleatorio
	var tipo = tipos[randi() % tipos.size()]
	$Sprite.play(tipo)
	
	# Detectar cuando Acorán la recoge
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Jugador":
		# Avisar al Mundo que se recogió basura
		get_parent().basura_recogida()
		queue_free()

extends CharacterBody2D

const VELOCIDAD = 150.0
var ultima_direccion = "down"

func _physics_process(delta):
	var direccion = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direccion.x += 1
	if Input.is_action_pressed("ui_left"):
		direccion.x -= 1
	if Input.is_action_pressed("ui_down"):
		direccion.y += 1
	if Input.is_action_pressed("ui_up"):
		direccion.y -= 1
	
	if direccion.length() > 0:
		direccion = direccion.normalized()
	
	velocity = direccion * VELOCIDAD
	move_and_slide()
	_actualizar_animacion(direccion)

func _actualizar_animacion(direccion: Vector2):
	if direccion.x > 0:
		ultima_direccion = "right"
	elif direccion.x < 0:
		ultima_direccion = "left"
	elif direccion.y > 0:
		ultima_direccion = "down"
	elif direccion.y < 0:
		ultima_direccion = "up"
	
	if direccion.length() > 0:
		$Sprite.play("walk_" + ultima_direccion)
	else:
		$Sprite.play("idle_" + ultima_direccion)

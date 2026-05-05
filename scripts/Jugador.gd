extends CharacterBody2D

const VELOCIDAD = 150.0

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
	
	# Normalizar para que en diagonal no vaya más rápido
	if direccion.length() > 0:
		direccion = direccion.normalized()
	
	velocity = direccion * VELOCIDAD
	move_and_slide()

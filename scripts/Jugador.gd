extends CharacterBody2D

const VELOCIDAD_NORMAL = 80.0
const VELOCIDAD_BOOST = 180.0
var velocidad_actual = VELOCIDAD_NORMAL
var ultima_direccion = "down"
var barraquito_activo = false
var bebiendo = false

func _physics_process(delta):
	if bebiendo:
		return
		
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
	
	velocity = direccion * velocidad_actual
	move_and_slide()
	_actualizar_animacion(direccion)

func _actualizar_animacion(direccion: Vector2):
	if bebiendo:
		return
		
	if direccion.x > 0:
		ultima_direccion = "right"
	elif direccion.x < 0:
		ultima_direccion = "left"
	elif direccion.y > 0:
		ultima_direccion = "down"
	elif direccion.y < 0:
		ultima_direccion = "up"
	
	if direccion.length() > 0:
		if barraquito_activo:
			$Sprite.play("run_" + ultima_direccion)
		else:
			$Sprite.play("walk_" + ultima_direccion)
	else:
		$Sprite.play("idle_" + ultima_direccion)

func activar_barraquito():
	bebiendo = true
	$Sprite.play("drink")
	# Esperar a que termine la animación de beber
	await $Sprite.animation_finished
	bebiendo = false
	barraquito_activo = true
	velocidad_actual = VELOCIDAD_BOOST
	
	# Barraquito dura 8 segundos
	await get_tree().create_timer(8.0).timeout
	barraquito_activo = false
	velocidad_actual = VELOCIDAD_NORMAL

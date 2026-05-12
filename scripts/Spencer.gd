extends CharacterBody2D

const VELOCIDAD = 55.0
const DISTANCIA_FLASH = 55.0
const COOLDOWN_FLASH = 6.0

var ultima_direccion = "down"
var timer_flash = 0.0
var usando_flash = false
var jugador = null
var nav_agent: NavigationAgent2D

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	nav_agent = $NavAgent

func _physics_process(delta):
	timer_flash -= delta

	if usando_flash:
		return
	if not jugador:
		return

	# Actualizar destino hacia el jugador cada frame
	nav_agent.target_position = jugador.global_position

	if jugador.global_position.distance_to(global_position) < DISTANCIA_FLASH and timer_flash <= 0:
		_ejecutar_flash()
		return

	if not nav_agent.is_navigation_finished():
		var siguiente = nav_agent.get_next_path_position()
		velocity = (siguiente - global_position).normalized() * VELOCIDAD
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_actualizar_animacion()

func _ejecutar_flash():
	usando_flash = true
	timer_flash = COOLDOWN_FLASH
	velocity = Vector2.ZERO
	if jugador:
		var diff = jugador.position - position
		if abs(diff.x) > abs(diff.y):
			ultima_direccion = "right" if diff.x > 0 else "left"
		else:
			ultima_direccion = "down" if diff.y > 0 else "up"
	$Sprite.play("flash_" + ultima_direccion)
	if jugador:
		jugador.recibir_flash()
	await $Sprite.animation_finished
	usando_flash = false

func _actualizar_animacion():
	if velocity.length() > 0:
		if abs(velocity.x) > abs(velocity.y):
			ultima_direccion = "right" if velocity.x > 0 else "left"
		else:
			ultima_direccion = "down" if velocity.y > 0 else "up"
		$Sprite.play("walk_" + ultima_direccion)
	else:
		$Sprite.play("idle_" + ultima_direccion)

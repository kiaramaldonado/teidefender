extends CharacterBody2D

const VELOCIDAD = 55.0
const DISTANCIA_FLASH = 55.0
const COOLDOWN_FLASH = 6.0
const REPLAN_INTERVALO = 0.4  # cada cuánto se refresca el destino sobre el jugador

var ultima_direccion = "down"
var timer_flash = 0.0
var timer_replan = 0.0
var usando_flash = false
var jugador = null
var nav_agent: NavigationAgent2D
var _nav_listo = false

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	nav_agent = $NavAgent
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 12.0
	# Esperar a que el nav mesh esté registrado
	await get_tree().process_frame
	await get_tree().physics_frame
	_nav_listo = true
	# Primer destino al jugador
	if jugador:
		nav_agent.target_position = jugador.global_position

func _physics_process(delta):
	if not _nav_listo or not jugador:
		return

	timer_flash -= delta

	if usando_flash:
		return

	# Refrescar destino periódicamente (no cada frame para no estresar al nav server)
	timer_replan -= delta
	if timer_replan <= 0:
		nav_agent.target_position = jugador.global_position
		timer_replan = REPLAN_INTERVALO

	var dist_jugador = jugador.global_position.distance_to(global_position)
	if dist_jugador < DISTANCIA_FLASH and timer_flash <= 0:
		_ejecutar_flash()
		return

	# Siempre intenta moverse siguiendo el camino. Si is_navigation_finished
	# devuelve true es porque ha "llegado" — en ese caso forzamos un repath
	# inmediato y movemos directamente hacia el jugador (corto alcance).
	if nav_agent.is_navigation_finished():
		nav_agent.target_position = jugador.global_position
		velocity = (jugador.global_position - global_position).normalized() * VELOCIDAD
	else:
		var siguiente = nav_agent.get_next_path_position()
		velocity = (siguiente - global_position).normalized() * VELOCIDAD

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

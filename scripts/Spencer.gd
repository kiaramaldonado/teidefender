extends CharacterBody2D

const VELOCIDAD = 55.0
const DISTANCIA_FLASH = 55.0
const COOLDOWN_FLASH = 6.0
const INTERVALO_DIR_MIN = 1.5
const INTERVALO_DIR_MAX = 3.0

var ultima_direccion = "down"
var timer_flash = 0.0
var timer_cambio = 0.0
var usando_flash = false
var jugador = null

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	_nueva_direccion()

func _physics_process(delta):
	timer_flash -= delta
	timer_cambio -= delta

	if usando_flash:
		return

	if jugador:
		var diff = jugador.position - position
		var distancia = diff.length()

		if distancia < DISTANCIA_FLASH and timer_flash <= 0:
			_ejecutar_flash()
			return

		# Sigue al jugador si está cerca, movimiento aleatorio si está lejos
		if distancia < 300:
			velocity = diff.normalized() * VELOCIDAD
		else:
			if timer_cambio <= 0:
				_nueva_direccion()

	var vel_antes = velocity
	move_and_slide()
	if vel_antes.length() > 0 and velocity.length() < vel_antes.length() * 0.3:
		_nueva_direccion()

	_actualizar_animacion()

func _nueva_direccion():
	timer_cambio = INTERVALO_DIR_MIN + randf() * (INTERVALO_DIR_MAX - INTERVALO_DIR_MIN)
	var dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	velocity = dirs[randi() % dirs.size()] * VELOCIDAD

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

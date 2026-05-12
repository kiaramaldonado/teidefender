extends CharacterBody2D

const VELOCIDAD = 60.0
const DISTANCIA_PUÑETAZO = 50.0
const COOLDOWN_PUÑETAZO = 3.0
const INTERVALO_DIR_MIN = 1.0
const INTERVALO_DIR_MAX = 2.5

var ultima_direccion = "down"
var timer_cambio = 0.0
var timer_puñetazo = 0.0
var golpeando = false
var jugador = null

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	_nueva_direccion()

func _physics_process(delta):
	timer_cambio -= delta
	timer_puñetazo -= delta

	if golpeando:
		return

	if jugador and timer_puñetazo <= 0:
		if position.distance_to(jugador.position) < DISTANCIA_PUÑETAZO:
			_ejecutar_puñetazo()
			return

	if timer_cambio <= 0:
		_nueva_direccion()

	var vel_antes = velocity
	move_and_slide()
	# Cambiar dirección si chocamos con algo
	if vel_antes.length() > 0 and velocity.length() < vel_antes.length() * 0.3:
		_nueva_direccion()

	_actualizar_animacion()

func _nueva_direccion():
	timer_cambio = INTERVALO_DIR_MIN + randf() * (INTERVALO_DIR_MAX - INTERVALO_DIR_MIN)
	var dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2.ZERO]
	velocity = dirs[randi() % dirs.size()] * VELOCIDAD
	if velocity.length() > 0:
		if abs(velocity.x) > abs(velocity.y):
			ultima_direccion = "left" if velocity.x > 0 else "right"
		else:
			ultima_direccion = "down" if velocity.y > 0 else "up"

func _ejecutar_puñetazo():
	golpeando = true
	timer_puñetazo = COOLDOWN_PUÑETAZO
	velocity = Vector2.ZERO

	if jugador:
		var diff = jugador.position - position
		if abs(diff.x) > abs(diff.y):
			ultima_direccion = "right" if diff.x > 0 else "left"
		else:
			ultima_direccion = "down" if diff.y > 0 else "up"

	$Sprite.play("punch_" + ultima_direccion)
	await $Sprite.animation_finished

	if jugador and position.distance_to(jugador.position) < DISTANCIA_PUÑETAZO * 1.5:
		jugador.recibir_puñetazo()

	golpeando = false

func _actualizar_animacion():
	if velocity.length() > 0:
		$Sprite.play("walk_" + ultima_direccion)
	else:
		$Sprite.play("idle_down")

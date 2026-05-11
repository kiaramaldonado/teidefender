extends CharacterBody2D

const VELOCIDAD = 45.0
const INTERVALO_DIR_MIN = 1.8
const INTERVALO_DIR_MAX = 3.5
const INTERVALO_VIOLETA = 15.0

var ultima_direccion = "down"
var timer_cambio = 0.0
var timer_violeta = 0.0

const VIOLETA_SCENE = preload("res://escenas/VioletaTeide.tscn")

func _ready():
	_nueva_direccion()
	timer_violeta = INTERVALO_VIOLETA

func _physics_process(delta):
	timer_cambio -= delta
	timer_violeta -= delta

	if timer_cambio <= 0:
		_nueva_direccion()

	if timer_violeta <= 0:
		_plantar_violeta()
		timer_violeta = INTERVALO_VIOLETA

	var vel_antes = velocity
	move_and_slide()
	if vel_antes.length() > 0 and velocity.length() < vel_antes.length() * 0.3:
		_nueva_direccion()

	_actualizar_animacion()

func _nueva_direccion():
	timer_cambio = INTERVALO_DIR_MIN + randf() * (INTERVALO_DIR_MAX - INTERVALO_DIR_MIN)
	var dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	velocity = dirs[randi() % dirs.size()] * VELOCIDAD

func _plantar_violeta():
	var violeta = VIOLETA_SCENE.instantiate()
	violeta.position = position
	get_parent().add_child(violeta)

func _actualizar_animacion():
	if velocity.length() > 0:
		if abs(velocity.x) > abs(velocity.y):
			ultima_direccion = "right" if velocity.x > 0 else "left"
		else:
			ultima_direccion = "down" if velocity.y > 0 else "up"
		$Sprite.play("walk_" + ultima_direccion)
	else:
		$Sprite.play("idle_" + ultima_direccion)

extends CharacterBody2D

const Maze = preload("res://scripts/Maze.gd")

# Tato patrulla en estilo Pac-Man: avanza por corredores, en cada cruce
# elige una nueva dirección (evitando media vuelta).  Si el jugador
# entra en su celda actual o adyacente, le suelta un puñetazo.

const VELOCIDAD = 95.0
const DISTANCIA_PUÑETAZO = 56.0
const COOLDOWN_PUÑETAZO = 3.0

var ultima_direccion = "down"
var timer_puñetazo = 0.0
var golpeando = false
var jugador = null

var _dir: Vector2i = Vector2i.ZERO
var _target_cell: Vector2i = Vector2i.ZERO
var _target_world: Vector2 = Vector2.ZERO

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	var cell = Maze.world_to_cell(global_position)
	global_position = Maze.cell_to_world(cell)
	_target_cell = cell
	_target_world = global_position
	_elegir_siguiente_direccion()

func _physics_process(delta):
	timer_puñetazo -= delta
	if golpeando:
		return

	if jugador and timer_puñetazo <= 0:
		if global_position.distance_to(jugador.global_position) < DISTANCIA_PUÑETAZO:
			_ejecutar_puñetazo()
			return

	var to_target = _target_world - global_position
	var paso = VELOCIDAD * delta
	if to_target.length() <= paso:
		global_position = _target_world
		velocity = Vector2.ZERO
		_elegir_siguiente_direccion()
	else:
		velocity = to_target.normalized() * VELOCIDAD
		move_and_slide()
	_actualizar_animacion()

func _elegir_siguiente_direccion():
	var aqui = Maze.world_to_cell(global_position)
	var vecinos = Maze.neighbours(aqui)
	if vecinos.size() == 0:
		_target_world = global_position
		return
	var reverso = -_dir
	var opciones = vecinos.duplicate()
	if vecinos.size() > 1 and reverso in opciones:
		opciones.erase(reverso)
	_dir = opciones[randi() % opciones.size()]
	_target_cell = aqui + _dir
	_target_world = Maze.cell_to_world(_target_cell)

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
	# Sprites de Tato tienen izquierda/derecha invertidos
	if _dir == Maze.DIR_E:
		ultima_direccion = "left"
	elif _dir == Maze.DIR_W:
		ultima_direccion = "right"
	elif _dir == Maze.DIR_N:
		ultima_direccion = "up"
	elif _dir == Maze.DIR_S:
		ultima_direccion = "down"
	$Sprite.play("walk_" + ultima_direccion)

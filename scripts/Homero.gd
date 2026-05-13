extends CharacterBody2D

const Maze = preload("res://scripts/Maze.gd")

# Homero patrulla el laberinto en estilo Pac-Man: avanza por corredores
# y en cada cruce elige una dirección al azar (evitando dar media vuelta).
# Cada cierto tiempo planta una violeta en la celda donde está.

const VELOCIDAD = 55.0            # más lento que el jugador (80)
const INTERVALO_VIOLETA = 7.0     # Homero planta más a menudo

var ultima_direccion = "down"
var timer_violeta = 0.0

var _dir: Vector2i = Vector2i.ZERO
var _target_cell: Vector2i = Vector2i.ZERO
var _target_world: Vector2 = Vector2.ZERO

const VIOLETA_SCENE = preload("res://escenas/VioletaTeide.tscn")

func _ready():
	timer_violeta = INTERVALO_VIOLETA
	var cell = Maze.world_to_cell(global_position)
	global_position = Maze.cell_to_world(cell)
	_target_cell = cell
	_target_world = global_position
	_elegir_siguiente_direccion()

func _physics_process(delta):
	timer_violeta -= delta
	if timer_violeta <= 0:
		_plantar_violeta()
		timer_violeta = INTERVALO_VIOLETA

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
	# Evitar dar media vuelta si hay alternativas
	var reverso = -_dir
	var opciones = vecinos.duplicate()
	if vecinos.size() > 1 and reverso in opciones:
		opciones.erase(reverso)
	_dir = opciones[randi() % opciones.size()]
	_target_cell = aqui + _dir
	_target_world = Maze.cell_to_world(_target_cell)

func _plantar_violeta():
	var violeta = VIOLETA_SCENE.instantiate()
	violeta.position = position
	get_parent().add_child(violeta)

func _actualizar_animacion():
	if _dir == Maze.DIR_E:
		ultima_direccion = "right"
	elif _dir == Maze.DIR_W:
		ultima_direccion = "left"
	elif _dir == Maze.DIR_N:
		ultima_direccion = "up"
	elif _dir == Maze.DIR_S:
		ultima_direccion = "down"
	$Sprite.play("walk_" + ultima_direccion)

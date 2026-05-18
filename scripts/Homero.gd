extends CharacterBody2D

const Maze = preload("res://scripts/Maze.gd")

# Homero patrulla el laberinto en estilo Pac-Man: avanza por corredores
# y en cada cruce elige una dirección al azar (evitando dar media vuelta).
# Cada cierto tiempo planta una violeta en la celda donde está.

const VELOCIDAD_BASE = 40.0       # base; se multiplica por Mundo.factor_enemigo()
const INTERVALO_VIOLETA_BASE = 12.0  # se divide por factor_spawn() del Mundo

var ultima_direccion = "down"
var timer_violeta = 0.0

const VIOLETA_SCENE = preload("res://escenas/VioletaTeide.tscn")

var _dir: Vector2i = Vector2i.ZERO
var _target_world: Vector2 = Vector2.ZERO

func _velocidad_actual() -> float:
	var m = get_parent()
	if m and m.has_method("factor_enemigo"):
		return VELOCIDAD_BASE * m.factor_enemigo()
	return VELOCIDAD_BASE

func _intervalo_violeta() -> float:
	var m = get_parent()
	if m and m.has_method("factor_spawn"):
		return INTERVALO_VIOLETA_BASE / m.factor_spawn()
	return INTERVALO_VIOLETA_BASE

func _ready():
	timer_violeta = _intervalo_violeta()
	global_position = Maze.cell_to_world(Maze.world_to_cell(global_position))
	_target_world = global_position
	_elegir_siguiente_direccion()

func _physics_process(delta):
	timer_violeta -= delta
	if timer_violeta <= 0:
		_plantar_violeta()
		timer_violeta = _intervalo_violeta()

	var to_target = _target_world - global_position
	var paso = _velocidad_actual() * delta
	if to_target.length() <= paso:
		global_position = _target_world
		velocity = Vector2.ZERO
		_elegir_siguiente_direccion()
	else:
		velocity = to_target.normalized() * _velocidad_actual()
		move_and_slide()
	_actualizar_animacion()

func _elegir_siguiente_direccion():
	var aqui = Maze.world_to_cell(global_position)
	var vecinos = Maze.neighbours(aqui)
	if vecinos.is_empty():
		_target_world = global_position
		return
	# Evitar dar media vuelta si hay alternativas.
	var opciones = vecinos.duplicate()
	if vecinos.size() > 1 and -_dir in opciones:
		opciones.erase(-_dir)
	_dir = opciones[randi() % opciones.size()]
	_target_world = Maze.cell_to_world(aqui + _dir)

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

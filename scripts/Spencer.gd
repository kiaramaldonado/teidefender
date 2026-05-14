extends CharacterBody2D

const Maze = preload("res://scripts/Maze.gd")

# Spencer persigue al jugador en una cuadrícula de Pac-Man.
# Se mueve celda a celda en una de las cuatro direcciones cardinales;
# nunca atraviesa muros porque solo elige direcciones donde la siguiente
# celda es corredor.

const VELOCIDAD_BASE = 55.0       # base; se multiplica por Mundo.factor_enemigo()
const DISTANCIA_FLASH = 60.0
const COOLDOWN_FLASH = 6.0

var ultima_direccion = "down"
var timer_flash = 0.0
var usando_flash = false
var jugador = null

var _dir: Vector2i = Vector2i.ZERO       # dirección actual de avance
var _target_cell: Vector2i = Vector2i.ZERO
var _target_world: Vector2 = Vector2.ZERO

func _velocidad_actual() -> float:
	var m = get_parent()
	if m and m.has_method("factor_enemigo"):
		return VELOCIDAD_BASE * m.factor_enemigo()
	return VELOCIDAD_BASE

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	# Alinear posición inicial a una celda y elegir primer destino
	var cell = Maze.world_to_cell(global_position)
	global_position = Maze.cell_to_world(cell)
	_target_cell = cell
	_target_world = global_position
	_elegir_siguiente_direccion()

func _physics_process(delta):
	timer_flash -= delta
	if usando_flash:
		return
	if not jugador:
		return

	# Flash si el jugador está muy cerca
	var dist = jugador.global_position.distance_to(global_position)
	if dist < DISTANCIA_FLASH and timer_flash <= 0:
		_ejecutar_flash()
		return

	# Avanzar hacia el target_world
	var to_target = _target_world - global_position
	var paso = _velocidad_actual() * delta
	if to_target.length() <= paso:
		# Llegamos a la celda destino: snap y elegir nuevo destino
		global_position = _target_world
		velocity = Vector2.ZERO
		_elegir_siguiente_direccion()
	else:
		velocity = to_target.normalized() * _velocidad_actual()
		move_and_slide()
	_actualizar_animacion()

func _elegir_siguiente_direccion():
	# Spencer: BFS hacia la celda del jugador.
	var aqui = Maze.world_to_cell(global_position)
	_target_cell = aqui
	var celda_jugador = Maze.world_to_cell(jugador.global_position) if jugador else aqui
	# Asegurar que la celda objetivo del jugador es válida; si no, buscar la más cercana
	if not Maze.is_corridor(celda_jugador):
		celda_jugador = _celda_corredor_mas_cercana(jugador.global_position)
	var dir = Maze.direction_towards(aqui, celda_jugador)
	if dir == Vector2i.ZERO:
		# Ya está en la misma celda o no hay camino: elegir cualquier vecino válido
		var vecinos = Maze.neighbours(aqui)
		if vecinos.size() == 0:
			_target_world = global_position
			return
		dir = vecinos[randi() % vecinos.size()]
	_dir = dir
	_target_cell = aqui + _dir
	_target_world = Maze.cell_to_world(_target_cell)

func _celda_corredor_mas_cercana(world_pos: Vector2) -> Vector2i:
	# Recorre todas las celdas de corredor y elige la más cercana al jugador.
	var celdas = Maze.all_corridor_cells()
	var mejor = celdas[0]
	var mejor_d = INF
	for c in celdas:
		var d = Maze.cell_to_world(c).distance_squared_to(world_pos)
		if d < mejor_d:
			mejor_d = d
			mejor = c
	return mejor

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
	# Convertir _dir cardinal a la cadena de animación
	if _dir == Maze.DIR_E:
		ultima_direccion = "right"
	elif _dir == Maze.DIR_W:
		ultima_direccion = "left"
	elif _dir == Maze.DIR_N:
		ultima_direccion = "up"
	elif _dir == Maze.DIR_S:
		ultima_direccion = "down"
	# Siempre walk: estamos siempre en marcha entre celdas
	$Sprite.play("walk_" + ultima_direccion)

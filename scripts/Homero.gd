extends CharacterBody2D

const VELOCIDAD = 45.0
const INTERVALO_VIOLETA = 15.0
const STUCK_CHECK = 0.5            # cada 0.5s comprobamos si avanzó
const STUCK_MIN_DIST = 6.0         # menos de esto = atascado
const STUCK_LIMITE = 1.2           # tras 1.2s atascado, cambia de meta
const MIN_DIST_WAYPOINT = 180.0    # los nuevos destinos deben estar al menos a esta distancia

var ultima_direccion = "down"
var timer_violeta = 0.0
var nav_agent: NavigationAgent2D
var _nav_listo = false
var _ultima_meta_idx = -1
var _pos_anterior = Vector2.ZERO
var _stuck_check_timer = 0.0
var _stuck_acumulado = 0.0

const WAYPOINTS = [
	Vector2(200, 130), Vector2(280, 130), Vector2(350, 130),
	Vector2(550, 130), Vector2(650, 130), Vector2(750, 130),
	Vector2(170, 250), Vector2(184, 328), Vector2(184, 392),
	Vector2(450, 200), Vector2(520, 200), Vector2(600, 200),
	Vector2(344, 360), Vector2(424, 360), Vector2(510, 350),
	Vector2(700, 280), Vector2(780, 280), Vector2(860, 280),
	Vector2(250, 480), Vector2(350, 480), Vector2(430, 480),
	Vector2(616, 472), Vector2(720, 480), Vector2(820, 480),
	Vector2(900, 380), Vector2(904, 424), Vector2(970, 420),
]

const VIOLETA_SCENE = preload("res://escenas/VioletaTeide.tscn")

func _ready():
	nav_agent = $NavAgent
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 8.0
	timer_violeta = INTERVALO_VIOLETA
	_pos_anterior = global_position
	# Esperar a que el nav mesh esté listo
	await get_tree().process_frame
	await get_tree().physics_frame
	_nav_listo = true
	nav_agent.navigation_finished.connect(_nueva_meta)
	_nueva_meta()

func _physics_process(delta):
	if not _nav_listo:
		return

	timer_violeta -= delta
	if timer_violeta <= 0:
		_plantar_violeta()
		timer_violeta = INTERVALO_VIOLETA

	# --- Detección de atasco ---
	_stuck_check_timer += delta
	if _stuck_check_timer >= STUCK_CHECK:
		var avance = global_position.distance_to(_pos_anterior)
		if avance < STUCK_MIN_DIST:
			_stuck_acumulado += _stuck_check_timer
			if _stuck_acumulado >= STUCK_LIMITE:
				_nueva_meta()
				_stuck_acumulado = 0.0
		else:
			_stuck_acumulado = 0.0
		_pos_anterior = global_position
		_stuck_check_timer = 0.0

	# --- Movimiento constante ---
	if nav_agent.is_navigation_finished():
		# Sin pausa: pedir otra meta inmediatamente
		_nueva_meta()

	var siguiente = nav_agent.get_next_path_position()
	var dir = (siguiente - global_position)
	if dir.length() > 0.01:
		velocity = dir.normalized() * VELOCIDAD
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_actualizar_animacion()

func _nueva_meta():
	# Elegir un waypoint que:
	#   - no sea el mismo que el anterior
	#   - esté lo bastante lejos para forzar atravesar el mapa
	var mejor = -1
	var mejor_dist = 0.0
	for _i in range(15):
		var idx = randi() % WAYPOINTS.size()
		if idx == _ultima_meta_idx:
			continue
		var d = WAYPOINTS[idx].distance_to(global_position)
		if d > MIN_DIST_WAYPOINT and d > mejor_dist:
			mejor = idx
			mejor_dist = d
	if mejor == -1:
		# Fallback: cualquiera que no sea el anterior
		mejor = randi() % WAYPOINTS.size()
		while mejor == _ultima_meta_idx and WAYPOINTS.size() > 1:
			mejor = randi() % WAYPOINTS.size()
	_ultima_meta_idx = mejor
	nav_agent.target_position = WAYPOINTS[mejor]

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

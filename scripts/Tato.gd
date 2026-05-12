extends CharacterBody2D

const VELOCIDAD = 60.0
const DISTANCIA_PUÑETAZO = 50.0
const COOLDOWN_PUÑETAZO = 3.0
const STUCK_CHECK = 0.5
const STUCK_MIN_DIST = 6.0
const STUCK_LIMITE = 1.2
const MIN_DIST_WAYPOINT = 180.0

var ultima_direccion = "down"
var timer_puñetazo = 0.0
var golpeando = false
var jugador = null
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

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	nav_agent = $NavAgent
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 8.0
	_pos_anterior = global_position
	await get_tree().process_frame
	await get_tree().physics_frame
	_nav_listo = true
	nav_agent.navigation_finished.connect(_nueva_meta)
	_nueva_meta()

func _physics_process(delta):
	if not _nav_listo:
		return

	timer_puñetazo -= delta

	if golpeando:
		return

	if jugador and timer_puñetazo <= 0:
		if position.distance_to(jugador.position) < DISTANCIA_PUÑETAZO:
			_ejecutar_puñetazo()
			return

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
		mejor = randi() % WAYPOINTS.size()
		while mejor == _ultima_meta_idx and WAYPOINTS.size() > 1:
			mejor = randi() % WAYPOINTS.size()
	_ultima_meta_idx = mejor
	nav_agent.target_position = WAYPOINTS[mejor]

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
		# Sprites de Tato tienen izquierda/derecha invertidos
		if abs(velocity.x) > abs(velocity.y):
			ultima_direccion = "left" if velocity.x > 0 else "right"
		else:
			ultima_direccion = "down" if velocity.y > 0 else "up"
		$Sprite.play("walk_" + ultima_direccion)
	else:
		$Sprite.play("idle_down")

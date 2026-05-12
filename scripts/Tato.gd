extends CharacterBody2D

const VELOCIDAD = 60.0
const DISTANCIA_PUÑETAZO = 50.0
const COOLDOWN_PUÑETAZO = 3.0

var ultima_direccion = "down"
var timer_puñetazo = 0.0
var golpeando = false
var jugador = null
var nav_agent: NavigationAgent2D

const WAYPOINTS = [
	Vector2(200, 130), Vector2(280, 130), Vector2(350, 130),
	Vector2(550, 130), Vector2(650, 130), Vector2(750, 130),
	Vector2(170, 250), Vector2(170, 320), Vector2(170, 390),
	Vector2(450, 200), Vector2(520, 200), Vector2(600, 200),
	Vector2(350, 350), Vector2(430, 350), Vector2(510, 350),
	Vector2(700, 280), Vector2(780, 280), Vector2(860, 280),
	Vector2(250, 480), Vector2(350, 480), Vector2(430, 480),
	Vector2(620, 480), Vector2(720, 480), Vector2(820, 480),
	Vector2(900, 380), Vector2(900, 450), Vector2(970, 420),
]

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	nav_agent = $NavAgent
	nav_agent.navigation_finished.connect(_nueva_meta)
	await get_tree().process_frame
	_nueva_meta()

func _physics_process(delta):
	timer_puñetazo -= delta

	if golpeando:
		return

	if jugador and timer_puñetazo <= 0:
		if position.distance_to(jugador.position) < DISTANCIA_PUÑETAZO:
			_ejecutar_puñetazo()
			return

	if not nav_agent.is_navigation_finished():
		var siguiente = nav_agent.get_next_path_position()
		velocity = (siguiente - global_position).normalized() * VELOCIDAD
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_actualizar_animacion()

func _nueva_meta():
	nav_agent.target_position = WAYPOINTS[randi() % WAYPOINTS.size()]

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

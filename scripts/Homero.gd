extends CharacterBody2D

const VELOCIDAD = 45.0
const INTERVALO_VIOLETA = 15.0

var ultima_direccion = "down"
var timer_violeta = 0.0
var nav_agent: NavigationAgent2D
var _nav_listo = false

const WAYPOINTS = [
	Vector2(200, 130), Vector2(280, 130), Vector2(350, 130),
	Vector2(550, 130), Vector2(650, 130), Vector2(750, 130),
	Vector2(170, 250), Vector2(184, 328), Vector2(184, 392),  # (170,320) y (170,390) estaban dentro de valla
	Vector2(450, 200), Vector2(520, 200), Vector2(600, 200),
	Vector2(344, 360), Vector2(424, 360), Vector2(510, 350),  # (350,350) y (430,350) estaban dentro de valla
	Vector2(700, 280), Vector2(780, 280), Vector2(860, 280),
	Vector2(250, 480), Vector2(350, 480), Vector2(430, 480),
	Vector2(616, 472), Vector2(720, 480), Vector2(820, 480),  # (620,480) estaba dentro de valla
	Vector2(900, 380), Vector2(904, 424), Vector2(970, 420),  # (900,450) estaba dentro de valla
]

const VIOLETA_SCENE = preload("res://escenas/VioletaTeide.tscn")

func _ready():
	nav_agent = $NavAgent
	timer_violeta = INTERVALO_VIOLETA
	# Esperar a que Mundo._ready() haya creado el nav mesh y el servidor lo procese
	await get_tree().process_frame
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

	if not nav_agent.is_navigation_finished():
		var siguiente = nav_agent.get_next_path_position()
		velocity = (siguiente - global_position).normalized() * VELOCIDAD
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_actualizar_animacion()

func _nueva_meta():
	nav_agent.target_position = WAYPOINTS[randi() % WAYPOINTS.size()]

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

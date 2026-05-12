extends CharacterBody2D

const VELOCIDAD = 45.0
const INTERVALO_VIOLETA = 15.0

var ultima_direccion = "down"
var timer_violeta = 0.0
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

const VIOLETA_SCENE = preload("res://escenas/VioletaTeide.tscn")

func _ready():
	nav_agent = $NavAgent
	nav_agent.navigation_finished.connect(_nueva_meta)
	timer_violeta = INTERVALO_VIOLETA
	# Esperar un frame para que el nav mesh esté listo
	await get_tree().process_frame
	_nueva_meta()

func _physics_process(delta):
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

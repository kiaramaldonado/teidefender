extends Node2D

const BASURA_SCENE = preload("res://escenas/Basura.tscn")
var puntos = 0
const BARRAQUITO_SCENE = preload("res://escenas/PowerUpBarraquito.tscn")

# Posiciones aleatorias dentro del laberinto
var spawn_points = [
	# Pasillo superior izquierdo
	Vector2(200, 130), Vector2(280, 130), Vector2(350, 130),
	# Pasillo superior derecho
	Vector2(550, 130), Vector2(650, 130), Vector2(750, 130),
	# Pasillo izquierdo vertical
	Vector2(170, 250), Vector2(170, 320), Vector2(170, 390),
	# Zona central superior
	Vector2(450, 200), Vector2(520, 200), Vector2(600, 200),
	# Pasillo central horizontal
	Vector2(350, 350), Vector2(430, 350), Vector2(510, 350),
	# Zona central derecha
	Vector2(700, 280), Vector2(780, 280), Vector2(860, 280),
	# Pasillo inferior izquierdo
	Vector2(250, 480), Vector2(350, 480), Vector2(430, 480),
	# Pasillo inferior derecho
	Vector2(620, 480), Vector2(720, 480), Vector2(820, 480),
	# Zona derecha interior
	Vector2(900, 380), Vector2(900, 450), Vector2(970, 420),
]
func _ready():
	# Aparecer basura cada 5 segundos
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 5.0
	timer.timeout.connect(_spawn_basura)
	timer.start()
	
	var timer_barraquito = Timer.new()
	add_child(timer_barraquito)
	timer_barraquito.wait_time = 20.0
	timer_barraquito.timeout.connect(_spawn_barraquito)
	timer_barraquito.start()
	
	$HUD/Puntos.text = "0"
	
	# Spawn inicial
	_spawn_basura()

func _spawn_basura():
	var basura = BASURA_SCENE.instantiate()
	var punto = spawn_points[randi() % spawn_points.size()]
	basura.position = punto
	add_child(basura)

func basura_recogida():
	puntos += 25
	$HUD/Puntos.text = str(puntos)

func _spawn_barraquito():
	var barraquito = BARRAQUITO_SCENE.instantiate()
	var punto = spawn_points[randi() % spawn_points.size()]
	barraquito.position = punto
	add_child(barraquito)

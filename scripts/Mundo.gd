extends Node2D

const BASURA_SCENE = preload("res://escenas/Basura.tscn")
var puntos = 0

# Posiciones aleatorias dentro del laberinto
var spawn_points = [
	Vector2(400, 250), Vector2(500, 250), Vector2(600, 250),
	Vector2(400, 350), Vector2(500, 350), Vector2(600, 350),
	Vector2(400, 450), Vector2(500, 450), Vector2(600, 450)
]

func _ready():
	# Aparecer basura cada 5 segundos
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 5.0
	timer.timeout.connect(_spawn_basura)
	timer.start()
	
	# Spawn inicial
	_spawn_basura()

func _spawn_basura():
	var basura = BASURA_SCENE.instantiate()
	var punto = spawn_points[randi() % spawn_points.size()]
	basura.position = punto
	add_child(basura)

func basura_recogida():
	puntos += 25
	print("Puntos: ", puntos)

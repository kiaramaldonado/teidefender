extends Node2D

const BASURA_SCENE = preload("res://escenas/Basura.tscn")
const BARRAQUITO_SCENE = preload("res://escenas/PowerUpBarraquito.tscn")
const Maze = preload("res://scripts/Maze.gd")
const MAX_BASURA = 16  # gran colchón: cada bolsa baja la barra ~6 %

var puntos = 200
var basura_en_campo = 0
var partida_terminada = false
var timer_barraquito_restante = 0.0
var barraquito_corriendo = false
var rush_activo = false

# Posibles centros de celdas-corredor donde puede aparecer basura/barraquito.
# Las celdas reservadas para jugador/enemigos no están aquí.
var spawn_points: Array[Vector2] = []

var _timer_basura: Timer
var _timer_powerup: Timer

func _ready():
	# Construir spawn_points como todos los centros de celda de corredor,
	# excepto las celdas iniciales de los personajes.
	var reservadas = [
		Vector2i(9, 9),   # jugador
		Vector2i(4, 1),   # Tato
		Vector2i(1, 5),   # Homero
		Vector2i(17, 5),  # Spencer
	]
	for c in Maze.all_corridor_cells():
		if c in reservadas:
			continue
		spawn_points.append(Maze.cell_to_world(c))

	# Timers de aparición con intervalos aleatorios
	_timer_basura = Timer.new()
	_timer_basura.one_shot = true
	add_child(_timer_basura)
	_timer_basura.timeout.connect(_on_timer_basura)
	_timer_basura.start(randf_range(3.5, 5.0))

	_timer_powerup = Timer.new()
	_timer_powerup.one_shot = true
	add_child(_timer_powerup)
	_timer_powerup.timeout.connect(_on_timer_powerup)
	_timer_powerup.start(randf_range(17.0, 24.0))

	$HUD/Banner/Puntos.text = str(puntos)
	$HUD/BarraIntegridad.value = 100
	$HUD/TimerBarraquito.visible = false
	$HUD/PantallaBlanca.visible = false
	$HUD/MenuPausa.visible = false

	$HUD/BotonPausa.pressed.connect(_toggle_pausa)
	$HUD/MenuPausa/BotonReanudar.pressed.connect(_toggle_pausa)
	$HUD/MenuPausa/BotonSalir.pressed.connect(_ir_al_menu)

	$SonidoRush.finished.connect(func():
		if rush_activo:
			$SonidoRush.play()
	)
	$BGM.finished.connect(func(): $BGM.play())
	$BGM.play()

	# Basura inicial: el jugador empieza con varias bolsas a la vista
	for i in range(5):
		_spawn_basura()

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pausa()

	if barraquito_corriendo:
		timer_barraquito_restante -= delta
		if timer_barraquito_restante > 0:
			$HUD/TimerBarraquito.text = "Barraquito: " + str(snapped(timer_barraquito_restante, 0.1)) + "s"
		else:
			$HUD/TimerBarraquito.visible = false
			barraquito_corriendo = false

func _toggle_pausa():
	get_tree().paused = !get_tree().paused
	$HUD/MenuPausa.visible = get_tree().paused

func _ir_al_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://escenas/MenuPrincipal.tscn")

func activar_barraquito_efectos():
	$SonidoBarraquito.play()
	barraquito_corriendo = true
	timer_barraquito_restante = 8.0
	$HUD/TimerBarraquito.visible = true

func desactivar_barraquito_efectos():
	barraquito_corriendo = false
	$HUD/TimerBarraquito.visible = false

func activar_ceguera():
	$SonidoFlash.play()
	$HUD/PantallaBlanca.visible = true
	await get_tree().create_timer(3.0).timeout
	if not partida_terminada:
		$HUD/PantallaBlanca.visible = false

func _on_timer_basura():
	_spawn_basura()
	# La presión sube muy despacio: 4 minutos hasta el mínimo, y el mínimo
	# es 85 % del intervalo base. El ritmo es vivo pero nunca abrumador.
	var presion = clamp(1.0 - (Time.get_ticks_msec() / 240000.0), 0.85, 1.0)
	_timer_basura.start(randf_range(3.5, 5.0) * presion)

func _on_timer_powerup():
	_spawn_barraquito()
	_timer_powerup.start(randf_range(17.0, 24.0))

func _spawn_basura():
	if partida_terminada or basura_en_campo >= MAX_BASURA or spawn_points.is_empty():
		return
	var basura = BASURA_SCENE.instantiate()
	basura.position = spawn_points[randi() % spawn_points.size()]
	add_child(basura)
	basura_en_campo += 1
	_actualizar_integridad()

func basura_recogida():
	puntos += 25
	basura_en_campo -= 1
	$HUD/Banner/Puntos.text = str(puntos)
	$SonidoDing.play()
	_actualizar_integridad()

func violeta_pisada():
	jugador_recibe_daño(50, "hojas")

func jugador_recibe_daño(cantidad: int, tipo: String):
	puntos -= cantidad
	if puntos < 0:
		puntos = 0
	$HUD/Banner/Puntos.text = str(puntos)

	match tipo:
		"punch":
			$SonidoPuñetazo.play()
		"hojas":
			$SonidoHojas.play()

	if puntos <= 0:
		game_over()

func _actualizar_integridad():
	var porcentaje = float(basura_en_campo) / float(MAX_BASURA)
	$HUD/BarraIntegridad.value = 100.0 * (1.0 - porcentaje)

	if basura_en_campo >= MAX_BASURA:
		game_over()
	elif porcentaje >= 0.6:
		if not rush_activo:
			rush_activo = true
			$SonidoRush.play()
	else:
		if rush_activo:
			rush_activo = false
			$SonidoRush.stop()

func game_over():
	if partida_terminada:
		return
	partida_terminada = true
	get_tree().paused = false
	$BGM.stop()
	$SonidoRush.stop()
	get_tree().change_scene_to_file("res://escenas/GameOver.tscn")

func _spawn_barraquito():
	if partida_terminada or spawn_points.is_empty():
		return
	var barraquito = BARRAQUITO_SCENE.instantiate()
	barraquito.position = spawn_points[randi() % spawn_points.size()]
	add_child(barraquito)

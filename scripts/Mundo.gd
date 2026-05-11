extends Node2D

const BASURA_SCENE = preload("res://escenas/Basura.tscn")
const BARRAQUITO_SCENE = preload("res://escenas/PowerUpBarraquito.tscn")
const MAX_BASURA = 8

var puntos = 0
var basura_en_campo = 0
var partida_terminada = false
var timer_barraquito_restante = 0.0
var barraquito_corriendo = false
var rush_activo = false

var spawn_points = [
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
	var timer_basura = Timer.new()
	add_child(timer_basura)
	timer_basura.wait_time = 5.0
	timer_basura.timeout.connect(_spawn_basura)
	timer_basura.start()

	var timer_powerup = Timer.new()
	add_child(timer_powerup)
	timer_powerup.wait_time = 20.0
	timer_powerup.timeout.connect(_spawn_barraquito)
	timer_powerup.start()

	$HUD/Puntos.text = "0"
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

func _spawn_basura():
	if partida_terminada or basura_en_campo >= MAX_BASURA:
		return
	var basura = BASURA_SCENE.instantiate()
	basura.position = spawn_points[randi() % spawn_points.size()]
	add_child(basura)
	basura_en_campo += 1
	_actualizar_integridad()

func basura_recogida():
	puntos += 25
	basura_en_campo -= 1
	$HUD/Puntos.text = str(puntos)
	$SonidoDing.play()
	_actualizar_integridad()

func violeta_pisada():
	jugador_recibe_daño(50, "hojas")

func jugador_recibe_daño(cantidad: int, tipo: String):
	puntos -= cantidad
	if puntos < 0:
		puntos = 0
	$HUD/Puntos.text = str(puntos)

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
	if partida_terminada:
		return
	var barraquito = BARRAQUITO_SCENE.instantiate()
	barraquito.position = spawn_points[randi() % spawn_points.size()]
	add_child(barraquito)

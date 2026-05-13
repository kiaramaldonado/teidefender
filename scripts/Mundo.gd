extends Node2D

const BASURA_SCENE = preload("res://escenas/Basura.tscn")
const BARRAQUITO_SCENE = preload("res://escenas/PowerUpBarraquito.tscn")
const Maze = preload("res://scripts/Maze.gd")
const MAX_BASURA = 24  # colchón enorme: cada bolsa baja la barra ~4 %

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
	_timer_basura.start(randf_range(2.0, 3.0))

	_timer_powerup = Timer.new()
	_timer_powerup.one_shot = true
	add_child(_timer_powerup)
	_timer_powerup.timeout.connect(_on_timer_powerup)
	_timer_powerup.start(randf_range(17.0, 24.0))

	$HUD/Banner/Puntos.text = str(puntos)
	$HUD/BarraIntegridad.value = 100
	$HUD/TimerBarraquito.visible = false
	$HUD/PantallaBlanca.visible = false
	$HUD/ImagenFlash.visible = false
	$HUD/MenuPausa.visible = false

	$HUD/BotonPausa.pressed.connect(_toggle_pausa)
	$HUD/BotonPausa.mouse_entered.connect(func(): $HUD/BordeHoverPausa.visible = true)
	$HUD/BotonPausa.mouse_exited.connect(func(): $HUD/BordeHoverPausa.visible = false)
	$HUD/MenuPausa/BotonReanudar.pressed.connect(_toggle_pausa)
	$HUD/MenuPausa/BotonSalir.pressed.connect(_ir_al_menu)

	$SonidoRush.finished.connect(func():
		if rush_activo:
			$SonidoRush.play()
	)
	$BGM.finished.connect(func(): $BGM.play())
	$BGM.play()

	# Basura inicial abundante: el jugador empieza con acción inmediata
	for i in range(8):
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
	var blanca := $HUD/PantallaBlanca
	var imagen := $HUD/ImagenFlash
	blanca.modulate.a = 0.0
	imagen.modulate.a = 0.0
	blanca.visible = true
	imagen.visible = true

	# Fade-in rápido (chasquido del flash)
	var fade_in := create_tween()
	fade_in.set_parallel(true)
	fade_in.tween_property(blanca, "modulate:a", 1.0, 0.15)
	fade_in.tween_property(imagen, "modulate:a", 1.0, 0.15)

	# Mantener visible
	await get_tree().create_timer(2.2).timeout
	if partida_terminada:
		return

	# Fade-out suave
	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(blanca, "modulate:a", 0.0, 0.7)
	fade_out.tween_property(imagen, "modulate:a", 0.0, 0.7)
	await fade_out.finished

	if not partida_terminada:
		blanca.visible = false
		imagen.visible = false

func _on_timer_basura():
	_spawn_basura()
	# La presión apenas crece: 4 min hasta el mínimo y el mínimo es 90 %.
	# Con MAX_BASURA=24, hay margen de sobra incluso a este ritmo.
	var presion = clamp(1.0 - (Time.get_ticks_msec() / 240000.0), 0.90, 1.0)
	_timer_basura.start(randf_range(2.0, 3.0) * presion)

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
	_flash_banner_rojo()

	match tipo:
		"punch":
			$SonidoPuñetazo.play()
		"hojas":
			$SonidoHojas.play()

	if puntos <= 0:
		game_over()

func _flash_banner_rojo():
	# Dos parpadeos rojos sobre el banner de puntos cuando se resta puntuación.
	var banner: Node = $HUD/Banner
	var rojo := Color(1.0, 0.35, 0.35, 1.0)
	var normal := Color(1, 1, 1, 1)
	banner.modulate = normal
	var t := create_tween()
	t.tween_property(banner, "modulate", rojo,   0.10)
	t.tween_property(banner, "modulate", normal, 0.10)
	t.tween_property(banner, "modulate", rojo,   0.10)
	t.tween_property(banner, "modulate", normal, 0.10)

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

extends Node2D

const BASURA_SCENE = preload("res://escenas/Basura.tscn")
const BARRAQUITO_SCENE = preload("res://escenas/PowerUpBarraquito.tscn")
const MAX_BASURA = 8

var puntos = 200  # margen inicial para no sufrir game over antes de recoger basura
var basura_en_campo = 0
var partida_terminada = false
var timer_barraquito_restante = 0.0
var barraquito_corriendo = false
var rush_activo = false

var spawn_points = [
	Vector2(200, 130), Vector2(280, 130), Vector2(350, 130),
	Vector2(550, 130), Vector2(650, 130), Vector2(750, 130),
	Vector2(170, 250), Vector2(184, 328), Vector2(184, 392),
	Vector2(450, 200), Vector2(520, 200), Vector2(600, 200),
	Vector2(344, 360), Vector2(424, 360), Vector2(510, 350),
	Vector2(700, 280), Vector2(780, 280), Vector2(860, 280),
	Vector2(250, 480), Vector2(350, 480), Vector2(430, 480),
	Vector2(616, 472), Vector2(720, 480), Vector2(820, 480),
	Vector2(900, 380), Vector2(904, 424), Vector2(970, 420),
	# Puntos extra para más variedad
	Vector2(120, 100), Vector2(400, 100), Vector2(900, 110),
	Vector2(1100, 250), Vector2(1100, 450), Vector2(1180, 600),
	Vector2(120, 600), Vector2(500, 700), Vector2(1000, 700),
]

var _timer_basura: Timer
var _timer_powerup: Timer

func _ready():
	_crear_navegacion()

	# Timers con intervalos aleatorios — cada disparo agenda el siguiente
	# con un nuevo tiempo, para que la partida no se sienta mecánica.
	_timer_basura = Timer.new()
	_timer_basura.one_shot = true
	add_child(_timer_basura)
	_timer_basura.timeout.connect(_on_timer_basura)
	_timer_basura.start(randf_range(3.5, 5.5))

	_timer_powerup = Timer.new()
	_timer_powerup.one_shot = true
	add_child(_timer_powerup)
	_timer_powerup.timeout.connect(_on_timer_powerup)
	_timer_powerup.start(randf_range(17.0, 24.0))

	$HUD/Puntos.text = str(puntos)
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

	# 3 piezas de basura iniciales para que el jugador tenga acción inmediata
	_spawn_basura()
	_spawn_basura()
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
	# El intervalo se acorta gradualmente con el tiempo de juego
	# para aumentar la presión a medida que avanza la partida.
	var presion = clamp(1.0 - (Time.get_ticks_msec() / 120000.0), 0.55, 1.0)
	_timer_basura.start(randf_range(3.5, 5.5) * presion)

func _on_timer_powerup():
	_spawn_barraquito()
	_timer_powerup.start(randf_range(17.0, 24.0))

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

func _crear_navegacion():
	var nav_poly = NavigationPolygon.new()
	# 12px de radio fuerza a los agentes a circular por el centro de los pasillos,
	# eliminando casi por completo los roces con las vallas.
	nav_poly.agent_radius = 12.0

	# NavigationMeshSourceGeometryData2D is the correct Godot 4.3+ API;
	# it handles winding order automatically and doesn't rely on the deprecated
	# make_polygons_from_outlines() path.
	var geo = NavigationMeshSourceGeometryData2D.new()

	# Outer walkable boundary
	geo.add_traversable_outline(PackedVector2Array([
		Vector2(40, 40), Vector2(1240, 40), Vector2(1240, 728), Vector2(40, 728),
	]))

	# Fence walls as obstacles — rectangles computed from real 16×16 tile positions.
	var vallas: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(80,224),  Vector2(320,224),  Vector2(320,240),  Vector2(80,240)]),
		PackedVector2Array([Vector2(80,240),  Vector2(96,240),   Vector2(96,496),   Vector2(80,496)]),
		PackedVector2Array([Vector2(80,496),  Vector2(336,496),  Vector2(336,512),  Vector2(80,512)]),
		PackedVector2Array([Vector2(160,304), Vector2(176,304),  Vector2(176,416),  Vector2(160,416)]),
		PackedVector2Array([Vector2(160,416), Vector2(336,416),  Vector2(336,432),  Vector2(160,432)]),
		PackedVector2Array([Vector2(240,336), Vector2(496,336),  Vector2(496,352),  Vector2(240,352)]),
		PackedVector2Array([Vector2(304,80),  Vector2(768,80),   Vector2(768,96),   Vector2(304,96)]),
		PackedVector2Array([Vector2(304,96),  Vector2(320,96),   Vector2(320,224),  Vector2(304,224)]),
		PackedVector2Array([Vector2(320,512), Vector2(336,512),  Vector2(336,656),  Vector2(320,656)]),
		PackedVector2Array([Vector2(320,656), Vector2(784,656),  Vector2(784,672),  Vector2(320,672)]),
		PackedVector2Array([Vector2(384,160), Vector2(544,160),  Vector2(544,176),  Vector2(384,176)]),
		PackedVector2Array([Vector2(384,176), Vector2(400,176),  Vector2(400,256),  Vector2(384,256)]),
		PackedVector2Array([Vector2(400,416), Vector2(496,416),  Vector2(496,432),  Vector2(400,432)]),
		PackedVector2Array([Vector2(400,496), Vector2(416,496),  Vector2(416,576),  Vector2(400,576)]),
		PackedVector2Array([Vector2(400,576), Vector2(704,576),  Vector2(704,592),  Vector2(400,592)]),
		PackedVector2Array([Vector2(464,176), Vector2(480,176),  Vector2(480,256),  Vector2(464,256)]),
		PackedVector2Array([Vector2(480,432), Vector2(496,432),  Vector2(496,464),  Vector2(480,464)]),
		PackedVector2Array([Vector2(480,480), Vector2(496,480),  Vector2(496,496),  Vector2(480,496)]),
		PackedVector2Array([Vector2(480,496), Vector2(528,496),  Vector2(528,512),  Vector2(480,512)]),
		PackedVector2Array([Vector2(528,96),  Vector2(544,96),   Vector2(544,160),  Vector2(528,160)]),
		PackedVector2Array([Vector2(592,496), Vector2(624,496),  Vector2(624,512),  Vector2(592,512)]),
		PackedVector2Array([Vector2(608,160), Vector2(1056,160), Vector2(1056,176), Vector2(608,176)]),
		PackedVector2Array([Vector2(608,240), Vector2(752,240),  Vector2(752,256),  Vector2(608,256)]),
		PackedVector2Array([Vector2(608,256), Vector2(624,256),  Vector2(624,288),  Vector2(608,288)]),
		PackedVector2Array([Vector2(608,352), Vector2(624,352),  Vector2(624,464),  Vector2(608,464)]),
		PackedVector2Array([Vector2(608,480), Vector2(624,480),  Vector2(624,496),  Vector2(608,496)]),
		PackedVector2Array([Vector2(688,352), Vector2(976,352),  Vector2(976,368),  Vector2(688,368)]),
		PackedVector2Array([Vector2(688,368), Vector2(704,368),  Vector2(704,576),  Vector2(688,576)]),
		PackedVector2Array([Vector2(752,96),  Vector2(768,96),   Vector2(768,160),  Vector2(752,160)]),
		PackedVector2Array([Vector2(768,432), Vector2(784,432),  Vector2(784,576),  Vector2(768,576)]),
		PackedVector2Array([Vector2(768,576), Vector2(1056,576), Vector2(1056,592), Vector2(768,592)]),
		PackedVector2Array([Vector2(768,592), Vector2(784,592),  Vector2(784,656),  Vector2(768,656)]),
		PackedVector2Array([Vector2(816,240), Vector2(976,240),  Vector2(976,256),  Vector2(816,256)]),
		PackedVector2Array([Vector2(848,432), Vector2(976,432),  Vector2(976,512),  Vector2(848,512)]),
		PackedVector2Array([Vector2(960,256), Vector2(976,256),  Vector2(976,352),  Vector2(960,352)]),
		PackedVector2Array([Vector2(1040,176),Vector2(1056,176), Vector2(1056,576), Vector2(1040,576)]),
	]
	for v in vallas:
		geo.add_obstruction_outline(v)

	NavigationServer2D.bake_from_source_geometry_data(nav_poly, geo)

	var nav_region = NavigationRegion2D.new()
	nav_region.name = "NavRegion"
	nav_region.navigation_polygon = nav_poly
	add_child(nav_region)

func _spawn_barraquito():
	if partida_terminada:
		return
	var barraquito = BARRAQUITO_SCENE.instantiate()
	barraquito.position = spawn_points[randi() % spawn_points.size()]
	add_child(barraquito)

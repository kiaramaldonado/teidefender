extends Node2D

const BASURA_SCENE = preload("res://escenas/Basura.tscn")
const BARRAQUITO_SCENE = preload("res://escenas/PowerUpBarraquito.tscn")
const Maze = preload("res://scripts/Maze.gd")
const MAX_BASURA = 24  # colchón enorme: cada bolsa baja la barra ~4 %
const PUNTOS_POR_NIVEL = 250  # cada 250 pts sube un nivel de dificultad

var puntos = 200
var puntos_max = 200       # mejor puntuación alcanzada en la partida
var nivel_dificultad = 0   # solo sube, nunca baja
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

# Tweens que parpadean en rojo de forma continua cuando los recursos
# están bajos. Se mantienen guardados para poder iniciarlos/pararlos.
var _flash_integridad_tween: Tween
var _flash_puntos_tween: Tween
const UMBRAL_INTEGRIDAD_BAJA := 0.25  # parpadea cuando queda ≤ 25 %
const UMBRAL_PUNTOS_BAJOS := 150

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
	_timer_basura.start(randf_range(4.0, 5.5))   # base cómoda, escala con el nivel

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
	# Parar la música del menú: en partida suena la banda sonora propia.
	MenuMusic.stop()
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
			desactivar_barraquito_efectos()

func _toggle_pausa():
	get_tree().paused = !get_tree().paused
	$HUD/MenuPausa.visible = get_tree().paused

func _ir_al_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://escenas/MenuPrincipal.tscn")

func activar_barraquito_efectos():
	$SonidoBarraquito.play()
	# Si ya hay un barraquito activo, el nuevo SUMA tiempo; si no, arranca.
	if barraquito_corriendo:
		timer_barraquito_restante += 8.0
	else:
		timer_barraquito_restante = 8.0
		barraquito_corriendo = true
		$HUD/TimerBarraquito.visible = true
		var j = get_tree().get_first_node_in_group("jugador")
		if j and j.has_method("activar_efecto_barraquito"):
			j.activar_efecto_barraquito()

func desactivar_barraquito_efectos():
	# Disparado por _process cuando el contador llega a 0.
	barraquito_corriendo = false
	$HUD/TimerBarraquito.visible = false
	var j = get_tree().get_first_node_in_group("jugador")
	if j and j.has_method("desactivar_efecto_barraquito"):
		j.desactivar_efecto_barraquito()

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
	# Escalado tipo Tetris: cada nivel acorta el intervalo de aparición.
	# El factor crece exponencialmente sin tope (a nivel 10 ≈ 3× más rápido).
	_timer_basura.start(randf_range(4.0, 5.5) / factor_spawn())

# --- Sistema de dificultad ---
# Cada PUNTOS_POR_NIVEL puntos acumulados sube el nivel. nivel_dificultad
# nunca baja aunque pierdas puntos, igual que el "level" de Tetris.

func _actualizar_nivel():
	var nuevo = int(puntos / PUNTOS_POR_NIVEL)
	if nuevo > nivel_dificultad:
		nivel_dificultad = nuevo

func factor_spawn() -> float:
	# Aparición de basura/violetas: crece sin tope (1.12^nivel).
	return pow(1.12, nivel_dificultad)

func factor_enemigo() -> float:
	# Velocidad de los enemigos: crece más despacio y con techo (cap 1.4)
	# para que nunca superen la velocidad del jugador (80 px/s).
	return min(pow(1.07, nivel_dificultad), 1.4)

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
	if puntos > puntos_max:
		puntos_max = puntos
	basura_en_campo -= 1
	$HUD/Banner/Puntos.text = str(puntos)
	$SonidoDing.play()
	_actualizar_integridad()
	_actualizar_nivel()
	_actualizar_parpadeo_puntos()

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
	# Dos parpadeos rojos discretos al recibir daño. Pausa el parpadeo
	# continuo (si está activo) y al terminar lo reactiva si procede.
	if _flash_puntos_tween and _flash_puntos_tween.is_valid():
		_flash_puntos_tween.kill()
		_flash_puntos_tween = null
	var banner: Node = $HUD/Banner
	var rojo := Color(1.0, 0.35, 0.35, 1.0)
	var normal := Color(1, 1, 1, 1)
	banner.modulate = normal
	var t := create_tween()
	t.tween_property(banner, "modulate", rojo,   0.10)
	t.tween_property(banner, "modulate", normal, 0.10)
	t.tween_property(banner, "modulate", rojo,   0.10)
	t.tween_property(banner, "modulate", normal, 0.10)
	t.finished.connect(_actualizar_parpadeo_puntos)

# --- Parpadeos continuos en rojo cuando un recurso está bajo ---

func _actualizar_parpadeo_puntos():
	if puntos < UMBRAL_PUNTOS_BAJOS:
		_iniciar_parpadeo_puntos()
	else:
		_detener_parpadeo_puntos()

func _iniciar_parpadeo_puntos():
	if _flash_puntos_tween and _flash_puntos_tween.is_valid():
		return
	var banner = $HUD/Banner
	_flash_puntos_tween = create_tween().set_loops()
	_flash_puntos_tween.tween_property(banner, "modulate", Color(1, 0.45, 0.45, 1), 0.45)
	_flash_puntos_tween.tween_property(banner, "modulate", Color(1, 1, 1, 1), 0.45)

func _detener_parpadeo_puntos():
	if _flash_puntos_tween:
		_flash_puntos_tween.kill()
		_flash_puntos_tween = null
	$HUD/Banner.modulate = Color(1, 1, 1, 1)

func _iniciar_parpadeo_integridad():
	if _flash_integridad_tween and _flash_integridad_tween.is_valid():
		return
	var bar = $HUD/BarraIntegridad
	# Rojo intenso + ciclo más rápido para que se note bien sobre el estilo
	# por defecto del ProgressBar.
	_flash_integridad_tween = create_tween().set_loops()
	_flash_integridad_tween.tween_property(bar, "modulate", Color(1.0, 0.15, 0.15, 1), 0.28)
	_flash_integridad_tween.tween_property(bar, "modulate", Color(1, 1, 1, 1),         0.28)

func _detener_parpadeo_integridad():
	if _flash_integridad_tween:
		_flash_integridad_tween.kill()
		_flash_integridad_tween = null
	$HUD/BarraIntegridad.modulate = Color(1, 1, 1, 1)

func _actualizar_integridad():
	var porcentaje = float(basura_en_campo) / float(MAX_BASURA)
	var integridad = 1.0 - porcentaje
	$HUD/BarraIntegridad.value = 100.0 * integridad

	# Parpadeo rojo continuo cuando la salud del parque está por debajo del 25 %.
	if integridad < UMBRAL_INTEGRIDAD_BAJA:
		_iniciar_parpadeo_integridad()
	else:
		_detener_parpadeo_integridad()

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
	# Guardar la mejor puntuación alcanzada en la partida (no la final).
	# Así aunque el jugador termine en 0 puntos, su mejor momento queda
	# registrado en el ranking.
	PlayerSession.last_score = puntos_max
	get_tree().change_scene_to_file("res://escenas/GameOver.tscn")

func _spawn_barraquito():
	if partida_terminada or spawn_points.is_empty():
		return
	var barraquito = BARRAQUITO_SCENE.instantiate()
	barraquito.position = spawn_points[randi() % spawn_points.size()]
	add_child(barraquito)

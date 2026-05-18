extends Node2D

# Escena principal de juego. Coordina spawn de basura/barraquito, contadores
# del jugador, HUD, audio, dificultad (estilo Tetris) y game over.

const BASURA_SCENE = preload("res://escenas/Basura.tscn")
const BARRAQUITO_SCENE = preload("res://escenas/PowerUpBarraquito.tscn")
const Maze = preload("res://scripts/Maze.gd")

# --- Balance del juego ------------------------------------------------------

const PUNTOS_INICIALES := 200
const PUNTOS_POR_BASURA := 25
const PUNTOS_POR_NIVEL := 250    # cada 250 pts sube un nivel de dificultad

const MAX_BASURA := 24           # cada bolsa baja la barra ~4 %
const BASURA_INICIAL := 8
const INTERVALO_BASURA := Vector2(4.0, 5.5)     # rango aleatorio en s
const INTERVALO_POWERUP := Vector2(17.0, 24.0)

const DURACION_BARRAQUITO := 8.0  # se acumula si bebes otro
const DURACION_FLASH := 2.2       # ceguera visible tras el chasquido inicial

# Cuenta atrás inicial (sincronizada con sonidos/countdown.mp3 ≈ 4 s)
const CUENTA_ATRAS_TEXTOS := ["3", "2", "1", "¡Vamos!"]
const CUENTA_ATRAS_INTERVALO := 1.0
const CUENTA_ATRAS_ESCALA_INICIAL := Vector2(2.5, 2.5)
const CUENTA_ATRAS_ESCALA_FINAL := Vector2(0.7, 0.7)

# Avisos visuales cuando los recursos están bajos
const UMBRAL_INTEGRIDAD_BAJA := 0.25  # < 25 % salud parque
const UMBRAL_PUNTOS_BAJOS := 150
const COLOR_PARPADEO_PUNTOS := Color(1, 0.45, 0.45, 1)
const COLOR_PARPADEO_INTEGRIDAD := Color(1, 0.15, 0.15, 1)
const COLOR_BLANCO := Color(1, 1, 1, 1)

# --- Estado de la partida ---------------------------------------------------

var puntos := PUNTOS_INICIALES
var puntos_max := PUNTOS_INICIALES   # mejor puntuación de la partida (para ranking)
var nivel_dificultad := 0            # solo sube, nunca baja
var basura_en_campo := 0
var partida_terminada := false
var rush_activo := false

var timer_barraquito_restante := 0.0
var barraquito_corriendo := false

# Centros de celdas-corredor donde puede aparecer basura/barraquito.
# Las celdas iniciales de jugador/enemigos están excluidas.
var spawn_points: Array[Vector2] = []

var _timer_basura: Timer
var _timer_powerup: Timer
var _flash_puntos_tween: Tween
var _flash_integridad_tween: Tween


# ============================================================================
# Ciclo de vida
# ============================================================================

func _ready():
	_calcular_spawn_points()
	_inicializar_timers()
	_inicializar_hud()
	_inicializar_audio()

	for _i in range(BASURA_INICIAL):
		_spawn_basura()

	# Cuenta atrás antes de empezar: la escena se ve pero está pausada.
	# Cuando termina, se reanuda y arranca la BSO.
	await _cuenta_atras_inicial()
	$BGM.play()

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pausa()

	if barraquito_corriendo:
		timer_barraquito_restante -= delta
		if timer_barraquito_restante > 0:
			$HUD/TimerBarraquito.text = "Barraquito: " + str(snapped(timer_barraquito_restante, 0.1)) + "s"
		else:
			desactivar_barraquito_efectos()


# ============================================================================
# Inicialización (extraída de _ready para legibilidad)
# ============================================================================

func _calcular_spawn_points():
	var reservadas := [
		Vector2i(9, 9),   # jugador
		Vector2i(4, 1),   # Tato
		Vector2i(1, 5),   # Homero
		Vector2i(17, 5),  # Spencer
	]
	for c in Maze.all_corridor_cells():
		if c not in reservadas:
			spawn_points.append(Maze.cell_to_world(c))

func _inicializar_timers():
	_timer_basura = Timer.new()
	_timer_basura.one_shot = true
	add_child(_timer_basura)
	_timer_basura.timeout.connect(_on_timer_basura)
	_timer_basura.start(randf_range(INTERVALO_BASURA.x, INTERVALO_BASURA.y))

	_timer_powerup = Timer.new()
	_timer_powerup.one_shot = true
	add_child(_timer_powerup)
	_timer_powerup.timeout.connect(_on_timer_powerup)
	_timer_powerup.start(randf_range(INTERVALO_POWERUP.x, INTERVALO_POWERUP.y))

func _inicializar_hud():
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

func _inicializar_audio():
	# Loop manual del rush (mientras esté activo) y del BGM.
	$SonidoRush.finished.connect(func():
		if rush_activo:
			$SonidoRush.play()
	)
	$BGM.finished.connect(func(): $BGM.play())
	# En partida suena la BSO propia; paramos la música del menú.
	# (La BSO no arranca aquí, lo hará al terminar la cuenta atrás.)
	MenuMusic.stop()


# ============================================================================
# Pausa y navegación
# ============================================================================

func _toggle_pausa():
	get_tree().paused = !get_tree().paused
	$HUD/MenuPausa.visible = get_tree().paused

func _ir_al_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://escenas/MenuPrincipal.tscn")


# ============================================================================
# Spawning de items
# ============================================================================

func _on_timer_basura():
	_spawn_basura()
	# Escalado tipo Tetris: cada nivel acorta el intervalo (sin tope).
	_timer_basura.start(randf_range(INTERVALO_BASURA.x, INTERVALO_BASURA.y) / factor_spawn())

func _on_timer_powerup():
	_spawn_barraquito()
	_timer_powerup.start(randf_range(INTERVALO_POWERUP.x, INTERVALO_POWERUP.y))

func _spawn_basura():
	if partida_terminada or basura_en_campo >= MAX_BASURA or spawn_points.is_empty():
		return
	var basura = BASURA_SCENE.instantiate()
	basura.position = spawn_points[randi() % spawn_points.size()]
	add_child(basura)
	basura_en_campo += 1
	_actualizar_integridad()

func _spawn_barraquito():
	if partida_terminada or spawn_points.is_empty():
		return
	var barraquito = BARRAQUITO_SCENE.instantiate()
	barraquito.position = spawn_points[randi() % spawn_points.size()]
	add_child(barraquito)


# ============================================================================
# Sistema de dificultad (sube según puntos acumulados, estilo Tetris)
# ============================================================================

func _actualizar_nivel():
	var nuevo := int(puntos / PUNTOS_POR_NIVEL)
	if nuevo > nivel_dificultad:
		nivel_dificultad = nuevo

func factor_spawn() -> float:
	# Crece exponencialmente sin tope.
	return pow(1.12, nivel_dificultad)

func factor_enemigo() -> float:
	# Crece más despacio y con techo, para que nunca superen al jugador (80 px/s).
	return min(pow(1.07, nivel_dificultad), 1.4)


# ============================================================================
# Interacciones (llamadas desde items y enemigos)
# ============================================================================

func basura_recogida():
	puntos += PUNTOS_POR_BASURA
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
	puntos = max(puntos - cantidad, 0)
	$HUD/Banner/Puntos.text = str(puntos)
	_flash_banner_rojo()

	match tipo:
		"punch": $SonidoPuñetazo.play()
		"hojas": $SonidoHojas.play()

	if puntos <= 0:
		game_over()

func activar_barraquito_efectos():
	$SonidoBarraquito.play()
	# Si ya hay un barraquito activo, el nuevo SUMA tiempo; si no, arranca.
	if barraquito_corriendo:
		timer_barraquito_restante += DURACION_BARRAQUITO
		return
	timer_barraquito_restante = DURACION_BARRAQUITO
	barraquito_corriendo = true
	$HUD/TimerBarraquito.visible = true
	var j = get_tree().get_first_node_in_group("jugador")
	if j and j.has_method("activar_efecto_barraquito"):
		j.activar_efecto_barraquito()

func desactivar_barraquito_efectos():
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

	# Chasquido (fade-in rápido)
	var fade_in := create_tween()
	fade_in.set_parallel(true)
	fade_in.tween_property(blanca, "modulate:a", 1.0, 0.15)
	fade_in.tween_property(imagen, "modulate:a", 1.0, 0.15)

	await get_tree().create_timer(DURACION_FLASH).timeout
	if partida_terminada:
		return

	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(blanca, "modulate:a", 0.0, 0.7)
	fade_out.tween_property(imagen, "modulate:a", 0.0, 0.7)
	await fade_out.finished

	if not partida_terminada:
		blanca.visible = false
		imagen.visible = false


# ============================================================================
# Barra de salud del parque
# ============================================================================

func _actualizar_integridad():
	var porcentaje := float(basura_en_campo) / float(MAX_BASURA)
	var integridad := 1.0 - porcentaje
	$HUD/BarraIntegridad.value = 100.0 * integridad

	_actualizar_parpadeo_integridad(integridad < UMBRAL_INTEGRIDAD_BAJA)

	if basura_en_campo >= MAX_BASURA:
		game_over()
	elif porcentaje >= 0.6 and not rush_activo:
		rush_activo = true
		$SonidoRush.play()
	elif porcentaje < 0.6 and rush_activo:
		rush_activo = false
		$SonidoRush.stop()


# ============================================================================
# Parpadeo visual al estar bajos de recursos
# ============================================================================
# _ajustar_parpadeo unifica iniciar/detener: si activo, garantiza un tween
# en loop con el color/duración dados; si no, lo mata y restaura el blanco.

func _ajustar_parpadeo(node: CanvasItem, current: Tween, activo: bool, color: Color, dur: float) -> Tween:
	if activo:
		if current and current.is_valid():
			return current
		var t := create_tween().set_loops()
		t.tween_property(node, "modulate", color, dur)
		t.tween_property(node, "modulate", COLOR_BLANCO, dur)
		return t
	if current:
		current.kill()
	node.modulate = COLOR_BLANCO
	return null

func _actualizar_parpadeo_puntos():
	var activo := puntos < UMBRAL_PUNTOS_BAJOS
	_flash_puntos_tween = _ajustar_parpadeo(
		$HUD/Banner, _flash_puntos_tween, activo, COLOR_PARPADEO_PUNTOS, 0.45
	)

func _actualizar_parpadeo_integridad(activo: bool):
	_flash_integridad_tween = _ajustar_parpadeo(
		$HUD/BarraIntegridad, _flash_integridad_tween, activo, COLOR_PARPADEO_INTEGRIDAD, 0.28
	)

func _flash_banner_rojo():
	# Dos parpadeos rápidos al recibir daño. Pausa el parpadeo continuo si lo
	# hay; al terminar lo reactiva si los puntos siguen bajos.
	if _flash_puntos_tween and _flash_puntos_tween.is_valid():
		_flash_puntos_tween.kill()
		_flash_puntos_tween = null
	var banner := $HUD/Banner
	banner.modulate = COLOR_BLANCO
	var t := create_tween()
	t.tween_property(banner, "modulate", COLOR_PARPADEO_PUNTOS, 0.10)
	t.tween_property(banner, "modulate", COLOR_BLANCO, 0.10)
	t.tween_property(banner, "modulate", COLOR_PARPADEO_PUNTOS, 0.10)
	t.tween_property(banner, "modulate", COLOR_BLANCO, 0.10)
	t.finished.connect(_actualizar_parpadeo_puntos)


# ============================================================================
# Fin de partida
# ============================================================================

func game_over():
	if partida_terminada:
		return
	partida_terminada = true
	get_tree().paused = false
	$BGM.stop()
	$SonidoRush.stop()
	# Guardamos la MEJOR puntuación, no la final: aunque el jugador termine
	# en 0 puntos, su mejor momento queda registrado en el ranking.
	PlayerSession.last_score = puntos_max
	get_tree().change_scene_to_file("res://escenas/GameOver.tscn")


# ============================================================================
# Cuenta atrás inicial
# ============================================================================

func _cuenta_atras_inicial():
	# Pausamos el árbol para que la escena quede congelada (enemigos, timers
	# y físicas paradas). El Label y el AudioStreamPlayer del countdown
	# tienen process_mode = ALWAYS para seguir funcionando.
	get_tree().paused = true
	$SonidoCuentaAtras.play()
	for texto in CUENTA_ATRAS_TEXTOS:
		_animar_numero_cuenta_atras(texto)
		await get_tree().create_timer(CUENTA_ATRAS_INTERVALO).timeout
	$HUD/CuentaAtras.visible = false
	get_tree().paused = false

func _animar_numero_cuenta_atras(texto: String):
	var label := $HUD/CuentaAtras
	label.text = texto
	label.scale = CUENTA_ATRAS_ESCALA_INICIAL
	label.modulate = COLOR_BLANCO
	label.visible = true
	# Tween anclado al propio Label (PROCESS_MODE_ALWAYS) para que la
	# animación se ejecute aunque el árbol esté pausado.
	var t := label.create_tween()
	t.set_parallel(true)
	t.tween_property(label, "scale", CUENTA_ATRAS_ESCALA_FINAL, CUENTA_ATRAS_INTERVALO * 0.9)
	t.tween_property(label, "modulate:a", 0.0, CUENTA_ATRAS_INTERVALO * 0.85).set_delay(CUENTA_ATRAS_INTERVALO * 0.1)

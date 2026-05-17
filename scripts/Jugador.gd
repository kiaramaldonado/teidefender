extends CharacterBody2D

const VELOCIDAD_NORMAL = 80.0
const VELOCIDAD_BOOST = 180.0

var velocidad_actual = VELOCIDAD_NORMAL
var ultima_direccion = "down"
var barraquito_activo = false
var bebiendo = false
var inmune = false
var inmovilizado = false  # bloqueado durante el puñetazo de Tato

func _ready():
	add_to_group("jugador")

func _physics_process(_delta):
	if bebiendo:
		return

	if inmovilizado:
		velocity = Vector2.ZERO
		move_and_slide()
		$Sprite.play("idle_" + ultima_direccion)
		return

	var direccion = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direccion.x += 1
	if Input.is_action_pressed("ui_left"):
		direccion.x -= 1
	if Input.is_action_pressed("ui_down"):
		direccion.y += 1
	if Input.is_action_pressed("ui_up"):
		direccion.y -= 1

	if direccion.length() > 0:
		direccion = direccion.normalized()

	velocity = direccion * velocidad_actual
	move_and_slide()
	_actualizar_animacion(direccion)

func _actualizar_animacion(direccion: Vector2):
	if bebiendo:
		return

	if direccion.x > 0:
		ultima_direccion = "right"
	elif direccion.x < 0:
		ultima_direccion = "left"
	elif direccion.y > 0:
		ultima_direccion = "down"
	elif direccion.y < 0:
		ultima_direccion = "up"

	if direccion.length() > 0:
		if barraquito_activo:
			$Sprite.play("run_" + ultima_direccion)
		else:
			$Sprite.play("walk_" + ultima_direccion)
	else:
		$Sprite.play("idle_" + ultima_direccion)

func activar_barraquito():
	bebiendo = true
	$Sprite.play("drink")
	await $Sprite.animation_finished
	bebiendo = false
	# Mundo es quien controla el contador y decide cuándo parar el efecto.
	# Al beber otro barraquito mientras estás bajo el primero, Mundo suma
	# 8 s al tiempo restante (en vez de resetearlo).
	get_parent().activar_barraquito_efectos()

func activar_efecto_barraquito():
	# Llamado por Mundo cuando empieza un nuevo "ciclo" de barraquito.
	barraquito_activo = true
	inmune = true
	velocidad_actual = VELOCIDAD_BOOST

func desactivar_efecto_barraquito():
	# Llamado por Mundo cuando expira el contador acumulado.
	barraquito_activo = false
	inmune = false
	velocidad_actual = VELOCIDAD_NORMAL

func recibir_puñetazo():
	if inmune:
		return
	get_parent().jugador_recibe_daño(100, "punch")

func recibir_flash():
	if inmune:
		return
	get_parent().activar_ceguera()

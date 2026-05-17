extends Node

# Autoload: reproductor único de la música de menú. Persiste entre escenas
# para que la canción siga sonando al pasar del menú al ranking, al game
# over, etc., sin reiniciarse.

const BGM := preload("res://sonidos/bgm_menu.mp3")

var _player: AudioStreamPlayer

func _ready():
	_player = AudioStreamPlayer.new()
	_player.stream = BGM
	_player.bus = "Master"
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)
	# Loop manual: al terminar, vuelve a empezar.
	_player.finished.connect(func(): _player.play())
	_player.play()

# Reanuda la música si está parada. Llamado por las pantallas tipo menú.
func play():
	if _player and not _player.playing:
		_player.play()

# Detiene la música. Llamado al entrar en la partida.
func stop():
	if _player and _player.playing:
		_player.stop()

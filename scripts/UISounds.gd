extends Node

# Autoload: reproduce un sonido cuando el cursor pasa por encima de cualquier
# Button / TextureButton / CheckBox… (todo lo que herede de BaseButton).
# Se autoconecta a botones existentes y a cualquiera que se añada después.

const HOVER_SOUND := preload("res://sonidos/hover.mp3")

var _player: AudioStreamPlayer

func _ready():
	_player = AudioStreamPlayer.new()
	_player.stream = HOVER_SOUND
	_player.process_mode = Node.PROCESS_MODE_ALWAYS  # suena también con el juego pausado
	add_child(_player)

	# Engancha los botones que ya existen en el árbol
	_conectar_recursivo(get_tree().root)
	# Y los que se añadan a partir de ahora
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	if node is BaseButton:
		_conectar_boton(node)

func _conectar_recursivo(node: Node):
	if node is BaseButton:
		_conectar_boton(node)
	for c in node.get_children():
		_conectar_recursivo(c)

func _conectar_boton(btn: BaseButton):
	if not btn.mouse_entered.is_connected(_play_hover):
		btn.mouse_entered.connect(_play_hover)

func _play_hover():
	_player.stop()
	_player.play()

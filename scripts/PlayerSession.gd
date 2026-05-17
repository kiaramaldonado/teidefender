extends Node

# Autoload: configura SilentWolf al arrancar y guarda los datos de la
# sesión (nombre del jugador, última puntuación, última posición) para
# que estén disponibles entre escenas.

const API_KEY := "wlFtgLp8y11CG848G1HmN8FpdgFrd8o03Qw5BnAy"
const GAME_ID := "Teidefender"
const GAME_VERSION := "1.0.0"

var player_name: String = ""
var last_score: int = 0
var last_position: int = -1   # -1 = aún sin calcular

func _ready():
	# Configurar SilentWolf una sola vez al inicio del juego
	if Engine.has_singleton("SilentWolf") or get_node_or_null("/root/SilentWolf") != null:
		SilentWolf.configure({
			"api_key": API_KEY,
			"game_id": GAME_ID,
			"game_version": GAME_VERSION,
			"log_level": 2,   # debug: ver logs completos en consola
		})
		_test_connection()
	else:
		push_warning("PlayerSession: autoload 'SilentWolf' no encontrado. Asegúrate de instalar el addon en res://addons/silent_wolf/")

# Lanza una petición simple al arrancar para diagnosticar si Godot puede
# hablar con el backend de SilentWolf. Imprime el response_code en consola.
func _test_connection():
	var http := HTTPRequest.new()
	http.timeout = 6.0
	add_child(http)
	http.request_completed.connect(func(_r, code, _h, body):
		var snippet: String = "(vacío)"
		if body.size() > 0:
			snippet = body.get_string_from_utf8().left(120)
		print("[PlayerSession] Test SilentWolf — HTTP code: %d  body: %s" % [code, snippet])
		http.queue_free()
	)
	var url := "https://api.silentwolf.com/get_scores/%s?max=1&ldboard_name=main&period_offset=0" % GAME_ID
	var headers := [
		"x-api-key: " + API_KEY,
		"x-sw-game-id: " + GAME_ID,
		"x-sw-plugin-version: 0.6.4",
		"x-sw-godot-version: 4.6",
	]
	var err := http.request(url, headers)
	if err != OK:
		print("[PlayerSession] Test SilentWolf — error al lanzar request: ", err)

# Espera una señal con timeout. Si la señal no se emite antes del tiempo
# indicado, devuelve null. Se usa para llamadas a SilentWolf, que en caso
# de error de conexión (response_code == 0) nunca emiten la señal y dejan
# colgada cualquier corrutina que esté esperando.
func await_or_timeout(source: Object, signal_name: StringName, secs: float) -> Variant:
	if source == null:
		return null
	var box := {"done": false, "result": null}
	var cb := func(r = null):
		box.done = true
		box.result = r
	source.connect(signal_name, cb, CONNECT_ONE_SHOT)
	var timer := get_tree().create_timer(secs)
	while not box.done:
		if timer.time_left <= 0.0:
			if source.is_connected(signal_name, cb):
				source.disconnect(signal_name, cb)
			return null
		await get_tree().process_frame
	return box.result

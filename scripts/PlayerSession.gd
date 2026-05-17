extends Node

# Autoload: configura SilentWolf al arrancar y guarda los datos de la
# sesión (nombre del jugador, última puntuación, última posición) para
# que estén disponibles entre escenas.
#
# Las credenciales de SilentWolf (api_key, game_id) NO van en el código
# fuente: se leen de config/silent_wolf.cfg, archivo ignorado por git.
# Usa config/silent_wolf.cfg.example como plantilla.

const CONFIG_PATH := "res://config/silent_wolf.cfg"

var player_name: String = ""
var last_score: int = 0
var last_position: int = -1   # -1 = aún sin calcular
var ranking_disponible: bool = false

func _ready():
	if get_node_or_null("/root/SilentWolf") == null:
		push_warning("PlayerSession: autoload 'SilentWolf' no encontrado. Instala el addon en res://addons/silent_wolf/")
		return
	_configurar_silent_wolf()

func _configurar_silent_wolf():
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		push_warning("PlayerSession: %s no encontrado. El ranking estará deshabilitado. Copia config/silent_wolf.cfg.example para activarlo." % CONFIG_PATH)
		return

	var api_key = cfg.get_value("silent_wolf", "api_key", "")
	var game_id = cfg.get_value("silent_wolf", "game_id", "")
	if api_key == "" or game_id == "" or api_key.begins_with("PON_AQUI"):
		push_warning("PlayerSession: %s incompleto (api_key / game_id sin rellenar)." % CONFIG_PATH)
		return

	SilentWolf.configure({
		"api_key": api_key,
		"game_id": game_id,
		"game_version": cfg.get_value("silent_wolf", "game_version", "1.0.0"),
		"log_level": cfg.get_value("silent_wolf", "log_level", 1),
	})
	ranking_disponible = true

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

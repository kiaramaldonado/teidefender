class_name Maze
extends RefCounted

# Laberinto Pacman-style del juego.
# 19 columnas × 11 filas, cada celda = 64×64 px.
# La celda (0,0) tiene su centro en (64, 64) del mundo.
#
#   '#' = pared
#   '.' = corredor

const GRID_W := 19
const GRID_H := 11
const CELL_PX := 64

const MAZE := [
	"###################",
	"#........#........#",
	"#.##.###.#.###.##.#",
	"#.................#",
	"#.##.#.#####.#.##.#",
	"#....#...#...#....#",
	"####.#.#.#.#.#.####",
	"#....#...#...#....#",
	"#.##.#.#####.#.##.#",
	"#.................#",
	"###################",
]

const DIR_N := Vector2i(0, -1)
const DIR_S := Vector2i(0, 1)
const DIR_E := Vector2i(1, 0)
const DIR_W := Vector2i(-1, 0)
const DIRECTIONS := [DIR_N, DIR_S, DIR_E, DIR_W]

static func cell_to_world(c: Vector2i) -> Vector2:
	return Vector2(c.x * CELL_PX + CELL_PX, c.y * CELL_PX + CELL_PX)

static func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(roundi((p.x - CELL_PX) / float(CELL_PX)), roundi((p.y - CELL_PX) / float(CELL_PX)))

static func is_corridor(c: Vector2i) -> bool:
	if c.x < 0 or c.x >= GRID_W or c.y < 0 or c.y >= GRID_H:
		return false
	return MAZE[c.y][c.x] == '.'

# Vecinos cardinales que son corredor.
static func neighbours(c: Vector2i) -> Array:
	var out := []
	for d in DIRECTIONS:
		var n: Vector2i = c + d
		if is_corridor(n):
			out.append(d)
	return out

# BFS: devuelve la primera dirección que conviene tomar desde `from` para llegar a `to`.
# Si no hay camino, devuelve Vector2i.ZERO.
static func direction_towards(from: Vector2i, to: Vector2i) -> Vector2i:
	if from == to or not is_corridor(from) or not is_corridor(to):
		return Vector2i.ZERO
	# BFS desde from
	var came_from := {from: Vector2i.ZERO}
	var queue := [from]
	while queue.size() > 0:
		var cur: Vector2i = queue.pop_front()
		if cur == to:
			break
		for d in DIRECTIONS:
			var n: Vector2i = cur + d
			if is_corridor(n) and not came_from.has(n):
				came_from[n] = cur
				queue.append(n)
	if not came_from.has(to):
		return Vector2i.ZERO
	# Reconstruir paso 1 → 2 → ... → to, devolver primera dirección
	var step := to
	while came_from[step] != from:
		step = came_from[step]
		if step == Vector2i.ZERO:
			return Vector2i.ZERO
	return step - from

# Lista de todas las celdas de corredor (en orden de lectura).
static func all_corridor_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(GRID_H):
		for x in range(GRID_W):
			if MAZE[y][x] == '.':
				out.append(Vector2i(x, y))
	return out

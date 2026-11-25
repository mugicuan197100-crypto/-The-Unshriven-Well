extends Node2D

const MAP := [
	"#######",
	"#..E..#",
	"#.###.#",
	"#..M..#",
	"###.###",
	"#.....#",
	"#######",
]
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const WARDEN := Vector2i(3, 3)
const EXIT := Vector2i(3, 1)
const INK := Color("#100d16")
const PAPER := Color("#e6cfaa")
const GOLD := Color("#d7a45e")
const DIM := Color("#ad9a9e")

var cell := Vector2i(3, 5)
var facing := 0
var hp := 18
var oil := 2
var foe_hp := 12
var combat := false
var seal := false
var finished := false
var message := "The bell beneath the well is still ringing."

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		act(event.physical_keycode)

func act(key: int) -> void:
	if finished:
		if key == KEY_R:
			get_tree().reload_current_scene()
	elif combat:
		match key:
			KEY_1:
				strike(4, "Your knife cuts the warden. It claws back.")
			KEY_2:
				if oil > 0:
					oil -= 1
					strike(8, "Saltfire finds its weakness.")
				else:
					message = "The salt oil flask is empty."
			KEY_3:
				if oil > 0:
					oil -= 1
					combat = false
					seal = true
					message = "It takes your oil and gives you the well seal."
				else:
					message = "You have no oil left to offer."
	else:
		match key:
			KEY_A, KEY_LEFT:
				facing = posmod(facing - 1, 4)
			KEY_D, KEY_RIGHT:
				facing = posmod(facing + 1, 4)
			KEY_W, KEY_UP:
				step(DIRECTIONS[facing])
			KEY_S, KEY_DOWN:
				step(-DIRECTIONS[facing])
	queue_redraw()

func strike(damage: int, line: String) -> void:
	foe_hp = maxi(0, foe_hp - damage)
	if foe_hp == 0:
		seal = true
		combat = false
		message = "The warden falls. You take the well seal."
	else:
		hp = maxi(0, hp - 3)
		finished = hp == 0
		message = "The well takes another name." if finished else line

func tile(at: Vector2i) -> String:
	if at.y < 0 or at.y >= MAP.size() or at.x < 0 or at.x >= MAP[0].length():
		return "#"
	return MAP[at.y][at.x]

func step(direction: Vector2i) -> void:
	var next := cell + direction
	if tile(next) == "#":
		message = "Cold masonry blocks the way."
		return
	if next == EXIT and not seal:
		message = "The iron gate asks for the well seal."
		return
	cell = next
	if cell == WARDEN and not seal:
		combat = true
		message = "The warden recoils from the salt in your flask."
	elif cell == EXIT:
		finished = true
		message = "The gate opens. Above you, the bell falls silent."
	else:
		message = "Water drips through the mortar."

func label_at(x: int, y: int, words: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func face(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, INK, 1.0)

func frame(depth: int) -> Rect2:
	var widths := [216, 148, 88, 48, 24]
	var heights := [98, 67, 40, 22, 11]
	return Rect2(240 - widths[depth], 136 - heights[depth], widths[depth] * 2, heights[depth] * 2)

func dungeon() -> void:
	draw_rect(Rect2(24, 38, 432, 196), Color("#201724"))
	draw_rect(Rect2(24, 136, 432, 98), Color("#30212b"))
	var forward: Vector2i = DIRECTIONS[facing]
	var right: Vector2i = DIRECTIONS[(facing + 1) % 4]
	var sight := 4
	for depth in range(1, 5):
		if tile(cell + forward * depth) == "#":
			sight = depth
			var end := frame(depth - 1)
			draw_rect(end, Color("#59404a").darkened(depth * 0.12))
			for row in range(1, 5):
				var y := floorf(end.position.y + end.size.y * row / 5.0)
				draw_line(Vector2(end.position.x, y), Vector2(end.end.x, y), INK)
				var x := floorf(end.get_center().x + (row % 2) * end.size.x / 5.0)
				draw_line(Vector2(x, y), Vector2(x, y + floorf(end.size.y / 5.0)), INK)
			break
	for depth in range(sight - 1, -1, -1):
		var outer := frame(depth)
		var inner := frame(depth + 1)
		var location := cell + forward * depth
		var wall_color := Color("#67444c").darkened(depth * 0.17)
		var floor_color := Color("#412b36").darkened(depth * 0.15)
		if depth < sight - 1 or sight == 4 and tile(cell + forward * sight) != "#":
			face([Vector2(outer.position.x, outer.end.y), outer.end, inner.end, Vector2(inner.position.x, inner.end.y)], floor_color)
			face([outer.position, Vector2(outer.end.x, outer.position.y), Vector2(inner.end.x, inner.position.y), inner.position], floor_color.darkened(0.35))
		if depth == sight - 1 and tile(cell + forward * sight) == "#":
			continue
		if tile(location - right) == "#":
			face([outer.position, inner.position, Vector2(inner.position.x, inner.end.y), Vector2(outer.position.x, outer.end.y)], wall_color)
		if tile(location + right) == "#":
			face([Vector2(outer.end.x, outer.position.y), Vector2(inner.end.x, inner.position.y), inner.end, outer.end], wall_color.darkened(0.23))
	if not seal and (combat or cell + forward == WARDEN):
		draw_warden(5 if combat else 3)
	if cell + forward == EXIT:
		var gate := Rect2(207, 89, 66, 100)
		draw_rect(gate, Color("#140f19"))
		for x in range(211, 273, 9):
			draw_rect(Rect2(x, 89, 3, 100), GOLD.darkened(0.55))
		draw_rect(gate, GOLD.darkened(0.44), false, 2.0)

func draw_warden(scale: int) -> void:
	var sprite := [
		"##............##",
		".##..........##.",
		"..##..####..##..",
		"...##########...",
		"....#o####o#....",
		".....######.....",
		"......####......",
		"....########....",
		"...##########...",
		"..############..",
		"..##.######.##..",
		".##..######..##.",
		".#...##..##...#.",
		".....##..##.....",
		"....###..###....",
	]
	for y in range(sprite.size()):
		for x in range(sprite[y].length()):
			var pixel: String = sprite[y][x]
			if pixel != ".":
				var color := GOLD if pixel == "o" else Color("#b58179").darkened(y * 0.027)
				draw_rect(Rect2(240 + (x - 8) * scale, 142 + (y - 8) * scale, scale, scale), color)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 480, 320), INK)
	label_at(24, 25, "THE UNSHRIVEN WELL", 19, PAPER)
	label_at(338, 24, "HP %02d  OIL %d" % [hp, oil], 14, GOLD)
	dungeon()
	draw_rect(Rect2(23, 37, 434, 198), GOLD.darkened(0.5), false, 1.0)
	if combat:
		label_at(36, 58, "ASH WARDEN  %02d/12" % foe_hp, 14, PAPER)
	elif seal:
		label_at(36, 58, "WELL SEAL", 14, GOLD)
	label_at(24, 258, message, 14, PAPER)
	var controls := "W/S  STEP       A/D  TURN"
	if finished:
		controls = "R  DESCEND AGAIN"
	elif combat:
		controls = "1  KNIFE     2  SALTFIRE     3  OFFER OIL"
	draw_line(Vector2(24, 271), Vector2(456, 271), GOLD.darkened(0.5))
	label_at(24, 297, controls, 14, DIM)

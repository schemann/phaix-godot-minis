extends Node2D
## The Short's scene: the game of main.tscn with three key caps under the floor. A cap lights while its key is down, so a press in the air
## and a key that is held at the landing can be seen next to the state label. Nothing else changes: level, knight and script are main.tscn's own.

const CAP_FILL := Color(0.114, 0.125, 0.149, 0.86) ## The outline colour of the state label.
const CAP_RIM := Color(0.74, 0.65, 0.57) ## The light stone of the floor.
const CAP_MARK := Color(0.96, 0.94, 0.9)
const LIT_FILL := Color(0.91, 0.54, 0.17) ## The plume.
const LIT_RIM := Color(1.0, 0.97, 0.9)
const LIT_MARK := Color(0.114, 0.125, 0.149)
const TOP := 528.0 ## Design pixels of the 1280 x 720 window: below the floor, inside the Short's middle 406 pixels, above its bottom 380 pixels.
const HEIGHT := 48.0

var _caps: Dictionary = {}
var _plain: StyleBoxFlat
var _lit: StyleBoxFlat

func _ready() -> void:
	_plain = _style(CAP_FILL, CAP_RIM)
	_lit = _style(LIT_FILL, LIT_RIM)
	var layer := CanvasLayer.new()
	layer.name = "Keys"
	add_child(layer)
	_add_cap(layer, "ui_left", Rect2(491.0, TOP, 64.0, HEIGHT), "")
	_add_cap(layer, "ui_accept", Rect2(565.0, TOP, 150.0, HEIGHT), "SPACE")
	_add_cap(layer, "ui_right", Rect2(725.0, TOP, 64.0, HEIGHT), "")

func _style(fill: Color, rim: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = rim
	box.set_border_width_all(4)
	box.set_corner_radius_all(6)
	return box

func _add_cap(layer: CanvasLayer, action: String, rect: Rect2, text: String) -> void:
	var cap := Panel.new()
	cap.position = rect.position
	cap.size = rect.size
	cap.add_theme_stylebox_override("panel", _plain)
	layer.add_child(cap)
	var mark: CanvasItem
	if text != "":
		var label := Label.new()
		label.text = text
		label.size = rect.size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		cap.add_child(label)
		mark = label
	else:
		var side := 1.0 if action == "ui_right" else -1.0
		var middle := rect.size / 2.0
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([middle + Vector2(-8.0 * side, -12.0), middle + Vector2(8.0 * side, 0.0), middle + Vector2(-8.0 * side, 12.0)])
		cap.add_child(arrow)
		mark = arrow
	_caps[action] = {cap = cap, mark = mark, lit = false}
	_paint(_caps[action], false)

func _paint(entry: Dictionary, lit: bool) -> void:
	entry.lit = lit
	(entry.cap as Panel).add_theme_stylebox_override("panel", _lit if lit else _plain)
	var colour := LIT_MARK if lit else CAP_MARK
	if entry.mark is Label:
		(entry.mark as Label).add_theme_color_override("font_color", colour)
	else:
		(entry.mark as Polygon2D).color = colour

func _process(_delta: float) -> void:
	for action: String in _caps:
		var entry: Dictionary = _caps[action]
		var down := Input.is_action_pressed(action)
		if down != entry.lit:
			_paint(entry, down)

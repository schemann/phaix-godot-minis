extends Node2D
## The Short's scene for its last line: the room and the knight of main.tscn, but the knight runs short/player_more.gd, the player
## script with the enum grown by ATTACK, CROUCH and DASH. Four key caps under the floor light while their key is down (the look of short/keys.gd).
## "attack" (X) and "dash" (Shift) are actions of this scene only; the project's own project.godot is not touched.

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

func _enter_tree() -> void:
	_add_action("attack", KEY_X)
	_add_action("dash", KEY_SHIFT)

func _ready() -> void:
	_plain = _style(CAP_FILL, CAP_RIM)
	_lit = _style(LIT_FILL, LIT_RIM)
	var layer := CanvasLayer.new()
	layer.name = "Keys"
	add_child(layer)
	_add_cap(layer, "ui_right", Rect2(454.0, TOP, 64.0, HEIGHT), "", 1.0)
	_add_cap(layer, "attack", Rect2(528.0, TOP, 64.0, HEIGHT), "X", 0.0)
	_add_cap(layer, "ui_down", Rect2(602.0, TOP, 64.0, HEIGHT), "", 0.0)
	_add_cap(layer, "dash", Rect2(676.0, TOP, 150.0, HEIGHT), "SHIFT", 0.0)

func _add_action(action: String, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func _style(fill: Color, rim: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = rim
	box.set_border_width_all(4)
	box.set_corner_radius_all(6)
	return box

## `side` is 1.0 for an arrow that points right, 0.0 for the one that points down; a cap with a text carries the text.
func _add_cap(layer: CanvasLayer, action: String, rect: Rect2, text: String, side: float) -> void:
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
		var middle := rect.size / 2.0
		var arrow := Polygon2D.new()
		if side == 1.0:
			arrow.polygon = PackedVector2Array([middle + Vector2(-8.0, -12.0), middle + Vector2(8.0, 0.0), middle + Vector2(-8.0, 12.0)])
		else:
			arrow.polygon = PackedVector2Array([middle + Vector2(-12.0, -8.0), middle + Vector2(12.0, -8.0), middle + Vector2(0.0, 8.0)])
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

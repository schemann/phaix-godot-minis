extends Node2D
## The Short's scene: the game of main.tscn with what the voice talks about made visible. Four key caps beside the knight light
## while their key is down. A readout above the knight shows its real velocity: the direction (velocity / speed), the length of that direction
## and the speed in pixels per second, read from `velocity` and `speed` every frame. A code panel under the knight shows the live source of the
## script that moves it (`source_code` of the knight's script), with the line the voice is talking about marked.
## The knight starts on short/player_bug.gd (the direction from two axes: a diagonal is 1.41 long). `fix()` puts the project's own player.gd
## back on it (one call, Input.get_vector: a diagonal is 1.00 long). Nothing is painted that the game does not compute.
## A take drives it with `set` events (`mark`, `full`, the `visible` of Hud/Readout and Hud/Code) and the calls `fix` and `rise`.

const BUG := preload("res://short/player_bug.gd")
const FIXED := preload("res://player.gd")

const FILL := Color(0.114, 0.125, 0.149, 0.88) ## The outline colour of the state label of mini 04.
const RIM := Color(0.74, 0.65, 0.57) ## The light stone of the floor.
const TEXT := Color(0.96, 0.94, 0.9)
const LIT_FILL := Color(0.91, 0.54, 0.17) ## The plume.
const LIT_RIM := Color(1.0, 0.97, 0.9)
const DARK := Color(0.114, 0.125, 0.149)
const TEAL := Color(0.44, 0.84, 0.82) ## The knight's armour.
const CAP := 36.0 ## A key cap, in design pixels of the 1280 x 720 window: the Short shows its middle 406 pixels and not its bottom 143.
const CAPS_LEFT := 452.0
const CAPS_TOP := 322.0
const READOUT := Rect2(457.0, 203.0, 366.0, 0.0)
const CODE := Rect2(439.0, 452.0, 402.0, 0.0)
const BODY_SIZE := 14
const FULL_SIZE := 13
const FULL_TOP := 384.0 ## The whole script is taller: the camera lifts the knight (`rise`) and the panel moves up under it.
const RISE := Vector2(0.0, 40.0) ## World pixels: at the camera's zoom 2 the knight stands 80 design pixels higher.

var mark := "": set = _set_mark ## The panel marks the first line that contains this text.
var full := false: set = _set_full ## false: the body of _physics_process, true: every line of the script.

var _player: CharacterBody2D
var _font := SystemFont.new()
var _caps: Dictionary = {}
var _holder: Control
var _plain: StyleBoxFlat
var _lit: StyleBoxFlat
var _direction: Label
var _length: Label
var _speed: Label
var _readout: PanelContainer
var _code: PanelContainer
var _rows: VBoxContainer
var _source := ""

func _ready() -> void:
	_player = $Player as CharacterBody2D
	_font.font_names = PackedStringArray(["Menlo", "Monaco", "Consolas", "DejaVu Sans Mono", "monospace"])
	_plain = _style(FILL, RIM, 4, 6)
	_lit = _style(LIT_FILL, LIT_RIM, 4, 6)
	_player.set_script(BUG)
	_player.set_physics_process(true)
	var hud := CanvasLayer.new()
	hud.name = "Hud"
	hud.layer = 20
	add_child(hud)
	_build_caps(hud)
	_build_readout(hud)
	_build_code(hud)
	_code.visible = false
	_rebuild()

## The one call of the fix: the project's own player.gd goes back on the knight, and the panel shows it.
func fix() -> void:
	_player.set_script(FIXED)
	_player.set_physics_process(true)
	_rebuild()

## The camera lifts over a third of a second and the key caps with it, so the whole script fits under the knight.
func rise() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property($Player/Camera2D, "offset", RISE, 0.35)
	tween.tween_property(_holder, "position", -RISE * 2.0, 0.35)

func _style(fill: Color, rim: Color, border: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = rim
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	return box

func _build_caps(hud: CanvasLayer) -> void:
	_holder = Control.new()
	_holder.name = "Caps"
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_holder)
	_add_cap(_holder, "ui_up", Vector2(CAPS_LEFT + CAP + 4.0, CAPS_TOP), Vector2(0.0, -1.0))
	_add_cap(_holder, "ui_left", Vector2(CAPS_LEFT, CAPS_TOP + CAP + 4.0), Vector2(-1.0, 0.0))
	_add_cap(_holder, "ui_down", Vector2(CAPS_LEFT + CAP + 4.0, CAPS_TOP + CAP + 4.0), Vector2(0.0, 1.0))
	_add_cap(_holder, "ui_right", Vector2(CAPS_LEFT + 2.0 * (CAP + 4.0), CAPS_TOP + CAP + 4.0), Vector2(1.0, 0.0))

func _add_cap(parent: Control, action: String, at: Vector2, side: Vector2) -> void:
	var cap := Panel.new()
	cap.position = at
	cap.size = Vector2(CAP, CAP)
	cap.add_theme_stylebox_override("panel", _plain)
	parent.add_child(cap)
	var middle := cap.size / 2.0
	var across := Vector2(-side.y, side.x)
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([middle - side * 7.0 + across * 10.0, middle + side * 8.0, middle - side * 7.0 - across * 10.0])
	cap.add_child(arrow)
	_caps[action] = {cap = cap, mark = arrow, lit = false}
	_paint(_caps[action], false)

func _paint(entry: Dictionary, lit: bool) -> void:
	entry.lit = lit
	(entry.cap as Panel).add_theme_stylebox_override("panel", _lit if lit else _plain)
	(entry.mark as Polygon2D).color = DARK if lit else TEXT

func _build_readout(hud: CanvasLayer) -> void:
	_readout = PanelContainer.new()
	_readout.name = "Readout"
	_readout.position = READOUT.position
	_readout.custom_minimum_size = Vector2(READOUT.size.x, 0.0)
	_readout.add_theme_stylebox_override("panel", _style(FILL, RIM, 3, 6))
	hud.add_child(_readout)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", -2)
	_readout.add_child(rows)
	_direction = _row(rows, 17, TEXT)
	_length = _row(rows, 34, TEAL)
	_speed = _row(rows, 17, TEXT)

func _row(parent: Control, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label

func _build_code(hud: CanvasLayer) -> void:
	_code = PanelContainer.new()
	_code.name = "Code"
	_code.position = CODE.position
	_code.custom_minimum_size = Vector2(CODE.size.x, 0.0)
	_code.add_theme_stylebox_override("panel", _style(FILL, RIM, 3, 6))
	hud.add_child(_code)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	_code.add_child(margin)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 1)
	margin.add_child(_rows)

func _set_mark(value: String) -> void:
	mark = value
	if _rows != null:
		_rebuild()

func _set_full(value: bool) -> void:
	full = value
	if _rows != null:
		_code.position.y = FULL_TOP if full else CODE.position.y
		_rebuild()

## The rows of the panel from the source of the knight's script now: one row per non-empty line, the first one that contains `mark` lit.
func _rebuild() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.free()
	_source = (_player.get_script() as GDScript).source_code
	var inside := false
	var marked := false
	for raw: String in _source.split("\n"):
		if raw.strip_edges() == "":
			continue
		if not full and not inside:
			inside = raw.begins_with("func ")
			continue
		var lit := mark != "" and not marked and raw.contains(mark)
		marked = marked or lit
		_add_row(raw.replace("\t", "    "), lit)

func _add_row(text: String, lit: bool) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _style(LIT_FILL if lit else Color(0.0, 0.0, 0.0, 0.0), LIT_FILL, 0, 3))
	var size := FULL_SIZE if full else BODY_SIZE
	var label := Label.new()
	label.text = _wrap(text, size, CODE.size.x - 12.0 - 6.0)
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_constant_override("line_spacing", -2)
	label.add_theme_color_override("font_color", DARK if lit else TEXT)
	row.add_child(label)
	_rows.add_child(row)

## A line that is wider than the panel continues on the next row, four spaces further in, so a wrapped line still reads as one line.
func _wrap(text: String, size: int, width: float) -> String:
	var indent := text.length() - text.lstrip(" ").length()
	var hang := " ".repeat(indent + 4)
	var rows: Array[String] = []
	var current := ""
	for word: String in text.lstrip(" ").split(" "):
		var candidate := (" ".repeat(indent) + word) if current == "" else current + " " + word
		if current != "" and _font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > width:
			rows.append(current)
			current = hang + word
		else:
			current = candidate
	rows.append(current)
	return "\n".join(rows)

func _process(_delta: float) -> void:
	for action: String in _caps:
		var entry: Dictionary = _caps[action]
		var down := Input.is_action_pressed(action)
		if down != entry.lit:
			_paint(entry, down)
	if _readout.visible:
		var direction := _player.velocity / float(_player.get("speed"))
		var length := direction.length()
		_direction.text = "direction (%.2f, %.2f)" % [_clean(direction.x), _clean(direction.y)]
		_length.text = "length %.2f" % length
		_length.add_theme_color_override("font_color", LIT_FILL if length > 1.005 else TEAL)
		_speed.text = "speed %d px/s" % roundi(_player.velocity.length())

## A -0.00 would print as "-0.00": a component below the printed precision is zero.
func _clean(value: float) -> float:
	return 0.0 if absf(value) < 0.005 else value

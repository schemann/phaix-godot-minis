extends CanvasLayer
## The readout of the Short and of the long video's clamp shot: the game's own numbers, read from the Player and its camera every frame, in
## degrees - the yaw of the Player and the pitch of its Camera3D. Nothing is typed by hand, and the pitch turns red while the view is upside down (the camera's up
## vector points down). It sits in the lower part of the middle third of the picture, inside the Short's 608 pixel window and under the Short's own badge and text, which
## covered it when it was at the top (first build, 2026-11-08).

const WIDTH := 330.0
const TOP := 455.0 ## design pixels from the top of the 720 px design height: in the Short (the 608 px window of the 1920 px frame, scaled to 1080 x 1920) that is y 1210 to 1500, below the Short's badge and its text (y 215 to 530) and inside the safe area (to y 1540)
const WHITE := Color(0.94, 0.95, 0.97)
const RED := Color(1.0, 0.36, 0.3)

var _yaw: Label
var _pitch: Label
var _player: Node3D
var _camera: Camera3D

func _ready() -> void:
	_player = get_parent().get_node("Player") as Node3D
	_camera = _player.get_node("Camera3D") as Camera3D
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -WIDTH / 2.0
	panel.offset_right = WIDTH / 2.0
	panel.offset_top = TOP
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE ## a readout takes no mouse: the mouse motion must reach the Player's _unhandled_input
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.78)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14.0)
	panel.add_theme_stylebox_override("panel", style)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(rows)
	_yaw = _row(rows, "yaw")
	_pitch = _row(rows, "pitch")
	add_child(panel)

## One row: the name on the left, the number on the right.
func _row(rows: VBoxContainer, title: String) -> Label:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := _label(title)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value := _label("")
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size.x = 170.0
	row.add_child(name_label)
	row.add_child(value)
	rows.add_child(row)
	return value

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", WHITE)
	return label

func _process(_delta: float) -> void:
	_yaw.text = "%+.1f°" % wrapf(_player.rotation_degrees.y, -180.0, 180.0)
	_pitch.text = "%+.1f°" % _camera.rotation_degrees.x
	_pitch.add_theme_color_override("font_color", RED if _camera.global_transform.basis.y.y < 0.0 else WHITE)

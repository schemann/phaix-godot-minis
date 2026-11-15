extends Node2D
## The Short's marker of the node: the Banner's rectangle and its position, drawn over the game picture so the viewer sees the
## node stand still while the pixels move, and, for the UV line, a probe that reads the position in the texture.

const BOX := Rect2(480, 336, 320, 272) ## the Banner: position (640, 472), texture 320 x 272, centred
const PIVOT := Vector2(640, 472)
const LINE := Color(1, 1, 1, 0.9)

var show_box := true:
	set(value):
		show_box = value
		queue_redraw()
var show_corners := false:
	set(value):
		show_corners = value
		queue_redraw()
var probe := Vector2(-1, -1): ## UV of the probe; negative = hidden
	set(value):
		probe = value
		queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	if show_box:
		draw_rect(BOX, LINE, false, 3.0)
		draw_line(PIVOT + Vector2(-12, 0), PIVOT + Vector2(12, 0), LINE, 3.0)
		draw_line(PIVOT + Vector2(0, -12), PIVOT + Vector2(0, 12), LINE, 3.0)
	if show_corners:
		_text(font, BOX.position + Vector2(10, 28), "0, 0", 24)
		_text(font, BOX.position + BOX.size - Vector2(10 + font.get_string_size("1, 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x, 12), "1, 1", 24)
	if probe.x >= 0.0:
		var at := BOX.position + probe * BOX.size
		draw_circle(at, 10.0, Color(0, 0, 0, 0.8))
		draw_circle(at, 7.0, Color.WHITE)
		_text(font, Vector2(BOX.position.x, BOX.position.y - 16), "UV = (%.2f, %.2f)" % [probe.x, probe.y], 26, BOX.size.x)

func _text(font: Font, at: Vector2, text: String, size: int, width: float = -1.0) -> void:
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER if width > 0.0 else HORIZONTAL_ALIGNMENT_LEFT, width, size, 6, Color(0, 0, 0, 0.9))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER if width > 0.0 else HORIZONTAL_ALIGNMENT_LEFT, width, size, Color.WHITE)

extends CanvasLayer
## The Output of the game as a readout over the picture (series rule 50: the Short shows the error while the voice says it). The error text is the engine's own,
## taken from a Logger, and the other lines are the real signals of the door and of the room, in the order they happen. Nothing in it is typed by hand. It lives in the
## root of the tree, so it outlives the scenes a door loads, and it starts a new group when the physics frame changes: one door crossing is one group.

const ERROR_COLOR := "#ff7085"
const TEXT_COLOR := "#d9dde3"
const BAR_COLOR := Color("#2b3240")
const BAR_ERROR_COLOR := Color("#8a2b3c")
const FLASH_SECONDS := 0.6

class Capture extends Logger:
	var console: Node

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		console.add_line("ERROR: " + (rationale if rationale != "" else code), ERROR_COLOR)

var rect := Rect2(437.33, 197.0, 405.33, 98.0) ## In the project's 1280 x 720 units, as the viewport stretches them.
var font_size := 11
var rows: Array[String] = [] ## The lines of the group on show, plain text.

var _bbcode: Array[String] = []
var _frame := -1
var _mutex := Mutex.new()
var _label: RichTextLabel
var _bar: ColorRect
var _flash := 0.0 ## Seconds the header stays red after an error was printed: a new error is seen even when its text is the same as the one before.
var _capture := Capture.new()
var _dirty := true

func _ready() -> void:
	layer = 100
	Engine.set_meta("demo_console", self)
	_capture.console = self
	OS.add_logger(_capture)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Menlo", "Monaco", "Consolas", "DejaVu Sans Mono", "Courier New"])
	var border := ColorRect.new()
	border.color = Color("#4a5364")
	border.position = rect.position - Vector2.ONE
	border.size = rect.size + Vector2.ONE * 2.0
	add_child(border)
	var panel := ColorRect.new()
	panel.color = Color("#1b1f26")
	panel.position = rect.position
	panel.size = rect.size
	add_child(panel)
	var bar_height := font_size * 1.6
	_bar = ColorRect.new()
	_bar.color = BAR_COLOR
	_bar.position = rect.position
	_bar.size = Vector2(rect.size.x, bar_height)
	add_child(_bar)
	var title := Label.new()
	title.text = "Output"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", font_size)
	title.add_theme_color_override("font_color", Color("#9aa4b5"))
	title.position = rect.position + Vector2(font_size * 0.6, font_size * 0.15)
	add_child(title)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_override("normal_font", font)
	_label.add_theme_font_size_override("normal_font_size", font_size)
	_label.add_theme_constant_override("line_separation", 1)
	_label.position = rect.position + Vector2(font_size * 0.5, bar_height + 2.0)
	_label.size = rect.size - Vector2(font_size, bar_height + 3.0)
	add_child(_label)

func _exit_tree() -> void:
	OS.remove_logger(_capture)
	Engine.remove_meta("demo_console")

## One line of the readout. A line that arrives in another physics frame than the one before starts a new group (the one on show is cleared).
func add_line(text: String, color := TEXT_COLOR) -> void:
	_mutex.lock()
	var frame := Engine.get_physics_frames()
	if frame != _frame:
		_frame = frame
		rows.clear()
		_bbcode.clear()
	if color == ERROR_COLOR:
		_flash = FLASH_SECONDS
	rows.append(text)
	_bbcode.append("[color=%s]%s[/color]" % [color, text.replace("[", "[lb]")])
	_dirty = true
	_mutex.unlock()

func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_bar.color = BAR_COLOR.lerp(BAR_ERROR_COLOR, _flash / FLASH_SECONDS)
	if _dirty:
		_mutex.lock()
		_label.text = "\n".join(_bbcode)
		_dirty = false
		_mutex.unlock()

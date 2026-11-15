extends CanvasLayer
## The Short's scene tree: two small panels beside the knight list what is under the Gun and under the current scene,
## read from get_children() every frame, so a bullet that the code adds shows up as a child of the node it was added to and leaves the list
## when it frees itself. Nothing is drawn that the tree does not hold. A bullet is shown by the name of its scene's root ("Bullet"), because the
## engine renames the second one to "@Area2D@2"; this readout's own node is left out of the list. The take shows the panels with a `visible` event.

const FILL := Color(0.114, 0.125, 0.149, 0.9) ## The outline colour of mini 04's state label.
const RIM := Color(0.74, 0.65, 0.57) ## The light stone of the floor.
const TEXT := Color(0.96, 0.94, 0.9)
const BULLET := Color(0.97, 0.66, 0.2) ## The plume.
const FONT_SIZE := 19
const LINE := 22.0
const PAD := 8.0
const INDENT := 18.0
const TOP := 296.0 ## Design pixels of the 1280 x 720 window: beside the knight, inside the Short's middle 406 pixels, above its bottom 380 pixels.
const MAX_ROWS := 12 ## A panel's rows; more bullets than that end in a "+n more" row (a count read from the same list).
const LEFT := Rect2(459.0, TOP, 116.0, 0.0) ## Narrowed by 8 pixels: its right edge stays left of the knight's plume tip (design pixels 576 to 588).
const RIGHT := Rect2(703.0, TOP, 118.0, 0.0)

var _canvas: Control
var _font: Font
var _box: StyleBoxFlat

func _ready() -> void:
	layer = 20
	visible = false
	_font = ThemeDB.fallback_font
	_box = StyleBoxFlat.new()
	_box.bg_color = FILL
	_box.border_color = RIM
	_box.set_border_width_all(3)
	_box.set_corner_radius_all(6)
	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_paint)
	add_child(_canvas)
	_become_current_scene.call_deferred()

## A take on the old Mac loads the scene under its own node, so get_tree().current_scene would be that node; the game's current scene is its Main.
## A take on a Windows host lives in a SubViewport that is the current scene (the take has "flat_root": the SubViewport is Main, shots.gd): the
## scene stays where it is, because only a SubViewport answers with the mouse the take pushes into it (the old reparent to the root window
## took the gun away from the mouse, so it never turned and every bullet flew the same way).
func _become_current_scene() -> void:
	var scene := get_parent()
	if scene.get_viewport() != get_tree().root or get_tree().current_scene == scene:
		return
	if scene.get_parent() != get_tree().root:
		scene.reparent(get_tree().root)
	get_tree().current_scene = scene

func _process(_delta: float) -> void:
	if visible:
		_canvas.queue_redraw()

func _paint() -> void:
	var scene := get_parent() ## The scene the readout belongs to: the current scene in the game, in a take too.
	if scene == null:
		return
	var gun := scene.get_node_or_null("Player/Gun")
	if gun != null:
		_panel(LEFT, gun, "Gun")
	_panel(RIGHT, scene, scene.name)

func _panel(rect: Rect2, node: Node, title: String) -> void:
	var rows: Array[Node] = []
	for child: Node in node.get_children():
		if child != self:
			rows.append(child)
	var room := MAX_ROWS - 1
	var shown := rows.size() if rows.size() <= room else room - 1
	var count := 1 + shown + (1 if shown < rows.size() else 0)
	rect.size.y = PAD * 2.0 + LINE * count
	_canvas.draw_style_box(_box, rect)
	var x := rect.position.x + PAD + 4.0
	var y := rect.position.y + PAD + LINE - 5.0
	_canvas.draw_string(_font, Vector2(x, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)
	var guide_x := x + 5.0
	var last_y := y
	for i in shown:
		y += LINE
		last_y = y - LINE * 0.35
		_canvas.draw_line(Vector2(guide_x, y - LINE * 0.35), Vector2(x + INDENT - 4.0, y - LINE * 0.35), RIM, 2.0)
		var child := rows[i]
		var colour := BULLET if _is_bullet(child) else TEXT
		_canvas.draw_string(_font, Vector2(x + INDENT, y), _label(child), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, colour)
	if shown < rows.size():
		y += LINE
		last_y = y - LINE * 0.35
		_canvas.draw_line(Vector2(guide_x, y - LINE * 0.35), Vector2(x + INDENT - 4.0, y - LINE * 0.35), RIM, 2.0)
		_canvas.draw_string(_font, Vector2(x + INDENT, y), "+%d more" % (rows.size() - shown), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, RIM)
	if count > 1:
		_canvas.draw_line(Vector2(guide_x, rect.position.y + PAD + LINE - 2.0), Vector2(guide_x, last_y), RIM, 2.0)

func _is_bullet(node: Node) -> bool:
	return node.scene_file_path.ends_with("bullet.tscn")

func _label(node: Node) -> String:
	if _is_bullet(node):
		return (load(node.scene_file_path) as PackedScene).get_state().get_node_name(0)
	return String(node.name)

extends Area2D
## The Short's own variant of the project's pickup.gd: the knight walking into it uses the item, and the label reads the item live, so every change is on screen.

@export var item: Item

@onready var icon: Sprite2D = $Icon
@onready var hud: CanvasLayer = $Hud
@onready var label: Label = $Hud/Label
@onready var file: Label = $Hud/File

func _ready() -> void:
	icon.texture = item.icon
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	hud.offset = get_viewport().get_canvas_transform() * global_position
	label.text = "%s\nx%d" % [item.title, item.uses]
	file.text = item.resource_path.get_file() if item.resource_path != "" else "own copy"

func _on_body_entered(_body: Node2D) -> void:
	item.uses -= 1

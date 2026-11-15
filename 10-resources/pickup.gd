extends Node2D

@export var item: Item

@onready var icon: Sprite2D = $Icon
@onready var label: Label = $Label

func _ready() -> void:
	icon.texture = item.icon
	label.text = "%s x%d" % [item.title, item.uses]

extends Node2D
## The room of a demo take: it puts the Output readout into the root of the tree once, where the next room finds it (series rule 50).

@export var console_rect := Rect2(437.33, 197.0, 405.33, 98.0)
@export var console_font := 11

func _ready() -> void:
	if get_tree().root.get_node_or_null("DemoConsole") == null:
		var console := (load("res://short/console.gd") as GDScript).new() as CanvasLayer
		console.name = "DemoConsole"
		console.set("rect", console_rect)
		console.set("font_size", console_font)
		get_tree().root.add_child.call_deferred(console)

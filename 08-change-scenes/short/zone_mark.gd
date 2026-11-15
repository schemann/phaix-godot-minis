extends Node2D
## Draws the door's zone, the shape of its Area2D, in the editor's teal for the demo takes: faint while nobody is in it, stronger while the knight touches it.

var _lit := false

func _process(_delta: float) -> void:
	var lit := (get_node("../Door") as Area2D).has_overlapping_bodies()
	if lit != _lit:
		_lit = lit
		queue_redraw()

func _draw() -> void:
	var door := get_node("../Door") as Area2D
	var shape := door.get_node("CollisionShape2D") as CollisionShape2D
	var size := (shape.shape as RectangleShape2D).size
	var rect := Rect2(door.position + shape.position - size / 2.0, size)
	draw_rect(rect, Color(0.25, 0.85, 0.9, 0.4 if _lit else 0.14))
	draw_rect(rect, Color(0.25, 0.85, 0.9, 0.9), false, 1.0)

extends CharacterBody2D
## The Short's wrong player: the project's player.gd with ONE line changed. The direction is built from two axes, so two keys
## give Vector2(1, 1), a vector 1.41 long, and a diagonal is 41 percent faster. Only short/diagonal.tscn puts this script on the knight; the game's
## own player.gd is not touched, and `fix()` of that scene puts it back.

@export var speed := 300.0

func _physics_process(_delta: float) -> void:
	var direction := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	velocity = direction * speed
	move_and_slide()

extends CharacterBody2D
## The Short's own variant of the project's enemy.gd: the vector to the target is the velocity (times 0.25, so the rush lasts long enough to watch). His scene is Floating like the project's enemy.
## He is on layer 2 and looks at layer 1 (the knight): he stops at the knight's shape, and the knight, who looks at layer 1 only, does not feel him and stays where he stands. (With the mask 0 of the rounds before he walked through the knight and the knight made room for him: 13.5 px/s across the room.)

@export var target: Node2D

func _physics_process(_delta: float) -> void:
	velocity = (target.global_position - global_position) * 0.25
	move_and_slide()

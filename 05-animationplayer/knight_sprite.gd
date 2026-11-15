extends AnimatedSprite2D
## The knight's animation, the same file in every mini from 03 on: walk while the body moves, idle while it stands, turned the way it walks (mini 02).

@onready var _body := get_parent() as CharacterBody2D

func _process(_delta: float) -> void:
	if _body == null or _body.velocity.length() < 1.0:
		play("idle")
		return
	play("walk")
	if absf(_body.velocity.x) > 1.0:
		flip_h = _body.velocity.x < 0.0

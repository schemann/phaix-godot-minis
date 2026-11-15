extends AnimatedSprite2D
## The knight's animation (mini 02, kept in every mini from 03 on). Mini 11 reads the movement that happened, get_real_velocity(), not the velocity the body asks for:
## the goblin's script sets his velocity every frame, also while the knight or a wall holds him, and he stands there, so he plays idle. Walk while the body really moves,
## turned the way it is pushed.

@onready var _body := get_parent() as CharacterBody2D

func _process(_delta: float) -> void:
	if _body == null or _body.get_real_velocity().length() < 8.0:
		play("idle")
	else:
		play("walk")
	if _body != null and absf(_body.velocity.x) > 1.0:
		flip_h = _body.velocity.x < 0.0

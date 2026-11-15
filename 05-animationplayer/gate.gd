extends AnimatableBody2D

var is_open := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		is_open = not is_open
		if is_open:
			animation_player.play("open")
		else:
			animation_player.play_backwards("open")

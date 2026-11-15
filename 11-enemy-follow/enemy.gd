extends CharacterBody2D

@export var speed := 60.0
@export var target: Node2D

func _physics_process(_delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * speed
	move_and_slide()

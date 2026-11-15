extends CharacterBody2D

enum State { IDLE, WALK, JUMP }

const SPEED := 300.0
const JUMP_SPEED := 450.0

var state := State.IDLE

@onready var label: Label = $Label

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	var jump := Input.is_action_just_pressed("ui_accept")
	velocity.x = direction * SPEED
	if not is_on_floor():
		velocity += get_gravity() * delta
	match state:
		State.IDLE:
			if jump:
				enter_jump()
			elif direction != 0.0:
				enter_walk()
		State.WALK:
			if jump:
				enter_jump()
			elif direction == 0.0:
				enter_idle()
		State.JUMP:
			if is_on_floor():
				if direction == 0.0:
					enter_idle()
				else:
					enter_walk()
	move_and_slide()

func enter_idle() -> void:
	state = State.IDLE
	label.text = "IDLE"

func enter_walk() -> void:
	state = State.WALK
	label.text = "WALK"

func enter_jump() -> void:
	state = State.JUMP
	label.text = "JUMP"
	velocity.y = -JUMP_SPEED

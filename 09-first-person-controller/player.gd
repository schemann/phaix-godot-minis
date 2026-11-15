extends CharacterBody3D

@export var speed := 5.0
@export var sensitivity := 0.003

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.screen_relative.x * sensitivity)
		camera.rotate_x(-event.screen_relative.y * sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := transform.basis * Vector3(input.x, 0.0, input.y)
	velocity = direction * speed
	move_and_slide()

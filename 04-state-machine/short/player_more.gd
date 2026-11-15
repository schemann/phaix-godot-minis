extends CharacterBody2D
## The Short's demo of "it scales to attack, crouch and dash": the tutorial's player.gd with three more states.
## The enum grew by ATTACK, CROUCH and DASH, the match by three branches, and each new state has an enter function that sets the label,
## exactly as idle, walk and jump do. The knight of the game itself keeps its three states; this script runs only in short/states_more.tscn.

enum State { IDLE, WALK, JUMP, ATTACK, CROUCH, DASH }

const SPEED := 300.0
const JUMP_SPEED := 450.0
const CROUCH_SPEED := 100.0 ## A crouch walks at a third of the speed.
const DASH_SPEED := 900.0
const ATTACK_TIME := 0.4
const DASH_TIME := 0.3
const GHOST_EVERY := 0.04 ## Seconds between two after-images of a dash.
const STAND_HEIGHT := 88.0
const CROUCH_HEIGHT := 54.0

var state := State.IDLE
var timer := 0.0
var ghost_timer := 0.0

@onready var label: Label = $Label
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body: CollisionShape2D = $CollisionShape2D

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	var jump := Input.is_action_just_pressed("ui_accept")
	var attack := Input.is_action_just_pressed("attack")
	var dash := Input.is_action_just_pressed("dash")
	var crouch := Input.is_action_pressed("ui_down")
	velocity.x = direction * SPEED
	if not is_on_floor():
		velocity += get_gravity() * delta
	match state:
		State.IDLE:
			if jump:
				enter_jump()
			elif attack:
				enter_attack()
			elif dash:
				enter_dash()
			elif crouch:
				enter_crouch()
			elif direction != 0.0:
				enter_walk()
		State.WALK:
			if jump:
				enter_jump()
			elif attack:
				enter_attack()
			elif dash:
				enter_dash()
			elif crouch:
				enter_crouch()
			elif direction == 0.0:
				enter_idle()
		State.JUMP:
			if is_on_floor():
				if direction == 0.0:
					enter_idle()
				else:
					enter_walk()
		State.ATTACK:
			velocity.x = 0.0
			timer -= delta
			if timer <= 0.0:
				leave(direction)
		State.CROUCH:
			velocity.x = direction * CROUCH_SPEED
			if not crouch:
				stand_up()
				leave(direction)
		State.DASH:
			velocity.x = DASH_SPEED
			timer -= delta
			ghost_timer -= delta
			if ghost_timer <= 0.0:
				ghost_timer = GHOST_EVERY
				spawn_ghost()
			if timer <= 0.0:
				leave(direction)
	move_and_slide()

func leave(direction: float) -> void:
	if direction == 0.0:
		enter_idle()
	else:
		enter_walk()

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

func enter_attack() -> void:
	state = State.ATTACK
	label.text = "ATTACK"
	timer = ATTACK_TIME
	swing()

func enter_crouch() -> void:
	state = State.CROUCH
	label.text = "CROUCH"
	var drop := (STAND_HEIGHT - CROUCH_HEIGHT) / 2.0
	sprite.scale = Vector2(1.1, CROUCH_HEIGHT / STAND_HEIGHT)
	sprite.position.y = drop
	(body.shape as RectangleShape2D).size.y = CROUCH_HEIGHT
	body.position.y = drop

func enter_dash() -> void:
	state = State.DASH
	label.text = "DASH"
	timer = DASH_TIME
	ghost_timer = 0.0

func stand_up() -> void:
	sprite.scale = Vector2.ONE
	sprite.position.y = 0.0
	(body.shape as RectangleShape2D).size.y = STAND_HEIGHT
	body.position.y = 0.0

## The blade of an attack: a plain polygon that swings from over the head down to the front and fades, while the knight leans into it.
func swing() -> void:
	var blade := Polygon2D.new()
	blade.polygon = PackedVector2Array([Vector2(0.0, -4.0), Vector2(52.0, -4.0), Vector2(66.0, 0.0), Vector2(52.0, 4.0), Vector2(0.0, 4.0)])
	blade.color = Color(0.96, 0.94, 0.9)
	blade.position = Vector2(24.0, 6.0)
	blade.rotation_degrees = -110.0
	add_child(blade)
	var slash := create_tween()
	slash.tween_property(blade, "rotation_degrees", 50.0, 0.16)
	slash.tween_interval(0.1)
	slash.tween_property(blade, "modulate:a", 0.0, 0.12)
	slash.tween_callback(blade.queue_free)
	var lean := create_tween()
	lean.tween_property(sprite, "rotation_degrees", 14.0, 0.08)
	lean.tween_property(sprite, "rotation_degrees", 0.0, 0.3)

## An after-image of a dash: the knight's current frame where it was, turned the way it faces, fading out behind it.
func spawn_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.55)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	ghost.global_position = global_position
	var fade := ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, 0.3)
	fade.tween_callback(ghost.queue_free)

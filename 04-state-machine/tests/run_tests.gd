extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

const IDLE := 0 ## The order of enum State in player.gd.
const WALK := 1
const JUMP := 2
const NAMES := ["IDLE", "WALK", "JUMP"]

var failures := 0
var player: CharacterBody2D

func _init() -> void:
	await process_frame
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	player = main.get_node("Player")
	await _ticks(20)

	_check(player.is_on_floor(), "the player stands on the floor")
	_check(player.state == IDLE and player.label.text == "IDLE", "it starts in idle, and the label says so")
	var knight := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(knight != null and knight.sprite_frames.has_animation("idle") and knight.sprite_frames.has_animation("walk"), "the knight is an AnimatedSprite2D with idle and walk")

	var start := player.position.x
	Input.action_press("ui_right")
	await _ticks(20)
	_check(player.state == WALK and player.label.text == "WALK", "a direction key starts walk, the label follows")
	_check(absf(player.position.x - start - 100.0) < 15.0, "a third of a second at speed 300 covers about 100 pixels, got %.1f" % (player.position.x - start))
	Input.action_release("ui_right")
	await _ticks(2)
	_check(player.state == IDLE and player.label.text == "IDLE", "letting go goes back to idle")
	var rest: float = player.position.x
	await _ticks(10)
	_check(player.position.x == rest, "idle stands still")

	var floor_y: float = player.position.y
	await _tap("ui_accept")
	_check(player.state == JUMP and player.label.text == "JUMP", "the jump key starts jump, the label follows")
	_check(player.velocity.y < 0.0, "jump sets an upward velocity")
	await _ticks(25)
	_check(player.position.y < floor_y - 50.0, "the player is in the air, got %.1f above the floor" % (floor_y - player.position.y))

	var before: float = player.velocity.y
	await _tap("ui_accept")
	_check(player.state == JUMP, "the jump key in the air leaves the state at jump")
	_check(player.velocity.y > before and player.velocity.y > -300.0, "no second jump in the air, velocity y went %.1f to %.1f" % [before, player.velocity.y])
	await _until_floor(120)
	_check(player.state == IDLE and player.label.text == "IDLE", "landing without a key goes to idle")

	Input.action_press("ui_right")
	await _ticks(10)
	var states := []
	await _tap("ui_accept")
	for i in 150:
		states.append(player.state)
		await physics_frame
	Input.action_release("ui_right")
	_check(states[0] == JUMP and states[-1] == WALK, "a jump while walking lands in walk, got %s to %s" % [states[0], states[-1]])
	_check(not states.has(IDLE), "landing with a key held goes straight to walk, never through idle")
	await _ticks(5)
	_check(player.state == IDLE, "letting go after the landing goes back to idle")

	_check(await _random_run(), "the label names the state on every tick of a random run")

	var camera: Camera2D = player.get_node("Camera2D")
	var half := Vector2(640.0, 360.0) / camera.zoom
	player.position = Vector2(1990.0, 24.0)
	Input.action_press("ui_right")
	await _ticks(120)
	Input.action_release("ui_right")
	var seen := camera.get_screen_center_position()
	_check(player.position.x <= 2016.5, "the right wall stops the player, got %.1f" % player.position.x)
	_check(seen.x + half.x <= 2112.5 and seen.y + half.y <= 320.5, "the picture stops at the right wall and the ground, it reaches %s" % (seen + half))

	player.position = Vector2(-1990.0, 24.0)
	Input.action_press("ui_left")
	await _ticks(120)
	Input.action_release("ui_left")
	seen = camera.get_screen_center_position()
	_check(player.position.x >= -2016.5, "the left wall stops the player, got %.1f" % player.position.x)
	_check(seen.x - half.x >= -2112.5, "the picture stops at the left wall, it reaches %.1f" % (seen.x - half.x))

	player.position = Vector2(0.0, -1300.0)
	await _ticks(18)
	seen = camera.get_screen_center_position()
	_check(player.position.y < -1200.0 and seen.y - half.y >= -1344.5, "the picture stops at the top of the backdrop, it reaches %.1f with the player at %.1f" % [seen.y - half.y, player.position.y])

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _random_run() -> bool:
	var random := RandomNumberGenerator.new()
	random.seed = 4
	var seen := {}
	for step in 80:
		for action: String in ["ui_left", "ui_right"]:
			Input.action_release(action)
		match random.randi_range(0, 2):
			1:
				Input.action_press("ui_left")
			2:
				Input.action_press("ui_right")
		if random.randf() < 0.5:
			Input.action_press("ui_accept")
		await physics_frame
		Input.action_release("ui_accept")
		for i in random.randi_range(5, 25):
			seen[player.state] = true
			if player.label.text != NAMES[player.state]:
				return false
			await physics_frame
	for action: String in ["ui_left", "ui_right"]:
		Input.action_release(action)
	return seen.size() == 3

func _ticks(count: int) -> void:
	for i in count:
		await physics_frame

func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame

func _until_floor(limit: int) -> void:
	for i in limit:
		await physics_frame
		if player.is_on_floor() and player.state != JUMP:
			return

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)

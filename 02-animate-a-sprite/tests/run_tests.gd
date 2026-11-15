extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

var failures := 0

func _init() -> void:
	await process_frame
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var player: CharacterBody2D = main.get_node("Player")
	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	await physics_frame

	# the sprite sheet and the two animations in the SpriteFrames
	var frames := sprite.sprite_frames
	_check(frames.has_animation("idle") and frames.has_animation("walk"), "the SpriteFrames has an idle and a walk animation")
	_check(frames.get_frame_count("walk") == 4, "walk has four frames, got %d" % frames.get_frame_count("walk"))
	_check(frames.get_frame_count("idle") == 4, "idle has four frames, got %d" % frames.get_frame_count("idle"))
	_check(is_equal_approx(frames.get_animation_speed("walk"), 10.0) and frames.get_animation_loop("walk"), "walk runs at 10 FPS and loops")
	_check(is_equal_approx(frames.get_animation_speed("idle"), 3.0) and frames.get_animation_loop("idle"), "idle runs at 3 FPS and loops, got %s FPS" % frames.get_animation_speed("idle"))
	var seen: Array[Rect2] = []
	for name: String in ["walk", "idle"]:
		for index in frames.get_frame_count(name):
			var piece := frames.get_frame_texture(name, index) as AtlasTexture
			_check(piece != null and piece.atlas.resource_path == "res://art/walk.png", "%s frame %d is a piece of the sprite sheet" % [name, index])
			if piece != null:
				_check(piece.region.size == Vector2(64, 88) and Rect2(Vector2.ZERO, piece.atlas.get_size()).encloses(piece.region), "%s frame %d lies inside the sheet" % [name, index])
				_check(not seen.has(piece.region), "%s frame %d is a cell of its own" % [name, index])
				seen.append(piece.region)

	# standing: idle
	await _hold([], 30)
	_check(sprite.animation == &"idle" and sprite.is_playing(), "it stands idle when nothing is pressed, got %s" % sprite.animation)
	var idle_frames := {sprite.frame: true}
	sprite.frame_changed.connect(func() -> void: idle_frames[sprite.frame] = true)
	await create_timer(1.7).timeout
	_check(idle_frames.size() == 4, "idle plays all four of its frames, got %d" % idle_frames.size())

	# walking right: walk, not flipped, the legs step through every frame although play("walk") is called sixty times a second
	var visited := {}
	var start := player.position.x
	var steps := func() -> void: visited[sprite.frame] = true
	sprite.frame_changed.connect(steps)
	Input.action_press("ui_right")
	await create_timer(1.0).timeout
	_check(sprite.animation == &"walk", "it plays walk while a key is held, got %s" % sprite.animation)
	_check(not sprite.flip_h, "walking right is not flipped")
	_check(player.position.x - start > 100.0, "it walked right, got %.1f" % (player.position.x - start))
	_check(visited.size() == 4, "play(\"walk\") on every tick does not restart it: %d of 4 frames were shown" % visited.size())
	Input.action_release("ui_right")
	sprite.frame_changed.disconnect(steps)

	# letting go: idle again, still facing right
	await _hold([], 10)
	_check(sprite.animation == &"idle" and not sprite.flip_h, "it stands idle again, facing right")

	# walking left: the same walk, flipped
	var before := player.position.x
	await _hold(["ui_left"], 40)
	_check(sprite.animation == &"walk" and sprite.flip_h, "walking left plays walk with flip_h")
	_check(player.position.x < before - 50.0, "it walked left, got %.1f" % (player.position.x - before))
	await _hold([], 10)
	_check(sprite.animation == &"idle" and sprite.flip_h, "it stands idle facing left")

	# no second animation: flipping the same frames mirrors them
	_check(frames.get_animation_names().size() == 2, "the SpriteFrames holds only idle and walk")

	# the wall stops it, the legs may keep stepping
	player.position = Vector2(750.0, 0.0)
	await _hold(["ui_right"], 60)
	_check(player.position.x <= 765.0 and player.position.x > 752.0, "the wall stops it at its face, got %.1f" % player.position.x)

	# the camera stops at the room's walls: the picture never shows outside the room
	var camera: Camera2D = player.get_node("Camera2D")
	var half := Vector2(640.0, 360.0) / camera.zoom
	player.position = Vector2(740.0, 390.0)
	await _hold([], 120)
	var seen_end := camera.get_screen_center_position() + half
	_check(seen_end.x <= 812.5 and seen_end.y <= 512.5, "the picture stops at the walls, it reaches %s" % seen_end)
	player.position = Vector2(-740.0, -390.0)
	await _hold([], 120)
	var seen_start := camera.get_screen_center_position() - half
	_check(seen_start.x >= -812.5 and seen_start.y >= -512.5, "the picture stops at the walls, it starts at %s" % seen_start)

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _hold(actions: Array, ticks: int) -> void:
	for action: String in actions:
		Input.action_press(action)
	for i in ticks:
		await physics_frame
	for action: String in actions:
		Input.action_release(action)

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)

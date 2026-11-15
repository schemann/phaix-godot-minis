extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

var failures := 0

func _init() -> void:
	await process_frame
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	var player := main.get_node("Player") as CharacterBody2D
	var enemy := main.get_node("Enemy") as CharacterBody2D
	_check(enemy.target == player, "the Enemy's Target slot holds the Player")

	# the knight and the goblin are AnimatedSprite2D with idle and walk (mini 02's animation)
	for body: CharacterBody2D in [player, enemy]:
		var sprite := body.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		_check(sprite != null and sprite.sprite_frames.has_animation("idle") and sprite.sprite_frames.has_animation("walk"), "%s is an AnimatedSprite2D with idle and walk" % body.name)
	_check(player.speed > enemy.speed, "the knight is faster than the goblin: %.0f against %.0f" % [player.speed, enemy.speed])

	# direction_to has length one, so the goblin walks at `speed` whether the knight is far away or close
	for i in 20:
		await physics_frame
	await process_frame
	_check(enemy.get_real_velocity().length() > 50.0 and enemy.get_node("AnimatedSprite2D").animation == &"walk", "while he crosses the room he really moves (%.0f px/s) and plays walk" % enemy.get_real_velocity().length())
	var fastest := 0.0
	var slowest := 1.0e9
	var far_seen := false
	var near_seen := false
	var frames := 0
	while frames < 1500 and enemy.global_position.distance_to(player.global_position) > 70.0:
		await physics_frame
		frames += 1
		var distance := enemy.global_position.distance_to(player.global_position)
		if distance > 70.0:
			fastest = maxf(fastest, enemy.velocity.length())
			slowest = minf(slowest, enemy.velocity.length())
			far_seen = far_seen or distance > 400.0
			near_seen = near_seen or distance < 100.0
	_check(far_seen and near_seen, "the run covers distances from over 400 to under 100 pixels")
	_check(absf(fastest - enemy.speed) < 0.01 and absf(slowest - enemy.speed) < 0.01, "the speed is %.0f at every distance: %.3f to %.3f" % [enemy.speed, slowest, fastest])

	# the goblin arrives and stands next to the knight: his shape stops at the knight's, and he does not jitter
	for i in 240:
		await physics_frame
	var before := enemy.global_position
	var gap := before.distance_to(player.global_position)
	for i in 120:
		await physics_frame
	var moved := enemy.global_position.distance_to(before)
	_check(gap < 80.0 and gap > 40.0, "he stands next to the knight, %.1f pixels between the two centres" % gap)
	_check(moved < 8.0, "and he stays where he is: he slides %.1f pixels along the knight in two seconds, no more (Floating motion mode: a slide along the knight's side, until he faces its middle)" % moved)
	await process_frame
	_check(enemy.velocity.length() > 50.0 and enemy.get_real_velocity().length() < 8.0, "he is asked to walk (velocity %.0f px/s) and the knight holds him (he really moves %.1f px/s)" % [enemy.velocity.length(), enemy.get_real_velocity().length()])
	_check(enemy.get_node("AnimatedSprite2D").animation == &"idle", "so his animation is idle: the sprite script reads the movement that happened (get_real_velocity), not the velocity he asks for")

	# the knight walks away and the goblin follows: the way is recomputed every physics frame
	player.position = Vector2(200.0, -60.0)
	await physics_frame
	var start := enemy.global_position.distance_to(player.global_position)
	for i in 120:
		await physics_frame
	_check(enemy.global_position.distance_to(player.global_position) < start - 100.0, "when the knight moves, the goblin follows him")

	# the knight against the wall of the room: he asks for 90 px/s, the wall holds him, and his animation is idle; let go and walk the other way, it is walk again
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	player.position = Vector2(280.0, 0.0)
	Input.action_press("ui_right")
	for i in 30:
		await physics_frame
	await process_frame
	_check(player.velocity.length() > 80.0 and player.get_real_velocity().length() < 8.0, "the knight pushes at the wall (velocity %.0f px/s) and the wall holds him (he really moves %.1f px/s)" % [player.velocity.length(), player.get_real_velocity().length()])
	_check(player.get_node("AnimatedSprite2D").animation == &"idle", "so the knight's animation is idle, and he is turned the way he pushes (flip_h %s)" % player.get_node("AnimatedSprite2D").flip_h)
	Input.action_release("ui_right")
	Input.action_press("ui_left")
	for i in 20:
		await physics_frame
	await process_frame
	_check(player.get_real_velocity().length() > 80.0 and player.get_node("AnimatedSprite2D").animation == &"walk", "let go and walking left: he really moves (%.0f px/s) and plays walk" % player.get_real_velocity().length())
	Input.action_release("ui_left")

	# a wall in between: he walks straight at the knight and does not look for a way around it
	var wall: Node = (load("res://short/wall.tscn") as PackedScene).instantiate()
	main.free()
	root.add_child(wall)
	await physics_frame
	var blocked := wall.get_node("Enemy") as CharacterBody2D
	var knight := wall.get_node("Player") as CharacterBody2D
	var free_wall := wall.get_node("Room/Walls/ShapeFree") as CollisionShape2D
	var wall_x := free_wall.global_position.x - (free_wall.shape as RectangleShape2D).size.x / 2.0
	for i in 600:
		await physics_frame
	var stuck := blocked.global_position
	for i in 180:
		await physics_frame
	_check(blocked.global_position.x + 22.0 <= wall_x + 0.5 and blocked.global_position.distance_to(stuck) < 0.01, "he stands at the wall, his centre at x %.1f, the wall's edge at %.1f, and does not move on" % [blocked.global_position.x, wall_x])
	_check(knight.global_position.x > wall_x and absf(blocked.global_position.y - knight.global_position.y) < 1.0, "the knight stands on the other side at the same height")

	# the Short's bug scene: the vector to the target is the velocity, so the speed is the distance (times 0.25): fast far away, slow close up, and he never quite arrives
	wall.free()
	var bug: Node = (load("res://short/bug.tscn") as PackedScene).instantiate()
	root.add_child(bug)
	await physics_frame
	var rusher := bug.get_node("Enemy") as CharacterBody2D
	var target := bug.get_node("Player") as CharacterBody2D
	for i in 10:
		await physics_frame
	_check(rusher.velocity == Vector2.ZERO, "the bug enemy waits until the take starts him")
	bug.start()
	await physics_frame
	var far_speed := rusher.velocity.length()
	for i in 300:
		await physics_frame
	var near_speed := rusher.velocity.length()
	var left := rusher.global_position.distance_to(target.global_position)
	_check(far_speed > 62.0 and near_speed < far_speed * 0.5, "the bug: fast far away (%.0f px/s, faster than the fix's 60) and slower after five seconds (%.0f px/s), as the distance shrinks" % [far_speed, near_speed])
	_check(left > 20.0, "and after five seconds he has not arrived, %.0f pixels from the knight" % left)
	bug.reset_far()
	await physics_frame
	await physics_frame
	_check(absf(rusher.velocity.length() - 90.3) < 1.5, "in the frame's corner (361 pixels) the same code walks at %.1f px/s" % rusher.velocity.length())
	bug.reset_mid()
	await physics_frame
	await physics_frame
	_check(absf(rusher.velocity.length() - 43.2) < 1.0, "in between (173 pixels) the same code walks at %.1f px/s" % rusher.velocity.length())
	bug.reset_near()
	await physics_frame
	await physics_frame
	_check(absf(rusher.velocity.length() - 27.5) < 1.0, "close up (110 pixels) the same code walks at %.1f px/s" % rusher.velocity.length())
	for i in 400:
		await physics_frame
	var crawled := rusher.global_position - target.global_position
	_check(absf(crawled.x) > 40.0 and absf(crawled.x) < 70.0 and absf(crawled.y) < 12.0, "and he crawls in from the side and stands beside the knight, %.0f px across and %.0f px up or down from him, not over his head" % [crawled.x, crawled.y])
	_check(target.global_position.distance_to(Vector2(100.0, 175.0)) < 0.5, "the knight has not moved: the crawling goblin does not push him (he is at %.1f, %.1f)" % [target.global_position.x, target.global_position.y])
	_check(absf(rusher.velocity.length() - 13.5) < 1.5, "and the readout of the bug scene reads %.1f there, a quarter of the 54 pixels between the two centres: Floating like the video's enemy, so the velocity stays what the code asks for while the knight's shape holds his body" % rusher.velocity.length())
	bug.free()

	# the Short's fix scene: the project's own enemy, direction_to has length one, so 60 px/s from the first step to the last, and 120 once speed is tuned
	var fix: Node = (load("res://short/fix.tscn") as PackedScene).instantiate()
	root.add_child(fix)
	await physics_frame
	var walker := fix.get_node("Enemy") as CharacterBody2D
	fix.start()
	var lowest := 1.0e9
	var highest := 0.0
	for i in 240:
		await physics_frame
		lowest = minf(lowest, walker.velocity.length())
		highest = maxf(highest, walker.velocity.length())
	_check(absf(lowest - 60.0) < 0.01 and absf(highest - 60.0) < 0.01, "the fix: %.2f to %.2f px/s during four seconds of walking" % [lowest, highest])
	fix.reset_far()
	fix.tune()
	for i in 10:
		await physics_frame
	_check(absf(walker.velocity.length() - 120.0) < 0.01, "speed is an export variable: tuned to 120 the same enemy walks at %.2f px/s" % walker.velocity.length())
	# the end of the take: he walks in from the left at the knight's height and stands BESIDE him (not over his head, the plume across his face), idle
	for i in 300:
		await physics_frame
	await process_frame
	var beside := walker.global_position - (fix.get_node("Player") as CharacterBody2D).global_position
	_check(absf(beside.x) > 40.0 and absf(beside.x) < 70.0 and absf(beside.y) < 20.0, "the fix: he ends beside the knight, %.0f px across and %.0f px up or down from him, not over his head" % [beside.x, beside.y])
	_check(walker.get_node("AnimatedSprite2D").animation == &"idle", "and he plays idle there")

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)
	else:
		print("ok: " + text)

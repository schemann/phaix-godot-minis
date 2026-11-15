extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.
## A headless run has no real cursor, so the aim is tested with mouse events that are pushed in, and the shot with look_at() before shoot().

var failures := 0

func _init() -> void:
	await process_frame
	_check(InputMap.has_action("shoot"), "the shoot action exists")
	var events := InputMap.action_get_events("shoot")
	_check(events.size() == 1 and events[0] is InputEventMouseButton and (events[0] as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT, "shoot is the left mouse button")

	# The gun follows the mouse, and one click fires one bullet, however long the button is held.
	var main := await _fresh_main()
	var gun: Node2D = main.get_node("Player/Gun")

	# The knight is an AnimatedSprite2D with idle and walk (mini 02's animation); this player never moves, so it stands and plays idle.
	var knight := main.get_node("Player/AnimatedSprite2D") as AnimatedSprite2D
	_check(knight != null and knight.sprite_frames.has_animation("idle") and knight.sprite_frames.has_animation("walk") and knight.animation == "idle" and knight.is_playing(), "the knight is an AnimatedSprite2D with idle and walk, and the standing knight plays idle")

	var before := gun.rotation
	_mouse_to(Vector2(1000.0, 500.0))
	await _frames(3)
	_check(absf(gun.rotation - before) > 0.3, "the gun turned to the mouse, got %.2f from %.2f" % [gun.rotation, before])
	_check(absf(gun.get_angle_to(gun.get_global_mouse_position())) < 0.01, "the gun points at the mouse, off by %.3f" % gun.get_angle_to(gun.get_global_mouse_position()))
	_click(true)
	await _frames(6)
	_check(_bullets(main).size() == 1, "one click fires one bullet, got %d" % _bullets(main).size())
	_click(false)
	await _frames(2)
	_click(true)
	await _frames(2)
	_check(_bullets(main).size() == 2, "a second click fires a second bullet, got %d" % _bullets(main).size())
	_click(false)

	# The bullet starts at the muzzle, points the way the gun points and is a child of the scene, not of the gun.
	main = await _fresh_main()
	gun = main.get_node("Player/Gun")
	var muzzle: Marker2D = gun.get_node("Muzzle")
	gun.look_at(Vector2(300.0, -200.0))
	gun.shoot()
	var bullet: Area2D = _bullets(main)[0]
	var start := bullet.global_position
	var angle := bullet.global_rotation
	var game_pixel: Vector2 = (bullet.get_node("Sprite2D") as Sprite2D).global_scale
	_check(game_pixel.is_equal_approx(Vector2.ONE), "the bullet shows its picture at its own pixel size like the knight and the tiles, got scale %s" % game_pixel)
	_check(start.distance_to(muzzle.global_position) < 0.01, "the bullet starts at the muzzle")
	_check(absf(angle_difference(angle, (Vector2(300.0, -200.0) - gun.global_position).angle())) < 0.01, "the bullet points at the target, got %.2f" % angle)
	_check(bullet.get_parent() == main and bullet.get_parent() != gun, "the bullet is a child of the scene")

	# It flies along its own right at speed pixels a second, and it does not follow the gun when the gun turns.
	await _frames(3)
	_mouse_to(Vector2(-1000.0, 600.0))
	var tick_start := bullet.global_position
	await _ticks(10)
	var covered := bullet.global_position.distance_to(tick_start)
	var expected: float = float(bullet.get("speed")) * 10.0 / Engine.physics_ticks_per_second
	_check(absf(covered - expected) < 15.0, "ten ticks cover %.0f px, got %.1f" % [expected, covered])
	_check(absf(angle_difference(bullet.global_rotation, angle)) < 0.001, "the bullet keeps its way, got %.3f" % bullet.global_rotation)
	_check(absf(angle_difference(gun.global_rotation, angle)) > 0.5, "the gun turned away meanwhile, got %.2f" % gun.global_rotation)

	# A hit: the target goes down and the bullet is gone with it.
	main = await _fresh_main()
	gun = main.get_node("Player/Gun")
	var target: Node2D = main.get_node("Targets/Target1")
	gun.look_at(target.global_position)
	gun.shoot()
	bullet = _bullets(main)[0]
	await _ticks(60)
	_check(not is_instance_valid(target), "the target went down")
	_check(not is_instance_valid(bullet), "the bullet is gone after the hit")
	_check(main.get_node("Targets").get_child_count() == 5, "the other five targets stand, got %d" % main.get_node("Targets").get_child_count())

	# A miss: the bullet hits the wall and frees itself, no target is touched.
	main = await _fresh_main()
	gun = main.get_node("Player/Gun")
	gun.look_at(Vector2(100.0, -100.0))
	gun.shoot()
	bullet = _bullets(main)[0]
	await _ticks(60)
	_check(not is_instance_valid(bullet), "a bullet that hits the wall frees itself")
	_check(main.get_node("Targets").get_child_count() == 6, "all six targets still stand, got %d" % main.get_node("Targets").get_child_count())

	# Collision follows what the viewer sees: the shape of every goblin is the box of its visible pixels, and a bullet that overlaps that box by 2 px knocks it down while
	# one that passes it 2 px clear does not, on every side.
	var lone_target: Node2D = (load("res://target.tscn") as PackedScene).instantiate()
	var visible_box := _visible_box(lone_target)
	_check(visible_box.size == Vector2(40.0, 40.0), "the goblin's visible pixels are a 40 x 40 box, got %s" % visible_box)
	_check(_shape_box(lone_target) == visible_box, "the target's shape is the box of its visible pixels %s, got %s" % [visible_box, _shape_box(lone_target)])
	lone_target.free()
	main = await _fresh_main()
	for each in main.get_node("Targets").get_children():
		_check(_shape_box(each) == visible_box, "%s's shape is the box of its visible pixels %s, got %s" % [each.name, visible_box, _shape_box(each)])
	var probe: Area2D = (load("res://bullet.tscn") as PackedScene).instantiate()
	var bullet_half: float = ((probe.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.y / 2.0
	probe.free()
	for way: Vector2 in [Vector2.RIGHT, Vector2.DOWN]:
		var box_half := visible_box.size.y / 2.0 if way == Vector2.RIGHT else visible_box.size.x / 2.0
		for sign: float in [1.0, -1.0]:
			var reach := (box_half + bullet_half) * sign
			var side := ("below" if sign > 0.0 else "above") if way == Vector2.RIGHT else ("left of" if sign > 0.0 else "right of")
			_check(await _graze(way, reach - 2.0 * sign), "a bullet that overlaps the goblin's visible edge by 2 px, passing %s it, knocks it down" % side)
			_check(not await _graze(way, reach + 2.0 * sign), "a bullet that passes the goblin's visible edge 2 px clear, %s it, leaves it standing" % side)

	# The camera stops at the walls: whoever stands where, the picture never reaches outside the room.
	main = await _fresh_main()
	var player: Node2D = main.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	player.position = Vector2(700.0, 390.0)
	await _ticks(10)
	var seen_end := camera.get_screen_center_position() + Vector2(640.0, 360.0) / camera.zoom
	_check(seen_end.x <= 364.5 and seen_end.y <= 192.5, "the picture stops at the walls, it reaches %s" % seen_end)
	player.position = Vector2(-700.0, -390.0)
	await _ticks(10)
	var seen_start := camera.get_screen_center_position() - Vector2(640.0, 360.0) / camera.zoom
	_check(seen_start.x >= -364.5 and seen_start.y >= -192.5, "the picture stops at the walls, it starts at %s" % seen_start)

	# In open space nothing stops it: it frees itself after a time.
	current_scene.queue_free()
	await _frames(2)
	var lone: Area2D = (load("res://bullet.tscn") as PackedScene).instantiate()
	root.add_child(lone)
	await create_timer(1.0).timeout
	_check(is_instance_valid(lone), "after one second the bullet still flies")
	await create_timer(0.8).timeout
	_check(not is_instance_valid(lone), "after one and a half seconds the bullet frees itself")

	# The mistake of the Short: a bullet added to the gun turns with the gun.
	var wrong := (load("res://short/wrong.tscn") as PackedScene).instantiate()
	root.add_child(wrong)
	current_scene = wrong
	await _frames(3)
	var wrong_gun: Node2D = wrong.get_node("Player/Gun")
	_mouse_to(Vector2(1000.0, 300.0))
	await _frames(3)
	wrong_gun.shoot()
	var stuck: Node2D = wrong_gun.get_child(wrong_gun.get_child_count() - 1)
	_check(stuck.get_parent() == wrong_gun, "in the mistake scene the bullet is a child of the gun")
	var turned_from := wrong_gun.global_rotation
	_mouse_to(Vector2(-1000.0, 600.0))
	await _frames(3)
	_check(absf(angle_difference(wrong_gun.global_rotation, turned_from)) > 0.5, "the gun turned")
	_check(absf(angle_difference(stuck.global_rotation, wrong_gun.global_rotation)) < 0.01, "the bullet on the gun turned with it")
	_check((stuck.get_node("Sprite2D") as Sprite2D).global_scale.is_equal_approx(game_pixel), "the Short's bullet on the gun shows the game's pixel size %s, got %s" % [game_pixel, (stuck.get_node("Sprite2D") as Sprite2D).global_scale])
	wrong.queue_free()
	await _frames(2)

	# The fix of the Short: the same scene with the bullet added to the scene flies on when the gun turns.
	var right := (load("res://short/right.tscn") as PackedScene).instantiate()
	root.add_child(right)
	current_scene = right
	await _frames(3)
	var right_gun: Node2D = right.get_node("Player/Gun")
	_mouse_to(Vector2(1000.0, 300.0))
	await _frames(3)
	right_gun.shoot()
	var flying: Node2D = _bullets(right)[0]
	var first_way := flying.global_rotation
	_mouse_to(Vector2(-1000.0, 600.0))
	await _frames(3)
	_check(flying.get_parent() == right, "in the fixed scene the bullet is a child of the scene")
	_check(absf(angle_difference(right_gun.global_rotation, first_way)) > 0.5, "the gun turned in the fixed scene too")
	_check(absf(angle_difference(flying.global_rotation, first_way)) < 0.001, "the bullet on the scene keeps its way")
	_check((flying.get_node("Sprite2D") as Sprite2D).global_scale.is_equal_approx(game_pixel), "the Short's bullet on the scene shows the game's pixel size %s, got %s" % [game_pixel, (flying.get_node("Sprite2D") as Sprite2D).global_scale])
	right.queue_free()

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

## A new Main scene, the one before it is gone. It is the current scene, as it is when the game runs.
func _fresh_main() -> Node:
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(3)
	return main

## The box of the goblin's visible pixels in the target's own coordinates: where its Sprite2D puts the part of the picture that is not transparent.
func _visible_box(target: Node2D) -> Rect2:
	var sprite: Sprite2D = target.get_node("Sprite2D")
	var used := Rect2(sprite.texture.get_image().get_used_rect())
	return Rect2(sprite.position + sprite.offset - sprite.texture.get_size() / 2.0 + used.position, used.size)

## The box of the target's rectangle shape in the target's own coordinates.
func _shape_box(target: Node2D) -> Rect2:
	var shape_node: CollisionShape2D = target.get_node("CollisionShape2D")
	var size: Vector2 = (shape_node.shape as RectangleShape2D).size
	return Rect2(shape_node.position - size / 2.0, size)

## Flies one bullet along `way` past a lone target, `lateral` px beside the centre of its visible box, and tells whether the target went down.
func _graze(way: Vector2, lateral: float) -> bool:
	var arena := Node2D.new()
	arena.position = Vector2(4000.0, 4000.0)    # far from the room's own targets and walls
	root.add_child(arena)
	var target: Node2D = (load("res://target.tscn") as PackedScene).instantiate()
	arena.add_child(target)
	var bullet: Area2D = (load("res://bullet.tscn") as PackedScene).instantiate()
	arena.add_child(bullet)
	bullet.position = _visible_box(target).get_center() - way * 120.0 + Vector2(-way.y, way.x) * lateral
	bullet.rotation = way.angle()
	await _ticks(45)
	var down := not is_instance_valid(target)
	arena.queue_free()
	await _frames(2)
	return down

func _bullets(main: Node) -> Array[Node]:
	return main.get_children().filter(func(child: Node) -> bool: return child is Area2D)

func _mouse_to(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)

func _click(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)

func _frames(count: int) -> void:
	for i in count:
		await process_frame

func _ticks(count: int) -> void:
	for i in count:
		await physics_frame

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)

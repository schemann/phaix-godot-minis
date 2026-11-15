extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

var failures := 0

func _init() -> void:
	await process_frame
	# class_name registers Item as a type: it is a global class that extends Resource, which is why it is on the list when a new resource is made
	var item_class := {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if entry["class"] == &"Item":
			item_class = entry
	_check(not item_class.is_empty() and item_class["base"] == &"Resource", "Item is a global class that extends Resource")

	# the three items are files, and each one holds its title, its icon and its uses
	var potion := load("res://potion.tres") as Item
	var sword := load("res://sword.tres") as Item
	var staff := load("res://staff.tres") as Item
	for item: Item in [potion, sword, staff]:
		_check(item != null and item.title != "" and item.icon != null and item.uses > 0, "%s is an Item with a title, an icon and uses" % item.resource_path)
	_check(potion.title == "Health Potion" and potion.uses == 3, "the potion file holds Health Potion and 3 uses")

	# one scene shows all three: the Pickup does not know a single item, it shows the one in its slot
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	var scenes := {}
	for pickup_name: String in ["Pickup", "Pickup2", "Pickup3"]:
		var pickup := main.get_node(pickup_name)
		scenes[pickup.scene_file_path] = true
		var item := pickup.item as Item
		_check((pickup.get_node("Icon") as Sprite2D).texture == item.icon, "%s shows the icon of %s" % [pickup_name, item.resource_path])
		_check((pickup.get_node("Label") as Label).text == "%s x%d" % [item.title, item.uses], "%s reads \"%s\"" % [pickup_name, (pickup.get_node("Label") as Label).text])
	_check(scenes.size() == 1 and scenes.keys()[0] == "res://pickup.tscn", "the three pickups are instances of the one scene pickup.tscn")
	_check(main.get_node("Pickup").item != main.get_node("Pickup2").item and main.get_node("Pickup2").item != main.get_node("Pickup3").item, "and each holds another item file")

	# the knight is an AnimatedSprite2D with idle and walk (mini 02's animation)
	var knight := main.get_node("Player/AnimatedSprite2D") as AnimatedSprite2D
	_check(knight != null and knight.sprite_frames.has_animation("idle") and knight.sprite_frames.has_animation("walk"), "the knight is an AnimatedSprite2D with idle and walk")

	# Y sort: Main sorts its children by the y of their origin and a Node2D has no y_sort_origin, so the knight and every pickup have the origin at their feet and the one whose feet are lower is drawn in front
	var player := main.get_node("Player") as CharacterBody2D
	var frame_height := knight.sprite_frames.get_frame_texture("idle", 0).get_height()
	var shape := player.get_node("CollisionShape2D") as CollisionShape2D
	_check(main.y_sort_enabled and is_equal_approx(knight.position.y + frame_height / 2.0, 0.0), "Main sorts by y and the bottom of the knight's picture is his origin")
	_check(is_equal_approx(shape.position.y + (shape.shape as RectangleShape2D).size.y / 2.0, 0.0), "the bottom of the knight's collision shape is his origin too")
	for pickup_name: String in ["Pickup", "Pickup2", "Pickup3"]:
		var icon := main.get_node(pickup_name + "/Icon") as Sprite2D
		_check(is_equal_approx(icon.position.y + icon.texture.get_height() / 2.0, 0.0), "the bottom of the %s picture is its origin, the same base line as the knight's" % pickup_name)

	# a fourth item is a fourth file: no new scene, no new code
	var fourth := Item.new()
	fourth.title = "Skull"
	fourth.icon = potion.icon
	fourth.uses = 1
	var extra := (load("res://pickup.tscn") as PackedScene).instantiate()
	extra.item = fourth
	main.add_child(extra)
	await process_frame
	_check((extra.get_node("Label") as Label).text == "Skull x1", "a fourth Item in the slot shows without any other change")

	# the fields of an Item are typed, each with its own editor in the Inspector: a String, a Texture2D and an int (a Dictionary holds anything under any key)
	var fields := {}
	for entry: Dictionary in Item.new().get_property_list():
		if entry["name"] in ["title", "icon", "uses"] and (int(entry["usage"]) & PROPERTY_USAGE_EDITOR) != 0 and (int(entry["usage"]) & PROPERTY_USAGE_STORAGE) != 0:
			fields[entry["name"]] = entry
	_check(fields.size() == 3 and fields["title"]["type"] == TYPE_STRING and fields["uses"]["type"] == TYPE_INT and fields["icon"]["type"] == TYPE_OBJECT and fields["icon"]["hint_string"] == "Texture2D", "title, icon and uses are typed fields (String, Texture2D, int), shown in the Inspector and saved in the file")

	# the exported slot is filled when _ready runs: the Pickup reads it there (Item is read in _ready, not in _init)
	var early := (load("res://pickup.tscn") as PackedScene).instantiate()
	_check(early.item == null, "before the Pickup is in the tree its slot is empty: only _ready sees the value of the Inspector")
	early.free()

	# the Short's two scenes: three pickups that share ONE Item file lose their uses together, and with duplicate() in _ready each loses its own
	main.free()
	var shared: Node = (load("res://short/shared.tscn") as PackedScene).instantiate()
	root.add_child(shared)
	await physics_frame
	var a := shared.get_node("PickupA")
	var b := shared.get_node("PickupB")
	var c := shared.get_node("PickupC")
	_check(a.item == b.item and b.item == c.item and a.item.resource_path == "res://potion.tres", "the bug scene: all three pickups hold the very same Item, res://potion.tres")
	var before: int = a.item.uses
	a.body_entered.emit(shared.get_node("Player"))
	await process_frame
	await process_frame
	_check(before == 3 and a.item.uses == 2 and (b.get_node("Hud/Label") as Label).text == "Health Potion\nx2" and (c.get_node("Hud/Label") as Label).text == "Health Potion\nx2", "using ONE pickup drops the label of all three: x3 to x2")
	(load("res://potion.tres") as Item).uses = 3 # the bug changed the one shared Item in memory: put it back for the next scene
	shared.free()
	var own: Node = (load("res://short/own.tscn") as PackedScene).instantiate()
	root.add_child(own)
	await physics_frame
	var oa := own.get_node("PickupA")
	var ob := own.get_node("PickupB")
	_check(oa.item != ob.item and oa.item.resource_path == "" and (oa.get_node("Hud/File") as Label).text == "own copy", "the fix scene: every pickup holds its own copy of the Item (duplicate has no file)")
	oa.body_entered.emit(own.get_node("Player"))
	await process_frame
	await process_frame
	_check((oa.get_node("Hud/Label") as Label).text == "Health Potion\nx2" and (ob.get_node("Hud/Label") as Label).text == "Health Potion\nx3" and (load("res://potion.tres") as Item).uses == 3, "the fix: using one pickup drops only its own label, the other two and the file stay at 3")

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)
	else:
		print("ok: " + text)

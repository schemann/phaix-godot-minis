extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

var failures := 0

func _init() -> void:
	await process_frame
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame

	var banner := main.get_node("Banner") as Sprite2D
	_check(main.has_node("Wall") and not main.has_node("Floor"), "the picture behind the banner is the node Wall")
	_check(banner.position == Vector2(640, 472), "the banner hangs on the wall tile in column 2, second row, got %s" % str(banner.position))
	var material := banner.material as ShaderMaterial
	_check(material != null, "the Banner has a ShaderMaterial")
	_check(material.shader.resource_path == "res://wave.gdshader", "the material runs wave.gdshader, got %s" % material.shader.resource_path)

	var shader := material.shader
	_check(shader.get_mode() == Shader.MODE_CANVAS_ITEM, "the shader is a canvas_item shader")
	_check(shader.code.contains("sin(") and shader.code.contains("TIME"), "the wave is a sin of TIME")
	_check(shader.code.contains("UV.y"), "the wave is multiplied by UV.y, so the top edge stays and the bottom swings")
	var uniforms := {}
	for entry: Dictionary in shader.get_shader_uniform_list():
		uniforms[entry.name] = entry
	_check(uniforms.keys() == ["speed", "strength", "tint"], "the shader has the uniforms speed, strength, tint, got %s" % str(uniforms.keys()))
	_check(uniforms["speed"].type == TYPE_FLOAT, "speed is a float")
	_check(uniforms["strength"].type == TYPE_FLOAT and uniforms["strength"].hint == PROPERTY_HINT_RANGE, "strength is a float with a range")
	_check(str(uniforms["strength"].hint_string).begins_with("0.0,0.1"), "strength goes from 0.0 to 0.1, got %s" % uniforms["strength"].hint_string)
	_check(uniforms["tint"].type == TYPE_COLOR, "tint is a colour")
	_check(FileAccess.get_file_as_string("res://wave.gdshader").strip_edges().split("\n").size() == 11, "the whole shader is eleven lines, the video says so")

	main.set("strength", 0.08)
	main.set("speed", 8.0)
	main.set("tint_html", "#4da6ff")
	_check(is_equal_approx(float(material.get_shader_parameter("strength")), 0.08), "strength changes without a code change")
	_check(is_equal_approx(float(material.get_shader_parameter("speed")), 8.0), "speed changes without a code change")
	_check((material.get_shader_parameter("tint") as Color).is_equal_approx(Color("#4da6ff")), "tint changes without a code change")

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)

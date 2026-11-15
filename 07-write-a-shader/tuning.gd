extends Node2D
## Not part of the lesson. A recording moves the three shader parameters from outside, the way the Inspector does.

@onready var _material := ($Banner as Sprite2D).material as ShaderMaterial

var speed := 3.0:
	set(value):
		speed = value
		_material.set_shader_parameter("speed", value)

var strength := 0.05:
	set(value):
		strength = value
		_material.set_shader_parameter("strength", value)

var tint_html := "#f28c28":
	set(value):
		tint_html = value
		_material.set_shader_parameter("tint", Color(value))

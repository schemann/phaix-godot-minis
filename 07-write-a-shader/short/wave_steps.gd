extends Node2D
## The Short's scene: the lesson's banner, built up as the voice says it. Each method is called by a `call` event of take S2 at the
## second of its line: the position in the texture (uv_view), a small number added to it (slide), the sine of TIME (swing_time), how wide
## (widen), the vertical position inside the sine (rows_in), the lesson's own shader (lesson_wave), the same shader on more sprites (every_sprite).
## Not part of the lesson. `speed`, `strength` and `tint_html` are set from outside like in tuning.gd.

const STEPS := preload("res://short/steps.gdshader")

@onready var _banner: Sprite2D = $Banner
@onready var _gizmo: Node2D = $Gizmo

var _lesson: ShaderMaterial ## wave.gdshader: the lesson's shader
var _steps := ShaderMaterial.new() ## steps.gdshader: its lines one at a time
var _tween: Tween

var speed := 3.0:
	set(value):
		speed = value
		_push()

var strength := 0.05:
	set(value):
		strength = value
		_push()

var tint_html := "#f28c28":
	set(value):
		tint_html = value
		_push()

func _ready() -> void:
	_lesson = _banner.material as ShaderMaterial
	_steps.shader = STEPS
	_push()

func _push() -> void:
	if _lesson == null:
		return
	_lesson.set_shader_parameter("speed", speed)
	_lesson.set_shader_parameter("strength", strength)
	_lesson.set_shader_parameter("tint", Color(tint_html))
	_steps.set_shader_parameter("speed", speed)
	_steps.set_shader_parameter("tint", Color(tint_html))

func _restart() -> Tween:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	return _tween

func _step(param: StringName, value: float) -> void:
	_steps.set_shader_parameter(param, value)

func _glide(tween: Tween, param: StringName, from: float, to: float, seconds: float, trans: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	tween.tween_method(func(value: float) -> void: _step(param, value), from, to, seconds).set_trans(trans).set_ease(Tween.EASE_IN_OUT)

func _swing_blend(share: float) -> void:
	_step(&"shift", lerpf(0.15, 0.0, share))
	_step(&"strength", lerpf(0.0, 0.1, share))

## UV is the position in the texture, from zero to one: UV as colour over the node's rectangle, and a probe that reads it.
func uv_view() -> void:
	_banner.material = _steps
	for param: StringName in [&"shift", &"strength", &"rows"]:
		_step(param, 0.0)
	_step(&"uv_view", 1.0)
	_gizmo.set("show_corners", true)
	_gizmo.set("probe", Vector2(0.5, 0.5))
	var tween := _restart()
	for stop: Array in [[Vector2(0.2, 0.75), 1.7], [Vector2(0.8, 0.3), 0.9], [Vector2(0.0, 0.0), 1.07], [Vector2(1.0, 1.0), 1.4]]:
		tween.tween_property(_gizmo, "probe", stop[0], stop[1]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## A small number added to UV: the picture slides sideways inside the node's rectangle.
func slide() -> void:
	_banner.material = _steps
	_step(&"uv_view", 0.0)
	_step(&"strength", 0.0)
	_step(&"rows", 0.0)
	_gizmo.set("show_corners", false)
	_gizmo.set("probe", Vector2(-1, -1))
	var tween := _restart()
	_glide(tween, &"shift", 0.0, 0.15, 1.3, Tween.TRANS_LINEAR)
	_glide(tween, &"shift", 0.15, 0.0, 2.4, Tween.TRANS_LINEAR)

## Make that number change: the sine of TIME swings the whole picture back and forth.
func swing_time() -> void:
	_banner.material = _steps
	_step(&"uv_view", 0.0)
	_step(&"rows", 0.0)
	_step(&"strength", 0.0)
	_step(&"shift", 0.15)
	_restart().tween_method(_swing_blend, 0.0, 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Times a uniform called strength: the swing is narrow, then wide.
func widen() -> void:
	_banner.material = _steps
	_step(&"rows", 0.0)
	_step(&"shift", 0.0)
	_step(&"strength", 0.04)
	_glide(_restart(), &"strength", 0.04, 0.1, 1.6)

## The vertical position inside the sine: the rows no longer swing together.
func rows_in() -> void:
	_banner.material = _steps
	_step(&"strength", 0.1)
	_step(&"rows", 0.0)
	var tween := _restart()
	tween.tween_interval(0.5)
	_glide(tween, &"rows", 0.0, 10.0, 1.4)

## The lesson's own shader, wave.gdshader.
func lesson_wave() -> void:
	if _tween != null:
		_tween.kill()
	_banner.material = _lesson

## The same shader on every sprite: two more sprites with wave.gdshader, all three a little smaller to stand in the Short's window.
func every_sprite() -> void:
	_gizmo.set("show_box", false)
	var extras: Array[Dictionary] = [{"x": -125.0, "tint": Color("#4da6ff")}, {"x": 125.0, "tint": Color("#66d17a")}]
	for extra: Dictionary in extras:
		var sprite := _banner.duplicate() as Sprite2D
		var material := ShaderMaterial.new()
		material.shader = _lesson.shader
		material.set_shader_parameter("speed", speed)
		material.set_shader_parameter("strength", strength)
		material.set_shader_parameter("tint", extra.tint)
		sprite.material = material
		sprite.scale = Vector2.ZERO
		sprite.position = _banner.position + Vector2(float(extra.x), 0)
		add_child(sprite)
		create_tween().tween_property(sprite, "scale", Vector2(0.7, 0.7), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(_banner, "scale", Vector2(0.7, 0.7), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

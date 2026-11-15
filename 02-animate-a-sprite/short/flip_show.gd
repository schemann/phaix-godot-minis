extends Node2D
## The Short's scene: the room and the knight of main.tscn, plus the calls the take makes at the words of the voice.
## player.gd is not touched. While the knight is held, it stands on the spot and the take sets what the sprite shows (flip_h, idle, walk),
## so "flip h mirrors every frame of every animation" is on screen exactly while the voice says it; released, player.gd runs as in the game.

@onready var _player: CharacterBody2D = $Player
@onready var _sprite: AnimatedSprite2D = $Player/AnimatedSprite2D

func stand() -> void:
	_player.set_physics_process(false)
	_player.velocity = Vector2.ZERO
	_sprite.flip_h = false
	_sprite.play("idle")

func release() -> void:
	_player.set_physics_process(true)

func flip_on() -> void:
	_sprite.flip_h = true

func flip_off() -> void:
	_sprite.flip_h = false

func idle() -> void:
	_sprite.play("idle")

func walk() -> void:
	_sprite.play("walk")

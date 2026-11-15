extends Node2D
## The Short's bug scene: the enemy starts when the take says so (start), and a take puts him far from the knight or close to him at the cut between two lines.

## far away: the top left corner of the frame, as far from the knight as the frame allows (361 px, the readout starts at 90): the way is a long diagonal that is never walked to its end in a take, so he does not reach the top of the knight's shape
const FAR := Vector2(-140, -95)
## in between: 173 px to the knight's upper left, the readout starts at 43 and he crawls in over about four seconds (the sentence "that vector is as long as the distance")
const MID := Vector2(-60, 110)
## close up: 110 px to the knight's left at his height, so the slow goblin crawls in from the side and stands beside him
const NEAR := Vector2(-10, 175)

@onready var enemy: CharacterBody2D = $Enemy

func start() -> void:
	enemy.process_mode = Node.PROCESS_MODE_INHERIT

func reset_far() -> void:
	_put(FAR)

func reset_mid() -> void:
	_put(MID)

func reset_near() -> void:
	_put(NEAR)

func _put(spot: Vector2) -> void:
	enemy.position = spot
	enemy.velocity = Vector2.ZERO

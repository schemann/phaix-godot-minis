extends Node2D
## The Short's fix scene: the project's own enemy, started by the take. tune is the Inspector's job in the project: the speed is an export variable.

## Where the take puts the goblin far away: at the left edge of the frame and almost at the knight's height, so he walks in from the side and ends standing BESIDE the knight (his shape stops at the knight's side, about 54 px from the knight's centre), never over his head
const FAR := Vector2(-140, 20)

@onready var enemy: CharacterBody2D = $Enemy

func start() -> void:
	enemy.process_mode = Node.PROCESS_MODE_INHERIT

func reset_far() -> void:
	enemy.position = FAR
	enemy.velocity = Vector2.ZERO
	enemy.speed = 60.0

func tune() -> void:
	enemy.speed = 120.0

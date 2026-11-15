extends Label
## The Short's readout, a fixed number at the top right under the Short's text block. The bug scene reads the length of the enemy's velocity: the vector to the target times 0.25, so the number is a quarter of the distance
## between the two centres, and the enemy (Floating, like the video's enemy) keeps asking for it while the knight's shape holds his body (14 at the knight's side, never 0). The fix scene reads the set speed, the exported variable `speed` of enemy.gd, and says so ("set speed"): the enemy stands at the knight at the end of the
## take, his velocity still reads 60 or 120 there while his body hardly moves, so the readout names what is set.

@export var enemy: CharacterBody2D
@export var show_variable := false

func _process(_delta: float) -> void:
	if show_variable:
		text = "set speed %d" % roundi(float(enemy.get("speed")))
	else:
		text = "speed %d" % roundi(enemy.velocity.length())

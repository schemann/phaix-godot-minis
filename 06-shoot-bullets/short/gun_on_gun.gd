extends "res://gun.gd"
## The mistake of the Short: the bullet is added to the gun, so it turns with the gun.

func shoot() -> void:
	var bullet: Node2D = bullet_scene.instantiate()
	add_child(bullet)
	bullet.global_transform = muzzle.global_transform

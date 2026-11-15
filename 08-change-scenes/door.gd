extends Area2D

@export_file("*.tscn") var target: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D) -> void:
	get_tree().change_scene_to_file.call_deferred(target)

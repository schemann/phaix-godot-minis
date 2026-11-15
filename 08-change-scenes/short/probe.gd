extends Node
## Logs, in the order they happen, what the door and its room do (series rule 50): the room's way out of the tree and the door's body_entered. It sits after
## the door in the room, so the door's own script has the signal first: a door that calls change_scene_to_file inside the signal has taken the room out of the tree
## before this one hears it, and a door that defers the call has finished the signal first.

func _ready() -> void:
	(get_node("../Door") as Area2D).body_entered.connect(_on_body_entered)
	get_parent().tree_exiting.connect(_on_room_leaving)

func _on_room_leaving() -> void:
	_log("%s.tree_exiting" % get_parent().name)

func _on_body_entered(body: Node2D) -> void:
	_log("Door.body_entered(%s)" % body.name)

func _log(text: String) -> void:
	var console: Variant = Engine.get_meta("demo_console", null)
	if console != null and is_instance_valid(console):
		(console as Node).call("add_line", text)

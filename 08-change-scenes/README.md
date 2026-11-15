# How to Change Scenes in Godot 4

The project of the Phaix mini tutorial "How to Change Scenes in Godot 4". Open `project.godot` in Godot 4.7 and press F5. Walk up to the door with the arrow keys and step into the doorway: room two loads, and the door there leads back to room one.

`door.gd` is the lesson: an `Area2D` that connects `body_entered` and calls `get_tree().change_scene_to_file(target)`. `target` is an `@export_file("*.tscn")`, so each door instance gets its scene in the Inspector (`room_one.tscn` has the door to `room_two.tscn`, `room_two.tscn` the door back). The call is deferred: `change_scene_to_file` takes the current scene, the door included, out of the tree at once, and Godot does not allow that inside a physics callback (without `.call_deferred(target)` it prints "Removing a CollisionObject node during a physics callback is not allowed").

Code and scenes are MIT, see `LICENSE` in the root of the repo.

The knight animates from `knight_frames.tres` (idle and walk, from `art/walk.png`) and `knight_sprite.gd` on its AnimatedSprite2D: walk while it moves, idle while it stands.

The art is 16x16 DungeonTileset II by 0x72 (https://0x72.itch.io/dungeontileset-ii), CC0, see `art/LICENSE.txt`.

`tests/run_tests.gd` is the project's check (`godot --headless --path . -s tests/run_tests.gd`). It also runs `tests/autoload_proof/`, a small project of its own with one autoload, that proves what the last step says: a value in an autoload is still there after `change_scene_to_file`, a value on a node of the old room is gone. This project has no autoload.

`short/` holds the demo of the Short: `door_bug.gd` is `door.gd` as it reads before the fix (the same call, without `.call_deferred(target)`, so the engine prints its error), and the rooms in it show an Output readout (`console.gd`: the engine's own error text from a Logger and the real signals of the door and its room, in the order they happen). `tests/run_short_tests.gd` proves the two orders headless. The folder is not needed for the lesson.

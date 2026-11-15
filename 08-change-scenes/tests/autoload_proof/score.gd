extends Node
## The autoload of the proof. `project.godot` registers it as `Score`, so Godot adds this node to the root of the tree when the game starts, next to the current scene and
## never inside a room. `change_scene_to_file` only swaps the current scene, so this node stays.

var points := 0

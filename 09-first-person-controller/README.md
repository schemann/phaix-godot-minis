# How to Make a First Person Controller in Godot 4

The project of the Phaix mini tutorial "How to Make a First Person Controller in Godot 4". Open `project.godot` in Godot 4.7 and press F5. Walk with W A S D and look around with the mouse. The mouse is captured while the game runs; close the game window with your system's shortcut (Alt+F4, Cmd+Q) or stop the game from the editor to get it back.

`player.gd` is the lesson, 21 lines on a `CharacterBody3D`. `_unhandled_input` reads `screen_relative` of the mouse motion (how far the mouse moved, in screen pixels, which the project's stretch settings do not scale) and turns the whole body with the sideways move (the yaw) and tilts only the `Camera3D` with the up and down move (the pitch), and `clampf` keeps the pitch between minus 80 and 80 degrees so the view never flips over. `_physics_process` reads the four actions of the Input Map (`move_forward` on W, `move_back` on S, `move_left` on A, `move_right` on D) with `Input.get_vector` and walks the body along its own basis with `move_and_slide`, which slides along walls instead of sticking to them. There is no gravity in the script, so it is made for a flat floor. `speed` and `sensitivity` are `@export` variables.

Code and scenes are MIT, see `LICENSE` in the root of the repo. The floor texture `textures/floor.png` is drawn for the mini (a checker of two greys) and MIT like the code.

`short/` holds the demo of the Short: `player_bug.gd` is `player.gd` without the `clampf` line, so the camera keeps adding up past 90 degrees and the view is upside down, and the scenes in it show a readout of the real yaw of the Player and pitch of its camera (`readout.gd`). `tests/run_short_tests.gd` proves both. The folder is not needed for the lesson.

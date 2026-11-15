# How to Make a State Machine in Godot 4

The project of the Phaix mini tutorial "How to Make a State Machine in Godot 4". Open `project.godot` in Godot 4.7 and press F5.

## Controls

- The left and right arrow keys walk the knight; the d-pad or the left stick of a gamepad works as well.
- Enter or Space jumps.

Code and scenes are MIT, see `LICENSE` in the root of the repo.

The knight animates from `knight_frames.tres` (idle and walk, from `art/walk.png`) and `knight_sprite.gd` on its AnimatedSprite2D: walk while it moves, idle while it stands.

The art is 16x16 DungeonTileset II by 0x72 (https://0x72.itch.io/dungeontileset-ii), CC0, see `art/LICENSE.txt`. The camera has limits in `player.tscn`, so the picture stops at the level's walls and never shows outside the level.

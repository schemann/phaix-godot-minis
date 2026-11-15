# How to Shoot Bullets in Godot 4

The project of the Phaix mini tutorial "How to Shoot Bullets in Godot 4". Open `project.godot` in Godot 4.7 and press F5. Move the mouse to aim, click the left mouse button to shoot.

`short/wrong.tscn` and `short/right.tscn` are the scenes of the Short: in the first one the bullet is added to the gun and turns with it, in the second one it is added to the scene.

Code and scenes are MIT, see `LICENSE` in the root of the repo.

The knight animates from `knight_frames.tres` (idle and walk, from `art/walk.png`) and `knight_sprite.gd` on its AnimatedSprite2D: walk while it moves, idle while it stands.

The art is 16x16 DungeonTileset II by 0x72 (https://0x72.itch.io/dungeontileset-ii), CC0, except `gun.png`, `bullet.png` and `crosshair.png`: the pack has no gun, so they are drawn for this mini and are MIT like the code. See `art/LICENSE.txt`. The camera has limits in `player.tscn`, so the picture stops at the room's walls and never shows outside the room.

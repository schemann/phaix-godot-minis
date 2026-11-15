# How to Use TileMapLayer in Godot 4

The project of the Phaix mini tutorial "How to Use TileMapLayer in Godot 4". Open `project.godot` in Godot 4.7 and press F5.

`short/ghost_walls.tscn` is the scene of the Short: the same level, switched between its Tile Set and a copy whose physics layer is removed, so the player walks through the walls the way it does before step one.

Code and scenes are MIT, see `LICENSE` in the root of the repo.

The knight animates from `knight_frames.tres` (idle and walk, from `art/walk.png`) and `knight_sprite.gd` on its AnimatedSprite2D: walk while it moves, idle while it stands.

The art is 16x16 DungeonTileset II by 0x72 (https://0x72.itch.io/dungeontileset-ii), CC0, see `art/LICENSE.txt`. The camera has limits in `player.tscn`, so the picture stops at the level's walls and never shows outside it.

# How to Write a Shader in Godot 4

The project of the Phaix mini tutorial "How to Write a Shader in Godot 4". Open `project.godot` in Godot 4.7 and press F5.

`wave.gdshader` is the lesson: a `canvas_item` shader with three uniforms (`speed`, `strength`, `tint`) that makes the banner wave. Select the Banner node and change them in the Inspector under Material > Shader Parameters. `tuning.gd` is not part of the lesson: it only lets a recording move the three values from outside. The wave is multiplied by `UV.y`, so the top edge stays put and the bottom swings.

Code and scenes are MIT, see `LICENSE` in the root of the repo.

The art is 16x16 DungeonTileset II by 0x72 (https://0x72.itch.io/dungeontileset-ii), CC0, see `art/LICENSE.txt`. `wall.png` is a brick wall with its floor and `banner.png` the pack's wall banner in grey and white, so the tint shows as a clean colour. Both are cut from the pack at one pixel size, 16 px.

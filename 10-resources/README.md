# How to Use Resources in Godot 4

The project of the Phaix mini tutorial "How to Use Resources in Godot 4". Open `project.godot` in Godot 4.7 and press F5: the room shows a potion, a sword and a staff, three instances of one scene, and the knight walks about with the arrow keys.

`item.gd` is the lesson: `class_name Item extends Resource` with three exported fields, a title, an icon and the uses. An item is a file (`potion.tres`, `sword.tres`, `staff.tres`), made in the editor with New Resource, where `Item` is on the list because of `class_name`. `pickup.gd` has one slot, `@export var item: Item`, and in `_ready` it puts the item's picture on its Icon and its title and uses on its Label. `main.tscn` instances `pickup.tscn` three times and each instance has another item file in its Item slot. A fourth item is a fourth file: no new scene and no new code.

Code and scenes are MIT, see `LICENSE` in the root of the repo.

The knight animates from `knight_frames.tres` (idle and walk, from `art/walk.png`) and `knight_sprite.gd` on its AnimatedSprite2D: walk while it moves, idle while it stands.

The art is 16x16 DungeonTileset II by 0x72 (https://0x72.itch.io/dungeontileset-ii), CC0, see `art/LICENSE.txt`.

`tests/run_tests.gd` is the project's check (`godot --headless --path . -s tests/run_tests.gd`): `Item` is a global class that extends Resource, the three files hold their values, one scene shows all three, a fourth item shows without any other change, and the Short's two scenes prove what happens when pickups share one item file and when each one duplicates it.

`short/` holds the demo of the Short: three pickups that point at one `potion.tres`, so using one drops the label of all three (`pickup_bug.gd`, an Area2D that uses the item when the knight walks into it and reads its label live), and the one line that fixes it, `item = item.duplicate()` in `_ready` (`pickup_fix.gd`). The folder is not needed for the lesson.

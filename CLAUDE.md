# Riftbound Survivor — working notes for Claude

Godot 4 (tested on 4.7.2) prototype of the Rift combat run for *Riftbound: Arcane Academy*.
Design reference: "Riftbound — Rift Run System Design" doc (claude.ai artifact 9BGeNePKAHEbQSCny4Voxm).

## Roles
- Claude writes all code, runs the automated tests, and pushes.
- Syifa (repo owner) only playtests and reports bugs / feel. Write summaries for her in Indonesian,
  and tell her exactly what to test after each change (see `docs/TESTING.md`).

## Rules
- All tunable numbers and content tables live in `scripts/data/game_data.gd`. Never hardcode balance numbers elsewhere.
- Weapon behaviour lives in `scripts/actors/weapons.gd`; its numbers in `GameData.WEAPONS`.
- Meta progression (resources, academy buildings) is saved by `scripts/meta/save_data.gd` to `user://riftbound_save.json`. Bump `SaveData.VERSION` and migrate in `load_data()` if the format changes.
- Enemies, bullets, projectiles and pickups are data-oriented (arrays drawn by one node). Do not add a node per enemy.
- Map generation must stay deterministic for a given seed (`tests/test_mapgen.gd` checks this).
- Keep code compatible with Godot 4.4+ unless a newer feature is clearly worth it.
- Before every push, run the test commands below; all must print `[autotest] done` and no `SCRIPT ERROR`.

## Test commands (headless)
```
godot --headless --path . --import
godot --headless --path . -s tests/test_mapgen.gd
godot --headless --path . -s tests/test_academy.gd
godot --headless --path . --fixed-fps 60 -- --autotest --seed=4242
godot --headless --path . --fixed-fps 60 -- --autotest --seed=565590 --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest-die --seed=77
godot --headless --path . --fixed-fps 60 -- --autotest-late --seed=99 --slots=4
```
The main scene is the academy; any `--autotest*` flag makes it jump straight into a run.
Autotests never read or write the player's save (`SaveData`); without `--slots` they use the base 2 + 2 slots.
Academy screenshot: `xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -- --academy-shot=/tmp/academy.png`
Run screenshots (needs Xvfb): `xvfb-run -a godot --path . --rendering-driver opengl3 --fixed-fps 60 --resolution 1280x720 -- --autotest --shot=/tmp/run.png`

Note: in the cloud workspace the Godot binary is not preinstalled; download the official
`Godot_v4.7.2-stable_linux.x86_64.zip` from the godotengine/godot GitHub releases.

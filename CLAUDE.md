# Riftbound Survivor — working notes for Claude

Godot 4 (tested on 4.7.2) prototype of the Rift combat run for *Riftbound: Arcane Academy*.
Design reference: "Riftbound — Rift Run System Design" doc (claude.ai artifact 9BGeNePKAHEbQSCny4Voxm).

## Roles
- Claude writes all code, runs the automated tests, and pushes.
- Syifa (repo owner) only playtests and reports bugs / feel. Write summaries for her in Indonesian,
  and tell her exactly what to test after each change (see `docs/TESTING.md`).

## Rules
- All tunable numbers and content tables live in `scripts/data/game_data.gd`. Never hardcode balance numbers elsewhere.
- Weapon behaviour lives in `scripts/actors/weapons.gd` (shots in `projectiles.gd`); its numbers in `GameData.WEAPONS`.
  Attack types follow the uploaded "Riftbound Weapon Attack Design" doc (prototype set of 8 weapons).
  `--weapons=meteor,void` gives extra weapons in an autotest run (for screenshots).
- Characters (stats, starter weapon, per-level passive) are rows in `GameData.CHARACTERS`.
- VFX: weapon/event effects are pixelfx sprite effects (https://github.com/patch-gg/pixelfx, MIT), exported by
  `node tools/pixelfx_export.mjs <pixelfx clone> assets/vfx` into a colour sheet + a light sheet per effect and
  `assets/vfx/effects.json` (which must stay in the Android `include_filter`). Play them with
  `game.vfx.play(name, pos, rot, scale, tint, light_k, until, follow)`; the light layer is drawn additively
  and boosted into HDR, the colour layer by `SpriteFxColor`. Keep total VFX texture memory under ~70 MB
  (the exporter prints it). Small particles/lights also live in `scripts/vfx/vfx.gd`
  (one additive node; colours > 1.0 bloom via HDR 2D glow),
  screen effects (shockwave/chroma/vignette shader, shake, hit-stop) in `scripts/vfx/screen_fx.gd`,
  shaders in `shaders/`. Quality switches: `GameData.VFX_*`.
- Art: character sprites in `assets/characters/<id>/<direction>.png` (see its README); enemies/props are
  hand-authored grids in `scripts/meta/pixel_sprites.gd`. `--autotest-boss` summons the boss at ~25 s (for boss screenshots). The cloud workspace cannot download from
  PixelLab; Syifa uploads the PNGs and Claude commits them. Do not route downloads through CI.
- Android APK: `.github/workflows/android.yml` builds on every push and publishes the `latest-build`
  pre-release. CI logs are not readable from the workspace; failures show up as a `ci-log-tail`
  annotation (GitHub API: check-runs/<job id>/annotations).
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
godot --headless --path . --fixed-fps 60 -- --autotest-die --seed=77 --char=kael
godot --headless --path . --fixed-fps 60 -- --autotest-late --seed=99 --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest-boss --seed=31337 --char=lyra
```
The main scene is the academy; any `--autotest*` flag makes it jump straight into a run.
Autotests never read or write the player's save (`SaveData`); without `--slots` they use the base 2 + 2 slots.
Academy screenshot: `xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -- --academy-shot=/tmp/academy.png`
Run screenshots (needs Xvfb): `xvfb-run -a godot --path . --rendering-driver opengl3 --fixed-fps 60 --resolution 1280x720 -- --autotest --char=lyra --shot=/tmp/run.png --shot-times=30,60`
(software GL is slow with heavy VFX: keep shot times early; OpenGL also shows much weaker bloom than the Mobile renderer on phones).

Note: in the cloud workspace the Godot binary is not preinstalled; download the official
`Godot_v4.7.2-stable_linux.x86_64.zip` from the godotengine/godot GitHub releases.

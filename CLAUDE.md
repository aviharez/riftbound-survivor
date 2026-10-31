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
  Attack types follow `docs/weapon_attack_design.md` (Syifa's "Riftbound Weapon Attack Design"; prototype set of 8 done,
  plus 6 alpha weapons: Crescent Slash, Rune Chakram (out-and-return), Arcane Familiar (summon), Aether Beam,
  Venom Bloom (poison cloud), Arcane Mine (trap)). Optional `short` in a weapon row = 3-letter HUD label.
  `--weapons=meteor,void` gives extra weapons (evolved ids such as `solar` come evolved) and `--swarm-at=30` starts
  the Final Swarm early in an autotest run; `--ready-evolve` puts owned weapons at the evolve level with their tome
  so the first chests evolve them; `--profile` prints load counters every 20 s of game time.
- Weapon evolutions (approved by Syifa): base weapon at `GameData.EVOLVE_LEVEL` (= max, 8) + its tome (any level)
  -> the next chest opened (any chest) gives the evolution instead of an item. Evolved rows are in `GameData.WEAPONS`
  with `evolved`/`from`/`tome`, weight 0, final numbers (lvl_* = 0); they replace the base weapon in its slot.
  Pairs: bolt+Multitude=Prismatic Barrage, flame+Ricochet=Solar Cataclysm, chain+Haste=Thunderstorm Network,
  meteor+Expanse=Starfall, blades+Vitality=Blade Halo, void+Attraction=Event Horizon, lance+Precision=Absolute Zero,
  seed+Mending=Worldroot Bloom. Freeze (`Enemy.freeze_t`) stops a foe and its contact damage; bosses are only slowed.
- Final Swarm scaling (swarm level per minute, wraiths, threat meter) is tuned by the `FINAL_SWARM_*` / `THREAT_NAMES` constants.
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
`GODOT=<godot binary> tools/run_tests.sh` runs all of these with a timeout each and prints ok/FAIL per test.
A GDScript parse error makes an autotest hang (the scene never loads) instead of failing: always use timeouts,
and check a suspicious script with `godot --headless --path . --check-only -s <script>`.
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
godot --headless --path . --fixed-fps 60 -- --autotest --seed=4242 --char=lyra --weapons=bolt,chain,meteor --ready-evolve --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest --seed=565590 --char=kael --weapons=void,lance,seed --ready-evolve --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest --seed=31337 --char=astra --weapons=slash,chakram,familiar,beam,venom,mine --slots=4
```
The two `--ready-evolve` runs must end with all 4 evolutions in `evolutions=[...]`.
The main scene is the academy; any `--autotest*` flag makes it jump straight into a run.
Autotests never read or write the player's save (`SaveData`); without `--slots` they use the base 2 + 2 slots.
Academy screenshot: `xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -- --academy-shot=/tmp/academy.png`
Run screenshots (needs Xvfb): `xvfb-run -a godot --path . --rendering-driver opengl3 --fixed-fps 60 --resolution 1280x720 -- --autotest --char=lyra --shot=/tmp/run.png --shot-times=30,60`
(software GL is slow with heavy VFX: keep shot times early; OpenGL also shows much weaker bloom than the Mobile renderer on phones).

Note: in the cloud workspace the Godot binary is not preinstalled; download the official
`Godot_v4.7.2-stable_linux.x86_64.zip` from the godotengine/godot GitHub releases.

## New session setup
1. Godot: download `Godot_v4.7.2-stable_linux.x86_64.zip` (godotengine/godot releases), unzip, run `--import` once.
2. pixelfx (only needed to change or add VFX): `git clone https://github.com/patch-gg/pixelfx`, `npm install` in it.
   Our custom effects live in `tools/pixelfx_custom/riftbound/`; the exporter copies them into the clone.
   Author new ones with the clone's `skills/pixelfx/SKILL.md` workflow (draft, `node tools/render.mjs`, look, fix,
   `node tools/check.mjs`), then copy the final file back into `tools/pixelfx_custom/`.
   Top-down rule: Syifa wants every effect to read top-down. Many library effects are side-view (frost-nova,
   ice-shatter, thorns, plasma-explosion's tilted rings): do not use those; author a custom one instead. Our
   convention (see `riftbound/meteor-strike.js`): floor rings are ellipses with sy = 0.6, "up the screen" = "into the
   sky", things fall down the screen. `p.disc` is round, so draw flat floor patches per pixel with `p.blend`.
3. Screenshots need `xvfb-run`; software GL is slow, keep shot times early.

## Status and next up (as of 2026-10-31, evening)
Done: map/run loop, chests, shrines (beam while unused), tomes, items, elites, Rift Surges, boss, Final Swarm
(swarm level per minute, wraiths, threat meter), academy (Library, Training Ground), 4 characters with
chibi sprites, 14 weapons from the design doc (prototype 8 + alpha 6), **8 weapon evolutions** (custom top-down
bursts solar-burst, frost-burst, void-collapse), pixelfx VFX, Android CI. No audio yet.
The 6 alpha weapons have no evolutions yet (the doc names them: Lunar Cross, Infinity Loop, Familiar Legion,
Celestial Ray, Plague Garden, Runic Chain); 5 tomes are still unpaired (Power, Fortune, Study, Greed, Cursed).
Open question: whether Lv 8 is reached often enough in real runs to evolve (EVOLVE_LEVEL is one constant).

Syifa's next priorities, in order she listed:
1. ~~Weapon evolutions~~ done (see Rules). Tune from her playtest feedback.
2. ~~More weapons~~ alpha set of 6 done. Still open from the doc: Hex Mark (damage amp), Glacial Burst,
   Gravity Lens / Mirror Gate / Crystal Barricade (arena manipulation), Phantom Knight, Prism Sweep, Riftstorm.
3. **Academy expansion**: more buildings (e.g. unlock characters such as Selene/Noah from the doc,
   permanent stat upgrades, adding weapons to the pool). Save format changes need `SaveData.VERSION` + migration.

Feedback to remember: VFX must read as top-down; heavy but not blinding (she asked to dim only the
Astral Blades tips, not the whole trail); characters cute/chibi; every weapon fires on cooldown even
with no enemy; PixelLab art is generated and uploaded by Syifa.

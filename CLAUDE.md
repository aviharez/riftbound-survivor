# Riftbound Survivor — working notes for Claude

Godot 4 (tested on 4.7.2) prototype of the Rift combat run for *Riftbound: Arcane Academy*.
Design reference: "Riftbound — Rift Run System Design" doc (claude.ai artifact 9BGeNePKAHEbQSCny4Voxm).
**Agreed game design (roster, meta systems, locations/danger, economy, monetization, phases): `docs/game_design.md`.
Read it before starting any phase.**

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
  seed+Mending=Worldroot Bloom. Level-up cards show a "COMBO + ... (owned) -> evolution" hint only when the
  player already owns the other half (`GameData.combo_hint`; tome cards only while the tome is NEW); plain otherwise.
  `--tomes=ricochet,haste` gives autotest runs tomes from the start. Freeze (`Enemy.freeze_t`) stops a foe and its contact damage; bosses are only slowed.
- Final Swarm scaling (swarm level per minute, wraiths, threat meter) is tuned by the `FINAL_SWARM_*` / `THREAT_NAMES` constants.
- Characters are rows in `GameData.CHARACTERS` (Syifa's direction: every character is a student or teacher of the
  academy, with a school/element, a role and a home building). Each has a mechanical `trait` (`GameData.TRAITS`,
  code in `weapons.gd` "character traits": Astra arcane_echo, Lyra kindling, Kael retaliation, Nym thornheal,
  Selene frostbite and Sera duelist in `Enemies.damage`, Noah plague, Raika static_charge, Vesper gravity_pull,
  Wren page_guard (`Player.take_damage`), Celeste stargazer, Runa rune_ward, Lumi overflow) plus small `per_level`
  stat growth, and `unlock`: the building whose restoration brings them back ("" = from the start;
  `unlock_level` when it needs more than Lv 1, Wren = Library at max). Full roster (13: mostly cute girls, Kael and Noah
  the boys) with roles, outfits and home buildings is in `docs/game_design.md` section 3. A character without
  sprite files falls back to the coloured placeholder.
- Academy buildings (`GameData.BUILDINGS`): `unlocks` = tome / weapon (slots), character (Lv 1 brings back
  `character`), lessons (Staff Room: teachers sell permanent upgrades `GameData.LESSONS`, bought with EXP + gold,
  rank cap = `LESSON_RANKS_PER_LEVEL` x Staff Room level, applied at run start). Academy strips scroll sideways;
  `--academy-demo` (sample save, never written), `--academy-lessons`, `--academy-scroll` are for screenshots.
  Autotests: `--lessons=might:3`; the summary prints `char=... trait_procs=N lessons=...`.
- VFX: weapon/event effects are pixelfx sprite effects (https://github.com/patch-gg/pixelfx, MIT), exported by
  `node tools/pixelfx_export.mjs <pixelfx clone> assets/vfx` into a colour sheet + a light sheet per effect and
  `assets/vfx/effects.json` (which must stay in the Android `include_filter`). Play them with
  `game.vfx.play(name, pos, rot, scale, tint, light_k, until, follow)`; the light layer is drawn additively
  and boosted into HDR, the colour layer by `SpriteFxColor`. Keep total VFX texture memory under ~70 MB
  (the exporter prints it). Small particles/lights also live in `scripts/vfx/vfx.gd`
  (one additive node; colours > 1.0 bloom via HDR 2D glow),
  screen effects (shockwave/chroma/vignette shader, shake, hit-stop) in `scripts/vfx/screen_fx.gd`,
  shaders in `shaders/`. Quality switches: `GameData.VFX_*`.
- Art: character sprites in `assets/characters/<id>/<direction>.png` plus `walk/` (6 frames) and `idle/` (4 frames)
  strips per direction, played by `CharacterArt.frames()` in `player.gd` (see the folder README for the full
  PixelLab workflow). Enemies/props are hand-authored grids in `scripts/meta/pixel_sprites.gd`.
  `--autotest-boss` summons the boss at ~25 s (for boss screenshots).
  Claude makes character art itself with the PixelLab MCP (Syifa's account, Tier 1: 2000 generations/month,
  8 jobs at once; report credit use each phase): `create_character` mode v3, size 64, view "low top-down",
  "cute chibi anime ..." (2 generations); `animate_character` templates `walking-6-frames` / `breathing-idle`
  (1 generation per direction). The workspace proxy blocks every PixelLab URL (downloads and uploads, 403):
  pull art out with `pixelart_workbench join ... --as sheet|rows` (the saved image is an 18 px caption above the
  sheet on solid #1f252c) and `python3 tools/pixellab_sheet.py` (checks the colour count). Sprites only use
  alpha 0/255. Do not route downloads through CI. Look at every generated sheet: check new designs against
  well-known game / anime characters (Syifa caught a Genshin look-alike), and re-roll directions where a
  template animation drops a detail (v3 custom animation, stored on an 84 px canvas).
- Android APK: `.github/workflows/android.yml` builds on every push and publishes the `latest-build`
  pre-release. CI logs are not readable from the workspace; failures show up as a `ci-log-tail`
  annotation (GitHub API: check-runs/<job id>/annotations).
- Meta progression is saved by `scripts/meta/save_data.gd` to `user://riftbound_save.json`: resources (+ Arcane
  `shards`), buildings, lessons (v2), per-character `characters` {exp, passive, weapon, bond} (v3), equipment
  `items`/`equipped`/`next_uid` + location `essence` (v4), `dorm`/`talked`/`expeditions` (v5). Phase 2 meta systems
  (numbers in `game_data.gd`: CHAR_*, ENHANCE_*, EQUIP_*/GEAR_RARITY_*/CRAFT_COST, BOND_*, DORM_ROOMS, EXPEDITIONS):
  character level from character EXP (= run EXP), enhance (passive = `Player.trait_power` scaling every trait via
  `Weapons._tk()`, signature = starter weapon + its evolution in `level_damage`/`level_cooldown`), equipment
  (3 slots, rolled substats, run drops, Workshop crafting/salvage), bond (levels give mods + a story scene in
  `scripts/data/bond_scenes.gd`), Dormitory rooms + daily talk, real-time expeditions (`now` passed in, so tests
  fake time). All of it reaches a run through `SaveData.char_run_bonus()` in `main._apply_lessons()`.
  Academy UI (Syifa's layout, after mobile hero games; she rejected the first ornate/Cinzel reskin): home =
  `scripts/ui/academy.gd` (class Home): pannable `AcademyMap` (PixelLab buildings in `assets/academy/`, 192 px drawn
  at `ACADEMY_SPRITE_SCALE`, plots/decor in `GameData.ACADEMY_*`; ruined = rubble + cyan hologram; tap opens
  `BuildingPanel`), HUD: top-left selected mage + quests (`Home.quests()`), top-right resources + settings,
  bottom-left Characters / Expedition / Codex, bottom-right ENTER THE RIFT -> Rift page (START). Pages
  `page_{characters,expedition,codex,rift}.gd` are full screen with a back button; overlays
  `{lessons,workshop,dorm,building}_panel.gd`. Look = `UiKit` + `GlassStyle` (rounded translucent glass, gold
  slanted CTA); fonts Nunito (body) + Exo 2 Italic (titles), OFL. No Cinzel (Syifa hates it).
  Screenshot flags with `--academy-demo`: `--academy-page=characters|rift|expedition|codex`, `--academy-tab=enhance|gear|bond`,
  `--academy-building=<id>`, `--academy-lessons/-workshop/-dorm/-settings`; `--academy-check` opens everything once (test `academy_ui`).
  Big illustrations: `assets/illustrations/<id>.png` (spec in its README) replace the scaled sprite on the Characters page. Autotest flags
  `--char-level=15 --enhance=3,3 --gear=robe:4,wand:2`; the summary prints `char_level= enhance= max_hp= shards= equipment=`. Bump `SaveData.VERSION` and migrate in `load_data()` if the format changes;
  `tests/test_academy.gd` loads a hand-written v1 save to check the migration.
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
godot --headless --path . -s tests/test_combo.gd
godot --headless --path . --fixed-fps 60 -- --autotest --seed=4242
godot --headless --path . --fixed-fps 60 -- --autotest --seed=565590 --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest-die --seed=77
godot --headless --path . --fixed-fps 60 -- --autotest-die --seed=77 --char=kael
godot --headless --path . --fixed-fps 60 -- --autotest-late --seed=99 --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest-boss --seed=31337 --char=lyra
godot --headless --path . --fixed-fps 60 -- --autotest --seed=4242 --char=lyra --weapons=bolt,chain,meteor --ready-evolve --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest --seed=565590 --char=kael --weapons=void,lance,seed --ready-evolve --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest --seed=31337 --char=astra --weapons=slash,chakram,familiar,beam,venom,mine --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest --seed=4242 --char=selene --lessons=might:3,vigor:2 --slots=4
godot --headless --path . --fixed-fps 60 -- --autotest-die --seed=77 --char=noah
```
The selene / noah runs (and every `trait_<character>` run in `tools/run_tests.sh`) must report `trait_procs` > 0.
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

## Status and next up (as of 2026-11-01)
Done: map/run loop, chests, shrines (beam while unused), tomes, items, elites, Rift Surges, boss, Final Swarm
(swarm level per minute, wraiths, threat meter), academy (Library, Training Ground, Staff Room, 6 character
buildings + Workshop + Dormitory), **all 13 characters** with v3 sprites + walk/idle animations and mechanical
traits (phase 1 done), **phase 2 meta systems** (character level, enhance, equipment + crafting, bond with 65 story
scenes, dormitory, expeditions), **phase 3 UI + home map** (academy hub map with tappable buildings made in phase 3 at Syifa's request; next:
construction timers + ad hooks (rest of phase 4), then phase 5 locations / danger / quests; some walk/idle directions still need revision, Syifa said later), 14 weapons from the design doc (prototype 8 + alpha 6), **8 weapon evolutions** (custom top-down
bursts solar-burst, frost-burst, void-collapse), pixelfx VFX, Android CI. No audio yet.
The 6 alpha weapons have no evolutions yet (the doc names them: Lunar Cross, Infinity Loop, Familiar Legion,
Celestial Ray, Plague Garden, Runic Chain); 5 tomes are still unpaired (Power, Fortune, Study, Greed, Cursed).
Open question: whether Lv 8 is reached often enough in real runs to evolve (EVOLVE_LEVEL is one constant).

Syifa's next priorities, in order she listed:
1. ~~Weapon evolutions~~ done (see Rules). Tune from her playtest feedback.
2. ~~More weapons~~ alpha set of 6 done. Still open from the doc: Hex Mark (damage amp), Glacial Burst,
   Gravity Lens / Mirror Gate / Crystal Barricade (arena manipulation), Phantom Knight, Prism Sweep, Riftstorm.
3. **Academy expansion**: phase 1 done (Staff Room lessons, Frost Tower -> Selene, Alchemy Lab -> Noah, mechanical
   traits for all 6, PixelLab sprites for Selene and Noah made by Claude). Next phases: the rest of the roster
   above (2 per phase).

Playtest fixes (1 Nov): Arcane Bolt = fast homing (`homing` turn rate, cyan trail); Flame Orb = big slow, bounces
off walls (`wall_bounce`) and splashes a top-down flame star on every hit (`splash_r`/`splash`); meteor-strike is a grey
cracked rock with a growing floor shadow and a dust ring (must not read as a fireball); Astral Blades trail body
stays under the bloom threshold (only the rim blooms); Void Well detonates with the centred void_collapse
(dark_explosion's pivot is at its base and drew the blast ~40 px above the pull centre: check pivots when mixing
effects); Thornseed uses the custom thorn-patch (snare ring, vines, thorns; `fx["speed"]` stretches a one-shot
to the zone's life) and snared foes are tinted `ROOTED_TINT`.
Feedback to remember: VFX must read as top-down; heavy but not blinding (she asked to dim only the
Astral Blades tips, not the whole trail); characters cute/chibi, more girls with cute outfits; every weapon
fires on cooldown even with no enemy; Claude generates PixelLab art itself (Syifa's account, Tier 1 = 2000
generations/month, up to 8 jobs at once) and reports credit use each phase; Syifa provides the big anime
illustrations.

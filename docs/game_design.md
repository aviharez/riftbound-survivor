# Riftbound: Arcane Academy — Game Design (agreed 1 Nov 2026)

Decisions from the design discussion between Syifa (owner) and Claude. This is the reference for every
later phase; change it when a decision changes. Weapon attack types live in `weapon_attack_design.md`.

## 1. Vision and direction

- Mobile-first (Android) landscape roguelite in the style of Megabonk / Survivor.io: short timed runs in the
  Rift, then progress back at a ruined magic academy that the player restores.
- Visual references: Syifa's mockup pack (navy UI with ornate gold frames and glowing cyan accents, pixel-art
  world, purple Rift corruption crystals on ruined buildings, chibi pixel sprites in play, large anime
  illustrations on character / roster / codex screens). Combat reference: big readable VFX, dense gems, a
  boss with a floor magic circle, minimal HUD.
- No gacha. Rarity labels (SSR/SR) in the mockups were decoration only.
- Game text in English.
- Open: first release platform — Android only, or Android + Steam (affects controls and resolution).

## 2. Art

- In-game characters: PixelLab, `create_character` mode v3, 64 px, view "low top-down", "cute chibi anime ..."
  (Selene and Noah set the quality bar). Walk and idle animations per character.
- Large anime illustrations (roster, character details, codex, victory screen) are prepared by Syifa from
  another source; Claude supplies the size / pose / transparency spec before she makes them.
- VFX: pixelfx custom effects, always top-down (see CLAUDE.md).
- UI: reskin to the reference look (navy panels, ornate gold borders, cyan glow), mostly drawn in code.
- Academy hub (later phase) is an isometric-style map; it needs its own PixelLab asset set.

## 3. Characters

Every character is a student or teacher of the academy with a school (element), a role and a home building
whose restoration brings them back. Direction: mostly girls with cute academy outfits (wholesome, the kind of
anime characters many people like); Kael and Noah stay as the two boys.

| Character | Role | School | Signature weapon | Home building | Outfit notes |
|---|---|---|---|---|---|
| Astra | new student (protagonist) | Arcana | Arcane Bolt | start | navy robe with gold trim, silver hair, crystal staff |
| Lyra | Duel Club champion | Pyromancy | Flame Orb | start | pink twin-tails, red uniform with ribbon |
| Kael (m) | academy guard | Spellblade | Astral Blades | start | silver knight armour, dark blue hair |
| Nym | infirmary healer | Herbology | Thornseed | start | long leaf-green hair, elf ears, white nurse outfit with nurse cap, flower crown |
| Selene | Student Council President | Cryomancy | Frost Lance | Frost Tower | done (silver hair, pale blue uniform, ice spear) |
| Noah (m) | alchemy student | Alchemy | Venom Bloom | Alchemy Lab | done (green hair, goggles, lab coat, flask) |
| Raika | weather club member | Tempestas (lightning) | Chain Lightning | Bell Tower | yellow twin-tails, raincoat capelet, lightning hairclips |
| Vesper | mysterious student of the forbidden wing | Gravimancy (void) | Void Well | Forbidden Archive | dark purple gothic dress, sleepy, hugs a plush |
| Wren | library assistant | Summoning | Arcane Familiar | Library (max) | round glasses, oversized cardigan, floating book |
| Sera | Spellblade instructor (teacher) | Spellblade | Crescent Slash | Duel Hall | young teacher, short black hair with side braid, teal instructor uniform + cape, rapier |
| Celeste | astronomy professor (teacher) | Astromancy | Meteor Fall | Observatory | star-patterned witch hat, always sleepy |
| Runa | rune master (teacher) | Runecraft | Rune Chakram / Arcane Mine | Rune Workshop | tiny genius in an oversized robe |
| Lumi | aether researcher (teacher) | Aether | Aether Beam | Arcana Lab | lab coat, prism earrings |

Designs must not resemble well-known game / anime characters (a first Nym looked like Genshin's Nahida and a
first Sera like Fairy Tail's Erza; both were replaced). Sprites: v3 64 px with walk + idle animations
(see `assets/characters/README.md`).

Each character has a mechanical trait (`GameData.TRAITS`) plus small per-level growth. Names of the new ones
are proposals Syifa may change.

## 4. Meta systems (all required)

- **Character level** (persistent, per character): character EXP earned by runs played with that character;
  raises base stats. Higher danger levels are meant to be easier with higher levels.
- **Enhance skills**: upgrades the character's passive / signature weapon; costs gold + Arcane Shards.
- **Equipment**: weapon / armour / accessory slots per character, shared inventory, any character can wear any
  piece, rarities common to legendary (no gacha). From run drops and expedition rewards, and craftable at the
  Workshop from materials + Rift Essence (each location drops its own essence).
- **Bond**: rises by playing a character, sending them on expeditions and talking to them in the dorm; each bond
  level unlocks a small passive bonus and a short story scene (English, drafted by Claude, reviewed by Syifa).
- **Dormitory**: rooms for returned characters; room count grows with the Dormitory level; character
  details and bond interactions happen here.
- **Expedition**: send characters not being played on real-time missions (hours); rewards gold, materials,
  shards, equipment. Runs while the game is closed.
- **Staff Room lessons**: global permanent upgrades (already built).

## 5. Academy buildings and construction

- The academy hub is a map; tap a building to open it (no walking).
- Repairing / upgrading takes real time, growing per level (about 5 min early, up to ~8 h at high levels). The
  first buildings are quick so new players are never stuck. Remaining time under 5 min can be finished free.
- Builder slots (start 1, can grow) limit parallel construction.
- Finished construction / expedition sends an Android notification. Autotests skip timers.

## 6. Locations and danger

- 5 locations in order: Ruined Courtyard, Whispering Forest, Forgotten Library, Crystal Cavern, Rift Nexus.
  Each has its own tileset, enemies and boss.
- 5 danger levels per location: higher danger = tougher / more / more elite enemies and multiplied rewards.
- Winning danger N unlocks N+1 of that location; winning danger 1 unlocks the next location.
- Each location and danger shows a recommended character level.

## 7. Economy

| System | Paid with | Earned from |
|---|---|---|
| Character level | character EXP | runs played with that character |
| Enhance skill | gold + Arcane Shard | run drops (bosses, high danger) |
| Buildings | gold, materials, aether + time | runs |
| Staff Room lessons | academy EXP + gold | runs |
| Equipment crafting | materials + Rift Essence (per location) | runs in that location |
| Expedition | time | gives gold, materials, shards, equipment |

## 8. Monetization (no gacha, never pay-to-win)

Phased:
1. **Launch**: optional rewarded ads + direct purchases with clear Rupiah prices.
   - Rewarded ads: speed up construction and expeditions (a fixed amount or a percentage per ad), one revive
     per run, double run rewards. Daily ad cap (about 10). Never forced ads in a run.
   - Direct purchases (non-consumable, restorable by the store, no server needed): Supporter Pack (remove ads +
     cosmetic), cute outfits (bought directly, no randomness), content packs (location + character).
2. **After an account + cloud save exist**: one premium top-up currency (working name Starshard) for
   cosmetics, instant finish of timers, extra expedition slots, dorm decoration. Rules: one premium currency
   only, packs that match item prices, real price shown, also earnable slowly in play, never sells power.
   (Consumable purchases cannot be restored by the store, so top-up needs cloud save first; EU consumer
   principles on virtual currencies apply to a global Play release.)
- Possible later: Steam premium version (about $5–10) with a free demo.
- Syifa checks her employment contract (side business) and tax matters herself.

## 9. Audio

Later phase. Music with Audio as Code (https://audioascode.com, local Python, MIT framework); sound effects by
procedural synthesis in code. Claude cannot listen: Syifa judges how it sounds.

## 10. Execution phases

1. Character art: v3 sprites for all 13 (4 old remade, 7 new) + walk / idle animations.
2. Meta systems: character level + enhance, equipment + crafting, bond, dorm, expedition (data, save, logic).
3. UI reskin + navigation bar (Academy, Characters, Rift, Expedition, Codex).
4. Academy hub map with tap-to-open buildings, construction mode and timers (+ ad hooks).
5. 5 locations x 5 danger, per-location tilesets / enemies / bosses, codex, quests.
6. Audio.

Every phase: tests, push, APK check, a test list for Syifa, and a PixelLab credit report.

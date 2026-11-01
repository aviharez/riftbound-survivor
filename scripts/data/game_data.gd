class_name GameData
extends RefCounted
## All tunable numbers and content tables for the Rift run live here.
## Add an item / enemy / shrine by adding a row; no system code needs to change.

const TILE := 16
const MAP_W := 160
const MAP_H := 160
const RUN_TIME := 600.0            # 10:00 countdown
const MAX_ENEMIES := 220

# --- VFX quality (lower these if a phone struggles) ---
const VFX_GLOW := true              # HDR bloom
const VFX_GLOW_INTENSITY := 0.9
const VFX_GLOW_THRESHOLD := 1.0      # only light brighter than this blooms
const VFX_LIGHT_BOOST := 1.7         # sprite-effect light layers are multiplied by this into HDR
const VFX_PROJECTILE_LIGHT := 1.6    # light layer of player shots
const VFX_PARTICLE_SCALE := 1.0     # 0.5 halves particle counts
const VFX_SHAKE := 1.0              # camera shake multiplier (0 = off)
const FOG_REVEAL_TILES := 11.0

# Tile ids
const T_GRASS := 0
const T_WALL := 1
const T_RIFT := 2
const T_RUINS := 3

# --- Map placement rules (tiles) ---
const SPAWN_EDGE_MIN := 12
const PORTAL_MIN_DIST := 70
const PORTAL_EDGE_MIN := 10
const CHEST_COUNT := 32
const CHEST_SPACING := 9
const CHEST_SPAWN_MIN := 8
const SHRINE_COUNT := 18
const SHRINE_SPACING := 11
const SHRINE_MAX_PER_TYPE := 6
# Placed first on every map, so these always exist (2 Aether Wells = gem pull is always findable)
const SHRINE_GUARANTEED := ["ley", "ley", "ley", "well", "well", "trial", "moon"]
const POT_COUNT := 120
const POT_SPACING := 3

# --- Timeline (seconds elapsed) ---
const ELITE_START := 60.0
const ELITE_INTERVAL := 60.0
const SURGE_DURATION := 30.0
const SURGE_WARNING := 5.0
const SURGES := [
	{"at": 150.0, "mult": 4.0, "elites": 0},
	{"at": 300.0, "mult": 5.0, "elites": 2},
	{"at": 450.0, "mult": 6.0, "elites": 3},
]
const SPAWN_RATE_START := 0.8
const SPAWN_RATE_END := 6.0
const HP_SCALE_PER_MIN := 0.15
# Final Swarm: endless and climbing. Every FINAL_SWARM_LEVEL_TIME seconds the swarm level goes up;
# each level multiplies (1 + per_level * level) on spawn rate, enemy HP and contact damage, and adds
# speed. Within a level the numbers also ramp smoothly, so it never plateaus. Wraiths (ghosts that
# ignore walls) make up a growing share of the spawns.
const FINAL_SWARM_RATE := 9.0
const FINAL_SWARM_LEVEL_TIME := 60.0
const FINAL_SWARM_RATE_PER_LEVEL := 0.45
const FINAL_SWARM_HP_PER_LEVEL := 0.35
const FINAL_SWARM_DMG_PER_LEVEL := 0.25
const FINAL_SWARM_SPEED_PER_LEVEL := 0.10
const FINAL_SWARM_SPEED_MAX := 2.0
const FINAL_SWARM_WRAITH_START := 0.35
const FINAL_SWARM_WRAITH_PER_LEVEL := 0.12
const FINAL_SWARM_WRAITH_MAX := 0.85
const FINAL_SWARM_MAX_ENEMIES := 300
# Difficulty meter (HUD): run threat rises with time, curse/avarice and swarm level.
# One name per threat step; the last one repeats with a growing number.
const THREAT_NAMES := ["Calm", "Uneasy", "Restless", "Hostile", "Dangerous", "Brutal", "Deadly", "Nightmare", "Cataclysm", "Doomed"]
const BOSS_ALIVE_SPAWN_MULT := 0.4
const DEFEAT_REWARD_SHARE := 0.5

# --- Economy ---
const CHEST_BASE_PRICE := 25.0
const CHEST_PRICE_GROWTH := 1.4
const RARITY_NAMES := ["Common", "Rare", "Epic", "Legendary"]
const RARITY_COLORS := [Color(0.92, 0.92, 0.92), Color(0.36, 0.62, 1.0), Color(0.78, 0.42, 1.0), Color(1.0, 0.8, 0.25)]
const RARITY_WEIGHTS := [70.0, 22.0, 7.0, 1.0]

# mods: [[stat, value], ...] — stats are defined in player.gd
const ITEMS := [
	{"id": "aether_lens", "name": "Aether Lens", "rarity": 0, "desc": "+8% damage", "mods": [["damage_pct", 0.08]]},
	{"id": "swift_ribbon", "name": "Swift Ribbon", "rarity": 0, "desc": "+7% move speed", "mods": [["speed_pct", 0.07]]},
	{"id": "mana_coil", "name": "Mana Coil", "rarity": 0, "desc": "+10% attack speed", "mods": [["attack_speed_pct", 0.10]]},
	{"id": "ward_charm", "name": "Ward Charm", "rarity": 0, "desc": "+15 max HP", "mods": [["max_hp", 15.0]]},
	{"id": "lodestone", "name": "Lodestone", "rarity": 0, "desc": "+25% pickup radius", "mods": [["pickup_pct", 0.25]]},
	{"id": "gilded_seal", "name": "Gilded Seal", "rarity": 1, "desc": "+20% gold", "mods": [["gold_pct", 0.20]]},
	{"id": "clover_pin", "name": "Clover Pin", "rarity": 1, "desc": "+10 Luck", "mods": [["luck", 10.0]]},
	{"id": "moss_vial", "name": "Moss Vial", "rarity": 1, "desc": "+0.6 HP/s regen", "mods": [["regen", 0.6]]},
	{"id": "bounce_rune", "name": "Bounce Rune", "rarity": 1, "desc": "+1 projectile bounce", "mods": [["bounce", 1.0]]},
	{"id": "prism_shard", "name": "Prism Shard", "rarity": 2, "desc": "+10% crit chance", "mods": [["crit", 0.10]]},
	{"id": "twin_sigil", "name": "Twin Sigil", "rarity": 2, "desc": "+1 projectile", "mods": [["projectiles", 1.0]]},
	{"id": "rift_heart", "name": "Rift Heart", "rarity": 3, "desc": "+25% damage, +25% area", "mods": [["damage_pct", 0.25], ["area_pct", 0.25]]},
]

# --- Tomes (Megabonk-style) ---
# Level-up offers 3 cards. A card is either a NEW tome (only while a tome slot is free),
# +1 level on a tome you own, or the Frost Nova weapon (unlock / level up).
# Each card rolls a rarity (Luck helps); rarity multiplies that level's gain.
# Like Megabonk, runs start with 2 tome slots and 2 weapon slots (Arcane Bolt always
# takes one weapon slot). Academy buildings unlock up to 4 + 4 (see BUILDINGS).
const BASE_TOME_SLOTS := 2
const BASE_WEAPON_SLOTS := 2
const MAX_SLOTS := 4
const OFFER_RARITY_MULT := [1.0, 1.4, 1.8, 2.5]
# stat: player stat key ("curse" = run difficulty). per: gain per level at Common.
# int: gain is rounded to a whole number (min 1). label: shown after the number.
const TOMES := [
	{"id": "power", "name": "Tome of Power", "stat": "damage_pct", "per": 0.08, "max": 99, "weight": 10.0, "label": "damage"},
	{"id": "haste", "name": "Tome of Haste", "stat": "attack_speed_pct", "per": 0.08, "max": 99, "weight": 10.0, "label": "attack speed"},
	{"id": "multitude", "name": "Tome of Multitude", "stat": "projectiles", "per": 1.0, "int": true, "max": 8, "weight": 6.0, "label": "projectile"},
	{"id": "expanse", "name": "Tome of Expanse", "stat": "area_pct", "per": 0.10, "max": 99, "weight": 7.0, "label": "area"},
	{"id": "swiftness", "name": "Tome of Swiftness", "stat": "speed_pct", "per": 0.06, "max": 99, "weight": 7.0, "label": "move speed"},
	{"id": "vitality", "name": "Tome of Vitality", "stat": "max_hp", "per": 20.0, "max": 99, "weight": 7.0, "label": "max HP"},
	{"id": "mending", "name": "Tome of Mending", "stat": "regen", "per": 0.4, "max": 99, "weight": 5.0, "label": "HP/s regen"},
	{"id": "fortune", "name": "Tome of Fortune", "stat": "luck", "per": 6.0, "max": 99, "weight": 6.0, "label": "Luck"},
	{"id": "study", "name": "Tome of Study", "stat": "xp_pct", "per": 0.07, "max": 99, "weight": 6.0, "label": "XP gain"},
	{"id": "attraction", "name": "Tome of Attraction", "stat": "pickup_pct", "per": 0.25, "max": 99, "weight": 5.0, "label": "pickup radius"},
	{"id": "precision", "name": "Tome of Precision", "stat": "crit", "per": 0.04, "max": 99, "weight": 6.0, "label": "crit chance"},
	{"id": "greed", "name": "Tome of Greed", "stat": "gold_pct", "per": 0.10, "max": 99, "weight": 5.0, "label": "gold"},
	{"id": "ricochet", "name": "Tome of Ricochet", "stat": "bounce", "per": 1.0, "int": true, "max": 6, "weight": 5.0, "label": "bounce"},
	{"id": "cursed", "name": "Cursed Tome", "stat": "curse", "per": 0.035, "max": 99, "weight": 3.0, "label": "difficulty (more foes, more XP)"},
]
const PCT_STATS := ["damage_pct", "attack_speed_pct", "area_pct", "speed_pct", "xp_pct", "pickup_pct", "crit", "gold_pct", "curse"]

# --- Weapons ---
# Every weapon levels 1..max through level-up cards. Per level: damage x(1 + lvl_dmg*(lv-1)),
# cooldown /(1 + lvl_cd*(lv-1)), size x(1 + lvl_area*(lv-1)); `count_at` lists the levels
# that add +1 to the weapon's count (projectiles / orbs / chain jumps).
# dmg is a multiplier of the player's damage. The player's "projectiles" stat
# (Tome of Multitude, Twin Sigil) adds to the count of weapons with uses_projectiles.
const WEAPON_MAX_LEVEL := 8
const WEAPONS := [
	# Attack types follow docs "Riftbound Weapon Attack Design" (prototype set of 8).
	# Projectile weapons: speed (px/s), life (s), hit_r (px), fx_scale; bounce / pierce add to the shot.
	{"id": "bolt", "name": "Arcane Bolt", "weight": 8.0,
		"desc": "Fast homing bolt that curves after its foe, then ricochets", "level_desc": "+20% damage, faster casts, more bolts at Lv 4/7",
		"cd": 0.8, "dmg": 1.0, "range": 220.0, "count": 1, "count_at": [4, 7], "uses_projectiles": true,
		"speed": 330.0, "life": 1.2, "hit_r": 4.0, "fx_scale": 0.6, "bounce": 1, "homing": 7.0,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.0},
	{"id": "flame", "name": "Flame Orb", "weight": 7.0,
		"desc": "Big slow fireball: bounces off foes AND walls, bursting into flame on every hit", "level_desc": "+20% damage, +1 ricochet at Lv 3/5/7",
		"cd": 1.0, "dmg": 1.2, "range": 220.0, "count": 1, "count_at": [6], "uses_projectiles": true,
		"speed": 165.0, "life": 1.8, "hit_r": 7.5, "fx_scale": 1.05, "bounce": 2, "bounce_at": [3, 5, 7],
		"wall_bounce": true, "splash_r": 18.0, "splash": 0.5,
		"lvl_dmg": 0.2, "lvl_cd": 0.04, "lvl_area": 0.04},
	{"id": "chain", "name": "Chain Lightning", "weight": 7.0,
		"desc": "Lightning that jumps between foes", "level_desc": "+20% damage, more jumps at Lv 3/5/7",
		"cd": 1.6, "dmg": 0.9, "range": 180.0, "jump_range": 90.0, "count": 3, "count_at": [3, 5, 7], "uses_projectiles": true,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.0},
	{"id": "meteor", "name": "Meteor Fall", "weight": 7.0,
		"desc": "Marks foes, then meteors crash onto the marks", "level_desc": "+20% damage, bigger blast, more meteors at Lv 4/7",
		"cd": 2.6, "dmg": 2.4, "radius": 30.0, "range": 210.0, "count": 1, "count_at": [4, 7], "delay": 0.5,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.06},
	{"id": "blades", "name": "Astral Blades", "weight": 7.0,
		"desc": "Spectral swords circle you and cut what they touch", "level_desc": "+20% damage, more blades at Lv 3/5/7",
		"cd": 0.5, "dmg": 0.5, "radius": 9.0, "blade_len": 22.0, "count": 2, "count_at": [3, 5, 7], "uses_projectiles": true,
		"spin": 4.0, "trail_arc": 1.5, "lvl_dmg": 0.2, "lvl_cd": 0.0, "lvl_area": 0.05},
	{"id": "void", "name": "Void Well", "weight": 6.0,
		"desc": "A singularity pulls foes in, then detonates", "level_desc": "+20% damage, wider pull, faster casts",
		"cd": 4.0, "dmg": 2.0, "radius": 46.0, "range": 160.0, "pull": 70.0, "duration": 1.3, "tick_dmg": 0.25,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.07},
	{"id": "lance", "name": "Frost Lance", "weight": 7.0,
		"desc": "Ice spear that pierces foes and leaves shards", "level_desc": "+20% damage, +1 pierce at Lv 3/5/7",
		"cd": 1.4, "dmg": 1.6, "range": 240.0, "count": 1, "count_at": [6], "uses_projectiles": true,
		"speed": 330.0, "life": 1.0, "hit_r": 5.0, "fx_scale": 0.42, "pierce": 3, "pierce_at": [3, 5, 7],
		"slow": 1.2, "lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.0},
	{"id": "seed", "name": "Thornseed", "weight": 7.0,
		"desc": "Seeds that burst into thorny roots on hit", "level_desc": "+20% damage, bigger root patch, more seeds at Lv 4/7",
		"cd": 1.3, "dmg": 0.8, "range": 200.0, "count": 1, "count_at": [4, 7], "uses_projectiles": true,
		"speed": 200.0, "life": 1.2, "hit_r": 5.0, "fx_scale": 0.8,
		"root_r": 20.0, "root_time": 1.6, "tick_dmg": 0.3, "slow": 0.6,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.06},
	# --- Alpha set: attack types the prototype did not have (doc sections C, D, E, F, B).
	{"id": "slash", "name": "Crescent Slash", "weight": 7.0,
		"desc": "A crescent of moonlight flies out, cutting through every foe", "level_desc": "+20% damage, bigger crescent, more slashes at Lv 4/7",
		"cd": 1.2, "dmg": 1.5, "range": 220.0, "count": 1, "count_at": [4, 7], "uses_projectiles": true,
		"speed": 230.0, "life": 0.85, "hit_r": 13.0, "fx_scale": 0.85, "pierce": 999, "grow": 0.5, "spread": 0.4,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.07},
	{"id": "chakram", "name": "Rune Chakram", "weight": 7.0,
		"desc": "A spinning rune disc flies out and returns, cutting both ways", "level_desc": "+20% damage, faster throws, more discs at Lv 4/7",
		"cd": 1.6, "dmg": 1.1, "range": 220.0, "count": 1, "count_at": [4, 7], "uses_projectiles": true,
		"speed": 250.0, "out_time": 0.55, "life": 3.0, "hit_r": 8.0, "fx_scale": 0.75, "pierce": 999, "spread": 0.5,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.05},
	{"id": "familiar", "name": "Arcane Familiar", "short": "Fam", "weight": 6.0,
		"desc": "A little crystal familiar floats beside you and shoots foes", "level_desc": "+20% damage, faster shots, another familiar at Lv 4/7",
		"cd": 0.9, "dmg": 0.7, "range": 210.0, "count": 1, "count_at": [4, 7],
		"speed": 300.0, "life": 0.8, "hit_r": 3.5, "fx_scale": 0.42, "bounce": 0,
		"orbit_r": 32.0, "orbit_speed": 0.9, "hover": 13.0,
		"lvl_dmg": 0.2, "lvl_cd": 0.06, "lvl_area": 0.0},
	{"id": "beam", "name": "Aether Beam", "weight": 6.0,
		"desc": "A straight beam of aether burns through a whole line of foes", "level_desc": "+20% damage, wider and longer beam, a second beam at Lv 5",
		"cd": 1.8, "dmg": 1.7, "range": 230.0, "length": 230.0, "width": 7.0, "count": 1, "count_at": [5], "uses_projectiles": true,
		"show_time": 0.3,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.06},
	{"id": "venom", "name": "Venom Bloom", "weight": 6.0,
		"desc": "Lobs a poison cloud onto foes that eats away at them", "level_desc": "+20% damage, bigger cloud, more clouds at Lv 4/7",
		"cd": 3.0, "dmg": 0.45, "range": 170.0, "radius": 30.0, "duration": 3.0, "tick": 0.4, "count": 1, "count_at": [4, 7],
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.07},
	{"id": "mine", "name": "Arcane Mine", "short": "Min", "weight": 6.0,
		"desc": "Drops runes on the floor that blow up when foes step close", "level_desc": "+20% damage, bigger blast, more runes at Lv 4/7",
		"cd": 1.5, "dmg": 2.6, "radius": 34.0, "trigger": 16.0, "arm": 0.5, "mine_life": 15.0, "max_mines": 8,
		"drop_min": 16.0, "drop_max": 40.0, "count": 1, "count_at": [4, 7],
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.06},

	# --- Evolutions (doc "Evolution" lines). A base weapon at EVOLVE_LEVEL plus its tome (any level)
	# turns into its evolution in the next chest opened. Evolved rows never level (lvl_* = 0) and are
	# never offered on level-up (weight 0): their numbers are the final values. For comparison, base
	# Lv 8 is about 2.4x base dmg and 1.35x faster casts.
	{"id": "prism", "name": "Prismatic Barrage", "evolved": true, "from": "bolt", "tome": "multitude", "weight": 0.0,
		"desc": "Volleys of elemental bolts (arcane, fire, ice, nature) that ricochet",
		"cd": 0.55, "dmg": 2.4, "range": 230.0, "count": 6, "uses_projectiles": true,
		"speed": 290.0, "life": 1.3, "hit_r": 4.5, "fx_scale": 0.62, "bounce": 2,
		"fire_splash_r": 16.0, "fire_splash": 0.4, "slow": 0.8,
		"lvl_dmg": 0.0, "lvl_cd": 0.0, "lvl_area": 0.0},
	{"id": "solar", "name": "Solar Cataclysm", "evolved": true, "from": "flame", "tome": "ricochet", "weight": 0.0,
		"desc": "A miniature sun ricochets, then detonates in a solar blast",
		"cd": 0.85, "dmg": 3.2, "range": 230.0, "count": 2, "uses_projectiles": true,
		"speed": 200.0, "life": 1.5, "hit_r": 8.0, "fx_scale": 0.3, "bounce": 6,
		"burst_r": 44.0, "burst_dmg": 2.0, "wall_bounce": true,
		"lvl_dmg": 0.0, "lvl_cd": 0.0, "lvl_area": 0.0},
	{"id": "storm", "name": "Thunderstorm Network", "evolved": true, "from": "chain", "tome": "haste", "weight": 0.0,
		"desc": "Several storms strike at once and chain across the whole pack",
		"cd": 1.1, "dmg": 2.4, "range": 230.0, "jump_range": 110.0, "count": 3, "jumps": 7, "uses_projectiles": true,
		"lvl_dmg": 0.0, "lvl_cd": 0.0, "lvl_area": 0.0},
	{"id": "starfall", "name": "Starfall", "evolved": true, "from": "meteor", "tome": "expanse", "weight": 0.0,
		"desc": "A rain of meteors strikes marked foes one after another",
		"cd": 2.0, "dmg": 6.0, "radius": 40.0, "range": 240.0, "count": 8, "delay": 0.5, "stagger": 0.12,
		"lvl_dmg": 0.0, "lvl_cd": 0.0, "lvl_area": 0.0},
	{"id": "halo", "name": "Blade Halo", "evolved": true, "from": "blades", "tome": "vitality", "weight": 0.0,
		"desc": "A halo of swords circles you and hurls blades at foes",
		"cd": 0.45, "dmg": 1.4, "radius": 13.0, "blade_len": 30.0, "count": 6, "uses_projectiles": true,
		"spin": 4.5, "trail_arc": 0.7,   # shorter trails: 6 blades with full trails merge into one bright disc
		"launch_cd": 0.8, "launch_dmg": 2.0, "launch_range": 210.0, "speed": 340.0, "life": 0.75, "hit_r": 6.0,
		"fx_scale": 1.15, "pierce": 5,
		"lvl_dmg": 0.0, "lvl_cd": 0.0, "lvl_area": 0.0},
	{"id": "horizon", "name": "Event Horizon", "evolved": true, "from": "void", "tome": "attraction", "weight": 0.0,
		"desc": "A vast singularity drags whole packs in before it collapses",
		"cd": 2.8, "dmg": 6.0, "radius": 95.0, "range": 180.0, "pull": 170.0, "duration": 2.2, "tick_dmg": 0.3,
		"lvl_dmg": 0.0, "lvl_cd": 0.0, "lvl_area": 0.0},
	{"id": "zero", "name": "Absolute Zero", "evolved": true, "from": "lance", "tome": "precision", "weight": 0.0,
		"desc": "Ice spears pierce a line, then burst into crystals that freeze",
		"cd": 1.0, "dmg": 4.2, "range": 250.0, "count": 2, "uses_projectiles": true,
		"speed": 340.0, "life": 0.9, "hit_r": 6.0, "fx_scale": 0.6, "pierce": 8,
		"slow": 1.5, "burst_r": 42.0, "burst_dmg": 1.0, "freeze": 1.6,
		"lvl_dmg": 0.0, "lvl_cd": 0.0, "lvl_area": 0.0},
	{"id": "worldroot", "name": "Worldroot Bloom", "evolved": true, "from": "seed", "tome": "mending", "weight": 0.0,
		"desc": "Seeds burst into spreading roots that trap whole packs",
		"cd": 0.95, "dmg": 2.2, "range": 210.0, "count": 3, "uses_projectiles": true,
		"speed": 210.0, "life": 1.2, "hit_r": 5.0, "fx_scale": 1.0,
		"root_r": 32.0, "root_time": 2.6, "tick_dmg": 0.35, "slow": 0.6, "branches": 2, "trap": 0.9,
		"lvl_dmg": 0.0, "lvl_cd": 0.0, "lvl_area": 0.0},
]
# Base weapon level needed to evolve (lower this if Lv 8 is rarely reached in real runs).
const EVOLVE_LEVEL := WEAPON_MAX_LEVEL
# Freeze (Absolute Zero, Worldroot traps): frozen foes stop and deal no contact damage.
# Bosses are never frozen; they are slowed instead.
const FROZEN_TINT := Color(0.55, 1.05, 1.6)
const ROOTED_TINT := Color(0.75, 1.3, 0.6)   # foes inside a Thornseed / Worldroot snare
const ROOT_TRAP_COOLDOWN := 2.5   # a foe can be root-trapped again after this many seconds


## The evolution row whose "from" is base_id ({} if none).
static func evolution_of(base_id: String) -> Dictionary:
	for w in WEAPONS:
		if w.get("from", "") == base_id:
			return w
	return {}


## Level-up card hint for an evolution combo, shown only when the player already owns the OTHER half
## (Syifa: a card stays plain while neither half is owned).
## kind "weapon": the paired tome is owned -> "COMBO: ..." (on every level of that weapon, it is working toward
## EVOLVE_LEVEL). kind "tome": only for a NEW tome, when an owned, not yet evolved weapon pairs with it.
## owned_weapons / owned_tomes: id -> level. Returns "" when there is nothing to say.
static func combo_hint(kind: String, id: String, owned_weapons: Dictionary, owned_tomes: Dictionary) -> String:
	if kind == "weapon":
		var evo := evolution_of(id)
		if evo.is_empty() or int(owned_tomes.get(evo["tome"], 0)) <= 0:
			return ""
		return "COMBO + %s (owned)\n-> %s at Lv %d" % [tome_by_id(evo["tome"])["name"], evo["name"], EVOLVE_LEVEL]
	if int(owned_tomes.get(id, 0)) > 0:
		return ""
	var lines: Array = []
	for w in WEAPONS:
		if w.get("tome", "") == id and owned_weapons.has(w["from"]) and not owned_weapons.has(w["id"]):
			lines.append("COMBO + %s (owned)\n-> %s at Lv %d" % [weapon_by_id(w["from"])["name"], w["name"], EVOLVE_LEVEL])
	return "\n".join(lines)


static func weapon_by_id(id: String) -> Dictionary:
	for w in WEAPONS:
		if w["id"] == id:
			return w
	return {}


## +1 per level threshold reached in w[key] (e.g. "bounce_at", "pierce_at").
static func weapon_bonus(w: Dictionary, key: String, lv: int) -> int:
	var n := 0
	for at in w.get(key, []):
		if lv >= int(at):
			n += 1
	return n


static func weapon_count(w: Dictionary, lv: int, extra_projectiles: int) -> int:
	var n: int = int(w.get("count", 1))
	for at in w.get("count_at", []):
		if lv >= int(at):
			n += 1
	if w.get("uses_projectiles", false):
		n += extra_projectiles
	return n


# --- Playable characters ---
# base: stat overrides on top of Player.stats defaults. starter: weapon that takes slot 1.
# per_level: passive mods applied on every level-up (the character's growth identity).
# colors: placeholder palette used until the character's sprite files exist.
# role: their place in the academy (Syifa: characters fit the magic-academy theme: students and teachers).
# unlock: building id whose restoration brings the character back ("" = available from the start).
# trait: mechanical passive (TRAITS below); per_level: small stat growth on every level-up.
const CHARACTERS := [
	{"id": "astra", "name": "Astra", "role": "New Student", "school": "Arcana", "starter": "bolt", "unlock": "",
		"base": {"max_hp": 100.0, "speed": 90.0, "damage": 10.0, "crit": 0.05},
		"trait": "arcane_echo", "passive": "Arcane Echo", "passive_desc": "Critical hits arc to a nearby foe for 50% damage. +1% crit per level",
		"per_level": [["crit", 0.01]],
		"colors": {"robe": Color(0.12, 0.18, 0.4), "hair": Color(0.85, 0.88, 0.95), "accent": Color(0.4, 1.0, 1.0)}},
	{"id": "lyra", "name": "Lyra", "role": "Duel Club Champion", "school": "Pyromancy", "starter": "flame", "unlock": "",
		"base": {"max_hp": 85.0, "speed": 96.0, "damage": 12.0, "area_pct": 0.10},
		"trait": "kindling", "passive": "Kindling", "passive_desc": "Foes you kill have a 25% chance to burst into flame. +2% damage per level",
		"per_level": [["damage_pct", 0.02]],
		"colors": {"robe": Color(0.55, 0.08, 0.12), "hair": Color(1.0, 0.55, 0.7), "accent": Color(1.0, 0.6, 0.2)}},
	{"id": "kael", "name": "Kael", "role": "Academy Guard", "school": "Spellblade", "starter": "blades", "unlock": "",
		"base": {"max_hp": 150.0, "speed": 82.0, "damage": 10.0, "armor": 0.10},
		"trait": "retaliation", "passive": "Retaliation", "passive_desc": "When hit, a sword wave slashes foes around you. +1% damage reduction per level",
		"per_level": [["armor", 0.01]],
		"colors": {"robe": Color(0.16, 0.2, 0.42), "hair": Color(0.15, 0.2, 0.45), "accent": Color(0.85, 0.88, 0.95)}},
	{"id": "nym", "name": "Nym", "role": "Infirmary Healer", "school": "Herbology", "starter": "seed", "unlock": "",
		"base": {"max_hp": 95.0, "speed": 92.0, "damage": 9.0, "regen": 0.6, "luck": 10.0, "heal_pct": 0.5},
		"trait": "thornheal", "passive": "Thornheal", "passive_desc": "Foes that die while snared by roots heal you. Healing +50%, +0.12 HP/s per level",
		"per_level": [["regen", 0.12]],
		"colors": {"robe": Color(0.9, 0.95, 0.9), "hair": Color(0.55, 1.0, 0.8), "accent": Color(0.3, 0.9, 0.45)}},
	{"id": "selene", "name": "Selene", "role": "Student Council President", "school": "Cryomancy", "starter": "lance", "unlock": "frost_tower",
		"base": {"max_hp": 90.0, "speed": 92.0, "damage": 11.0, "crit": 0.03},
		"trait": "frostbite", "passive": "Frostbite", "passive_desc": "Slowed or frozen foes take +25% damage. +1.5% damage per level",
		"per_level": [["damage_pct", 0.015]],
		"colors": {"robe": Color(0.75, 0.85, 0.98), "hair": Color(0.88, 0.92, 1.0), "accent": Color(0.45, 0.8, 1.0)}},
	{"id": "noah", "name": "Noah", "role": "Alchemy Student", "school": "Alchemy", "starter": "venom", "unlock": "alchemy_lab",
		"base": {"max_hp": 100.0, "speed": 88.0, "damage": 10.0, "area_pct": 0.10},
		"trait": "plague", "passive": "Plague", "passive_desc": "Poisoned foes that die may spread a small poison cloud. +1% area per level",
		"per_level": [["area_pct", 0.01]],
		"colors": {"robe": Color(0.25, 0.3, 0.2), "hair": Color(0.35, 0.55, 0.25), "accent": Color(0.6, 1.0, 0.35)}},
	{"id": "raika", "name": "Raika", "role": "Weather Club Member", "school": "Tempestas", "starter": "chain", "unlock": "bell_tower",
		"base": {"max_hp": 85.0, "speed": 98.0, "damage": 10.0, "attack_speed_pct": 0.05},
		"trait": "static_charge", "passive": "Static Charge", "passive_desc": "Every 8 kills release a lightning bolt that jumps through 4 foes. +1% attack speed per level",
		"per_level": [["attack_speed_pct", 0.01]],
		"colors": {"robe": Color(0.95, 0.75, 0.2), "hair": Color(1.0, 0.85, 0.35), "accent": Color(0.6, 0.85, 1.0)}},
	{"id": "vesper", "name": "Vesper", "role": "Forbidden Wing Student", "school": "Gravimancy", "starter": "void", "unlock": "forbidden_archive",
		"base": {"max_hp": 95.0, "speed": 86.0, "damage": 11.0, "area_pct": 0.10},
		"trait": "gravity_pull", "passive": "Gravity Pull", "passive_desc": "Foes you kill may collapse, dragging and hurting the foes around them. +1% area per level",
		"per_level": [["area_pct", 0.01]],
		"colors": {"robe": Color(0.2, 0.12, 0.3), "hair": Color(0.3, 0.2, 0.45), "accent": Color(0.75, 0.45, 1.0)}},
	{"id": "wren", "name": "Wren", "role": "Library Assistant", "school": "Summoning", "starter": "familiar", "unlock": "library", "unlock_level": 2,
		"base": {"max_hp": 90.0, "speed": 92.0, "damage": 9.0, "xp_pct": 0.10},
		"trait": "page_guard", "passive": "Page Guard", "passive_desc": "A paper ward blocks one hit every 6 s. +2% XP gain per level",
		"per_level": [["xp_pct", 0.02]],
		"colors": {"robe": Color(0.8, 0.68, 0.5), "hair": Color(0.45, 0.28, 0.2), "accent": Color(0.5, 0.85, 1.0)}},
	{"id": "sera", "name": "Sera", "role": "Spellblade Instructor", "school": "Spellblade", "starter": "slash", "unlock": "duel_hall",
		"base": {"max_hp": 120.0, "speed": 94.0, "damage": 11.0, "armor": 0.05},
		"trait": "duelist", "passive": "Duelist", "passive_desc": "Elites and bosses take +30% damage. +1.5% damage per level",
		"per_level": [["damage_pct", 0.015]],
		"colors": {"robe": Color(0.2, 0.55, 0.55), "hair": Color(0.12, 0.12, 0.16), "accent": Color(0.6, 1.0, 0.95)}},
	{"id": "celeste", "name": "Celeste", "role": "Astronomy Professor", "school": "Astromancy", "starter": "meteor", "unlock": "observatory",
		"base": {"max_hp": 85.0, "speed": 84.0, "damage": 12.0, "luck": 10.0},
		"trait": "stargazer", "passive": "Stargazer", "passive_desc": "Every 5 s a falling star strikes a nearby foe. +1 Luck per level",
		"per_level": [["luck", 1.0]],
		"colors": {"robe": Color(0.15, 0.17, 0.35), "hair": Color(0.65, 0.78, 0.95), "accent": Color(1.0, 0.9, 0.5)}},
	{"id": "runa", "name": "Runa", "role": "Rune Master", "school": "Runecraft", "starter": "chakram", "unlock": "rune_workshop",
		"base": {"max_hp": 80.0, "speed": 96.0, "damage": 10.0, "pickup_pct": 0.20},
		"trait": "rune_ward", "passive": "Rune Ward", "passive_desc": "Foes you kill may leave a rune that explodes under the next foe. +1% attack speed per level",
		"per_level": [["attack_speed_pct", 0.01]],
		"colors": {"robe": Color(0.35, 0.18, 0.15), "hair": Color(0.92, 0.9, 0.9), "accent": Color(1.0, 0.6, 0.25)}},
	{"id": "lumi", "name": "Lumi", "role": "Aether Researcher", "school": "Aether", "starter": "beam", "unlock": "arcana_lab",
		"base": {"max_hp": 90.0, "speed": 90.0, "damage": 11.0, "crit": 0.03},
		"trait": "overflow", "passive": "Overflow", "passive_desc": "Overkill damage refracts into the nearest foe. +1% crit per level",
		"per_level": [["crit", 0.01]],
		"colors": {"robe": Color(0.92, 0.94, 0.96), "hair": Color(0.75, 0.6, 0.9), "accent": Color(0.5, 1.0, 0.95)}},
]
# Character traits (mechanical passives). Damage values are multiples of the player's damage.
const TRAITS := {
	"arcane_echo": {"mult": 0.5, "range": 70.0},                        # crit -> spark to one other foe
	"kindling": {"chance": 0.25, "radius": 22.0, "dmg": 1.0},           # kill -> flame burst
	"retaliation": {"radius": 42.0, "dmg": 1.6, "cooldown": 0.8},       # hurt -> sword wave
	"thornheal": {"heal": 1.0},                                         # snared foe dies -> heal
	"frostbite": {"mult": 1.25},                                        # slowed / frozen foes take more
	"plague": {"chance": 0.5, "poisoned_window": 1.0, "radius": 18.0, "duration": 1.6, "tick": 0.4, "dmg": 0.3},
	"static_charge": {"kills": 8, "jumps": 4, "range": 70.0, "jump_range": 60.0, "dmg": 1.5},   # every N kills -> chain bolt
	"gravity_pull": {"chance": 0.2, "radius": 40.0, "pull": 14.0, "dmg": 0.6},              # kill -> small implosion
	"page_guard": {"cooldown": 6.0},                                                        # blocks one hit per cooldown
	"duelist": {"mult": 1.3},                                                               # elites / bosses take more
	"stargazer": {"interval": 5.0, "range": 150.0, "radius": 22.0, "delay": 0.55, "dmg": 1.6},  # timed falling star
	"rune_ward": {"chance": 0.15, "radius": 28.0, "trigger": 12.0, "arm": 0.4, "life": 7.0, "dmg": 1.3, "max": 4},
	"overflow": {"min": 1.0, "range": 60.0},                                                # overkill -> nearest foe
}
const ARMOR_CAP := 0.5
# Speed multiplier of a slowed enemy (Frost Lance, Thornseed roots).
const SLOW_MULT := 0.5
# Hero sprites are drawn so the whole sprite canvas is this many world pixels tall
# (~2x a slime), whatever size the source art is (48 or 64 px).
# canvas_items stretch renders at the phone's native resolution, so this stays crisp.
const CHARACTER_SPRITE_HEIGHT := 33.0
# Sprite animation speeds (frames per second) for the walk / idle strips in assets/characters/<id>/<anim>/.
const CHARACTER_WALK_FPS := 10.0
const CHARACTER_IDLE_FPS := 5.0


static func character_by_id(id: String) -> Dictionary:
	for c in CHARACTERS:
		if c["id"] == id:
			return c
	return CHARACTERS[0]


# --- Academy (meta progression, saved between runs) ---
# Level names follow the concept doc's building progression.
const BUILDING_STATES := ["Ruins", "Repaired", "Functional"]
# unlocks: "tome" / "weapon" (+1 slot per level), "character" (Lv 1 brings back `character`),
# "lessons" (the Staff Room: teachers sell permanent upgrades, LESSONS below; each level raises the rank cap).
const BUILDINGS := [
	{"id": "library", "name": "Library", "unlocks": "tome", "desc": "Restored shelves of spell tomes: +1 tome slot per level",
		"costs": [{"gold": 400, "materials": 60, "aether": 0}, {"gold": 1200, "materials": 180, "aether": 20}]},
	{"id": "training", "name": "Training Ground", "unlocks": "weapon", "desc": "Practice yards for combat magic: +1 weapon slot per level",
		"costs": [{"gold": 350, "materials": 80, "aether": 0}, {"gold": 1100, "materials": 220, "aether": 20}]},
	{"id": "staff_room", "name": "Staff Room", "unlocks": "lessons", "desc": "The teachers return and give lessons: permanent upgrades",
		"costs": [{"gold": 500, "materials": 90, "aether": 0}, {"gold": 1400, "materials": 240, "aether": 25}]},
	{"id": "frost_tower", "name": "Frost Tower", "unlocks": "character", "character": "selene",
		"desc": "The Cryomancy tower thaws out: Selene, the Student Council President, returns",
		"costs": [{"gold": 700, "materials": 140, "aether": 10}]},
	{"id": "alchemy_lab", "name": "Alchemy Lab", "unlocks": "character", "character": "noah",
		"desc": "Cauldrons bubble again: Noah, the alchemy student, returns",
		"costs": [{"gold": 900, "materials": 180, "aether": 20}]},	{"id": "bell_tower", "name": "Bell Tower", "unlocks": "character", "character": "raika",
		"desc": "The storm bell rings again: Raika of the Weather Club returns",
		"costs": [{"gold": 800, "materials": 160, "aether": 15}]},
	{"id": "duel_hall", "name": "Duel Hall", "unlocks": "character", "character": "sera",
		"desc": "The duelling floor is swept clean: Sera, the Spellblade instructor, returns",
		"costs": [{"gold": 1000, "materials": 200, "aether": 20}]},
	{"id": "observatory", "name": "Observatory", "unlocks": "character", "character": "celeste",
		"desc": "The great telescope turns again: Professor Celeste returns (eventually wakes up)",
		"costs": [{"gold": 1100, "materials": 220, "aether": 25}]},
	{"id": "rune_workshop", "name": "Rune Workshop", "unlocks": "character", "character": "runa",
		"desc": "Rune presses hum back to life: Runa, the tiny rune master, returns",
		"costs": [{"gold": 1100, "materials": 240, "aether": 25}]},
	{"id": "arcana_lab", "name": "Arcana Lab", "unlocks": "character", "character": "lumi",
		"desc": "Aether lenses are polished: Lumi, the aether researcher, returns",
		"costs": [{"gold": 1300, "materials": 260, "aether": 30}]},
	{"id": "forbidden_archive", "name": "Forbidden Archive", "unlocks": "character", "character": "vesper",
		"desc": "The sealed wing opens: Vesper wanders out, still half asleep",
		"costs": [{"gold": 1500, "materials": 300, "aether": 40}]},
]
# Staff Room lessons: permanent run bonuses bought with EXP (+ gold). Rank cap = LESSON_RANKS_PER_LEVEL x Staff Room level.
const LESSON_RANKS_PER_LEVEL := 3
const LESSON_COST_EXP := 120.0      # rank 1; each next rank costs LESSON_COST_GROWTH times more
const LESSON_COST_GOLD := 60.0
const LESSON_COST_GROWTH := 1.5
const LESSONS := [
	{"id": "might", "name": "Battle Magic", "teacher": "Spellblade Instructor", "stat": "damage_pct", "per": 0.04, "label": "damage"},
	{"id": "vigor", "name": "Healing Arts", "teacher": "Infirmary Mistress", "stat": "max_hp", "per": 8.0, "label": "max HP"},
	{"id": "haste", "name": "Quick Casting", "teacher": "Arcana Professor", "stat": "attack_speed_pct", "per": 0.03, "label": "attack speed"},
	{"id": "stride", "name": "Fleet Foot", "teacher": "Groundskeeper", "stat": "speed_pct", "per": 0.03, "label": "move speed"},
	{"id": "fortune", "name": "Divination", "teacher": "Astronomy Professor", "stat": "luck", "per": 3.0, "label": "Luck"},
	{"id": "wisdom", "name": "Scholarship", "teacher": "Head Librarian", "stat": "xp_pct", "per": 0.05, "label": "XP gain"},
	{"id": "greed", "name": "Alchemy of Gold", "teacher": "Alchemy Master", "stat": "gold_pct", "per": 0.05, "label": "gold"},
	{"id": "magnet", "name": "Attraction Runes", "teacher": "Rune Master", "stat": "pickup_pct", "per": 0.10, "label": "pickup radius"},
]


static func lesson_by_id(id: String) -> Dictionary:
	for l in LESSONS:
		if l["id"] == id:
			return l
	return {}


## Cost of buying `rank` (1-based) of a lesson.
# --- Character progression (persistent, per character; saved in SaveData "characters") ---
# Character level: character EXP comes from runs played with that character (same amount as the academy EXP).
const CHAR_MAX_LEVEL := 30
const CHAR_EXP_FIRST := 120.0      # EXP from Lv 1 to Lv 2; each next level needs CHAR_EXP_GROWTH times more
const CHAR_EXP_GROWTH := 1.16
const CHAR_LEVEL_MODS := [["max_hp", 4.0], ["damage_pct", 0.02]]   # per level above 1, applied at run start
# Enhance: two tracks per character, paid with gold + Arcane Shards. Rank N needs character level
# N x ENHANCE_LEVEL_STEP. Passive = trait strength, signature = the starter weapon (and its evolution).
const ENHANCE_MAX := 5
const ENHANCE_LEVEL_STEP := 5
const ENHANCE_COST_GOLD := [250, 500, 900, 1500, 2400]     # rank 1..5
const ENHANCE_COST_SHARDS := [2, 4, 7, 11, 16]
const ENHANCE_TRAIT_PER_RANK := 0.15       # trait damage / heal / chance x (1 + 0.15 x rank), cooldowns / that
const ENHANCE_WEAPON_DMG := 0.08           # signature weapon damage +8% per rank
const ENHANCE_WEAPON_CD := 0.04            # signature weapon attack speed +4% per rank
# Arcane Shards from a run: the boss, plus one per ELITES_PER_SHARD elites killed (defeat keeps them all).
const SHARDS_BOSS := 3
const ELITES_PER_SHARD := 3


## Total character EXP needed to reach `level` (Lv 1 = 0).
static func char_exp_for(level: int) -> int:
	var total := 0.0
	for l in range(1, level):
		total += CHAR_EXP_FIRST * pow(CHAR_EXP_GROWTH, l - 1)
	return int(round(total))


## Character level for a total EXP amount (capped at CHAR_MAX_LEVEL).
static func char_level_for(exp: int) -> int:
	var lv := 1
	while lv < CHAR_MAX_LEVEL and exp >= char_exp_for(lv + 1):
		lv += 1
	return lv


## Stat mods of a character level ([[stat, value], ...]).
static func char_level_mods(level: int) -> Array:
	var out: Array = []
	for m in CHAR_LEVEL_MODS:
		out.append([m[0], float(m[1]) * (level - 1)])
	return out


## Cost of enhance rank `rank` (1..ENHANCE_MAX).
static func enhance_cost(rank: int) -> Dictionary:
	return {"gold": ENHANCE_COST_GOLD[rank - 1], "shards": ENHANCE_COST_SHARDS[rank - 1]}


static func lesson_cost(rank: int) -> Dictionary:
	var k := pow(LESSON_COST_GROWTH, rank - 1)
	return {"exp": int(round(LESSON_COST_EXP * k)), "gold": int(round(LESSON_COST_GOLD * k))}


static func building_by_id(id: String) -> Dictionary:
	for b in BUILDINGS:
		if b["id"] == id:
			return b
	return {}


# When every tome and weapon is maxed out
const LEVELUP_FALLBACK := [
	{"id": "fb_heal", "name": "Second Wind", "desc": "Heal 40% HP", "kind": "heal", "value": 0.4},
	{"id": "fb_gold", "name": "Aether Coins", "desc": "+20 gold", "kind": "gold", "value": 20.0},
]


static func tome_by_id(id: String) -> Dictionary:
	for t in TOMES:
		if t["id"] == id:
			return t
	return {}


## Gain for one tome level at a given offer rarity.
static func tome_gain(t: Dictionary, rarity: int) -> float:
	var g: float = float(t["per"]) * float(OFFER_RARITY_MULT[rarity])
	if t.get("int", false):
		g = max(1.0, round(g))
	return g


static func format_gain(t: Dictionary, gain: float) -> String:
	if t["stat"] in PCT_STATS:
		return "+%s%% %s" % [_num(gain * 100.0), t["label"]]
	return "+%s %s" % [_num(gain), t["label"]]


static func _num(v: float) -> String:
	return str(int(round(v))) if absf(v - round(v)) < 0.05 else "%.1f" % v


# Ley Shrine boons (pick 1 of 3)
const BOONS := [
	{"id": "b_dmg", "name": "Ley: Might", "desc": "+12% damage", "mods": [["damage_pct", 0.12]]},
	{"id": "b_spd", "name": "Ley: Haste", "desc": "+10% move speed", "mods": [["speed_pct", 0.10]]},
	{"id": "b_hp", "name": "Ley: Vigor", "desc": "+20 max HP", "mods": [["max_hp", 20.0]]},
	{"id": "b_aspd", "name": "Ley: Flow", "desc": "+10% attack speed", "mods": [["attack_speed_pct", 0.10]]},
	{"id": "b_luck", "name": "Ley: Fate", "desc": "+12 Luck", "mods": [["luck", 12.0]]},
	{"id": "b_crit", "name": "Ley: Focus", "desc": "+6% crit chance", "mods": [["crit", 0.06]]},
]

const SHRINE_TYPES := {
	"ley": {"name": "Ley Shrine", "weight": 30.0, "charge": 4.0, "color": Color(0.3, 0.85, 1.0)},
	"trial": {"name": "Trial Shrine", "weight": 20.0, "charge": 0.3, "color": Color(1.0, 0.45, 0.3)},
	"avarice": {"name": "Avarice Altar", "weight": 15.0, "charge": 1.0, "color": Color(1.0, 0.8, 0.2)},
	"well": {"name": "Aether Well", "weight": 15.0, "charge": 1.0, "color": Color(0.55, 1.0, 0.6)},
	"moon": {"name": "Moon Fountain", "weight": 20.0, "charge": 2.0, "color": Color(0.85, 0.85, 1.0)},
}
const TRIAL_DURATION := 45.0
const TRIAL_MINIONS := 12
const AVARICE_GOLD := 25
const AVARICE_DIFFICULTY := 0.05

const ENEMY_TYPES := {
	"slime": {"hp": 10.0, "speed": 38.0, "radius": 6.0, "dmg": 6.0, "min_time": 0.0, "weight": 10.0, "color": Color(0.55, 0.3, 0.85), "xp": 1},
	"bat": {"hp": 6.0, "speed": 70.0, "radius": 5.0, "dmg": 4.0, "min_time": 60.0, "weight": 5.0, "color": Color(0.35, 0.3, 0.5), "xp": 1},
	"brute": {"hp": 40.0, "speed": 28.0, "radius": 10.0, "dmg": 12.0, "min_time": 240.0, "weight": 3.0, "color": Color(0.5, 0.45, 0.4), "xp": 3},
	# Final Swarm only: fast ghosts that drift through walls (Megabonk-style swarm ghosts)
	"wraith": {"hp": 12.0, "speed": 78.0, "radius": 6.0, "dmg": 8.0, "min_time": 0.0, "weight": 0.0, "swarm_only": true,
		"color": Color(0.6, 0.85, 1.0), "xp": 1, "ghost": true},
	"caster": {"hp": 14.0, "speed": 34.0, "radius": 7.0, "dmg": 3.0, "min_time": 300.0, "weight": 3.0, "color": Color(0.85, 0.25, 0.55), "xp": 2, "ranged": true},
}
const ELITE_SCALE := 1.6
const ELITE_HP_MULT := 12.0
const ELITE_AFFIXES := ["swift", "warded", "splitter"]
const ELITE_GOLD := 8

const BOSS := {
	"name": "Corrupted Guardian", "hp": 2500.0, "radius": 22.0, "sprite_scale": 1.5, "speed": 35.0, "dmg": 20.0,
	"ring_bullets": 16, "bullet_speed": 90.0, "bullet_dmg": 10.0,
	"dash_telegraph": 0.8, "dash_speed": 400.0, "dash_time": 0.5, "summon": 6,
	"gap": 1.6, "gap_enraged": 0.9,
}
const PORTAL_CHARGE := 3.0
const PORTAL_SUMMON_DELAY := 2.0

static func chest_price(paid_opened: int) -> int:
	return int(round(CHEST_BASE_PRICE * pow(CHEST_PRICE_GROWTH, paid_opened)))


static func xp_to_next(level: int) -> float:
	return 5.0 + level * 4.0


## Rolls a rarity index. Luck moves weight away from Common into higher tiers.
static func roll_rarity(rng: RandomNumberGenerator, luck: float, min_rarity: int = 0) -> int:
	var w: Array = RARITY_WEIGHTS.duplicate()
	var shift: float = min(w[0] - 10.0, luck * 0.6)
	w[0] -= shift
	w[1] += shift * 0.6
	w[2] += shift * 0.3
	w[3] += shift * 0.1
	for i in range(min_rarity):
		w[i] = 0.0
	return weighted_index(rng, w)


static func weighted_index(rng: RandomNumberGenerator, weights: Array) -> int:
	var total := 0.0
	for x in weights:
		total += float(x)
	var r := rng.randf() * total
	for i in weights.size():
		r -= float(weights[i])
		if r <= 0.0:
			return i
	return weights.size() - 1


static func items_of_rarity(rarity: int) -> Array:
	var out: Array = []
	for it in ITEMS:
		if int(it["rarity"]) == rarity:
			out.append(it)
	return out

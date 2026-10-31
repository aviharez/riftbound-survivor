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
const FINAL_SWARM_RATE := 8.0
const FINAL_SWARM_STEP := 15.0     # every 15 s: +10% hp, +3% speed
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
	{"id": "bolt", "name": "Arcane Bolt", "starter": true, "weight": 8.0,
		"desc": "Homing magic bolt at the nearest foe", "level_desc": "+20% damage, faster casts",
		"cd": 0.8, "dmg": 1.0, "range": 220.0, "count": 1, "count_at": [4, 7], "uses_projectiles": true,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.0},
	{"id": "nova", "name": "Frost Nova", "weight": 7.0,
		"desc": "Pulse that hits all nearby foes", "level_desc": "+20% damage, wider, faster",
		"cd": 3.0, "dmg": 0.8, "radius": 60.0,
		"lvl_dmg": 0.2, "lvl_cd": 0.06, "lvl_area": 0.06},
	{"id": "orb", "name": "Flame Orb", "weight": 7.0,
		"desc": "Fire orbs circle you and burn what they touch", "level_desc": "+20% damage, more orbs at Lv 3/5/7",
		"cd": 0.5, "dmg": 0.45, "radius": 34.0, "count": 2, "count_at": [3, 5, 7], "uses_projectiles": true,
		"spin": 3.2, "lvl_dmg": 0.2, "lvl_cd": 0.0, "lvl_area": 0.05},
	{"id": "burst", "name": "Mana Burst", "weight": 7.0,
		"desc": "Explosion on a random foe nearby", "level_desc": "+20% damage, bigger blast",
		"cd": 2.4, "dmg": 2.2, "radius": 38.0, "range": 200.0,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.08},
	{"id": "chain", "name": "Storm Chain", "weight": 7.0,
		"desc": "Lightning that jumps between foes", "level_desc": "+20% damage, more jumps at Lv 3/5/7",
		"cd": 1.6, "dmg": 0.9, "range": 180.0, "jump_range": 90.0, "count": 3, "count_at": [3, 5, 7], "uses_projectiles": true,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.0},
	{"id": "blade", "name": "Spirit Blade", "weight": 7.0,
		"desc": "Wide slash in the direction you move", "level_desc": "+20% damage, longer reach",
		"cd": 1.2, "dmg": 1.5, "radius": 46.0, "arc": 2.1,
		"lvl_dmg": 0.2, "lvl_cd": 0.05, "lvl_area": 0.06},
]


static func weapon_by_id(id: String) -> Dictionary:
	for w in WEAPONS:
		if w["id"] == id:
			return w
	return {}


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
const CHARACTERS := [
	{"id": "astra", "name": "Astra", "role": "Mage", "starter": "bolt",
		"base": {"max_hp": 100.0, "speed": 90.0, "damage": 10.0, "crit": 0.05},
		"passive": "Arcane Focus", "passive_desc": "+1% crit chance per level", "per_level": [["crit", 0.01]],
		"colors": {"robe": Color(0.12, 0.18, 0.4), "hair": Color(0.85, 0.88, 0.95), "accent": Color(0.4, 1.0, 1.0)}},
	{"id": "lyra", "name": "Lyra", "role": "Fire Mage", "starter": "orb",
		"base": {"max_hp": 85.0, "speed": 96.0, "damage": 12.0, "area_pct": 0.10},
		"passive": "Kindling", "passive_desc": "+2% damage per level", "per_level": [["damage_pct", 0.02]],
		"colors": {"robe": Color(0.55, 0.08, 0.12), "hair": Color(1.0, 0.55, 0.7), "accent": Color(1.0, 0.6, 0.2)}},
	{"id": "kael", "name": "Kael", "role": "Knight", "starter": "blade",
		"base": {"max_hp": 150.0, "speed": 82.0, "damage": 10.0, "armor": 0.10},
		"passive": "Bulwark", "passive_desc": "+1% damage reduction per level (max 50%)", "per_level": [["armor", 0.01]],
		"colors": {"robe": Color(0.16, 0.2, 0.42), "hair": Color(0.15, 0.2, 0.45), "accent": Color(0.85, 0.88, 0.95)}},
	{"id": "nym", "name": "Nym", "role": "Healer", "starter": "nova",
		"base": {"max_hp": 95.0, "speed": 92.0, "damage": 9.0, "regen": 0.6, "luck": 10.0, "heal_pct": 0.5},
		"passive": "Verdant Grace", "passive_desc": "+0.12 HP/s regen per level; all healing +50%", "per_level": [["regen", 0.12]],
		"colors": {"robe": Color(0.9, 0.95, 0.9), "hair": Color(0.55, 1.0, 0.8), "accent": Color(0.3, 0.9, 0.45)}},
]
const ARMOR_CAP := 0.5
# Hero sprites are drawn so the whole sprite canvas is this many world pixels tall
# (~2x a slime), whatever size the source art is (48 or 64 px).
# canvas_items stretch renders at the phone's native resolution, so this stays crisp.
const CHARACTER_SPRITE_HEIGHT := 33.0


static func character_by_id(id: String) -> Dictionary:
	for c in CHARACTERS:
		if c["id"] == id:
			return c
	return CHARACTERS[0]


# --- Academy (meta progression, saved between runs) ---
# Level names follow the concept doc's building progression.
const BUILDING_STATES := ["Ruins", "Repaired", "Functional"]
const BUILDINGS := [
	{"id": "library", "name": "Library", "unlocks": "tome", "desc": "Restored shelves of spell tomes: +1 tome slot per level",
		"costs": [{"gold": 400, "materials": 60, "aether": 0}, {"gold": 1200, "materials": 180, "aether": 20}]},
	{"id": "training", "name": "Training Ground", "unlocks": "weapon", "desc": "Practice yards for combat magic: +1 weapon slot per level",
		"costs": [{"gold": 350, "materials": 80, "aether": 0}, {"gold": 1100, "materials": 220, "aether": 20}]},
]


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

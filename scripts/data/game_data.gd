class_name GameData
extends RefCounted
## All tunable numbers and content tables for the Rift run live here.
## Add an item / enemy / shrine by adding a row; no system code needs to change.

const TILE := 16
const MAP_W := 160
const MAP_H := 160
const RUN_TIME := 600.0            # 10:00 countdown
const MAX_ENEMIES := 220
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
# Megabonk starts with 2 tome slots and unlocks up to 4; here 4 for the prototype
# (later this can be gated by the academy Library).
const TOME_SLOTS := 4
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

# Weapons offered at level-up besides tomes. Arcane Bolt is the starting weapon.
const WEAPONS := [
	{"id": "nova", "name": "Frost Nova", "max": 8, "weight": 7.0,
		"unlock_desc": "New weapon: pulse that hits all nearby foes", "unlock_mods": [["nova", 1.0]],
		"level_desc": "+30% damage, pulses faster", "level_mods": [["nova_power", 1.0]]},
]
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
	"name": "Corrupted Guardian", "hp": 2500.0, "radius": 20.0, "speed": 35.0, "dmg": 20.0,
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

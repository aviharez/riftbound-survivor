class_name PixelSprites
extends RefCounted
## Hand-authored pixel art stored as character grids, turned into textures at
## runtime. Used for enemies and props until/unless generated art replaces them.
## Each palette letter maps to a colour; "." is transparent.

const PALETTES := {
	"slime": {"o": "#1d0b2e", "d": "#4a1f7a", "m": "#7d3fc4", "l": "#b07cf0", "w": "#f2e6ff", "e": "#ffe066", "p": "#2b0f45"},
	"bat": {"o": "#120c1c", "d": "#2e2440", "m": "#4b3d66", "l": "#6e5d91", "e": "#ff5a7a", "f": "#8a7ab0"},
	"brute": {"o": "#1a1612", "d": "#4a4038", "m": "#6e6255", "l": "#958877", "c": "#e04aff", "e": "#ff6a3a"},
	"caster": {"o": "#14070f", "d": "#4d0f2e", "m": "#8a1f4f", "l": "#c23a73", "s": "#2a1a12", "g": "#ff7ad9", "e": "#ffe0f0"},
	"wraith": {"o": "#0a1420", "d": "#2a4a6e", "m": "#5f9ac4", "l": "#a8dcf2", "w": "#eafaff", "e": "#ff3a5a"},
	"chest": {"o": "#120a1e", "d": "#3b2560", "m": "#5d3c8f", "l": "#8462bd", "g": "#d9b04a", "y": "#ffe9a3"},
	"chest_gold": {"o": "#2a1a05", "d": "#8a5a12", "m": "#c88a1e", "l": "#f0bf3c", "g": "#fff1b0", "y": "#ffffff"},
}

const GRIDS := {
	"slime": [
		"......oooo......",
		"....oolllloo....",
		"...ollwwllmmo...",
		"..olwwlllmmmmo..",
		".olllllmmmmmmmo.",
		".olmmmmmmmmmmmo.",
		"olmmeommmmeommdo",
		"olmmeemmmmeemmdo",
		"ommmmmmmppmmmddo",
		"odmmmmmmmmmmdddo",
		".oddmmmmmmmddddo",
		"..ooddddddddddo.",
		"....oooooooooo..",
	],
	"bat": [
		"o..............o",
		"oo............oo",
		"odo...o..o...odo",
		"odfo.oddddo.ofdo",
		"odffoddeeddoffdo",
		"oddffddmmddffddo",
		".odddddmmddddddo",
		"..oodddddddddoo.",
		"....oo.dd.oo....",
		"......o..o......",
	],
	"bat_up": [
		"......o..o......",
		"o....oddddo....o",
		"oo..oddeeddo..oo",
		"odoooddmmddoooddo",
		".odffddmmddffdo.",
		"..odfffddfffdo..",
		"...oooddddooo...",
		"......o..o......",
	],
	"brute": [
		".....oooooooo.....",
		"....ollllllllo....",
		"...ollmmmmmmllo...",
		"..olmmeemmeemmlo..",
		"..olmmmmmmmmmmlo..",
		".oolmmmcmmmmmmloo.",
		"ollllmmmcmmmmmllllo",
		"olmmlmmmmcmmmmlmmlo",
		"olmmloddmmcmddlmmlo",
		"oddmlommmmmcmolmddo",
		".oddooddddddddooddo",
		"..oo.odmmmmmdo.oo..",
		".....odmmodmmo.....",
		".....oddo.oddo.....",
		"....ooooo.ooooo....",
	],
	"wraith": [
		".....oooo.....",
		"...oollllo....",
		"..olwwllllo...",
		".olwwllllmmo..",
		".olleeolleemo.",
		"olllemlllemmo.",
		"ollllllllmmmdo",
		"olllmmllmmmmdo",
		".olmmmmmmmmddo",
		".olmmmmmmmdddo",
		"..olmmmmmddo..",
		"..odmmddmdo...",
		"...odo.odmo...",
		"....o...odo...",
		".........oo...",
	],
	"caster": [
		"......oo......",
		".....olmo.....",
		"....olmmmo....",
		"...olmooomo...",
		"...omoeoeoo.g.",
		"...omooooomogg",
		"..olmmmmmmmosg",
		"..olmmlmmmmos.",
		".olmmmlmmmmmo.",
		".olmmmlmmmmmo.",
		".odmmmlmmmmdo.",
		"odddmmlmmmddo.",
		"oddddddddddddo",
		".oooooooooooo.",
	],
	"chest": [
		"..oooooooooooo..",
		".ollllllllllllo.",
		"olmmmmmggmmmmmlo",
		"ogggggggyygggggo",
		"odmmmmmggmmmmmdo",
		"odmmmmogyommmmdo",
		"odmmmmmooommmmdo",
		"oddddddddddddddo",
		".oooooooooooooo.",
	],
}

static var _cache := {}


static func texture(name: String, palette := "") -> Texture2D:
	var key := name + ":" + palette
	if _cache.has(key):
		return _cache[key]
	var grid: Array = GRIDS[name]
	var pal: Dictionary = PALETTES[palette if palette != "" else name.get_slice("_", 0)]
	var w := 0
	for row in grid:
		w = max(w, String(row).length())
	var img := Image.create(w, grid.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var ch := row[x]
			if pal.has(ch):
				img.set_pixel(x, y, Color(pal[ch]))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

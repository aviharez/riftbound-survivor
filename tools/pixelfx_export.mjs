// Exports selected pixelfx effects (https://github.com/patch-gg/pixelfx, MIT) as
// Godot-ready sprite sheets. Each effect gets TWO sheets so the game can keep
// pixelfx's two-buffer look:
//   <name>_color.png  colour buffer, drawn with normal blending
//   <name>_light.png  light buffer, drawn additively (and boosted into HDR bloom)
// plus <name>.json with frame rects, fps, pivot and loop flag.
//
// Frames are cropped to the union of all non-empty pixels, rendered at a lower
// fps than the source, and trailing empty frames are dropped, to keep texture
// memory small on phones.
//
// usage: node tools/pixelfx_export.mjs /path/to/pixelfx assets/vfx
import { writeFileSync, mkdirSync } from "node:fs";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const [pixelfxDir, outDir] = process.argv.slice(2);
if (!pixelfxDir || !outDir) {
  console.error("usage: node tools/pixelfx_export.mjs <pixelfx dir> <out dir>");
  process.exit(1);
}
const lib = await import(pathToFileURL(resolve(pixelfxDir, "tools/lib/fxlib.mjs")).href);
const { encodePNG } = await import(pathToFileURL(resolve(pixelfxDir, "tools/lib/png.mjs")).href);

// name in game -> pixelfx id, fps, max seconds kept, render options (palette etc.)
const EFFECTS = [
  { name: "hit_spark", id: "impacts/hit-spark", fps: 24 },
  { name: "crit_hit", id: "impacts/crit-hit", fps: 20, max: 0.7 },
  { name: "arcane_orb", id: "arcane/arcane-orb", fps: 15, max: 1.2 },
  { name: "frost_nova", id: "ice/frost-nova", fps: 15, max: 1.5 },
  { name: "spirit_flame", id: "fire/spirit-flame", fps: 15, max: 1.2, opts: { palette: ["#2a0802", "#6e1a04", "#c2410c", "#f97316", "#fdba74", "#fff4d6"] } },
  { name: "mana_burst", id: "arcane/mana-burst", fps: 18, max: 1.1 },
  { name: "zap_hit", id: "lightning/zap-hit", fps: 24, max: 0.6 },
  { name: "sword_slash", id: "melee/sword-slash", fps: 30, max: 0.5 },
  { name: "poof", id: "spawn/poof", fps: 20, max: 1.0 },
  { name: "dark_explosion", id: "shadow/dark-explosion", fps: 15, max: 1.1 },
  { name: "big_explosion", id: "explosions/big-explosion", fps: 12, max: 1.6 },
  { name: "spawn_portal", id: "spawn/spawn-portal", fps: 12, max: 2.0 },
  { name: "portal", id: "arcane/portal", fps: 15 },
  { name: "level_up", id: "ui/level-up", fps: 15, max: 1.5 },
  { name: "heal", id: "holy/heal", fps: 20, max: 1.5 },
  { name: "loot_beam", id: "pickups/loot-beam", fps: 15, max: 1.4 },
  { name: "blink_out", id: "arcane/blink-out", fps: 24, max: 0.8 },
];

mkdirSync(outDir, { recursive: true });
let totalBytes = 0;
const manifest = {};

for (const e of EFFECTS) {
  const fx = await lib.loadEffect(e.id);
  const r = lib.renderFrames(fx, { fps: e.fps, bg: "none", actor: false, options: e.opts });
  let frames = r.frames;
  if (e.max) frames = frames.filter((f) => f.t <= e.max + 1e-6);
  // light buffer as RGBA: rgb = light, alpha = its brightest channel (for additive drawing)
  const lightRGBA = (f) => {
    const out = new Uint8ClampedArray(r.w * r.h * 4);
    for (let i = 0; i < r.w * r.h; i++) {
      const l = f.light[i] & 0xffffff;
      if (!l) continue;
      const R = l & 255, G = (l >>> 8) & 255, B = (l >>> 16) & 255, m = Math.max(R, G, B);
      out[i * 4] = Math.min(255, (R * 255) / m); out[i * 4 + 1] = Math.min(255, (G * 255) / m);
      out[i * 4 + 2] = Math.min(255, (B * 255) / m); out[i * 4 + 3] = m;
    }
    return out;
  };
  const colorRGBA = (f) => {
    const out = new Uint8ClampedArray(r.w * r.h * 4);
    for (let i = 0; i < r.w * r.h; i++) {
      const c = f.raw[i], a = c >>> 24;
      if (!a) continue;
      out[i * 4] = c & 255; out[i * 4 + 1] = (c >>> 8) & 255; out[i * 4 + 2] = (c >>> 16) & 255; out[i * 4 + 3] = a;
    }
    return out;
  };
  const layers = frames.map((f) => ({ color: colorRGBA(f), light: lightRGBA(f) }));
  // drop trailing empty frames (one-shots)
  const empty = (L) => !L.color.some((v, i) => i % 4 === 3 && v > 0) && !L.light.some((v, i) => i % 4 === 3 && v > 3);
  if (!fx.meta.loop) while (layers.length > 1 && empty(layers[layers.length - 1])) layers.pop();
  // union bounding box
  let x0 = r.w, y0 = r.h, x1 = -1, y1 = -1;
  for (const L of layers)
    for (let y = 0; y < r.h; y++)
      for (let x = 0; x < r.w; x++) {
        const i = (y * r.w + x) * 4 + 3;
        if (L.color[i] > 0 || L.light[i] > 3) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
      }
  if (x1 < 0) { console.error(`${e.name}: empty`); continue; }
  const cw = x1 - x0 + 1, ch = y1 - y0 + 1, n = layers.length;
  const cols = Math.max(1, Math.min(n, Math.floor(2048 / cw))), rows = Math.ceil(n / cols);
  const W = cols * cw, H = rows * ch;
  const sheets = { color: new Uint8ClampedArray(W * H * 4), light: new Uint8ClampedArray(W * H * 4) };
  layers.forEach((L, k) => {
    const ox = (k % cols) * cw, oy = Math.floor(k / cols) * ch;
    for (const key of ["color", "light"])
      for (let y = 0; y < ch; y++)
        for (let x = 0; x < cw; x++) {
          const s = ((y + y0) * r.w + (x + x0)) * 4, d = ((oy + y) * W + (ox + x)) * 4;
          sheets[key].set(L[key].subarray(s, s + 4), d);
        }
  });
  writeFileSync(join(outDir, `${e.name}_color.png`), encodePNG(W, H, sheets.color));
  writeFileSync(join(outDir, `${e.name}_light.png`), encodePNG(W, H, sheets.light));
  const [px, py] = fx.meta.origin;
  manifest[e.name] = {
    source: e.id, fps: e.fps, loop: !!fx.meta.loop, frames: n, columns: cols,
    frame_size: [cw, ch], pivot: [px - x0, py - y0],
  };
  totalBytes += W * H * 4 * 2;
  console.log(`${e.name.padEnd(16)} ${n} frames ${cw}x${ch}  sheet ${W}x${H}  ${((W * H * 8) / 1048576).toFixed(1)} MB VRAM`);
}
writeFileSync(join(outDir, "effects.json"), JSON.stringify(manifest, null, 1));
console.log(`total texture memory ~${(totalBytes / 1048576).toFixed(1)} MB`);

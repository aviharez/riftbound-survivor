// Top-down crystal blast for Riftbound (Absolute Zero): a frost ring races out over the floor ellipse
// (camera looks down at a slant, sy = 0.6), ice crystals erupt from the floor across the area (back rows dimmer,
// drawn first), a cold mist rolls out and the floor stays frosted; then the crystals shatter into shards
// that arc away, leaving glints. Burst at t = 0.04 s.
import { fit, clamp, smooth, rng, TAU, WHITE, crystal, sparkle } from "../../core/index.js";

export const meta = {
  name: "Frost burst (top-down)",
  desc: "A frost ring sweeps the floor, crystals erupt across the area, cold mist rolls out, then the crystals shatter into glinting shards.",
  tags: ["ice", "freeze", "explosion", "aoe", "top-down", "one-shot"],
  size: [116, 92],
  origin: [58, 56],
  duration: 1.1,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#0c1430", "#162c5c", "#1f4f94", "#2f7fcc", "#58b4ec", "#9bdcff", "#d8f4ff", "#ffffff"], reach: 42, sy: 0.6, seed: 9 },
};

const HIT = 0.04;
const SHATTER = 0.62;

// crystal layout: positions on the floor (u, v in reach units), height, width, lean, grow delay
function layout(o) {
  const r = rng(o.seed, 1), out = [];
  const rings = [[0.0, 1, 21], [0.18, 2, 15], [0.42, 5, 13], [0.7, 6, 9], [0.92, 5, 6]];
  for (const [d, n, h] of rings) {
    const a0 = r.range(0, TAU);
    for (let i = 0; i < n; i++) {
      const g = a0 + (i / n) * TAU + r.range(-0.2, 0.2), dd = d * r.range(0.85, 1.1);
      out.push({ u: Math.cos(g) * dd, v: Math.sin(g) * dd, h: h * r.range(0.75, 1.15), w: 3 + h * 0.28 * r.range(0.8, 1.2),
        lean: Math.cos(g) * r.range(1, 3.5) * dd + r.range(-0.8, 0.8), delay: d * 0.12 + r.range(0, 0.03), g });
    }
  }
  return out.sort((a, b) => a.v - b.v); // back rows (further up the screen) first
}

export function draw(p, t, o) {
  const C = fit(o.palette, 8), R = o.reach, SY = o.sy;
  const ramp = o.palette;
  if (t < HIT) {
    // anticipation: a cold point gathers
    p.circle(0, 0, 2, C[6]);
    p.glow(0, 0, 10, C[5], 0.6 * (t / HIT));
    return;
  }
  const s = t - HIT;
  // frosted floor: a scatter of pale specks inside the blast, fading late
  const fr = 1 - smooth(0.6, 1.0, s);
  const rf = rng(o.seed, 2);
  const grown = clamp(s / 0.3);
  for (let i = 0; i < 110; i++) {
    const g = rf.range(0, TAU), d = Math.sqrt(rf.next()) * R * 0.95;
    if (d > R * grown) continue;
    p.dot(Math.cos(g) * d, Math.sin(g) * d * SY, i % 3 ? C[4] : C[6], fr * 0.75);
  }
  // hero frame: light only, plus a small white core
  if (s < 0.12) {
    const k = s / 0.12;
    p.glow(0, 0, R, C[5], 0.85 * (1 - k));
    p.glow(0, 0, 12, WHITE, 0.9 * (1 - k));
    p.ellipse(0, 0, 9 * (1 - k) + 2, (9 * (1 - k) + 2) * SY, WHITE);
  }
  // frost ring racing out: white rim, cyan and blue bands behind, little ice teeth on the rim
  const rk = clamp(s / 0.34);
  if (rk < 1) {
    const rr = 4 + R * (1 - Math.pow(1 - rk, 3)), w = Math.max(1, Math.round(3 * (1 - rk)));
    const n = Math.ceil(TAU * rr * 1.6);
    for (let i = 0; i < n; i++) {
      const g = (i / n) * TAU, cx = Math.cos(g), cy = Math.sin(g) * SY;
      for (let j = 0; j < w; j++) p.dot(cx * (rr - j), cy * (rr - j), j === 0 ? (rk < 0.4 ? WHITE : C[6]) : j === 1 ? C[5] : C[3], 1 - rk * 0.6);
      if (i % 7 === 0 && rk < 0.8) { p.dot(cx * rr, cy * rr - 1, C[6], 1 - rk); p.dot(cx * rr, cy * rr - 2, C[5], 0.7 * (1 - rk)); }
      if (i % 6 === 0) p.light(cx * rr, cy * rr, C[5], 0.4 * (1 - rk));
    }
  }
  // cold mist rolling out along the floor: soft translucent puffs, thinning
  const rm = rng(o.seed, 3);
  for (let i = 0; i < 9; i++) {
    const g = (i / 9) * TAU + rm.range(-0.3, 0.3), life = rm.range(0.55, 0.85), k = s / life;
    if (k >= 1) continue;
    const d = R * (0.2 + 0.6 * (1 - Math.pow(1 - k, 2)));
    p.disc(Math.cos(g) * d, Math.sin(g) * d * SY - 2 - 3 * k, 3 + 5 * k, C[6], 0.16 * (1 - k));
  }
  // cold light pool over the frozen floor while the crystals stand
  const pool = clamp(s / 0.1) * (1 - smooth(SHATTER, SHATTER + 0.25, s));
  if (pool > 0) for (let i = 0; i < 5; i++) p.glow(((i - 2) / 2) * R * 0.5, 0, R * 0.45, C[4], 0.12 * pool);
  // crystals: erupt fast, hold, then shatter (shrink and break into shards)
  const cs = layout(o);
  for (const c of cs) {
    const ls = s - c.delay;
    if (ls <= 0) continue;
    const grow = 1 - Math.pow(1 - clamp(ls / 0.12), 3);
    const brk = clamp((s - SHATTER - c.delay * 0.5) / 0.14);
    if (brk >= 1) continue;
    const h = c.h * grow * (1 - brk * 0.7), x = c.u * R, base = c.v * R * SY;
    const back = c.v < -0.1;
    crystal(p, x, base, h, c.w * (1 - brk * 0.4), c.lean * grow, ramp, { a: (back ? 0.85 : 1) * (1 - brk), glint: brk > 0 ? -1 : (s * 2 + c.u) % 1 });
    if (grow < 1) p.light(x, base - h * 0.6, C[6], 0.5);
    p.glow(x + c.lean * 0.5, base - h * 0.5, 4 + h * 0.4, C[5], 0.22 * (1 - brk));
    p.light(x + c.lean * 0.8, base - h * 0.85, WHITE, 0.5 * (1 - brk));
  }
  // shards: when the crystals shatter, splinters fly out and arc down the screen
  if (s > SHATTER) {
    const ss = s - SHATTER, rs = rng(o.seed, 4);
    for (let i = 0; i < 34; i++) {
      const c = cs[i % cs.length], g = rs.range(0, TAU), v = rs.range(25, 70), life = rs.range(0.2, 0.42), k = ss / life;
      if (k >= 1) continue;
      const x0 = c.u * R, y0 = c.v * R * SY - c.h * 0.4;
      const x = x0 + Math.cos(g) * v * ss, y = y0 + Math.sin(g) * v * ss * SY - rs.range(10, 30) * ss + 90 * ss * ss;
      p.dot(x, y, k < 0.4 ? WHITE : k < 0.7 ? C[6] : C[4], 1 - k);
      p.dot(x - Math.cos(g), y - Math.sin(g) * SY, C[4], 0.6 * (1 - k));
      if (k < 0.4) p.light(x, y, C[5], 0.4);
    }
  }
  // glints twinkling over the frost
  const rg = rng(o.seed, 5);
  for (let i = 0; i < 6; i++) {
    const at = rg.range(0.15, 0.85), g = rg.range(0, TAU), d = rg.range(0.1, 0.8) * R;
    const k = (s - at) / 0.16;
    if (k < 0 || k >= 1) continue;
    sparkle(p, Math.cos(g) * d, Math.sin(g) * d * SY - 3, 3 * Math.sin(k * Math.PI), WHITE, C[5]);
  }
}

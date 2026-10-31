// Top-down solar detonation for Riftbound (Solar Cataclysm): the miniature sun collapses to a white-hot point,
// then bursts. A fire ring races out across the floor ellipse (camera looks down at a slant, sy = 0.6), flame
// spokes lick outward like a sun's corona, embers arc away and a warm scorch glow fades. Burst at t = 0.05 s.
import { fit, clamp, smooth, rng, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Solar burst (top-down)",
  desc: "A miniature sun detonates: white flash, a fire ring racing over the floor, corona flame spokes, embers and a fading scorch glow.",
  tags: ["fire", "holy", "explosion", "aoe", "top-down", "one-shot"],
  size: [116, 92],
  origin: [58, 50],
  duration: 0.8,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#2a0a04", "#6a1a08", "#c0400e", "#f08a1c", "#ffc83a", "#fff09a", "#ffffff"], reach: 44, sy: 0.6, seed: 5 },
};

const HIT = 0.05;

export function draw(p, t, o) {
  const C = fit(o.palette, 7), R = o.reach, SY = o.sy;
  // collapse: the sun shrinks to a point just before it bursts
  if (t < HIT) {
    const k = t / HIT, r = 6 * (1 - k) + 2;
    p.circle(0, 0, r, C[5]);
    p.circle(0, 0, r * 0.5, WHITE);
    p.glow(0, 0, 16, C[4], 0.7);
    return;
  }
  const s = t - HIT;
  // scorch glow left on the floor: a warm ring of cracks, fading out
  const sc = 1 - smooth(0.25, 0.7, s);
  if (sc > 0) {
    const rc = rng(o.seed, 3);
    for (let i = 0; i < 12; i++) {
      const g = (i / 12) * TAU + rc.range(-0.15, 0.15), len = R * rc.range(0.3, 0.55);
      for (let d = 4; d < len; d += 1)
        p.dot(Math.cos(g) * d + Math.sin(d * 0.6 + i) * 0.7, Math.sin(g) * d * SY, d < len * 0.5 ? C[3] : C[1], sc * (1 - d / len * 0.6));
    }
    p.glow(0, 0, R * 0.7, C[3], 0.25 * sc);
  }
  // hero frame: a white-hot disc and a big warm light, light only so sprites stay readable
  if (s < 0.12) {
    const k = s / 0.12;
    p.glow(0, 0, R * 1.1, C[5], 0.9 * (1 - k));
    p.glow(0, 0, 16, WHITE, 1.0 * (1 - k));
    p.circle(0, 0, 9 * (1 - k) + 1, WHITE);
    p.ellipse(0, 0, 12 * (1 - k) + 2, (12 * (1 - k) + 2) * SY, C[6]);
  }
  // the sun's core lingers a moment as a cooling fireball, sinking into the scorch
  const fk = 1 - smooth(0.08, 0.4, s);
  if (fk > 0) {
    const r = 3 + 5 * fk;
    p.ellipse(0, 0, r + 1, (r + 1) * SY, C[2]);
    p.ellipse(0, 0, r, r * SY, fk > 0.6 ? C[5] : C[4]);
    p.ellipse(-0.5, -0.5, r * 0.55, r * 0.55 * SY, fk > 0.5 ? WHITE : C[5]);
    p.glow(0, 0, 14, C[4], 0.5 * fk);
  }
  // corona: flame spokes bursting out radially, thinning and cooling as they reach out
  const ck = clamp(s / 0.42);
  if (ck < 1) {
    const rs = rng(o.seed, 4);
    for (let i = 0; i < 14; i++) {
      const g = (i / 14) * TAU + rs.range(-0.12, 0.12);
      const reach = R * rs.range(0.55, 0.95) * (1 - Math.pow(1 - ck, 3));
      const start = reach * 0.25 * ck;
      const steps = Math.max(1, Math.ceil(reach - start));
      for (let j = 0; j < steps; j++) {
        const q = j / steps, d = start + (reach - start) * q;
        const x = Math.cos(g) * d + Math.sin(d * 0.5 + i * 1.7 + s * 20) * 1.2 * q;
        const y = Math.sin(g) * d * SY;
        const heat = q + ck * 0.6;
        const c = heat < 0.3 ? C[6] : heat < 0.6 ? C[5] : heat < 0.95 ? C[4] : C[3];
        const fa = 1 - smooth(0.55, 1, ck);   // spokes burn out from the tips inward
        if (q > fa + 0.1) continue;
        p.dot(x, y, c, Math.min(1, fa * 1.6));
        // flames are thick at the root, a single pixel at the tip
        if (q < 0.55 * fa) { p.dot(x - Math.sin(g), y + Math.cos(g) * SY, heat < 0.5 ? C[5] : C[3], fa); p.dot(x, y - 1, C[4], fa); }
        if (q > 0.85 && j % 2) p.dot(x, y - 1, C[3], 0.5);
      }
      p.light(Math.cos(g) * reach * 0.6, Math.sin(g) * reach * 0.6 * SY, C[4], 0.35 * (1 - ck));
    }
  }
  // fire ring racing out over the floor: hot rim, then cooler bands behind it
  const rk = clamp(s / 0.4);
  if (rk < 1) {
    const rr = 5 + R * (1 - Math.pow(1 - rk, 3)), w = Math.max(1, Math.round(4 * (1 - rk)));
    const n = Math.ceil(TAU * rr * 1.6);
    const hot = Math.min(3, Math.floor(rk * 4));   // rim cools: white -> yellow -> orange -> red
    for (let i = 0; i < n; i++) {
      const g = (i / n) * TAU, cx = Math.cos(g), cy = Math.sin(g) * SY;
      for (let j = 0; j < w; j++) {
        const c = C[Math.max(2, 6 - hot - j)];
        p.dot(cx * (rr - j), cy * (rr - j), c, 1 - rk * 0.75);
      }
      // little flame tongues licking up off the rim
      if (i % 5 === 0 && rk < 0.75) {
        const h = Math.round((2 + 3 * Math.abs(Math.sin(i * 1.3 + s * 25))) * (1 - rk));
        for (let k = 1; k <= h; k++) p.dot(cx * rr, cy * rr - k, k < h * 0.5 ? C[Math.max(3, 5 - hot)] : C[3], (1 - rk) * (1 - k / (h + 1)));
      }
      if (i % 6 === 0) p.light(cx * rr, cy * rr, C[4], 0.45 * (1 - rk));
    }
  }
  // a second, slower and dimmer heat ring
  const r2k = clamp((s - 0.06) / 0.5);
  if (r2k > 0 && r2k < 1) {
    const rr = 3 + R * 0.75 * (1 - Math.pow(1 - r2k, 2));
    const n = Math.ceil(TAU * rr * 1.2);
    for (let i = 0; i < n; i += 2) {
      const g = (i / n) * TAU;
      p.dot(Math.cos(g) * rr, Math.sin(g) * rr * SY, C[3], 0.7 * (1 - r2k));
    }
  }
  // embers flying out and arcing down the screen (falling back to the floor)
  const re = rng(o.seed, 2);
  for (let i = 0; i < 30; i++) {
    const g = re.range(0, TAU), v = re.range(40, 95), life = re.range(0.3, 0.7), k = s / life;
    if (k >= 1) continue;
    const x = Math.cos(g) * v * s, y = Math.sin(g) * v * s * SY - re.range(25, 50) * s + 70 * s * s;
    p.dot(x, y, k < 0.35 ? C[6] : k < 0.7 ? C[5] : C[3], 1 - k);
    if (k < 0.3) p.dot(x - Math.cos(g), y - Math.sin(g) * SY, C[4], 0.6 * (1 - k));
    if (k < 0.5) p.light(x, y, C[4], 0.5);
  }
}

// Top-down meteor strike for Riftbound: a red target ring on the floor and a shadow that grows as a dark, cracked
// ROCK (glowing only in its cracks) drops straight down the screen onto it (the camera looks down at a slant, so
// "down the screen" reads as "out of the sky"), trailing grey smoke with only a thin hot streak. Impact: a short
// flash, a dust ring rolling out over the floor ellipse, rock chunks thrown out and bouncing, a cratered scorch
// with molten cracks that cools, and a little fire. It must not read as a fireball (that is Flame Orb).
// Impact at t = 0.5 s.
import { fit, clamp, smooth, rng, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Meteor strike (top-down)",
  desc: "A cracked rock falls onto a target ring with a growing shadow; impact throws a dust ring, bouncing rock chunks and leaves a molten crater.",
  tags: ["earth", "fire", "meteor", "aoe", "top-down", "one-shot"],
  size: [104, 196],
  origin: [52, 160],
  duration: 1.2,
  loop: false,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#2a0a0a", "#6a1a10", "#b8341a", "#ec6a1e", "#ffa83a", "#ffe08a", "#ffffff"],
    stone: ["#14100e", "#2a221e", "#463a32", "#665448", "#8a7464", "#ab9886"],
    dust: ["#3a302a", "#5e5048", "#857264", "#a89482"],
    reach: 38, sy: 0.6, seed: 11,
  },
};

const HIT = 0.5;

export function draw(p, t, o) {
  const C = fit(o.palette, 7), S = fit(o.stone, 6), D = fit(o.dust, 4), R = o.reach, SY = o.sy;
  // warning ring on the floor
  if (t < HIT + 0.05) {
    const k = clamp(t / HIT), a = 0.55 + 0.45 * Math.sin(t * 40);
    const r = R * (1 - 0.25 * k);
    for (let i = 0; i < 48; i++) {
      const g = (i / 48) * TAU + t * 2;
      if (i % 4 === 3) continue;
      p.dot(Math.cos(g) * r, Math.sin(g) * r * SY, k > 0.7 ? C[4] : C[2], a);
    }
    for (let i = -3; i <= 3; i++) { p.dot(i, 0, C[3], a * 0.8); p.dot(0, i * SY, C[3], a * 0.8); }
  }
  if (t < HIT) {
    const k = t / HIT, f = k * k;
    // the rock's shadow on the floor: grows and darkens as it comes down (the strongest "from the sky" cue)
    const sh = 3 + 9 * k;
    for (let y = Math.floor(-sh * SY); y <= Math.ceil(sh * SY); y++)
      for (let x = Math.floor(-sh); x <= Math.ceil(sh); x++) {
        const d = Math.hypot(x / sh, y / (sh * SY));
        if (d < 1) p.blend(x, y, S[0], (0.25 + 0.5 * k) * (1 - d * d * 0.5));
      }
    // the rock: falls from high above with a slight drift, accelerating
    const x = 12 * (1 - f), y = -124 * (1 - f), rr = 7;
    const dx = 12, dy = 124, n = Math.hypot(dx, dy), ux = dx / n, uy = -dy / n; // trail points back up the path
    // grey smoke trail, widening and thinning behind the rock, with a thin hot streak in its core
    const TL = 14 + 30 * k;
    for (let i = 3; i < TL; i += 1.5) {
      const q = i / TL;
      p.disc(x + ux * i + Math.sin(i * 0.5 + t * 20) * q * 2, y + uy * i, 1.5 + 3.5 * q, q < 0.3 ? D[2] : D[1], 0.45 * (1 - q));
    }
    for (let i = 2; i < TL * 0.45; i++) {
      const q = i / (TL * 0.45);
      p.dot(x + ux * i, y + uy * i, q < 0.3 ? C[5] : q < 0.6 ? C[4] : C[3], 1 - q);
    }
    p.glowLine(x, y, x + ux * TL * 0.4, y + uy * TL * 0.4, 3, C[3], 0.3);
    // rock body: dark stone lit from the top-left, the leading (bottom) face glowing from friction
    p.circle(x, y, rr + 1, S[0]);
    // grey stone, lit top-left; only a thin rim on the leading (bottom) face glows from friction
    p.circle(x, y, rr, (d, ang) => (Math.sin(ang) > 0.5 && d > 0.85 ? C[3] : Math.cos(ang + 2.4) > 0.35 ? (d < 0.6 ? S[5] : S[4]) : d > 0.7 ? S[2] : S[3]));
    // knobbly outline: a couple of bumps so it reads as a rock, not a ball
    p.px(x - rr - 0.5, y - 2, S[1]); p.px(x + rr, y - 3, S[1]); p.px(x + 2, y - rr - 0.5, S[1]);
    p.px(x - 3, y - 3, S[5]); p.px(x - 2, y - 4, S[5]);
    // two thin molten cracks
    p.line(x - 3, y + 1, x, y + 2, C[3]); p.line(x + 1, y - 1, x + 3, y + 1, C[2]);
    p.glow(x, y + rr, 6, C[3], 0.3);
  }
  if (t < HIT) return;
  const s = t - HIT;
  // crater: a dark dish with molten cracks radiating out, cooling from yellow to dark red, then fading
  const sc = 1 - smooth(0.4, 0.7, s), heat = clamp(s / 0.45);
  if (sc > 0) {
    for (let y = Math.floor(-9 * SY); y <= Math.ceil(9 * SY); y++)
      for (let x = -9; x <= 9; x++) {
        const d = Math.hypot(x / 9, y / (9 * SY));
        if (d < 1) p.blend(x, y, S[0], 0.7 * sc * (1 - d * 0.4));
      }
    const rc = rng(o.seed, 3);
    for (let i = 0; i < 9; i++) {
      const g = (i / 9) * TAU + rc.range(-0.2, 0.2), len = R * rc.range(0.35, 0.6);
      for (let d = 4; d < len; d += 1) {
        const c = heat < 0.3 ? C[5] : heat < 0.6 ? C[4] : heat < 0.85 ? C[3] : C[2];
        p.dot(Math.cos(g) * d + Math.sin(d * 0.7 + i) * 0.8, Math.sin(g) * d * SY, d < len * 0.5 ? c : C[1], sc * (1 - d / len * 0.5));
      }
    }
    p.glow(0, 0, 14, C[3], 0.35 * sc * (1 - heat * 0.6));
  }
  // flash: short, light only
  if (s < 0.1) {
    const k = s / 0.1;
    p.glow(0, 0, 34, C[5], 0.75 * (1 - k));
    p.circle(0, 0, 4 * (1 - k) + 1, WHITE);
  }
  // dust ring rolling out over the floor: soft brown-grey puffs on the ellipse, thinning
  const dk = clamp(s / 0.55);
  if (dk < 1) {
    const rr = 6 + R * (1 - Math.pow(1 - dk, 3));
    // overlapping puffs (more, smaller) so the ring reads as one rolling dust wall
    for (let i = 0; i < 30; i++) {
      const g = (i / 30) * TAU, jit = Math.sin(i * 2.7) * 2;
      p.disc(Math.cos(g) * (rr + jit), Math.sin(g) * (rr + jit) * SY - 2 * dk, 2.5 + 3 * dk, i % 3 ? D[2] : D[3], 0.42 * (1 - dk));
    }
    // the ring's leading edge: a thin pale line on the floor
    const n = Math.ceil(TAU * rr * 1.4);
    for (let i = 0; i < n; i += 2) {
      const g = (i / n) * TAU;
      p.dot(Math.cos(g) * rr, Math.sin(g) * rr * SY, D[3], 0.8 * (1 - dk));
    }
  }
  // rock chunks thrown out, arcing up the screen and falling back with a bounce
  const r2 = rng(o.seed, 2);
  for (let i = 0; i < 12; i++) {
    const g = r2.range(0, TAU), v = r2.range(35, 75), up = r2.range(40, 80), life = r2.range(0.45, 0.65);
    if (s >= life) continue;
    const gx = Math.cos(g) * v * s, gy = Math.sin(g) * v * s * SY;
    let h = up * s - 220 * s * s;   // height above the floor
    if (h < 0) h = -h * 0.3;        // a small bounce
    const x = gx, y = gy - h, a = 1 - smooth(0.7, 1, s / life);
    p.dot(x, gy + 1, S[0], 0.4 * a);                  // its little shadow on the floor
    p.dot(x, y, i % 3 ? S[3] : S[4], a); p.dot(x + 1, y, S[2], a);
    if (i % 3 === 0) { p.dot(x, y - 1, C[4], a); p.light(x, y, C[3], 0.3 * a); }
  }
  // a little fire licking in the crater
  const fk = 1 - smooth(0.12, 0.4, s);
  if (fk > 0) {
    const r = rng(o.seed, 1);
    for (let i = 0; i < 6; i++) {
      const g = r.range(0, TAU), d = r.range(0, 6), x = Math.cos(g) * d, y = Math.sin(g) * d * SY;
      const h = r.range(4, 9) * fk * (0.6 + 0.4 * Math.sin(s * 30 + i));
      for (let k = 0; k < h; k++) { const q = k / h; p.dot(x + Math.sin(k * 0.7 + i) * 0.6, y - k, q < 0.3 ? C[5] : q < 0.7 ? C[4] : C[3], fk * (1 - q)); }
    }
  }
}

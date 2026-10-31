// Top-down meteor strike for Riftbound: a warning circle on the floor, a burning rock falling straight down onto
// it (the camera looks down at a slant, so "down the screen" reads as "out of the sky"), then the impact: a white
// flash, a fire ring racing out across the floor ellipse, embers and a fading scorch mark. Impact at t = 0.5 s.
import { fit, clamp, smooth, rng, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Meteor strike (top-down)",
  desc: "A red target ring pulses on the floor as a meteor drops onto it; on impact a white flash, a fire ring over the ground, embers and a fading scorch mark.",
  tags: ["fire", "meteor", "aoe", "top-down", "one-shot"],
  size: [104, 172],
  origin: [52, 136],
  duration: 1.15,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#2a0a0a", "#6a1a10", "#b8341a", "#ec6a1e", "#ffa83a", "#ffe08a", "#ffffff"], reach: 38, sy: 0.6, seed: 11 },
};

const HIT = 0.5;

export function draw(p, t, o) {
  const C = fit(o.palette, 7), R = o.reach, SY = o.sy;
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
  // the meteor: falls from high above with a slight drift, accelerating
  if (t < HIT) {
    const k = t / HIT, f = k * k, x = 14 * (1 - f), y = -124 * (1 - f);
    const dx = 14, dy = 124, n = Math.hypot(dx, dy), ux = dx / n, uy = -dy / n; // tail points back up the path
    const TL = 10 + 26 * k;
    for (let i = 0; i < TL; i++) {
      const q = i / TL, wv = Math.max(0.5, 4.5 * (1 - q));
      const c = q < 0.15 ? C[6] : q < 0.35 ? C[5] : q < 0.6 ? C[4] : q < 0.85 ? C[3] : C[2];
      const tx = x + ux * i, ty = y + uy * i;
      for (let w = -wv; w <= wv; w += 1) p.dot(tx + w, ty, c, 1 - q * 0.8);
    }
    p.glowLine(x, y, x + ux * TL, y + uy * TL, 6, C[4], 0.4);
    p.circle(x, y, 5, C[1]);
    p.circle(x - 0.5, y + 0.5, 3.8, C[3]);
    p.circle(x - 0.8, y + 1, 2.2, C[5]);
    p.px(x - 1, y + 1, WHITE);
    p.glow(x, y, 14, C[4], 0.55);
    // growing shadow on the floor under it
    if (k > 0.25) p.ellipse(0, 0, 2 + 7 * k, (2 + 7 * k) * SY, C[0]);
  }
  if (t < HIT) return;
  const s = t - HIT;
  // scorch: a few dark cracks radiating from the crater (solid pixels, no dithered fill)
  const sc = 1 - smooth(0.3, 0.65, s);
  if (sc > 0) {
    const rc = rng(o.seed, 3);
    for (let i = 0; i < 9; i++) {
      const g = (i / 9) * TAU + rc.range(-0.2, 0.2), len = R * rc.range(0.35, 0.6);
      for (let d = 3; d < len; d += 1) p.dot(Math.cos(g) * d + Math.sin(d * 0.7 + i) * 0.8, Math.sin(g) * d * SY, d < len * 0.4 ? C[3] : C[1], sc * (1 - d / len * 0.5));
    }
    p.circle(0, 0, 3, C[1], sc);
  }
  // flash: light only, so the sprites under it stay readable
  if (s < 0.14) {
    const k = s / 0.14;
    p.glow(0, 0, 40, C[5], 0.9 * (1 - k));
    p.glow(0, 0, 14, WHITE, 0.9 * (1 - k));
    p.circle(0, 0, 5 * (1 - k) + 1, WHITE);
  }
  // fire ring racing out over the floor: a solid outline on the floor ellipse, thinning as it goes
  const rk = clamp(s / 0.32);
  if (rk < 1) {
    const rr = 4 + R * (1 - Math.pow(1 - rk, 3)), w = Math.max(1, Math.round(3 * (1 - rk)));
    const n = Math.ceil(TAU * rr * 1.6);
    for (let i = 0; i < n; i++) {
      const g = (i / n) * TAU;
      for (let j = 0; j < w; j++) {
        const c = j === 0 ? C[5] : j === 1 ? C[4] : C[3];
        p.dot(Math.cos(g) * (rr - j), Math.sin(g) * (rr - j) * SY, c, 1 - rk * 0.6);
      }
    }
    p.glowRing(0, 0, rr, 4, C[4], 0.35 * (1 - rk));
  }
  // flame tongues licking up inside the crater
  const fk = 1 - smooth(0.2, 0.55, s);
  if (fk > 0) {
    const r = rng(o.seed, 1);
    for (let i = 0; i < 9; i++) {
      const g = r.range(0, TAU), d = r.range(0, R * 0.4), x = Math.cos(g) * d, y = Math.sin(g) * d * SY;
      const h = r.range(5, 13) * fk * (0.6 + 0.4 * Math.sin(s * 30 + i));
      for (let k = 0; k < h; k++) { const q = k / h; p.dot(x + Math.sin(k * 0.7 + i) * 0.6, y - k, q < 0.3 ? C[5] : q < 0.7 ? C[4] : C[3], fk * (1 - q)); }
    }
  }
  // embers flying out and arcing down
  const r2 = rng(o.seed, 2);
  for (let i = 0; i < 26; i++) {
    const g = r2.range(0, TAU), v = r2.range(30, 80), life = r2.range(0.3, 0.6), k = s / life;
    if (k >= 1) continue;
    const x = Math.cos(g) * v * s, y = Math.sin(g) * v * s * SY - r2.range(20, 50) * s + 90 * s * s;
    p.dot(x, y, k < 0.4 ? C[6] : k < 0.7 ? C[5] : C[3], 1 - k);
    if (k < 0.5) p.light(x, y, C[4], 0.5);
  }
}

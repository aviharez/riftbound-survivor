// Top-down singularity collapse for Riftbound (Event Horizon): violet streaks rush inward across the floor
// ellipse (camera looks down at a slant, sy = 0.6) and the dark core pinches to a point; then it bursts: a
// white-violet flash, a bright rim ring chased by a dark wake racing out over the floor, ragged void tendrils
// and violet sparks, and a dark smudge that fades. Collapse at t = 0.14 s.
import { fit, clamp, smooth, rng, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Void collapse (top-down)",
  desc: "Violet streaks rush into a pinching dark core, which bursts: flash, a rim ring with a dark wake over the floor, void tendrils and sparks.",
  tags: ["shadow", "void", "gravity", "explosion", "aoe", "top-down", "one-shot"],
  size: [116, 84],
  origin: [58, 46],
  duration: 0.95,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#07040e", "#1c1030", "#3a1a66", "#6b2cc0", "#a058f0", "#d4a0ff", "#f4e4ff"], reach: 46, sy: 0.6, seed: 13 },
};

const HIT = 0.14;

export function draw(p, t, o) {
  const C = fit(o.palette, 7), R = o.reach, SY = o.sy;
  const ri = rng(o.seed, 1);
  if (t < HIT) {
    // implosion: streaks along the floor rush into the core, accelerating
    const k = t / HIT;
    for (let i = 0; i < 18; i++) {
      const g = ri.range(0, TAU), d0 = R * ri.range(0.6, 1.0), d = d0 * (1 - k * k), len = 4 + 10 * k;
      for (let j = 0; j < len; j++) {
        const dd = d + j;
        p.dot(Math.cos(g) * dd, Math.sin(g) * dd * SY, j < 2 ? C[6] : j < len * 0.5 ? C[4] : C[3], (1 - j / len) * (0.4 + 0.6 * k));
      }
    }
    const r = 7 * (1 - k) + 2;
    p.ellipse(0, 0, r + 1.5, (r + 1.5) * SY, C[4]);
    p.ellipse(0, 0, r, r * SY, C[0]);
    p.glow(0, 0, 14 + 10 * k, C[3], 0.35 + 0.3 * k);
    return;
  }
  const s = t - HIT;
  // dark smudge on the floor where it collapsed
  const sm = 1 - smooth(0.3, 0.8, s);
  if (sm > 0) {
    // a translucent dark patch lying flat on the floor (an ellipse, not a ball)
    const rr = R * 0.42 * (0.6 + 0.4 * smooth(0, 0.2, s));
    for (let y = Math.floor(-rr * SY); y <= Math.ceil(rr * SY); y++)
      for (let x = Math.floor(-rr); x <= Math.ceil(rr); x++) {
        const d = Math.hypot(x / rr, y / (rr * SY));
        if (d < 1) p.blend(x, y, C[0], 0.5 * sm * (1 - d * d));
      }
    const rc = rng(o.seed, 3);
    for (let i = 0; i < 10; i++) {
      const g = (i / 10) * TAU + rc.range(-0.2, 0.2), len = R * rc.range(0.3, 0.55);
      for (let d = 3; d < len; d += 1) p.dot(Math.cos(g) * d + Math.sin(d * 0.8 + i) * 0.8, Math.sin(g) * d * SY, d < len * 0.5 ? C[3] : C[1], sm * (1 - d / len * 0.6));
    }
  }
  // hero frame: white-violet flash, light only plus a small core
  if (s < 0.1) {
    const k = s / 0.1;
    p.glow(0, 0, R * 1.0, C[4], 0.85 * (1 - k));
    p.glow(0, 0, 12, WHITE, 0.9 * (1 - k));
    p.ellipse(0, 0, 8 * (1 - k) + 2, (8 * (1 - k) + 2) * SY, C[6]);
  }
  // void tendrils lashing outward along the floor, wavering, then withering from the tips
  const tk = clamp(s / 0.45);
  if (tk < 1) {
    const rt = rng(o.seed, 4);
    for (let i = 0; i < 9; i++) {
      const g = (i / 9) * TAU + rt.range(-0.25, 0.25), reach = R * rt.range(0.5, 0.85) * (1 - Math.pow(1 - clamp(tk * 2), 3));
      const fade = 1 - smooth(0.45, 1, tk), ph = rt.range(0, TAU);
      for (let d = 2; d < reach * fade + 2; d += 1) {
        const q = d / reach, wob = Math.sin(d * 0.35 + ph + s * 18) * 2 * q;
        const x = Math.cos(g) * d - Math.sin(g) * wob, y = (Math.sin(g) * d + Math.cos(g) * wob) * SY;
        // dark body with a lit violet edge on top, so the tendril reads against the floor
        p.px(x, y, q < 0.4 ? C[1] : C[2]);
        p.dot(x, y - 1, q < 0.5 ? C[4] : C[3], fade);
        if (d % 4 === 0) { p.dot(x, y - 2, C[5], 0.8 * fade); p.light(x, y - 1, C[4], 0.25 * fade); }
      }
    }
  }
  // rim ring racing out with a dark wake behind it
  const rk = clamp(s / 0.38);
  if (rk < 1) {
    const rr = 4 + R * (1 - Math.pow(1 - rk, 3)), n = Math.ceil(TAU * rr * 1.6);
    for (let i = 0; i < n; i++) {
      const g = (i / n) * TAU, cx = Math.cos(g), cy = Math.sin(g) * SY;
      p.dot(cx * rr, cy * rr, rk < 0.35 ? C[6] : C[5], 1 - rk * 0.5);
      p.dot(cx * (rr - 1), cy * (rr - 1), C[4], 1 - rk * 0.7);
      for (let j = 2; j < 2 + 4 * (1 - rk); j++) p.dot(cx * (rr - j), cy * (rr - j), C[j < 3 ? 2 : 1], 0.8 * (1 - rk));
      if (i % 6 === 0) p.light(cx * rr, cy * rr, C[4], 0.45 * (1 - rk));
    }
  }
  // a slower, thinner second ring (the field's echo)
  const ek = clamp((s - 0.1) / 0.45);
  if (ek > 0 && ek < 1) {
    const rr = 3 + R * 0.7 * (1 - Math.pow(1 - ek, 2)), n = Math.ceil(TAU * rr * 1.2);
    for (let i = 0; i < n; i += 2) {
      const g = (i / n) * TAU;
      p.dot(Math.cos(g) * rr, Math.sin(g) * rr * SY, C[4], 0.7 * (1 - ek));
    }
  }
  // violet sparks thrown out, arcing down the screen
  const rs = rng(o.seed, 2);
  for (let i = 0; i < 26; i++) {
    const g = rs.range(0, TAU), v = rs.range(40, 90), life = rs.range(0.25, 0.55), k = s / life;
    if (k >= 1) continue;
    const x = Math.cos(g) * v * s, y = Math.sin(g) * v * s * SY - rs.range(15, 35) * s + 70 * s * s;
    p.dot(x, y, k < 0.35 ? WHITE : k < 0.7 ? C[5] : C[3], 1 - k);
    p.dot(x - Math.cos(g), y - Math.sin(g) * SY, C[4], 0.6 * (1 - k));
    if (k < 0.5) p.light(x, y, C[4], 0.5);
  }
}

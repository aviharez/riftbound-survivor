// Thornseed root patch for Riftbound (top-down): where the seed lands it pops, and thorny vines burst out and
// creep across the floor (an ellipse, camera looks down at a slant, sy = 0.6), curling as they go. A dotted green
// border marks the snare area the whole time (foes inside are slowed and hurt), little thorn spikes poke up out of
// the ground (up the screen = up out of the floor), and at the end the vines wither and pull back.
// Lasts 1.6 s (the game speeds it up / slows it down to match the patch's life).
import { fit, clamp, smooth, rng, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Thorn patch (top-down)",
  desc: "A seed pops and thorny vines creep out over the floor inside a marked snare ring, thorns poking up, then wither.",
  tags: ["nature", "roots", "thorns", "snare", "zone", "top-down", "one-shot"],
  size: [64, 48],
  origin: [32, 26],
  duration: 1.6,
  loop: false,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#0e1a08", "#1e3a10", "#2e6418", "#4a9a24", "#7ed040", "#c4f07a", "#f0ffd0"],
    wood: ["#1a0f08", "#3a2414", "#5e3c20", "#86603a"],
    reach: 20, sy: 0.6, seed: 6,
  },
};

const GROW = 0.28, WITHER = 1.25;

export function draw(p, t, o) {
  const C = fit(o.palette, 7), W = fit(o.wood, 4), R = o.reach, SY = o.sy;
  const grow = 1 - Math.pow(1 - clamp(t / GROW), 3);
  const wither = smooth(WITHER, meta.duration, t);
  const alive = 1 - wither;
  if (alive <= 0.001) return;
  // seed pop
  if (t < 0.12) {
    const k = t / 0.12;
    p.circle(0, 0, 2.5 * (1 - k) + 0.5, C[5]);
    p.glow(0, 0, 10, C[4], 0.7 * (1 - k));
    for (let i = 0; i < 8; i++) { const g = (i / 8) * TAU; p.dot(Math.cos(g) * 8 * k, Math.sin(g) * 8 * k * SY, C[6], 1 - k); }
  }
  // snare border: a dotted green ring on the floor at the patch edge, slowly marching
  const br = R * grow;
  if (br > 2) {
    const n = Math.ceil(TAU * br * 1.3);
    for (let i = 0; i < n; i++) {
      if ((i + Math.floor(t * 20)) % 3 === 0) continue;
      const g = (i / n) * TAU;
      p.dot(Math.cos(g) * br, Math.sin(g) * br * SY, C[4], 0.85 * alive);
    }
    // faint tint over the floor inside
    for (let y = Math.floor(-br * SY); y <= Math.ceil(br * SY); y++)
      for (let x = Math.floor(-br); x <= Math.ceil(br); x++) {
        const d = Math.hypot(x / br, y / (br * SY));
        if (d < 1) p.blend(x, y, C[2], 0.18 * alive);
      }
  }
  // vines: creep outward and curl; wood stem with a green lit edge, thorns sticking out sideways
  const rv = rng(o.seed, 1);
  for (let v = 0; v < 7; v++) {
    const g0 = (v / 7) * TAU + rv.range(-0.25, 0.25), curl = rv.range(0.6, 1.3) * (v % 2 ? 1 : -1);
    const len = R * rv.range(0.8, 1.0) * grow * (1 - wither);   // pulls all the way back
    let prevx = 0, prevy = 0;
    for (let d = 1; d < len; d += 0.6) {
      const q = d / R, g = g0 + curl * q * q * 0.9 + Math.sin(t * 4 + v) * 0.04;
      const x = Math.cos(g) * d, y = Math.sin(g) * d * SY;
      const thick = q < 0.45;
      p.px(x, y, wither > 0.4 ? W[1] : W[2]);
      if (thick) p.px(x, y - 1, wither > 0.4 ? C[1] : C[3]);
      // thorns: every few px, a pale spike sideways
      if (Math.floor(d) % 4 === 2 && Math.abs(d - Math.floor(d)) < 0.6) {
        const nx = -Math.sin(g), ny = Math.cos(g) * SY, sgn = Math.floor(d) % 8 < 4 ? 1 : -1;
        p.px(x + nx * sgn * 1.2, y + ny * sgn * 1.2, W[3]);
        p.px(x + nx * sgn * 2.2, y + ny * sgn * 2.2, C[5]);
      }
      prevx = x; prevy = y;
    }
    // a leaf bud at the tip
    if (len > 3) { p.px(prevx, prevy, C[4]); p.px(prevx + 1, prevy, C[5]); p.light(prevx, prevy, C[4], 0.35 * alive); }
  }
  // thorn spikes poking up out of the ground inside the patch (rise fast, sink when withering)
  const rs = rng(o.seed, 2);
  for (let i = 0; i < 9; i++) {
    const g = rs.range(0, TAU), d = Math.sqrt(rs.next()) * R * 0.85, delay = rs.range(0.08, 0.3);
    const h = Math.round(rs.range(3, 6) * clamp((t - delay) / 0.12) * (1 - wither));
    if (h < 1 || d > br) continue;
    const x = Math.cos(g) * d, y = Math.sin(g) * d * SY;
    p.px(x, y, W[1]);
    for (let k = 1; k <= h; k++) p.px(x, y - k, k === h ? C[6] : k > h - 2 ? C[4] : W[2]);
    if (h > 3) p.px(x + 1, y - 1, W[1]);
  }
  // glow over the patch while it holds, a few spores drifting up
  p.glow(0, 0, R * 0.9, C[3], 0.2 * grow * alive);
  const rp = rng(o.seed, 3);
  for (let i = 0; i < 5; i++) {
    const k = ((t * 0.9 + i / 5) % 1), g = rp.range(0, TAU), d = rp.range(0.1, 0.8) * R;
    p.dot(Math.cos(g) * d, Math.sin(g) * d * SY - k * 8, k < 0.4 ? WHITE : C[5], (1 - k) * alive * grow);
  }
}

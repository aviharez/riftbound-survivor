// Venom Bloom poison cloud for Riftbound (top-down): a toxic stain lies flat on the floor ellipse (sy = 0.6),
// soft translucent green puffs churn slowly around the centre (lit on top, darker underneath), glowing spores
// rise up the screen (into the air) and fade, and small bubbles pop on the stain. Seamless loop.
import { fit, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Venom cloud (top-down)",
  desc: "A churning poison cloud over a toxic floor stain, seen from above: translucent green puffs, rising glowing spores, popping bubbles.",
  tags: ["nature", "poison", "cloud", "dot", "aoe", "top-down", "loop"],
  size: [84, 64],
  origin: [42, 36],
  duration: 2.0,
  loop: true,
  fps: 30,
  bg: "ground",
  options: { palette: ["#0a1a0a", "#163a12", "#2a6a1a", "#4aa02a", "#8ad040", "#c8f070", "#f4ffc0"], reach: 30, sy: 0.6, seed: 4 },
};

export function draw(p, t, o) {
  const C = fit(o.palette, 7), R = o.reach, SY = o.sy, ph = (t / meta.duration) * TAU;
  // toxic stain lying flat on the floor: translucent, darker toward the rim
  for (let y = Math.floor(-R * SY); y <= Math.ceil(R * SY); y++)
    for (let x = Math.floor(-R); x <= Math.ceil(R); x++) {
      const d = Math.hypot(x / R, y / (R * SY));
      if (d < 1) p.blend(x, y, d > 0.85 ? C[3] : C[2], d > 0.85 ? 0.45 : 0.28);
    }
  // bubbles popping on the stain
  for (let i = 0; i < 6; i++) {
    const k = ((t / meta.duration) * 2 + i / 6) % 1, g = i * 2.4, d = (0.2 + 0.12 * i) * R;
    const x = Math.cos(g) * d, y = Math.sin(g) * d * SY;
    if (k < 0.6) p.ring(x, y, 1 + 1.6 * k, 0.8, C[5], 1 - k);
    else if (k < 0.7) { p.px(x - 2, y, C[6]); p.px(x + 2, y, C[6]); p.px(x, y - 2, C[6]); }
  }
  // churning puffs: each circles the centre once (or twice) per loop and breathes, so the loop is seamless
  for (let i = 0; i < 9; i++) {
    const turns = i % 3 === 0 ? 2 : 1, dir = i % 2 ? 1 : -1;
    const g = (i / 9) * TAU + dir * ph * turns * 0.5;
    const d = R * (0.25 + 0.45 * ((i * 37) % 9) / 9);
    const x = Math.cos(g) * d, y = Math.sin(g) * d * SY - 4 - (i % 3) * 2;
    const r = 6 + (i % 4) + 1.5 * Math.sin(ph * turns + i);
    p.disc(x, y + 1, r, C[1], 0.25);                                  // shadowed underside
    p.disc(x, y, r, (d2) => (d2 < 0.45 ? C[4] : C[3]), (d2) => 0.32 * (1 - d2 * 0.6));
    p.disc(x - r * 0.25, y - r * 0.3, r * 0.45, C[5], 0.22);          // lit top
  }
  p.glow(0, -4, R * 0.9, C[4], 0.22);
  // spores rising up the screen (into the air), drifting and fading
  for (let i = 0; i < 14; i++) {
    const k = ((t / meta.duration) + i / 14) % 1, g = i * 1.9, d = R * (0.1 + 0.07 * (i % 9));
    const x = Math.cos(g) * d + Math.sin(ph + i) * 2, y = Math.sin(g) * d * SY - 4 - k * 20;
    const c = k < 0.3 ? WHITE : k < 0.6 ? C[6] : C[5];
    p.dot(x, y, c, 1 - k);
    if (k < 0.7) p.light(x, y, C[5], 0.5 * (1 - k));
  }
}

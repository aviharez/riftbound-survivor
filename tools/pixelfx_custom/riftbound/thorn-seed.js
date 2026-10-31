// Thornseed for Riftbound: a spinning green seed pod with a leafy trail, facing right; the game rotates it to its
// flight direction. On hit the game plays root-snare where it lands.
import { fit, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Thornseed",
  desc: "A small green-gold seed pod tumbling through the air, a faint leafy green trail behind it and a tiny glowing sprout tip.",
  tags: ["projectile", "nature", "seed", "directional", "top-down", "loop"],
  size: [40, 18],
  origin: [30, 9],
  duration: 0.4,
  loop: true,
  fps: 20,
  bg: "dark",
  options: { palette: ["#14280e", "#2a5418", "#3e8a22", "#6cc232", "#b4ec5a", "#eaffb0"], length: 20 },
};

export function draw(p, t, o) {
  const C = fit(o.palette, 6), L = o.length, w = (t / meta.duration) * TAU;
  // trail: wavy green ribbon with leaf flecks
  for (let x = -3; x > -L; x--) {
    const u = -x / L, y = Math.sin(x * 0.5 + w) * 1.2 * u;
    p.dot(x, y, u < 0.3 ? C[4] : u < 0.65 ? C[3] : C[2], 1 - u);
  }
  for (let i = 0; i < 3; i++) {
    const x = -5 - i * 5 - ((t * 40) % 5), y = (i % 2 ? 1 : -1) * (2 + Math.sin(w + i));
    p.dot(x, y, C[3], 0.8 - i * 0.2); p.dot(x - 1, y, C[2], 0.6 - i * 0.15);
  }
  p.glowLine(-2, 0, -L * 0.6, 0, 4, C[3], 0.25);
  // seed: an oval pod spinning (its stripe rolls round)
  p.ellipse(0, 0, 4, 3, C[1]);
  p.ellipse(0, 0, 3.2, 2.2, C[2]);
  const sx = Math.cos(w) * 2.4;
  p.dot(sx, -1, C[4]); p.dot(sx, 0, C[3]); p.dot(sx, 1, C[3]);
  p.dot(-1, -1, C[4]);
  // sprout tip glowing at the nose
  p.dot(4, -1, C[4]); p.dot(5, -2, C[5]); p.px(5, -2, C[5]);
  p.glow(4, -1, 5, C[4], 0.35);
  p.light(5, -2, WHITE, 0.4);
}

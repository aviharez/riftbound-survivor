// Rune Chakram for Riftbound (top-down): a spinning bladed disc seen from above. A gold rim with three hooked
// blades, a ring of cyan runes turning the other way, a bright gem in the middle and faint motion arcs.
// Seamless loop: the disc has 3-fold symmetry, so one loop turns it a third of a circle.
import { fit, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Rune chakram (top-down)",
  desc: "A spinning gold chakram with three hooked blades, a counter-rotating ring of cyan runes and a glowing gem, seen from above.",
  tags: ["projectile", "disc", "boomerang", "rune", "top-down", "loop"],
  size: [40, 40],
  origin: [20, 20],
  duration: 0.24,
  loop: true,
  fps: 30,
  bg: "dark",
  options: {
    palette: ["#2a1606", "#6a3c0c", "#b0741a", "#e8b030", "#ffe07a", "#fff6cc"],
    rune: ["#0a2a3a", "#1a6a8a", "#3ac0e0", "#a0f0ff", "#ffffff"],
    seed: 1,
  },
};

export function draw(p, t, o) {
  const G = fit(o.palette, 6), U = fit(o.rune, 5);
  const k = t / meta.duration, a = k * (TAU / 3), ar = -k * (TAU / 3);
  // motion arcs: faint swept rings behind each blade
  for (let b = 0; b < 3; b++) {
    const g0 = a + (b / 3) * TAU;
    for (let i = 1; i < 10; i++) {
      const g = g0 - i * 0.09;
      p.dot(Math.cos(g) * 12, Math.sin(g) * 12, i < 4 ? G[4] : G[2], 0.55 * (1 - i / 10));
    }
  }
  // three hooked blades: solid swept hooks leaving the rim, lit edge on the leading side
  for (let b = 0; b < 3; b++) {
    const g = a + (b / 3) * TAU, P = (gg, r) => [Math.cos(gg) * r, Math.sin(gg) * r];
    p.poly([P(g - 0.2, 9.5), P(g + 0.25, 10), P(g + 0.75, 15), P(g + 0.3, 13.5)], G[2]);
    p.poly([P(g - 0.05, 10), P(g + 0.3, 10.5), P(g + 0.72, 14.5)], G[4]);
    const tip = P(g + 0.75, 15);
    p.px(tip[0], tip[1], WHITE);
    p.light(tip[0], tip[1], G[4], 0.6);
  }
  // gold rim: dark outer edge, bright inner edge, lit from the top-left
  p.ring(0, 0, 9.5, 2.2, (d, ang) => (Math.cos(ang + 2.3) > 0.3 ? G[4] : G[3]));
  p.ring(0, 0, 10.4, 0.9, G[1]);
  // runes: six ticks turning the other way
  for (let i = 0; i < 6; i++) {
    const g = ar + (i / 6) * TAU, x = Math.cos(g) * 5.5, y = Math.sin(g) * 5.5;
    p.px(x, y, U[3]);
    if (i % 2 === 0) { p.px(x + Math.cos(g + 1.57), y + Math.sin(g + 1.57), U[2]); }
    p.light(x, y, U[2], 0.45);
  }
  p.ring(0, 0, 7, 0.8, U[1]);
  // centre gem
  p.circle(0, 0, 2.3, U[2]);
  p.px(-0.5, -0.5, WHITE);
  p.glow(0, 0, 9, U[2], 0.4);
  p.glow(0, 0, 18, G[3], 0.15);
}

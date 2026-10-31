// Arcane Mine rune for Riftbound (top-down): a glowing sigil lying flat on the floor (an ellipse, sy = 0.6):
// an outer ring of turning tick marks, an inner ring, a triangle rune and a pulsing core, with motes rising
// up the screen from it. Seamless loop; the game draws it while the mine waits.
import { fit, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Rune sigil (top-down)",
  desc: "A pulsing arcane sigil lying flat on the floor: turning outer ticks, inner ring, triangle rune, rising motes.",
  tags: ["arcane", "rune", "trap", "mine", "top-down", "loop"],
  size: [40, 30],
  origin: [20, 17],
  duration: 1.2,
  loop: true,
  fps: 30,
  bg: "ground",
  options: { palette: ["#140a2e", "#3a1a7a", "#6a3cd0", "#4a9ce0", "#7ce0ff", "#d0f8ff", "#ffffff"], reach: 12, sy: 0.6, seed: 2 },
};

export function draw(p, t, o) {
  const C = fit(o.palette, 7), R = o.reach, SY = o.sy, ph = (t / meta.duration) * TAU;
  const pulse = 0.5 + 0.5 * Math.sin(ph);
  const F = (g, r) => [Math.cos(g) * r, Math.sin(g) * r * SY];
  // outer ring of ticks, turning (12 ticks: a loop turns it by one tick spacing)
  for (let i = 0; i < 12; i++) {
    const g = (i / 12) * TAU + (t / meta.duration) * (TAU / 12);
    for (let s = -1; s <= 1; s++) { const [x, y] = F(g + s * 0.08, R); p.px(x, y, s === 0 ? C[4] : C[2]); }
  }
  // inner ring
  for (let i = 0; i < 48; i++) { const [x, y] = F((i / 48) * TAU, R * 0.68); p.dot(x, y, C[4], 0.85); }
  // triangle rune, counter-turning slowly
  const tri = [0, 1, 2].map((k) => F(-(t / meta.duration) * (TAU / 3) + (k / 3) * TAU - Math.PI / 2, R * 0.6));
  for (let k = 0; k < 3; k++) p.line(tri[k][0], tri[k][1], tri[(k + 1) % 3][0], tri[(k + 1) % 3][1], C[6]);
  for (let k = 0; k < 3; k++) p.light(tri[k][0], tri[k][1], C[4], 0.5);
  // core
  p.px(0, 0, pulse > 0.5 ? WHITE : C[5]);
  if (pulse > 0.7) { p.px(-1, 0, C[5]); p.px(1, 0, C[5]); }
  p.glow(0, 0, R * 1.1, C[3], 0.25 + 0.2 * pulse);
  p.glow(0, 0, 4, C[5], 0.25 + 0.25 * pulse);
  // motes rising up the screen from the sigil
  for (let i = 0; i < 5; i++) {
    const k = ((t / meta.duration) + i / 5) % 1, [x0, y0] = F(i * 1.3, R * 0.7);
    p.dot(x0, y0 - k * 9, k < 0.4 ? C[6] : C[4], 1 - k);
  }
}

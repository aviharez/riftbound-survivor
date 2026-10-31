// Astral blade for Riftbound: one spectral sword lying flat, blade pointing right (+x) from the hilt at the
// origin. The game orbits several of them round the hero, rotated so the blade points outward, and draws the
// curved trail itself (a baked trail would be straight). A glint runs down the edge each loop.
import { fit, clamp, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Astral blade",
  desc: "A small spectral sword made of starlight: violet hilt and crossguard, a pale cyan blade with a bright edge, a glint sliding from hilt to tip and a soft glow.",
  tags: ["melee", "sword", "orbit", "arcane", "top-down", "loop"],
  size: [44, 20],
  origin: [6, 10],
  duration: 0.6,
  loop: true,
  fps: 20,
  bg: "dark",
  options: { palette: ["#1a1040", "#3a2a8a", "#6a4ad0", "#3aa6e0", "#7ad8f8", "#c4f4ff", "#ffffff"], length: 26 },
};

export function draw(p, t, o) {
  const C = fit(o.palette, 7), L = o.length, u = t / meta.duration;
  // soft halo along the whole blade
  p.glowLine(2, 0, L, 0, 6, C[4], 0.32);
  // pommel and grip
  p.circle(-3, 0, 1.6, C[2]);
  p.px(-3, 0, C[5]);
  p.rect(-2, -1, 4, 2, C[1]);
  p.dot(-1, -1, C[2]);
  // crossguard: a short bar across the blade, tips curling back
  p.rect(2, -5, 2, 10, C[2]);
  p.px(2, -5, C[1]); p.px(2, 4, C[1]);
  p.px(1, -6, C[2]); p.px(1, 5, C[2]);
  p.px(3, -1, C[5]); p.px(3, 0, C[5]);
  // blade: 4 px wide at the guard, tapering to a point; dark spine, cyan body, white upper edge
  for (let x = 4; x <= L; x++) {
    const k = (x - 4) / (L - 4), half = 2 * (1 - Math.pow(k, 3)) + 0.4;
    for (let y = -Math.round(half); y <= Math.round(half) - 1; y++) {
      const edge = y === -Math.round(half);
      p.dot(x, y, edge ? C[6] : y === 0 ? C[3] : C[4], 1);
    }
  }
  p.px(L + 1, -1, C[5]);
  // glint sliding from guard to tip in the first half of the loop
  const g = clamp(u * 2);
  if (g < 1) {
    const gx = 4 + g * (L - 4);
    for (let i = -2; i <= 2; i++) p.dot(gx + i, -1, WHITE, 1 - Math.abs(i) / 3);
    p.glow(gx, -1, 5, WHITE, 0.5 * Math.sin(Math.PI * g));
    p.light(gx, -1, C[5], 0.8);
  }
  // star twinkle at the tip
  const tw = 0.5 + 0.5 * Math.sin(u * TAU * 2);
  p.dot(L + 2, -1, C[6], tw);
  p.glow(L, -1, 4, C[5], 0.25 + 0.2 * tw);
}

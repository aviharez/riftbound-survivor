// Top-down arcane bolt for Riftbound. Faces right; the game rotates it to the flight direction, so the trail
// always lies straight behind the head. Head-and-trail layering after src/fx/projectiles/plasma-shot.js.
import { fit, cycle, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Arcane bolt",
  desc: "A small cyan arcane bolt: a white-hot core with a flickering rim, a straight tapering trail that cools from white to deep blue, and sparks that peel off the tail and wink out.",
  tags: ["projectile", "arcane", "magic", "directional", "top-down", "loop"],
  size: [72, 24],
  origin: [56, 12],
  duration: 0.4,
  loop: true,
  fps: 30,
  bg: "dark",
  options: { palette: ["#0a1030", "#14306a", "#1f62a8", "#2ea6d8", "#62dcf4", "#b4f4ff", "#ffffff"], length: 30, seed: 5 },
};

export function draw(p, t, o) {
  const C = fit(o.palette, 7), L = o.length, D = meta.duration, w = (TAU * t) / D;
  const fr = Math.floor(t * 30 + 1e-6);

  // trail: a 2 px ribbon straight behind the head, tapering to 1 px, cooling white -> cyan -> blue
  for (let x = -2; x > -L; x--) {
    const u = -x / L, c = u < 0.18 ? C[6] : u < 0.4 ? C[5] : u < 0.7 ? C[4] : C[3];
    const shimmer = 0.5 + 0.5 * Math.sin(x * 0.9 + w * 3);
    p.dot(x, 0, c, u < 0.75 ? 1 : (1 - u) / 0.25);
    if (u < 0.55) p.dot(x, -1, u < 0.25 ? C[5] : C[4], (1 - u / 0.55) * (0.6 + 0.4 * shimmer));
    if (u < 0.3) p.dot(x, 1, C[4], (1 - u / 0.3) * 0.7);
  }
  p.glowLine(-2, 0, -L * 0.7, 0, 5, C[4], 0.35);

  // sparks that peel off the tail and fall behind, deterministic and seamless
  cycle(t, D, 6, o.seed, (r) => r.range(0.2, 0.35), (age, life, r) => {
    const k = age / life, x = -r.range(4, L * 0.6) - 40 * age, y = r.sign() * (1 + 18 * age * r.range(0.4, 1));
    p.dot(x, y, k < 0.4 ? C[6] : C[4], 1 - k);
    if (k < 0.3) p.light(x, y, C[5], 0.4);
  });

  // head: deep rim, cyan body, white core; a flickering 4-ray glint
  p.circle(0, 0, 3.2, C[3]);
  p.circle(0, 0, 2.4, C[4]);
  p.circle(0.4, -0.3, 1.5, C[5]);
  p.px(0, 0, WHITE);
  p.px(1, 0, WHITE);
  const arm = 3 + (fr % 3);
  for (let i = 1; i <= arm; i++) {
    const a = 1 - i / (arm + 1);
    p.dot(i + 2, 0, C[6], a);
    p.dot(0, -i - 2, C[5], a * 0.7);
    p.dot(0, i + 2, C[5], a * 0.7);
  }
  p.glow(0, 0, 12, C[5], 0.45);
  p.glow(0, 0, 4, WHITE, 0.28);
}

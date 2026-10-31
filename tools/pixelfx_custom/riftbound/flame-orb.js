// Top-down orbiting fire orb for Riftbound. Faces right (the direction it travels); the game rotates it to the
// tangent of its orbit, so the flames always stream back along the circle. After src/fx/projectiles/plasma-shot.js.
import { fit, cycle, noise2, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Flame orb",
  desc: "A small comet of fire: a white-hot core in an orange ball, ragged flame tongues licking back from it, embers peeling off the tail and cooling to red.",
  tags: ["fire", "orb", "projectile", "directional", "top-down", "loop"],
  size: [56, 28],
  origin: [40, 14],
  duration: 0.5,
  loop: true,
  fps: 30,
  bg: "dark",
  options: { palette: ["#2a0802", "#6e1a04", "#b8320a", "#f06a12", "#ffa42e", "#ffd97a", "#fff6dc"], length: 22, seed: 9 },
};

export function draw(p, t, o) {
  const C = fit(o.palette, 7), L = o.length, D = meta.duration, ph = t / D;

  // flame tongues: a tapering body behind the head whose outline flickers with looping noise
  p.shade(-L - 2, -9, 4, 9, (x, y) => {
    if (x > 0) return;
    const u = -x / L;
    if (u > 1) return;
    const n = noise2(x * 0.35 - ph * 18, y * 0.5 + 3.1, 7) * 0.5 + noise2(x * 0.35 - (ph - 1) * 18, y * 0.5 + 3.1, 7) * 0.5;
    // ragged tongues: width swings hard with the noise, and the far tail breaks into separate licks
    const half = (5 - 4.3 * u) * (0.6 + 0.8 * n);
    const d = Math.abs(y) / Math.max(0.5, half);
    if (d > 1 || (u > 0.62 && n < 0.26)) return;
    const heat = (1 - u) * (1 - d * 0.7) + n * 0.2;
    return heat > 0.85 ? C[5] : heat > 0.6 ? C[4] : heat > 0.38 ? C[3] : heat > 0.2 ? C[2] : C[1];
  });

  // embers peeling off the tail, drifting outward and cooling
  cycle(t, D, 7, o.seed, (r) => r.range(0.25, 0.45), (age, life, r) => {
    const k = age / life, x = -r.range(6, L * 0.8) - 30 * age, y = r.sign() * (1.5 + 22 * age * r.range(0.3, 1));
    p.dot(x, y, k < 0.35 ? C[5] : k < 0.7 ? C[3] : C[2], 1 - k * 0.8);
    if (k < 0.4) p.light(x, y, C[4], 0.35);
  });

  // head: dark rim, orange ball, yellow inner, white-hot core
  p.circle(0, 0, 3.6, C[3]);
  p.circle(0.3, -0.2, 2.7, C[4]);
  p.circle(0.6, -0.4, 1.6, C[5]);
  p.px(1, 0, WHITE);
  p.px(0, -1, WHITE);
  p.glowLine(0, 0, -L * 0.6, 0, 6, C[3], 0.35);
  p.glow(0, 0, 13, C[4], 0.5);
  p.glow(0, 0, 4, C[6], 0.35);
}

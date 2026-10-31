// Top-down frost nova for Riftbound: the ring lies on the floor as an ellipse and crystals erupt all the way
// round it (a far half behind the caster, a near half in front). Techniques after src/fx/ice/frost-nova.js.
import { Particles, Bits, Lights, P, B, Rng, fit, crystal, band, flare, clamp, smooth, ease, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Frost nova (top-down)",
  desc: "A cold flash at the caster's feet, a ring of frost racing out across the floor, a full circle of ice crystals punching up behind it, glints, then the ice sinks away.",
  tags: ["ice", "nova", "aoe", "frost", "top-down", "one-shot"],
  size: [184, 128],
  origin: [92, 74],
  duration: 1.45,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#151a3d", "#212f6b", "#2c58aa", "#3a8bd8", "#62c8f4", "#a6ecff", "#dcfbff", "#ffffff"], reach: 60, sy: 0.62, seed: 7 },
};

const CHARGE = 0.1, SPREAD = 0.28, HOLD = 0.85, MELT = 0.4;

export function create(o) {
  const C = fit(o.palette, 8), DIM = [C[0], C[0], C[1], C[2], C[3], C[4], C[5], C[6]];
  // top-down: there is no single floor line, so particles never land (a y = 0 floor would stack them into a stripe)
  const REACH = o.reach, SY = o.sy, R = new Rng(o.seed), floor = () => 1e6;
  const ps = new Particles({ rng: R, ground: floor, sparks: [C[7], C[6], C[5], C[4]], haze: C[5] });
  const bits = new Bits({ ground: floor }), lights = new Lights();
  const front = (t) => (t < CHARGE ? 0 : REACH * (1 - Math.pow(1 - clamp((t - CHARGE) / SPREAD), 3)));
  const reachedAt = (d) => CHARGE + SPREAD * (1 - Math.cbrt(1 - Math.min(1, d / REACH)));
  // crystals on two rings round the full circle; y = sin(angle) * r * SY puts them on the floor ellipse
  const sites = [];
  for (const [q, n, h, w] of [[0.5, 7, [6, 9], [4, 6]], [0.92, 12, [8, 13], [5, 7]]])
    for (let i = 0; i < n; i++) {
      const a = (i / n) * TAU + R.range(-0.18, 0.18), d = q * REACH * R.range(0.92, 1.06);
      const x = Math.cos(a) * d, y = Math.sin(a) * d * SY, hh = R.range(...h);
      sites.push({ x, y, h: hh, w: R.range(...w), lean: Math.cos(a) * hh * R.range(0.15, 0.35), back: y < 0, t0: reachedAt(d) + R.range(0, 0.02), up: false, phase: R.next() });
    }
  sites.sort((a, b) => a.y - b.y); // far crystals first
  let t = 0, released = false;
  const sink = (tt) => smooth(HOLD, HOLD + MELT, tt);

  const drawCrystals = (p, back) => {
    const m = sink(t);
    if (m >= 1) return;
    for (const s of sites) {
      if (!s.up || s.back !== back) continue;
      const g = ease.outBack(clamp((t - s.t0) / 0.08), 2.4), white = t < s.t0 + 0.03, sw = (((t - s.t0) * 0.9 + s.phase * 3) % 1.4) / 0.45;
      crystal(p, s.x, s.y, s.h * g * (1 - m), s.w * (1 - m * 0.3), s.lean * g * (1 - m), back ? DIM : C, { white, glint: sw <= 1 ? sw : -1 });
    }
  };
  const ring = (p, back) => {
    if (t < CHARGE) return;
    const u = clamp((t - CHARGE) / (SPREAD + 0.12));
    if (u >= 1) return;
    band(p, 0, 0, front(t) + 1, SY, Math.max(1.5, 6 * Math.pow(1 - u, 0.7)), u < 0.7 ? 1 : (1 - u) / 0.3, C, (g) => (Math.sin(g) < 0) === back, t - CHARGE < 0.08);
  };
  // frost crust on the floor: a pale translucent disc that grows with the front and fades as the ice melts
  const frost = (p) => {
    const fr = front(t), out = 1 - smooth(HOLD - 0.25, HOLD + MELT * 0.6, t);
    if (t < CHARGE || out <= 0) return;
    for (let y = -fr * SY; y <= fr * SY; y += 1)
      for (let x = -fr; x <= fr; x += 1) {
        const d = Math.hypot(x / fr, y / (fr * SY));
        if (d > 1) continue;
        // a ragged crust at the rim (broken by noise), a thin pale sheen inside
        const rim = d > 0.95 && ((Math.floor(x) * 7 + Math.floor(y) * 13) & 3) !== 0;
        if (rim) p.dot(x, y, C[5], 0.7 * out);
        else p.blend(x, y, C[5], (0.08 + 0.12 * (1 - d)) * out);
      }
  };

  return {
    update(dt) {
      t += dt;
      if (t >= CHARGE && !released) {
        released = true;
        lights.add(0, -6, 70, C[4], 0.85, 0.45);
        lights.add(0, -6, 30, WHITE, 0.8, 0.1);
        for (let i = 0; i < 18; i++) {
          const a = R.range(0, TAU), sp = R.range(90, 200);
          bits.add({ kind: B.SHARD, x: 0, y: -4, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * SY - R.range(40, 100), g: 0.35, drag: 1.4, bounce: 0.25, life: R.range(0.35, 0.6), a: R.range(0, TAU), va: R.range(-20, 20), s: R.range(1.2, 2.6), c: R.pick([C[7], C[6], C[5]]) });
        }
      }
      const fr = front(t);
      if (t > CHARGE && t < CHARGE + SPREAD)
        for (let i = 0; i < 3; i++) {
          const a = R.range(0, TAU);
          ps.spawn(P.VAPOUR, Math.cos(a) * fr, Math.sin(a) * fr * SY, Math.cos(a) * R.range(10, 40), Math.sin(a) * R.range(5, 20) - R.range(2, 8), R.range(0.35, 0.6), R.chance(0.7) ? C[6] : C[5], R.range(2, 3.5));
          if (R.chance(0.4)) ps.spawn(P.FLAKE, Math.cos(a) * fr, Math.sin(a) * fr * SY - 2, Math.cos(a) * R.range(10, 40), -R.range(20, 60), R.range(0.6, 1.0), R.chance(0.5) ? WHITE : C[6], R.range(0.5, 1.1));
        }
      for (const s of sites)
        if (!s.up && t >= s.t0) {
          s.up = true;
          for (let i = 0; i < 2; i++) {
            const a = -Math.PI / 2 + R.range(-1.2, 1.2), sp = R.range(50, 140);
            bits.add({ kind: B.SHARD, x: s.x, y: s.y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, g: 0.5, drag: 1.2, bounce: 0.3, life: R.range(0.3, 0.55), a: R.range(0, TAU), va: R.range(-18, 18), s: R.range(1, 2), c: R.pick([C[7], C[6]]) });
          }
          if (s.h > 8) ps.spawn(P.STAR, s.x, s.y - s.h * 0.7, 0, -3, R.range(0.25, 0.45), C[6], R.range(1, 2));
        }
      if (t > CHARGE + 0.2 && t < HOLD && R.chance(0.35)) {
        const s = R.pick(sites);
        if (s.up) ps.spawn(P.STAR, s.x + R.range(-2, 2), s.y - R.range(2, s.h * 0.9), 0, -3, R.range(0.25, 0.5), R.chance(0.6) ? C[6] : WHITE, R.range(0.6, 1.8));
      }
      ps.update(dt);
      bits.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      frost(p);
      ring(p, true);
      drawCrystals(p, true);
      ps.draw(p, "back");
    },
    draw(p) {
      ring(p, false);
      drawCrystals(p, false);
      if (t < CHARGE + 0.16) {
        const a = clamp((t - CHARGE) / 0.16);
        if (t < CHARGE) p.glow(0, -6, 10 + 30 * (t / CHARGE), C[5], 0.5);
        else {
          flare(p, 0, -6, 28 * Math.pow(1 - a, 1.5), 1 - a, C);
          p.glow(0, -6, 36, WHITE, 0.6 * (1 - a));
        }
      }
      if (t > CHARGE) {
        const k = 1 - smooth(HOLD, HOLD + MELT, t), fr = front(t);
        p.glow(0, 0, fr * 0.9 + 8, C[4], 0.22 * k);
      }
      bits.draw(p);
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}

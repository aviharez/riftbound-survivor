// Crescent Slash for Riftbound (top-down): a flying crescent of moonlight seen from above, flat in the ground
// plane. Faces right (the game rotates it to the flight direction): the bright convex edge leads, the body fades
// from white through ice blue to violet toward the horns, with speed streaks trailing behind and a few glints.
// A short seamless loop (the edge shimmers), played as the projectile's look.
import { fit, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Crescent slash (top-down)",
  desc: "A flying moonlit crescent seen from above: bright leading edge, blue-to-violet body fading to the horns, trailing streaks.",
  tags: ["melee", "slash", "projectile", "moon", "top-down", "loop"],
  size: [56, 56],
  origin: [34, 28],
  duration: 0.4,
  loop: true,
  fps: 30,
  bg: "dark",
  options: { palette: ["#140a2e", "#2c1a66", "#5a3cb0", "#4a7ce0", "#7cc0ff", "#c8ecff", "#ffffff"], seed: 3 },
};

const RO = 20, OX = -8;   // outer circle: radius, centre x
const RI = 19, IX = -15;  // inner circle (the bite): radius, centre x

export function draw(p, t, o) {
  const C = fit(o.palette, 7), ph = (t / meta.duration) * TAU;
  // trailing speed streaks behind the crescent (to the left), flickering
  for (let i = 0; i < 7; i++) {
    const y = -14 + i * 4.6, len = 8 + 5 * Math.abs(Math.sin(ph + i * 1.7));
    if (Math.abs(y) > RI - 1) continue;
    const x0 = IX + Math.sqrt(RI * RI - y * y) - 1;   // starts at the bite, runs out behind the crescent
    for (let k = 0; k < len; k++) p.dot(x0 - k, y, k < 2 ? C[4] : C[3], (1 - k / len) * 0.75);
  }
  // body: inside the outer circle, outside the inner one
  p.shade(-30, -22, 14, 22, (x, y, out) => {
    const dO = Math.hypot(x - OX, y), dI = Math.hypot(x - IX, y);
    if (dO > RO || dI < RI) return;
    const edge = RO - dO;                         // 0 at the leading edge
    const horn = Math.abs(y) / RO;                 // 0 middle .. 1 at the horn tips
    const shimmer = 0.5 + 0.5 * Math.sin(ph * 2 + y * 0.5);
    let c;
    if (edge < 1) c = horn < 0.75 ? WHITE : C[5];
    else if (edge < 2) c = horn < 0.55 ? C[6] : horn < 0.8 ? C[5] : C[4];
    else if (edge < 3.5) c = horn < 0.5 ? C[5] : horn < 0.8 ? C[4] : C[3];
    else c = horn < 0.6 ? C[4] : C[2];
    out.c = c;   // solid pixels: the horns taper by shape, not by dithering
    if (edge < 2) { out.l = C[5]; out.k = (0.35 + 0.25 * shimmer) * (1 - horn * 0.7); }
  });
  // dark rim on the inner (bite) side, so the crescent reads against bright ground
  for (let i = 0; i < 40; i++) {
    const g = -1.05 + (i / 39) * 2.1, x = IX + Math.cos(g) * RI, y = Math.sin(g) * RI;
    if (Math.hypot(x - OX, y) < RO - 0.5) p.dot(x - 0.5, y, C[1], 0.6);
  }
  p.glow(OX + RO - 3, 0, 12, C[4], 0.35);
  // glints running along the edge
  for (let i = 0; i < 2; i++) {
    const g = Math.sin(ph + i * Math.PI) * 0.9, x = OX + Math.cos(g) * (RO - 0.5), y = Math.sin(g) * (RO - 0.5);
    p.px(x, y, WHITE);
    p.light(x, y, C[5], 0.8);
  }
}

# Riftbound: Arcane Academy — Weapon & Attack Design

## 1. Design Goals

Riftbound: Arcane Academy is a portrait-oriented fantasy roguelite with ricochet-based combat. Its weapon system should support varied builds, satisfying visual effects (VFX), and distinct combat patterns.

The core principle is that weapons should differ in more than damage and color. Each weapon should have a recognizable:
- Projectile or attack pattern.
- Targeting behavior.
- Interaction with enemies and the arena.
- Visual silhouette and impact effect.
- Upgrade path and potential synergies.

### Weapon Categories

1. **Character Signature Weapons** — a character's defining starting attack.
2. **General Weapons** — available to multiple or all characters.
3. **Passive Skills and Modifiers** — improve weapons, change their behavior, or support a build.

A suggested long-term target is approximately 30–40 active weapons, supported by 15–20 passive skills or modifiers. This is a content target, not a requirement for the first prototype.

---

## 2. Character Signature Weapons

Signature weapons define a character's identity and should remain recognizable in both gameplay and VFX.

### 2.1 Lyra Emberveil — Flame Orb

- **Element:** Fire
- **Role:** Damage / Ricochet
- **Base behavior:** Fires a fireball that ricochets between enemies and/or suitable arena surfaces.
- **VFX:** Orange-hot core, red outer flame, ember trail, star-shaped impact burst.
- **Upgrade ideas:**
  - Increase ricochet count.
  - Split into smaller fireballs.
  - Leave a burning zone on impact.
- **Evolution:** **Solar Cataclysm** — the orb becomes a miniature sun and detonates after several ricochets.

### 2.2 Selene Frostvale — Frost Lance

- **Element:** Ice
- **Role:** Piercing / Crowd control
- **Base behavior:** Launches an ice spear through multiple enemies, leaving shards behind.
- **VFX:** Translucent blue crystal, cyan streak, ice fragments, cold mist.
- **Upgrade ideas:**
  - Increase piercing count.
  - Add a chance to freeze.
  - Spawn shards after piercing a target.
- **Evolution:** **Absolute Zero** — the spear triggers a crystal explosion that freezes an area.

### 2.3 Noah Verdant — Thornseed

- **Element:** Nature
- **Role:** Spread / Damage over time
- **Base behavior:** Fires enchanted seeds that grow thorns or roots when hitting enemies.
- **VFX:** Green leaves, glowing seeds, roots spreading across the ground.
- **Upgrade ideas:**
  - Branching roots.
  - Poison effect.
  - Thorns that pierce multiple enemies.
- **Evolution:** **Worldroot Bloom** — massive roots spread across the arena and trap enemies.

These are initial character concepts. Additional characters may introduce lightning, wind, shadow, holy, or gravity themes.

---

## 3. General Weapons

General weapons can be selected by multiple characters during level-up. Their behaviors should provide meaningful differences between builds.

### A. Projectile & Ricochet

#### 4. Arcane Bolt
- **Role:** Single target / Ricochet
- **Behavior:** A magic orb targets an enemy and ricochets a limited number of times.
- **VFX:** Cyan core and geometric energy trail.
- **Evolution:** **Prismatic Barrage** — multiple bolts with different elemental colors.

#### 5. Chain Lightning
- **Role:** Chain / Crowd clear
- **Behavior:** Electricity jumps from one enemy to another.
- **VFX:** Sharp cyan-white zigzag arcs.
- **Evolution:** **Thunderstorm Network** — chains connect many enemies simultaneously.

#### 6. Phantom Orb
- **Role:** Ricochet / Multi-hit
- **Behavior:** A violet orb leaves an afterimage with each bounce; afterimages repeat attacks after a delay.
- **VFX:** Purple orb and ghostly trails.
- **Evolution:** **Eternal Echo** — attacks propagate through previous orb trails.

#### 7. Seeker Wisps
- **Role:** Homing / Multi-target
- **Behavior:** Small spirits automatically pursue nearby enemies.
- **VFX:** Floating lights and curved trails.
- **Evolution:** **Astral Constellation** — wisps form a constellation pattern before attacking.

### B. Area of Effect

#### 8. Meteor Fall
- **Role:** Delayed AoE / Burst
- **Behavior:** Meteors strike marked enemy locations.
- **VFX:** Burning meteor trails, dust, and glowing ground cracks.
- **Evolution:** **Starfall** — multiple meteors strike in sequence.

#### 9. Void Well
- **Role:** Pull / AoE setup
- **Behavior:** Creates a singularity that pulls enemies inward before detonating.
- **VFX:** Spiral vortex and particles pulled toward the center.
- **Evolution:** **Event Horizon** — a larger and stronger gravitational field.

#### 10. Arcane Mine
- **Role:** Trap / Delayed burst
- **Behavior:** Places a rune that detonates when an enemy approaches.
- **VFX:** Glowing floor sigil and sharp energy burst.
- **Evolution:** **Runic Chain** — triggering one mine activates nearby mines.

#### 11. Flame Pillar
- **Role:** Area denial / Damage over time
- **Behavior:** Pillars of fire erupt from the ground along enemy paths.
- **VFX:** Orange flames, heat distortion, and glowing cracks.
- **Evolution:** **Infernal Corridor** — a sequence of pillars sweeps across part of the arena.

### C. Orbit & Close-range

#### 12. Astral Blades
- **Role:** Orbit / Contact damage
- **Behavior:** Magical swords rotate around the player.
- **VFX:** Glowing blades and circular trails.
- **Evolution:** **Blade Halo** — orbiting blades occasionally launch toward enemies.

#### 13. Crescent Slash
- **Role:** Directional / Piercing
- **Behavior:** A crescent-shaped slash travels through multiple enemies.
- **VFX:** Bright curved energy arc.
- **Evolution:** **Lunar Cross** — two large slashes cross over each other.

#### 14. Rune Chakram
- **Role:** Outbound-and-return / Ricochet
- **Behavior:** A spinning disc travels outward and returns, hitting enemies in both directions.
- **VFX:** Rotating rune markings and circular trails.
- **Evolution:** **Infinity Loop** — multiple discs cross along intersecting paths.

#### 15. Guardian Sigils
- **Role:** Defense / Contact damage
- **Behavior:** Small shields or sigils orbit the player, damaging enemies and providing limited protection.
- **VFX:** Gold-cyan shield flashes and circular runes.
- **Evolution:** **Sanctuary Ring** — a wider defensive ring.

### D. Summoning & Autonomous Weapons

#### 16. Arcane Familiar
- **Role:** Summon / Auto-target
- **Behavior:** A familiar floats near the player and automatically shoots enemies.
- **VFX:** Small floating magical creature or crystal with cyan shots.
- **Evolution:** **Familiar Legion** — summons several familiars with different attacks.

#### 17. Phantom Knight
- **Role:** Summon / Dash attack
- **Behavior:** A spectral knight charges through a line of enemies, then disappears.
- **VFX:** Ghostly armor, violet afterimage, and impact streak.
- **Evolution:** **Spectral Cavalry** — several knights charge in sequence.

#### 18. Prismatic Drone
- **Role:** Summon / Support fire
- **Behavior:** A floating crystal fires short beams or bolts.
- **VFX:** Refracted light and focused beams.
- **Evolution:** **Prism Array** — several drones focus their beams on one target.

### E. Beam & Continuous Attacks

#### 19. Aether Beam
- **Role:** Beam / Piercing
- **Behavior:** Fires a straight beam through a line of enemies.
- **VFX:** Bright cyan beam and temporary energy afterglow.
- **Evolution:** **Celestial Ray** — a wider beam leaves a lingering energy trace.

#### 20. Riftstorm
- **Role:** Random AoE / Burst
- **Behavior:** Rift energy strikes random locations across the arena.
- **VFX:** Violet lightning and explosive impact flashes.
- **Evolution:** **Cataclysm** — multiple strikes converge into a large explosion.

#### 21. Prism Sweep
- **Role:** Sweeping beam / Area control
- **Behavior:** A rotating beam periodically sweeps an area.
- **VFX:** Rotating laser line and geometric light patterns.
- **Evolution:** **Prismatic Cage** — multiple beams form a geometric area trap.

### F. Debuff & Damage-over-Time

#### 22. Venom Bloom
- **Role:** Poison / Damage over time
- **Behavior:** Creates a poison cloud that deals repeated damage.
- **VFX:** Green toxic mist and glowing spores.
- **Evolution:** **Plague Garden** — enemies that die spread poison to nearby targets.

#### 23. Hex Mark
- **Role:** Curse / Damage amplification
- **Behavior:** Marks an enemy so it takes extra damage from all weapons.
- **VFX:** Dark runes and a violet curse mark.
- **Evolution:** **Doom Sigil** — the curse spreads when the marked enemy dies.

#### 24. Glacial Burst
- **Role:** Freeze / Crowd control
- **Behavior:** Releases an icy blast that slows or freezes enemies in a radius.
- **VFX:** Blue ice crystals and a frost shockwave.
- **Evolution:** **Shatterfield** — frozen enemies can trigger a crystal burst when they take a heavy hit.

### G. Arena Manipulation

These weapons can help distinguish Riftbound from other survivor-like games.

#### 25. Gravity Lens
- **Role:** Projectile manipulation / Setup
- **Behavior:** Bends nearby projectile trajectories toward targets.
- **VFX:** Circular distortion and curved trajectory lines.
- **Evolution:** **Singularity Engine** — projectiles orbit a target before striking.

#### 26. Mirror Gate
- **Role:** Portal / Projectile routing
- **Behavior:** Creates linked portals that transfer projectiles between points.
- **VFX:** Paired cyan-violet portals with rippling edges.
- **Evolution:** **Portal Network** — additional portals create complex firing paths.

#### 27. Crystal Barricade
- **Role:** Barrier / Ricochet
- **Behavior:** Creates a crystal wall that reflects projectiles and damages enemies on contact.
- **VFX:** Faceted cyan-violet crystal wall and refracted light.
- **Evolution:** **Prismatic Fortress** — multiple walls create angled ricochet surfaces.

#### 28. Temporal Field
- **Role:** Time control / Utility
- **Behavior:** Slows enemies and changes projectile speed inside an area.
- **VFX:** Clock-like rune, circular distortion, and time afterimages.
- **Evolution:** **Time Fracture** — projectiles crossing the field leave afterimages and can hit again.

### H. Additional Weapons

| # | Weapon | Main mechanic | Signature VFX |
|---|---|---|---|
| 29 | Comet Lance | Fast piercing projectile | Comet tail and impact trail |
| 30 | Moon Disc | Rotating and bouncing disc | Crescent-shaped circular trail |
| 31 | Soul Leech | Drains enemy energy for limited healing | Violet energy threads toward the player |
| 32 | Blood Sigil | Sacrifices some HP for burst damage | Crimson rune and explosion |
| 33 | Holy Nova | Radial explosion centered on the player | Golden wave of light |
| 34 | Shadow Clones | Shadows repeat the player's attacks with a delay | Dark silhouettes and afterimages |
| 35 | Wind Cutter | Spinning wind blades that launch outward | Teal crescent trails |
| 36 | Echo Mine | Initial explosion triggers follow-up explosions | Layered shockwave rings |
| 37 | Soul Lantern | A spirit orbits, then fires at enemies | Floating lantern and ghost trail |
| 38 | Rift Eruption | Ground cracks release energy or monsters | Violet cracks and vertical eruption |

---

## 4. Passive Skills and Modifiers

Passives should sometimes change weapon behavior rather than only increasing numeric stats.

| Passive / Modifier | Effect |
|---|---|
| **Ricochet Mastery** | Increases the number of projectile bounces. |
| **Split Impact** | Projectiles split into smaller projectiles on impact. |
| **Overcharge** | Projectiles gain bonus damage after multiple bounces. |
| **Piercing Core** | Projectiles pass through additional enemies. |
| **Volatile Impact** | The final hit triggers an explosion. |
| **Elemental Convergence** | Improves interactions between two different elements. |
| **Critical Focus** | Increases critical-hit chance. |
| **Arcane Haste** | Reduces attack cooldowns. |
| **Extended Orbit** | Increases the orbit radius of orbiting weapons. |
| **Homing Rune** | Improves projectile tracking. |
| **Last Echo** | Some projectiles repeat their attack after a delay. |
| **Overgrowth** | Expands roots, poison clouds, and zone-based attacks. |
| **Frostbite** | Slowed enemies take additional damage. |
| **Aftershock** | Explosions trigger a second damage wave. |
| **Mana Battery** | A certain number of hits charges an additional skill. |
| **Guardian Pulse** | Grants a shield after a kill threshold is reached. |
| **Rift Resonance** | Creates a Rift effect when enemies die. |
| **Executioner** | Increases damage against low-health enemies. |

Passives may appear as independent level-up choices or as targeted upgrades for specific weapons.

---

## 5. Example Builds and Synergies

### Build A — Ricochet Chaos
**Flame Orb + Arcane Bolt + Ricochet Mastery + Overcharge**

Projectiles bounce repeatedly, split, and explode. The screen fills with readable trajectory lines, fireballs, and chained impacts.

### Build B — Gravity Collapse
**Void Well + Meteor Fall + Volatile Impact**

Pull enemies into one location, drop meteors, and trigger a large explosion. Designed for clearing dense waves.

### Build C — Frozen Shatter
**Frost Lance + Glacial Burst + Frostbite**

Slow or freeze enemies, then shatter them with burst damage. Blue crystal effects provide a strong visual contrast.

### Build D — Prismatic Geometry
**Aether Beam + Mirror Gate + Crystal Barricade**

Create complex beam paths through the arena. Positioning and reflection angles become important to hitting multiple targets.

### Build E — Verdant Plague
**Thornseed + Venom Bloom + Overgrowth**

Fill the arena with spreading roots and poison. Emphasizes sustained damage and area control rather than immediate burst damage.

---

## 6. Level-Up System

When the player levels up, present a small set of meaningful choices drawn from three categories:

1. **New Weapon** — unlocks a new source of damage.
2. **Weapon Upgrade** — improves or changes an owned weapon.
3. **Passive Modifier** — strengthens the character or changes interactions between attacks.

### Example Level-Up Choices

- **Flame Orb — Split Impact** *(Weapon Upgrade)*  
  The main projectile splits into two smaller fireballs when it hits an enemy.

- **Chain Lightning** *(New Weapon)*  
  Unlocks lightning that jumps between enemies.

- **Overcharge** *(Passive Modifier)*  
  Projectiles gain bonus damage based on how many times they have bounced.

The level-up system should consider:
- Weapons already owned.
- Character and elemental affinity.
- Available weapon slots.
- Rarity and upgrade weights.
- Build synergy.
- Avoiding repetitive or irrelevant offers.

Signature weapons should retain their character identity and may have exclusive upgrade paths. General weapons give players freedom to create different builds during each run.

---

## 7. Recommended Development Priorities

Do not implement all weapons at once. First validate that ricochet combat is fun and that each weapon changes how the player approaches a run.

| Phase | Target | Suggested content |
|---|---:|---|
| **Prototype** | 8 weapons | Flame Orb, Arcane Bolt, Chain Lightning, Meteor Fall, Astral Blades, Void Well, Frost Lance, Thornseed |
| **Alpha** | 16–20 weapons | Add summons, beams, poison, orbit weapons, and crowd control |
| **Content expansion** | 30–40 weapons | Add arena manipulation, more elements, and advanced combinations |

### Technical Recommendation

Separate the following systems:
- Weapon logic.
- Projectile movement and collision behavior.
- Damage calculation.
- Status effects.
- VFX and hit feedback.
- Upgrade definitions and evolution rules.

For example, Arcane Bolt and Flame Orb could share a ricochet behavior component while using different damage values, impact effects, elemental statuses, and upgrade paths. This makes adding weapons easier without rebuilding the combat system.

---

## 8. Key Design Principles

- Make ricochet combat the core identity of Riftbound.
- Give every weapon a recognizable movement pattern and impact effect.
- Use VFX to communicate mechanics, not merely decorate the screen.
- Keep projectile paths and enemy silhouettes readable in the portrait arena.
- Ensure the player can move horizontally along a broad bottom platform.
- Keep the Rift at the upper end of the arena as the source of monster waves.
- Design weapon synergies that reward experimentation.
- Preserve distinct signature weapons for each character.
- Use modular weapon and VFX systems to support future content.
- Balance spectacle with performance, especially when many projectiles are active.

**Project vision:** Build a roguelite where ricochet combat creates satisfying chain reactions, elemental combinations produce distinctive visual spectacle, and every level-up meaningfully changes the player's build.

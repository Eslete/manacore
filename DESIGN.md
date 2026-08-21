# Incremental Game – Cyan/Violet Design Update

**Status:** Latest design authority after the previous project plan.

**Rule:** If this document conflicts with older plans, prompts, AGENTS notes, or prototypes, this document takes precedence unless the user explicitly revises it later.

Preserved where this update is silent: portrait screens stay separate (CORE / ANOMALY / RELICS / SPACE / ARCHIVE). Korean UI. No ads, servers, offline rewards, prestige/reset, or `stage_3d` unless a later revision asks. Archive stays informational. Generator upgrades do not raise weapon damage; weapon upgrades do not raise mana/s.

---

# 0. Purpose of this update

The core loop is already fun enough to continue. The project is now moving from broad concept work into content/system detailing and implementation.

The immediate goal is not to add many systems. The goal is to make the Cyan prologue and the beginning of Violet sufficiently complete that the next major step is real playtesting and tuning.

The design should remain:

- a portrait mobile incremental/idle game;
- visually polished despite a simple implementation;
- centered on a Mana Core, mana production, relics/weapons, and linear anomaly progression;
- friendly both to active clicker players and mostly-idle players;
- simple at first, with mechanics unfolding gradually.

# 1. High-level progression structure

## 1.1 Core progression and Anomaly progression are separate

Do not require the player to clear the Cyan boss in order to reach Violet.

There are two progression axes:

**CORE PROGRESSION**

Pure incremental growth.

- generate Mana;
- upgrade the Core;
- increase Output and Capacity;
- specialize toward Tap or Passive/Auto production;
- accumulate enough power/resources to synthesize the next Core color.

**ANOMALY PROGRESSION**

Combat/story progression.

- fight anomalies in a fixed linear order;
- defeat bosses;
- unlock locations, Archive entries, relics, knowledge, and combat technologies;
- no repeated-kill mastery loop is required.

These systems must interact, but neither should fully gate the other.

A player should be allowed to:

- heavily develop the Core before pushing combat;
- push anomalies while remaining on a lower Core color longer than expected;
- return overpowered and destroy earlier anomalies quickly.

Use soft gates through difficulty, not frequent explicit Requires Tier X locks.

# 2. Color tiers are not equal-length chapters

## 2.1 Cyan is intentionally short

Cyan is now treated as the tutorial/prologue Core tier.

It should teach:

- tapping the Core for Mana;
- passive generation;
- Output and Capacity;
- the existence of Tap-specialized and Auto-specialized Core upgrades;
- Shooter operation and Mana consumption;
- basic relic equipment;
- anomaly combat;
- Core color ascension.

Cyan does not need to contain the full long-term depth of the game.

**Provisional duration target**

These are tuning targets, not hard requirements:

- active/Tap-focused play: roughly 45–120 minutes;
- mixed active + idle play: roughly 2–4 hours;
- mostly idle play may take longer.

Do not artificially stretch Cyan with huge HP or cost multipliers.

## 2.2 Violet is the first real chapter

Violet should be materially longer than Cyan and is where the game begins to feel like a real build-focused incremental game.

Violet is where the player first encounters:

- enemies whose mechanics cannot be solved by raw DPS alone;
- the need for continuous damage;
- Beam / Continuous Discharge technology;
- more meaningful Relic combinations;
- stronger differences between Tap-focused and Auto-focused Core investment.

**Provisional duration target**

Aim for Violet to be several times longer than Cyan. A first tuning target could be:

- several hours for highly active play;
- roughly a day or more for mixed/idle play.

Do not achieve this merely by inflating numbers. Violet must be longer because its systems have more depth and more goals.

## 2.3 Later tiers become progressively longer

The expected pacing concept is:

- Cyan: tutorial/prologue;
- Violet: first full chapter;
- Amber: multi-day progression begins;
- later tiers: increasingly long-term progression;
- a much later major reset/transformative event may eventually fill the role of a Singularity-like milestone, but do not implement that now.

# 3. Core upgrade structure

## 3.1 Do not use a Manual/Auto mode toggle

Previous ideas about switching between a MANUAL mode and AUTO mode are superseded.

Instead, the Core upgrade tree itself branches into two investment directions.

The player may buy upgrades on both sides. Nothing is permanently locked by choosing one branch.

Build identity should emerge from:

- where the player spends Mana;
- which branch is more developed;
- which Passive Relics are equipped.

Basic structure

```
                     CORE
                      │
            OUTPUT / CAPACITY
                      │
          ┌───────────┴───────────┐
          │                       │
      TAP BRANCH              AUTO BRANCH
      active gain             passive gain
```

## 3.2 Shared Core upgrades

**Output**

The common source of production power.

Increasing Output should improve both:

- passive Mana/s;
- baseline Mana gained per valid Tap.

**Capacity**

Maximum stored Mana.

Capacity should matter because:

- weapons consume stored Mana;
- large upgrades/ascensions require large amounts;
- active burst play benefits from larger reserves.

## 3.3 Tap should scale automatically with Core strength

Do not create a generic infinite Tap Power Lv. 1–100 stat detached from the generator.

Baseline Tap gain should be derived from Core output, e.g. conceptually:

`Tap Gain = Base Output × Tap Time Equivalent × Tap Multipliers`

The exact coefficient is a balance variable.

This makes scientific/fictional sense: tapping is manually exciting the same generator, so a stronger generator yields more Mana per manual excitation.

## 3.4 Tap rate must be capped sensibly

The game should not reward extreme physical spam or autoclickers.

Use an effective Tap cooldown / input rate cap such that approximately 3–6 meaningful taps per second is enough for maximum useful input.

Extra taps above the cap should not create proportionally more Mana.

Do not turn the game into a dexterity/rhythm game unless explicitly redesigned later.

# 4. Tap branch vs Auto branch balance

## 4.1 Core principle

A player who is actively tapping should always be able to outperform simply leaving the game untouched if they have invested at least somewhat into Tap.

The intended ordering is:

```
Plain passive generation
        <
Optimized Auto / Flywheel state
        <
Light Tap investment + active tapping
        <
Deep Tap investment + Tap relics + active play
```

However, the margin depends on investment.

**If Tap investment is low**

Active tapping should only be somewhat better than optimized Auto.

The player should feel:

“I can squeeze more out by playing actively, but this is not worth constant tapping unless I build for it.”

**If Tap investment is high**

Active tapping should be substantially better than Auto.

This creates a genuine clicker build.

A first balance target can be:

- lightly invested active tapping: roughly 10–30% above optimized Auto;
- strongly invested Tap build: roughly 1.5–2.5× optimized Auto while actively playing.

These are playtest targets, not fixed formulas.

## 4.2 Auto/Flywheel is compensation for inactivity, not the best possible state

The Auto branch should contain a Flywheel-like mechanic that rewards sustained non-interaction.

Example concept:

- after a period without valid tapping, passive generation gradually stabilizes;
- it ramps toward an Auto bonus;
- remaining untouched maintains the bonus.

But Flywheel must not make active tapping pointless.

Even a primarily Auto-focused player who invested a little in Tap should usually gain somewhat more Mana while actively tapping than while sitting at max Flywheel.

## 4.3 Do not punish accidental taps harshly

A single tap should not instantly erase the entire Flywheel bonus.

Instead:

- tapping can interrupt further stabilization;
- existing Flywheel bonus can decay over a short window;
- sustained active tapping transitions the player from Auto efficiency into active output.

This keeps the system readable and avoids “I touched the screen and ruined my build” frustration.

# 5. Core upgrade node philosophy

Exact node names and numbers can remain data-driven, but Cyan should expose only a small number of meaningful upgrades.

## 5.1 Shared

- Output upgrades;
- Capacity upgrades;
- Core tier synthesis requirement/progress.

## 5.2 Tap branch examples

Possible Cyan nodes:

- Manual Coupling: Tap multiplier increase;
- Piezo Stack: additional Tap multiplier;
- Excitation Circuit: active tapping can temporarily boost generation;
- Resonant Contact: stronger Tap scaling;
- Feedback Excitation: improves the active boost.

Do not overload Cyan with complicated conditional effects.

## 5.3 Auto branch examples

Possible Cyan nodes:

- Stable Dynamo: passive output multiplier;
- Closed Loop: additional passive multiplier;
- Flywheel: inactivity-based stabilization bonus;
- Self-Regulation: stronger passive scaling;
- Inertial Stabilizer: faster/stronger Flywheel stabilization.

Again, keep effects readable.

# 6. Relics should reinforce builds rather than define modes

Passive Relics are the second layer of build identity after Core upgrades.

Examples:

**Tap-support relics**

- Tap Mana ×2;
- active excitation duration increase;
- stronger temporary output after tapping;
- occasional stronger Tap, if kept simple and readable.

**Auto-support relics**

- Passive Mana/s ×1.5;
- Flywheel reaches maximum faster;
- higher Flywheel ceiling;
- greater idle efficiency.

**Combat/economy relics**

- Shooter damage multiplier;
- Shooter Mana cost reduction;
- Capacity multiplier.

Important:

A player who invests in Tap Core upgrades and equips Tap relics should become a real clicker build.
A player who invests in Auto upgrades and Auto relics should become a real idle build.
Hybrid builds must remain possible.

Do not permanently lock players into one build.

# 7. Cyan weapon design

## 7.1 Cyan has only one active weapon: Shooter

Do not add Beam, Prism, Capacitor, etc. as Cyan starting weapons.

Shooter represents:

- discrete projectile damage;
- a **flat** Mana cost per shot that rises with Shooter ranks, not with Capacity/Output;
- player-armed combat on the ANOMALY screen;
- the basic conversion of Mana into damage.

It does **not** fire just because combat is live or because the player is on CORE.

Cyan default: enter ANOMALY → press **사격** → one discrete shot (Mana + cooldown). Leaving ANOMALY never spends.

**연사** is an early Shooter upgrade on RELICS (one rank). After buying it, ANOMALY uses **사격 시작 / 사격 중지**: while on, shots repeat at the Shooter interval. 연사 does **not** mean firing on CORE or other tabs. Leaving ANOMALY still stops spend.

Do not implement off-tab fire.

## 7.2 Keep Shooter simple in Cyan

Primary growth should initially focus on:

- Damage / Power;
- Mana per shot as a **flat number** that rises with Shooter ranks (not a fraction of Capacity or Output). Generator upgrades must not change shot cost.

Do not add Crit, elements, penetration, attack patterns, ammo types, etc. unless testing proves Cyan needs more depth.

## 7.3 Shooter must have meaningful gaps between hits

The important mechanical identity of Shooter is that damage arrives in separate pulses.

Its firing interval should remain long enough that later enemies can react to damage gaps.

This property is what makes Beam meaningful later.

# 8. Cyan Anomaly design

Cyan is still a prologue, not a full-length chapter. The **low-orbit front** must still be long enough that Shooter ranks 1–8 are worth buying before the Cyan boss.

This slice’s Cyan playable front (earth orbit). Each fight has a unique silhouette (not shared crystals/shells):

- shard — dummy, Shooter 0; broken-quad crystal;
- splinter — ordinary, Shooter 0–1; thin rhombus flake, not a triangle;
- regenerator / ablative polyhedron — first shell; faceted hex + incomplete crescent;
- needle — ordinary, 연사 starts to matter; one tall spear-diamond;
- plate — thicker shell; wide flat hex shield;
- cluster — mixed pieces in a web, no split gimmick;
- orbit ring — ordinary, Shooter 5–6; hollow torus, empty center;
- lattice — Cyan three-stage boss, Shooter 6–8; wireframe cage → grid → core.

Target time-to-kill at the intended Shooter rank: about 15–40s for regulars, 45–90s for the boss. Do not fake that length with regeneration.

They should not introduce every combat gimmick. Only:

- higher Stability;
- simple damage reduction / armor shell;
- visual phase changes;
- shell breaking;
- multi-layer boss presentation.

Avoid in Cyan:

- regeneration as a central mechanic;
- damage-gap healing;
- mechanics designed specifically for Beam;
- complex shield timing;
- multi-weapon puzzles.

## 8.1 Cyan boss

The Cyan boss should feel visually large and layered but remain mechanically simple.

A three-stage structure is appropriate:

- outer shell;
- internal lattice;
- exposed core.

The boss rewards combat progression, relics, Archive data, and access to the next location/sector.

It does not drop or gate the Violet Core.

After the Cyan boss is down, the anomaly front **holds** (전선 안정). The next fight is not another Cyan enemy. Grow the Core and synthesize Violet; then the atmosphere front opens.

# 9. Violet Core synthesis

Violet Core is a Core/incremental milestone, not a boss trophy.

Its requirements should come from Core growth, e.g.:

- sufficient Output;
- sufficient Capacity;
- a large amount of stored Mana consumed in synthesis.

Exact values remain tunable.

Ascending to Violet:

- does not reset Output;
- does not reset Capacity;
- does not remove Core branch upgrades;
- does not remove Shooter;
- does not remove relics;
- does not reset Anomaly progress;
- mainly consumes the Mana required for synthesis and unlocks access to Violet-tier possibilities.

This is not Prestige.

# 10. Beam must not unlock immediately when Violet is reached

Reaching Violet should not display an automatic BEAM UNLOCKED reward.

Violet represents the Core becoming capable of more advanced energy behavior, but the player must first encounter a reason to invent/use continuous damage.

# 11. The enemy that teaches continuous damage

The Reconstructor is the **first Violet anomaly**, not a fourth Cyan fight.

Cyan playable front (this slice) is the eight low-orbit fights in §8, ending at lattice. Then the front waits. Early in Violet / atmosphere progression, introduce the Reconstructor.

Its core behavior:

If it receives no damage for a short interval, it performs a large burst heal.

Conceptual example:

No damage for longer than the Shooter interval → immediately restore a significant percentage of Stability

Exact timing and heal percentage are balance variables. The gap must stay **longer than** the Shooter interval (~0.95s) so **연사** (repeat fire on ANOMALY) can hold the line. Single discrete shots still lose to the heal. That is a soft gate, not a brick wall.

Because Shooter deals discrete damage with gaps, the player sees something like:

Shooter hits → brief gap → enemy repairs itself massively → Shooter hits again → brief gap → enemy repairs again

The intended realization is:

“My raw damage is not necessarily too low. The problem is that the damage is interrupted.”

This is the first strong combat puzzle in the game.

## 11.1 Do not hard-lock alternative solutions

If a player has absurdly high Shooter damage and can one-shot the enemy, allow it.

If they bought **연사** and keep 사격 시작 on, the stream should prevent the burst heal and let them finish the fight. Beam is the dedicated continuous tool after Violet + observing this enemy — not the only legal answer.

The game should generally prefer soft mechanical problems over explicit hard gates.

# 12. Beam unlock flow

After the player observes the Reconstructor behavior, unlock access to a research/crafting/development step such as:

Continuous Discharge

Requirements may include:

- Violet Core;
- a Mana cost;
- first observation/encounter with the Reconstructor;
- optionally a combat-derived component or research record.

Completing the development unlocks the Beam relic/weapon.

Beam identity:

- continuous Mana drain;
- continuous damage;
- suppresses Reconstructor burst healing because damage no longer stops;
- different economic behavior from Shooter.

This establishes a long-term pattern:

New tier → new kind of problem appears → player understands why old tool is insufficient → new technology becomes meaningful

Do not simply award one weapon automatically per Core color without context.

# 13. Why Violet should be longer than Cyan

Violet is allowed to be much longer because it adds decision depth, not merely waiting time.

During Violet, the player now has interactions among:

- Shooter vs Beam;
- per-shot cost vs continuous drain;
- Tap vs Auto Core investment;
- Passive Relic combinations;
- enemies with different damage requirements;
- larger Mana reserves and longer-term upgrades.

Therefore Violet can support longer progression without feeling like a stretched tutorial.

Do not extend playtime by only multiplying enemy Stability and upgrade prices.

# 14. Visual quality target

The game should remain feasible for a small/AI-assisted development workflow, but the presentation target should be at least comparable in polish to Cell to Singularity in the sense of:

- simple geometry/assets used well;
- coherent 3D/2.5D presentation;
- strong lighting/glow;
- subtle particle systems;
- satisfying tap feedback;
- clean projectile trails;
- readable hit/destruction feedback;
- smooth UI transitions;
- consistent typography and spacing;
- mobile-game-level polish rather than debug UI.

Do not interpret this target as requiring highly detailed character animation or many bespoke organic models.

Prefer:

simple assets + strong presentation

over

complex assets + unfinished presentation.

Cyan anomalies can be made largely from primitives, procedural motion, emissive materials, particles, and staged break-apart effects.

# 15. Implementation boundaries

## Implement now

**Core**

- Mana resource;
- Capacity;
- Output;
- Tap generation tied to Output;
- meaningful input rate cap;
- Tap upgrade branch;
- Auto upgrade branch;
- Flywheel-like inactivity stabilization;
- gradual Flywheel decay/transition when active tapping begins;
- data-driven upgrade values.

**Combat**

- Shooter;
- Mana consumption;
- Stability damage;
- Cyan anomaly sequence;
- simple shell/phase logic;
- Cyan boss;
- combat continuing while the player views other screens if that behavior already exists in the architecture.

**Relics**

- small Cyan passive relic pool;
- Tap multiplier relic(s);
- Auto multiplier relic(s);
- Shooter economy/damage relic(s);
- equipment slots.

**Progression**

- independent Core tier progression;
- independent Anomaly progression;
- Cyan → Violet Core synthesis;
- Violet does not require Cyan boss clear;
- Cyan boss does not award Violet Core.

**Violet preview / first mechanic**

- Reconstructor-style damage-gap healing enemy;
- observation-triggered Continuous Discharge development;
- Beam unlock only after that problem is introduced.

**Presentation**

- CORE is one shaded monochrome sphere (fixed radius `0.22`) plus an **additive** shader corona — not stacked `draw_circle` discs. Generation motes only fall inward. Light/density, not size. Do not copy Kurtzgesagt props; match that polish of simple emissive shape.
- polished Cyan Core tap feedback;
- polished Shooter projectile/hit feedback;
- Cyan anomaly silhouettes are unique per fight (shard / splinter / polyhedron / needle / plate / cluster / ring / lattice cage);
- Cyan anomaly break/destruction effects;
- clear Core tree UI;
- clear Relic UI;
- portrait-friendly navigation.

## Do not implement yet

- large numbers of Violet enemies;
- a full Violet content set before Cyan is tested;
- Amber or later tier content;
- prestige/reset systems;
- complex crafting;
- multiple currencies without a strong need;
- repeated-kill Bestiary mastery;
- mandatory combat gates for Core color progression;
- monetization systems;
- elaborate humanoid/creature animation pipelines.

# 16. Data-driven tuning requirements

Do not bury balance constants in UI scripts.

At minimum, make the following easy to tune from data/resources/config:

- Output upgrade cost curve;
- Output scaling;
- Capacity cost/scale;
- baseline Tap time-equivalent coefficient;
- Tap input cooldown;
- every Tap branch multiplier;
- every Auto branch multiplier;
- Flywheel delay, ramp time, maximum multiplier, decay behavior;
- Relic multipliers;
- Shooter damage, cost, rate, upgrade curve;
- anomaly Stability and defenses;
- Cyan boss phase values;
- Violet synthesis requirements;
- Reconstructor no-damage window and burst-heal amount;
- Beam damage/Mana-drain parameters.

# 17. Telemetry needed for real playtesting

Before calling the design finished, add lightweight debug telemetry so testing is not purely subjective.

Track at least:

- total session time;
- time to passive generation unlock/first meaningful Core upgrade;
- time to Tap/Auto branch access;
- time of key branch purchases;
- total Mana generated by taps;
- total Mana generated passively;
- active tapping time;
- time spent at high Flywheel efficiency;
- Mana spent on Core upgrades;
- Mana spent on Shooter upgrades;
- Cyan anomaly clear timestamps;
- Cyan boss clear time;
- Violet synthesis time;
- equipped Relics at milestones;
- average Shooter uptime due to Mana availability;
- first Reconstructor encounter duration;
- number/amount of Reconstructor burst heals observed before Beam development;
- Beam development/unlock time.

The exact format can be a debug panel and/or a simple JSON/CSV-style log.

# 18. Playtest success criteria

After the implementation above is complete, stop adding systems and playtest.

The remaining questions should be tuning/feel questions. If any answer is “no”, first adjust multipliers, cost curves, unlock timing, enemy values, feedback/VFX, and UI clarity.

Do not respond to a pacing problem by immediately adding a new system.

# 19. Implementation order for Cursor agents

The Cyan → early Violet slice in this document is already in the repo. Remaining work is playtest and numerical/feel tuning, not a new specialist pipeline.

Current team (see `AGENTS.md`): architect (gated), gameplay, presentation, verifier. Do not assign core-systems / anomaly-combat / mobile-ui / visual-vfx / content-data — those roles were merged.

If a later feature is required:

1. Parent classifies: trivial / gameplay / presentation / gameplay then presentation / architect.
2. gameplay owns `game.gd` + `data.gd` + `fmt.gd`.
3. presentation owns `main.gd` + views. Do not duplicate formulas in UI.
4. verifier once at the end of a user-visible slice.
5. Engineering splits and perf live in `OPTIMIZE.md`; do not start them unless asked.

# 20. Short version – latest non-negotiable decisions

- Cyan is a tutorial/prologue, not a full-length late-game tier, but the low-orbit front is eight fights so Shooter can be ranked to max before the Cyan boss.
- Violet is the first substantial chapter and should be much longer.
- Core color progression and Anomaly combat progression are separate axes.
- Cyan boss does not drop or gate Violet Core.
- Core upgrades branch into Tap and Auto/Passive investment paths; there is no Manual/Auto mode toggle.
- Both branches remain purchasable; builds emerge from investment and Relic choices.
- Tap gain automatically scales with generator Output.
- A lightly invested active Tap setup should beat optimized Auto/Flywheel slightly.
- A deeply invested Tap build should beat optimized Auto substantially while actively played.
- Flywheel is an inactivity optimization, not the strongest possible production state.
- A single accidental tap should not instantly destroy Flywheel efficiency.
- Cyan has only Shooter as its active weapon.
- Shooter default is single shot on ANOMALY. 연사 is an early Shooter upgrade that enables 사격 시작/중지 repeat fire on that screen only. Leaving ANOMALY always stops spend.
- Shooter Mana per shot is a flat number that rises with Shooter ranks. Capacity and Output do not change it.
- Beam does not unlock merely because Violet was reached.
- Violet introduces an enemy that burst-heals after a damage gap.
- That enemy creates the need for continuous damage, after which Beam/Continuous Discharge becomes available.
- Do not solve pacing problems by adding systems before testing the existing ones.
- Once the above is implemented with basic polish and telemetry, the next step is real playtesting and numerical tuning.

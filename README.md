# Colossus Arena

Colossus Arena is a complete six-player Roblox boss-rush game. Each player receives a colored floating base connected to a shared 120-stud arena, fights alternating two-minute colossi, earns coins from contribution, and upgrades swords and armor.

The server assigns bases, validates melee and shop requests, controls bosses and damage, calculates rewards, and owns profile persistence. The responsive client HUD renders warnings, boss state, results, inventory, feedback, sound, particles, and camera impact.

## Controls

- Move and jump with standard Roblox controls.
- Click or tap with the equipped sword to attack.
- Press `B` to open or close the inventory. On touch devices, use **PACK**.
- Press `T` to travel between your base and the arena. On touch devices, use the destination button.
- Use an **UPGRADES** kiosk to buy swords. The server requires the player to be alive and physically near a kiosk.

A boss owns one 120-second cycle. Killing it early turns the remaining cycle time into downtime; no extra intermission is added. Teleporting locks during the final five seconds before the next boss arrives.

## Bosses and counters

### Emberhorn

Emberhorn is a pursuing bull-golem that deals contact damage and enrages below 30% health.

- **Slam:** leave the 45-stud warning circle.
- **Rings:** jump over three expanding fire rings.
- **Charge:** sidestep the telegraphed line. A missed charge leaves Emberhorn stunned.
- **Meteor Rain:** below 50% health, leave the eight marked impact circles.

### Glacius

Glacius is a floating crystal sorcerer that enrages below 25% health.

- **Nova:** stand inside a blue safe circle. Enrage reduces the safe circles from three to two; a failed dodge also slows movement briefly.
- **Orbs:** avoid three visible homing projectiles. Pillars and solid obstacles destroy them, and returning to a safe base ends pursuit.
- **Sweep:** hide behind one of four ice pillars while the beam rotates through a full circle.
- **Crystal Shield:** at 50% health, destroy four cardinal crystals with 800 HP each. A large hit cannot skip the phase. Breaking the last crystal stuns Glacius for four seconds.

## Progression and loot

The six weapons are Wooden Trainer, Bronze Shortblade, Knight's Longsword, Sunfang Greatsword, Emberhorn's Cleaver, and Glacial Edge. The first four form the kiosk progression; the last two are rare drops. Molten Plate grants 30 max health and Frostweave Cloak grants 15% movement speed. Both armor effects can be enabled together.

Contribution share is `player damage / boss maximum HP`, capped at 100% per player. Shield-crystal damage counts toward rewards, while boss-only damage is tracked separately. Rewards use:

```text
coins = floor(coin pool × contribution share × rank multiplier × outcome multiplier)
```

First, second, and third use `1.5×`, `1.25×`, and `1.1×`; others use `1×`. A timeout uses a `0.5×` outcome multiplier. Players with at least 10% share remain eligible for a 2–8% rare-drop roll on either a kill or timeout. Duplicate rare items convert to 500 coins.

Profiles store coins, owned items, equipped sword, and enabled armor. Session locks, sanitation, retries, 60-second autosaves, and shutdown saves prevent an offline/default session from overwriting a live profile.

## Build

Use Rojo 7.7 or compatible:

```sh
rojo build default.project.json -o ColossusArena.rbxlx
```

Open the generated place in Roblox Studio and press Play. The unrelated BLACKOUT place is separate and was preserved.

The arena uses procedural anchored geometry and an audited low-poly tree under `assets/`; the imported tree contains no scripts. Bosses, crystals, projectiles, pillars, floor art, telegraphs, particles, and impact visuals are built from local source. Audio IDs and effect tuning are centralized in `Config.luau`.

## Tuning

- `src/ReplicatedStorage/Modules/Config.luau`: map, player, cycle, combat, shop, audio, and polish.
- `BossDefs.luau`: HP, coin pools, colors, and drops.
- `EmberhornDefs.luau` and `GlaciusDefs.luau`: ability timing, damage, sizes, cadence, and phases.
- `SwordDefs.luau` and `ArmorDefs.luau`: equipment stats and costs.
- `EconomyDefs.luau`: rank rewards, timeout multiplier, rare drops, duplicates, DataStore locks, retries, autosave, and shutdown.

## Verification

All 24 source files compile. Automated checks cover the six exact sword definitions, loot boundaries, and simulated persistence lifecycle. Studio fixtures cover base spawn, real Tool combat and invalid requests, every boss mechanic, shield accounting, payouts, shop validation, armor, teleport timing, desktop mouse and `B` controls, and portrait phone layout. The natural deadline transition verified the final-five-second HUD lock and its unlock when Glacius spawned. See `docs/VERIFICATION.md` for details.

Live published-server DataStore save/rejoin and a real multiplayer session were not tested. The persistence suite uses simulated services, and unpublished Studio correctly remains session-only.

Run the four Lune checks listed in [the delivery notes](docs/HANDOFF.md). Tool versions are pinned in `rokit.toml`.

The coin pools are 1,000 for Emberhorn and 1,400 for Glacius. Zero damage earns zero coins. The exact rare chance is `min(0.08, 0.02 + (share - 0.10) * 0.08)` for eligible contributors, with one roll per boss. Emberhorn drops its Cleaver or Molten Plate; Glacius drops Glacial Edge or Frostweave Cloak.

Next validation: published DataStore save/rejoin and a six-player session, followed by balance and performance tuning from real play. No additional boss or monetization systems are included.

# Colossus Arena

A six-player Roblox boss-rush game under construction. **This is an incomplete development build, not the final playable deliverable.**

## Verified and pushed

1. Public repository and source scaffold.
2. Colorful circular arena, six radial bridges and six bases, kiosks, banners, floating scenery and warm lighting.
3. Session base ownership, release, server-side six-player admission cap and owned respawn.
4. Alternating 120-second Emberhorn/Glacius cycle, scaled HP, timeout cleanup and downtime. A complete real-time cycle was observed in Studio.
5. Six sword definitions and server-authoritative melee. Actual Tool activation, request spam, forged payload rejection, shield rejection, overkill clamping and the complete boss-damage ledger passed runtime checks.

## In progress

Emberhorn/Glacius abilities, telegraph rendering, persistence and loot source have been pushed as work in progress. They compile, but their full runtime verification and integration are unfinished. Shop/inventory, full HUD, polish and final verification remain.

The build agents hit the account usage limit after the user-requested interim push. See [handoff](docs/HANDOFF.md), [implementation checklist](docs/IMPLEMENTATION.md) and [verification evidence](docs/VERIFICATION.md).

## Build

Use Rojo 7.7 or compatible:

```sh
rojo build -o ColossusArena.rbxlx
```

Open that place in Roblox Studio and press Play. The map builds at runtime. Source mirrors Roblox services under `src/`. Main starts the current development components. The existing BLACKOUT place is separate and was preserved.

## Development controls

Standard Roblox movement, jump and equipped Tool activation (mouse/touch). The Wooden Trainer equips automatically. The temporary top timer is present; the final shop, inventory and teleport UI is not yet implemented.

## Tuning

- `src/ReplicatedStorage/Modules/Config.luau`: map, players, cycle and combat settings.
- `BossDefs.luau`, `EmberhornDefs.luau`, `GlaciusDefs.luau`: boss stats and abilities.
- `SwordDefs.luau`: exact requested six sword damage/cooldown/cost values.
- `EconomyDefs.luau`, `ArmorDefs.luau`: economy and armor values under development.

## Tests

Run with Lune:

```sh
lune run tests/syntax.luau
lune run tests/swords.luau
lune run tests/loot.luau
```

Syntax and sword tests passed at the interim checkpoint; the loot test and Studio boss fixtures still require final execution/review. Studio fixture files under `tests/` are not included in the game source tree. Unpublished Studio persistence cannot prove real DataStore save/rejoin behavior.

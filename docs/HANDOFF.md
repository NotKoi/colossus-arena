# Delivery state

All twelve build checkpoints are implemented. See README.md for controls, movesets, rewards and tuning, and VERIFICATION.md for the recorded runtime evidence.

The source builds with Rojo 7.7.0. Open ColossusArena.rbxlx in Studio and press Play; the map builds automatically. The existing unrelated BLACKOUT place was preserved.

Production source has no ManualBossTests switches. The historical Studio fixtures under tests/ require an isolated test harness and are not shipped into the place. Lune tests can be run directly from the repository:

```sh
lune run tests/syntax.luau
lune run tests/swords.luau
lune run tests/loot.luau
lune run tests/persistence.luau
```

Live published-server DataStore save/rejoin and a real multiplayer session remain unverified. Unpublished Studio uses session-only profiles. Next validation should exercise these in a published test experience; no published game or live persistence verification is claimed.

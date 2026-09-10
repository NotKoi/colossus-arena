# Studio verification

- Checkpoint 2: Studio Play console: `Colossus Arena: map ready 6`; no warnings/errors. Server asserts six base models, six spawns and six kiosk prompts. Edit camera screenshot confirms complete colorful radial map.
- Asset search: inspected free Minotaur 12485225836; rejected humanoid brown anatomy and incomplete-looking head for armored bull-golem art direction. Ice-wizard and fantasy-sword search results were unrelated creatures/buildings. Free tree 12549617200 audited: zero scripts, two meshes. Procedural fallback avoids runtime asset-loading dependency; imported candidates remain isolated in ServerStorage during review.
- Checkpoint 3: Play server asserts assigned index, matching RespawnLocation and avatar within 12 studs of owned spawn. Console clean.

- Checkpoint 4: observed the real 120-second timeout, Emberhorn cleanup and cycle 2 Glacius with 6500 HP. Initial Emberhorn HP 8000 and countdown 0..120 validated. Console clean; all 9 sources compiled with Lune.

- Checkpoint 5: actual equipped Tool.Activate dealt10;20 simultaneous remotes produced only one hit. Forged target/damage request from base changed no HP. Runtime probe passed shield immunity, unknown target rejection, remaining-HP cap, boss damage ledger=8000, death/downtime and post-death rejection. All six sword stats checked against spec with Lune. Console clean.

- User-requested interim push: combat checkpoints1-5 verified; Emberhorn, Glacius, telegraph rendering and economy source are in progress and are not yet fully runtime verified.

- Checkpoint 6: manual server fixtures passed Emberhorn slam radius/timing, three ring waves (75 grounded/0 jumping), charge line sidestep/stun, meteor timing and safe-zone exclusion. Runtime enrage trigger passed. Client capture shows ground warning before slam and bull-golem model. Console clean.

- Checkpoint 7: Glacius mandatory50% shield cap, immunity, four800HP crystals, contribution ledger and4s stun passed. Nova safe/outside/base geometry,1.8s preview, slow expiry and two-circle enrage passed. Sweep hit exposed target and protected pillar shadow. Orb tests passed obstacle shatter, three35-damage hits and safe-zone retreat. First orb assertion was corrected to observe damage because Roblox auto-regeneration changes final HP. Clean rerun console. Shared ring/beam timestamps now identical in server and client packet.

- Checkpoint 8: runtime economy tests passed starter profile, duplicate500 conversion,750 kill payout for50% first place,375 timeout payout, zero participation and payout idempotence. Pure loot boundary tests pass. Actual DataService source passes simulated-service rejoin/lock/retry/autosave/shutdown/snapshot/sanitation/Sync tests. Unpublished Studio deliberately uses session-only data; live Roblox DataStore rejoin is not verified. Console clean.

- Checkpoint 9: Studio fixture completed shop proximity restriction, exact250-coin Bronze purchase, purchase/equip ownership/rate limits, boss-drop shop rejection, insufficient funds,30HP armor,15% speed, derived81 strength, no toggle-healing, base/arena teleport and final5-second downtime lock. Console reports Shop and inventory runtime tests passed.

## Checkpoint 10 — final HUD
Desktop mouse inventory open/close and B shortcut passed. iPhone 14 portrait HUD and results screenshots inspected: readable timer/coins/strength, buttons clear of Jump. Scale-only sizing checked. Final normal startup console has no warnings/errors; early-kill fixture confirmed inactive boss retains original deadline and shopping downtime. Production ManualBossTests branches removed. Live multi-client and published DataStore verification remain unavailable.

## Checkpoint 11 — polish and final cycle
Final map overview and phone inventory screenshots inspected. Normal early-kill downtime reached the five-second UI lock, then Glacius spawned and teleport unlocked. Reoriented equipped blade dealt exactly 10 damage. Impact particle emitter creation verified. A diagnostic event initially omitted the required start timestamp; that fixture error was isolated and the final session restarted. Static imported tree is script-free; Rojo build succeeds with the asset included.

# Implementation plan

Goal: playable six-player Colossus Arena, server-authoritative combat/economy, client telegraphs and responsive HUD.
Architecture: shared Config/Defs/RemoteNames; server MapBuilder, BaseAssignment, BossController, CombatService, DataService, LootService; client CombatClient, TelegraphRenderer and UIController. Rojo mirrors source into a separate place. Each numbered checkpoint ends in a build, Studio play/console verification, commit and push.

- [x] 1. Public repo scaffold.
- [x] 2. MapBuilder.Build: 120-radius patterned arena, six bridges/bases and warm fantasy lighting; inspect screenshot.
- [x] 3. BaseAssignment: six unique session slots, release on leave, respawn and HUD identity; inspect spawn.
- [x] 4. BossController: alternating 120-second cycles, spawn-time HP scaling, downtime/death/timeout cleanup; inspect timed state.
- [x] 5. CombatService: server Tool blade touches, cooldown/range/debounce, contribution records, client input and damage feedback; test invalid attacks and capped damage.
- [x] 6. Emberhorn: slam, rings, charge/stun and meteors, health-gated enrage; exercise each telegraph and safe-zone exclusion.
- [x] 7. Glacius: safe-circle nova, homing orbs, occluded sweep, mandatory four-crystal shield; test immunity and break.
- [x] 8. Loot/Data: ranked proportional payout, rare eligibility and duplicate conversion, retries/autosave/close; test math boundaries and save/rejoin when available.
- [x] 9. Shop/inventory: validate purchase/equip, kiosk range, owned equipment and armor bonuses; reject forged requests.
- [x] 10. HUD: countdown/HP, animated coins, strength, panels, teleport lock, results and rare banner; inspect client GUI.
- [x] 11. Polish: trails, sound, particles, impact shake, portrait layout; inspect screenshot and console.
- [x] 12. Final: controls, boss counters, loot and tuning guide, exact tested/untested status; final build and push.

Decisions: the submitted specification is the approved design; work autonomously. Preserve BLACKOUT.rbxlx. Base armor items each have an equipment slot; both distinct armor effects can be enabled. Teleport locks only in downtime with <=5 seconds remaining. Timeout still rolls qualifying rare drops per the given rules. Offline DataStore sessions never overwrite live data.

Completion records implementation and the available checks. Live published DataStore save/rejoin and real multiplayer validation remain outstanding; see VERIFICATION.md.

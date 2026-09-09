# Studio verification

- Checkpoint 2: Studio Play console: `Colossus Arena: map ready 6`; no warnings/errors. Server asserts six base models, six spawns and six kiosk prompts. Edit camera screenshot confirms complete colorful radial map.
- Asset search: inspected free Minotaur 12485225836; rejected humanoid brown anatomy and incomplete-looking head for armored bull-golem art direction. Ice-wizard and fantasy-sword search results were unrelated creatures/buildings. Free tree 12549617200 audited: zero scripts, two meshes. Procedural fallback avoids runtime asset-loading dependency; imported candidates remain isolated in ServerStorage during review.
`n- Checkpoint 3: Play server asserts assigned index, matching RespawnLocation and avatar within 12 studs of owned spawn. Console clean.

- Checkpoint 4: observed the real 120-second timeout, Emberhorn cleanup and cycle 2 Glacius with 6500 HP. Initial Emberhorn HP 8000 and countdown 0..120 validated. Console clean; all 9 sources compiled with Lune.

- Checkpoint 5: actual equipped Tool.Activate dealt10;20 simultaneous remotes produced only one hit. Forged target/damage request from base changed no HP. Runtime probe passed shield immunity, unknown target rejection, remaining-HP cap, boss damage ledger=8000, death/downtime and post-death rejection. All six sword stats checked against spec with Lune. Console clean.

- User-requested interim push: combat checkpoints1-5 verified; Emberhorn, Glacius, telegraph rendering and economy source are in progress and are not yet fully runtime verified.

- Checkpoint 6: manual server fixtures passed Emberhorn slam radius/timing, three ring waves (75 grounded/0 jumping), charge line sidestep/stun, meteor timing and safe-zone exclusion. Runtime enrage trigger passed. Client capture shows ground warning before slam and bull-golem model. Console clean.

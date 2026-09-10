# Colossus Arena HUD

UIController builds a responsive HUD from server state. Builder Sans Medium and Bold replace the heavy display font. Warm charcoal surfaces, fine borders, gold/teal actions and subtle shadows preserve the palette.

- Boss panel uses 44% width on landscape and 90% in portrait; coins/strength move below it on phones.
- Inventory and teleport remain above mobile Jump. Keyboard shortcuts: B and T.
- Shared UIEffects provide hover/focus highlighting, a 2.5% lift, press compression, a brief flash and pooled hover/click sounds. Disabled actions remain still and silent.
- Inventory footer provides Music and Motion controls. Reduced motion disables button scaling and impact shake; essential combat telegraphs stay visible. Preferences are local to the current play session.
- Panels use a short reveal. HP text remains readable over both filled and empty tracks.
- Positions and sizes use scale-based UDim2 values. Lists use automatic canvas sizing.
- The client only displays state and requests actions; server validation owns purchases, equipment, currency, damage and teleport.

Tune typography and interactions in UIDefs; themes and fades in AudioDefs.

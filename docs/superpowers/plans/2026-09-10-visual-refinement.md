# Visual refinement plan — September 10

User requests cleaner professional map/UI preserving palette, animated buttons and interaction sounds/effects, distinct boss music, and a nicer sky without floating-platform presentation. Existing autonomous authorization applies.

Chosen direction: grounded sunlit mountain courtyard. Keep combat radius, six base locations, safe zones and telegraph contrast. Connect bases visually through planted land and stone causeways. Layer mountains and clouds at the horizon. UI uses one modern sans family, restrained rounded corners, thin borders, clear type hierarchy, short hover/press transitions and quiet sounds. Music crossfades per active boss and fades in downtime; provide a mute toggle.

1. MapBuilder + separate EnvironmentDefs: replace floating scenery with valley grounds, planted slopes, architectural causeways, distant mountains and richer atmosphere/clouds. Preserve gameplay dimensions. Inspect wide and player-level screenshots.
2. UIController + UIEffects: refine fonts, spacing and surfaces; shared hover/focus/press scale, stroke highlight and pooled hover/click audio. Animate modal entry. Test real mouse, B, touch layout and disabled teleport.
3. BossMusic + AudioDefs: source public Creator Store tracks, preload/verify, crossfade active boss, silence downtime, local music toggle. Test both tracks and rapid state changes.
4. Syntax + existing regression tests, Studio console and desktop/phone screenshots. Rebuild deliverable, document sourced assets and push changes.

Completed: valley geometry and sunset sky, UI typography/interactions/preferences, both loaded boss themes, Studio desktop/portrait and state-transition checks, regression suites, rebuilt place. Final clean startup verified current theme playing and refined HUD active. Source remains server-authoritative.

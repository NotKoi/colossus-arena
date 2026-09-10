# Decisions

- Follow the supplied twelve build checkpoints in order.
- Use a Rojo-compatible source hierarchy and server-authoritative game systems.
- Count crystal damage in contribution totals; verify boss damage separately against boss HP, because including 3,200 crystal HP makes the prompt’s total-equals-boss-HP assertion inconsistent.
- Only the existing BLACKOUT.rbxlx Studio session is connected. Preserve it; build Colossus Arena in a separate place.

- Preserve the explicitly requested bossMaxHP payout denominator, including crystal contribution, rather than normalize shares across contributors. Early kills use the remainder of the fixed 120-second cycle as downtime; timeouts immediately start the next cycle.
- Production source contains no manual boss-test switches. Unpublished Studio uses clearly labeled session-only profiles; live persistence requires a published experience and is not claimed verified.
- B opens inventory because Roblox consumes I for camera zoom. Phone buttons omit keyboard hints and sit above the native Jump control.

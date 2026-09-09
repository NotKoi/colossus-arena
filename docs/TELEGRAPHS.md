# Ability rendering contract

Every server telegraph packet has kind, cycle and start=workspace:GetServerTimeNow(). duration is the preview window for circles/lines/nova. All visual ground geometry clips to the central 120-radius arena. Clear destroys current-cycle visual effects. Clients use server time to stay aligned.

Kinds planned:
- Circle: position, radius, duration, color, label. Outline + transparent fill; ends at impact.
- Line: position, finish, width, duration, color, label.
- Ring: position, speed, maxRadius, width, duration (active expanding wave), color.
- Nova: positions (safe circles), radius, duration, color; blue safe zones and warning text.
- Orb: model server-owned moving part; uses replicated transform.
- Beam: position, angle, duration, radius, width, color; rotating with server time, blocked by tagged pillars.
- Burst: position, radius, duration, color; cosmetic impact.
- Clear: clear visuals.

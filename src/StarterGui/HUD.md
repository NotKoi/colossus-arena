# Colossus Arena HUD

The HUD is constructed at runtime by `UIController.client.luau` so it can respond to each player's profile, base color, viewport, input type, and live boss state.

- The boss panel centers at 50% width on landscape displays and 90% on portrait displays. Coins and strength move below it in portrait mode.
- Inventory and teleport controls stay above the lower-right mobile controls. Keyboard shortcuts are `I` and `T`.
- Inventory, shop, rewards, teleport requests, and profile synchronization use the centralized remotes. The client displays server state but never grants items, spends coins, equips gear, awards drops, or teleports itself.
- All positions and sizes use scale-based `UDim2` values. List rows use automatic canvas sizing and scale-relative row heights.

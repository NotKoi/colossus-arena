# Boss music

The client plays a distinct looping theme while each boss is active:

| Boss | Track | Creator Store publisher | Source |
| --- | --- | --- | --- |
| Emberhorn | Determined Epic Theme (Alt1) | APMOfficial | https://create.roblox.com/store/asset/1836104000 |
| Glacius | Battle! The Angel of Ice | DistrokidOfficial | https://create.roblox.com/store/asset/129144166532573 |

These tracks were selected from free Creator Store listings. Listing availability does not establish playback access for every experience; verify playback in the target published experience. No additional composer or licensing claims are implied here.

`AudioDefs` contains the asset IDs, volume (0.24), and crossfade duration (1.5 seconds). `BossMusic.client` reuses exactly two looping Sound instances under `SoundService.ColossusMusic`, named `EmberhornTheme` and `GlaciusTheme`. An inactive boss state fades both voices to silence and stops them. Rapid boss changes cancel old fades safely. Late joiners immediately select the current active boss.

Set the local player's `MusicMuted` attribute to `true` to fade out music, or `false` to restore the active boss theme. This preference affects only local music. Preloading runs asynchronously; inaccessible audio does not block the HUD and the script does not retry or issue repeated warnings.

For diagnostics, the folder's `ActiveTheme` is the requested audible boss (empty when inactive or muted); it does not prove sound is loaded. Each Sound has a `Loaded` attribute, and the folder's `Loaded` becomes true when both sounds report `IsLoaded`. Check actual audibility as well as these attributes in Studio and the published experience.

Studio validation: both tracks loaded (66.77s and 223.05s). Active-theme playback state, mute, downtime fade/stop, and rapid Emberhorn/Glacius transition cancellation passed. Inventory controls were exercised with actual mouse input. Published-experience audio permissions were not tested.

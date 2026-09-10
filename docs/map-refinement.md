# Sunset valley courtyard

The arena now sits in a continuous meadow with rounded foothills and two distant, low mountain ranges. Soft green near slopes give way to desaturated blue-gray distant ridges. The mint, teal, sandstone, gold, and six player colors remain the visual identity; warm cloud light and a six-face sunset sky add depth.

Revision 4 responds to Studio review of the first skyline: the high, repetitive triangle wall is replaced by fewer, much lower peaks farther back, with asymmetric slopes, varied summit heights, varied widths, and rotated faces. Broad, partially buried ellipsoids form rolling foothills. Twelve irregular foreground groves, low meadow rises, and fieldstones provide a middle distance around radius 360–425 without entering the arena or its paths. Map labels use Builder Sans Medium and title case.

Six limestone causeways retain their original dimensions and use thin player-color inlays. Outposts retain their spawn and upgrade interactions, with stone kiosk counters, supported teal roofs, color fascia, trees, and two lanterns per base. The existing flat arena pattern and directional medallions stay readable beneath combat effects. No new scenery enters the combat courtyard.

The courtyard perimeter has two low limestone terraces outside radius 120, restrained masonry buttresses, and six paired 10.5-stud gateway posts. The posts provide 20 studs of clear space between their feet around each 15-stud causeway. Teal crowns, mint panels, and narrow gold trims echo the palette without oversized monuments. A thin gold cap finishes the limestone rim. Terraces preserve the six existing angular openings.

## Compatibility and ownership

- `Config.Map` is unchanged: arena radius 120, floor top 0, six bases at radius 245, and 15-by-100 causeways.
- `ColossusMap`, `Arena.Floor`, `Bases.Base1` through `Base6`, `BaseIndex`, `BaseColor`, `Spawn`, `UpgradeKiosk`, and `ShopPrompt` are preserved.
- `EnvironmentDefs` owns the environment palette, skyline dimensions, sky settings, causeway details, and lighting parameters.
- Ground consists of nine anchored grass tiles, each below Roblox's part size limit. Mountain wedges are buried into this ground. All geometry belongs to `ColossusMap`; Terrain voxels are never changed.
- `ColossusValleyClouds` is the only Terrain child the builder replaces. Existing unrelated effects are untouched. Only the previously owned lighting effect names are refreshed.
- Same-revision builds reuse the map. A different environment revision replaces the owned map, so revisions should be built before gameplay systems cache its instances.
- Only the existing audited `Assets.LowPolyTree` is cloned. The sky uses the six texture faces from free Creator Store Sunset Skybox asset 3017752195 by bestgamer_inroblox. It was audited as one Sky with zero executable descendants; IDs are recorded in SkyDefs. [Source](https://create.roblox.com/store/asset/3017752195).

## Validation

`lune run tests/syntax.luau` passed after the implementation. Desktop and phone Studio screenshots were inspected; all six causeway corridors passed raycast clearance checks. Low-end physical-device rendering cost remains unmeasured. The ground is now walkable outside causeways, which is an intentional consequence of grounding the setting; combat boundaries still belong to the existing gameplay systems.

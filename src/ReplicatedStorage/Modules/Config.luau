local Config = {}

Config.Map = {
	ArenaRadius = 120,
	TopY = 0,
	FloorThickness = 7,
	BaseCount = 6,
	BaseRadius = 245,
	BasePlatformRadius = 34,
	BridgeWidth = 15,
	BridgeLength = 100,
	BridgeThickness = 4,
	RimHeight = 5,
	RimWidth = 4,
	RimSegments = 120,
	OpeningHalfAngle = 5,
	PatternRadius = 88,
	PatternWidth = 0.45,
	PatternSegments = 96,
	CenterRadius = 23,
	SpawnSize = Vector3.new(9, 1, 9),
	KioskOffset = Vector3.new(17, 0, 4),
	KioskSize = Vector3.new(8, 5, 5),
	BannerHeight = 20,
	TreeHeight = 14,
	SceneryRadius = 345,
	SceneryCount = 12,
	IslandRadius = 17,
}

Config.BaseColors = {
	Color3.fromRGB(255, 105, 110),
	Color3.fromRGB(255, 190, 63),
	Color3.fromRGB(115, 220, 122),
	Color3.fromRGB(67, 202, 247),
	Color3.fromRGB(163, 122, 248),
	Color3.fromRGB(246, 127, 213),
}

return Config

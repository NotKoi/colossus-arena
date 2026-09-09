local D = {
	Names = { "Nova", "Orbs", "Sweep", "Shield" },
	ArenaRadius = 120,
	GroundY = 0.18,
	Cadence = 4.5,
	EnragedCadence = 3,
	EnrageRatio = 0.25,
	ShieldRatio = 0.50,
	Shield = { Count = 4, Radius = 75, HP = 800, Stun = 4 },
	Nova = {
		Windup = 1.8, SafeCount = 3, EnragedSafeCount = 2, SafeRadius = 20,
		Damage = 45, SlowDuration = 2, SlowScale = 0.55,
	},
	Orbs = {
		Windup = 1.2, Count = 3, Speed = 34, Lifetime = 6, Radius = 3.5,
		Damage = 35, SpawnRadius = 12,
	},
	Sweep = {
		Windup = 1.5, Duration = 5, Radius = 120, Width = 5,
		Damage = 20, DamageInterval = 0.5, PillarCount = 4,
		PillarRadius = 45, PillarSize = Vector3.new(8, 28, 8), PillarLifetime = 20,
	},
	Model = {
		Cyan = Color3.fromRGB(82, 232, 255),
		White = Color3.fromRGB(235, 252, 255),
		Violet = Color3.fromRGB(151, 105, 255),
		Ice = Color3.fromRGB(125, 224, 255),
	},
}

return table.freeze(D)

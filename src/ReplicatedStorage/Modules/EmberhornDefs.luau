local D = {
	Names = { "Slam", "Ring", "Charge", "Rain" },
	GroundY = 0.35,
	ArenaRadius = 120,
	ArenaMargin = 10,
	EnrageRatio = 0.30,
	RainRatio = 0.50,
	Cadence = 5,
	EnragedCadence = 3.5,
	Contact = { Range = 12, Damage = 15, EnragedDamage = 25, Cooldown = 1 },
	Chase = { Speed = 8 },
	Animation = { ArmTween = 0.35 },
	Slam = { Windup = 1.5, Radius = 45, Damage = 40, KnockUp = 78, BurstDuration = 0.6, Label = "SLAM" },
	Ring = {
		Windup = 1.5, Waves = 3, Spacing = 1.2, Speed = 35, Width = 5,
		Damage = 25, JumpHeight = 6, Label = "JUMP THE RINGS",
	},
	Charge = {
		Windup = 1.8, Width = 14, Damage = 55, Speed = 75, Knockback = 95,
		Stun = 3, Label = "CHARGE",
	},
	Rain = { Windup = 1.2, Count = 8, Radius = 10, Damage = 30, BurstDuration = 0.5, MeteorHeight = 65, MeteorSize = 5, Label = "METEOR" },
	Model = {
		Rock = Color3.fromRGB(65, 28, 18),
		DarkRock = Color3.fromRGB(35, 18, 16),
		Armor = Color3.fromRGB(180, 54, 18),
		Gold = Color3.fromRGB(255, 174, 45),
		Molten = Color3.fromRGB(255, 70, 8),
		Horn = Color3.fromRGB(255, 205, 111),
		Enraged = Color3.fromRGB(255, 35, 4),
		Meteor = Color3.fromRGB(65, 22, 12),
	},
}

return table.freeze(D)

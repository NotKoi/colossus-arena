local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local Config = require(RS.Modules.Config)
local D = require(RS.Modules.GlaciusDefs)
local Glacius = {}

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function effectPart(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Shape = shape or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Parent = parent
	return p
end

local function modelPart(b, name, size, offset, color, material, shape)
	local p = effectPart(b.model, name, size, b.root.CFrame * offset, color, material, shape)
	p.CanQuery = false
	return p
end

local function stateShielded(value)
	local state = RS:FindFirstChild("BossState")
	if state then state:SetAttribute("Shielded", value) end
end

local function safeZonePlayer(player)
	return player:GetAttribute("InSafeZone") == true or player:GetAttribute("SafeZone") == true
end

local function arenaTargets(Boss)
	local targets = {}
	for _, target in Boss.ArenaPlayers() do
		if not safeZonePlayer(target.player) then table.insert(targets, target) end
	end
	return targets
end

local function validOrbTarget(target)
	return target
		and target.player.Parent == Players
		and target.root.Parent ~= nil
		and target.humanoid.Health > 0
		and flat(target.root.Position).Magnitude <= D.ArenaRadius
		and not safeZonePlayer(target.player)
end

local function randomGround(radiusMargin)
	local angle = math.random() * math.pi * 2
	local radius = math.sqrt(math.random()) * (D.ArenaRadius - radiusMargin)
	return Vector3.new(math.cos(angle) * radius, D.GroundY, math.sin(angle) * radius)
end

function Glacius.Build(b)
	b.root.Transparency = 1
	b.root.CanCollide = false
	b.root.CanQuery = true
	CollectionService:AddTag(b.model, "BossTarget")

	modelPart(b, "Robe", Vector3.new(13, 17, 10), CFrame.new(0, 0, 0), D.Model.Violet, Enum.Material.SmoothPlastic)
	modelPart(b, "Mantle", Vector3.new(18, 5, 12), CFrame.new(0, 7, 0), D.Model.White, Enum.Material.Glass)
	modelPart(b, "HeadCrystal", Vector3.new(8, 11, 8), CFrame.new(0, 15, 0) * CFrame.Angles(0, 0, math.rad(45)), D.Model.Cyan, Enum.Material.Neon)
	modelPart(b, "Crown", Vector3.new(4, 10, 4), CFrame.new(0, 23, 0) * CFrame.Angles(0, 0, math.rad(45)), D.Model.White, Enum.Material.Glass)
	modelPart(b, "LeftArm", Vector3.new(5, 14, 5), CFrame.new(-10, 3, 0) * CFrame.Angles(0, 0, math.rad(-25)), D.Model.Cyan, Enum.Material.Glass)
	modelPart(b, "RightArm", Vector3.new(5, 14, 5), CFrame.new(10, 3, 0) * CFrame.Angles(0, 0, math.rad(25)), D.Model.Cyan, Enum.Material.Glass)

	b.orbitShards = {}
	for i = 1, 6 do
		local shard = modelPart(b, "OrbitShard", Vector3.new(2.5, 8, 2.5), CFrame.new(), i % 2 == 0 and D.Model.White or D.Model.Cyan, Enum.Material.Neon)
		table.insert(b.orbitShards, shard)
	end
	local started = workspace:GetServerTimeNow()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not b.active or not b.model.Parent then connection:Disconnect(); return end
		local t = workspace:GetServerTimeNow() - started
		for i, shard in b.orbitShards do
			if shard.Parent then
				local angle = t * 0.55 + (i - 1) / #b.orbitShards * math.pi * 2
				local offset = Vector3.new(math.cos(angle) * 17, 7 + math.sin(t * 1.1 + i) * 2, math.sin(angle) * 17)
				shard.CFrame = CFrame.new(b.root.Position + offset) * CFrame.Angles(t, -angle, math.rad(45))
			end
		end
	end)
	b.orbitConnection = connection
end

local function spawnShield(b, Boss)
	if b.shieldTriggered or not b.active then return false end
	b.shieldTriggered = true
	b.shielded = true
	stateShielded(true)
	if Boss then Boss.Telegraph(b, "Clear", {}) end
	b.crystals = b.crystals or {}
	for i = 1, D.Shield.Count do
		local angle = (i - 1) / D.Shield.Count * math.pi * 2
		local position = Vector3.new(math.cos(angle) * D.Shield.Radius, 8, math.sin(angle) * D.Shield.Radius)
		local model = Instance.new("Model")
		model.Name = "ShieldCrystal" .. i
		local crystal = effectPart(model, "Crystal", Vector3.new(9, 16, 9), CFrame.new(position) * CFrame.Angles(0, angle, math.rad(45)), D.Model.Cyan, Enum.Material.Neon)
		model.PrimaryPart = crystal
		model:SetAttribute("Cycle", b.cycle)
		model:SetAttribute("ShieldCrystal", true)
		model:SetAttribute("HP", D.Shield.HP)
		model:SetAttribute("MaxHP", D.Shield.HP)
		model:SetAttribute("Position", position)
		model.Parent = b.effects
		CollectionService:AddTag(model, "BossTarget")
		b.crystals[model] = true
	end
	return true
end

function Glacius.OnDamaged(b, Boss)
	if b and Boss.Active(b) and not b.shieldTriggered and b.hp <= b.maxHP * D.ShieldRatio then
		return spawnShield(b, Boss)
	end
	return false
end

local function nova(b, Boss)
	local d = D.Nova
	local count = b.hp / b.maxHP <= D.EnrageRatio and d.EnragedSafeCount or d.SafeCount
	local positions = {}
	for _ = 1, count do table.insert(positions, randomGround(d.SafeRadius + 4)) end
	Boss.Telegraph(b, "Nova", { positions = positions, radius = d.SafeRadius, duration = d.Windup, color = D.Model.Cyan, label = "FIND A SAFE CIRCLE" })
	if not Boss.Wait(b, d.Windup) then return end
	if b.shielded then return end
	for _, target in arenaTargets(Boss) do
		local safe = false
		for _, position in positions do
			if (flat(target.root.Position) - flat(position)).Magnitude <= d.SafeRadius then safe = true; break end
		end
		if not safe then
			Boss.Hurt(b, target, d.Damage)
			local baseSpeed = target.player:GetAttribute("BaseWalkSpeed") or Config.Player.WalkSpeed
			local token = (target.player:GetAttribute("GlaciusSlowToken") or 0) + 1
			target.player:SetAttribute("GlaciusSlowToken", token)
            target.player:SetAttribute("GlaciusSlowUntil", workspace:GetServerTimeNow()+d.SlowDuration)
			target.humanoid.WalkSpeed = baseSpeed * d.SlowScale
			task.delay(d.SlowDuration, function()
				if target.player.Parent == Players and target.humanoid.Parent and target.player:GetAttribute("GlaciusSlowToken") == token then
					target.humanoid.WalkSpeed = target.player:GetAttribute("BaseWalkSpeed") or Config.Player.WalkSpeed
				end
			end)
		end
	end
end

local function orbTarget(Boss, index)
	local targets = arenaTargets(Boss)
	if #targets == 0 then return nil end
	return targets[(index - 1) % #targets + 1]
end

local function runOrb(b, Boss, orb, target)
	local d = D.Orbs
	local started = workspace:GetServerTimeNow()
	local last = orb.Position
	while Boss.Active(b) and orb.Parent and workspace:GetServerTimeNow() - started < d.Lifetime do
		if not validOrbTarget(target) then target = orbTarget(Boss, math.random(1, 99)) end
		if not target then break end
		local dt = RunService.Heartbeat:Wait()
		local delta = target.root.Position - last
		if delta.Magnitude < 0.01 then continue end
		local step = delta.Unit * math.min(d.Speed * dt, delta.Magnitude)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local excluded = { b.model, orb }
		for _, item in b.effects:GetChildren() do
			if item:IsA("BasePart") and item.Name == "HomingOrb" then table.insert(excluded, item) end
		end
		params.FilterDescendantsInstances = excluded
		local hit = workspace:Raycast(last, step, params)
		if hit then
			if hit.Instance:IsDescendantOf(target.player.Character) then Boss.Hurt(b, target, d.Damage) end
			break
		end
		local nextPosition = last + step
		if flat(nextPosition).Magnitude >= D.ArenaRadius - d.Radius then break end
		orb.CFrame = CFrame.lookAt(nextPosition, nextPosition + delta.Unit)
		last = nextPosition
		if delta.Magnitude <= d.Radius + 2 then Boss.Hurt(b, target, d.Damage); break end
	end
	if orb.Parent then orb:Destroy() end
end

local function orbs(b, Boss)
	local d = D.Orbs
	local targets = arenaTargets(Boss)
	if #targets == 0 then return end
	local previews = {}
	for i = 1, d.Count do
		local target = targets[(i - 1) % #targets + 1]
		table.insert(previews, target)
		Boss.Telegraph(b, "Circle", { position = flat(target.root.Position) + Vector3.new(0, D.GroundY, 0), radius = d.Radius * 2, duration = d.Windup, color = D.Model.Cyan, label = "ORB" })
	end
	if not Boss.Wait(b, d.Windup) then return end
	for i, target in previews do
		local angle = (i - 1) / d.Count * math.pi * 2
		local position = b.root.Position + Vector3.new(math.cos(angle) * d.SpawnRadius, 4, math.sin(angle) * d.SpawnRadius)
		local orb = effectPart(b.effects, "HomingOrb", Vector3.one * d.Radius * 2, CFrame.new(position), D.Model.Cyan, Enum.Material.Neon, Enum.PartType.Ball)
		orb.CanQuery = false
		Debris:AddItem(orb, d.Lifetime + 1)
		task.spawn(runOrb, b, Boss, orb, target)
	end
end

local function spawnPillars(b)
	local d = D.Sweep
	local pillars = {}
	for i = 1, d.PillarCount do
		local angle = (i - 1) / d.PillarCount * math.pi * 2
		local position = Vector3.new(math.cos(angle) * d.PillarRadius, d.PillarSize.Y / 2, math.sin(angle) * d.PillarRadius)
		local pillar = effectPart(b.effects, "IcePillar", d.PillarSize, CFrame.new(position) * CFrame.Angles(0, angle, math.rad(8)), D.Model.Ice, Enum.Material.Glass)
		pillar.CanCollide = true
		CollectionService:AddTag(pillar, "IcePillar")
		Debris:AddItem(pillar, d.PillarLifetime)
		table.insert(pillars, pillar)
	end
	return pillars
end

local function sweep(b, Boss)
	local d = D.Sweep
	spawnPillars(b)
	local angle = math.random() * math.pi * 2
	Boss.Telegraph(b, "Circle", { position = Vector3.new(0, D.GroundY, 0), radius = d.Radius, duration = d.Windup, color = D.Model.Violet, label = "ICE SWEEP" })
	if not Boss.Wait(b, d.Windup) then return end
	if b.shielded then return end
	local started = workspace:GetServerTimeNow()
	Boss.Telegraph(b, "Beam", { start = started, position = Vector3.new(0, D.GroundY, 0), angle = angle, duration = d.Duration, radius = d.Radius, width = d.Width, color = D.Model.Cyan })
	local lastDamage = {}
	while Boss.Active(b) and not b.shielded do
		local elapsed = workspace:GetServerTimeNow() - started
		if elapsed >= d.Duration then break end
		local beamAngle = angle + elapsed / d.Duration * math.pi * 2
		local direction = Vector3.new(math.cos(beamAngle), 0, math.sin(beamAngle))
		for _, target in arenaTargets(Boss) do
			local relative = flat(target.root.Position)
			local along = relative:Dot(direction)
			local across = math.abs(relative.X * direction.Z - relative.Z * direction.X)
			local now = workspace:GetServerTimeNow()
			if along >= 0 and along <= d.Radius and across <= d.Width * 0.5 and now - (lastDamage[target.player] or -math.huge) >= d.DamageInterval then
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Include
				params.FilterDescendantsInstances = CollectionService:GetTagged("IcePillar")
				local hit = workspace:Raycast(Vector3.new(0, 3, 0), direction * along, params)
				if not hit then lastDamage[target.player] = now; Boss.Hurt(b, target, d.Damage) end
			end
		end
		RunService.Heartbeat:Wait()
	end
end

local casts = { Nova = nova, Orbs = orbs, Sweep = sweep, Shield = spawnShield }

function Glacius.Cast(b, Boss, name)
	local cast = casts[name]
	if not cast or not Boss.Active(b) then return false end
	if workspace:GetServerTimeNow() < (b.stunnedUntil or 0) then return false end
	b.casting = true
	cast(b, Boss)
	b.casting = false
	return Boss.Active(b)
end

function Glacius.Run(b, Boss)
	local previous
	while Boss.Active(b) do
		Glacius.OnDamaged(b, Boss)
		local cadence = b.hp / b.maxHP <= D.EnrageRatio and D.EnragedCadence or D.Cadence
		if not Boss.Wait(b, cadence) then break end
		if workspace:GetServerTimeNow() < (b.stunnedUntil or 0) then continue end
		local choices = b.shielded and { "Orbs" } or { "Nova", "Orbs", "Sweep" }
		local name
		repeat name = choices[math.random(1, #choices)] until name ~= previous or #choices == 1
		previous = name
		Glacius.Cast(b, Boss, name)
	end
	if b.orbitConnection and b.orbitConnection.Connected then b.orbitConnection:Disconnect() end
end

return Glacius

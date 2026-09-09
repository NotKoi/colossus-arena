local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local D = require(RS.Modules.EmberhornDefs)
local Emberhorn = {}

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function part(b, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Shape = shape or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = b.model
	return p
end

local function localPart(b, name, size, offset, color, material, shape)
	return part(b, name, size, b.root.CFrame * offset, color, material, shape)
end

local function ground(position)
	return Vector3.new(position.X, D.GroundY, position.Z)
end

local function activeTargets(Boss)
	return Boss.ArenaPlayers()
end

local function nearest(Boss, position)
	local best, bestDistance
	for _, target in activeTargets(Boss) do
		local distance = (flat(target.root.Position) - flat(position)).Magnitude
		if not bestDistance or distance < bestDistance then
			best, bestDistance = target, distance
		end
	end
	return best, bestDistance
end

local function farthest(Boss, position)
	local best, bestDistance
	for _, target in activeTargets(Boss) do
		local distance = (flat(target.root.Position) - flat(position)).Magnitude
		if not bestDistance or distance > bestDistance then
			best, bestDistance = target, distance
		end
	end
	return best, bestDistance
end

local function raiseArms(b, raised)
	for _, arm in { b.leftArm, b.rightArm } do
		if arm and arm.Parent then
			local sign = arm == b.leftArm and -1 or 1
			local target = b.root.CFrame * CFrame.new(sign * 10, raised and 10 or 3, 0)
				* CFrame.Angles(0, 0, math.rad(sign * (raised and 55 or 12)))
			TweenService:Create(arm, TweenInfo.new(D.Animation.ArmTween, Enum.EasingStyle.Quad), { CFrame = target }):Play()
		end
	end
end

local function setEnraged(b)
	if b.enraged then return end
	b.enraged = true
	for _, item in b.model:GetDescendants() do
		if item:IsA("BasePart") then
			if item.Name == "MoltenCrack" then
				item.Color = D.Model.Enraged
				item.Material = Enum.Material.Neon
			elseif string.find(item.Name, "Armor") or string.find(item.Name, "Gold") or string.find(item.Name, "Pauldron") then
				item.Material = Enum.Material.Neon
			end
		end
	end
end

function Emberhorn.Build(b)
	b.root.Transparency = 1
	b.root.Color = D.Model.Molten
	b.root.Material = Enum.Material.Neon
	b.root.CanCollide = false
	CollectionService:AddTag(b.model, "BossTarget")

	local rock, armor, gold, molten, horn = D.Model.Rock, D.Model.Armor, D.Model.Gold, D.Model.Molten, D.Model.Horn
	localPart(b, "Torso", Vector3.new(19, 18, 13), CFrame.new(0, 3, 0), rock)
	localPart(b, "ChestArmor", Vector3.new(21, 9, 15), CFrame.new(0, 6, -0.5), armor, Enum.Material.Metal)
	localPart(b, "GoldChest", Vector3.new(12, 3, 15.5), CFrame.new(0, 7, -0.8), gold, Enum.Material.Metal)
	localPart(b, "Head", Vector3.new(11, 9, 10), CFrame.new(0, 14, 0), D.Model.DarkRock)
	localPart(b, "Muzzle", Vector3.new(8, 4, 6), CFrame.new(0, 11.5, -5), rock)
	localPart(b, "LeftHorn", Vector3.new(12, 3, 3), CFrame.new(-7, 18, 0) * CFrame.Angles(0, 0, math.rad(-38)), horn, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	localPart(b, "RightHorn", Vector3.new(12, 3, 3), CFrame.new(7, 18, 0) * CFrame.Angles(0, 0, math.rad(38)), horn, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	localPart(b, "LeftHornTip", Vector3.new(7, 2, 2), CFrame.new(-10, 22, 0) * CFrame.Angles(0, 0, math.rad(-58)), gold, Enum.Material.Metal, Enum.PartType.Cylinder)
	localPart(b, "RightHornTip", Vector3.new(7, 2, 2), CFrame.new(10, 22, 0) * CFrame.Angles(0, 0, math.rad(58)), gold, Enum.Material.Metal, Enum.PartType.Cylinder)
	b.leftArm = localPart(b, "LeftArm", Vector3.new(7, 17, 7), CFrame.new(-10, 3, 0) * CFrame.Angles(0, 0, math.rad(-12)), rock)
	b.rightArm = localPart(b, "RightArm", Vector3.new(7, 17, 7), CFrame.new(10, 3, 0) * CFrame.Angles(0, 0, math.rad(12)), rock)
	localPart(b, "LeftPauldron", Vector3.new(9, 7, 10), CFrame.new(-10, 8, 0), armor, Enum.Material.Metal)
	localPart(b, "RightPauldron", Vector3.new(9, 7, 10), CFrame.new(10, 8, 0), armor, Enum.Material.Metal)
	for _, x in { -6, 6 } do
		localPart(b, "Leg", Vector3.new(8, 14, 9), CFrame.new(x, -3, 0), D.Model.DarkRock)
		localPart(b, "GoldGreave", Vector3.new(9, 7, 10), CFrame.new(x, -5, -0.5), gold, Enum.Material.Metal)
	end
	for _, crack in {
		CFrame.new(0, 3, -6.7), CFrame.new(-5, 0, -6.7) * CFrame.Angles(0, 0, 0.55),
		CFrame.new(5, 1, -6.7) * CFrame.Angles(0, 0, -0.5), CFrame.new(0, 14, -5.1),
	} do
		localPart(b, "MoltenCrack", Vector3.new(1, 8, 0.35), crack, molten, Enum.Material.Neon)
	end
end

local function slam(b, Boss)
	local d = D.Slam
	raiseArms(b, true)
	Boss.Telegraph(b, "Circle", { position = ground(b.root.Position), radius = d.Radius, duration = d.Windup, color = D.Model.Molten, label = d.Label })
	if not Boss.Wait(b, d.Windup) then return end
	raiseArms(b, false)
	Boss.Telegraph(b, "Burst", { position = ground(b.root.Position), radius = d.Radius, duration = d.BurstDuration, color = D.Model.Molten })
	for _, target in activeTargets(Boss) do
		if (flat(target.root.Position) - flat(b.root.Position)).Magnitude <= d.Radius then
			Boss.Hurt(b, target, d.Damage, Vector3.new(0, d.KnockUp, 0))
		end
	end
end

local function ringWave(b, Boss, origin, maxRadius)
	local d = D.Ring
	local duration = maxRadius / d.Speed
	local start = workspace:GetServerTimeNow()
	Boss.Telegraph(b, "Ring", { start = start, position = origin, speed = d.Speed, maxRadius = maxRadius, width = d.Width, duration = duration, color = D.Model.Molten })
	local hit = {}
	while Boss.Active(b) do
		local radius = math.min(maxRadius, (workspace:GetServerTimeNow() - start) * d.Speed)
		for _, target in activeTargets(Boss) do
			if not hit[target.player] then
				local distance = (flat(target.root.Position) - flat(origin)).Magnitude
				if math.abs(distance - radius) <= d.Width * 0.5 and target.root.Position.Y - D.GroundY <= d.JumpHeight then
					hit[target.player] = true
					Boss.Hurt(b, target, d.Damage)
				end
			end
		end
		if radius >= maxRadius then break end
		RunService.Heartbeat:Wait()
	end
end

local function rings(b, Boss)
	local d = D.Ring
	local origin = ground(b.root.Position)
	local maxRadius = D.ArenaRadius + flat(origin).Magnitude
	Boss.Telegraph(b, "Circle", { position = origin, radius = maxRadius, duration = d.Windup, color = D.Model.Gold, label = d.Label })
	if not Boss.Wait(b, d.Windup) then return end
	for wave = 1, d.Waves do
		if not Boss.Active(b) then return end
		task.spawn(ringWave, b, Boss, origin, maxRadius)
		if wave < d.Waves and not Boss.Wait(b, d.Spacing) then return end
	end
end

local function charge(b, Boss)
	local d = D.Charge
	local target = farthest(Boss, b.root.Position)
	if not target then return end
	local startFlat = flat(b.root.Position)
	local aim = flat(target.root.Position) - startFlat
	if aim.Magnitude < 0.01 then return end
	local direction = aim.Unit
	local projection = -startFlat:Dot(direction)
	local discriminant = projection * projection + (D.ArenaRadius - D.ArenaMargin)^2 - startFlat.Magnitude^2
	local travel = math.max(0, projection + math.sqrt(math.max(0, discriminant)))
	local finishFlat = startFlat + direction * travel
	Boss.Telegraph(b, "Line", { position = ground(b.root.Position), finish = Vector3.new(finishFlat.X, D.GroundY, finishFlat.Z), width = d.Width, duration = d.Windup, color = D.Model.Molten, label = d.Label })
	if not Boss.Wait(b, d.Windup) then return end
	b.charging = true
	local hit = {}
	local travelled = 0
	while Boss.Active(b) and travelled < travel do
		local dt = RunService.Heartbeat:Wait()
		local previous = startFlat + direction * travelled
		local step = math.min(d.Speed * dt, travel - travelled)
		travelled += step
		local p = startFlat + direction * travelled
		b.model:PivotTo(CFrame.lookAt(Vector3.new(p.X, b.root.Position.Y, p.Z), Vector3.new(p.X, b.root.Position.Y, p.Z) + direction))
		for _, candidate in activeTargets(Boss) do
			local q = flat(candidate.root.Position)
			local segment = p - previous
			local along = (q - startFlat):Dot(direction)
			local alpha = segment.Magnitude > 0 and math.clamp((q - previous):Dot(segment) / segment:Dot(segment), 0, 1) or 0
			local distance = (q - (previous + segment * alpha)).Magnitude
			if not hit[candidate.player] and along >= 0 and along <= travel and distance <= d.Width * 0.5 then
				hit[candidate.player] = true
				Boss.Hurt(b, candidate, d.Damage, direction * d.Knockback + Vector3.new(0, d.Knockback * 0.35, 0))
			end
		end
	end
	b.charging = false
	b.stunnedUntil = workspace:GetServerTimeNow() + d.Stun
end

local function rain(b, Boss)
	local d = D.Rain
	local positions = {}
	for _ = 1, d.Count do
		local angle = math.random() * math.pi * 2
		local radius = math.sqrt(math.random()) * (D.ArenaRadius - d.Radius)
		table.insert(positions, Vector3.new(math.cos(angle) * radius, D.GroundY, math.sin(angle) * radius))
	end
	for _, position in positions do
		Boss.Telegraph(b, "Circle", { position = position, radius = d.Radius, duration = d.Windup, color = D.Model.Molten, label = d.Label })
		if b.effects and b.effects.Parent then
			local meteor = part({ model = b.effects }, "Meteor", Vector3.one * d.MeteorSize, CFrame.new(position + Vector3.new(0, d.MeteorHeight, 0)), D.Model.Meteor, Enum.Material.Slate, Enum.PartType.Ball)
			TweenService:Create(meteor, TweenInfo.new(d.Windup, Enum.EasingStyle.Linear), { Position = position }):Play()
			Debris:AddItem(meteor, d.Windup + d.BurstDuration)
		end
	end
	if not Boss.Wait(b, d.Windup) then return end
	for _, position in positions do
		Boss.Telegraph(b, "Burst", { position = position, radius = d.Radius, duration = d.BurstDuration, color = D.Model.Molten })
		for _, target in activeTargets(Boss) do
			if (flat(target.root.Position) - flat(position)).Magnitude <= d.Radius then Boss.Hurt(b, target, d.Damage) end
		end
	end
end

local casts = { Slam = slam, Ring = rings, Charge = charge, Rain = rain }

function Emberhorn.Cast(b, Boss, name)
	local cast = casts[name]
	if not cast or not Boss.Active(b) then return false end
	b.casting = true
	cast(b, Boss)
	b.casting = false
	return Boss.Active(b)
end

local function startMovementAndContact(b, Boss)
	local lastHit = {}
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not Boss.Active(b) then
			connection:Disconnect()
			return
		end
		if b.hp / b.maxHP <= D.EnrageRatio then setEnraged(b) end
		local now = workspace:GetServerTimeNow()
		if not b.charging and now >= (b.stunnedUntil or 0) then
			for _, candidate in activeTargets(Boss) do
				local candidateDistance = (flat(candidate.root.Position) - flat(b.root.Position)).Magnitude
				if candidateDistance <= D.Contact.Range and now - (lastHit[candidate.player] or -math.huge) >= D.Contact.Cooldown then
					lastHit[candidate.player] = now
					Boss.Hurt(b, candidate, b.enraged and D.Contact.EnragedDamage or D.Contact.Damage)
				end
			end
		end
		local target, distance = nearest(Boss, b.root.Position)
		if target and distance then
			if not b.charging and not b.casting and now >= (b.stunnedUntil or 0) and distance > D.Contact.Range then
				local delta = flat(target.root.Position) - flat(b.root.Position)
				if delta.Magnitude > 0.01 then
					local step = math.min(D.Chase.Speed * dt, delta.Magnitude)
					local p = b.root.Position + delta.Unit * step
					b.model:PivotTo(CFrame.lookAt(p, p + delta.Unit))
				end
			end
		end
	end)
	b.contactConnection = connection
end

function Emberhorn.Run(b, Boss)
	startMovementAndContact(b, Boss)
	local previous
	while Boss.Active(b) do
		local cadence = b.hp / b.maxHP <= D.EnrageRatio and D.EnragedCadence or D.Cadence
		if not Boss.Wait(b, cadence) then break end
		if workspace:GetServerTimeNow() < (b.stunnedUntil or 0) then continue end
		local choices = { "Slam", "Ring", "Charge" }
		if b.hp / b.maxHP < D.RainRatio then table.insert(choices, "Rain") end
		local name
		repeat name = choices[math.random(1, #choices)] until name ~= previous or #choices == 1
		previous = name
		Emberhorn.Cast(b, Boss, name)
	end
	if b.contactConnection and b.contactConnection.Connected then b.contactConnection:Disconnect() end
end

return Emberhorn

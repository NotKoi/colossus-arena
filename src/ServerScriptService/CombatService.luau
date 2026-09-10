local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Modules.Config)
local SwordDefs = require(ReplicatedStorage.Modules.SwordDefs)
local Remotes = require(script.Parent.Remotes)

local CombatService = {}
local DEFAULT_SWORD = "WoodenTrainer"
local SWOOSH_ID = Config.Audio.Swing

local bossController
local getProfile
local playerConnections = {}
local lastRemote = {}
local lastSwing = {}
local activeSwing = {}

local function defaultProfile()
	return { owned = { WoodenTrainer = true }, equipped = DEFAULT_SWORD, armor = {} }
end

local function disconnectAll(connections)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function closestPointOnPart(part, worldPoint)
	local localPoint = part.CFrame:PointToObjectSpace(worldPoint)
	local half = part.Size * 0.5
	local clamped = Vector3.new(
		math.clamp(localPoint.X, -half.X, half.X),
		math.clamp(localPoint.Y, -half.Y, half.Y),
		math.clamp(localPoint.Z, -half.Z, half.Z)
	)
	return part.CFrame:PointToWorldSpace(clamped)
end

local function targetPoint(model, origin)
	local bestPoint
	local bestDistance = math.huge
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local point = closestPointOnPart(descendant, origin)
			local distance = (point - origin).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				bestPoint = point
			end
		end
	end
	return bestPoint, bestDistance
end

local function resolveTaggedTarget(instance)
	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") and CollectionService:HasTag(current, "BossTarget") then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function tryDamage(player, swing, target)
	if swing.hit[target] or not target.Parent or not CollectionService:HasTag(target, "BossTarget") then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not humanoid or humanoid.Health <= 0 or swing.tool.Parent ~= character then
		return
	end
	local _, distance = targetPoint(target, root.Position)
	if distance > Config.Combat.Range then
		return
	end
	swing.hit[target] = true
	bossController.Damage(player, target, swing.damage)
end

local function overlapSweep(player, swing)
	local character = player.Character
	local blade = swing.tool:FindFirstChild("Blade")
	if not character or not blade then return end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	for _, part in workspace:GetPartBoundsInBox(blade.CFrame, blade.Size + Vector3.new(2, 2, 2), params) do
		local target = resolveTaggedTarget(part)
		if target then tryDamage(player, swing, target) end
	end
end

local function animateSwing(tool, token)
	local original = tool.Grip
	local backswing = original * CFrame.Angles(0, 0, math.rad(-70))
	local forward = original * CFrame.Angles(0, 0, math.rad(75))
	local tween = TweenService:Create(tool, TweenInfo.new(Config.Combat.SwingWindow * 0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Grip = forward })
	tool.Grip = backswing
	tween:Play()
	task.delay(Config.Combat.SwingWindow, function()
		local active = activeSwing[tool]
		if tool.Parent and (not active or active.token == token) then
			TweenService:Create(tool, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Grip = original }):Play()
		end
	end)
end

local function beginSwing(player, tool)
	local now = workspace:GetServerTimeNow()
	if now - (lastRemote[player] or -math.huge) < Config.Combat.RemoteInterval then return end
	lastRemote[player] = now
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or tool.Parent ~= character or not humanoid or humanoid.Health <= 0 then return end
	local swordId = tool:GetAttribute("SwordId")
	local def = swordId and SwordDefs[swordId]
	if not def or now - (lastSwing[player] or -math.huge) < def.Cooldown then return end
	lastSwing[player] = now
	local token = {}
	local swing = { tool = tool, damage = def.Damage, hit = {} }
	activeSwing[tool] = { token = token, swing = swing }
	tool:SetAttribute("Swinging", true)
	local sound = tool.Handle:FindFirstChild("Swoosh")
	if sound then sound:Play() end
	local trail = tool.Handle:FindFirstChildOfClass("Trail")
	if trail then trail.Enabled = true end
	animateSwing(tool, token)
	task.spawn(function()
		local deadline = workspace:GetServerTimeNow() + Config.Combat.SwingWindow
		repeat
			overlapSweep(player, swing)
			task.wait()
		until not activeSwing[tool] or activeSwing[tool].token ~= token or workspace:GetServerTimeNow() >= deadline
		if activeSwing[tool] and activeSwing[tool].token == token then
			activeSwing[tool] = nil
			if tool.Parent then tool:SetAttribute("Swinging", false) end
			if trail then trail.Enabled = false end
		end
	end)
end

local function createSwordTool(swordId, def)
	local tool = Instance.new("Tool")
	tool.Name = def.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("SwordId", swordId)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.55, 1.45, 0.55)
	handle.Color = Color3.fromRGB(74, 53, 42)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.75, 0.45, 4.6)
	blade.Color = def.Color
	blade.Material = Enum.Material.Neon
	blade.CanCollide = false
	blade.CanTouch = true
	blade.Massless = true
	blade.CFrame = handle.CFrame * CFrame.new(0, 1.5, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
	blade.Parent = tool
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "rbxasset://fonts/sword.mesh"
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = blade

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = blade
	weld.Parent = handle

	local bottom = Instance.new("Attachment")
	bottom.Position = Vector3.new(0, 0, -blade.Size.Z * 0.5)
	bottom.Parent = blade
	local top = Instance.new("Attachment")
	top.Position = Vector3.new(0, 0, blade.Size.Z * 0.5)
	top.Parent = blade
	local trail = Instance.new("Trail")
	trail.Attachment0 = bottom
	trail.Attachment1 = top
	trail.Color = ColorSequence.new(def.Color, Color3.new(1, 1, 1))
	trail.Lifetime = 0.12
	trail.Enabled = false
	trail.Parent = handle

	local sound = Instance.new("Sound")
	sound.Name = "Swoosh"
	sound.SoundId = SWOOSH_ID
	sound.Volume = 0.45
	sound.Parent = handle

	blade.Touched:Connect(function(part)
		local active = activeSwing[tool]
		local owner = Players:GetPlayerFromCharacter(tool.Parent)
		local target = active and resolveTaggedTarget(part)
		if owner and target then
			tryDamage(owner, active.swing, target)
		end
	end)
	return tool
end

function CombatService.Refresh(player)
	local profile = (getProfile and getProfile(player)) or defaultProfile()
	profile = type(profile) == "table" and profile or defaultProfile()
	local equipped = profile.equipped
	if not SwordDefs[equipped] or not (profile.owned and profile.owned[equipped]) then equipped = DEFAULT_SWORD end
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("SwordId") then child:Destroy() end
			end
		end
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		local tool = createSwordTool(equipped, SwordDefs[equipped])
		tool.Parent = backpack
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then humanoid:EquipTool(tool) end
	end
end

function CombatService.Start(controller, profileProvider)
	bossController = controller
	getProfile = profileProvider
	Remotes.Swing.OnServerEvent:Connect(function(player)
		local character = player.Character
		local tool = character and character:FindFirstChildOfClass("Tool")
		if tool and tool:GetAttribute("SwordId") then beginSwing(player, tool) end
	end)
	local function bindPlayer(player)
		local connections = {}
		playerConnections[player] = connections
		table.insert(connections, player.CharacterAdded:Connect(function()
			task.defer(CombatService.Refresh, player)
		end))
		if player.Character then task.defer(CombatService.Refresh, player) end
	end
	for _, player in Players:GetPlayers() do bindPlayer(player) end
	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		if playerConnections[player] then disconnectAll(playerConnections[player]) end
		playerConnections[player] = nil
		lastRemote[player] = nil
		lastSwing[player] = nil
	end)
end

return CombatService

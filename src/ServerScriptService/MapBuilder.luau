-- Procedural, anchored map. Build is safe to call repeatedly.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"))
local M = Config.Map
local MapBuilder = {}
local sand = Color3.fromRGB(211, 202, 151)
local mint = Color3.fromRGB(151, 198, 161)
local teal = Color3.fromRGB(55, 158, 153)
local gold = Color3.fromRGB(244, 191, 77)
local grass = Color3.fromRGB(106, 194, 116)

local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function disc(parent, name, radius, thickness, position, color)
	local p = part(parent, name, Vector3.new(thickness, radius * 2, radius * 2),
		CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2), color)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function label(parent, text)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(14, 3)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.MaxDistance = 180
	gui.Parent = parent
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.45
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = gui
end

local function tree(parent, pos, scale)
	local assets = ServerStorage:FindFirstChild("Assets")
	local template = assets and assets:FindFirstChild("LowPolyTree")
	if template and template:IsA("Model") then
		local model = template:Clone()
		local _, originalSize = model:GetBoundingBox()
		if originalSize.Y > 0 then
			model:ScaleTo(model:GetScale() * M.TreeHeight * M.TreeVisualHeightMultiplier * scale / originalSize.Y)
			local box, size = model:GetBoundingBox()
			local bottom = box.Position - Vector3.new(0, size.Y / 2, 0)
			model:PivotTo(model:GetPivot() + (pos - bottom))
			for _, child in model:GetDescendants() do
				if child:IsA("BasePart") then
					child.Anchored, child.CanCollide = true, false
					child.Color = child.Name == "Foliage" and Color3.fromRGB(72, 163, 91) or Color3.fromRGB(137, 93, 55)
				end
			end
			model.Parent = parent
			return
		end
		model:Destroy()
	end
	local h = M.TreeHeight * scale
	part(parent, "Trunk", Vector3.new(2, h * 0.65, 2) * scale,
		CFrame.new(pos + Vector3.new(0, h * 0.3, 0)), Color3.fromRGB(123, 91, 66), Enum.Material.Wood)
	for level = 0, 1 do
		local crown = part(parent, "Canopy", Vector3.new(h * 0.7, h * 0.65, h * 0.7),
			CFrame.new(pos + Vector3.new(0, h * (0.75 + level * 0.27), 0)) * CFrame.Angles(0, level + scale, 0),
			level == 0 and Color3.fromRGB(58, 155, 103) or grass)
		crown.CanCollide = false
	end
end

local function ring(parent, name, radius, width, height, y, count, color, openings)
	local arc = math.pi * 2 / count
	for i = 0, count - 1 do
		local a = i * arc
		local sector = 360 / M.BaseCount
		local distance = math.abs((math.deg(a) + sector / 2) % sector - sector / 2)
		if not openings or distance > M.OpeningHalfAngle then
			local segment = part(parent, name, Vector3.new(width, height, radius * arc + 0.2),
				CFrame.new(math.cos(a) * radius, y, math.sin(a) * radius) * CFrame.Angles(0, -a, 0), color)
			if not openings then segment.CanCollide, segment.CanQuery, segment.CanTouch = false, false, false end
		end
	end
end

local function lighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(126, 151, 157)
	Lighting.OutdoorAmbient = Color3.fromRGB(154, 177, 178)
	Lighting.GlobalShadows = true
	for _, name in {"ColossusAtmosphere", "ColossusBloom", "ColossusSunRays", "ColossusSky"} do
		local old = Lighting:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "ColossusAtmosphere"
	atmosphere.Density, atmosphere.Offset = 0.22, 0.1
	atmosphere.Color = Color3.fromRGB(188, 231, 231)
	atmosphere.Decay = Color3.fromRGB(241, 214, 167)
	atmosphere.Haze, atmosphere.Glare = 1.2, 0.15
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold = "ColossusBloom", 0.15, 24, 1.4
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Name, rays.Intensity, rays.Spread = "ColossusSunRays", 0.06, 0.8
	rays.Parent = Lighting
	local sky = Instance.new("Sky")
	sky.Name, sky.StarCount = "ColossusSky", 0
	sky.Parent = Lighting
end

function MapBuilder.Build()
	local existing = workspace:FindFirstChild("ColossusMap")
	if existing then lighting(); return existing end
	local map = Instance.new("Model")
	map.Name = "ColossusMap"
	local arena = Instance.new("Model")
	arena.Name, arena.Parent = "Arena", map
	disc(arena, "Floor", M.ArenaRadius, M.FloorThickness,
		Vector3.new(0, M.TopY - M.FloorThickness / 2, 0), mint)
	disc(arena, "Underside", M.ArenaRadius * 0.94, M.FloorThickness * 2,
		Vector3.new(0, M.TopY - M.FloorThickness * 1.5, 0), teal)
	local function floorArt(name, radius, layer, color, offset)
		local p = disc(arena, name, radius, M.PatternLayerThickness,
			(offset or Vector3.zero) + Vector3.new(0, M.TopY + layer * M.PatternLayerStep, 0), color)
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		return p
	end
	local patternColors = {teal, mint, sand}
	for layer, radiusFactor in M.FloorPatternRadiusFactors do
		floorArt("FloorPattern" .. layer, M.ArenaRadius * radiusFactor, layer, patternColors[layer])
	end
	floorArt("CenterMedallion", M.CenterRadius, 4, teal)
	ring(arena, "Inlay", M.PatternRadius, M.PatternWidth, M.PatternLayerThickness,
		M.TopY + 4 * M.PatternLayerStep, M.PatternSegments, gold, false)
	ring(arena, "Rim", M.ArenaRadius - M.RimWidth / 2, M.RimWidth, M.RimHeight,
		M.TopY + M.RimHeight / 2, M.RimSegments, gold, true)
	local bases = Instance.new("Folder")
	bases.Name, bases.Parent = "Bases", map
	for i = 1, M.BaseCount do
		local angle = (i - 1) * math.pi * 2 / M.BaseCount
		local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local center = radial * M.BaseRadius + Vector3.new(0, M.TopY, 0)
		local color = Config.BaseColors[i]
		floorArt("DirectionMedallion" .. i, M.DirectionalMedallionRadius, 4, color, radial * M.DirectionalMedallionDistance)
		local frame = CFrame.new(center) * CFrame.Angles(0, -angle - math.pi / 2, 0)
		local base = Instance.new("Model")
		base.Name = "Base" .. i
		base:SetAttribute("BaseIndex", i)
		base:SetAttribute("BaseColor", color)
		base.Parent = bases
		disc(base, "Platform", M.BasePlatformRadius, M.FloorThickness, center - Vector3.new(0, M.FloorThickness / 2, 0), sand)
		disc(base, "Foundation", M.BasePlatformRadius * 0.96, M.FloorThickness, center - Vector3.new(0, M.FloorThickness * 1.5, 0), color)
		local bridgeCenter = radial * (M.ArenaRadius + M.BridgeLength / 2 - 1)
		part(base, "Bridge", Vector3.new(M.BridgeWidth, M.BridgeThickness, M.BridgeLength),
			CFrame.new(bridgeCenter + Vector3.new(0, M.TopY - M.BridgeThickness / 2, 0)) * CFrame.Angles(0, -angle - math.pi / 2, 0), color)
		local spawn = Instance.new("SpawnLocation")
		spawn.Name, spawn.Size = "Spawn", M.SpawnSize
		spawn.CFrame = frame + Vector3.new(0, M.SpawnSize.Y / 2, 0)
		spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
		spawn.Color, spawn.Material = color, Enum.Material.SmoothPlastic
		spawn.Parent = base
		local kiosk = part(base, "UpgradeKiosk", M.KioskSize,
			frame * CFrame.new(M.KioskOffset + Vector3.new(0, M.KioskSize.Y / 2, 0)), teal)
		part(base, "KioskAwning", Vector3.new(M.KioskSize.X + 2, 1, M.KioskSize.Z + 2),
			kiosk.CFrame * CFrame.new(0, M.KioskSize.Y / 2 + 1, 0), color)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name, prompt.ActionText, prompt.ObjectText = "ShopPrompt", "Open Upgrades", "Colossus Forge"
		prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0, 12, false
		prompt.Parent = kiosk
		label(kiosk, "UPGRADES")
		local bannerCF = frame * CFrame.new(-17, M.BannerHeight / 2, 8)
		part(base, "BannerPole", Vector3.new(0.7, M.BannerHeight, 0.7), bannerCF, gold, Enum.Material.Metal)
		local banner = part(base, "Banner", Vector3.new(9, 6, 0.35), bannerCF * CFrame.new(4.5, M.BannerHeight / 2 - 4, 0), color)
		banner.CanCollide = false
		label(banner, "BASE " .. i)
		tree(base, frame:PointToWorldSpace(Vector3.new(-20, 0, -12)), 0.85)
		tree(base, frame:PointToWorldSpace(Vector3.new(19, 0, -17)), 0.65)
	end
	local scenery = Instance.new("Folder")
	scenery.Name, scenery.Parent = "Scenery", map
	for i = 1, M.SceneryCount do
		local a = (i - 0.5) * math.pi * 2 / M.SceneryCount
		local pos = Vector3.new(math.cos(a) * M.SceneryRadius, M.TopY - 16 + (i % 3) * 7, math.sin(a) * M.SceneryRadius)
		disc(scenery, "FloatingIsland", M.IslandRadius, 7, pos - Vector3.new(0, 3.5, 0), grass)
		local rock = part(scenery, "IslandRock", Vector3.new(22, 22, 22), CFrame.new(pos - Vector3.new(0, 14, 0)) * CFrame.Angles(0, a, math.pi / 4), teal, Enum.Material.Slate)
		rock.CanCollide = false
		tree(scenery, pos, 1 + (i % 2) * 0.25)
	end
	lighting()
	map.Parent = workspace
	return map
end

return MapBuilder

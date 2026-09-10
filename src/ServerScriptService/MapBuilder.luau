-- Procedural, anchored map. Build is safe to call repeatedly.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"))
local E = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EnvironmentDefs"))
local SkyDefs = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SkyDefs"))
local M = Config.Map
local MapBuilder = {}
local sand, mint, teal, gold, grass = E.Palette.Stone, E.Palette.Mint, E.Palette.Teal, E.Palette.Gold, E.Palette.Grass

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
	t.Font = Enum.Font.BuilderSansMedium
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

local function ring(parent, name, radius, width, height, y, count, color, openings, material)
	local arc = math.pi * 2 / count
	for i = 0, count - 1 do
		local a = i * arc
		local sector = 360 / M.BaseCount
		local distance = math.abs((math.deg(a) + sector / 2) % sector - sector / 2)
		if not openings or distance > M.OpeningHalfAngle then
			local segment = part(parent, name, Vector3.new(width, height, radius * arc + 0.2),
				CFrame.new(math.cos(a) * radius, y, math.sin(a) * radius) * CFrame.Angles(0, -a, 0), color, material)
			if not openings then segment.CanCollide, segment.CanQuery, segment.CanTouch = false, false, false end
		end
	end
end

local function lighting()
	Lighting.ClockTime = E.Sky.ClockTime
	Lighting.Brightness = E.Sky.Brightness
	Lighting.Ambient = E.Sky.Ambient
	Lighting.OutdoorAmbient = E.Sky.OutdoorAmbient
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = SkyDefs.Diffuse
	Lighting.EnvironmentSpecularScale = SkyDefs.Specular
	Lighting.ExposureCompensation = SkyDefs.Exposure
	for _, name in {"ColossusAtmosphere", "ColossusBloom", "ColossusSunRays", "ColossusSky"} do
		local old = Lighting:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "ColossusAtmosphere"
	atmosphere.Density, atmosphere.Offset = E.Sky.Density, E.Sky.Offset
	atmosphere.Color = E.Sky.Color
	atmosphere.Decay = E.Sky.Decay
	atmosphere.Haze, atmosphere.Glare = E.Sky.Haze, E.Sky.Glare
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold = "ColossusBloom", 0.15, 24, 1.4
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Name, rays.Intensity, rays.Spread = "ColossusSunRays", 0.06, 0.8
	rays.Parent = Lighting
	local sky = Instance.new("Sky")
	sky.Name, sky.StarCount = "ColossusSky", 0
	for property, assetId in SkyDefs.Faces do sky[property] = assetId end
	sky.CelestialBodiesShown = false
	sky.SunAngularSize = 12
	sky.Parent = Lighting
	-- Clouds must live under Terrain. Only our uniquely named effect is replaced;
	-- no Terrain voxels or unrelated atmosphere/sky objects are ever cleared.
	local oldClouds = workspace.Terrain:FindFirstChild("ColossusValleyClouds")
	if oldClouds then oldClouds:Destroy() end
	local clouds = Instance.new("Clouds")
	clouds.Name = "ColossusValleyClouds"
	clouds.Cover, clouds.Density, clouds.Color = E.Sky.CloudCover, E.Sky.CloudDensity, E.Sky.CloudColor
	clouds.Parent = workspace.Terrain
end

local function decoration(p)
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	return p
end

local function valley(parent)
	-- A continuous, grounded meadow supports arena, causeways, and outposts.
	-- All terrain-like geometry belongs to this map, so rebuilds are reversible.
	for x = -E.Ground.TileRadius, E.Ground.TileRadius do
		for z = -E.Ground.TileRadius, E.Ground.TileRadius do
			part(parent, "ValleyGround", Vector3.new(E.Ground.TileSize, E.Ground.Depth, E.Ground.TileSize),
				CFrame.new(x * E.Ground.TileSize, M.TopY + E.Ground.Top - E.Ground.Depth / 2, z * E.Ground.TileSize), grass, Enum.Material.Grass)
		end
	end
	local random = Random.new(E.Landscape.Seed)
	local function mound(name, position, size, color, angle)
		local hill = part(parent, name, size, CFrame.new(position) * CFrame.Angles(0, angle, 0), color, Enum.Material.Grass)
		hill.Shape = Enum.PartType.Ball
		return hill
	end
	local function ridge(settings, name, color, phase)
		for i = 1, settings.Count do
			local a = (i - 1) * math.pi * 2 / settings.Count + phase + random:NextNumber(-0.17, 0.17)
			local height = settings.Height * random:NextNumber(0.4, 1.35)
			local width = settings.Width * random:NextNumber(0.75, 1.3)
			local radius = settings.Radius + random:NextNumber(-65, 65)
			local position = Vector3.new(math.cos(a) * radius, M.TopY + E.Ground.Top - 30, math.sin(a) * radius)
			local orientation = -a + random:NextNumber(-0.55, 0.55)
			-- Unequal slopes and summit offsets break the repeating triangle silhouette.
			local split = random:NextNumber(0.3, 0.68)
			for side = -1, 1, 2 do
				local slopeWidth = width * (side == -1 and split or 1 - split)
				local wedge = Instance.new("WedgePart")
				wedge.Name = name
				wedge.Size = Vector3.new(settings.Depth, height, slopeWidth)
				wedge.CFrame = CFrame.new(position) * CFrame.Angles(0, orientation, 0)
					* CFrame.new(0, height / 2, side * slopeWidth / 2)
					* CFrame.Angles(0, side == 1 and math.pi or 0, 0)
				wedge.Anchored = true
				wedge.Material = Enum.Material.Slate
				wedge.Color = color:Lerp(E.Palette.Limestone, (i % 3) * 0.035)
				wedge.TopSurface, wedge.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
				wedge.Parent = parent
			end
		end
	end
	ridge(E.DistantMountains, "DistantMountain", E.Palette.DistantMountain, 0.13)
	ridge(E.Mountains, "Mountain", E.Palette.Mountain, 0.05)
	for i = 1, E.Foothills.Count do
		local a = (i - 1) * math.pi * 2 / E.Foothills.Count + random:NextNumber(-0.16, 0.16)
		local radius = E.Foothills.Radius + random:NextNumber(-65, 65)
		local height = E.Foothills.Height * random:NextNumber(0.65, 1.25)
		mound("RollingFoothill", Vector3.new(math.cos(a) * radius, M.TopY + E.Ground.Top - height * 0.18, math.sin(a) * radius),
			Vector3.new(E.Foothills.Width * random:NextNumber(0.8, 1.3), height, E.Foothills.Depth),
			E.Palette.Foothill:Lerp(grass, random:NextNumber(0.15, 0.5)), -a)
	end
	-- Small, irregular groves give the foreground a scale between bases and hills.
	-- Their inner edge remains well beyond all paths and the combat courtyard.
	for i = 1, E.Landscape.Clusters do
		local a = (i - 0.35) * math.pi * 2 / E.Landscape.Clusters + random:NextNumber(-0.08, 0.08)
		local radius = E.Landscape.Radius + random:NextNumber(0, E.Landscape.RadiusVariation)
		local origin = Vector3.new(math.cos(a) * radius, M.TopY + E.Ground.Top, math.sin(a) * radius)
		local height = E.Landscape.MoundHeight * random:NextNumber(0.65, 1.1)
		mound("MeadowRise", origin - Vector3.new(0, height * 0.2, 0),
			Vector3.new(E.Landscape.MoundWidth, height, E.Landscape.MoundDepth), grass:Lerp(mint, 0.08), -a)
		for j = 1, 3 do
			local offset = Vector3.new((j - 2) * 14, height * 0.23, random:NextNumber(-12, 12))
			tree(parent, origin + offset, random:NextNumber(0.85, 1.45))
		end
		local stone = mound("Fieldstone", origin + Vector3.new(30, 0.3, -14), Vector3.new(7, 3, 5), sand, a)
		stone.Material = Enum.Material.Limestone
	end
end

local function lantern(parent, cf)
	part(parent, "LanternFoot", Vector3.new(2.4, 0.7, 2.4), cf * CFrame.new(0, 0.35, 0), sand, Enum.Material.Limestone)
	part(parent, "LanternPost", Vector3.new(0.45, E.Architecture.LanternHeight, 0.45),
		cf * CFrame.new(0, E.Architecture.LanternHeight / 2, 0), teal, Enum.Material.Metal)
	local glow = decoration(part(parent, "LanternGlass", Vector3.new(1.2, 1.7, 1.2),
		cf * CFrame.new(0, E.Architecture.LanternHeight, 0), E.Palette.Lantern, Enum.Material.Neon))
	part(parent, "LanternCap", Vector3.new(1.8, 0.35, 1.8),
		cf * CFrame.new(0, E.Architecture.LanternHeight + 1, 0), teal, Enum.Material.Metal)
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range = E.Palette.Lantern, E.Architecture.LanternBrightness, E.Architecture.LanternRange
	light.Shadows = false
	light.Parent = glow
end

local function courtyardArchitecture(arena)
	local A = E.Architecture
	-- Terraces begin outside the combat floor and share the six existing openings.
	ring(arena, "StoneTerrace", M.ArenaRadius + 1 + A.TerraceWidth / 2, A.TerraceWidth, 1.2,
		M.TopY - 0.6, A.TerraceSegments, E.Palette.Limestone, true, Enum.Material.Limestone)
	ring(arena, "TerraceStep", M.ArenaRadius + 1 + A.TerraceWidth + A.OuterTerraceWidth / 2, A.OuterTerraceWidth, 0.6,
		M.TopY - 0.9, A.TerraceSegments, sand, true, Enum.Material.Limestone)
	for i = 1, M.BaseCount do
		local angle = (i - 1) * math.pi * 2 / M.BaseCount
		local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local gateCF = CFrame.new(radial * (M.ArenaRadius + A.GateRadiusOffset) + Vector3.new(0, M.TopY, 0))
			* CFrame.Angles(0, -angle - math.pi / 2, 0)
		for _, side in {-1, 1} do
			local cf = gateCF * CFrame.new(side * A.GateSideOffset, 0, 0)
			part(arena, "GateFoot", Vector3.new(A.GateFootWidth, 1, A.GateFootWidth), cf * CFrame.new(0, 0.5, 0), sand, Enum.Material.Limestone)
			part(arena, "GatePillar", Vector3.new(A.GateWidth, A.GateHeight, A.GateWidth),
				cf * CFrame.new(0, A.GateHeight / 2, 0), E.Palette.Limestone, Enum.Material.Limestone)
			part(arena, "GateCrown", Vector3.new(A.GateWidth + 0.7, 0.6, A.GateWidth + 0.7),
				cf * CFrame.new(0, A.GateHeight - 0.3, 0), teal, Enum.Material.Limestone)
			decoration(part(arena, "GateGoldTrim", Vector3.new(A.GateWidth + 0.8, A.CapThickness, A.GateWidth + 0.8),
				cf * CFrame.new(0, A.GateHeight + A.CapThickness / 2, 0), gold, Enum.Material.Metal))
			decoration(part(arena, "GateMintPanel", Vector3.new(A.GateWidth * 0.48, A.GateHeight * 0.45, 0.08),
				cf * CFrame.new(0, A.GateHeight * 0.5, -A.GateWidth / 2 - 0.04), mint))
		end
		for subdivision = 1, 3 do
			local a = angle + subdivision * (math.pi * 2 / M.BaseCount) / 4
			local cf = CFrame.new(math.cos(a) * (M.ArenaRadius + A.ButtressWidth / 2 + 0.5), M.TopY, math.sin(a) * (M.ArenaRadius + A.ButtressWidth / 2 + 0.5))
				* CFrame.Angles(0, -a, 0)
			part(arena, "StoneButtress", Vector3.new(A.ButtressWidth, A.ButtressHeight, 3),
				cf * CFrame.new(0, A.ButtressHeight / 2 - 0.5, 0), sand, Enum.Material.Limestone)
			part(arena, "ButtressCap", Vector3.new(A.ButtressWidth + 0.5, 0.4, 3.5),
				cf * CFrame.new(0, A.ButtressHeight - 0.3, 0), E.Palette.Limestone, Enum.Material.Limestone)
		end
	end
end

function MapBuilder.Build()
	local existing = workspace:FindFirstChild("ColossusMap")
	if existing and existing:GetAttribute("EnvironmentRevision") == E.Revision then lighting(); return existing end
	if existing then existing:Destroy() end
	local map = Instance.new("Model")
	map.Name = "ColossusMap"
	map:SetAttribute("EnvironmentRevision", E.Revision)
	local arena = Instance.new("Model")
	arena.Name, arena.Parent = "Arena", map
	disc(arena, "Floor", M.ArenaRadius, M.FloorThickness,
		Vector3.new(0, M.TopY - M.FloorThickness / 2, 0), mint)
	disc(arena, "Underside", M.ArenaRadius, M.FloorThickness * 2,
		Vector3.new(0, M.TopY - M.FloorThickness * 1.5, 0), sand).Material = Enum.Material.Limestone
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
		M.TopY + M.RimHeight / 2, M.RimSegments, sand, true, Enum.Material.Limestone)
	ring(arena, "RimCap", M.ArenaRadius - M.RimWidth / 2, M.RimWidth, E.Architecture.CapThickness,
		M.TopY + M.RimHeight + E.Architecture.CapThickness / 2, M.RimSegments, gold, true, Enum.Material.Metal)
	courtyardArchitecture(arena)
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
		disc(base, "Foundation", M.BasePlatformRadius, E.Architecture.FoundationDepth,
			center - Vector3.new(0, M.FloorThickness + E.Architecture.FoundationDepth / 2, 0), E.Palette.Earth).Material = Enum.Material.Limestone
		local bridgeCenter = radial * (M.ArenaRadius + M.BridgeLength / 2 - 1)
		local bridgeCF = CFrame.new(bridgeCenter + Vector3.new(0, M.TopY - M.BridgeThickness / 2, 0)) * CFrame.Angles(0, -angle - math.pi / 2, 0)
		part(base, "Bridge", Vector3.new(M.BridgeWidth, M.BridgeThickness, M.BridgeLength),
			bridgeCF, E.Palette.Limestone, Enum.Material.Limestone)
		for _, side in {-1, 1} do
			decoration(part(base, "CausewayInlay", Vector3.new(E.Causeway.InlayWidth, M.PatternLayerThickness, M.BridgeLength),
				bridgeCF * CFrame.new(side * (M.BridgeWidth / 2 - 1.5), M.BridgeThickness / 2 + M.PatternLayerStep, 0), color))
			decoration(part(base, "CausewayBorder", Vector3.new(E.Causeway.EdgeWidth, M.PatternLayerThickness, M.BridgeLength),
				bridgeCF * CFrame.new(side * (M.BridgeWidth / 2 - E.Causeway.EdgeWidth / 2), M.BridgeThickness / 2 + M.PatternLayerStep, 0), sand))
		end
		for distance = E.Causeway.JointSpacing, M.BridgeLength - 1, E.Causeway.JointSpacing do
			decoration(part(base, "PavingJoint", Vector3.new(M.BridgeWidth - 4, M.PatternLayerThickness, 0.1),
				bridgeCF * CFrame.new(0, M.BridgeThickness / 2 + M.PatternLayerStep, distance - M.BridgeLength / 2), sand))
		end
		local spawn = Instance.new("SpawnLocation")
		spawn.Name, spawn.Size = "Spawn", M.SpawnSize
		spawn.CFrame = CFrame.lookAt(center + Vector3.new(0, M.SpawnSize.Y / 2, 0), Vector3.new(0, M.TopY + M.SpawnSize.Y / 2, 0))
		spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
		spawn.Color, spawn.Material = color, Enum.Material.SmoothPlastic
		spawn.Parent = base
		local kiosk = part(base, "UpgradeKiosk", M.KioskSize,
			frame * CFrame.new(M.KioskOffset + Vector3.new(0, M.KioskSize.Y / 2, 0)), teal)
		part(base, "KioskPlinth", Vector3.new(M.KioskSize.X + 1.5, 0.6, M.KioskSize.Z + 1.5),
			kiosk.CFrame * CFrame.new(0, -M.KioskSize.Y / 2 + 0.3, 0), sand, Enum.Material.Limestone)
		part(base, "KioskCounter", Vector3.new(M.KioskSize.X + 1, 0.5, M.KioskSize.Z + 1),
			kiosk.CFrame * CFrame.new(0, 0.5, 0), E.Palette.Limestone, Enum.Material.Limestone)
		part(base, "KioskAwning", Vector3.new(M.KioskSize.X + 2, 1, M.KioskSize.Z + 2),
			kiosk.CFrame * CFrame.new(0, M.KioskSize.Y / 2 + 2.5, 0), teal)
		for _, side in {-1, 1} do
			part(base, "KioskPillar", Vector3.new(0.5, M.KioskSize.Y + 2, 0.5),
				kiosk.CFrame * CFrame.new(side * (M.KioskSize.X / 2 + 0.3), 1, 0), sand, Enum.Material.Limestone)
		end
		decoration(part(base, "KioskFascia", Vector3.new(M.KioskSize.X + 2.1, 0.3, M.KioskSize.Z + 2.1),
			kiosk.CFrame * CFrame.new(0, M.KioskSize.Y / 2 + 2.1, 0), color))
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name, prompt.ActionText, prompt.ObjectText = "ShopPrompt", "Open Upgrades", "Colossus Forge"
		prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0, 12, false
		prompt.Parent = kiosk
		label(kiosk, "Upgrades")
		local bannerCF = frame * CFrame.new(-17, M.BannerHeight / 2, 8)
		part(base, "BannerPole", Vector3.new(0.7, M.BannerHeight, 0.7), bannerCF, gold, Enum.Material.Metal)
		local banner = part(base, "Banner", Vector3.new(9, 6, 0.35), bannerCF * CFrame.new(4.5, M.BannerHeight / 2 - 4, 0), color)
		banner.CanCollide = false
		label(banner, "Base " .. i)
		tree(base, frame:PointToWorldSpace(Vector3.new(-20, 0, -12)), 0.85)
		tree(base, frame:PointToWorldSpace(Vector3.new(19, 0, -17)), 0.65)
		lantern(base, frame * CFrame.new(-11, 0, -21))
		lantern(base, frame * CFrame.new(11, 0, -21))
	end
	local scenery = Instance.new("Folder")
	scenery.Name, scenery.Parent = "Scenery", map
	valley(scenery)
	lighting()
	map.Parent = workspace
	return map
end

return MapBuilder

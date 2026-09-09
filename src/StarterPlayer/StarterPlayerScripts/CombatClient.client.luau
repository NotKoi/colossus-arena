local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local swingRemote = remotes:WaitForChild("Swing")
local damageRemote = remotes:WaitForChild("Damage")
local characterConnections = {}

local function clearConnections()
	for _, connection in characterConnections do connection:Disconnect() end
	table.clear(characterConnections)
end

local function bindTool(tool)
	if not tool:IsA("Tool") or not tool:GetAttribute("SwordId") then return end
	table.insert(characterConnections, tool.Activated:Connect(function()
		swingRemote:FireServer()
	end))
end

local function bindCharacter(character)
	clearConnections()
	for _, child in character:GetChildren() do bindTool(child) end
	table.insert(characterConnections, character.ChildAdded:Connect(bindTool))
end

if player.Character then bindCharacter(player.Character) end
player.CharacterAdded:Connect(bindCharacter)

damageRemote.OnClientEvent:Connect(function(position, dealt, userId)
	if userId ~= player.UserId or typeof(position) ~= "Vector3" or type(dealt) ~= "number" then return end
	local anchor = Instance.new("Part")
	anchor.Name = "DamageNumberAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position = position + Vector3.new(0, 3, 0)
	anchor.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromScale(4, 1.5)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
	billboard.Adornee = anchor
	billboard.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = tostring(math.floor(dealt + 0.5))
	label.TextColor3 = Color3.fromRGB(255, 235, 103)
	label.TextStrokeColor3 = Color3.fromRGB(72, 25, 15)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Parent = billboard

	TweenService:Create(anchor, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = anchor.Position + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.7), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.75, function() anchor:Destroy() end)
end)

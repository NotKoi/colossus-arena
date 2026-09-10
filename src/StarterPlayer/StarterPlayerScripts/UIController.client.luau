local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local Modules = RS:WaitForChild("Modules")
local Names = require(Modules:WaitForChild("RemoteNames"))
local Swords = require(Modules:WaitForChild("SwordDefs"))
local Armor = require(Modules:WaitForChild("ArmorDefs"))
local Config = require(Modules:WaitForChild("Config"))
local Bosses = require(Modules:WaitForChild("BossDefs"))
local UI = require(Modules:WaitForChild("UIDefs"))
local UIEffects = require(Modules:WaitForChild("UIEffects"))

local player = Players.LocalPlayer
local remotesFolder = RS:WaitForChild("Remotes")
local Remotes = {}
for key, name in Names do Remotes[key] = remotesFolder:WaitForChild(name) end

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)

local COLORS = {
	ink = Color3.fromRGB(44, 37, 32), cream = Color3.fromRGB(246, 242, 225),
	surface = Color3.fromRGB(56, 48, 45), dark = Color3.fromRGB(39, 35, 34),
	gold = Color3.fromRGB(255, 190, 63), teal = Color3.fromRGB(54, 205, 190),
	red = Color3.fromRGB(240, 83, 69), muted = Color3.fromRGB(205, 190, 170),
}

local function ui(className, props, parent)
	local object = Instance.new(className)
	for key, value in props do object[key] = value end
	object.Parent = parent
	return object
end

local function round(parent, radius)
	ui("UICorner", { CornerRadius = UDim.new(radius or UI.Corner, 0) }, parent)
end

local function stroke(parent, color, thickness)
	return ui("UIStroke", { Color = color or COLORS.gold, Thickness = thickness or 1, Transparency = 0.65 }, parent)
end

local function text(parent, value, size, position, color, align)
	local label = ui("TextLabel", {
		BackgroundTransparency = 1, Text = value, Size = size, Position = position or UDim2.fromScale(0, 0),
		TextColor3 = color or COLORS.cream, Font = UI.Font, TextScaled = true,
		TextXAlignment = align or Enum.TextXAlignment.Center, TextWrapped = true,
	}, parent)
	ui("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = UI.TextMax }, label)
	return label
end

local function button(parent, label, size, position, color)
	local b = ui("TextButton", {
		Text = label, Size = size, Position = position, BackgroundColor3 = color or COLORS.teal,
		TextColor3 = COLORS.ink, Font = UI.HeadingFont, TextScaled = true, AutoButtonColor = false,
	}, parent)
	round(b, UI.ButtonCorner); stroke(b, COLORS.cream, 1)
	ui("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = UI.ButtonTextMax }, b)
	UIEffects.Bind(b)
	return b
end

local function panel(parent, name, size, position)
	local shadow = ui("Frame", { Name = name .. "Shadow", Size = size, Position = position + UDim2.fromScale(0.003, 0.005), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.78, BorderSizePixel = 0 }, parent)
	round(shadow)
	local frame = ui("Frame", { Name = name, Size = size, Position = position, BackgroundColor3 = COLORS.surface, BorderSizePixel = 0 }, parent)
	round(frame); stroke(frame)
	return frame, shadow
end

local gui = ui("ScreenGui", { Name = "ColossusHUD", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
local top, topShadow = panel(gui, "BossPanel", UDim2.fromScale(0.44, 0.12), UDim2.fromScale(0.28, 0.025))
local bossName = text(top, "COLOSSUS APPROACHES", UDim2.fromScale(0.62, 0.24), UDim2.fromScale(0.03, 0.05), COLORS.cream, Enum.TextXAlignment.Left)
local timer = text(top, "2:00", UDim2.fromScale(0.3, 0.28), UDim2.fromScale(0.67, 0.04), COLORS.gold)
local nextBoss = text(top, "NEXT: EMBERHORN", UDim2.fromScale(0.94, 0.18), UDim2.fromScale(0.03, 0.29), COLORS.muted, Enum.TextXAlignment.Left)
local hpTrack = ui("Frame", { Size = UDim2.fromScale(0.94, 0.29), Position = UDim2.fromScale(0.03, 0.54), BackgroundColor3 = COLORS.muted, BorderSizePixel = 0, ClipsDescendants = true }, top)
round(hpTrack, 0.22)
local hpFill = ui("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = COLORS.red, BorderSizePixel = 0 }, hpTrack); round(hpFill, 0.22)
local hpText = text(hpTrack, "Waiting for boss", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), COLORS.ink)
local shielded = text(top, "SHIELDED", UDim2.fromScale(0.34, 0.18), UDim2.fromScale(0.63, 0.3), COLORS.teal); shielded.Visible = false

local stats, statsShadow = panel(gui, "Stats", UDim2.fromScale(0.21, 0.105), UDim2.fromScale(0.025, 0.035))
local coinsLabel = text(stats, "◆ 0", UDim2.fromScale(0.9, 0.34), UDim2.fromScale(0.05, 0.04), COLORS.gold, Enum.TextXAlignment.Left)
local strengthLabel = text(stats, "STRENGTH —", UDim2.fromScale(0.9, 0.28), UDim2.fromScale(0.05, 0.39), COLORS.cream, Enum.TextXAlignment.Left)
local strengthTrack = ui("Frame", { Size = UDim2.fromScale(0.9, 0.16), Position = UDim2.fromScale(0.05, 0.75), BackgroundColor3 = COLORS.dark, BorderSizePixel = 0, ClipsDescendants = true }, stats)
round(strengthTrack, 0.25)
local strengthFill = ui("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = COLORS.teal, BorderSizePixel = 0 }, strengthTrack); round(strengthFill, 0.25)
local statsStroke = stats:FindFirstChildOfClass("UIStroke")

local inventoryButton = button(gui, "Inventory  [B]", UDim2.fromScale(0.14, 0.065), UDim2.fromScale(0.82, 0.78), COLORS.gold)
inventoryButton.Name = "InventoryButton"
local teleportButton = button(gui, "To arena  [T]", UDim2.fromScale(0.14, 0.065), UDim2.fromScale(0.82, 0.865), COLORS.teal)

teleportButton.Name = "TeleportButton"
local modalShade = ui("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.48, Visible = false, AutoButtonColor = false }, gui)
local window, windowShadow = panel(gui, "Panel", UDim2.fromScale(0.50, 0.68), UDim2.fromScale(0.25, 0.17)); window.Visible = false; windowShadow.Visible = false
local panelTitle = text(window, "ADVENTURER'S PACK", UDim2.fromScale(0.76, 0.07), UDim2.fromScale(0.05, 0.025), COLORS.gold, Enum.TextXAlignment.Left)
local persistenceText = text(window, "", UDim2.fromScale(0.75, 0.03), UDim2.fromScale(0.05, 0.11), COLORS.muted, Enum.TextXAlignment.Left)
local closeButton = button(window, "×", UDim2.fromScale(0.09, 0.09), UDim2.fromScale(0.86, 0.025), COLORS.red)
closeButton.Name = "CloseButton"
local musicButton = button(window, "Music: On", UDim2.fromScale(.42,.055), UDim2.fromScale(.05,.92), COLORS.gold)
musicButton.Name = "MusicButton"
local motionButton = button(window, "Motion: On", UDim2.fromScale(.42,.055), UDim2.fromScale(.53,.92), COLORS.teal)
motionButton.Name = "MotionButton"
musicButton.Activated:Connect(function()
 player:SetAttribute("MusicMuted", player:GetAttribute("MusicMuted") ~= true)
end)
motionButton.Activated:Connect(function()
 player:SetAttribute("ReducedMotion", player:GetAttribute("ReducedMotion") ~= true)
end)
local function updatePreferences()
 musicButton.Text = player:GetAttribute("MusicMuted") and "Music: Off" or "Music: On"
 motionButton.Text = player:GetAttribute("ReducedMotion") and "Motion: Reduced" or "Motion: On"
end
player:GetAttributeChangedSignal("MusicMuted"):Connect(updatePreferences)
player:GetAttributeChangedSignal("ReducedMotion"):Connect(updatePreferences)
updatePreferences()
local scroll = ui("ScrollingFrame", { Size = UDim2.fromScale(0.9, 0.73), Position = UDim2.fromScale(0.05, 0.16), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = COLORS.gold, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromScale(0, 0) }, window)
local list = ui("UIListLayout", { Padding = UDim.new(0.018, 0), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
local padding = ui("UIPadding", { PaddingTop = UDim.new(0.01, 0), PaddingBottom = UDim.new(0.02, 0), PaddingLeft = UDim.new(0.01, 0), PaddingRight = UDim.new(0.01, 0) }, scroll)

local toast = text(gui, "", UDim2.fromScale(0.46, 0.07), UDim2.fromScale(0.27, 0.2), COLORS.cream); toast.BackgroundColor3 = COLORS.dark; toast.BackgroundTransparency = 0.08; toast.Visible = false; round(toast); stroke(toast)
local winner = text(gui, "", UDim2.fromScale(0.56, 0.11), UDim2.fromScale(0.22, 0.31), COLORS.gold); winner.BackgroundColor3 = COLORS.dark; winner.BackgroundTransparency = 0.04; winner.Visible = false; round(winner); stroke(winner, COLORS.gold, 3)
local results, resultsShadow = panel(gui, "Results", UDim2.fromScale(0.54, 0.53), UDim2.fromScale(0.23, 0.22)); results.Visible = false; resultsShadow.Visible = false
modalShade.ZIndex=9;windowShadow.ZIndex=10;window.ZIndex=11;resultsShadow.ZIndex=19;results.ZIndex=20;toast.ZIndex=30;winner.ZIndex=40
local rareSound = ui("Sound", { SoundId = Config.Audio.Rare, Volume = 0.55 }, gui)

local profile
local panelMode = "inventory"
local toastToken = 0
local resultsToken = 0
local coinValue = Instance.new("NumberValue")
coinValue.Value = 0
coinValue.Changed:Connect(function(value) coinsLabel.Text = "◆ " .. tostring(math.floor(value + 0.5)) end)

local function clearRows(container)
	for _, child in container:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
end

local function row(titleValue, detail, actionText, actionColor)
	local frame = ui("Frame", { Size = UDim2.fromScale(0.98, 0.145), BackgroundColor3 = COLORS.dark, BackgroundTransparency = 0.04, BorderSizePixel = 0 }, scroll)
	round(frame, .065)
	text(frame, titleValue, UDim2.fromScale(0.62, 0.39), UDim2.fromScale(0.04, 0.09), COLORS.cream, Enum.TextXAlignment.Left)
	text(frame, detail, UDim2.fromScale(0.62, 0.32), UDim2.fromScale(0.04, 0.55), COLORS.muted, Enum.TextXAlignment.Left)
	return frame, button(frame, actionText, UDim2.fromScale(0.27, 0.56), UDim2.fromScale(0.69, 0.22), actionColor)
end

local function strengthRating(p)
	local sword = Swords[p.equipped] or Swords.WoodenTrainer
	local dps = sword.Damage / sword.Cooldown
	local health, movement = 0, 0
	for id, owned in p.armor or {} do
		local def = owned and Armor[id]
		if def then health += def.MaxHealth or 0; movement += math.floor(((def.SpeedMultiplier or 1) - 1) * 100 + 0.5) end
	end
	local total = math.floor(dps + health + movement + 0.5)
	return total
end

local function updateStrength(p)
	local rating = strengthRating(p)
	local lower, target = 0, Config.Shop.StrengthTiers[#Config.Shop.StrengthTiers]
	for _, tier in Config.Shop.StrengthTiers do
		if rating < tier then target = tier; break end
		lower = tier
	end
	local progress = target == lower and 1 or math.clamp((rating - lower) / (target - lower), 0, 1)
	strengthLabel.Text = string.format("Strength %d  ·  Next tier %d", rating, target)
	strengthFill.Size = UDim2.fromScale(progress, 1)
end

local function rebuildInventory()
	clearRows(scroll)
	if not profile then
		row("LOADING YOUR PACK…", "Requesting your profile", "…", COLORS.muted)
		return
	end
	for id, def in Swords do
		if profile.owned and profile.owned[id] then
			local equipped = profile.equipped == id
			local frame, action = row(def.Name, string.format("%d damage  •  %.2fs swing  •  %.0f DPS", def.Damage, def.Cooldown, def.Damage / def.Cooldown), equipped and "Equipped" or "Equip", equipped and COLORS.gold or COLORS.teal)
			action.AutoButtonColor = false; action.Active = not equipped
			if not equipped then action.Activated:Connect(function() Remotes.Equip:FireServer(id) end) end
		end
	end
	for id, def in Armor do
		if profile.owned and profile.owned[id] then
			local equipped = profile.armor and profile.armor[id]
			local stat = def.MaxHealth and ("+" .. def.MaxHealth .. " max health") or ("+" .. math.floor((def.SpeedMultiplier - 1) * 100 + 0.5) .. "% movement")
			local frame, action = row(def.Name, stat, equipped and "Unequip" or "Equip", equipped and COLORS.gold or COLORS.teal)
			action.Activated:Connect(function() Remotes.Equip:FireServer(id) end)
		end
	end
end

local SHOP_IDS = { "BronzeShortblade", "KnightLongsword", "SunfangGreatsword", "WoodenTrainer" }
local function rebuildShop()
	clearRows(scroll)
	for _, id in SHOP_IDS do
		local def = Swords[id]
		local owned = profile and profile.owned and profile.owned[id]
		local frame, action = row(def.Name, string.format("%d damage  •  %.0f DPS  •  ◆ %d", def.Damage, def.Damage / def.Cooldown, def.Cost or 0), owned and "Owned" or "Buy", owned and COLORS.gold or COLORS.teal)
		action.AutoButtonColor = false; action.Active = not owned
		if not owned then action.Activated:Connect(function() Remotes.Buy:FireServer(id) end) end
	end
end

local function showPanel(mode)
	panelMode = mode; modalShade.Visible = true; window.Visible = true; windowShadow.Visible = true
	panelTitle.Text = mode == "shop" and "Sunforge Armory" or "Inventory"
	panelTitle.Font = UI.HeadingFont
	UIEffects.Reveal(window)
	TweenService:Create(modalShade, TweenInfo.new(UI.PanelTransition), {BackgroundTransparency = .48}):Play()
	persistenceText.Visible = mode == "inventory"
	persistenceText.Text = tostring(player:GetAttribute("Persistence") or "LOADING PROFILE"):upper()
	if mode == "shop" then rebuildShop() else rebuildInventory() end
end
local function hidePanel() modalShade.Visible = false; window.Visible = false; windowShadow.Visible = false end
closeButton.Activated:Connect(hidePanel); modalShade.Activated:Connect(hidePanel)
inventoryButton.Activated:Connect(function() showPanel("inventory") end)
teleportButton.Activated:Connect(function() Remotes.Teleport:FireServer() end)
player:GetAttributeChangedSignal("Persistence"):Connect(function()
	if panelMode == "inventory" then persistenceText.Text = tostring(player:GetAttribute("Persistence") or "LOADING PROFILE"):upper() end
end)

local function showToast(message, duration)
	toastToken += 1; local token = toastToken
	toast.Text = tostring(message); toast.Visible = true; toast.TextTransparency = 0; toast.BackgroundTransparency = 0.08
	task.delay(duration or 3, function()
		if token ~= toastToken then return end
		local tween = TweenService:Create(toast, TweenInfo.new(0.25), { TextTransparency = 1, BackgroundTransparency = 1 })
		tween:Play(); tween.Completed:Wait(); if token == toastToken then toast.Visible = false end
	end)
end

local function escapeRich(value)
	return tostring(value):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
end
local function chat(message)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general then general:DisplaySystemMessage(message) end
	end)
end

Remotes.Profile.OnClientEvent:Connect(function(snapshot)
	profile = snapshot
	local target = math.max(0, tonumber(snapshot.coins) or 0)
	TweenService:Create(coinValue, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Value = target }):Play()
	updateStrength(snapshot)
	if panelMode == "shop" then rebuildShop() else rebuildInventory() end
end)
Remotes.OpenShop.OnClientEvent:Connect(function() showPanel("shop") end)
Remotes.Notice.OnClientEvent:Connect(function(message) showToast(message, 3) end)
Remotes.RareDrop.OnClientEvent:Connect(function(name, id, userId)
	local def = Swords[id] or Armor[id]
	local itemName = def and def.Name or id
	local message = string.format("✦ %s found the rare %s!", escapeRich(name), escapeRich(itemName))
	showToast(message, 4); chat("<font color=\"#FFBE3F\"><b>" .. message .. "</b></font>"); rareSound:Play()
	if userId == player.UserId then
		winner.Text = "RARE DROP!\n" .. tostring(itemName); winner.Visible = true
		task.delay(4, function() winner.Visible = false end)
	end
end)
Remotes.Results.OnClientEvent:Connect(function(rows, killed)
	resultsToken += 1; local token = resultsToken
	clearRows(results)
	text(results, killed and "Colossus defeated" or "Battle ended", UDim2.fromScale(0.9, 0.11), UDim2.fromScale(0.05, 0.03), killed and COLORS.gold or COLORS.cream)
	local holder = ui("Frame", { Size = UDim2.fromScale(0.9, 0.76), Position = UDim2.fromScale(0.05, 0.17), BackgroundTransparency = 1 }, results)
	ui("UIListLayout", { Padding = UDim.new(0.012, 0) }, holder)
	for index, result in rows do
		if index > 6 then break end
		local own = result.userId == player.UserId
		local line = text(holder, string.format("%s   %d DMG   %.0f%%   ◆ %d", result.name, result.damage, result.share * 100, result.coins), UDim2.fromScale(1, 0.1), UDim2.fromScale(0, 0), own and COLORS.gold or COLORS.cream, Enum.TextXAlignment.Left)
		line.BackgroundColor3 = own and Color3.fromRGB(76, 77, 55) or COLORS.dark; line.BackgroundTransparency = 0.08; round(line, 0.12)
	end
	if #rows > 6 then text(holder, "+ " .. tostring(#rows - 6) .. " MORE CONTRIBUTORS", UDim2.fromScale(1, 0.08), UDim2.fromScale(0, 0), COLORS.muted) end
	results.Visible = true; resultsShadow.Visible = true
	task.delay(6, function() if token == resultsToken then results.Visible = false; resultsShadow.Visible = false end end)
end)

local bossState
task.spawn(function() bossState = RS:WaitForChild("BossState") end)

local function adapt()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local portrait = viewport.Y > viewport.X
	local topSize = portrait and UDim2.fromScale(0.9, 0.13) or UDim2.fromScale(0.44, 0.12)
	local topPos = portrait and UDim2.fromScale(0.05, 0.02) or UDim2.fromScale(0.28, 0.025)
	top.Size = topSize; top.Position = topPos; topShadow.Size = topSize; topShadow.Position = topPos + UDim2.fromScale(0.003, 0.005)
	stats.Size = portrait and UDim2.fromScale(0.9, 0.08) or UDim2.fromScale(0.21, 0.105)
	stats.Position = portrait and UDim2.fromScale(0.05, 0.165) or UDim2.fromScale(0.025, 0.035)
	statsShadow.Size = stats.Size; statsShadow.Position = stats.Position + UDim2.fromScale(0.003, 0.005)
	window.Size = portrait and UDim2.fromScale(0.9, 0.62) or UDim2.fromScale(0.50, 0.68)
	window.Position = portrait and UDim2.fromScale(0.05, 0.18) or UDim2.fromScale(0.25, 0.17)
	windowShadow.Size = window.Size; windowShadow.Position = window.Position + UDim2.fromScale(0.003, 0.005)
	inventoryButton.Size = portrait and UDim2.fromScale(0.29, 0.06) or UDim2.fromScale(0.14, 0.065)
	teleportButton.Size = inventoryButton.Size
	inventoryButton.Position = portrait and UDim2.fromScale(0.67, 0.64) or UDim2.fromScale(0.82, 0.78)
	teleportButton.Position = portrait and UDim2.fromScale(0.67, 0.72) or UDim2.fromScale(0.82, 0.865)
	inventoryButton.Text = UserInputService.TouchEnabled and "Inventory" or "Inventory  [B]"
	local resultSize = portrait and UDim2.fromScale(0.9, 0.52) or UDim2.fromScale(0.54, 0.53)
	local resultPosition = portrait and UDim2.fromScale(0.05, 0.25) or UDim2.fromScale(0.23, 0.22)
	results.Size = resultSize; results.Position = resultPosition; resultsShadow.Size = resultSize; resultsShadow.Position = resultPosition + UDim2.fromScale(0.003, 0.005)
	toast.Size = portrait and UDim2.fromScale(0.9, 0.07) or UDim2.fromScale(0.46, 0.07)
	toast.Position = portrait and UDim2.fromScale(0.05, 0.26) or UDim2.fromScale(0.27, 0.2)
	winner.Size = portrait and UDim2.fromScale(0.9, 0.11) or UDim2.fromScale(0.56, 0.11)
	winner.Position = portrait and UDim2.fromScale(0.05, 0.35) or UDim2.fromScale(0.22, 0.31)
end
adapt()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt) end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(adapt)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B then if window.Visible then hidePanel() else showPanel("inventory") end end
	if input.KeyCode == Enum.KeyCode.T and teleportButton.Active then Remotes.Teleport:FireServer() end
end)

task.spawn(function()
	while not profile do Remotes.Sync:FireServer(); task.wait(2) end
end)

task.spawn(function()
	while gui.Parent do
		if bossState then
			local now = workspace:GetServerTimeNow()
			local deadline = bossState:GetAttribute("Deadline") or now
			local remaining = math.max(0, deadline - now)
			timer.Text = string.format("%d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))
			local id = bossState:GetAttribute("Boss")
			local def = id and Bosses[id]
			local hp, maxHP = bossState:GetAttribute("HP") or 0, bossState:GetAttribute("MaxHP") or 1
			local ratio = math.clamp(hp / math.max(1, maxHP), 0, 1)
			local active = bossState:GetAttribute("Active") == true
			local upcoming = tostring(bossState:GetAttribute("NextBoss") or "—")
			bossName.Text = active and (def and def.Name or "COLOSSUS") or ("Next boss: " .. upcoming)
			nextBoss.Text = active and ("Next: " .. upcoming) or "Prepare for the next battle"
			hpFill.Size = UDim2.fromScale(ratio, 1); hpFill.BackgroundColor3 = def and def.Color or COLORS.red
			hpText.Text = active and string.format("%s  •  %.0f%%", bossState:GetAttribute("Shielded") and "SHIELDED" or (tostring(math.floor(hp)) .. " / " .. tostring(math.floor(maxHP))), ratio * 100) or (hp <= 0 and "Defeated" or "Time expired")
			shielded.Visible = active and bossState:GetAttribute("Shielded") == true
			local locked = not active and remaining <= Config.Cycle.TeleportLock
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local insideArena = root and Vector3.new(root.Position.X, 0, root.Position.Z).Magnitude <= Config.Map.ArenaRadius
			local destination = insideArena and "To base" or "To arena"
			local shortcut = UserInputService.TouchEnabled and "" or "  [T]"
			teleportButton.Text = locked and "Locked" or (destination .. shortcut)
			teleportButton.AutoButtonColor = false; teleportButton.Active = not locked
			teleportButton.BackgroundColor3 = locked and COLORS.muted or COLORS.teal
		end
		local accent = player:GetAttribute("BaseColor")
		if typeof(accent) == "Color3" then statsStroke.Color = accent end
		task.wait(0.1)
	end
end)

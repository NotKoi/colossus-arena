local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Modules.Config)
local BaseAssignment = { Slots = {} }
function BaseAssignment.Assign(player)
	if player:GetAttribute("BaseIndex") then return player:GetAttribute("BaseIndex") end
	for i = 1, Config.Map.BaseCount do
		if not BaseAssignment.Slots[i] then
			BaseAssignment.Slots[i] = player
			player:SetAttribute("BaseIndex", i)
			player:SetAttribute("BaseColor", Config.BaseColors[i])
			local base = workspace.ColossusMap.Bases["Base" .. i]
			base:SetAttribute("OwnerId", player.UserId)
			player.RespawnLocation = base.Spawn
			return i
		end
	end
	player:Kick("All six bases are occupied. Please join another server.")
end
function BaseAssignment.Release(player)
	local i = player:GetAttribute("BaseIndex")
	if i and BaseAssignment.Slots[i] == player then
		BaseAssignment.Slots[i] = nil
		workspace.ColossusMap.Bases["Base" .. i]:SetAttribute("OwnerId", nil)
	end
end
function BaseAssignment.ToBase(player)
	local i = player:GetAttribute("BaseIndex")
	if i and player.Character then
		local cf = workspace.ColossusMap.Bases["Base" .. i].Spawn.CFrame
		player.Character:PivotTo(cf + Vector3.new(0, 4, 0))
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if root then root.AssemblyLinearVelocity = Vector3.zero end
	end
end
function BaseAssignment.Start()
	local function joined(player)
		if not BaseAssignment.Assign(player) then return end
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart")
			BaseAssignment.ToBase(player)
		end)
		if player.Character then BaseAssignment.ToBase(player) end
	end
	Players.PlayerAdded:Connect(joined)
	Players.PlayerRemoving:Connect(BaseAssignment.Release)
	for _, player in Players:GetPlayers() do joined(player) end
end
return BaseAssignment

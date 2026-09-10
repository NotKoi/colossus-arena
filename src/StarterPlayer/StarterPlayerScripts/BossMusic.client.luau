-- Two reusable, local voices: no per-round Sound allocation or heartbeat polling.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local AudioDefs = require(RS:WaitForChild("Modules"):WaitForChild("AudioDefs"))
local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "ColossusMusic"
folder:SetAttribute("Loaded", false)
folder:SetAttribute("ActiveTheme", "")
folder.Parent = SoundService

local voices = {}
local preload = {}
local function updateLoaded()
	local allLoaded = true
	for _, voice in pairs(voices) do
		voice.sound:SetAttribute("Loaded", voice.sound.IsLoaded)
		allLoaded = allLoaded and voice.sound.IsLoaded
	end
	folder:SetAttribute("Loaded", allLoaded)
end

for id, theme in pairs(AudioDefs.Themes) do
	local sound = Instance.new("Sound")
	sound.Name = theme.SoundName
	sound.SoundId = theme.SoundId
	sound.Volume = 0
	sound.Looped = true
	sound:SetAttribute("Loaded", false)
	sound.Parent = folder
	voices[id] = { sound = sound, generation = 0, tween = nil }
	table.insert(preload, sound)
	sound.Loaded:Connect(updateLoaded)
end

-- Preloading must never hold up state subscriptions or other client scripts.
task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync(preload)
	end)
	updateLoaded()
end)

local function fade(voice, audible)
	voice.generation += 1
	local generation = voice.generation
	if voice.tween then
		voice.tween:Cancel()
		voice.tween = nil
	end
	if audible and not voice.sound.IsPlaying then
		voice.sound:Play()
	end
	local tween = TweenService:Create(voice.sound,
		TweenInfo.new(AudioDefs.FadeSeconds, Enum.EasingStyle.Linear),
		{ Volume = audible and AudioDefs.Volume or 0 })
	voice.tween = tween
	tween.Completed:Once(function(playbackState)
		-- Cancelled fade-outs must not stop a voice selected by a newer round.
		if voice.generation ~= generation or playbackState ~= Enum.PlaybackState.Completed then
			return
		end
		voice.tween = nil
		if not audible then
			voice.sound:Stop()
		end
	end)
	tween:Play()
end

local state = RS:WaitForChild("BossState")
local selected = nil
local function refresh()
	local id = state:GetAttribute("Boss")
	local desired = state:GetAttribute("Active") == true
		and player:GetAttribute("MusicMuted") ~= true and voices[id] and id or ""
	if desired == selected then return end
	selected = desired
	folder:SetAttribute("ActiveTheme", desired)
	for bossId, voice in pairs(voices) do
		fade(voice, bossId == desired)
	end
end
state:GetAttributeChangedSignal("Boss"):Connect(refresh)
state:GetAttributeChangedSignal("Active"):Connect(refresh)
player:GetAttributeChangedSignal("MusicMuted"):Connect(refresh)
refresh() -- Covers late joiners even if all attributes already replicated.

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local D = require(script.Parent.UIDefs)
local Effects = {}
local sounds = {}
local lastSound = {}
local function reduced() return Players.LocalPlayer:GetAttribute("ReducedMotion") == true end
function Effects.Sound(kind)
 if os.clock() - (lastSound[kind] or 0) < D.SoundInterval then return end
 lastSound[kind] = os.clock()
 local sound = sounds[kind]
 if not sound then
  sound = Instance.new("Sound"); sound.Name = "UI" .. kind
  sound.SoundId = kind == "Hover" and D.HoverSound or D.ClickSound
  sound.Volume = kind == "Hover" and D.HoverVolume or D.ClickVolume
  sound.PlaybackSpeed = kind == "Hover" and D.HoverPitch or D.ClickPitch
  sound.Parent = SoundService; sounds[kind] = sound
 end
 sound:Stop(); sound:Play()
end
function Effects.Bind(button)
 button.AutoButtonColor = false
 button.ClipsDescendants = true
 local scale = Instance.new("UIScale"); scale.Name = "InteractionScale"; scale.Parent = button
 local focus = Instance.new("UIStroke"); focus.Name = "InteractionFocus"
 focus.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; focus.Color = Color3.new(1, 1, 1)
 focus.Thickness = 2; focus.Transparency = 1; focus.Parent = button
 local hovering, selected, pressed = false, false, false
 local scaleTween, focusTween
 local function refresh()
  if scaleTween then scaleTween:Cancel() end
  if focusTween then focusTween:Cancel() end
  local active = button.Active
  local target = active and (pressed and D.PressScale or ((hovering or selected) and D.HoverScale or 1)) or 1
  if reduced() then scale.Scale = 1 else
   scaleTween = TweenService:Create(scale, TweenInfo.new(D.Transition, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = target}); scaleTween:Play()
  end
  focusTween = TweenService:Create(focus, TweenInfo.new(D.Transition), {Transparency = active and (hovering or selected) and .35 or 1}); focusTween:Play()
 end
 button.MouseEnter:Connect(function() hovering = true; if button.Active then Effects.Sound("Hover") end; refresh() end)
 button.MouseLeave:Connect(function() hovering = false; pressed = false; refresh() end)
 button.SelectionGained:Connect(function() selected = true; if button.Active then Effects.Sound("Hover") end; refresh() end)
 button.SelectionLost:Connect(function() selected = false; pressed = false; refresh() end)
 button.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then pressed = true; refresh() end
 end)
 button.InputEnded:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then pressed = false; refresh() end
 end)
 button.Activated:Connect(function()
  if not button.Active then return end
  Effects.Sound("Click")
  if reduced() then return end
  local flash = Instance.new("Frame"); flash.Name = "PressFlash"; flash.Size = UDim2.fromScale(1, 1)
  flash.BackgroundColor3 = Color3.new(1, 1, 1); flash.BackgroundTransparency = .78; flash.BorderSizePixel = 0; flash.Parent = button
  TweenService:Create(flash, TweenInfo.new(D.PanelTransition), {BackgroundTransparency = 1}):Play()
  Debris:AddItem(flash, D.PanelTransition)
 end)
 button:GetPropertyChangedSignal("Active"):Connect(function() pressed = false; refresh() end)
 local connection = Players.LocalPlayer:GetAttributeChangedSignal("ReducedMotion"):Connect(refresh)
 button.Destroying:Connect(function() connection:Disconnect(); if scaleTween then scaleTween:Cancel() end; if focusTween then focusTween:Cancel() end end)
end
function Effects.Reveal(panel)
 local scale = panel:FindFirstChild("RevealScale")
 if not scale then scale = Instance.new("UIScale"); scale.Name = "RevealScale"; scale.Parent = panel end
 scale.Scale = reduced() and 1 or .985
 TweenService:Create(scale, TweenInfo.new(D.PanelTransition, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1}):Play()
end
return Effects

local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Debris=game:GetService("Debris")
local Config=require(RS:WaitForChild("Modules"):WaitForChild("Config"))
local Names=require(RS.Modules.RemoteNames)
local remote=RS:WaitForChild("Remotes"):WaitForChild(Names.Telegraph)
local player=Players.LocalPlayer
local shakeUntil=0;local lastWarning=0
local function sound(id,parent,volume)
 local s=Instance.new("Sound");s.SoundId=id;s.Volume=volume;s.RollOffMaxDistance=160;s.Parent=parent;s:Play();Debris:AddItem(s,4)
end
remote.OnClientEvent:Connect(function(d)
 if d.kind=="Clear" then shakeUntil=0;return end
 if d.kind=="Burst" then
  local anchor=Instance.new("Part");anchor.Name="ImpactSparkles";anchor.Size=Vector3.one;anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.Position=d.position;anchor.Parent=workspace
  local sparks=Instance.new("ParticleEmitter");sparks.Texture="rbxasset://textures/particles/sparkles_main.dds";sparks.Color=ColorSequence.new(d.color or Color3.fromRGB(255,180,65));sparks.Rate=0;sparks.Lifetime=NumberRange.new(.4,Config.Polish.ParticleLifetime);sparks.Speed=NumberRange.new(12,28);sparks.SpreadAngle=Vector2.new(180,180);sparks.LightEmission=.8;sparks.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.4),NumberSequenceKeypoint.new(1,0)});sparks.Parent=anchor;sparks:Emit(Config.Polish.ParticleCount)
  Debris:AddItem(anchor,Config.Polish.ParticleLifetime+1)
  sound(Config.Audio.Impact,anchor,.28)
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if root and (root.Position-d.position).Magnitude<Config.Polish.ShakeRadius then shakeUntil=os.clock()+Config.Polish.ShakeDuration end
 elseif d.kind=="Circle" or d.kind=="Line" or d.kind=="Nova" then
  if os.clock()-lastWarning>Config.Polish.WarningInterval then lastWarning=os.clock();sound(Config.Audio.Warning,game:GetService("SoundService"),.18) end
 end
end)
RunService:BindToRenderStep("ColossusImpactShake",Enum.RenderPriority.Camera.Value+1,function()
 local c=workspace.CurrentCamera
 if c and player:GetAttribute("ReducedMotion") ~= true and c.CameraType~=Enum.CameraType.Scriptable and os.clock()<shakeUntil then
  local fade=(shakeUntil-os.clock())/Config.Polish.ShakeDuration
  c.CFrame*=CFrame.new(math.sin(os.clock()*75)*Config.Polish.ShakeMagnitude*fade,math.cos(os.clock()*67)*Config.Polish.ShakeMagnitude*fade,0)
 end
end)

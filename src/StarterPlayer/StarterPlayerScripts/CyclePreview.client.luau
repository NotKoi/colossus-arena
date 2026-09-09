local RS=game:GetService("ReplicatedStorage")
local state=RS:WaitForChild("BossState")
local gui=Instance.new("ScreenGui");gui.Name="CyclePreview";gui.ResetOnSpawn=false;gui.Parent=game.Players.LocalPlayer:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(0.4,0.08);label.Position=UDim2.fromScale(0.3,0.02);label.BackgroundColor3=Color3.fromRGB(26,67,76);label.TextColor3=Color3.new(1,1,1);label.TextScaled=true;label.Parent=gui
while gui.Parent do
 local seconds=math.max(0,math.ceil((state:GetAttribute("Deadline") or 0)-workspace:GetServerTimeNow()))
 label.Text=string.format("%s  %d:%02d  | NEXT: %s",state:GetAttribute("Boss") or "",math.floor(seconds/60),seconds%60,state:GetAttribute("NextBoss") or "")
 task.wait(0.1)
end

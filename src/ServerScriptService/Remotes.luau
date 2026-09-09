local RS = game:GetService("ReplicatedStorage")
local Names = require(RS.Modules.RemoteNames)
local Remotes = {}
function Remotes.Start()
 local f = RS:FindFirstChild("Remotes") or Instance.new("Folder")
 f.Name = "Remotes"; f.Parent = RS
 for key, name in Names do
  local r = f:FindFirstChild(name) or Instance.new("RemoteEvent")
  r.Name = name; r.Parent = f; Remotes[key] = r
 end
end
return Remotes

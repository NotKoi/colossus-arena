local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local CollectionService=game:GetService("CollectionService")
local Names=require(RS:WaitForChild("Modules"):WaitForChild("RemoteNames"))
local Config=require(RS.Modules.Config)
local remote=RS:WaitForChild("Remotes"):WaitForChild(Names.Telegraph)
local folder=Instance.new("Folder");folder.Name="ClientTelegraphs";folder.Parent=workspace
local active={}
local function part(parent,color)
 local p=Instance.new("Part");p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=Enum.Material.Neon;p.Color=color or Color3.fromRGB(255,76,65);p.Transparency=0.12;p.Parent=parent;return p
end
local function inside(p) return Vector3.new(p.X,0,p.Z).Magnitude<=Config.Map.ArenaRadius end
local function segment(p,a,b,width)
 local length=(a-b).Magnitude;p.Size=Vector3.new(width,0.12,math.max(0.01,length));p.CFrame=CFrame.lookAt((a+b)/2,b);p.Transparency=(inside(a) and inside(b)) and 0.12 or 1
end
local function ring(parent,color)
 local parts={};for i=1,Config.Effects.RingSegments do parts[i]=part(parent,color) end;return parts
end
local function drawRing(parts,center,radius,width)
 for i,p in parts do local a=(i-1)/#parts*math.pi*2;local b=i/#parts*math.pi*2;segment(p,Vector3.new(center.X+math.cos(a)*radius,Config.Effects.GroundY,center.Z+math.sin(a)*radius),Vector3.new(center.X+math.cos(b)*radius,Config.Effects.GroundY,center.Z+math.sin(b)*radius),width or 1) end
end
local function caption(parent,pos,text,color)
 local anchor=part(parent,color);anchor.Transparency=1;anchor.Size=Vector3.one;anchor.Position=Vector3.new(pos.X,4,pos.Z)
 local g=Instance.new("BillboardGui");g.Size=UDim2.fromScale(18,3);g.AlwaysOnTop=true;g.MaxDistance=250;g.Parent=anchor
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=Color3.fromRGB(25,43,62);t.BackgroundTransparency=.15;t.TextColor3=Color3.new(1,1,1);t.TextScaled=true;t.Font=Enum.Font.GothamBlack;t.Text=text;t.Parent=g
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(.2,0);corner.Parent=t
end
remote.OnClientEvent:Connect(function(d)
 if d.kind=="Clear" then for _,e in active do e.model:Destroy() end;table.clear(active);return end
 local m=Instance.new("Model");m.Name=d.kind;m.Parent=folder
 local e={data=d,model=m};local center=d.position or Vector3.zero
 if d.kind=="Circle" or d.kind=="Ring" or d.kind=="Burst" then e.ring=ring(m,d.color)
 elseif d.kind=="Line" then e.line=part(m,d.color)
 elseif d.kind=="Nova" then
  e.safe={};for _,pos in d.positions do table.insert(e.safe,{pos=pos,parts=ring(m,d.color or Color3.fromRGB(40,180,255))});caption(m,pos,"SAFE",d.color) end
  e.ring=ring(m,Color3.fromRGB(255,75,110))
 elseif d.kind=="Beam" then e.line=part(m,d.color)
 else m:Destroy();return end
 if d.label then caption(m,center,d.label,d.color) end
 table.insert(active,e);Debris:AddItem(m,(d.duration or 2)+1)
end)
RunService.RenderStepped:Connect(function()
 local now=workspace:GetServerTimeNow()
 for i=#active,1,-1 do
  local e=active[i];local d=e.data;local elapsed=now-d.start;local duration=d.duration or 2;local center=d.position or Vector3.zero
  if elapsed>=duration or not e.model.Parent then e.model:Destroy();table.remove(active,i)
  elseif d.kind=="Circle" then drawRing(e.ring,center,d.radius,1.8)
  elseif d.kind=="Ring" then drawRing(e.ring,center,math.max(0.1,elapsed*(d.speed or 35)),d.width or 3)
  elseif d.kind=="Burst" then drawRing(e.ring,center,(d.radius or 20)*elapsed/duration,2)
  elseif d.kind=="Line" then segment(e.line,Vector3.new(center.X,Config.Effects.GroundY,center.Z),Vector3.new(d.finish.X,Config.Effects.GroundY,d.finish.Z),d.width or 10)
  elseif d.kind=="Nova" then drawRing(e.ring,Vector3.zero,Config.Map.ArenaRadius-1,3);for _,r in e.safe do drawRing(r.parts,r.pos,d.radius,2.5) end
  elseif d.kind=="Beam" then
   local a=(d.angle or 0)+elapsed/duration*math.pi*2;local dir=Vector3.new(math.cos(a),0,math.sin(a));local length=d.radius or Config.Map.ArenaRadius
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=CollectionService:GetTagged("IcePillar")
   local origin=Vector3.new(center.X,3,center.Z);local hit=workspace:Raycast(origin,dir*length,params);if hit then length=hit.Distance end
   segment(e.line,Vector3.new(center.X,.3,center.Z),Vector3.new(center.X,.3,center.Z)+dir*length,d.width or 3)
  end
 end
end)

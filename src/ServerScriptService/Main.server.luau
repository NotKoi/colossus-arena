local map = require(script.Parent.MapBuilder).Build()
require(script.Parent.BaseAssignment).Start()
print("Colossus Arena: map and base assignment ready", #map.Bases:GetChildren())

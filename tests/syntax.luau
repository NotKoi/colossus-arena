local fs = require("@lune/fs")
local luau = require("@lune/luau")
local count = 0
local function scan(dir)
 for _, name in fs.readDir(dir) do
  local path=dir.."/"..name
  if fs.isDir(path) then scan(path)
  elseif string.match(name,"%.luau$") then
   local ok, err = pcall(luau.load, fs.readFile(path), {debugName=path})
   assert(ok, tostring(err)); count += 1
  end
 end
end
scan("src")
print("PASS syntax:", count, "Luau sources")

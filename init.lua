
--init

local modpath = minetest.get_modpath("biometer")

if minetest.get_modpath("default") then
  cg = "minetest_game"
  cgs = "minetest_game"
elseif minetest.get_modpath("mcl_core") then
  cg = "mineclone"
end
if minetest.get_modpath("vl_legacy") then
  cgs = "voxelibre"
else
  cgs = "mineclonia"
end

local file = io.open(modpath.."/environment_nodes.txt", "r")
if not file then
    print("Error while reading a file")
end
local content = file:read("*a")
file:close()

local inner_game = content:match(cg.."%s*=%s*%[(.-)%]")
local inner_heat = inner_game:match("heat%s*=%s*%{(.-)%}")
heat_nodes = {}
heat_nodes_counts = {}
if inner_heat then
  for name, num in inner_heat:gmatch("([^%s%(%)%,]+)%s*%((%-?[%d%.]+)%)") do
    table.insert(heat_nodes, name)
    heat_nodes_counts[name] = tonumber(num)
  end
end
inner_freeze = inner_game:match("freeze%s*=%s*%{(.-)%}")
freeze_nodes = {}
freeze_nodes_counts = {}
if inner_freeze then
  for name, num in inner_freeze:gmatch("([^%s%(%)%,]+)%s*%((%-?[%d%.]+)%)") do
    table.insert(freeze_nodes, name)
    freeze_nodes_counts[name] = tonumber(num)
  end
end

dofile(modpath .. "/functions.lua")
dofile(modpath .. "/hydration_bar.lua")
dofile(modpath .. "/temperature_display.lua")
dofile(modpath .. "/items.lua")
dofile(modpath .. "/ui.lua")

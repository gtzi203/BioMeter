
--init

biometer = {}

biometer.cg = "minetest_game"

if minetest.get_modpath("mcl_core") then
    biometer.cg = "mineclone"
end

biometer.environment_nodes = {}
biometer.environment_node_names = {}
biometer.heat_nodes = {}
biometer.freeze_nodes = {}

biometer.default_player_settings = {
    ["minetest_game"] = {
        ["HBpos"] = {x = 0.5, y = 1},
        ["HBoffset"] = {x = 151, y = -110},
        ["HBdirection"] = -1,
        ["SAVEDhydr"] = 20,
        ["SAVEDlockedhydr"] = false,
        ["TDpos"] = {x = 1, y = 1},
        ["TDoffset"] = {x = -70, y = -135},
        ["TDcolor"] = {r = 196, g = 0, b = 0},
        ["TDunit"] = "celsius",
        ["SAVEDadditionaltemp"] = 0,
        ["SAVEDlockedtemp"] = false
    },
    ["mineclone"] = {
        ["HBpos"] = {x = 0.5, y = 1},
        ["HBoffset"] = {x = -130, y = -138},
        ["HBdirection"] = -1,
        ["SAVEDhydr"] = 20,
        ["SAVEDlockedhydr"] = false,
        ["TDpos"] = {x = 1, y = 1},
        ["TDoffset"] = {x = -70, y = -135},
        ["TDcolor"] = {r = 196, g = 0, b = 0},
        ["TDunit"] = "celsius",
        ["SAVEDadditionaltemp"] = 0,
        ["SAVEDlockedtemp"] = false
    }
}
biometer.player_settings = {}
biometer.fake_player_settings = {}
biometer.player_hydrs = {}
biometer.player_temps = {}
biometer.saved_player_temps = {}
biometer.player_hydr_bar_huds = {}
biometer.player_temp_dis_huds = {}
biometer.player_editor_huds = {}
biometer.update_player_editor_huds = {}
biometer.editor_custom_save = {}

biometer.HYDR_BAR_SIZE = 20
biometer.hydr_bar_size_offset = biometer.HYDR_BAR_SIZE * 6.3

biometer.THER_SCALE = 8
biometer.EDITOR_THER_SCALE = 16
biometer.TEMP_HUDS_SCALE = 7.5
biometer.heat_hud_images = {
    {image = "biometer_heat_hud.png^[transformFX", pos = {x = 0, y = 0}, offset = {x = 240, y = 240}},
    {image = "biometer_heat_hud.png", pos = {x = 1, y = 0}, offset = {x = -240, y = 240}},
    {image = "biometer_heat_hud.png^[transformR180", pos = {x = 0, y = 1}, offset = {x = 240, y = -240}},
    {image = "biometer_heat_hud.png^[transformFXR180", pos = {x = 1, y = 1}, offset = {x = -240, y = -240}}
}
biometer.freeze_hud_images = {
    {image = "biometer_freeze_hud.png^[transformFX", pos = {x = 0, y = 0}, offset = {x = 240, y = 240}},
    {image = "biometer_freeze_hud.png", pos = {x = 1, y = 0}, offset = {x = -240, y = 240}},
    {image = "biometer_freeze_hud.png^[transformR180", pos = {x = 0, y = 1}, offset = {x = 240, y = -240}},
    {image = "biometer_freeze_hud.png^[transformFXR180", pos = {x = 1, y = 1}, offset = {x = -240, y = -240}}
}

biometer.player_test_hud = {}
biometer.update_player_test_hud = {}

biometer.hydr_bar_positions = {}
biometer.temp_dis_positions = {}
biometer.temp_units = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
local worldpath = minetest.get_worldpath()

local env_nodes_file = io.open(modpath.."/environment_nodes.txt", "r")
if not env_nodes_file then
    error("[Biometer]: Coulnd't find file 'environment_nodes.txt'")
end
local env_nodes = env_nodes_file:read("*a")
env_nodes_file:close()

local env_nodes = env_nodes:match(biometer.cg .. "%s*=%s*%[(.-)%]")
local heat_nodes = env_nodes:match("heat%s*=%s*%{(.-)%}")
local freeze_nodes = env_nodes:match("freeze%s*=%s*%{(.-)%}")

if heat_nodes then
    for name, number in heat_nodes:gmatch("([^%s%(%)%,]+)%s*%((%-?[%d%.]+)%)") do
        biometer.environment_nodes[tostring(name)] = tonumber(number)
        table.insert(biometer.environment_node_names, name)
        biometer.heat_nodes[tostring(name)] = tonumber(number)
    end
end
if freeze_nodes then
    for name, number in freeze_nodes:gmatch("([^%s%(%)%,]+)%s*%((%-?[%d%.]+)%)") do
        biometer.environment_nodes[tostring(name)] = tonumber(number)
        table.insert(biometer.environment_node_names, name)
        biometer.freeze_nodes[tostring(name)] = tonumber(number)
    end
end

minetest.mkdir(worldpath .. "/biometer")

minetest.register_on_prejoinplayer(function(name, ip)
    ::get_settings::

    local settings = io.open(worldpath .. "/biometer/" .. name .. ".txt", "r")

    if not settings then
        local new_settings = io.open(worldpath .. "/biometer/" .. name .. ".txt", "w")

        new_settings:write(minetest.serialize(biometer.default_player_settings[biometer.cg]))
        new_settings:close()

        goto get_settings
    end

    biometer.player_settings[name] = minetest.deserialize(settings:read("*a"))
    biometer.player_hydrs[name] = 20
    biometer.player_temps[name] = 0
    biometer.saved_player_temps[name] = {biome = 0, env_nodes = 0, time = 0, height = 0}

    settings:close()
end)

minetest.register_node("biometer:test_heat", {
    description = "Test Heat",
    tiles = {"biometer_heat_hud_bg.png"},
    groups = {oddly_breakable_by_hand = 3, not_in_creative_inventory = 1}
})

minetest.register_node("biometer:test_freeze", {
    description = "Test Freeze",
    tiles = {"biometer_freeze_hud_bg.png"},
    groups = {oddly_breakable_by_hand = 3, not_in_creative_inventory = 1}
})

dofile(modpath .. "/api.lua")
dofile(modpath .. "/hydration_bar.lua")
dofile(modpath .. "/temperature_display.lua")
dofile(modpath .. "/commands.lua")
dofile(modpath .. "/editor.lua")
dofile(modpath .. "/items.lua")
dofile(modpath .. "/crafting.lua")

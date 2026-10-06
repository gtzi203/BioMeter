
--hydration_bar

local S = minetest.get_translator(minetest.get_current_modname())

local HYDR_UPDATE_INTERVAL = tonumber(minetest.settings:get("biometer.hydr_update_interval") or 8)
local HYDR_DAMAGE_INTERVAL = tonumber(minetest.settings:get("biometer.hydr_damage_interval") or 2)

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()

    local settings = biometer.get_settings(player_name)

    if not settings then
        return
    end

    biometer.set_hydr(player, settings.SAVEDhydr, false, true)

    biometer.player_hydr_bar_huds[player_name] = false

    minetest.after(0.5, function()
        local id_hydr_bar = player:hud_add({
            hud_elem_type = "statbar",
            position = {x = 0, y = 0},
            offset = {x = 0, y = 0},
            text = "biometer_hydration_icon_" .. biometer.cg .. ".png",
            text2 = (biometer.cg == "mineclone" and "biometer_hydration_icon_black_mineclone.png") or "",
            number = biometer.HYDR_BAR_SIZE,
            item = biometer.HYDR_BAR_SIZE,
            direction = 0,
            size = {x = 24, y = 24},
            z_index = -1
        })

        local id_hydr_hud_bg = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.5},
            offset = {x = 0, y = 0},
            text = "",
            alignment = {x = 0, y = 0},
            scale = {x = 0, y = 0},
            z_index = 1001
        })

        biometer.player_hydr_bar_huds[player_name] = {hydr_bar = id_hydr_bar, hydr_hud_bg = id_hydr_hud_bg}

        biometer.update_hydr_bar(player)
    end)
end)

local count = 0
local damage_count = 0

minetest.register_globalstep(function(dtime)
    count = count + dtime
    damage_count = damage_count + dtime

    if count >= HYDR_UPDATE_INTERVAL then
        for _, player in ipairs(minetest.get_connected_players()) do
            local player_name = player:get_player_name()
            
            local hydr = biometer.calc_hydr(biometer.get_temp(player_name))

            biometer.add_hydr(player, -hydr)
        end

        count = 0
    end

    if damage_count >= HYDR_DAMAGE_INTERVAL then
        for _, player in ipairs(minetest.get_connected_players()) do
            biometer.deal_hydr_damage(player)
        end

        damage_count = 0
    end
end)

--it only works sometimes, so i just set it every time in set_hydr()
--[[minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()

    biometer.set_settings(player_name, {["SAVEDhydr"] = biometer.get_hydr(player_name)})
end)--]]

minetest.register_on_respawnplayer(function(player)
    biometer.set_hydr(player, biometer.HYDR_BAR_SIZE, false, true)
end)
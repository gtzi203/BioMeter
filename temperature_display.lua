
--temperature_display

local S = minetest.get_translator(minetest.get_current_modname())

local TEMP_UPDATE_INTERVAL = tonumber(minetest.settings:get("biometer.temp_update_interval") or 0.1)
local TEMP_DAMAGE_INTERVAL = tonumber(minetest.settings:get("biometer.temp_damage_interval") or 2)

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()

    local _, temps = biometer.calc_temp(player:get_pos())

    biometer.saved_player_temps[player_name] = temps

    biometer.set_temp(player, biometer.calc_total_temp(temps))

    biometer.player_temp_dis_huds[player_name] = false

    --wait a bit, because window information needs some time
    minetest.after(0.5, function()
        local id_temp_dis = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0, y = 0},
            offset = {x = 0, y = 0},
            text = "--??",
            alignment = {x = 0, y = 0},
            scale = {x = 0, y = 0},
            number = 0xFFFFFF,
            z_index = 5
        })

        local id_ther = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0, y = 0},
            offset = {x = 0, y = 0},
            text = "biometer_thermometer.png",
            alignment = {x = 0, y = 0},
            scale = {x = 0, y = 0},
            z_index = 5
        })

        local id_ther_inner = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0, y = 0},
            offset = {x = 0, y = 0},
            text = "biometer_thermometer_inner.png",
            alignment = {x = 0, y = 0},
            scale = {x = 0, y = 0},
            z_index = 3
        })

        local id_ther_inner_down = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0, y = 0},
            offset = {x = 0, y = 0},
            text = "biometer_thermometer_inner_down.png",
            alignment = {x = 0, y = 0},
            scale = {x = 0, y = 0},
            z_index = 4
        })

        local heat_huds = {}
        local freeze_huds = {}

        local id_heat_hud_bg = player:hud_add({
                hud_elem_type = "image",
                position = {x = 0.5, y = 0.5},
                offset = {x = 0, y = 0},
                text = "",
                alignment = {x = 0, y = 0},
                scale = {x = 999, y = 999},
                z_index = 999
            })

        for i = 1, 4, 1 do
            local heat_hud = biometer.heat_hud_images[i]

            local id_heat_hud = player:hud_add({
                hud_elem_type = "image",
                position = heat_hud.pos,
                offset = {x = 0, y = 0},
                text = "",
                alignment = {x = 0, y = 0},
                scale = {x = 0, y = 0},
                z_index = 1000
            })

            heat_huds[i] = id_heat_hud
        end

        local id_freeze_hud_bg = player:hud_add({
                hud_elem_type = "image",
                position = {x = 0.5, y = 0.5},
                offset = {x = 0, y = 0},
                text = "",
                alignment = {x = 0, y = 0},
                scale = {x = 999, y = 999},
                z_index = 999
            })

        for i = 1, 4, 1 do
            local freeze_hud = biometer.freeze_hud_images[i]

            local id_freeze_hud = player:hud_add({
                hud_elem_type = "image",
                position = freeze_hud.pos,
                offset = {x = 0, y = 0},
                text = "",
                alignment = {x = 0, y = 0},
                scale = {x = 0, y = 0},
                z_index = 1000
            })

            freeze_huds[i] = id_freeze_hud
        end

        biometer.player_temp_dis_huds[player_name] = {temp_dis = id_temp_dis, ther = id_ther, ther_inner = id_ther_inner, ther_inner_down = id_ther_inner_down, heat_hud_bg = id_heat_hud_bg, heat_huds = heat_huds, freeze_hud_bg = id_freeze_hud_bg, freeze_huds = freeze_huds}

        biometer.update_temp_dis(player)
    end)
end)

local count = 0
local biome_count = 0
local damage_count = 0

minetest.register_globalstep(function(dtime)
    count = count + dtime
    damage_count = damage_count + dtime

    if count >= TEMP_UPDATE_INTERVAL then
        biome_count = biome_count + dtime

        for _, player in ipairs(minetest.get_connected_players()) do
            local player_name = player:get_player_name()
            local player_pos = player:get_pos()

            if biome_count < 1 * (TEMP_UPDATE_INTERVAL * 10) then
                local biome_temp = biometer.saved_player_temps[player_name].biome
                local env_nodes_temp = biometer.calc_env_nodes_temp(player_pos)
                local time_temp = biometer.calc_time_temp()
                local height_temp = biometer.saved_player_temps[player_name].height

                biometer.saved_player_temps[player_name] = {biome = biome_temp, env_nodes = env_nodes_temp, time = time_temp, height = height_temp}
            else
                local _, temps = biometer.calc_temp(player_pos)

                biometer.saved_player_temps[player_name] = temps

                biome_count = 0
            end

            biometer.set_temp(player, biometer.calc_total_temp(biometer.saved_player_temps[player_name]))
        end

        count = 0
    end

    if damage_count >= TEMP_DAMAGE_INTERVAL then
        for _, player in ipairs(minetest.get_connected_players()) do
            biometer.deal_temp_damage(player)
        end

        damage_count = 0
    end
end)

minetest.register_on_respawnplayer(function(player)
    biometer.set_temp(player, biometer.calc_temp(player:get_pos()))
end)
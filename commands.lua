
--commands

local S = minetest.get_translator(minetest.get_current_modname())

local INIT_TEST_HUD = minetest.settings:get_bool("biometer.init_test_hud") or false

--privs

minetest.register_privilege("biometer_test", {
    description = "Allows you to use the biometer_test command",
    give_to_singleplayer = false
})

--command functions

local function command_reset_action(player, full)
    local player_name = player:get_player_name()

    biometer.hide_editor_huds(player)

    local settings = biometer.get_settings(player_name)
    local default_settings = table.copy(biometer.default_player_settings[biometer.cg])

    if full then
        biometer.set_settings(player_name, default_settings)

        biometer.unlock_hydr(player_name)
        biometer.set_additional_temp(player_name, 0)
        biometer.unlock_temp(player_name)

        biometer.set_hydr(player, default_settings.SAVEDhydr, false, true)
        biometer.set_temp(player, biometer.calc_temp(player:get_pos()))
    else
        default_settings.SAVEDhydr = settings.SAVEDhydr

        biometer.set_settings(player_name, default_settings)

        biometer.update_hydr_bar(player)
        biometer.update_temp_dis(player)
    end
end

local function command_action(player_name, param)
    local player = minetest.get_player_by_name(player_name)

    if param == "" or param == "editor" then
        biometer.open_editor(player)
    elseif param == "reset" then
        command_reset_action(player, false)

        biometer.msg(player_name, S("Reseted") .. "!")
    elseif param == "reset_editor" then
        biometer.hide_editor_huds(player)

        biometer.msg(player_name, S("Editor reseted") .. "!")
    else
        biometer.msg(player_name, S("Invalid parameter '@1'", param) .. ".")
    end
end

--commands

minetest.register_chatcommand("biometer", {
    description = "Params: none/editor: opens editor, reset: resets settings",
    privs = {},
    func = function(name, param)
        command_action(name, param)
    end,
})

minetest.register_chatcommand("bm", {
    description = "Params: none/editor: opens editor, reset: resets settings",
    privs = {},
    func = function(name, param)
        command_action(name, param)
    end,
})

minetest.register_chatcommand("biometer_test", {
    description = "",
    privs = {biometer_test = true},
    func = function(name, param)
        local player = minetest.get_player_by_name(name)

        if param == "" or param == "test_hud" then
            if INIT_TEST_HUD then
                if not biometer.update_player_test_hud[name] then
                    biometer.update_player_test_hud[name] = true

                    biometer.msg(name, "Run this command again to disable the hud.")
                else
                    biometer.update_player_test_hud[name] = false

                    biometer.msg(name, "Run this command again to enable the hud.")
                end
            else
                biometer.msg(name, "Enable the test hud in the settings (Set 'Initialize Test Hud' to true).")
            end
        elseif string.find(param, "set_hydr") then
            local hydr = tonumber(string.sub(param, 10)) or biometer.HYDR_BAR_SIZE

            biometer.set_hydr(player, hydr, false, true)

            biometer.msg(name, "Set hydration to " .. hydr .. ".")
        elseif param == "reset" then
            command_reset_action(player, true)

            biometer.msg(player:get_player_name(), S("Fully reseted") .. "!")
        elseif string.find(param, "lock_hydr") and not string.find(param, "unlock_hydr") then
            local locked_hydr = tonumber(string.sub(param, 11)) or nil

            biometer.lock_hydr(name, locked_hydr)

            biometer.msg(name, "Locked hydration at " .. (locked_hydr or biometer.get_hydr(name)) .. ".")
        elseif param == "unlock_hydr" then
            biometer.unlock_hydr(name)

            biometer.msg(name, "Unlocked hydration.")
        elseif string.find(param, "set_add_temp") then
            local additional_temp = tonumber(string.sub(param, 14)) or 0

            biometer.set_additional_temp(name, additional_temp)

            biometer.msg(name, "Set additional temperature to " .. additional_temp .. ".")
        elseif string.find(param, "lock_temp") and not string.find(param, "unlock_temp") then
            local locked_temp = tonumber(string.sub(param, 11)) or nil

            biometer.lock_temp(name, locked_temp)

            biometer.msg(name, "Locked temperature at " .. (locked_temp or biometer.get_temp(name)) .. ".")
        elseif param == "unlock_temp" then
            biometer.unlock_temp(name)

            biometer.msg(name, "Unlocked temperature.")
        elseif param == "custom_hydr_bar" then
            biometer.open_custom_hydr_bar_pos_editor(player)
        elseif param == "custom_temp_dis" then
            biometer.open_custom_temp_dis_pos_editor(player)
        else
            biometer.msg(name, S("Invalid parameter '@1'", param) .. ".")
        end
    end,
})

--test huds

if INIT_TEST_HUD then
    minetest.register_on_joinplayer(function(player)
        local id_test_hud = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0, y = 0.4},
            offset = {x = 20, y = 0},
            text = "",
            alignment = {x = 1, y = 0},
            scale = {x = 0, y = 0},
            number = 0xFFFFFF,
            z_index = 99999
        })

        biometer.player_test_hud[player:get_player_name()] = id_test_hud
    end)

    minetest.register_globalstep(function(dtime)
        for _, player in ipairs(minetest.get_connected_players()) do
            local player_name = player:get_player_name()

            local id = biometer.player_test_hud[player_name]

            if id then
                if biometer.update_player_test_hud[player_name] then
                    local _, hydrs = biometer.get_hydr(player_name)
                    local _, temps = biometer.get_temp(player_name)

                    local output_text = (
                        "BioMeter - Test Hud (" .. player_name .. ")\n" ..
                        "\nHYDRATION:" ..
                        "\n  Resulting: " .. hydrs.resulting ..
                        "\n  Real: " .. hydrs.real ..
                        "\n  Locked: " .. tostring(hydrs.locked) .. "\n" ..
                        "\nTEMPERATURE:" ..
                        "\n  Resutling: " .. 
                        temps.resulting .. 
                        "\n  Real: " .. temps.real .. 
                        "\n  Additional: " .. temps.additional .. 
                        "\n  Locked: " .. tostring(temps.locked) ..
                        "\n  Saved: " ..
                        "\n    Biome: " .. tostring(temps.saved.biome) .. 
                        "\n    Environment Nodes: " .. tostring(temps.saved.env_nodes) .. 
                        "\n    Time: " .. tostring(temps.saved.time) .. 
                        "\n    Height: " .. tostring(temps.saved.height)
                    )

                    player:hud_change(id, "text", output_text)
                else
                    player:hud_change(id, "text", "")
                end
            end
        end
    end)
end
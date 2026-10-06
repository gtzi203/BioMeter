
--editor

local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()

    biometer.player_temp_dis_huds[player_name] = false

    --wait a bit, because window information needs some time
    minetest.after(0.5, function()
        biometer.THER_SCALE = 8

        local hud_scale_mult = biometer.get_hud_scale_mult(player_name)

        local id_bg = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.5},
            offset = {x = 0, y = 0},
            text = "",
            alignment = {x = 0, y = 0},
            scale = {x = 0, y = 0},
            z_index = 9999
        })

        local id_text_r = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.4815, y = 0.2925},
            offset = {x = 0, y = 0},
            text = "",
            alignment = {x = 1, y = 0},
            scale = {x = 1, y = 1},
            number = 0x80FFFFFF,
            z_index = 10000
        })

        local id_text_g = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.4815, y = 0.3525},
            offset = {x = 0, y = 0},
            text = "",
            alignment = {x = 1, y = 0},
            scale = {x = 1, y = 1},
            number = 0xFFFFFF,
            z_index = 10000
        })

        local id_text_b = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.4815, y = 0.412},
            offset = {x = 0, y = 0},
            text = "",
            alignment = {x = 1, y = 0},
            scale = {x = 1, y = 1},
            number = 0xFFFFFF,
            z_index = 10000
        })

        local id_temp_dis = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.63, y = 0.49},
            offset = {x = 0, y = 0},
            text = "",
            alignment = {x = 0, y = 0},
            scale = {x = 0, y = 0},
            size = {x = 2, y = 2},
            number = 0xFFFFFF,
            z_index = 10003
        })

        local id_ther = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.63, y = 0.49},
            offset = {x = 0, y = 0},
            text = "",
            alignment = {x = 0, y = 0},
            scale = {x = biometer.EDITOR_THER_SCALE, y = biometer.EDITOR_THER_SCALE},
            z_index = 10003
        })

        local id_ther_inner = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.63, y = 0.49},
            offset = {x = 0, y = 0},
            text = "",
            alignment = {x = 0, y = 0},
            scale = {x = biometer.EDITOR_THER_SCALE, y = biometer.EDITOR_THER_SCALE},
            z_index = 10001
        })

        local id_ther_inner_down = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.63, y = 0.49},
            offset = {x = 0, y = 0},
            text = "",
            alignment = {x = 0, y = 0},
            scale = {x = biometer.EDITOR_THER_SCALE, y = biometer.EDITOR_THER_SCALE},
            z_index = 10002
        })

        biometer.player_editor_huds[player_name] = {bg = id_bg, text_r = id_text_r, text_g = id_text_g, text_b = id_text_b, temp_dis = id_temp_dis, ther = id_ther, ther_inner = id_ther_inner, ther_inner_down = id_ther_inner_down}
    end)
end)

--editor

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "biometer:editor" then
        return
    end

    local player_name = player:get_player_name()

    local default_settings = biometer.default_player_settings[biometer.cg]

    if fields.color_r or fields.color_g or fields.color_b and not fields.apply_changes then
        local r = minetest.explode_textlist_event(fields.color_r).index
        local g = minetest.explode_textlist_event(fields.color_g).index
        local b = minetest.explode_textlist_event(fields.color_b).index

        biometer.set_fake_settings(player_name, {["TDcolor"] = {r = r, g = g, b = b}})

        biometer.update_temp_dis(player)
    end

    if fields.default_color then
        biometer.set_fake_settings(player_name, {["TDcolor"] = default_settings.TDcolor})

        biometer.update_temp_dis(player)

        biometer.open_editor(player, true)
    end

    if fields.temp_unit and not fields.apply_changes then
        local _, temp_unit = biometer.get_temp_unit_index_by_description(fields.temp_unit)

        biometer.set_fake_settings(player_name, {["TDunit"] = temp_unit.name})

        biometer.update_temp_dis(player)
    end

    if fields.default_temp_unit then
        biometer.set_fake_settings(player_name, {["TDunit"] = default_settings.TDunit})

        biometer.update_temp_dis(player)

        biometer.open_editor(player, true)
    end

    if fields.temp_dis_pos and not fields.apply_changes then
        local _, temp_dis_pos = biometer.get_temp_dis_pos_index_by_description(fields.temp_dis_pos, true)

        if not temp_dis_pos then
            temp_dis_pos = table.copy(biometer.editor_custom_save[player_name]["temp_dis"])
        end

        biometer.set_fake_settings(player_name, {["TDpos"] = temp_dis_pos.pos, ["TDoffset"] = temp_dis_pos.offset})

        biometer.update_temp_dis(player)
    end

    if fields.custom_temp_dis_pos then
        biometer.hide_editor_huds(player, true)

        biometer.open_custom_temp_dis_pos_editor(player)
    end

    if fields.default_temp_dis_pos then
        biometer.set_fake_settings(player_name, {["TDpos"] = default_settings.TDpos, ["TDoffset"] = default_settings.TDoffset})

        biometer.update_temp_dis(player)

        biometer.open_editor(player, true)
    end

    if fields.hydr_bar_pos and not fields.apply_changes then
        local _, hydr_bar_pos = biometer.get_hydr_bar_pos_index_by_description(fields.hydr_bar_pos, true)

        if not hydr_bar_pos then
            hydr_bar_pos = table.copy(biometer.editor_custom_save[player_name]["hydr_bar"])
        end

        biometer.set_fake_settings(player_name, {["HBpos"] = hydr_bar_pos.pos, ["HBoffset"] = hydr_bar_pos.offset, ["HBdirection"] = hydr_bar_pos.direction})

        biometer.update_hydr_bar(player)
    end

    if fields.custom_hydr_bar_pos then
        biometer.hide_editor_huds(player, true)

        biometer.open_custom_hydr_bar_pos_editor(player)
    end

    if fields.default_hydr_bar_pos then
        biometer.set_fake_settings(player_name, {["HBpos"] = default_settings.HBpos, ["HBoffset"] = default_settings.HBoffset, ["HBdirection"] = default_settings.HBdirection})

        biometer.update_hydr_bar(player)

        biometer.open_editor(player, true)
    end

    if fields.quit then
        if fields.apply_changes then
            local fake_settings = biometer.get_fake_settings(player_name)

            biometer.set_settings(player_name, {
                ["HBpos"] = fake_settings.HBpos,
                ["HBoffset"] = fake_settings.HBoffset,
                ["HBdirection"] = fake_settings.HBdirection,
                ["TDpos"] = fake_settings.TDpos,
                ["TDoffset"] = fake_settings.TDoffset,
                ["TDcolor"] = fake_settings.TDcolor,
                ["TDunit"] = fake_settings.TDunit
            })
        end

        biometer.remove_fake_settings(player_name)
        biometer.hide_editor_huds(player)

        biometer.update_hydr_bar(player)
        biometer.update_temp_dis(player)
    end
end)

--custom hydr bar pos editor

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "biometer:custom_hydr_bar_pos_editor" then
        return
    end

    local player_name = player:get_player_name()

    if (fields.xpos or fields.ypos or fields.xoffset or fields.yoffset) and fields.key_enter_field then
        biometer.set_fake_settings(player_name, {["HBpos"] = {x = tonumber(fields.xpos) or 0, y = tonumber(fields.ypos) or 0}, ["HBoffset"] = {x = tonumber(fields.xoffset) or 0, y = tonumber(fields.yoffset) or 0}})

        biometer.update_hydr_bar(player)

        minetest.after(0.04, function()
            biometer.open_custom_hydr_bar_pos_editor(player)
        end)
    end

    if fields.direction then
        local direction = -1

        if fields.direction == "2" then
            direction = 1
        end

        biometer.set_fake_settings(player_name, {["HBdirection"] = direction})

        biometer.update_hydr_bar(player)
    end

    if fields.confirm then
        biometer.show_editor_huds(player)

        biometer.open_editor(player, true)
    end

    if fields.quit and not fields.key_enter_field then
        local settings = biometer.get_settings(player_name, true)

        if not settings then
            return
        end

        biometer.set_fake_settings(player_name, {["HBpos"] = settings.HBpos, ["HBoffset"] = settings.HBoffset, ["HBdirection"] = settings.HBdirection})

        biometer.update_hydr_bar(player)

        minetest.after(0.04, function()
            biometer.show_editor_huds(player)

            biometer.open_editor(player, true)
        end)
    end
end)

--custom temp dis pos editor

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "biometer:custom_temp_dis_pos_editor" then
        return
    end

    local player_name = player:get_player_name()

    if (fields.xpos or fields.ypos or fields.xoffset or fields.yoffset) and fields.key_enter_field then
        biometer.set_fake_settings(player_name, {["TDpos"] = {x = tonumber(fields.xpos) or 0, y = tonumber(fields.ypos) or 0}, ["TDoffset"] = {x = tonumber(fields.xoffset) or 0, y = tonumber(fields.yoffset) or 0}})

        biometer.update_temp_dis(player)

        minetest.after(0.04, function()
            biometer.open_custom_temp_dis_pos_editor(player)
        end)
    end

    if fields.confirm then
        biometer.show_editor_huds(player)

        biometer.open_editor(player, true)
    end

    if fields.quit and not fields.key_enter_field then
        local settings = biometer.get_settings(player_name, true)

        if not settings then
            return
        end

        biometer.set_fake_settings(player_name, {["TDpos"] = settings.TDpos, ["TDoffset"] = settings.TDoffset, ["TDdirection"] = settings.TDdirection})

        biometer.update_temp_dis(player)

        minetest.after(0.04, function()
            biometer.show_editor_huds(player)

            biometer.open_editor(player, true)
        end)
    end
end)

minetest.register_on_dieplayer(function(player, reason)
    biometer.remove_fake_settings(player:get_player_name())
    biometer.hide_editor_huds(player)

    biometer.update_hydr_bar(player)
    biometer.update_temp_dis(player)
end)

--inventory buttons

if minetest.get_modpath("i3") then
    i3.new_tab("biometer_editor", {
        description = S("BioMeter Editor"),
        fields = function(player, data, fields)
            i3.set_tab(player, "inventory")

            biometer.open_editor(player)
        end
    })
elseif minetest.get_modpath("unified_inventory") then
    unified_inventory.register_button("biometer_editor", {
        type = "image",
        image = "biometer_icon.png",
        tooltip = S("BioMeter Editor"),
        action = function(player)
            biometer.open_editor(player)
        end
    })
elseif minetest.get_modpath("mcl_inventory") then
    minetest.register_craftitem("biometer:icon", {
        description = "BioMeter Icon",
        inventory_image = "biometer_icon.png",
        groups = {not_in_creative_inventory = 1},
        stack_max = 1
    })

    mcl_inventory.register_survival_inventory_tab({
        id = "biometer_editor",
        description = S("BioMeter Editor"),
        item_icon = "biometer:icon",
        show_inventory = false,
        build = function(player)
            return ""
        end,
        handle = function(player, fields)
            biometer.open_editor(player)
        end
    })
elseif minetest.get_modpath("sfinv") then
    sfinv.register_page("biometer_editor", {
        title = S("BioMeter Editor"),
        get = function(self, player, context)
            return ""
        end,
        on_enter = function(self, player, context)
            sfinv.contexts[player:get_player_name()].page = sfinv.get_homepage_name(player)

            biometer.open_editor(player)
        end
    })
end
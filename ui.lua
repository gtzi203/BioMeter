
--ui

local S = minetest.get_translator(minetest.get_current_modname())

local index = {}

local function hud_add(player, hud)
	local hud_style = core.has_feature("hud_def_type_field")
	if hud_style and hud["hud_elem_type"] then
		hud["type"] = hud["hud_elem_type"]
		hud["hud_elem_type"] = nil
	end
	return player:hud_add(hud)
end

minetest.register_chatcommand("bm", {
  description = "Opens the BM UI.",
  func = function(name, param)
    player = minetest.get_player_by_name(name)

    biometer.button_action(player)
end})

minetest.register_chatcommand("bm_reset", {
  description = "Resets the BM UI or the positions of the hydration bar and the thermometer.",
  func = function(name, param)
    local player = minetest.get_player_by_name(name)
    local meta = player:get_meta()

    if param == "ui" then
      meta:set_string("bm_temp_in", meta:get_string("bm_temp_in_old"))
      biometer.update_ui_ther(player, false, true, false)
      biometer.update_ther_color(player, "no")
      biometer.set_temp(player)
      minetest.chat_send_player(name, "[BioMeter] UI reseted!")
    elseif param == "pos" then
      local default_hydr_bar_pos = bm.hydr_bar_pos[cg][bm.hydr_bar_pos[cg].default_pos].pos
      local default_ther_pos = bm.ther_pos[cg][bm.ther_pos[cg].default_pos].pos

      meta:set_string("bm_hydr_bar_pos", default_hydr_bar_pos)
      meta:set_string("bm_hydr_bar_pos_old", default_hydr_bar_pos)

      meta:set_string("bm_ther_pos", default_ther_pos)
      meta:set_string("bm_ther_pos_old", default_ther_pos)

      biometer.update_hydr_bar_pos(player)
      biometer.update_ui_ther(player, false, true, false)
      biometer.update_ther_pos(player)
      minetest.chat_send_player(name, "[BioMeter] Positions reseted!")
    end
end})

minetest.register_chatcommand("bm_hydr", {
  description = "Set hydration to n.",
  params = "<number>",
  privs = {creative = true},
  func = function(name, param)
    param = tonumber(param)
    if param and param >= 0 and param <= 20 then
      biometer.set_hydr_bar(minetest.get_player_by_name(name), false, param)
      minetest.chat_send_player(name, "Hydration set to "..param..".")
    else
      minetest.chat_send_player(name, "Please use a valid number number (0-20).")
    end
end})

if minetest.global_exists("sfinv") then
  sfinv.register_page("biometer", {
    title = S("BioMeter"),
    get = function(self, player, context)
      return ""
    end,
    on_enter = function(self, player, context)
      sfinv.contexts[player:get_player_name()].page = sfinv.get_homepage_name(player)
      biometer.button_action(player)
    end
  })
end

if minetest.global_exists("mcl_inventory") then
  minetest.register_craftitem("biometer:icon", {
    description = "BioMeter Icon",
    inventory_image = "biometer_icon.png",
    groups = {not_in_creative_inventory = 1},
    stack_max = 1
  })

  mcl_inventory.register_survival_inventory_tab({
    id = "biometer",
    description = "BioMeter",
    item_icon = "biometer:icon",
    show_inventory = false,
    build = function(player)
      return ""
    end,
    handle = function(player, fields)
      biometer.button_action(player)
    end
  })
end

if minetest.global_exists("unified_inventory") then
  unified_inventory.register_button("biometer", {
    type = "image",
    image = "biometer_icon.png",
    tooltip = "BioMeter",
    action = function(player)
      biometer.button_action(player)
    end
  })
end

if minetest.global_exists("i3") then
  i3.new_tab("biometer_test", {
    description = "BioMeter",
    fields = function(player, data, fields)
      i3.set_tab(player, "inventory")
      biometer.button_action(player)
    end
  })
end

minetest.register_on_joinplayer(function(player)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local id_bg = hud_add(player, {
      hud_elem_type = "image",
      position = {x = 0.5, y = 0.5},
      offset = {x = 0, y = 0},
      text = "biometer_bg.png^[opacity:0",
      alignment = {x = 0, y = 0},
      scale = {x = 48, y = 39},
      z_index = 9999
    })

    local id_r_text = hud_add(player, {
      hud_elem_type = "text",
      position = {x = 0.5, y = 0.5},
      offset = {x = -38, y = -225}, --20 -233
      text = "",
      alignment = {x = 1, y = 0},
      scale = {x = 1, y = 1},
      number = 0x80FFFFFF,
      z_index = 10000
    })

    local id_g_text = hud_add(player, {
      hud_elem_type = "text",
      position = {x = 0.5, y = 0.5},
      offset = {x = -38, y = -160},
      text = "",
      alignment = {x = 1, y = 0},
      scale = {x = 1, y = 1},
      number = 0xFFFFFF,
      z_index = 10000
    })

    local id_b_text = hud_add(player, {
      hud_elem_type = "text",
      position = {x = 0.5, y = 0.5},
      offset = {x = -38, y = -95},
      text = "",
      alignment = {x = 1, y = 0},
      scale = {x = 1, y = 1},
      number = 0xFFFFFF,
      z_index = 10000
    })
    meta:set_string("bm_bg_id", id_bg)
    meta:set_string("bm_r_text_id", id_r_text)
    meta:set_string("bm_g_text_id", id_g_text)
    meta:set_string("bm_b_text_id", id_b_text)
  end
end)

minetest.register_on_dieplayer(function(player)
  local meta = player:get_meta()

  meta:set_string("bm_temp_in", meta:get_string("bm_temp_in_old"))
  biometer.update_ui_ther(player, false, true, false)
  biometer.update_ther_color(player, "no")
  biometer.set_temp(player)
end)

function biometer.get_ui(player, new)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local r, g, b

    local _temp_in = {["celsius"] = 1, ["fahrenheit"] = 2, ["kelvin"] = 3}
    local temp_in = _temp_in[meta:get_string("bm_temp_in")]

    local hydr_bar_pos
    local hydr_bar_pos_custom = ""

    local ther_pos
    local ther_pos_custom = ""

    for k, v in pairs(bm.hydr_bar_pos[cg]) do
      if type(v) == "table" and v.pos == meta:get_string("bm_hydr_bar_pos") then
        hydr_bar_pos = k

        break
      end
    end

    if not hydr_bar_pos then
      hydr_bar_pos_custom = "Custom,"
      hydr_bar_pos = 1
    end

    for k, v in pairs(bm.ther_pos[cg]) do
      if type(v) == "table" and v.pos == meta:get_string("bm_ther_pos") then
        ther_pos = k

        break
      end
    end

    if not ther_pos then
      ther_pos_custom = "Custom,"
      ther_pos = 1
    end

    index[player:get_player_name()] = (tonumber(index[player:get_player_name()] or 0) + 1)
    local player_index = index[player:get_player_name()]

    if new then
      r, g, b = biometer.get_rgb(meta:get_string("bm_ther_color"))
      meta:set_string("bm_temp_in_old", meta:get_string("bm_temp_in"))
      meta:set_string("bm_hydr_bar_pos_old", meta:get_string("bm_hydr_bar_pos"))
      meta:set_string("bm_ther_pos_old", meta:get_string("bm_ther_pos"))
    else
      r, g, b = biometer.get_rgb(meta:get_string("bm_ther_color_change"))
    end

    meta:set_string("bm_do_temp_dmg", "true")

    formspec = (
      "formspec_version[6]"..
      "size[12,10]"..
      "no_prepend[]"..
      "bgcolor[#FFFFFF00;false]"..
      "label[0.2,0.4;BioMeter]"..

      "container[1,1.3]"..
        "scrollbaroptions[min=0;max=255;smallstep=1]"..

        "label[0,0.25;R]"..
        "box[0.3,0.01;3.99,0.48;#FF0000CC]"..
        "scrollbar[0.3,0;4,0.5;horizontal;r_"..player_index..";"..r.."]"..

        "label[0,1.25;G]"..
        "box[0.3,1.01;3.99,0.48;#00FF00CC]"..
        "scrollbar[0.3,1;4,0.5;horizontal;g_"..player_index..";"..g.."]"..

        "label[0,2.25;B]"..
        "box[0.3,2.01;3.99,0.48;#0000FFCC]"..
        "scrollbar[0.3,2;4,0.5;horizontal;b_"..player_index..";"..b.."]"..

        "tooltip[default_color;"..S("Set to Default").."]"..
        "image_button[5.3,0.85;0.8,0.8;biometer_default_btn.png;default_color;;false;true]"..

          "label[0,3.3;"..S("Temperature in")..":]"..
          "dropdown[0,3.5;3,0.8;temp_in;"..S("Celsius")..","..S("Fahrenheit")..","..S("Kelvin")..";"..temp_in..";false]"..

          "tooltip[default_temp;"..S("Set to Default").."]"..
          "image_button[3.2,3.5;0.8,0.8;biometer_default_btn.png;default_temp;;false;true]"..

        "label[0,4.8;"..S("Thermometer Position")..":]"..
        "dropdown[0,5;3,0.8;ther_pos;"..ther_pos_custom..""..S("Hotbar-Right")..","..S("Hotbar-Left")..","..S("Top-Middle")..","..S("Top-Right")..","..S("Top-Left")..","..S("Middle-Right")..","..S("Middle-Left")..","..S("Bottom-Right")..","..S("Bottom-Left")..";"..ther_pos..";false]"..

        "tooltip[custom_ther_pos;"..S("Custom").."]"..
        "image_button[3.2,5;0.8,0.8;biometer_custom_btn.png;custom_ther_pos;;false;true]"..

        "tooltip[default_ther_pos;"..S("Set to Default").."]"..
        "image_button[4.2,5;0.8,0.8;biometer_default_btn.png;default_ther_pos;;false;true]"..

          "label[0,6.3;"..S("Hydration Bar Position")..":]"..
          "dropdown[0,6.5;3,0.8;hydr_bar_pos;"..hydr_bar_pos_custom..""..S("Hotbar-Top-Right")..","..S("Hotbar-Top-Left")..","..S("Hotbar-Middle-Right")..","..S("Hotbar-Middle-Left")..","..S("Hotbar-Bottom-Right")..","..S("Hotbar-Bottom-Left")..","..S("Hotbar-Right")..","..S("Hotbar-Left")..","..S("Top-Middle")..","..S("Top-Right")..","..S("Top-Left")..","..S("Middle-Right")..","..S("Middle-Left")..","..S("Bottom-Right")..","..S("Bottom-Left")..";"..hydr_bar_pos..";false]"..

          "tooltip[custom_hydr_bar_pos;"..S("Custom").."]"..
          "image_button[3.2,6.5;0.8,0.8;biometer_custom_btn.png;custom_hydr_bar_pos;;false;true]"..

          "tooltip[default_hydr_bar_pos;"..S("Set to Default").."]"..
          "image_button[4.2,6.5;0.8,0.8;biometer_default_btn.png;default_hydr_bar_pos;;false;true]"..
      "container_end[]"..

      "style[cancel;bgcolor=#FF0F1180]"..
      "button_exit[5.67,8.9;3,0.8;cancel;"..S("Cancel").."]"..
      "button[8.8,8.9;3,0.8;apply;"..S("Apply Changes").."]"
    )

    biometer.update_ui_ther(player, true, false, false)

    return formspec
  end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    if formname ~= "biometer:ui" then
      return false
    end

    local meta = player:get_meta()
    local player_name = player:get_player_name()
    local player_index = index[player:get_player_name()]

    local _temp_in = {[S("Celsius")] = "celsius", [S("Fahrenheit")] = "fahrenheit", [S("Kelvin")] = "kelvin"}

    if fields["r_"..player_index] or fields["g_"..player_index] or fields["b_"..player_index] then
      local r = tonumber(fields["r_"..player_index]:match("%d+"))
      local g = tonumber(fields["g_"..player_index]:match("%d+"))
      local b = tonumber(fields["b_"..player_index]:match("%d+"))

      meta:set_string("bm_ther_color_change", r..", "..g..", "..b)

      biometer.update_ui_ther(player, false, false, true)
    end

    if fields.default_color then
      meta:set_string("bm_ther_color_change", "196, 0, 0")

      minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
      biometer.update_ui_ther(player, false, false, true)
    end

    if fields.temp_in then
      meta:set_string("bm_temp_in", _temp_in[fields.temp_in])

      biometer.set_temp(player, "ignore_inner")
    end

    if fields.default_temp then
      meta:set_string("bm_temp_in", "celsius")

      minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
      biometer.update_ui_ther(player, false, false, true)
      biometer.set_temp(player)
    end

    if fields.hydr_bar_pos then
      if fields.hydr_bar_pos ~= "Custom" then
        for k, v in pairs(bm.hydr_bar_pos[cg]) do
          if type(v) ~= "number" and v.name == fields.hydr_bar_pos then
            meta:set_string("bm_hydr_bar_pos", v.pos)

            break
          end
        end
      else
        --nothing here yet
      end

      biometer.update_hydr_bar_pos(player)
    end

    if fields.custom_hydr_bar_pos then
      biometer.update_ui_ther(player, false, true, false)
      biometer.update_ther_color(player, "change")

      minetest.show_formspec(player_name, "biometer:ui_custom_hydr", biometer.get_custom_ui(player, "hydr_bar"))
    end

    if fields.default_hydr_bar_pos then
      meta:set_string("bm_hydr_bar_pos", bm.hydr_bar_pos[cg][bm.hydr_bar_pos[cg].default_pos].pos)

      minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
      biometer.update_ui_ther(player, false, false, true)
      biometer.update_hydr_bar_pos(player)
    end

    if fields.ther_pos then
      if fields.ther_pos ~= "Custom" then
        for k, v in pairs(bm.ther_pos[cg]) do
          if type(v) ~= "number" and v.name == fields.ther_pos then
            meta:set_string("bm_ther_pos", v.pos)

            break
          end
        end
      else
        --nothing here yet
      end

      biometer.update_ther_pos(player)
    end

    if fields.custom_ther_pos then
      biometer.update_ui_ther(player, false, true, false)
      biometer.update_ther_color(player, "change")

      minetest.show_formspec(player_name, "biometer:ui_custom_ther", biometer.get_custom_ui(player, "ther"))
    end

    if fields.default_ther_pos then
      meta:set_string("bm_ther_pos", bm.ther_pos[cg][bm.ther_pos[cg].default_pos].pos)

      minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
      biometer.update_ui_ther(player, false, false, true)
      biometer.update_ther_pos(player)
    end

    if fields.apply then
      minetest.close_formspec(player_name, formname)
      biometer.update_ui_ther(player, false, true, false)
      meta:set_string("bm_do_temp_dmg", "false")
      biometer.update_ther_color(player, "yes")
      biometer.update_hydr_bar_pos(player)
      biometer.update_ther_pos(player)
    end

    if fields.quit then
      meta:set_string("bm_temp_in", meta:get_string("bm_temp_in_old"))
      biometer.update_ui_ther(player, false, true, false)

      meta:set_string("bm_do_temp_dmg", "false")
      biometer.update_ther_color(player, "no")

      meta:set_string("bm_hydr_bar_pos", meta:get_string("bm_hydr_bar_pos_old"))
      biometer.update_hydr_bar_pos(player)
      meta:set_string("bm_ther_pos", meta:get_string("bm_ther_pos_old"))
      biometer.update_ther_pos(player)
      biometer.set_temp(player)
    end

    return true
  end
end)

function biometer.get_custom_ui(player, type)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()

    local formspec
    local obj

    if type == "hydr_bar" then
      obj = biometer.get_pos_from_string(meta:get_string("bm_hydr_bar_pos"))

      formspec = (
        "formspec_version[6]"..
        "size[6.8,7]"..
        "no_prepend[]"..

        "label[0.2,0.3;"..S("Hydration Bar Position").."]"..
        "field[0.2,1.4;3,0.8;xpos;X-"..S("Position")..":;"..obj.pos.x.."]"..
        "field[0.2,2.9;3,0.8;ypos;Y-"..S("Position")..":;"..obj.pos.y.."]"..
        "field[3.6,1.4;3,0.8;xoffset;X-"..S("Offset")..":;"..obj.offset.x.."]"..
        "field[3.6,2.9;3,0.8;yoffset;Y-"..S("Offset")..":;"..obj.offset.y.."]"..
        "label[0.3,4.3;"..S("Direction")..":]"..
        "dropdown[0.3,4.6;3,0.8;direction;"..S("Right")..","..S("Left")..";"..obj.direction + 1 ..";false]"..

        "style[cancel;bgcolor=#FF0F1180]"..
        "button[0.2,5.9;3,0.8;cancel;"..S("Cancel").."]"..
        "button[3.6,5.9;3,0.8;confirm;"..S("Confirm").."]"
      )
    elseif type == "ther" then
      obj = biometer.get_pos_from_string(meta:get_string("bm_ther_pos"))

      formspec = (
        "formspec_version[6]"..
        "size[6.8,5.3]"..
        "no_prepend[]"..

        "label[0.2,0.3;"..S("Thermometer Position").."]"..
        "field[0.2,1.4;3,0.8;xpos;X-"..S("Position")..":;"..obj.pos.x.."]"..
        "field[0.2,2.9;3,0.8;ypos;Y-"..S("Position")..":;"..obj.pos.y.."]"..
        "field[3.6,1.4;3,0.8;xoffset;X-"..S("Offset")..":;"..obj.offset.x.."]"..
        "field[3.6,2.9;3,0.8;yoffset;Y-"..S("Offset")..":;"..obj.offset.y.."]"..

        "style[cancel;bgcolor=#FF0F1180]"..
        "button[0.2,4.3;3,0.8;cancel;"..S("Cancel").."]"..
        "button[3.6,4.3;3,0.8;confirm;"..S("Confirm").."]"
      )
    end

    return formspec
  end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    if formname ~= "biometer:ui_custom_hydr" then
      return false
    end

    local meta = player:get_meta()
    local player_name = player:get_player_name()

    local hydr_bar = biometer.get_pos_from_string(meta:get_string("bm_hydr_bar_pos"))

    if fields.key_enter_field then
      meta:set_string("bm_hydr_bar_pos", (tonumber(fields.xpos) or 0)..","..(tonumber(fields.ypos) or 0)..","..(tonumber(fields.xoffset) or 0)..","..(tonumber(fields.yoffset) or 0)..","..hydr_bar.direction)

      biometer.update_hydr_bar_pos(player)

      minetest.after(0.04, function()
        minetest.show_formspec(player_name, "biometer:ui_custom_hydr", biometer.get_custom_ui(player, "hydr_bar"))
      end)
    end

    if fields.direction and not fields.key_enter_field then
      if fields.direction == S("Right") then
        meta:set_string("bm_hydr_bar_pos", hydr_bar.pos.x..","..hydr_bar.pos.y..","..hydr_bar.offset.x..","..hydr_bar.offset.y..",0")

        biometer.update_hydr_bar_pos(player)
      elseif fields.direction == S("Left") then
        meta:set_string("bm_hydr_bar_pos", hydr_bar.pos.x..","..hydr_bar.pos.y..","..hydr_bar.offset.x..","..hydr_bar.offset.y..",1")

        biometer.update_hydr_bar_pos(player)
      end
    end

    if fields.cancel then
      meta:set_string("bm_hydr_bar_pos", meta:get_string("bm_hydr_bar_pos_old"))
      biometer.update_hydr_bar_pos(player)
      biometer.update_ui_ther(player, false, false, true)

      minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
    end

    if fields.confirm then
      biometer.update_ui_ther(player, false, false, true)
      biometer.update_hydr_bar_pos(player)

      minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
    end

    if fields.quit and not fields.key_enter_field then
      minetest.after(0.04, function()
        meta:set_string("bm_hydr_bar_pos", meta:get_string("bm_hydr_bar_pos_old"))
        biometer.update_hydr_bar_pos(player)
        biometer.update_ui_ther(player, false, false, true)

        minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
      end)
    end

    return true
  end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    if formname ~= "biometer:ui_custom_ther" then
      return false
    end

    local meta = player:get_meta()
    local player_name = player:get_player_name()

    local ther = biometer.get_pos_from_string(meta:get_string("bm_ther_pos"))

    if fields.key_enter_field then
      meta:set_string("bm_ther_pos", (tonumber(fields.xpos) or 0)..","..(tonumber(fields.ypos) or 0)..","..(tonumber(fields.xoffset) or 0)..","..(tonumber(fields.yoffset) or 0)..","..ther.direction)

      biometer.update_ther_pos(player)

      minetest.after(0.04, function()
        minetest.show_formspec(player_name, "biometer:ui_custom_ther", biometer.get_custom_ui(player, "ther"))
      end)
    end

    if fields.cancel then
      meta:set_string("bm_ther_pos", meta:get_string("bm_ther_pos_old"))
      biometer.update_ther_pos(player)
      biometer.update_ui_ther(player, false, false, true)

      minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
    end

    if fields.confirm then
      biometer.update_ui_ther(player, false, false, true)
      biometer.update_ther_pos(player)

      minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
    end

    if fields.quit and not fields.key_enter_field then
      minetest.after(0.04, function()
        meta:set_string("bm_ther_pos", meta:get_string("bm_ther_pos_old"))
        biometer.update_ther_pos(player)
        biometer.update_ui_ther(player, false, false, true)

        minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, false))
      end)
    end

    return true
  end
end)

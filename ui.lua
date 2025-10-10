
--ui

local S = minetest.get_translator(minetest.get_current_modname())

local index = 0

minetest.register_chatcommand("bm", {
  description = "Opens the BM UI.",
  func = function(name)
    player = minetest.get_player_by_name(name)

    button_action(player)
end})

minetest.register_chatcommand("bm_reset", {
  description = "Resets the BM UI.",
  func = function(name)
    local player = minetest.get_player_by_name(name)
    local meta = player:get_meta()

    meta:set_string("bm_temp_in", meta:get_string("bm_temp_in_old"))
    update_ui_ther(player, false, true, false)
    update_ther_color(player, "no")
    set_temp(player)
    minetest.chat_send_player(name, "[BioMeter] UI reseted!")
end})

if minetest.global_exists("sfinv") then
  sfinv.register_page("biometer", {
    title = S("BioMeter"),
    get = function(self, player, context)
      return ""
    end,
    on_enter = function(self, player, context)
      sfinv.contexts[player:get_player_name()].page = sfinv.get_homepage_name(player)
      button_action(player)
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
      button_action(player)
    end
  })
end

if minetest.global_exists("unified_inventory") then
  unified_inventory.register_button("biometer", {
    type = "image",
    image = "biometer_icon.png",
    tooltip = "BioMeter",
    action = function(player)
      button_action(player)
    end
  })
end

if minetest.global_exists("i3") then
  i3.new_tab("biometer_test", {
    description = "BioMeter",
    fields = function(player, data, fields)
      i3.set_tab(player, "inventory")
      button_action(player)
    end
  })
end

minetest.register_on_joinplayer(function(player)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local id_bg = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0.5, y = 0.5},
      offset = {x = 0, y = 0},
      text = "biometer_bg.png^[opacity:0",
      alignment = {x = 0, y = 0},
      scale = {x = 48, y = 39},
      z_index = 9999
    })

    local id_r_text = player:hud_add({
      hud_elem_type = "text",
      position = {x = 0.5, y = 0.5},
      offset = {x = 20, y = -233},
      text = "",
      alignment = {x = 1, y = 0},
      scale = {x = 1, y = 1},
      number = 0x80FFFFFF,
      z_index = 10000
    })

    local id_g_text = player:hud_add({
      hud_elem_type = "text",
      position = {x = 0.5, y = 0.5},
      offset = {x = 20, y = -168},
      text = "",
      alignment = {x = 1, y = 0},
      scale = {x = 1, y = 1},
      number = 0xFFFFFF,
      z_index = 10000
    })

    local id_b_text = player:hud_add({
      hud_elem_type = "text",
      position = {x = 0.5, y = 0.5},
      offset = {x = 20, y = -103},
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
  update_ui_ther(player, false, true, false)
  update_ther_color(player, "no")
  set_temp(player)
end)

function get_ui(player, new)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local r, g, b
    local temp_in

    index = index + 1

    if meta:get_string("bm_temp_in") == "celsius" then
      temp_in = 1
    elseif meta:get_string("bm_temp_in") == "fahrenheit" then
      temp_in = 2
    elseif meta:get_string("bm_temp_in") == "kelvin" then
      temp_in = 3
    end

    if new then
      r, g, b = get_rgb(meta:get_string("bm_ther_color"))
      meta:set_string("bm_temp_in_old", meta:get_string("bm_temp_in"))
    else
      r, g, b = get_rgb(meta:get_string("bm_ther_color_change"))
    end

    meta:set_string("bm_do_temp_dmg", "true")

    formspec = (
      "formspec_version[6]"..
      "size[12,10]"..
      "no_prepend[]"..
      "bgcolor[#FFFFFF00;false]"..
      "label[0.2,0.4;BioMeter]"..

      "container[1.9,1.2]"..
      "scrollbaroptions[min=0;max=255;smallstep=1]"..

      "label[0,0.25;R]"..
      "box[0.3,0.01;3.99,0.48;#FF0000CC]"..
      "scrollbar[0.3,0;4,0.5;horizontal;r_"..index..";"..r.."]"..

      "label[0,1.25;G]"..
      "box[0.3,1.01;3.99,0.48;#00FF00CC]"..
      "scrollbar[0.3,1;4,0.5;horizontal;g_"..index..";"..g.."]"..

      "label[0,2.25;B]"..
      "box[0.3,2.01;3.99,0.48;#0000FFCC]"..
      "scrollbar[0.3,2;4,0.5;horizontal;b_"..index..";"..b.."]"..

      "button[0,2.9;2.5,0.7;default_color;"..S("Set to Default").."]"..

      "label[0,4.7;"..S("Temperature in")..":]"..
      "dropdown[0,4.9;3,0.8;temperature_in;Celsius,Fahrenheit,Kelvin;"..temp_in..";false]"..

      "button[0,6.1;2.5,0.7;default_temp;"..S("Set to Default").."]"..
      "container_end[]"..

      "style[cancel;bgcolor=#FF0F1180]"..
      "button_exit[5.67,8.9;3,0.8;cancel;"..S("Cancel").."]"..
      "button[8.8,8.9;3,0.8;apply;"..S("Apply Changes").."]"
    )

    update_ui_ther(player, true, false, false)

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

    if fields["r_"..index] or fields["g_"..index] or fields["b_"..index] then
      local r = tonumber(fields["r_"..index]:match("%d+"))
      local g = tonumber(fields["g_"..index]:match("%d+"))
      local b = tonumber(fields["b_"..index]:match("%d+"))
      meta:set_string("bm_ther_color_change", r..", "..g..", "..b)
      update_ui_ther(player, false, false, true)
    end

    if fields.default_color then
      meta:set_string("bm_ther_color_change", "196, 0, 0")
      minetest.show_formspec(player_name, "biometer:ui", get_ui(player, false))
      update_ui_ther(player, false, false, true)
    end

    if fields.temperature_in then
      if fields.temperature_in == "Celsius" then
        meta:set_string("bm_temp_in", "celsius")
        set_temp(player)
      elseif fields.temperature_in == "Fahrenheit" then
        meta:set_string("bm_temp_in", "fahrenheit")
        set_temp(player)
      elseif fields.temperature_in == "Kelvin" then
        meta:set_string("bm_temp_in", "kelvin")
        set_temp(player)
      end
    end

    if fields.default_temp then
      meta:set_string("bm_temp_in", "celsius")
      minetest.show_formspec(player_name, "biometer:ui", get_ui(player, false))
      update_ui_ther(player, false, false, true)
      set_temp(player)
    end

    if fields.apply then
      minetest.close_formspec(player_name, formname)
      update_ui_ther(player, false, true, false)
      meta:set_string("bm_do_temp_dmg", "false")
      update_ther_color(player, "yes")
      return true
    end

    if fields.quit then
      meta:set_string("bm_temp_in", meta:get_string("bm_temp_in_old"))
      update_ui_ther(player, false, true, false)
      meta:set_string("bm_do_temp_dmg", "false")
      update_ther_color(player, "no")
      set_temp(player)
    end

    return true
  end
end)

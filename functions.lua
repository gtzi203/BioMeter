
--functions

biometer = {}
bm = {}

local S = minetest.get_translator(minetest.get_current_modname())

local hydration_damage = minetest.settings:get_bool("biometer.hydration_damage") ~= false
local heat_damage = minetest.settings:get_bool("biometer.heat_damage") ~= false
local freeze_damage = minetest.settings:get_bool("biometer.freeze_damage") ~= false

local decimal = 10 ^ 1
local radius = 2

local ther_min = -20
local ther_max = 50
local ther_scale_min = 0
local ther_scale_max = 8
local ther_off_x = -100
local ther_off_y = 0

local temp_y_up_max = 500
local temp_y_down_max = 600

bm.ui_state = {}

bm.hud_alignments = {
  [1] = {alignment = "left", pos = {x = 0, y = 0}, ofs = {x = 1, y = 1}, rot = 0},
  [2] = {alignment = "right", pos = {x = 1, y = 0}, ofs = {x = -1, y = 1}, rot = 0},
  [3] = {alignment = "left", pos = {x = 1, y = 1}, ofs = {x = -1, y = -1}, rot = 180},
  [4] = {alignment = "right", pos = {x = 0, y = 1}, ofs = {x = 1, y = -1}, rot = 180}
}

hydr_bar_params = {
  hotbar_offset = {
    ["mtg"] = {
      dy = -88,
      xr = 241,
      xl = -265,
      y = 22
    },
    ["mc"] = {
      dy = -110,
      xr = 232.5,
      xl = -256,
      y = 28
    }
  }
}

bm.hydr_bar_pos = {
  ["minetest_game"] = {
    default_pos = 3,
    [1] = {name = S("Hotbar-Top-Right"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mtg"].xr..","..hydr_bar_params.hotbar_offset["mtg"].dy - hydr_bar_params.hotbar_offset["mtg"].y * 2 ..",1"},
    [2] = {name = S("Hotbar-Top-Left"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mtg"].xl..","..hydr_bar_params.hotbar_offset["mtg"].dy - hydr_bar_params.hotbar_offset["mtg"].y * 2 ..",0"},
    [3] = {name = S("Hotbar-Middle-Right"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mtg"].xr..","..hydr_bar_params.hotbar_offset["mtg"].dy - hydr_bar_params.hotbar_offset["mtg"].y..",1"},
    [4] = {name = S("Hotbar-Middle-Left"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mtg"].xl..","..hydr_bar_params.hotbar_offset["mtg"].dy - hydr_bar_params.hotbar_offset["mtg"].y..",0"},
    [5] = {name = S("Hotbar-Bottom-Right"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mtg"].xr..","..hydr_bar_params.hotbar_offset["mtg"].dy..",1"},
    [6] = {name = S("Hotbar-Bottom-Left"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mtg"].xl..","..hydr_bar_params.hotbar_offset["mtg"].dy..",0"},
    [7] = {name = S("Hotbar-Right"), pos = "0.5,1,237,-28,0"},
    [8] = {name = S("Hotbar-Left"), pos = "0.5,1,-260,-28,1"},
    [9] = {name = S("Top-Middle"), pos = "0.5,0,".. 12 * 5 * -1 - 54 ..",25,0"},  --i had to add a small offset (-54), because statbars are positioned weirdly :(
    [10] = {name = S("Top-Right"), pos = "1,0,".. 12 * 5 - 111 ..",25,1"},
    [11] = {name = S("Top-Left"), pos = "0,0,".. 12 * 5 * -1 + 81 ..",25,0"},
    [12] = {name = S("Middle-Right"), pos = "1,0.5,".. 12 * 5 - 111 ..",-49,1"},
    [13] = {name = S("Middle-Left"), pos = "0,0.5,".. 12 * 5 * -1 + 81 ..",-49,0"},
    [14] = {name = S("Bottom-Right"), pos = "1,1,".. 12 * 5 - 111 ..",-49,1"},
    [15] = {name = S("Bottom-Left"), pos = "0,1,".. 12 * 5 * -1 + 81 ..",-49,0"}
  },
  ["mineclone"] = {
    default_pos = 4,
    [1] = {name = S("Hotbar-Top-Right"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mc"].xr..","..hydr_bar_params.hotbar_offset["mc"].dy - hydr_bar_params.hotbar_offset["mc"].y * 2 ..",1"},
    [2] = {name = S("Hotbar-Top-Left"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mc"].xl..","..hydr_bar_params.hotbar_offset["mc"].dy - hydr_bar_params.hotbar_offset["mc"].y * 2 ..",0"},
    [3] = {name = S("Hotbar-Middle-Right"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mc"].xr..","..hydr_bar_params.hotbar_offset["mc"].dy - hydr_bar_params.hotbar_offset["mc"].y..",1"},
    [4] = {name = S("Hotbar-Middle-Left"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mc"].xl..","..hydr_bar_params.hotbar_offset["mc"].dy - hydr_bar_params.hotbar_offset["mc"].y..",0"},
    [5] = {name = S("Hotbar-Bottom-Right"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mc"].xr..","..hydr_bar_params.hotbar_offset["mc"].dy..",1"},
    [6] = {name = S("Hotbar-Bottom-Left"), pos = "0.5,1,"..hydr_bar_params.hotbar_offset["mc"].xl..","..hydr_bar_params.hotbar_offset["mc"].dy..",0"},
    [7] = {name = S("Hotbar-Right"), pos = "0.5,1,267,-29,0"},
    [8] = {name = S("Hotbar-Left"), pos = "0.5,1,-290,-29,1"},
    [9] = {name = S("Top-Middle"), pos = "0.5,0,".. 12 * 5 * -1 - 54 ..",25,0"},
    [10] = {name = S("Top-Right"), pos = "1,0,".. 12 * 5 - 111 ..",25,1"},
    [11] = {name = S("Top-Left"), pos = "0,0,".. 12 * 5 * -1 + 81 ..",25,0"},
    [12] = {name = S("Middle-Right"), pos = "1,0.5,".. 12 * 5 - 111 ..",-49,1"},
    [13] = {name = S("Middle-Left"), pos = "0,0.5,".. 12 * 5 * -1 + 81 ..",-49,0"},
    [14] = {name = S("Bottom-Right"), pos = "1,1,".. 12 * 5 - 111 ..",-49,1"},
    [15] = {name = S("Bottom-Left"), pos = "0,1,".. 12 * 5 * -1 + 81 ..",-49,0"}
  }
}

bm.ther_pos = {
  ["minetest_game"] = {
    default_pos = 8,
    [1] = {name = S("Hotbar-Right"), pos = "0.5,1,320,-110,-0"},
    [2] = {name = S("Hotbar-Left"), pos = "0.5,1,-320,-110,-0"},
    [3] = {name = S("Top-Middle"), pos = "0.5,0,0,165,-0"},
    [4] = {name = S("Top-Right"), pos = "1,0,-75,165,-0"},
    [5] = {name = S("Top-Left"), pos = "0,0,75,165,-0"},
    [6] = {name = S("Middle-Right"), pos = "1,0.5,-75,-30,-0"},
    [7] = {name = S("Middle-Left"), pos = "0,0.5,75,-30,-0"},
    [8] = {name = S("Bottom-Right"), pos = "1,1,-75,-135,-0"},
    [9] = {name = S("Bottom-Left"), pos = "0,1,75,-135,-0"}
  },
  ["mineclone"] = {
    default_pos = 8,
    [1] = {name = S("Hotbar-Right"), pos = "0.5,1,320,-110,-0"},
    [2] = {name = S("Hotbar-Left"), pos = "0.5,1,-320,-110,-0"},
    [3] = {name = S("Top-Middle"), pos = "0.5,0,0,165,-0"},
    [4] = {name = S("Top-Right"), pos = "1,0,-75,165,-0"},
    [5] = {name = S("Top-Left"), pos = "0,0,75,165,-0"},
    [6] = {name = S("Middle-Right"), pos = "1,0.5,-75,-30,-0"},
    [7] = {name = S("Middle-Left"), pos = "0,0.5,75,-30,-0"},
    [8] = {name = S("Bottom-Right"), pos = "1,1,-75,-135,-0"},
    [9] = {name = S("Bottom-Left"), pos = "0,1,75,-135,-0"}
  }
}

function biometer.button_action(player)
  player_name = player:get_player_name()
  if not minetest.is_creative_enabled(player:get_player_name()) then
    minetest.show_formspec(player_name, "biometer:ui", biometer.get_ui(player, true))
  else
    minetest.chat_send_player(player_name, "[BioMeter] "..S("This is only for survival mode")..".")
  end
end

function biometer.current_biome(player)
  local biome_data = minetest.get_biome_data(player:get_pos())

  return {name = minetest.get_biome_name(biome_data.biome), humidity = biome_data.humidity, heat = biome_data.heat}
end

function biometer.get_pos_from_string(str)
  local parts = {}
  for value in string.gmatch(str, "([^,]+)") do
    parts[#parts + 1] = tonumber(value)
  end

  if #parts ~= 5 then
    return
  end

  return {
    pos = {x = parts[1], y = parts[2]},
    offset = {x = parts[3], y = parts[4]},
    direction = parts[5]
  }
end

function biometer.calc_temp(player, base)
  local meta = player:get_meta()
  local biome = biometer.current_biome(player)
  local temp_r = 0

  if base then
    local temp_r = (biome.heat / 100) * 50 - 10

    temp_r = math.floor(temp_r * decimal + 0.5) / decimal
    meta:set_float("bm_temp_base", temp_r)
    return temp_r
  else
    local player_pos = player:get_pos()
    local minp = {x = player_pos.x - radius, y = player_pos.y - radius, z = player_pos.z - radius}
    local maxp = {x = player_pos.x + radius, y = player_pos.y + radius, z = player_pos.z + radius}

    local extra_temp = 0
    local positions_heat, counts_heat = minetest.find_nodes_in_area(minp, maxp, heat_nodes)
    for name, count in pairs(counts_heat) do
      extra_temp = heat_nodes_counts[name]
      if extra_temp then
        temp_r = temp_r + extra_temp * count
      end
    end
    extra_temp = 0
    local positions_freeze, counts_freeze = minetest.find_nodes_in_area(minp, maxp, freeze_nodes)
    for name, count in pairs(counts_freeze) do
      extra_temp = freeze_nodes_counts[name]
      if extra_temp then
        temp_r = temp_r + extra_temp * count
      end
    end

    if player_pos.y <= temp_y_up_max and player_pos.y >= temp_y_down_max * -1 then
      temp_r = temp_r + (player_pos.y * -1 * 0.03)
    else
      if player_pos.y >= 0 then
        temp_r = temp_r + (temp_y_up_max * -1 * 0.03)
      else
        temp_r = temp_r + (temp_y_down_max * 0.03)
      end
    end

    local tod = minetest.get_timeofday()
    if tod >= 0.2 and tod < 0.4 then
      temp_r = temp_r - 4.5
    elseif tod >= 0.4 and tod < 0.7 then
      temp_r = temp_r
    elseif tod >= 0.7 and tod < 0.85 then
      temp_r = temp_r - 4.5
    else
      temp_r = temp_r - 8
    end

    temp_r = math.floor(temp_r * decimal + 0.5) / decimal
    meta:set_float("bm_temp", temp_r)
    return temp_r
  end
end

function biometer.update_hydr_bar_pos(player)
  local meta = player:get_meta()

  local id = meta:get_string("bm_hydr_bar_id")
  local hydr_bar = biometer.get_pos_from_string(meta:get_string("bm_hydr_bar_pos"))

  player:hud_change(id, "position", {x = hydr_bar.pos.x, y = hydr_bar.pos.y})
  player:hud_change(id, "offset", {x = hydr_bar.offset.x, y = hydr_bar.offset.y})
  player:hud_change(id, "direction", hydr_bar.direction)
end

function biometer.update_ther_pos(player)
  local meta = player:get_meta()
  local player_name = player:get_player_name()

  local temp_dis_id = meta:get_string("bm_temp_dis_id")
  local ther_dis_id = meta:get_string("bm_temp_dis_ther_id")
  local ther_dis_inner_id = meta:get_string("bm_temp_dis_ther_inner_id")
  local ther_dis_inner_down_id = meta:get_string("bm_temp_dis_ther_inner_down_id")
  local ther = biometer.get_pos_from_string(meta:get_string("bm_ther_pos"))

  player:hud_change(temp_dis_id, "position", {x = ther.pos.x, y = ther.pos.y})
  player:hud_change(temp_dis_id, "offset", {x = ther.offset.x, y = ther.offset.y - 130})

  player:hud_change(ther_dis_id, "position", {x = ther.pos.x, y = ther.pos.y})
  player:hud_change(ther_dis_id, "offset", {x = ther.offset.x, y = ther.offset.y})

  player:hud_change(ther_dis_inner_id, "position", {x = ther.pos.x, y = ther.pos.y})
  player:hud_change(ther_dis_inner_id, "offset", {x = ther.offset.x, y = ther.offset.y})

  bm.ui_state[player_name].ther_off_x = ther.offset.x
  bm.ui_state[player_name].ther_off_y = ther.offset.y + 125.5

  player:hud_change(ther_dis_inner_down_id, "position", {x = ther.pos.x, y = ther.pos.y})
  player:hud_change(ther_dis_inner_down_id, "offset", {x = ther.offset.x, y = ther.offset.y})

  biometer.set_temp(player)
end

function biometer.update_temp(player, temp)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local id = ""
    local cur_id = ""
    if temp >= 40 and temp <= 60 then
      id = meta:get_string("bm_ther_heat_id")
      player:hud_change(id, "text", "biometer_thermometer_heat.png^[opacity:"..(temp - 39) * 7)
      for i = 1, 4, 1 do
        cur_id = meta:get_string("bm_heat_"..i.."_id")
        player:hud_change(cur_id, "text", "biometer_heat_"..bm.hud_alignments[i].alignment..".png^[transformR"..bm.hud_alignments[i].rot.."^[opacity:"..(temp - 39) * 11)
      end
    elseif temp <= 0 and temp >= -15 then
      id = meta:get_string("bm_ther_freeze_id")
      player:hud_change(id, "text", "biometer_thermometer_freeze.png^[opacity:"..((temp + 4) * -1) * 9)
      for i = 1, 4, 1 do
        cur_id = meta:get_string("bm_freeze_"..i.."_id")
        player:hud_change(cur_id, "text", "biometer_freeze_"..bm.hud_alignments[i].alignment..".png^[transformR"..bm.hud_alignments[i].rot.."^[opacity:"..(temp * -1) * 15)
      end
    elseif temp > 60 or temp < -15 then
      if temp > 60 then
        temp = 61
        id = meta:get_string("bm_ther_heat_id")
        player:hud_change(id, "text", "biometer_thermometer_heat.png^[opacity:"..(temp - 39) * 7)
        for i = 1, 4, 1 do
          cur_id = meta:get_string("bm_heat_"..i.."_id")
          player:hud_change(cur_id, "text", "biometer_heat_"..bm.hud_alignments[i].alignment..".png^[transformR"..bm.hud_alignments[i].rot.."^[opacity:"..(temp - 39) * 11)
        end
      elseif temp < -15 then
        temp = -16
        id = meta:get_string("bm_ther_freeze_id")
        player:hud_change(id, "text", "biometer_thermometer_freeze.png^[opacity:"..((temp + 4) * -1) * 9)
        for i = 1, 4, 1 do
          cur_id = meta:get_string("bm_freeze_"..i.."_id")
          player:hud_change(cur_id, "text", "biometer_freeze_"..bm.hud_alignments[i].alignment..".png^[transformR"..bm.hud_alignments[i].rot.."^[opacity:"..((temp + 4) * -1) * 15)
        end
      end
      if meta:get_string("bm_do_temp_dmg") == "false" then
        local hp = player:get_hp()

        if temp > 0 and heat_damage then
          player:set_hp(hp - 4)
        elseif temp < 0 and freeze_damage then
          player:set_hp(hp - 4)
        end
      end
    else
      local id_heat = meta:get_string("bm_ther_heat_id")
      player:hud_change(id_heat, "text", "biometer_thermometer_heat.png^[opacity:0")
      for i = 1, 4, 1 do
        cur_id = meta:get_string("bm_heat_"..i.."_id")
        player:hud_change(cur_id, "text", "biometer_heat_"..bm.hud_alignments[i].alignment..".png^[transformR"..bm.hud_alignments[i].rot.."^[opacity:0")
      end
      local id_freeze = meta:get_string("bm_ther_freeze_id")
      player:hud_change(id_freeze, "text", "biometer_thermometer_freeze.png^[opacity:0")
      for i = 1, 4, 1 do
        cur_id = meta:get_string("bm_freeze_"..i.."_id")
        player:hud_change(cur_id, "text", "biometer_freeze_"..bm.hud_alignments[i].alignment..".png^[transformR"..bm.hud_alignments[i].rot.."^[opacity:0")
      end
    end
  end
end

function biometer.rgb_to_hex(r, g, b)
  return string.format("%02X%02X%02X", r, g, b)
end

function biometer.get_rgb(v)
  v = v:gsub("%s", "")

  local r,g,b = v:match("^(%d+),(%d+),(%d+)$")
  r, g, b = tonumber(r), tonumber(g), tonumber(b)

  return r, g, b
end

function biometer.update_ui_ther(player, big, small, update_color)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local player_name = player:get_player_name()
    local meta = player:get_meta()

    --[[bm.ui_state[player_name] = bm.ui_state[player_name] or {
      ther_off_x = -100,
      ther_off_y = 0,
      ther_scale_max = 8
    }--]]

    local r, g, b = biometer.get_rgb(meta:get_string("bm_ther_color"))
    local id_bg = meta:get_string("bm_bg_id")
    local id_r_text = meta:get_string("bm_r_text_id")
    local id_g_text = meta:get_string("bm_g_text_id")
    local id_b_text = meta:get_string("bm_b_text_id")
    local id = meta:get_string("bm_temp_dis_id")
    local id_ther = meta:get_string("bm_temp_dis_ther_id")
    local id_ther_inner = meta:get_string("bm_temp_dis_ther_inner_id")
    local id_ther_inner_down = meta:get_string("bm_temp_dis_ther_inner_down_id")
    local id_big = meta:get_string("bm_temp_dis_big_id")
    local id_ther_big = meta:get_string("bm_temp_dis_big_ther_id")
    local id_ther_big_inner = meta:get_string("bm_temp_dis_big_ther_inner_id")
    local id_ther_big_inner_down = meta:get_string("bm_temp_dis_big_ther_inner_down_id")

    if big then
      --[[bm.ui_state[player_name].ther_off_x = -747
      bm.ui_state[player_name].ther_off_y = -393.5
      bm.ui_state[player_name].ther_scale_max = 16--]]

      player:hud_change(id_bg, "text", "biometer_bg.png^[opacity:255")

      player:hud_change(id_big, "position", {x = 1, y = 1})
      player:hud_change(id_ther_big, "position", {x = 1, y = 1})
      player:hud_change(id_ther_big_inner, "position", {x = 1, y = 1})
      player:hud_change(id_ther_big_inner_down, "position", {x = 1, y = 1})

      --[[player:hud_change(id, "offset", {x = -747, y = -795})
      player:hud_change(id, "z_index", 10003)

      player:hud_change(id_ther, "offset", {x = -747, y = -550})
      player:hud_change(id_ther, "scale", {x = 16, y = 16})
      player:hud_change(id_ther, "z_index", 10003)

      player:hud_change(id_ther_inner, "offset", {x = bm.ui_state[player_name].ther_off_x, y = -550})
      player:hud_change(id_ther_inner, "scale", {x = 16, y = 16})
      player:hud_change(id_ther_inner, "z_index", 10001)

      player:hud_change(id_ther_inner_down, "offset", {x = -747, y = -550})
      player:hud_change(id_ther_inner_down, "scale", {x = 16, y = 16})
      player:hud_change(id_ther_inner_down, "z_index", 10002)--]]

      player:hud_change(id_r_text, "text", r)
      player:hud_change(id_g_text, "text", g)
      player:hud_change(id_b_text, "text", b)

      biometer.set_temp(player)
    end

    if small then
      --[[bm.ui_state[player_name].ther_off_x = -100
      bm.ui_state[player_name].ther_off_y = 0
      bm.ui_state[player_name].ther_scale_max = 8--]]

      player:hud_change(id_bg, "text", "biometer_bg.png^[opacity:0")

      player:hud_change(id_big, "position", {x = 9999, y = 9999})
      player:hud_change(id_ther_big, "position", {x = 9999, y = 9999})
      player:hud_change(id_ther_big_inner, "position", {x = 9999, y = 9999})
      player:hud_change(id_ther_big_inner_down, "position", {x = 9999, y = 9999})

      --[[player:hud_change(id, "offset", {x = -100, y = -255})
      player:hud_change(id, "z_index", 5)

      player:hud_change(id_ther, "offset", {x = -100, y = -125})
      player:hud_change(id_ther, "scale", {x = 8, y = 8})
      player:hud_change(id_ther, "z_index", 5)

      player:hud_change(id_ther_inner, "offset", {x = -100, y = -125})
      player:hud_change(id_ther_inner, "scale", {x = 8, y = 8})
      player:hud_change(id_ther_inner, "z_index", 3)

      player:hud_change(id_ther_inner_down, "offset", {x = -100, y = -125})
      player:hud_change(id_ther_inner_down, "scale", {x = 8, y = 8})
      player:hud_change(id_ther_inner_down, "z_index", 4)--]]

      player:hud_change(id_r_text, "text", "")
      player:hud_change(id_g_text, "text", "")
      player:hud_change(id_b_text, "text", "")

      biometer.update_ther_pos(player)

      biometer.set_temp(player)
    end

    if update_color then
      biometer.update_ther_color(player, "change")

      r, g, b = biometer.get_rgb(meta:get_string("bm_ther_color_change"))
      player:hud_change(id_r_text, "text", r)
      player:hud_change(id_g_text, "text", g)
      player:hud_change(id_b_text, "text", b)
    end
  end
end

function biometer.update_ther_color(player, set_as_new)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local id = meta:get_string("bm_temp_dis_ther_inner_id")
    local id_down = meta:get_string("bm_temp_dis_ther_inner_down_id")
    local id_big = meta:get_string("bm_temp_dis_big_ther_inner_id")
    local id_down_big = meta:get_string("bm_temp_dis_big_ther_inner_down_id")
    local r, g, b = biometer.get_rgb(meta:get_string("bm_ther_color"))
    if set_as_new == "yes" then
      meta:set_string("bm_ther_color", meta:get_string("bm_ther_color_change"))
      r, g, b = biometer.get_rgb(meta:get_string("bm_ther_color"))
    elseif set_as_new == "change" then
      r, g, b = biometer.get_rgb(meta:get_string("bm_ther_color_change"))
    end

    player:hud_change(id, "text", "biometer_thermometer_inner.png^[multiply:#"..biometer.rgb_to_hex(r, g, b))
    player:hud_change(id_down, "text", "biometer_thermometer_inner_down.png^[multiply:#"..biometer.rgb_to_hex(r, g, b))

    player:hud_change(id_big, "text", "biometer_thermometer_inner.png^[multiply:#"..biometer.rgb_to_hex(r, g, b))
    player:hud_change(id_down_big, "text", "biometer_thermometer_inner_down.png^[multiply:#"..biometer.rgb_to_hex(r, g, b))
  end
end

function biometer.update_ther_inner(player, temp)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local player_name = player:get_player_name()
    local meta = player:get_meta()
    local id = meta:get_string("bm_temp_dis_ther_inner_id")
    local id_big = meta:get_string("bm_temp_dis_big_ther_inner_id")

    if temp < ther_min then
      temp = ther_min
    end

    if temp > ther_max then
      temp = ther_max
    end

    local scale_y = (temp - ther_min) / (ther_max - ther_min) * (bm.ui_state[player_name].ther_scale_max - ther_scale_min) + ther_scale_min
    local scale_y_big = (temp - ther_min) / (ther_max - ther_min) * (bm.ui_state[player_name].ther_scale_max * 2 - ther_scale_min) + ther_scale_min
    player:hud_change(id, "scale", {x = bm.ui_state[player_name].ther_scale_max, y = scale_y})
    player:hud_change(id_big, "scale", {x = bm.ui_state[player_name].ther_scale_max * 2, y = scale_y_big})

    local base_offset_y = -94
    local offset_y = base_offset_y - (scale_y * 3.9)
    local offset_y_big = base_offset_y - (scale_y_big * 3.9)

    player:hud_change(id, "offset", {x = bm.ui_state[player_name].ther_off_x, y = offset_y + bm.ui_state[player_name].ther_off_y})
    player:hud_change(id_big, "offset", {x = -747, y = offset_y_big - 393.5})
  end
end

function biometer.set_temp(player, temp)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local id = meta:get_string("bm_temp_dis_id")
    local id_big = meta:get_string("bm_temp_dis_big_id")
    local ignore_inner = false
    if temp == "ignore_inner" then
      ignore_inner = true
      temp = false
    end
    if not temp then
      local temp_base = meta:get_float("bm_temp_base")
      local temp_extra = meta:get_float("bm_temp")
      temp = temp_base + temp_extra
    end
    if id and temp then
      --temp = -13.2
      local temp_sym = "°C"
      local display_temp = temp

      if meta:get_string("bm_temp_in") == "fahrenheit" then
        display_temp = math.floor((temp * 9 / 5 + 32) * decimal + 0.5) / decimal
        temp_sym = "°F"
      elseif meta:get_string("bm_temp_in") == "kelvin" then
        display_temp = math.floor((temp + 273.15) * decimal + 0.5) / decimal
        temp_sym = "K"
      end

      player:hud_change(id, "text", display_temp..temp_sym)
      player:hud_change(id_big, "text", display_temp..temp_sym)
      biometer.update_temp(player, temp)
      if not ignore_inner then
        biometer.update_ther_inner(player, temp)
      end
    end
  end
end

function biometer.update_hydr(player)
  local meta = player:get_meta()
  local id = meta:get_string("bm_hydr_black_id")
  local current_value = meta:get_int("bm_hydr_bar_value")

  if current_value <= 4 then
    player:hud_change(id, "text", "biometer_hydration_black.png^[opacity:"..((current_value - 5) * -1) * 55 + ((current_value - 1) * 5))
  else
    player:hud_change(id, "text", "biometer_hydration_black.png^[opacity:0")
  end
end

function biometer.set_hydr_bar(player, respawn, value)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local temp_base = meta:get_float("bm_temp_base")
    local temp_extra = meta:get_float("bm_temp")
    local temp = temp_base + temp_extra
    local id = meta:get_string("bm_hydr_bar_id")
    local current_value = meta:get_int("bm_hydr_bar_value")

    if current_value > 1 and current_value <= 20 and not respawn and not value then
      if temp < 1 and temp >= 0 then
        temp = 1
      end
      if temp < 0 then
        temp = temp * -1
      end
      if temp > 50 then
        temp = 50
      end

      local half_drop_chance = math.min(80, temp * 0.7)   -- vorher 1.5 → sanfter
      local full_drop_chance = math.min(50, temp * 0.5)   -- vorher 1.0 → sanfter

      if math.random(100) <= half_drop_chance then
          current_value = current_value - 1
          if math.random(100) <= full_drop_chance then
              current_value = current_value - 1
          end
      end

      if current_value < 1 then
          current_value = 1
      elseif current_value > 20 then
          current_value = 20
      end
      meta:set_int("bm_hydr_bar_value", current_value)
      player:hud_change(id, "number", current_value)
    elseif current_value < 2 and not respawn and not value then
      local hp = player:get_hp()

      if hydration_damage then
        player:set_hp(hp - 3)
      end
    elseif respawn and not value then
      player:hud_change(id, "number", current_value)
    elseif value then
      if respawn then
        if current_value + value < 1 then
          value = 0
          current_value = 1
        elseif current_value + value > 20 then
          value = 0
          current_value = 20
        end
        player:hud_change(id, "number", current_value + value)
        meta:set_int("bm_hydr_bar_value", current_value + value)
      else
        current_value = value
        player:hud_change(id, "number", current_value)
        meta:set_int("bm_hydr_bar_value", current_value)
      end
    end
    biometer.update_hydr(player)
  end
end

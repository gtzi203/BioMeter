
--temperature_display

local S = minetest.get_translator(minetest.get_current_modname())

local timer_n = 0
local timer_b = 0
local timer_e = 0
local interval_n = 20
local interval_b = 5
local interval_e = 2

minetest.register_on_joinplayer(function(player)
  local meta = player:get_meta()
  local player_name = player:get_player_name()

  local default_ther_pos = bm.ther_pos[cg][bm.ther_pos[cg].default_pos].pos

  meta:set_string("bm_ther_pos", meta:get_string("bm_ther_pos") ~= "" and meta:get_string("bm_ther_pos") or default_ther_pos)
  meta:set_string("bm_ther_pos_old", meta:get_string("bm_ther_pos_old") ~= "" and meta:get_string("bm_ther_pos_old") or default_ther_pos)

  bm.ui_state[player_name] = {ther_off_x = -100, ther_off_y = 0, ther_scale_max = 8}

  --meta:set_string("bm_ther_pos", default_ther_pos)
  --meta:set_string("bm_ther_pos_old", default_ther_pos)

  if not minetest.is_creative_enabled(player_name) then
    local meta = player:get_meta()
    local id_ther_heat = {}
    local id_ther_freeze = {}
    local id_cur_heat = ""
    local id_cur_freeze = ""

    local id = player:hud_add({
      hud_elem_type = "text",
      position = {x = 0, y = 0},
      offset = {x = 0, y = 0},
      text = "--°?",
      alignment = {x = 0, y = 0},
      scale = {x = 0, y = 0},
      number = 0xFFFFFF,
      z_index = 5
    })
    local id_ther = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0, y = 0},
      offset = {x = 0, y = 0},
      text = "biometer_thermometer_"..cg..".png",
      alignment = {x = 0, y = 0},
      scale = {x = 8, y = 8},
      z_index = 5
    })
    local id_ther_inner_down = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0, y = 0},
      offset = {x = 0, y = 0},
      text = "biometer_thermometer_inner_down.png^[multiply:#FFFFFF",
      alignment = {x = 0, y = 0},
      scale = {x = 8, y = 8},
      z_index = 4
    })
    local id_ther_inner = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0, y = 0},
      offset = {x = 0, y = 0},
      text = "biometer_thermometer_inner.png^[multiply:#FFFFFF",
      alignment = {x = 0, y = 0},
      scale = {x = 8, y = 0},
      z_index = 3
    })
    local id_big = player:hud_add({
      hud_elem_type = "text",
      position = {x = 9999, y = 9999},
      offset = {x = -747, y = -805},
      text = "--?°",
      alignment = {x = 0, y = 0},
      scale = {x = 0, y = 0},
      size = {x = 2, y = 2},
      number = 0xFFFFFF,
      z_index = 10003
    })
    local id_ther_big = player:hud_add({
      hud_elem_type = "image",
      position = {x = 9999, y = 9999},
      offset = {x = -747, y = -550},
      text = "biometer_thermometer_"..cg..".png^[opacity:255",
      alignment = {x = 0, y = 0},
      scale = {x = 16, y = 16},
      z_index = 10003
    })
    local id_ther_big_inner_down = player:hud_add({
      hud_elem_type = "image",
      position = {x = 9999, y = 9999},
      offset = {x = -747, y = -550},
      text = "biometer_thermometer_inner_down.png^[multiply:#FFFFFF^[opacity:255",
      alignment = {x = 0, y = 0},
      scale = {x = 16, y = 16},
      z_index = 10002
    })
    local id_ther_big_inner = player:hud_add({
      hud_elem_type = "image",
      position = {x = 9999, y = 9999},
      offset = {x = -747, y = -550},
      text = "biometer_thermometer_inner.png^[multiply:#FFFFFF^[opacity:255",
      alignment = {x = 0, y = 0},
      scale = {x = 16, y = 16},
      z_index = 10001
    })
    for k, v in pairs(bm.hud_alignments) do
      id_cur_heat = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0 + v.pos.x, y = 0 + v.pos.y},
        offset = {x = 216 * v.ofs.x, y = 216 * v.ofs.y},
        text = "biometer_heat_"..v.alignment..".png^[transformR"..v.rot.."^[opacity:0",
        alignment = {x = 0, y = 0},
        scale = {x = 9, y = 9},
        z_index = 2
      })
      id_cur_heat = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0 + v.pos.x, y = 0 + v.pos.y},
        offset = {x = 216 * v.ofs.x, y = 216 * v.ofs.y},
        text = "biometer_freeze_"..v.alignment..".png^[transformR"..v.rot.."^[opacity:0",
        alignment = {x = 0, y = 0},
        scale = {x = 9, y = 9},
        z_index = 2
      })
      meta:set_string("bm_heat_"..k.."_id", id_cur_heat)
      meta:set_string("bm_freeze_"..k.."_id", id_cur_heat)
    end
    id_ther_heat = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0.5, y = 0.5},
      scale = {x = -100, y = -100},
      text = "biometer_thermometer_heat.png^[opacity:0",
      z_index = 1
    })
    id_ther_freeze = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0.5, y = 0.5},
      scale = {x = -100, y = -100},
      text = "biometer_thermometer_freeze.png^[opacity:0",
      z_index = 1
    })

    meta:set_string("bm_cur_biome", biometer.current_biome(player).name)
    meta:set_string("bm_temp_dis_id", id)
    meta:set_string("bm_temp_dis_ther_id", id_ther)
    meta:set_string("bm_temp_dis_ther_inner_id", id_ther_inner)
    meta:set_string("bm_temp_dis_ther_inner_down_id", id_ther_inner_down)
    meta:set_string("bm_temp_dis_big_id", id_big)
    meta:set_string("bm_temp_dis_big_ther_id", id_ther_big)
    meta:set_string("bm_temp_dis_big_ther_inner_id", id_ther_big_inner)
    meta:set_string("bm_temp_dis_big_ther_inner_down_id", id_ther_big_inner_down)
    meta:set_string("bm_ther_heat_id", id_ther_heat)
    meta:set_string("bm_ther_freeze_id", id_ther_freeze)
    meta:set_string("bm_do_temp_dmg", "false")
    meta:set_string("bm_temp_in", meta:get_string("bm_temp_in") ~= "" and meta:get_string("bm_temp_in") or "celsius")
    meta:set_string("bm_temp_in_old", meta:get_string("bm_temp_in_old") ~= "" and meta:get_string("bm_temp_in_old") or "celsius")
    meta:set_string("bm_ther_color", meta:get_string("bm_ther_color") ~= "" and meta:get_string("bm_ther_color") or "196, 0, 0")
    meta:set_string("bm_ther_color_change", meta:get_string("bm_ther_color_change") ~= "" and meta:get_string("bm_ther_color_change") or "196, 0, 0")

    biometer.calc_temp(player, true)
    biometer.set_temp(player)
    biometer.update_ther_pos(player)
    biometer.update_ui_ther(player, false, true, false)
    biometer.update_ther_color(player)
  end
end)

minetest.register_on_respawnplayer(function(player)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    meta:set_string("bm_cur_biome", biometer.current_biome(player).name)

    meta:set_string("bm_do_temp_dmg", "true")

    biometer.calc_temp(player, true)
    biometer.set_temp(player)

    minetest.after(2, function()
      meta:set_string("bm_do_temp_dmg", "false")
    end)
  end
end)

minetest.register_globalstep(function(dtime)
  timer_n = timer_n + dtime
  timer_b = timer_b + dtime
  timer_e = timer_e + dtime
  if timer_n >= interval_n then
    timer_n = 0
    for _, player in ipairs(minetest.get_connected_players()) do
      if not minetest.is_creative_enabled(player:get_player_name()) then
        biometer.calc_temp(player, true)
        biometer.set_temp(player)
      end
    end
  end
  if timer_b >= interval_b then
    timer_b = 0
    for _, player in ipairs(minetest.get_connected_players()) do
      if not minetest.is_creative_enabled(player:get_player_name()) then
        local meta = player:get_meta()
        local biome = biometer.current_biome(player)
        if meta:get_string("bm_cur_biome") ~= biome.name then
          meta:set_string("bm_cur_biome", biome.name)
          biometer.calc_temp(player, true)
          biometer.set_temp(player)
        end
      end
    end
  end
  if timer_e >= interval_e then
    timer_e = 0
    for _, player in ipairs(minetest.get_connected_players()) do
      if not minetest.is_creative_enabled(player:get_player_name()) then
        biometer.calc_temp(player, false)
        biometer.set_temp(player)
      end
    end
  end
end)

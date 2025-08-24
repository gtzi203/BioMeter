
--functions

local S = minetest.get_translator(minetest.get_current_modname())

local decimal = 10 ^ 1
local radius = 2

local ther_min = -20
local ther_max = 50
local ther_scale_min = 0
local ther_scale_max = 8

function current_biome(player)
  local biome_data = minetest.get_biome_data(player:get_pos())

  return {name = minetest.get_biome_name(biome_data.biome), humidity = biome_data.humidity, heat = biome_data.heat}
end

function calc_temp(player, base)
  local meta = player:get_meta()
  local biome = current_biome(player)
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

    temp_r = temp_r + (player_pos.y * -1 * 0.03)

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

function update_temp(player, temp)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local id = ""
    local cur_id = ""
    if temp >= 40 and temp <= 60 then
      id = meta:get_string("bm_ther_heat_id")
      player:hud_change(id, "text", "biometer_thermometer_heat.png^[opacity:"..(temp - 39) * 7)
      for i = 1, 4, 1 do
        cur_id = meta:get_string("bm_heat_"..i.."_id")
        player:hud_change(cur_id, "text", "biometer_heat_"..alignments[i].alignment..".png^[transformR"..alignments[i].rot.."^[opacity:"..(temp - 39) * 11)
      end
    elseif temp <= 0 and temp >= -15 then
      id = meta:get_string("bm_ther_freeze_id")
      player:hud_change(id, "text", "biometer_thermometer_freeze.png^[opacity:"..((temp + 4) * -1) * 9)
      for i = 1, 4, 1 do
        cur_id = meta:get_string("bm_freeze_"..i.."_id")
        player:hud_change(cur_id, "text", "biometer_freeze_"..alignments[i].alignment..".png^[transformR"..alignments[i].rot.."^[opacity:"..(temp * -1) * 15)
      end
    elseif temp > 60 or temp < -15 then
      if temp > 60 then
        temp = 61
        id = meta:get_string("bm_ther_heat_id")
        player:hud_change(id, "text", "biometer_thermometer_heat.png^[opacity:"..(temp - 39) * 7)
        for i = 1, 4, 1 do
          cur_id = meta:get_string("bm_heat_"..i.."_id")
          player:hud_change(cur_id, "text", "biometer_heat_"..alignments[i].alignment..".png^[transformR"..alignments[i].rot.."^[opacity:"..(temp - 39) * 11)
        end
      elseif temp < -15 then
        temp = -16
        id = meta:get_string("bm_ther_freeze_id")
        player:hud_change(id, "text", "biometer_thermometer_freeze.png^[opacity:"..((temp + 4) * -1) * 9)
        for i = 1, 4, 1 do
          cur_id = meta:get_string("bm_freeze_"..i.."_id")
          player:hud_change(cur_id, "text", "biometer_freeze_"..alignments[i].alignment..".png^[transformR"..alignments[i].rot.."^[opacity:"..((temp + 4) * -1) * 15)
        end
      end
      local hp = player:get_hp()
      player:set_hp(hp - 4)
    else
      local id_heat = meta:get_string("bm_ther_heat_id")
      player:hud_change(id_heat, "text", "biometer_thermometer_heat.png^[opacity:0")
      for i = 1, 4, 1 do
        cur_id = meta:get_string("bm_heat_"..i.."_id")
        player:hud_change(cur_id, "text", "biometer_heat_"..alignments[i].alignment..".png^[transformR"..alignments[i].rot.."^[opacity:0")
      end
      local id_freeze = meta:get_string("bm_ther_freeze_id")
      player:hud_change(id_freeze, "text", "biometer_thermometer_freeze.png^[opacity:0")
      for i = 1, 4, 1 do
        cur_id = meta:get_string("bm_freeze_"..i.."_id")
        player:hud_change(cur_id, "text", "biometer_freeze_"..alignments[i].alignment..".png^[transformR"..alignments[i].rot.."^[opacity:0")
      end
    end
  end
end

function update_ther_inner(player, temp)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local id = meta:get_string("bm_temp_dis_ther_inner_id")

    if temp < ther_min then
      temp = ther_min
    end
    if temp > ther_max then
      temp = ther_max
    end

    local scale_y = (temp - ther_min) / (ther_max - ther_min) * (ther_scale_max - ther_scale_min) + ther_scale_min
    player:hud_change(id, "scale", {x = 8, y = scale_y})

    local base_offset_y = -94  -- +4 = 4px tiefer (anpassen nach Bedarf)
    local offset_y = base_offset_y - (scale_y * 3.9)

    player:hud_change(id, "offset", {x = -100, y = offset_y})
  end
end

function set_temp(player, temp)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local id = meta:get_string("bm_temp_dis_id")
    if not temp then
      local temp_base = meta:get_float("bm_temp_base")
      local temp_extra = meta:get_float("bm_temp")
      temp = temp_base + temp_extra
    end
    if id and temp then
      --temp = -13.2
      if s.temp_in == "fahrenheit" then
        temp_f = math.floor((temp * 9 / 5 + 32) * decimal + 0.5) / decimal
      end
      player:hud_change(id, "text", (temp_f or temp)..s.temp_sym)
      update_temp(player, temp)
      update_ther_inner(player, temp)
    end
  end
end

function update_hydr(player)
  local meta = player:get_meta()
  local id = meta:get_string("bm_hydr_black_id")
  local current_value = meta:get_int("bm_hydr_bar_value")

  if current_value <= 4 then
    player:hud_change(id, "text", "biometer_hydration_black.png^[opacity:"..((current_value - 5) * -1) * 55 + ((current_value - 1) * 5))
  else
    player:hud_change(id, "text", "biometer_hydration_black.png^[opacity:0")
  end
end

function set_hydr_bar(player, respawn, value)
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
      player:set_hp(hp - 3)
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
    update_hydr(player)
  end
end

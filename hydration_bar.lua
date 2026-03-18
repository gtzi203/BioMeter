
--hydration_bar

local S = minetest.get_translator(minetest.get_current_modname())

local timer = 0
local interval = 2

--[[if minetest.get_modpath("hudbars") then
  hb.register_hudbar("biometer.hydr_bar", 0xFFFFFF, S("Hydration Bar"), {icon = "biometer_hydr_bar_icon.png", bgicon = "biomter_hydr_bar_bg_icon.png", bar = "biometer_hydr_bar_bg.png"}, 20, 20, false, nil, {order = { "label", "value", "max_value"}})
end--]]

minetest.register_on_joinplayer(function(player)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local hydr_bar_value = meta:get_int("bm_hydr_bar_value")
    local id = nil

    local default_hydr_bar_pos = bm.hydr_bar_pos[cg][bm.hydr_bar_pos[cg].default_pos].pos

    meta:set_string("bm_hydr_bar_pos", meta:get_string("bm_hydr_bar_pos") ~= "" and meta:get_string("bm_hydr_bar_pos") or default_hydr_bar_pos)
    meta:set_string("bm_hydr_bar_pos_old", meta:get_string("bm_hydr_bar_pos_old") ~= "" and meta:get_string("bm_hydr_bar_pos_old") or default_hydr_bar_pos)

    --meta:set_string("bm_hydr_bar_pos", default_hydr_bar_pos)
    --meta:set_string("bm_hydr_bar_pos_old", default_hydr_bar_pos)

    local hydr_bar = biometer.get_pos_from_string(meta:get_string("bm_hydr_bar_pos"))

    local text2 = ""

    if cg == "mineclone" then
      text2 = "biometer_hydration_icon_black_mineclone.png"
    end

    --if not minetest.get_modpath("hudbars") then
      id = player:hud_add({
        hud_elem_type = "statbar",
        position = {x = 0, y = 0},
        offset = {x = 0, y = 0},
        text = "biometer_hydration_icon_"..cg..".png",
        text2 = text2,
        number = 20,
        item = 20,
        direction = 0,
        size = {x = 24, y = 24},
        z_index = 0
      })
    --[[else
      hb.init_hudbar(player, "biometer.hydr_bar", 20, 20, false)
    end--]]
    local id_hydr_black = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0.5, y = 0.5},
      scale = {x = -100, y = -100},
      text = "biometer_hydration_black.png^[opacity:0",
      z_index = 9999
    })

    meta:set_string("bm_hydr_bar_id", id)
    meta:set_string("bm_hydr_black_id", id_hydr_black)
    if hydr_bar_value > 0 then
      meta:set_int("bm_hydr_bar_value", meta:get_int("bm_hydr_bar_value"))
    else
      meta:set_int("bm_hydr_bar_value", 20)
    end
    --meta:set_int("bm_hydr_bar_value", 4)

    biometer.update_hydr_bar_pos(player)
    biometer.set_hydr_bar(player, true)
  end
end)

minetest.register_on_respawnplayer(function(player)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    meta:set_int("bm_hydr_bar_value", 20)

    biometer.set_hydr_bar(player, true)
  end
end)

minetest.register_globalstep(function(dtime)
  timer = timer + dtime
  if timer >= interval then
    timer = 0
    for _, player in ipairs(minetest.get_connected_players()) do
      if not minetest.is_creative_enabled(player:get_player_name()) then
        biometer.set_hydr_bar(player, false)
      end
    end
  end
end)


--hydration_bar

local timer = 0
local interval = 2

minetest.register_on_joinplayer(function(player)
  if not minetest.is_creative_enabled(player:get_player_name()) then
    local meta = player:get_meta()
    local hydr_bar_value = meta:get_int("bm_hydr_bar_value")
    local id = nil
    if cg == "minetest_game" then
      id = player:hud_add({
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        offset = {x = 25, y = -110},
        text = "biometer_hydration_icon_minetest_game.png",
        number = 20,
        size = {x = 24, y = 24},
        z_index = 0
      })
    else
      id = player:hud_add({
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        offset = {x = -258, y = -137},
        text = "biometer_hydration_icon_mineclone.png",
        text2 = "biometer_hydration_icon_black_mineclone.png",
        number = 20,
        item = 20,
        size = {x = 24, y = 24},
        z_index = 0
      })
    end
    local id_hydr_black = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0.5, y = 0.5},
      scale = {x = -100, y = -100},
      text = "biometer_hydration_black.png^[opacity:0",
      z_index = 2
    })
    meta:set_string("bm_hydr_bar_id", id)
    meta:set_string("bm_hydr_black_id", id_hydr_black)
    if hydr_bar_value > 0 then
      meta:set_int("bm_hydr_bar_value", meta:get_int("bm_hydr_bar_value"))
    else
      meta:set_int("bm_hydr_bar_value", 20)
    end
    --meta:set_int("bm_hydr_bar_value", 4)

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

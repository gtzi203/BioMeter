
--api

local S = minetest.get_translator(minetest.get_current_modname())

local ENV_NODES = minetest.settings:get_bool("biometer.env_nodes") ~= false
local ENV_NODES_RADIUS = tonumber(minetest.settings:get("biometer.env_nodes_radius") or 5)

local DEAL_HYDR_DAMAGE = minetest.settings:get_bool("biometer.deal_hydr_damage") ~= false
local DEAL_HYDR_DAMAGE_AT = tonumber(minetest.settings:get("biometer.deal_hydr_damage_at") or 3)
local HYDR_DAMAGE = tonumber(minetest.settings:get("biometer.hydr_damage") or 1)

local DEAL_HEAT_DAMAGE = minetest.settings:get_bool("biometer.deal_heat_damage") ~= false
local DEAL_HEAT_DAMAGE_AT = tonumber(minetest.settings:get("biometer.deal_heat_damage_at") or 150)
local HEAT_DAMAGE = tonumber(minetest.settings:get("biometer.heat_damage") or 2)

local DEAL_FREEZE_DAMAGE = minetest.settings:get_bool("biometer.deal_freeze_damage") ~= false
local DEAL_FREEZE_FREEZE_AT = tonumber(minetest.settings:get("biometer.deal_freeze_damage_at") or -20)
local FREEZE_DAMAGE = tonumber(minetest.settings:get("biometer.freeze_damage") or 1)

--helpers

function biometer.round(number, decimal)
    local mult = 10 ^ (decimal or 0)
    
    return math.floor(number * mult + 0.5) / mult
end

function biometer.deg_to_rad(deg)
    return (deg * math.pi) / 180
end

function biometer.rgb_to_hex(rgb_tbl)
    return string.format("#%02x%02x%02x", rgb_tbl.r, rgb_tbl.g, rgb_tbl.b)
end

function biometer.get_hud_scale_mult(player_name)
    local window = minetest.get_player_window_information(player_name)

    if not window then
        return 0
    end

    --maby not perfect, but ok. idk :,(

    --2560, 1351

    --local hud_scale_mult = ((window.size.x / 2560) * (window.size.y / 1351)) ^ (1 / 2.35)
    --local hud_scale_mult = (window.max_formspec_size.x / 28.423389434814) * (window.max_formspec_size.y / 15)
    --local hud_scale_mult = window.max_formspec_size.x / 28.423389434814
    local hud_scale_mult = (math.sqrt((window.size.x ^ 2) + (window.size.y ^ 2))) / (math.sqrt((2560 ^ 2) + (1351 ^ 2)))
    local hud_scale_mult_x = (window.size.x / 2560)
    local hud_scale_mult_y = (window.size.y / 1351)

    return hud_scale_mult, hud_scale_mult_x, hud_scale_mult_y
end

function biometer.msg(player_name, msg)
    minetest.chat_send_player(player_name, minetest.colorize("#1873B8", "[BioMeter]: ") .. msg)
end

function biometer.add_item_to_player(player, itemstack, from_stack)
    local result_stack = from_stack

    local player_name = player:get_player_name()
    local inv = player:get_inventory()

    if from_stack:get_count() > 1 or minetest.is_creative_enabled(player_name) then
        if inv:room_for_item("main", itemstack) then
            inv:add_item("main", itemstack)
        else
            local pos = player:get_pos()

            minetest.add_item({x = pos.x, y = pos.y + 0.7, z = pos.z}, itemstack)
        end

        if not minetest.is_creative_enabled(player_name) then
            result_stack:take_item()
        end
    else
        result_stack = itemstack
    end

    return result_stack
end

function biometer.drink_item(hydr_change, replace_with_item, itemstack, user)
    local player_name = user:get_player_name()

    biometer.add_hydr(user, hydr_change, false, true)

    minetest.sound_play("biometer_drinking", {to_player = player_name, gain = 0.5})

    return ItemStack(replace_with_item)
end

function biometer.drink_item_mcl(hydr_change, replace_with_item, itemstack, player, pointed_thing)
    local player_name = player:get_player_name()

    mcl_hunger.eat_internal[player_name]._custom_itemstack = itemstack
    mcl_hunger.eat_internal[player_name]._custom_func = function(itemstack)
        biometer.add_hydr(player, hydr_change, false, true)
    end
    mcl_hunger.eat_internal[player_name]._custom_wrapper = function(player_name)
        mcl_hunger.eat_internal[player_name]._custom_func(
            mcl_hunger.eat_internal[player_name]._custom_itemstack
        )
    end

    return minetest.do_item_eat(0, replace_with_item, itemstack, player, pointed_thing)
end

--player settings

function biometer.get_settings(player_name, force_real)
    if not force_real then
        return biometer.fake_player_settings[player_name] or biometer.player_settings[player_name]
    else
        return biometer.player_settings[player_name]
    end
end

function biometer.set_settings(player_name, changes)
    for k, v in pairs(changes) do
        biometer.player_settings[player_name][k] = v
    end

    minetest.mkdir(minetest.get_worldpath() .. "/biometer")

    local settings = io.open(minetest.get_worldpath() .. "/biometer/" .. player_name .. ".txt", "w")

    settings:write(minetest.serialize(biometer.player_settings[player_name]))
    settings:close()

    return biometer.player_settings[player_name]
end

function biometer.create_fake_settings(player_name)
    biometer.fake_player_settings[player_name] = table.copy(biometer.player_settings[player_name])
end

function biometer.remove_fake_settings(player_name)
    biometer.fake_player_settings[player_name] = nil
end

function biometer.get_fake_settings(player_name, changes)
    return biometer.fake_player_settings[player_name]
end

function biometer.set_fake_settings(player_name, changes)
    for k, v in pairs(changes) do
        biometer.fake_player_settings[player_name][k] = v
    end

    return biometer.fake_player_settings[player_name]
end

--registrations

function biometer.register_hydr_bar_pos(def)
    local def = def or {}

    local index = #biometer.hydr_bar_positions + 1

    biometer.hydr_bar_positions[index] = {
        description = def.description or "unknown#" .. index,
        pos = def.pos or {x = 0, y = 0},
        offset = def.offset or {x = 0, y = 0},
        direction = def.direction or 0
    }

    return index
end

biometer.register_hydr_bar_pos({description = S("Top-Middle"), pos = {x = 0.5, y = 0}, offset = {x = 0, y = 20}, direction = -1})
biometer.register_hydr_bar_pos({description = S("Top-Rigth"), pos = {x = 1, y = 0}, offset = {x = -132, y = 20}, direction = 1})
biometer.register_hydr_bar_pos({description = S("Top-Left"), pos = {x = 0, y = 0}, offset = {x = 140, y = 20}, direction = -1})
biometer.register_hydr_bar_pos({description = S("Middle-Right"), pos = {x = 1, y = 0.5}, offset = {x = -132, y = 0}, direction = 1})
biometer.register_hydr_bar_pos({description = S("Middle-Left"), pos = {x = 0, y = 0.5}, offset = {x = 140, y = 0}, direction = -1})
biometer.register_hydr_bar_pos({description = S("Bottom-Right"), pos = {x = 1, y = 1}, offset = {x = -132, y = -40}, direction = 1})
biometer.register_hydr_bar_pos({description = S("Bottom-Left"), pos = {x = 0, y = 1}, offset = {x = 140, y = -40}, direction = -1})

if biometer.cg == "minetest_game" then
    biometer.register_hydr_bar_pos({description = S("Hotbar-Right"), pos = {x = 0.5, y = 1}, offset = {x = 360, y = -35}, direction = -1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Left"), pos = {x = 0.5, y = 1}, offset = {x = -350, y = -35}, direction = 1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Top-Right"), pos = {x = 0.5, y = 1}, offset = {x = 151, y = -132}, direction = -1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Top-Left"), pos = {x = 0.5, y = 1}, offset = {x = -138, y = -132}, direction = -1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Middle-Right"), pos = {x = 0.5, y = 1}, offset = {x = 151, y = -110}, direction = -1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Middle-Left"), pos = {x = 0.5, y = 1}, offset = {x = -138, y = -110}, direction = -1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Bottom-Right"), pos = {x = 0.5, y = 1}, offset = {x = 151, y = -88}, direction = -1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Bottom-Left"), pos = {x = 0.5, y = 1}, offset = {x = -138, y = -88}, direction = -1})
elseif biometer.cg == "mineclone" then
    biometer.register_hydr_bar_pos({description = S("Hotbar-Right"), pos = {x = 0.5, y = 1}, offset = {x = 390, y = -35}, direction = -1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Left"), pos = {x = 0.5, y = 1}, offset = {x = -380, y = -35}, direction = 1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Top-Right"), pos = {x = 0.5, y = 1}, offset = {x = 142, y = -168}, direction = 1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Top-Left"), pos = {x = 0.5, y = 1}, offset = {x = -130, y = -168}, direction = -1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Middle-Right"), pos = {x = 0.5, y = 1}, offset = {x = 142, y = -138}, direction = 1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Middle-Left"), pos = {x = 0.5, y = 1}, offset = {x = -130, y = -138}, direction = -1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Bottom-Right"), pos = {x = 0.5, y = 1}, offset = {x = 142, y = -108}, direction = 1})
    biometer.register_hydr_bar_pos({description = S("Hotbar-Bottom-Left"), pos = {x = 0.5, y = 1}, offset = {x = -130, y = -108}, direction = -1})
end

function biometer.get_hydr_bar_pos(index, return_nil)
    return biometer.hydr_bar_positions[index] or (not return_nil and biometer.hydr_bar_positions[1])
end

function biometer.get_hydr_bar_pos_index_by_pos(pos, offset, direction, return_nil)
    for index, def in pairs(biometer.hydr_bar_positions) do
        if pos.x == def.pos.x and pos.y == def.pos.y and offset.x == def.offset.x and offset.y == def.offset.y and direction == def.direction then
            return index, def
        end
    end

    if not return_nil then
        return 1, biometer.hydr_bar_positions[1]
    else
        return nil, nil
    end
end

function biometer.get_hydr_bar_pos_index_by_description(description, return_nil)
    for index, def in pairs(biometer.hydr_bar_positions) do
        if description == def.description then
            return index, def
        end
    end

    if not return_nil then
        return 1, biometer.hydr_bar_positions[1]
    else
        return nil, nil
    end
end

function biometer.register_temp_dis_pos(def)
    local def = def or {}

    local index = #biometer.temp_dis_positions + 1

    biometer.temp_dis_positions[index] = {
        description = def.description or "unknown#" .. index,
        pos = def.pos or {x = 0, y = 0},
        offset = def.offset or {x = 0, y = 0}
    }

    return index
end

biometer.register_temp_dis_pos({description = S("Top-Middle"), pos = {x = 0.5, y = 0}, offset = {x = 0, y = 160}})
biometer.register_temp_dis_pos({description = S("Top-Right"), pos = {x = 1, y = 0}, offset = {x = -70, y = 160}})
biometer.register_temp_dis_pos({description = S("Top-Left"), pos = {x = 0, y = 0}, offset = {x = 70, y = 160}})
biometer.register_temp_dis_pos({description = S("Middle-Right"), pos = {x = 1, y = 0.5}, offset = {x = -70, y = 0}})
biometer.register_temp_dis_pos({description = S("Middle-Left"), pos = {x = 0, y = 0.5}, offset = {x = 70, y = 0}})
biometer.register_temp_dis_pos({description = S("Bottom-Right"), pos = {x = 1, y = 1}, offset = {x = -70, y = -135}})
biometer.register_temp_dis_pos({description = S("Bottom-Left"), pos = {x = 0, y = 1}, offset = {x = 70, y = -135}})
biometer.register_temp_dis_pos({description = S("Hotbar-Right"), pos = {x = 0.5, y = 1}, offset = {x = 330, y = -115}})
biometer.register_temp_dis_pos({description = S("Hotbar-Left"), pos = {x = 0.5, y = 1}, offset = {x = -330, y = -115}})

function biometer.get_temp_dis_pos(index, return_nil)
    return biometer.temp_dis_positions[index] or (not return_nil and biometer.temp_dis_positions[1])
end

function biometer.get_temp_dis_pos_index_by_pos(pos, offset, return_nil)
    for index, def in pairs(biometer.temp_dis_positions) do
        if pos.x == def.pos.x and pos.y == def.pos.y and offset.x == def.offset.x and offset.y == def.offset.y then
            return index, def
        end
    end

    if not return_nil then
        return 1, biometer.temp_dis_positions[1]
    else
        return nil, nil
    end
end

function biometer.get_temp_dis_pos_index_by_description(description, return_nil)
    for index, def in pairs(biometer.temp_dis_positions) do
        if description == def.description then
            return index, def
        end
    end

    if not return_nil then
        return 1, biometer.temp_dis_positions[1]
    else
        return nil, nil
    end
end

function biometer.register_temp_unit(name, def)
    local def = def or {}

    local index = #biometer.temp_units + 1

    biometer.temp_units[index] = {
        name = name,
        description = def.description or name,
        symbol = def.symbol or "",
        convert_temp = def.convert_temp or function(temp) return temp end
    }

    return index
end

biometer.register_temp_unit("celsius", {description = "Celsius", symbol = "°C", convert_temp = function(temp) return temp end})
biometer.register_temp_unit("fahrenheit", {description = "Fahrenheit", symbol = "°F", convert_temp = function(temp) return temp * 9 / 5 + 32 end})
biometer.register_temp_unit("kelvin", {description = "Kelvin", symbol = "K", convert_temp = function(temp) return temp + 273.15 end})
biometer.register_temp_unit("rankine", {description = "Rankine", symbol = "°R", convert_temp = function(temp) return (temp + 273.15) * (9 / 5) end})
biometer.register_temp_unit("reaumur", {description = "Réaumur", symbol = "°Ré", convert_temp = function(temp) return temp * 0.8 end})

function biometer.get_temp_unit(index, return_nil)
    return biometer.temp_units[index] or (not return_nil and biometer.temp_units[1])
end

function biometer.get_temp_unit_index_by_name(name, return_nil)
    for index, def in pairs(biometer.temp_units) do
        if name == def.name then
            return index, def
        end
    end

    if not return_nil then
        return 1, biometer.temp_units[1]
    else
        return nil, nil
    end
end

function biometer.get_temp_unit_index_by_description(description, return_nil)
    for index, def in pairs(biometer.temp_units) do
        if description == def.description then
            return index, def
        end
    end

    if not return_nil then
        return 1, biometer.temp_units[1]
    else
        return nil, nil
    end
end

--hydration cap

function biometer.get_hydr_cap(hydr)
    local MIN_HYDR = 1
    local MAX_HYDR = 20

    if hydr < MIN_HYDR then
        hydr = MIN_HYDR
    elseif hydr > MAX_HYDR then
        hydr = MAX_HYDR
    end

    return hydr
end

--lock hydration

function biometer.get_locked_hydr(player_name)
    local settings = biometer.get_settings(player_name)

    if not settings then
        return false
    end

    return settings.SAVEDlockedhydr or false
end

function biometer.lock_hydr(player_name, locked_hydr, skip_update, ignore_cap)
    locked_hydr = locked_hydr or biometer.get_hydr(player_name)

    if not ignore_cap then
        locked_hydr = biometer.get_hydr_cap(locked_hydr)
    end

    biometer.set_settings(player_name, {["SAVEDlockedhydr"] = locked_hydr})

    if not skip_update then
        local player = minetest.get_player_by_name(player_name)

        biometer.update_hydr_bar(player)
        biometer.update_hydr_huds(player)
    end
end

function biometer.unlock_hydr(player_name, skip_update)
    biometer.set_settings(player_name, {["SAVEDlockedhydr"] = false})

    if not skip_update then
        local player = minetest.get_player_by_name(player_name)

        biometer.update_hydr_bar(player)
        biometer.update_hydr_huds(player)
    end
end

--hydration calculation

function biometer.calc_hydr(temp)
    local drop = 0

    local MAX_HALF_DROP_CHANCE = 60
    local MAX_FULL_DROP_CHANCE = 40  --full drops only happen, when a half drop does

    local half_drop_chance = 1 * temp

    if half_drop_chance > MAX_HALF_DROP_CHANCE then
        half_drop_chance = MAX_HALF_DROP_CHANCE
    end

    math.randomseed(os.time())

    local random_half_drop = math.random(1, 100)

    if random_half_drop <= half_drop_chance then
        drop = drop + 1

        local full_drop_chance = (1 * temp) / 3

        if full_drop_chance > MAX_FULL_DROP_CHANCE then
            full_drop_chance = MAX_FULL_DROP_CHANCE
        end

        math.randomseed(os.time())

        local random_full_drop = math.random(1, 100)

        if random_full_drop <= full_drop_chance then
            drop = drop + 1
        end
    end

    return drop
end

--hydration (bar)

function biometer.get_hydr(player_name)
    local hydr = biometer.player_hydrs[player_name] or 20
    local locked_hydr = biometer.get_locked_hydr(player_name) or false

    local resulting_hydr = locked_hydr or hydr

    return resulting_hydr, {resulting = resulting_hydr, real = hydr, locked = locked_hydr}
end

function biometer.get_real_hydr(player_name)
    return biometer.player_hydrs[player_name] or 20
end

function biometer.set_hydr(player, hydr, skip_update, ignore_creative, ignore_cap)
    local player_name = player:get_player_name()

    if not minetest.is_creative_enabled(player_name) or ignore_creative then
        hydr = biometer.get_hydr_cap(hydr)

        biometer.player_hydrs[player_name] = hydr

        biometer.set_settings(player_name, {["SAVEDhydr"] = hydr})

        if not skip_update then
            biometer.update_hydr_bar(player)
            biometer.update_hydr_huds(player)
        end
    end
end

function biometer.add_hydr(player, hydr, skip_update, ignore_creative, ignore_cap)
    biometer.set_hydr(player, biometer.get_real_hydr(player:get_player_name()) + hydr, skip_update, ignore_creative, ignore_cap)
end

function biometer.update_hydr_bar(player, hydr_override)
    local player_name = player:get_player_name()

    local settings = biometer.get_settings(player_name)
    local ids = biometer.player_hydr_bar_huds[player_name]

    if not settings or not ids then
        return
    end

    --local hud_scale_mult = biometer.get_hud_scale_mult(player_name)

    local hydr = hydr_override or biometer.get_hydr(player_name)

    player:hud_change(ids.hydr_bar, "position", settings.HBpos)
    player:hud_change(ids.hydr_bar, "offset", {x = (settings.HBoffset.x + (biometer.hydr_bar_size_offset * settings.HBdirection) + (-17.8 - (settings.HBdirection * 17.8))), y = settings.HBoffset.y})
    player:hud_change(ids.hydr_bar, "direction", settings.HBdirection)
    player:hud_change(ids.hydr_bar, "number", hydr)
end

function biometer.update_hydr_huds(player, hydr_override)
    local player_name = player:get_player_name()

    local hydr = hydr_override or biometer.get_hydr(player_name)
    local ids = biometer.player_hydr_bar_huds[player_name]
    local hud_scale_mult = biometer.get_hud_scale_mult(player_name)

    if not ids then
        return
    end

    local MIN_HYDR = 3

    local MAX_HUD_BG_OPACITY = 250

    if hydr <= MIN_HYDR then
        player:hud_change(ids.hydr_hud_bg, "text", "biometer_hydr_hud_bg.png^[opacity:" .. MAX_HUD_BG_OPACITY - (30 * hydr))
        player:hud_change(ids.hydr_hud_bg, "scale", {x = 64 * hud_scale_mult, y = 67.6 * hud_scale_mult})
    else
        player:hud_change(ids.hydr_hud_bg, "text", "")
    end
end

function biometer.deal_hydr_damage(player)
    local hydr = biometer.get_hydr(player:get_player_name())

    if DEAL_HYDR_DAMAGE then
        if hydr <= DEAL_HYDR_DAMAGE_AT then
            player:set_hp(player:get_hp() - HYDR_DAMAGE)
        end
    end
end

--additional/lock temperature

function biometer.get_additional_temp(player_name)
    local settings = biometer.get_settings(player_name)

    if not settings then
        return 0
    end

    return settings.SAVEDadditionaltemp or 0
end

function biometer.set_additional_temp(player_name, additional_temp, skip_update)
    biometer.set_settings(player_name, {["SAVEDadditionaltemp"] = additional_temp})

    if not skip_update then
        local player = minetest.get_player_by_name(player_name)

        biometer.update_temp_dis(player)
        biometer.update_temp_huds(player)
    end
end

function biometer.get_locked_temp(player_name)
    local settings = biometer.get_settings(player_name)

    if not settings then
        return false
    end

    return settings.SAVEDlockedtemp or false
end

function biometer.lock_temp(player_name, locked_temp, skip_update)
    biometer.set_settings(player_name, {["SAVEDlockedtemp"] = locked_temp or biometer.get_temp(player_name)})

    if not skip_update then
        local player = minetest.get_player_by_name(player_name)

        biometer.update_temp_dis(player)
        biometer.update_temp_huds(player)
    end
end

function biometer.unlock_temp(player_name, skip_update)
    biometer.set_settings(player_name, {["SAVEDlockedtemp"] = false})

    if not skip_update then
        local player = minetest.get_player_by_name(player_name)

        biometer.update_temp_dis(player)
        biometer.update_temp_huds(player)
    end
end

--temperature calculation

function biometer.get_biome(pos)
  local biome_data = minetest.get_biome_data(pos)

  return {name = minetest.get_biome_name(biome_data.biome), humidity = biome_data.humidity, heat = biome_data.heat}
end

function biometer.calc_total_temp(temps)
    return temps.biome + temps.env_nodes + temps.time + temps.height
end

function biometer.calc_temp(pos)
    local total_temp = 0
    local temp_biome = biometer.calc_biome_temp(pos)
    local temp_env_nodes = biometer.calc_env_nodes_temp(pos)
    local temp_time = biometer.calc_time_temp()
    local temp_height = biometer.calc_height_temp(pos)

    total_temp = temp_biome + temp_env_nodes + temp_time + temp_height

    return total_temp, {biome = temp_biome, env_nodes = temp_env_nodes, time = temp_time, height = temp_height}
end

function biometer.calc_biome_temp(pos)
    local temp = 0

    local biome = biometer.get_biome(pos)

    temp = (biome.heat / 100) * (biome.humidity / 2.5)

    return biometer.round(temp, 1)
end

function biometer.calc_env_nodes_temp(pos)
    local temp = 0

    if ENV_NODES then
        local minp = {x = pos.x - ENV_NODES_RADIUS, y = pos.y - ENV_NODES_RADIUS, z = pos.z - ENV_NODES_RADIUS}
        local maxp = {x = pos.x + ENV_NODES_RADIUS, y = pos.y + ENV_NODES_RADIUS, z = pos.z + ENV_NODES_RADIUS}

        local env_node_positions = minetest.find_nodes_in_area(minp, maxp, biometer.environment_node_names)

        for _, env_node_pos in ipairs(env_node_positions) do
            local env_node = minetest.get_node(env_node_pos)
            local distance = vector.distance(pos, env_node_pos)

            if distance < 1 then
                distance = 1
            end

            temp = temp + (biometer.environment_nodes[env_node.name] / distance)
        end
    end

    return biometer.round(temp, 1)
end

function biometer.calc_time_temp()
    local temp = 0

    local MAX_TIME_TEMP = 8

    local time = minetest.get_timeofday()

    temp = (math.cos(biometer.deg_to_rad(time * 360)) * MAX_TIME_TEMP) * -1

    return biometer.round(temp, 1)
end

function biometer.calc_height_temp(pos)
    local temp = 0

    local TEMP_UP_CAP = -20
    local TEMP_DOWN_CAP = 30

    local temp = pos.y * -0.03

    if temp < TEMP_UP_CAP then
        temp = TEMP_UP_CAP
    elseif temp > TEMP_DOWN_CAP then
        temp = TEMP_DOWN_CAP
    end

    return biometer.round(temp, 1)
end

--temperature (display)

function biometer.get_temp(player_name)
    local temp = biometer.player_temps[player_name] or 0
    local additional_temp = biometer.get_additional_temp(player_name) or 0
    local locked_temp = biometer.get_locked_temp(player_name) or false
    local saved_temps = biometer.saved_player_temps[player_name] or {}

    local resulting_temp = locked_temp or (temp + additional_temp)

    return resulting_temp, {resulting = resulting_temp, real = temp, additional = additional_temp, locked = locked_temp, saved = saved_temps}
end

function biometer.get_real_temp(player_name)
    return biometer.player_temps[player_name] or 0
end

function biometer.set_temp(player, temp, skip_update)
    local player_name = player:get_player_name()

    biometer.player_temps[player_name] = temp

    if not skip_update then
        biometer.update_temp_dis(player)
        biometer.update_temp_huds(player)
    end
end

function biometer.update_temp_dis(player, temp_override)
    local player_name = player:get_player_name()

    local ids = biometer.player_temp_dis_huds[player_name]
    local settings = biometer.get_settings(player_name)

    if not settings or not ids then
        return
    end

    local hud_scale_mult, hud_scale_mult_x, hud_scale_mult_y = biometer.get_hud_scale_mult(player_name)

    local temp = temp_override or biometer.get_temp(player_name)
    local _, temp_unit = biometer.get_temp_unit_index_by_name(settings.TDunit)

    local dis_temp = biometer.round(temp_unit.convert_temp(temp), 1) .. temp_unit.symbol

    player:hud_change(ids.temp_dis, "text", dis_temp)
    player:hud_change(ids.temp_dis, "position", settings.TDpos)
    player:hud_change(ids.temp_dis, "offset", {x = settings.TDoffset.x * hud_scale_mult, y = (settings.TDoffset.y - (130 * (biometer.THER_SCALE / 8))) * hud_scale_mult})

    player:hud_change(ids.ther, "position", settings.TDpos)
    player:hud_change(ids.ther, "offset", {x = settings.TDoffset.x * hud_scale_mult, y = settings.TDoffset.y * hud_scale_mult})
    player:hud_change(ids.ther, "scale", {x = biometer.THER_SCALE * hud_scale_mult, y = biometer.THER_SCALE * hud_scale_mult})

    local MIN_TEMP = -30
    local MAX_TEMP = 150

    if temp < MIN_TEMP then
        temp = MIN_TEMP
    elseif temp > MAX_TEMP then
        temp = MAX_TEMP
    end

    local ther_inner_color = biometer.rgb_to_hex(settings.TDcolor)
    local ther_inner_offset = function(offset, scale) return {x = offset.x * hud_scale_mult, y = (offset.y + (32 * (scale / biometer.THER_SCALE) * (math.abs(temp - MAX_TEMP) / (math.abs(MIN_TEMP) + math.abs(MAX_TEMP))))) * hud_scale_mult} end
    local ther_inner_scale = function(scale) return {x = scale * hud_scale_mult, y = scale * hud_scale_mult * ((((temp + math.abs(MIN_TEMP)) * 100) / (math.abs(MIN_TEMP) + math.abs(MAX_TEMP))) / 100)} end

    player:hud_change(ids.ther_inner, "position", settings.TDpos)
    player:hud_change(ids.ther_inner, "offset", ther_inner_offset(settings.TDoffset, biometer.THER_SCALE))
    player:hud_change(ids.ther_inner, "text", "biometer_thermometer_inner.png^[multiply:" .. ther_inner_color)
    player:hud_change(ids.ther_inner, "scale", ther_inner_scale(biometer.THER_SCALE))

    player:hud_change(ids.ther_inner_down, "position", settings.TDpos)
    player:hud_change(ids.ther_inner_down, "offset", {x = settings.TDoffset.x * hud_scale_mult, y = settings.TDoffset.y * hud_scale_mult})
    player:hud_change(ids.ther_inner_down, "text", "biometer_thermometer_inner_down.png^[multiply:" .. ther_inner_color)
    player:hud_change(ids.ther_inner_down, "scale", {x = biometer.THER_SCALE * hud_scale_mult, y = biometer.THER_SCALE * hud_scale_mult})

    if biometer.update_player_editor_huds[player_name] then
        local editor_ids = biometer.player_editor_huds[player_name]

        if not editor_ids then
            return
        end

        player:hud_change(editor_ids.bg, "text", "biometer_editor_bg.png")
        player:hud_change(editor_ids.bg, "scale", {x = 48 * hud_scale_mult_y, y = 39 * hud_scale_mult_y})

        player:hud_change(editor_ids.text_r, "text", settings.TDcolor.r)
        player:hud_change(editor_ids.text_g, "text", settings.TDcolor.g)
        player:hud_change(editor_ids.text_b, "text", settings.TDcolor.b)

        player:hud_change(editor_ids.temp_dis, "text", dis_temp)
        player:hud_change(editor_ids.temp_dis, "offset", {x = 0, y = 0 - (260 * (biometer.EDITOR_THER_SCALE / 16) * hud_scale_mult)})

        player:hud_change(editor_ids.ther, "text", "biometer_thermometer.png")
        player:hud_change(editor_ids.ther, "scale", {x = biometer.EDITOR_THER_SCALE * hud_scale_mult, y = biometer.EDITOR_THER_SCALE * hud_scale_mult})

        player:hud_change(editor_ids.ther_inner, "offset", ther_inner_offset({x = 0, y = 0}, biometer.EDITOR_THER_SCALE))
        player:hud_change(editor_ids.ther_inner, "text", "biometer_thermometer_inner.png^[multiply:" .. ther_inner_color)
        player:hud_change(editor_ids.ther_inner, "scale", ther_inner_scale(biometer.EDITOR_THER_SCALE))

        player:hud_change(editor_ids.ther_inner_down, "text", "biometer_thermometer_inner_down.png^[multiply:" .. ther_inner_color)
        player:hud_change(editor_ids.ther_inner_down, "scale", {x = biometer.EDITOR_THER_SCALE * hud_scale_mult, y = biometer.EDITOR_THER_SCALE * hud_scale_mult})
    end
end

local function remove_heat_huds(player, ids)
    player:hud_change(ids.heat_hud_bg, "text", "")

    for i = 1, 4, 1 do
        local id = ids.heat_huds[i]

        player:hud_change(id, "text", "")
    end
end

local function remove_freeze_huds(player, ids)
    player:hud_change(ids.freeze_hud_bg, "text", "")

    for i = 1, 4, 1 do
        local id = ids.freeze_huds[i]

        player:hud_change(id, "text", "")
    end
end

function biometer.update_temp_huds(player, temp_override)
    local player_name = player:get_player_name()

    local temp = temp_override or biometer.get_temp(player_name)
    local ids = biometer.player_temp_dis_huds[player_name]

    if not ids then
        return
    end

    local hud_scale_mult = biometer.get_hud_scale_mult(player_name)

    local MAX_TEMP = 60
    local MIN_TEMP = -10

    local MAX_HUD_BG_OPACITY = 200

    if temp <= MIN_TEMP then
        local opacity = math.abs(temp) - math.abs(MIN_TEMP)

        player:hud_change(ids.freeze_hud_bg, "text", "biometer_freeze_hud_bg.png^[opacity:" .. ((opacity * 1.5 <= MAX_HUD_BG_OPACITY and opacity * 1.5) or MAX_HUD_BG_OPACITY))

        for i = 1, 4, 1 do
            local id = ids.freeze_huds[i]
            local freeze_hud = biometer.freeze_hud_images[i]

            player:hud_change(id, "text", freeze_hud.image .. "^[opacity:" .. opacity * 3)
            player:hud_change(id, "offset", {x = freeze_hud.offset.x * hud_scale_mult, y = freeze_hud.offset.y * hud_scale_mult})
            player:hud_change(id, "scale", {x = biometer.TEMP_HUDS_SCALE * hud_scale_mult, y = biometer.TEMP_HUDS_SCALE * hud_scale_mult})
        end

        remove_heat_huds(player, ids)
    elseif temp >= MAX_TEMP then
        local opacity = math.abs(temp) - math.abs(MAX_TEMP)

        player:hud_change(ids.heat_hud_bg, "text", "biometer_heat_hud_bg.png^[opacity:" .. ((opacity * 1.5 <= MAX_HUD_BG_OPACITY and opacity * 1.5) or MAX_HUD_BG_OPACITY))

        for i = 1, 4, 1 do
            local id = ids.heat_huds[i]
            local freeze_hud = biometer.heat_hud_images[i]

            player:hud_change(id, "text", freeze_hud.image .. "^[opacity:" .. opacity * 3)
            player:hud_change(id, "offset", {x = freeze_hud.offset.x * hud_scale_mult, y = freeze_hud.offset.y * hud_scale_mult})
            player:hud_change(id, "scale", {x = biometer.TEMP_HUDS_SCALE * hud_scale_mult, y = biometer.TEMP_HUDS_SCALE * hud_scale_mult})
        end

        remove_freeze_huds(player, ids)
    else
        remove_heat_huds(player, ids)
        remove_freeze_huds(player, ids)
    end
end

function biometer.deal_temp_damage(player)
    local temp = biometer.get_temp(player:get_player_name())

    if temp >= DEAL_HEAT_DAMAGE_AT then
        if DEAL_HEAT_DAMAGE then
            player:set_hp(player:get_hp() - HEAT_DAMAGE)
        end
    elseif temp <= DEAL_FREEZE_FREEZE_AT then
        if DEAL_FREEZE_DAMAGE then
            player:set_hp(player:get_hp() - FREEZE_DAMAGE)
        end
    end
end

--editor helpers

function biometer.get_temp_unit_descriptions_string()
    local string = ""

    for index = 1, #biometer.temp_units, 1 do
        string = string .. ((string ~= "" and ",") or "") .. biometer.temp_units[index].description
    end

    return string
end

function biometer.get_hydr_bar_pos_descriptions_string(current_pos, current_offset, current_direction)
    local string = ""

    if not biometer.get_hydr_bar_pos_index_by_pos(current_pos, current_offset, current_direction, true) then
        string = S("Custom")
    end

    for index = 1, #biometer.hydr_bar_positions, 1 do
        string = string .. ((string ~= "" and ",") or "") .. biometer.hydr_bar_positions[index].description
    end

    return string
end

function biometer.get_temp_dis_pos_descriptions_string(current_pos, current_offset)
    local string = ""

    if not biometer.get_temp_dis_pos_index_by_pos(current_pos, current_offset, true) then
        string = S("Custom")
    end

    for index = 1, #biometer.temp_dis_positions, 1 do
        string = string .. ((string ~= "" and ",") or "") .. biometer.temp_dis_positions[index].description
    end

    return string
end

--editor

function biometer.open_custom_hydr_bar_pos_editor(player)
    local player_name = player:get_player_name()

    local settings = biometer.get_settings(player_name)

    if not settings then
        return
    end

    local direction_index = 1

    if settings.HBdirection == 1 then
        direction_index = 2
    end

    local formspec = (
        "formspec_version[6]" ..
        "size[7,6.8]" ..
        "no_prepend[]" ..

        "label[0.1,0.2;" .. S("Hydration Bar") .. "  |  " .. S("Press enter to update the position") .. ".]" ..

        "field[0.3,1.3;3,0.8;xpos;X-" .. S("Position") .. ";" .. settings.HBpos.x .. "]" ..
        "field[3.7,1.3;3,0.8;ypos;Y-" .. S("Position") .. ";" .. settings.HBpos.y .. "]" ..

        "field[0.3,2.9;3,0.8;xoffset;X-" .. S("Offset") .. ";" .. settings.HBoffset.x .. "]" ..
        "field[3.7,2.9;3,0.8;yoffset;Y-" .. S("Offset") .. ";" .. settings.HBoffset.y .. "]" ..

        "label[0.3,4.3;" .. S("Direction") .. "]" ..
        "dropdown[0.3,4.5;3,0.8;direction;" .. S("Right") .. "," .. S("Left") .. ";" .. direction_index .. ";true]" ..

        "style[cancel;bgcolor=#FF0F1180]" .. 
        "button_exit[0.2,5.8;3.2,0.8;cancel;" .. S("Cancel") .. "]" ..
        "button[3.6,5.8;3.2,0.8;confirm;" .. S("Confirm") .. "]"
    )

    minetest.show_formspec(player_name, "biometer:custom_hydr_bar_pos_editor", formspec .. "label[-10,-10;" .. os.clock() .. "]")
end

function biometer.open_custom_temp_dis_pos_editor(player)
    local player_name = player:get_player_name()

    local settings = biometer.get_settings(player_name)

    if not settings then
        return
    end

    local direction_index = 1

    if settings.HBdirection == 1 then
        direction_index = 2
    end

    local formspec = (
        "formspec_version[6]" ..
        "size[7,5.3]" ..
        "no_prepend[]" ..

        "label[0.1,0.2;" .. S("Temeperature Display") .. "  |  " .. S("Press enter to update the position") .. ".]" ..

        "field[0.3,1.3;3,0.8;xpos;X-" .. S("Position") .. ";" .. settings.TDpos.x .. "]" ..
        "field[3.7,1.3;3,0.8;ypos;Y-" .. S("Position") .. ";" .. settings.TDpos.y .. "]" ..

        "field[0.3,2.9;3,0.8;xoffset;X-" .. S("Offset") .. ";" .. settings.TDoffset.x .. "]" ..
        "field[3.7,2.9;3,0.8;yoffset;Y-" .. S("Offset") .. ";" .. settings.TDoffset.y .. "]" ..

        "style[cancel;bgcolor=#FF0F1180]" .. 
        "button_exit[0.2,4.3;3.2,0.8;cancel;" .. S("Cancel") .. "]" ..
        "button[3.6,4.3;3.2,0.8;confirm;" .. S("Confirm") .. "]"
    )

    minetest.show_formspec(player_name, "biometer:custom_temp_dis_pos_editor", formspec .. "label[-10,-10;" .. os.clock() .. "]")
end

function biometer.open_editor(player, reopen)
    local player_name = player:get_player_name()

    local settings = biometer.get_settings(player_name)

    if not settings then
        return
    end

    if not reopen then
        biometer.create_fake_settings(player_name)

        biometer.show_editor_huds(player)
    end

    ther_pos = ""
    ther_pos_custom = ""
    hydr_bar_pos = ""
    hydr_bar_pos_custom = ""

    biometer.editor_custom_save[player_name] = {
        ["hydr_bar"] = {
            pos = settings.HBpos, 
            offset = settings.HBoffset, 
            direction = settings.HBdirection
        },
        ["temp_dis"] = {
            pos = settings.TDpos,
            offset = settings.TDoffset
        }
    }

    local temp_unit_index = biometer.get_temp_unit_index_by_name(settings.TDunit)
    local hydr_bar_pos_index = biometer.get_hydr_bar_pos_index_by_pos(settings.HBpos, settings.HBoffset, settings.HBdirection)
    local temp_dis_pos_index = biometer.get_temp_dis_pos_index_by_pos(settings.TDpos, settings.TDoffset)

    local formspec = (
        "formspec_version[6]" .. 
        "size[12,10]" .. 
        "no_prepend[]" .. 
        "bgcolor[#FFFFFF00;false]" .. 
        "label[0.2,0.4;" .. S("BioMeter Editor") .. "]" .. 

        "container[1,1.3]" .. 
            "scrollbaroptions[min=0;max=255;smallstep=1]" .. 

            "label[0,0.25;R]"..
            "box[0.3,0.01;3.99,0.48;#FF0000CC]"..
            "scrollbar[0.3,0;4,0.5;horizontal;color_r;" .. settings.TDcolor.r .. "]"..

            "label[0,1.25;G]"..
            "box[0.3,1.01;3.99,0.48;#00FF00CC]"..
            "scrollbar[0.3,1;4,0.5;horizontal;color_g;" .. settings.TDcolor.g .. "]"..

            "label[0,2.25;B]"..
            "box[0.3,2.01;3.99,0.48;#0000FFCC]"..
            "scrollbar[0.3,2;4,0.5;horizontal;color_b;" .. settings.TDcolor.b .. "]"..

            "tooltip[default_color;" .. S("Set to Default") .. "]" .. 
            "image_button[5.3,0.85;0.8,0.8;biometer_editor_default_btn.png;default_color;;false;true]" .. 

            "label[0,3.3;" .. S("Temperature in") .. ":]" .. 
            "dropdown[0,3.5;3,0.8;temp_unit;" .. biometer.get_temp_unit_descriptions_string() .. ";" .. temp_unit_index .. ";false]" .. 

            "tooltip[default_temp_unit;" .. S("Set to Default") .. "]" .. 
            "image_button[3.2,3.5;0.8,0.8;biometer_editor_default_btn.png;default_temp_unit;;false;true]" .. 

            "label[0,4.8;" .. S("Thermometer Position") .. ":]" .. 
            "dropdown[0,5;3,0.8;temp_dis_pos;" .. biometer.get_temp_dis_pos_descriptions_string(settings.TDpos, settings.TDoffset) .. ";" .. temp_dis_pos_index .. ";false]" .. 

            "tooltip[custom_temp_dis_pos;" .. S("Custom") .. "]" .. 
            "image_button[3.2,5;0.8,0.8;biometer_editor_custom_btn.png;custom_temp_dis_pos;;false;true]" .. 

            "tooltip[default_temp_dis_pos;" .. S("Set to Default") .. "]" .. 
            "image_button[4.2,5;0.8,0.8;biometer_editor_default_btn.png;default_temp_dis_pos;;false;true]" .. 

            "label[0,6.3;" .. S("Hydration Bar Position") .. ":]" .. 
            "dropdown[0,6.5;3,0.8;hydr_bar_pos;" .. biometer.get_hydr_bar_pos_descriptions_string(settings.HBpos, settings.HBoffset, settings.HBdirection) .. ";" .. hydr_bar_pos_index .. ";false]" .. 

            "tooltip[custom_hydr_bar_pos;" .. S("Custom") .. "]" .. 
            "image_button[3.2,6.5;0.8,0.8;biometer_editor_custom_btn.png;custom_hydr_bar_pos;;false;true]" .. 

            "tooltip[default_hydr_bar_pos;" .. S("Set to Default") .. "]" .. 
            "image_button[4.2,6.5;0.8,0.8;biometer_editor_default_btn.png;default_hydr_bar_pos;;false;true]" .. 
        "container_end[]" .. 

        "style[cancel;bgcolor=#FF0F1180]" .. 
        "button_exit[5.67,8.9;3,0.8;cancel;" .. S("Cancel") .. "]" .. 
        "button_exit[8.8,8.9;3,0.8;apply_changes;" .. S("Apply Changes") .. "]"
    )

    --had to add an always changeing label, because the formspec will only update if there is a change in the formspec
    minetest.show_formspec(player_name, "biometer:editor", formspec .. "label[-10,-10;" .. os.clock() .. "]")

    return formspec
end

function biometer.show_editor_huds(player)
    biometer.update_player_editor_huds[player:get_player_name()] = true

    biometer.update_temp_dis(player)

    if biometer.cg == "minetest_game" then
        player:hud_change(biometer.player_hydr_bar_huds[player:get_player_name()].hydr_bar, "text2", "biometer_hydration_icon_minetest_game.png^[opacity:128")
    end
end

function biometer.hide_editor_huds(player, skip_hydr_bar_bg)
    local player_name = player:get_player_name()

    biometer.update_player_editor_huds[player_name] = false

    local ids = biometer.player_editor_huds[player_name]

    if not ids then
        return
    end

    player:hud_change(ids.bg, "text", "")
    player:hud_change(ids.text_r, "text", "")
    player:hud_change(ids.text_g, "text", "")
    player:hud_change(ids.text_b, "text", "")
    player:hud_change(ids.temp_dis, "text", "")
    player:hud_change(ids.ther, "text", "")
    player:hud_change(ids.ther_inner, "text", "")
    player:hud_change(ids.ther_inner_down, "text", "")

    if biometer.cg == "minetest_game" and not skip_hydr_bar_bg then
        player:hud_change(biometer.player_hydr_bar_huds[player_name].hydr_bar, "text2", "")
    end
end
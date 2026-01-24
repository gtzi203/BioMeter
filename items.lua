
--items

local S = minetest.get_translator(minetest.get_current_modname())

if cg == "minetest_game" then
  minetest.register_node("biometer:bowl", {
    description = S("Bowl"),
    drawtype = "plantlike",
    tiles = {"biometer_bowl_minetest_game.png"},
    inventory_image = "biometer_bowl_inv_minetest_game.png",
  	wield_image = "biometer_bowl_minetest_game.png",
  	paramtype = "light",
  	is_ground_content = false,
  	walkable = false,
  	selection_box = {
  		type = "fixed",
  		fixed = {-0.2500, -0.5000, -0.2500, 0.2500, -0.1250, 0.2500}
  	},
  	groups = {vessel = 1, dig_immediate = 3, attached_node = 1},
  	sounds = default.node_sound_wood_defaults(),
  })

  local bottles_override = {
    ["vessels:glass_bottle"] = "bottle",
    ["vessels:drinking_glass"] = "drinking_glass",
    ["vessels:steel_bottle"] = "steel_bottle",
    ["biometer:bowl"] = "bowl"
  }
  local drinking_bottles = {
    ["water_bottle"] = {des = "Water Bottle", reg = 3, par = "vessels:glass_bottle", inv = "water_bottle", sound = default.node_sound_glass_defaults(), sel_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}, form_string = true},
    ["river_water_bottle"] = {des = "River Water Bottle", reg = 4, par = "vessels:glass_bottle", inv = "river_water_bottle", sound = default.node_sound_glass_defaults(), sel_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}, form_string = true},
    ["drinking_glass_with_water"] = {des = "Drinking Glass with Water", reg = 1, par = "vessels:drinking_glass", inv = "drinking_glass_with_water_inv", sound = default.node_sound_glass_defaults(), sel_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}, form_string = true},
    ["drinking_glass_with_river_water"] = {des = "Drinking Glass with River Water", reg = 2, par = "vessels:drinking_glass", inv = "drinking_glass_with_river_water_inv", sound = default.node_sound_glass_defaults(), sel_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}, form_string = true},
    ["steel_bottle_with_water"] = {des = "Heavy Steel Bottle with Water", reg = 4, par = "vessels:steel_bottle", inv = "vessels_steel_bottle", sound = default.node_sound_defaults(), sel_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}, form_string = false},
    ["steel_bottle_with_river_water"] = {des = "Heavy Steel Bottle with River Water", reg = 5, par = "vessels:steel_bottle", inv = "vessels_steel_bottle", sound = default.node_sound_defaults(), sel_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}, form_string = false},
    ["bowl_with_water"] = {des = "Bowl with Water", reg = 1, par = "biometer:bowl", inv = "bowl_with_water_inv", sound = default.node_sound_wood_defaults(), sel_box = {-0.2500, -0.5000, -0.2500, 0.2500, -0.1250, 0.2500}, form_string = true},
    ["bowl_with_river_water"] = {des = "Bowl with River Water", reg = 2, par = "biometer:bowl", inv = "bowl_with_river_water_inv", sound = default.node_sound_wood_defaults(), sel_box = {-0.2500, -0.5000, -0.2500, 0.2500, -0.1250, 0.2500}, form_string = true}
  }

  local function get_item_list(modname)
    local result = {}

    for name, _ in pairs(minetest.registered_items) do
      if name:sub(1, #modname + 1) == modname..":" then
        local reg
        local par

        if name:find("jbo") then
          reg = 3
          par = "vessels:glass_bottle"
        elseif name:find("jcu") then
          reg = 2
          par = "vessels:drinking_glass"
        elseif name:find("jsb") then
          reg = 4
          par = "vessels:steel_bottle"
        elseif name:find("jbu") then
          reg = 5
          par = "bucket:bucket_empty"
        end

        if reg and par then
          result[name] = {reg = reg, par = par}
        end
      end
    end

    return result
  end

  for k, v in pairs(bottles_override) do
    minetest.override_item(k, {
      liquids_pointable = true,
      on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type ~= "node" then
          return
        end

        local node = minetest.get_node(pointed_thing.under)
        local name = node.name
        local player_inv = user:get_inventory()

        local bottle
        if name == "default:water_source" or name == "default:water_flowing" then
          if v == "bottle" then
            bottle = ItemStack("biometer:water_bottle")
          elseif v == "drinking_glass" then
            bottle = ItemStack("biometer:drinking_glass_with_water")
          elseif v == "steel_bottle" then
            bottle = ItemStack("biometer:steel_bottle_with_water")
          else
            bottle = ItemStack("biometer:bowl_with_water")
          end
        elseif name == "default:river_water_source" or name == "default:river_water_flowing" then
          if v == "bottle" then
            bottle = ItemStack("biometer:river_water_bottle")
          elseif v == "drinking_glass" then
            bottle = ItemStack("biometer:drinking_glass_with_river_water")
          elseif v == "steel_bottle" then
            bottle = ItemStack("biometer:steel_bottle_with_river_water")
          else
            bottle = ItemStack("biometer:bowl_with_river_water")
          end
        else
          return
        end

        if itemstack:get_count() > 1 then
          if player_inv:room_for_item("main", bottle) then
            player_inv:add_item("main", bottle)
          else
            local pos = user:get_pos()
            minetest.add_item({x = pos.x, y = pos.y + 0.7, z = pos.z}, bottle)
          end

          itemstack:take_item()
        else
          itemstack = bottle
        end

        minetest.sound_play("biometer_water", {to_player = user:get_player_name(), gain = 1.4})

        return itemstack
      end
    })
  end

  for k, v in pairs(drinking_bottles) do
    local til = ""
    local inv_img = ""
    local wie_img = ""

    if v.form_string then
      til = "biometer_"..k.."_minetest_game.png"
      inv_img = "biometer_"..v.inv.."_minetest_game.png"
      wie_img = "biometer_"..k.."_minetest_game.png"
    else
      til = v.inv..".png"
      inv_img = v.inv..".png"
      wie_img = v.inv..".png"
    end

    minetest.register_node("biometer:"..k, {
      description = S(v.des),
      tiles = {til},
      inventory_image = inv_img,
      wield_image = wie_img,
      stack_max = 1,
      drawtype = "plantlike",
      paramtype = "light",
      is_ground_content = false,
      walkable = false,
      selection_box = {
        type = "fixed",
        fixed = v.sel_box
      },
      groups = {vessel = 1, drink = 1, dig_immediate = 3, attached_node = 1},
      sounds = v.sound,
      on_use = function(itemstack, user, pointed_thing)
        biometer.set_hydr_bar(user, true, v.reg)
        minetest.sound_play("biometer_drinking", {to_player = user:get_player_name(), gain = 0.5})
        itemstack = ItemStack(v.par)

        return itemstack
      end
    })
  end

  for k, v in pairs(get_item_list("drinks")) do
    minetest.override_item(k, {
      on_use = function(itemstack, user, pointed_thing)
        local player_inv = user:get_inventory()

        biometer.set_hydr_bar(user, true, v.reg)
        minetest.sound_play("biometer_drinking", {to_player = user:get_player_name(), gain = 0.5})

        if itemstack:get_count() > 1 then
          if player_inv:room_for_item("main", v.par) then
            player_inv:add_item("main", v.par)
          else
            local pos = user:get_pos()
            minetest.add_item({x = pos.x, y = pos.y + 0.7, z = pos.z}, v.par)
          end
          itemstack:take_item()
        else
          itemstack = ItemStack(v.par)
        end

        return itemstack
      end
    })
  end
else
  local mcS = minetest.get_translator("mcl_potions")

  local allow_place = {}

  minetest.register_on_joinplayer(function(player)
    player_name = player:get_player_name()

    allow_place[player_name] = true
  end)

  --the fill_cauldron and the dispense_water_bottle function are from voxelibre

  local cauldron_levels = {
  	{ "",    "_1",  "_1r" },
  	{ "_1",  "_2",  "_2" },
  	{ "_2",  "_3",  "_3" },
  	{ "_1r", "_2r",  "_2r" },
  	{ "_2r", "_3r", "_3r" }
  }

  local fill_cauldron = function(cauldron, water_type)
    local base = "mcl_cauldrons:cauldron"
    for i = 1, #cauldron_levels do
      if cauldron == base .. cauldron_levels[i][1] then
        if water_type == "mclx_core:river_water_source" then
          return base .. cauldron_levels[i][3]
        else
          return base .. cauldron_levels[i][2]
        end
      end
    end
  end

  local function dispense_water_bottle(stack, pos, droppos, parent)
    local node = minetest.get_node(droppos)
    if node.name == "mcl_core:dirt" or node.name == "mcl_core:coarse_dirt" then
      minetest.set_node(droppos, {name = "mcl_mud:mud"})
      minetest.sound_play("mcl_potions_bottle_pour", {pos = droppos, gain = 0.5, max_hear_range = 16}, true)
      if stack:get_name() == "mcl_potions:water" or stack:get_name() == "mcl_potions:river_water" then
        return ItemStack("mcl_potions:glass_bottle")
      else
        return ItemStack("mcl_core:bowl")
      end

    elseif node.name == "mcl_mud:mud" then
      return stack
    end
  end

  local function allow_place_timer(player_name)
    minetest.after(1.6, function()
      allow_place[player_name] = true
    end)
  end

  local function mc_drink(v, itemstack, user, pointed_thing)
    local player_name = user:get_player_name()

    if allow_place[player_name] then
      allow_place[player_name] = false

      if v.def then
        itemstack = v.def(itemstack, user, pointed_thing) or itemstack
      end

      if not minetest.is_creative_enabled(user:get_player_name()) then
        local start_time = minetest.get_us_time()

        local function check_hold()
          if not user or not user:is_player() then return end
          local player_control = user:get_player_control()

          if player_control.place then
            local held_for = (minetest.get_us_time() - start_time) / 1e6

            if held_for >= 1.6 then
              biometer.set_hydr_bar(user, true, v.reg)
              allow_place_timer(player_name)
              return itemstack
            end

            minetest.after(0.1, check_hold)
          end
        end

        minetest.after(0.1, check_hold)

        allow_place_timer(player_name)
      end
    else
      return itemstack
    end
  end

  local bowls = {
    ["bowl_with_water"] = {des = "Bowl with Water", reg = 1, liq = "Water"},
    ["bowl_with_river_water"] = {des = "Bowl with River Water", reg = 2, liq = "River Water"}
  }

  for k, v in pairs(bowls) do
    minetest.register_craftitem("biometer:"..k, {
      description = S(v.des),
      inventory_image = "biometer_"..k.."_inv_mineclone.png",
    	_doc_items_longdesc = S("Bowls with @1 can be used to fill cauldrons", S(v.liq))..".",
    	_doc_items_usagehelp = mcS("Use the “Place” key to drink. Place this item on a cauldron to pour the water into the cauldron."),
      groups = {food = 3, can_eat_when_full = 1, water_bottle = 1, bottle = 1},
      stack_max = 1,
      on_secondary_use = minetest.item_eat(0, "mcl_core:bowl"),
      _on_dispense = dispense_water_bottle,
      _dispense_into_walkable = true
    })
  end

  local bottles_override = {
    ["mcl_potions:water"] = {def = minetest.registered_items["mcl_potions:water"].on_secondary_use, par = "mcl_potions:glass_bottle", reg = 3},
    ["mcl_potions:river_water"] = {def = minetest.registered_items["mcl_potions:river_water"].on_secondary_use, par = "mcl_potions:glass_bottle", reg = 4},
    ["biometer:bowl_with_water"] = {def = minetest.registered_items["biometer:bowl_with_water"].on_secondary_use, par = "mcl_core:bowl", reg = 1},
    ["biometer:bowl_with_river_water"] = {def = minetest.registered_items["biometer:bowl_with_river_water"].on_secondary_use, par = "mcl_core:bowl", reg = 2},
  }

  --[[mcl_potions.register_effect({
    name = "hydration",
  	description = S("Hydration"),
    get_tt = function(factor)
  		return ""
  	end,
  	res_condition = function(object)
  		return (not object:is_player())
  	end,
  	on_step = function(dtime, object, factor, duration)
      if object:is_player() then
  		  biometer.set_hydr_bar(object, true, factor)
      end
  	end,
  	particle_color = "#14099C",
  	uses_factor = true,
  	lvl1_factor = 3,
  	lvl2_factor = 4,
  })--]]

  for k, v in pairs(bottles_override) do
    minetest.override_item(k, {
      on_secondary_use = function(itemstack, user, pointed_thing)
        itemstack = mc_drink(v, itemstack, user, pointed_thing)

        return itemstack
      end,
      on_place = function(itemstack, placer, pointed_thing)
        player_name = placer:get_player_name()

        if pointed_thing.type == "node" then
          local pos = pointed_thing.under
          local node = minetest.get_node(pos)

          if node.name ~= "mcl_cauldrons:cauldron" and node.name ~= "mcl_cauldrons:cauldron_1" and node.name ~= "mcl_cauldrons:cauldron_2" and node.name ~= "mcl_cauldrons:cauldron_1r" and node.name ~= "mcl_cauldrons:cauldron_2r" and node.name ~= "mcl_core:dirt" and node.name ~= "mcl_core:coarse_dirt" then
            itemstack = mc_drink(v, itemstack, placer, pointed_thing)
          else
            if node.name == "mcl_core:dirt" or node.name == "mcl_core:coarse_dirt" then
              minetest.set_node(pointed_thing.under, {name = "mcl_mud:mud"})
            else
              local cauldron = "mcl_cauldrons:cauldron"

              if itemstack:get_name() == "mcl_potions:water" or itemstack:get_name() == "biometer:bowl_with_water" then
                cauldron = fill_cauldron(node.name, "mcl_core:water_source")
              else
                cauldron = fill_cauldron(node.name, "mclx_core:river_water_source")
              end

              minetest.set_node(pointed_thing.under, {name = cauldron})
            end

            minetest.sound_play("mcl_potions_bottle_pour", {pos = pointed_thing.under, gain = 0.5, max_hear_range = 16}, true)

            local player_inv = placer:get_inventory()

            if itemstack:get_count() > 1 then
              if player_inv:room_for_item("main", v.par) then
                player_inv:add_item("main", v.par)
              else
                local pos = placer:get_pos()
                minetest.add_item({x = pos.x, y = pos.y + 0.7, z = pos.z}, v.par)
              end
              itemstack:take_item()
            else
              itemstack = v.par
            end
          end

          return itemstack
        end
      end
    })
  end

  minetest.override_item("mcl_core:bowl", {
    liquids_pointable = true,
    on_place = function(itemstack, placer, pointed_thing)
      if pointed_thing.type ~= "node" then
        return
      end

      if pointed_thing and pointed_thing.type == "node" then
        local node = minetest.get_node(pointed_thing.under)
        local name = node.name

        if node.name == "mcl_core:water_source" or node.name == "mclx_core:river_water_source" or node.name == "mcl_cauldrons:cauldron_1" or node.name == "mcl_cauldrons:cauldron_2" or node.name == "mcl_cauldrons:cauldron_3" or node.name == "mcl_cauldrons:cauldron_1r" or node.name == "mcl_cauldrons:cauldron_2r" or node.name == "mcl_cauldrons:cauldron_3r" then
          local player_inv = placer:get_inventory()

          local bottle
          if name == "mcl_core:water_source" then
            bottle = ItemStack("biometer:bowl_with_water")
          elseif name == "mclx_core:river_water_source" then
            bottle = ItemStack("biometer:bowl_with_river_water")
          end

          if node.name == "mcl_cauldrons:cauldron_3" then
            bottle = ItemStack("biometer:bowl_with_water")
            minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_2"})
          elseif node.name == "mcl_cauldrons:cauldron_2" then
            bottle = ItemStack("biometer:bowl_with_water")
            minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_1"})
          elseif node.name == "mcl_cauldrons:cauldron_1" then
            bottle = ItemStack("biometer:bowl_with_water")
            minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron"})
          elseif node.name == "mcl_cauldrons:cauldron_3r" then
            bottle = ItemStack("biometer:bowl_with_river_water")
            minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_2r"})
          elseif node.name == "mcl_cauldrons:cauldron_2r" then
            bottle = ItemStack("biometer:bowl_with_river_water")
            minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_1r"})
          elseif node.name == "mcl_cauldrons:cauldron_1r" then
            bottle = ItemStack("biometer:bowl_with_river_water")
            minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron"})
          end

          minetest.sound_play("mcl_potions_bottle_pour", {pos = pointed_thing.under, gain = 0.5, max_hear_range = 16}, true)

          if bottle then
            if not minetest.is_creative_enabled(placer:get_player_name()) then
              if itemstack:get_count() > 1 then
                if player_inv:room_for_item("main", bottle) then
                  player_inv:add_item("main", bottle)
                else
                  local pos = placer:get_pos()
                  minetest.add_item({x = pos.x, y = pos.y + 0.7, z = pos.z}, bottle)
                end
                itemstack:take_item()
              else
                itemstack = bottle
              end
            else
              if not player_inv:contains_item("main", bottle) then
                player_inv:add_item("main", bottle)
              end
            end
          end
        end

        return itemstack
      end
    end
})
end

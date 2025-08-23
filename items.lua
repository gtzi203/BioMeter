
--items

local S = minetest.get_translator(minetest.get_current_modname())

if cg == "minetest_game" then
  local bottles_override = {
    ["vessels:glass_bottle"] = "bottle",
    ["vessels:drinking_glass"] = "drinking_glass"
  }
  local drinking_bottles = {
    ["water_bottle"] = {des = "Water Bottle", reg = 3, par = "vessels:glass_bottle", inv = "water_bottle"},
    ["river_water_bottle"] = {des = "River Water Bottle", reg = 4, par = "vessels:glass_bottle", inv = "river_water_bottle"},
    ["drinking_glass_with_water"] = {des = "Drinking Glass with Water", reg = 1, par = "vessels:drinking_glass", inv = "drinking_glass_with_water_inv"},
    ["drinking_glass_with_river_water"] = {des = "Drinking Glass with River Water", reg = 2, par = "vessels:drinking_glass", inv = "drinking_glass_with_river_water_inv"}
  }

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
          else
            bottle = ItemStack("biometer:drinking_glass_with_water")
          end
        elseif name == "default:river_water_source" or name == "default:river_water_flowing" then
          if v == "bottle" then
            bottle = ItemStack("biometer:river_water_bottle")
          else
            bottle = ItemStack("biometer:drinking_glass_with_river_water")
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

  for k, v in pairs (drinking_bottles) do
    minetest.register_node("biometer:"..k, {
      description = S(v.des),
      tiles = {"biometer_"..k.."_minetest_game.png"},
      inventory_image = "biometer_"..v.inv.."_minetest_game.png",
      wield_image = "biometer_"..k.."_minetest_game.png",
      stack_max = 1,
      drawtype = "plantlike",
      paramtype = "light",
      is_ground_content = false,
      walkable = false,
      selection_box = {
        type = "fixed",
        fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
      },
      groups = {vessel = 1, dig_immediate = 3, attached_node = 1},
      sounds = default.node_sound_glass_defaults(),
      on_use = function(itemstack, user, pointed_thing)
        set_hydr_bar(user, true, v.reg)
        minetest.sound_play("biometer_drinking", {to_player = user:get_player_name(), gain = 0.5})
        itemstack = ItemStack(v.par)

        return itemstack
      end
    })
  end
else
  local bottles_override = {
    ["mcl_potions:water"] = {def = minetest.registered_items["mcl_potions:water"].on_secondary_use , reg = 3},
    ["mcl_potions:river_water"] = {def = minetest.registered_items["mcl_potions:river_water"].on_secondary_use, reg = 4}
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
  		  set_hydr_bar(object, true, factor)
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
        if v.def then
          itemstack = v.def(itemstack, user, pointed_thing) or itemstack
        end

        if not minetest.is_creative_enabled(user:get_player_name()) then
          if cgs == "voxelibre" then
            local start_time = minetest.get_us_time()

            local function check_hold()
              if not user or not user:is_player() then return end
              local c = user:get_player_control()
              if c.place then
                local held_for = (minetest.get_us_time() - start_time) / 1e6
                if held_for >= 1.6 then
                  set_hydr_bar(user, true, v.reg)
                  return
                end
                minetest.after(0.1, check_hold)
              end
            end

            minetest.after(0.1, check_hold)
          else
            set_hydr_bar(user, true, v.reg)
          end
        end

        return itemstack
      end
    })
  end
end

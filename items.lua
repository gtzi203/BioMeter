
--items

local S = minetest.get_translator(minetest.get_current_modname())

if biometer.cg == "minetest_game" and minetest.get_modpath("vessels") then
    local water_types = {
        ["default:water_source"] = "water",
        ["default:water_flowing"] = "water",
        ["default:river_water_source"] = "river_water",
        ["default:river_water_flowing"] = "river_water"
    }

    local bottles_override = {
        ["vessels:glass_bottle"] = "bottle",
        ["vessels:drinking_glass"] = "drinking_glass",
        ["vessels:steel_bottle"] = "steel_bottle",
        ["biometer:bowl"] = "bowl"
    }
    local drinking_bottles = {
        ["bottle_with_water"] = {description = S("Bottle with Water"), texture = "biometer_bottle_with_water_minetest_game.png", texture_inv = "biometer_bottle_with_water_minetest_game.png", regenerate = 3, parent = "vessels:glass_bottle", sound = default.node_sound_glass_defaults(), selection_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}},
        ["bottle_with_river_water"] = {description = S("Bottle with River Water"), texture = "biometer_bottle_with_river_water_minetest_game.png", texture_inv = "biometer_bottle_with_river_water_minetest_game.png", regenerate = 4, parent = "vessels:glass_bottle", sound = default.node_sound_glass_defaults(), selection_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}},
        ["drinking_glass_with_water"] = {description = S("Drinking Glass with Water"), texture = "biometer_drinking_glass_with_water_minetest_game.png", texture_inv = "biometer_drinking_glass_with_water_inv_minetest_game.png", regenerate = 1, parent = "vessels:drinking_glass", sound = default.node_sound_glass_defaults(), selection_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}},
        ["drinking_glass_with_river_water"] = {description = S("Drinking Glass with River Water"), texture = "biometer_drinking_glass_with_river_water_minetest_game.png", texture_inv = "biometer_drinking_glass_with_river_water_inv_minetest_game.png", regenerate = 2, parent = "vessels:drinking_glass", sound = default.node_sound_glass_defaults(), selection_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}},
        ["steel_bottle_with_water"] = {description = S("Heavy Steel Bottle with Water"), texture = "vessels_steel_bottle.png", texture_inv = "vessels_steel_bottle.png", regenerate = 4, parent = "vessels:steel_bottle", sound = default.node_sound_defaults(), selection_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}},
        ["steel_bottle_with_river_water"] = {description = S("Heavy Steel Bottle with River Water"), texture = "vessels_steel_bottle.png", texture_inv = "vessels_steel_bottle.png", regenerate = 5, parent = "vessels:steel_bottle", sound = default.node_sound_defaults(), selection_box = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}},
        ["bowl_with_water"] = {description = S("Bowl with Water"), texture = "biometer_bowl_minetest_game.png", texture_inv = "biometer_bowl_with_water_inv_minetest_game.png", regenerate = 1, parent = "biometer:bowl", sound = default.node_sound_wood_defaults(), selection_box = {-0.2500, -0.5000, -0.2500, 0.2500, -0.1250, 0.2500}},
        ["bowl_with_river_water"] = {description = S("Bowl with River Water"), texture = "biometer_bowl_minetest_game.png", texture_inv = "biometer_bowl_with_river_water_inv_minetest_game.png", regenerate = 2, parent = "biometer:bowl", sound = default.node_sound_wood_defaults(), selection_box = {-0.2500, -0.5000, -0.2500, 0.2500, -0.1250, 0.2500}}
    }

    local function get_drinks_override_list()
        local list = {}

        for name, _ in pairs(minetest.registered_items) do
            if string.sub(name, 1, 7) == "drinks:" then
                local regenerate = 0

                if string.find(name, "jbo") then
                    regenerate = 3
                elseif string.find(name, "jcu") then
                    regenerate = 2
                elseif string.find(name, "jsb") then
                    regenerate = 4
                --elseif string.find(name, "jbu") then
                --    regenerate = 5
                end

                list[name] = regenerate
            end
        end

        return list
    end

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

    for name, type in pairs(bottles_override) do
        minetest.override_item(name ,{
            liquids_pointable = true,
            on_use = function(itemstack, user, pointed_thing)
                if pointed_thing.type ~= "node" then
                    return
                end

                local node_name = minetest.get_node(pointed_thing.under).name

                local water = water_types[node_name]

                if not water then
                    return itemstack
                end

                minetest.sound_play("biometer_water", {to_player = user:get_player_name(), gain = 1.4})

                return biometer.add_item_to_player(user, ItemStack("biometer:" .. type .. "_with_" .. water), itemstack)
            end
        })
    end

    for name, def in pairs(drinking_bottles) do
        minetest.register_node("biometer:" .. name, {
            description = def.description  .. "\n" .. S("Regenerates @1 hydration", def.regenerate) .. ".",
            tiles = {def.texture},
            wield_image = def.texture,
            inventory_image = def.texture_inv,
            groups = {vessel = 1, dig_immediate = 3, attached_node = 1, drink = 1},
            sounds = def.sound,
            drawtype = "plantlike",
            paramtype = "light",
            is_ground_content = false,
            walkable = false,
            stack_max = 1,
            selection_box = {
                type = "fixed",
                fixed = def.selection_box
            },
            on_use = function(itemstack, user, pointed_thing)
                return biometer.drink_item(def.regenerate, def.parent, itemstack, user)
            end
        })
    end

    for name, regenerate in pairs(get_drinks_override_list()) do
        local on_use = minetest.registered_items[name].on_use

        minetest.override_item(name ,{
            on_use = function(itemstack, user, pointed_thing)
                biometer.set_hydr(user, biometer.get_hydr(user:get_player_name()) + regenerate, false, true)

                if on_use then
                    on_use(itemstack, user, pointed_thing)
                end
            end 
        })
    end
else
    local bottles_override = {
        ["mcl_potions:water"] = {regenerate = 3, parent = "mcl_potions:glass_bottle"},
        ["mcl_potions:river_water"] = {regenerate = 4, parent = "mcl_potions:glass_bottle"}
    }

    local bowls = {
        ["bowl_with_water"] = {description = S("Bowl with Water"), texture = "biometer_bowl_with_water_inv_mineclone.png", regenerate = 1, parent = "mcl_core:bowl"},
        ["bowl_with_river_water"] = {description = S("Bowl with River Water"), texture = "biometer_bowl_with_river_water_inv_mineclone.png", regenerate = 2, parent = "mcl_core:bowl"}
    }

    --took the following functions from mineclones (voxelibres) code

    local cauldron_levels = {
        -- start = { add water, add river water }
        { "",    "_1",  "_1r" },
        { "_1",  "_2",  "_2" },
        { "_2",  "_3",  "_3" },
        { "_1r", "_2r",  "_2r" },
        { "_2r", "_3r", "_3r" },
    }

    local fill_cauldron = function(cauldron, water_type)
        local base = "mcl_cauldrons:cauldron"
        for i=1, #cauldron_levels do
            if cauldron == base .. cauldron_levels[i][1] then
                if water_type == "mclx_core:river_water_source" then
                    return base .. cauldron_levels[i][3]
                else
                    return base .. cauldron_levels[i][2]
                end
            end
        end
    end

    local function set_node_empty_bottle(itemstack, placer, pointed_thing, newitemstring, bm_def)
        local pname = placer:get_player_name()
        if core.is_protected(pointed_thing.under, pname) then
            core.record_protection_violation(pointed_thing.under, pname)
            return itemstack
        end

        -- set the node to `itemstring`
        core.set_node(pointed_thing.under, {name=newitemstring})

        -- play sound
        core.sound_play("mcl_potions_bottle_pour", {pos=pointed_thing.under, gain=0.5, max_hear_range=16}, true)

        if core.is_creative_enabled(pname) then
            return itemstack
        end

        local empty_bottle = ItemStack(bm_def.parent)
        if itemstack:get_count() == 1 then
            return empty_bottle
        end

        itemstack:take_item(1)
        local inv = placer:get_inventory()
        if inv and inv:room_for_item("main", empty_bottle) then
            inv:add_item("main", empty_bottle)
        else
            core.add_item(placer:get_pos(), empty_bottle)
        end
        return itemstack
    end

    local function water_bottles_on_place(itemstack, placer, pointed_thing, bm_def)
        if pointed_thing.type == "node" then
            local node = core.get_node(pointed_thing.under)
            local def = core.registered_nodes[node.name]

            -- Call on_rightclick if the pointed node defines it
            local new_stack = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
            if new_stack and new_stack ~= itemstack then
                return new_stack
            end

            local cauldron = nil
            if itemstack:get_name() == "mcl_potions:water" or itemstack:get_name() == "biometer:bowl_with_water" then -- regular water
                cauldron = fill_cauldron(node.name, "mcl_core:water_source")
            elseif itemstack:get_name() == "mcl_potions:river_water" or itemstack:get_name() == "biometer:bowl_with_river_water" then -- river water
                cauldron = fill_cauldron(node.name, "mclx_core:river_water_source")
            end

            if cauldron then
                return set_node_empty_bottle(itemstack, placer, pointed_thing, cauldron, bm_def)
            elseif node.name == "mcl_core:dirt" or node.name == "mcl_core:coarse_dirt" then
                return set_node_empty_bottle(itemstack, placer, pointed_thing, "mcl_mud:mud", bm_def)
            end
        end

	    -- Drink the water by default
	    return biometer.drink_item_mcl(bm_def.regenerate, bm_def.parent, itemstack, placer, pointed_thing)
    end

    local function dispense_water_bowl(stack, pos, droppos)
        local node = core.get_node(droppos)
        local nodedef = core.registered_nodes[node.name]
        if node.name == "mcl_core:dirt" or node.name == "mcl_core:coarse_dirt" then
            core.set_node(droppos, { name = "mcl_mud:mud" })
            core.sound_play("mcl_potions_bottle_pour", { pos = droppos, gain = 0.5, max_hear_range = 16 }, true)
            return ItemStack("mcl_core:bowl")
        elseif nodedef and not nodedef.walkable then
            -- Only drop into non-solid spaces (air, flowers, etc.)
            core.add_item(droppos, stack)
            stack:take_item()
            return stack
        else
            -- Solid block - do nothing, keep item in dispenser
            return stack
        end
    end

    minetest.override_item("mcl_core:bowl", {
        liquids_pointable = true,
        on_place = function(itemstack, placer, pointed_thing)
            --took this peace of code from mineclones (voxelibres) code too

            if pointed_thing.type == "node" then
                local node = core.get_node(pointed_thing.under)
                local def = core.registered_nodes[node.name]

                -- Call on_rightclick if the pointed node defines it
                local new_stack = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
                if new_stack and new_stack ~= itemstack then
                    return new_stack
                end

                -- Try to fill glass bottle with water
                local get_water = false
                --local from_liquid_source = false
                local river_water = false
                if def and def.groups and def.groups.water and def.liquidtype == "source" then
                    -- Water source
                    get_water = true
                    --from_liquid_source = true
                    river_water = node.name == "mclx_core:river_water_source"
                -- Or reduce water level of cauldron by 1
                elseif string.sub(node.name, 1, 14) == "mcl_cauldrons:" then
                    local pname = placer:get_player_name()
                    if core.is_protected(pointed_thing.under, pname) then
                        core.record_protection_violation(pointed_thing.under, pname)
                        return itemstack
                    end
                    if node.name == "mcl_cauldrons:cauldron_3" then
                        get_water = true
                        core.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_2"})
                    elseif node.name == "mcl_cauldrons:cauldron_2" then
                        get_water = true
                        core.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_1"})
                    elseif node.name == "mcl_cauldrons:cauldron_1" then
                        get_water = true
                        core.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron"})
                    elseif node.name == "mcl_cauldrons:cauldron_3r" then
                        get_water = true
                        river_water = true
                        core.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_2r"})
                    elseif node.name == "mcl_cauldrons:cauldron_2r" then
                        get_water = true
                        river_water = true
                        core.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron_1r"})
                    elseif node.name == "mcl_cauldrons:cauldron_1r" then
                        get_water = true
                        river_water = true
                        core.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron"})
                    end
                end
                if get_water then
                    local water_bottle
                    if river_water then
                        water_bottle = ItemStack("biometer:bowl_with_river_water")
                    else
                        water_bottle = ItemStack("biometer:bowl_with_water")
                    end
                    -- Replace with water bottle, if possible, otherwise
                    -- place the water potion at a place where's space
                    local inv = placer:get_inventory()
                    core.sound_play("mcl_potions_bottle_fill", {pos=pointed_thing.under, gain=0.5, max_hear_range=16}, true)
                    if core.is_creative_enabled(placer:get_player_name()) then
                        -- Don't replace empty bottle in creative for convenience reasons
                        if not inv:contains_item("main", water_bottle) then
                            inv:add_item("main", water_bottle)
                        end
                    elseif itemstack:get_count() == 1 then
                        return water_bottle
                    else
                        if inv:room_for_item("main", water_bottle) then
                            inv:add_item("main", water_bottle)
                        else
                            core.add_item(placer:get_pos(), water_bottle)
                        end
                        itemstack:take_item()
                    end
                end
            end
            return itemstack
        end
    })

    for name, def in pairs(bottles_override) do
        minetest.override_item(name, {
            on_place = function(itemstack, placer, pointed_thing)
                return water_bottles_on_place(itemstack, placer, pointed_thing, def)
            end,
            on_secondary_use = function(itemstack, user, pointed_thing)
                return water_bottles_on_place(itemstack, user, pointed_thing, def)
            end
        })
    end

    for name, def in pairs(bowls) do
        minetest.register_craftitem("biometer:" .. name, {
            description = def.description,
            inventory_image = def.texture,
            groups = {food = 3, can_eat_when_full = 1},
            stack_max = 1,
            _dispense_into_walkable = true,
            on_place = function(itemstack, placer, pointed_thing)
                return water_bottles_on_place(itemstack, placer, pointed_thing, def)
            end,
            on_secondary_use = function(itemstack, user, pointed_thing)
                return water_bottles_on_place(itemstack, user, pointed_thing, def)
            end,
            _on_dispense = dispense_water_bowl
        })
    end
end

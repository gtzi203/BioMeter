
--crafting

if cg == "minetest_game" then
  minetest.register_craft( {
    output = "biometer:bowl 1",
    recipe = {
      { "default:stick", "", "default:stick" },
      { "", "group:wood", "" }
    }
  })
end

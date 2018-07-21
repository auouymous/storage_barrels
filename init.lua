storage_barrels = {}
local MP = minetest.get_modpath("storage_barrels").."/"



-- settings

local default_max_y = 0.5 - (1/32) -- half a pixel shorter than full block
local max_y = tonumber(minetest.settings:get("storage_barrels_height")) or (0.5 + default_max_y)
if max_y < 0.25 or max_y > 1.0 then max_y = (0.5 + default_max_y) end
max_y = max_y - 0.5
storage_barrels.max_y = max_y

storage_barrels.entity_offset = default_max_y
if max_y < storage_barrels.entity_offset then storage_barrels.entity_offset = max_y end

storage_barrels.enable_liquid_barrels = not minetest.settings:get_bool("storage_barrels_disable_liquid_barrels")
storage_barrels.enable_locked_barrels = not minetest.settings:get_bool("storage_barrels_disable_locked_barrels")
storage_barrels.enable_protected_barrels = not minetest.settings:get_bool("storage_barrels_disable_protected_barrels")



-- includes

dofile(MP.."entities.lua")
dofile(MP.."particles.lua")
dofile(MP.."barrels.lua")

dofile(MP.."small_barrels.lua")
if not minetest.settings:get_bool("storage_barrels_disable_large_barrels") then
	dofile(MP.."large_barrels.lua")
end
if storage_barrels.enable_liquid_barrels then
	dofile(MP.."liquid_barrels.lua")
end
dofile(MP.."creative_barrels.lua")
if not minetest.settings:get_bool("storage_barrels_disable_barrel_mover") then
	dofile(MP.."mover.lua")
end

dofile(MP.."api.lua")
dofile(MP.."hopper_support.lua")

print("[MOD] Storage Barrels loaded")

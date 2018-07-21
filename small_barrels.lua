local top_texture = "storage_barrels_top_item_small.png"
storage_barrels.base_ndef.groups = storage_barrels.item_groups

-- 3168 is 32 stacks of 99
local max_count_small = tonumber(minetest.settings:get("storage_barrels_max_count_small")) or 3000
if max_count_small <= 0 then max_count_small = 3000 end
print("[Storage Barrels] small barrel capacity = "..max_count_small)
storage_barrels.base_ndef.max_count = max_count_small



-- Small Item Barrel Block

local ndef = table.copy(storage_barrels.base_ndef)
ndef.description = "Item Barrel"
storage_barrels.configure_item_barrel_ndef(ndef, top_texture)
minetest.register_node("storage_barrels:item", ndef)

minetest.register_craft({
	output = "storage_barrels:item 1",
	recipe = {
		{"group:wood","","group:wood"},
		{"group:wood","","group:wood"},
		{"group:wood","group:wood","group:wood"}
	}
})



-- Small Item Barrel Block - Locked

if storage_barrels.enable_locked_barrels then
	local ndef = table.copy(storage_barrels.base_ndef)
	ndef.description = "Locked Item Barrel"
	storage_barrels.configure_item_barrel_ndef(ndef, top_texture)
	storage_barrels.configure_locked_barrel_ndef(ndef)
	minetest.register_node("storage_barrels:item_locked", ndef)

	minetest.register_craft({
		output = "storage_barrels:item_locked 1",
		recipe = {
			{"group:wood","","group:wood"},
			{"group:wood","default:steel_ingot","group:wood"},
			{"group:wood","group:wood","group:wood"}
		}
	})
	minetest.register_craft({
		output = "storage_barrels:item_locked 1",
		recipe = {
			{"default:steel_ingot"},
			{"storage_barrels:item",}
		}
	})
end



-- Small Item Barrel Block - Protected

if storage_barrels.enable_protected_barrels then
	local ndef = table.copy(storage_barrels.base_ndef)
	ndef.description = "Protected Item Barrel"
	storage_barrels.configure_item_barrel_ndef(ndef, top_texture)
	storage_barrels.configure_protected_barrel_ndef(ndef)
	minetest.register_node("storage_barrels:item_protected", ndef)

	minetest.register_craft({
		output = "storage_barrels:item_protected 1",
		recipe = {
			{"group:wood","","group:wood"},
			{"group:wood","default:copper_ingot","group:wood"},
			{"group:wood","group:wood","group:wood"}
		}
	})
	minetest.register_craft({
		output = "storage_barrels:item_protected 1",
		recipe = {
			{"default:copper_ingot"},
			{"storage_barrels:item"}
		}
	})
end

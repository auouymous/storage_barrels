local top_texture = "storage_barrels_top_item_large.png"
storage_barrels.base_ndef.groups = storage_barrels.item_groups

-- 101376 is 1024 stacks of 99
local max_count_large = tonumber(minetest.settings:get("storage_barrels_max_count_large")) or 99999
if max_count_large <= 0 then max_count_large = 99999 end
print("[Storage Barrels] large barrel capacity = "..max_count_large)
storage_barrels.base_ndef.max_count = max_count_large



-- Large Item Barrel Block

local ndef = table.copy(storage_barrels.base_ndef)
ndef.description = "Large Item Barrel"
storage_barrels.configure_item_barrel_ndef(ndef, top_texture, true, true)
minetest.register_node("storage_barrels:large_item", ndef)

minetest.register_craft({
	output = "storage_barrels:large_item 1",
	recipe = {
		{"default:mese_crystal","","default:mese_crystal"},
		{"default:mese_crystal","","default:mese_crystal"},
		{"default:mese_crystal","storage_barrels:item","default:mese_crystal"}
	}
})



-- Large Item Barrel Block - Locked

if storage_barrels.enable_locked_barrels then
	local ndef = table.copy(storage_barrels.base_ndef)
	ndef.description = "Large Locked Item Barrel"
	storage_barrels.configure_item_barrel_ndef(ndef, top_texture, true, false)
	storage_barrels.configure_locked_barrel_ndef(ndef)
	minetest.register_node("storage_barrels:large_item_locked", ndef)

	minetest.register_craft({
		output = "storage_barrels:large_item_locked 1",
		recipe = {
			{"default:mese_crystal","","default:mese_crystal"},
			{"default:mese_crystal","","default:mese_crystal"},
			{"default:mese_crystal","storage_barrels:item_locked","default:mese_crystal"}
		}
	})
	minetest.register_craft({
		output = "storage_barrels:large_item_locked 1",
		recipe = {
			{"default:mese_crystal","","default:mese_crystal"},
			{"default:mese_crystal","default:steel_ingot","default:mese_crystal"},
			{"default:mese_crystal","storage_barrels:item","default:mese_crystal"}
		}
	})
	minetest.register_craft({
		output = "storage_barrels:large_item_locked 1",
		recipe = {
			{"default:steel_ingot"},
			{"storage_barrels:large_item"}
		}
	})
end



-- Large Item Barrel Block - Protected

if storage_barrels.enable_protected_barrels then
	local ndef = table.copy(storage_barrels.base_ndef)
	ndef.description = "Large Protected Item Barrel"
	storage_barrels.configure_item_barrel_ndef(ndef, top_texture, true, true)
	storage_barrels.configure_protected_barrel_ndef(ndef)
	minetest.register_node("storage_barrels:large_item_protected", ndef)

	minetest.register_craft({
		output = "storage_barrels:large_item_protected 1",
		recipe = {
			{"default:mese_crystal","","default:mese_crystal"},
			{"default:mese_crystal","","default:mese_crystal"},
			{"default:mese_crystal","storage_barrels:item_protected","default:mese_crystal"}
		}
	})
	minetest.register_craft({
		output = "storage_barrels:large_item_protected 1",
		recipe = {
			{"default:mese_crystal","","default:mese_crystal"},
			{"default:mese_crystal","default:copper_ingot","default:mese_crystal"},
			{"default:mese_crystal","storage_barrels:item","default:mese_crystal"}
		}
	})
	minetest.register_craft({
		output = "storage_barrels:large_item_protected 1",
		recipe = {
			{"default:copper_ingot"},
			{"storage_barrels:large_item"}
		}
	})
end

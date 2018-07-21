local top_texture = "storage_barrels_top_liquid_small.png"
storage_barrels.base_ndef.groups = storage_barrels.liquid_groups

local max_count_liquid = tonumber(minetest.settings:get("storage_barrels_max_count_liquid")) or 100
if max_count_liquid <= 0 then max_count_liquid = 100 end
print("[Storage Barrels] liquid barrel capacity = "..max_count_liquid)
storage_barrels.base_ndef.max_count = max_count_liquid



-- Liquid Barrel Block

local ndef = table.copy(storage_barrels.base_ndef)
ndef.description = "Liquid Barrel"
storage_barrels.configure_liquid_barrel_ndef(ndef, top_texture)
minetest.register_node("storage_barrels:liquid", ndef)

minetest.register_craft({
	output = "storage_barrels:liquid 1",
	recipe = {
		{"default:stone","","default:stone"},
		{"default:stone","","default:stone"},
		{"default:stone","bucket:bucket_empty","default:stone"}
	}
})



-- Liquid Barrel Block - Locked

if storage_barrels.enable_locked_barrels then
	local ndef = table.copy(storage_barrels.base_ndef)
	ndef.description = "Locked Liquid Barrel"
	storage_barrels.configure_liquid_barrel_ndef(ndef, top_texture)
	storage_barrels.configure_locked_barrel_ndef(ndef)
	minetest.register_node("storage_barrels:liquid_locked", ndef)

	minetest.register_craft({
		output = "storage_barrels:liquid_locked 1",
		recipe = {
			{"default:stone","","default:stone"},
			{"default:stone","default:steel_ingot","default:stone"},
			{"default:stone","bucket:bucket_empty","default:stone"}
		}
	})
	minetest.register_craft({
		output = "storage_barrels:liquid_locked 1",
		recipe = {
			{"default:steel_ingot"},
			{"storage_barrels:liquid"}
		}
	})
end



-- Liquid Barrel Block - Protected

if storage_barrels.enable_protected_barrels then
	local ndef = table.copy(storage_barrels.base_ndef)
	ndef.description = "Protected Liquid Barrel"
	storage_barrels.configure_liquid_barrel_ndef(ndef, top_texture)
	storage_barrels.configure_protected_barrel_ndef(ndef)
	minetest.register_node("storage_barrels:liquid_protected", ndef)

	minetest.register_craft({
		output = "storage_barrels:liquid_protected 1",
		recipe = {
			{"default:stone","","default:stone"},
			{"default:stone","default:copper_ingot","default:stone"},
			{"default:stone","bucket:bucket_empty","default:stone"}
		}
	})
	minetest.register_craft({
		output = "storage_barrels:liquid_protected 1",
		recipe = {
			{"default:copper_ingot"},
			{"storage_barrels:liquid"}
		}
	})
end

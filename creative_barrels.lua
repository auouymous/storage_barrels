-- Creative Item Barrel Block

storage_barrels.base_ndef.groups = storage_barrels.item_groups
storage_barrels.base_ndef.max_count = -1

local ndef = table.copy(storage_barrels.base_ndef)
ndef.description = "Creative Item Barrel"
storage_barrels.configure_item_barrel_ndef(ndef, "storage_barrels_top_item_creative.png", false, true)
storage_barrels.configure_locked_barrel_ndef(ndef)
minetest.register_node("storage_barrels:item_creative", ndef)



-- Creative Liquid Barrel Block

if storage_barrels.enable_liquid_barrels then
	storage_barrels.base_ndef.groups = storage_barrels.liquid_groups
	storage_barrels.base_ndef.max_count = -1

	local ndef = table.copy(storage_barrels.base_ndef)
	ndef.description = "Creative Liquid Barrel"
	storage_barrels.configure_liquid_barrel_ndef(ndef, "storage_barrels_top_liquid_creative.png", false, true)
	storage_barrels.configure_locked_barrel_ndef(ndef)
	minetest.register_node("storage_barrels:liquid_creative", ndef)
end

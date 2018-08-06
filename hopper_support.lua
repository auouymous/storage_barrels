--[[
	https://github.com/minetest-mods/hopper/
	- hopper mod must have ability to use functions instead of inventories

	- running the following code will patch the hopper mod
		(cd ~/.minetest/mods/hopper ; patch -p1 < ~/.minetest/mods/storage_barrels/patches/hopper.patch)

	- then add the follow line to ~/.minetest/minetest.conf
		storage_barrels_enable_hopper = true
]]

if minetest.settings:get_bool("storage_barrels_enable_hopper") and minetest.get_modpath("hopper") then
	print("[Storage Barrels] hopper support enabled")

	local function barrel_to_hopper(pos, node, taker, inv, inv_name)
		local meta = minetest.get_meta(pos)
		if not meta then return nil end -- no item
		local item = meta:get_string("item")
		if item == "" then return nil end -- no item
		if not inv:room_for_item(inv_name, item) then return nil end

		return storage_barrels.api.take_itemstack_from_barrel(pos, node, taker, 1)
	end

	hopper:add_container({
		{"top", "group:storage_item_barrel", barrel_to_hopper},
		{"side", "group:storage_item_barrel", storage_barrels.api.put_itemstack_in_barrel},
		{"bottom", "group:storage_item_barrel", storage_barrels.api.put_itemstack_in_barrel}
	})
	-- hoppers can't interact with liquid barrels
end

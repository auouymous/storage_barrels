storage_barrels.api = {}



-- returns item in barrel
storage_barrels.api.get_item_in_barrel = function(pos)
	local meta = minetest.get_meta(pos)
	if not meta then return "" end
	return meta:get_string("item")
end

-- returns count in barrel
storage_barrels.api.get_count_in_barrel = function(pos)
	local meta = minetest.get_meta(pos)
	if not meta then return 0 end
	return meta:get_int("count")
end

-- returns max count for barrel -- creative barrels return -1
storage_barrels.api.get_max_count_for_barrel = function(node)
	return minetest.registered_nodes[node.name].max_count
end



-- returns itemstack with leftovers or cleared
storage_barrels.api.put_itemstack_in_barrel = function(pos, node, what, itemstack)
	if not itemstack or itemstack:is_empty() then return itemstack end

	local meta = minetest.get_meta(pos)
	if not meta then return itemstack end
	local item = meta:get_string("item")
	local count = meta:get_int("count")
	local ndef = minetest.registered_nodes[node.name]
	local max_count = ndef.max_count

	local put_count
	if ndef.is_storage_liquid_barrel then
		local liquid_source = storage_barrels.is_valid_liquid_source(itemstack)
		if not liquid_source then return itemstack end -- wrong liquid
		if itemstack:get_name() == liquid_source then liquid_source = nil end -- consume liquid source
		put_count = storage_barrels.put_itemstack_in_barrel(pos, node, itemstack, meta, item, count, max_count, liquid_source)
	else
		put_count = storage_barrels.put_itemstack_in_barrel(pos, node, itemstack, meta, item, count, max_count, nil)
	end
	if put_count > 0 then
		minetest.log("action", what:get_player_name().." <put> "..put_count.." "..item.." in barrel at "..minetest.pos_to_string(pos))
	end
	return itemstack
end



-- returns itemstack with <= want_count or nil if barrel is empty
storage_barrels.api.take_itemstack_from_barrel = function(pos, node, what, want_count)
	if want_count <= 0 then return nil end

	local meta = minetest.get_meta(pos)
	if not meta then return nil end
	local item = meta:get_string("item")
	local count = meta:get_int("count")
	local ndef = minetest.registered_nodes[node.name]
	local max_count = ndef.max_count

	if not ndef.is_storage_item_barrel then return nil end

	local itemstack = ItemStack(item.." 1")
	local take_count = itemstack:get_stack_max()
	if want_count < take_count then take_count = want_count end
	if take_count > count and max_count > 0 then take_count = count end

	if take_count == 0 then return nil end

	count = count - take_count
	if max_count > 0 then
		meta:set_int("count", count)
		storage_barrels.update_barrel_infotext(meta, item, count, max_count, nil)
	end
	minetest.log("action", what:get_player_name().." <take> "..take_count.." "..item.." from barrel at "..minetest.pos_to_string(pos))
	itemstack:set_count(take_count)
	return itemstack
end

-- returns itemstack with <= want_count or nil if barrel is empty
storage_barrels.api.take_liquid_from_barrel = function(pos, node, what, want_count)
	if want_count <= 0 then return nil end

	local meta = minetest.get_meta(pos)
	if not meta then return nil end
	local item = meta:get_string("item")
	local count = meta:get_int("count")
	local ndef = minetest.registered_nodes[node.name]
	local max_count = ndef.max_count

	if not ndef.is_storage_liquid_barrel then return nil end

	local itemstack = ItemStack(item.." 1")
	local take_count = itemstack:get_stack_max()
	if want_count < take_count then take_count = want_count end
	if take_count > count and max_count > 0 then take_count = count end

	if take_count == 0 then return nil end

	count = count - take_count
	if max_count > 0 then
		meta:set_int("count", count)
		storage_barrels.update_barrel_infotext(meta, item, count, max_count, nil)
	end
	minetest.log("action", what:get_player_name().." <take> "..take_count.." "..item.." from barrel at "..minetest.pos_to_string(pos))
	itemstack:set_count(take_count)
	return itemstack
end

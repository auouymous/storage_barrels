local msg_put_stackable_items_only = "[STORAGE BARRELS] Only stackable items can be put in item barrels." -- put non-stackable item
local msg_put_stackable_liquids_only = "[STORAGE BARRELS] Only bucketed liquids can be put in liquid barrels." -- put non-stackable liquid
local msg_put_barrel_is_empty_item = "[STORAGE BARRELS] Right-click with a stackable item to initialize barrel." -- mass-put in uninitialized barrel
local msg_put_barrel_is_empty_liquid = "[STORAGE BARRELS] Right-click with a stackable item to initialize barrel." -- mass-put in uninitialized barrel
local msg_put_barrel_is_full = "[STORAGE BARRELS] Barrel is full."
local msg_take_barrel_use_bucket = "[STORAGE BARRELS] Punch with empty bucket to take liquid."
local msg_take_barrel_is_empty = "[STORAGE BARRELS] Barrel is empty."



storage_barrels.update_barrel_infotext = function(meta, item, count, max_count, owner)
	-- max_count==0 turns off count+item
	if owner == nil then owner = meta:get_string("owner") end
	local item_txt = ""
	if max_count < 0 then
		item_txt = ItemStack(item):get_definition().description
	elseif max_count > 0 then
		item_txt = count.." "..ItemStack(item):get_definition().description.."   "..math.floor(100*count/max_count).."%"
	end
	if owner ~= "" then
		if item_txt ~= "" then
			meta:set_string("infotext", item_txt.."\nOwned by: "..owner)
		else
			meta:set_string("infotext", "Owned by: "..owner)
		end
	else
		meta:set_string("infotext", item_txt)
	end
end



storage_barrels.put_itemstack_in_barrel = function(pos, node, itemstack, meta, item, count, max_count, liquid_source)
	if max_count < 0 then return 0 end -- can't put items in creative barrels

	-- liquid_source can be nil

	local can_put_count = max_count - count
	local put_count = itemstack:get_count()
	if put_count > can_put_count then put_count = can_put_count end

	if put_count > 0 then
		if item == "" then
			if liquid_source then
				item = liquid_source
			else
				item = itemstack:get_name()
			end
			meta:set_string("item", item)
			storage_barrels.add_barrel_entity(item, pos)
		end
		if liquid_source then
			itemstack:set_name("bucket:bucket_empty")
		else
			if put_count == itemstack:get_count() then
				itemstack:clear()
			else
				itemstack:take_item(put_count)
			end
		end
		meta:set_int("count", count + put_count)
		storage_barrels.update_barrel_infotext(meta, item, count + put_count, max_count, nil)
	end

	return put_count
end



storage_barrels.is_valid_liquid_source = function(itemstack)
	-- itemstack is a liquid bucket
	local item = itemstack:get_name()
	for _,v in pairs(bucket.liquids) do
		if v.source == item then return item end
	end
	return nil
end
storage_barrels.bucket_to_liquid_source = function(itemstack)
	-- itemstack is a liquid bucket
	local item = itemstack:get_name()
	for _,v in pairs(bucket.liquids) do
		if v.itemname == item then return v.source end
	end
	return nil
end
storage_barrels.liquid_source_to_bucket = function(item)
	-- item is a liquid source
	for _,v in pairs(bucket.liquids) do
		if v.source == item then return v.itemname end
	end
	return nil
end



local function barrel_on_rightclick_put_items(pos, node, player, itemstack)
	local meta = minetest.get_meta(pos)
	if meta ~= nil then
		local item = meta:get_string("item")
		local count = meta:get_int("count")
		local ndef = minetest.registered_nodes[node.name]
		local max_count = ndef.max_count
		local is_item_barrel = ndef.is_storage_item_barrel
		local is_liquid_barrel = ndef.is_storage_liquid_barrel
		if itemstack:get_name() == "" then
			-- hand is empty
			if item ~= "" then
				if max_count < 0 then return itemstack end -- can't put items in creative barrels, silently ignore

				-- barrel has items, insert all of item from inventory
				local player_name = player:get_player_name()
				local inv = player:get_inventory()
				local is_first = true
				local liquid_source = nil
				local liquid_bucket = nil
				if is_liquid_barrel then
					liquid_bucket = storage_barrels.liquid_source_to_bucket(item)
					if liquid_bucket then liquid_source = item end
				end
				for _,v in pairs(inv:get_list('main') or {}) do
					if (is_item_barrel and item == v:get_name()) or (is_liquid_barrel and liquid_bucket == v:get_name()) then
						local v_count = v:get_count()
						inv:remove_item('main', v)
						local put_count = storage_barrels.put_itemstack_in_barrel(pos, node, v, meta, item, count, max_count, liquid_source)
						if v_count > put_count or is_liquid_barrel then
							inv:add_item('main', v)
						end
						if put_count == 0 then break end -- barrel is full

						if is_first then
							-- only spawn particles for first stack
							storage_barrels.spawn_particles(pos, node, false)
							is_first = false
						end
						-- TODO: play sound?
						minetest.log("action", player_name.." put "..put_count.." "..item.." in barrel at "..minetest.pos_to_string(pos))

						count = count + put_count
						if count == max_count then break end -- barrel is full
					end
				end
				if count == max_count then
					minetest.chat_send_player(player_name, msg_put_barrel_is_full)
				end
			else
				minetest.chat_send_player(player:get_player_name(), msg_put_barrel_is_empty_item)    
			end
		elseif item == "" then
			-- barrel is empty
			local liquid_source = nil
			if is_liquid_barrel then liquid_source = storage_barrels.bucket_to_liquid_source(itemstack) end

			if is_item_barrel and itemstack:get_stack_max() == 1 then
				minetest.chat_send_player(player:get_player_name(), msg_put_stackable_items_only)
			elseif is_liquid_barrel and not liquid_source then
				minetest.chat_send_player(player:get_player_name(), msg_put_stackable_liquids_only)
			else
				local put_count
				if max_count < 0 then
					-- initialize to stackable item in hand
					if is_item_barrel then
						item = itemstack:get_name()
					else
						item = liquid_source
					end
					meta:set_string("item", item)
					storage_barrels.add_barrel_entity(item, pos)
					meta:set_int("count", 0)
					storage_barrels.update_barrel_infotext(meta, item, 0, max_count, nil)
				else
					-- insert stackable item in hand
					put_count = storage_barrels.put_itemstack_in_barrel(pos, node, itemstack, meta, item, count, max_count, liquid_source)
					if count + put_count == max_count then
						minetest.chat_send_player(player:get_player_name(), msg_put_barrel_is_full)
					end
				end

				storage_barrels.spawn_particles(pos, node, false)
				-- TODO: play sound?
				if max_count > 0 then
					minetest.log("action", player:get_player_name().." put "..put_count.." "..meta:get_string("item").." in barrel at "..minetest.pos_to_string(pos))
				end
			end
		else
			if max_count < 0 then return itemstack end -- can't put items in creative barrels, silently ignore

			if is_item_barrel and item ~= itemstack:get_name() then return itemstack end -- silently ignore wrong item

			local liquid_source = nil
			if is_liquid_barrel then
				liquid_source = storage_barrels.bucket_to_liquid_source(itemstack)
				if not liquid_source or item ~= liquid_source then return itemstack end -- silently ignore wrong liquid bucket
			end

			-- barrel has items and hand has same item, insert item in hand
			local put_count = storage_barrels.put_itemstack_in_barrel(pos, node, itemstack, meta, item, count, max_count, liquid_source)
			if count + put_count == max_count then
				minetest.chat_send_player(player:get_player_name(), msg_put_barrel_is_full)
			end

			if put_count > 0 then
				storage_barrels.spawn_particles(pos, node, false)
				-- TODO: play sound?
				minetest.log("action", player:get_player_name().." put "..put_count.." "..item.." in barrel at "..minetest.pos_to_string(pos))
			end
		end
	end
	return itemstack
end



local function barrel_on_punch_take_items(pos, node, player)
	local meta = minetest.get_meta(pos)
	if meta ~= nil then
		local item = meta:get_string("item")
		local count = meta:get_int("count")
		local ndef = minetest.registered_nodes[node.name]
		local max_count = ndef.max_count
		local is_item_barrel = ndef.is_storage_item_barrel
		local is_liquid_barrel = ndef.is_storage_liquid_barrel
		if max_count < 0 then count = 1 end -- creative barrel
		if item ~= "" and count > 0 then
			if is_item_barrel then
				if (player:get_player_control()["sneak"]) then
					-- take out an entire stack
					local itemstack = ItemStack(item.." 1")
					local take_count = itemstack:get_stack_max()
					if max_count < 0 then
						count = take_count -- creative barrel
					elseif take_count > count then take_count = count end

					local inv = player:get_inventory()
					local leftovers = inv:add_item("main", item.." "..take_count)
					local took_count = take_count
					if leftovers ~= nil then
						took_count = take_count - leftovers:get_count()
					end
					if took_count > 0 then
						count = count - took_count
						if max_count > 0 then
							meta:set_int("count", count)
							storage_barrels.update_barrel_infotext(meta, item, count, max_count, nil)
						end

						storage_barrels.spawn_particles(pos, node, true)
						-- TODO: play sound?
						minetest.log("action", player:get_player_name().." take "..took_count.." "..item.." from barrel at "..minetest.pos_to_string(pos))
					end
				elseif count >= 1 then
					-- take out 1 unit
					local itemstack = item.." 1"
					local inv = player:get_inventory()
					if inv:room_for_item("main", itemstack) then
						inv:add_item("main", itemstack)
						count = count - 1
						if max_count > 0 then
							meta:set_int("count", count)
							storage_barrels.update_barrel_infotext(meta, item, count, max_count, nil)
						end

						storage_barrels.spawn_particles(pos, node, true)
						-- TODO: play sound?
						minetest.log("action", player:get_player_name().." take 1 "..item.." from barrel at "..minetest.pos_to_string(pos))
					end
				end
			elseif is_liquid_barrel then
				local empty_itemstack = player:get_wielded_item()
				if empty_itemstack:get_name() ~= "bucket:bucket_empty" then
					minetest.chat_send_player(player:get_player_name(), msg_take_barrel_use_bucket)
				elseif count >= 1 then
					-- take out 1 unit
					local empty_count = empty_itemstack:get_count()
					local liquid_bucket = storage_barrels.liquid_source_to_bucket(item)
					local full_itemstack = liquid_bucket.." 1"
					local inv = player:get_inventory()
					if empty_count == 1 or inv:room_for_item("main", full_itemstack) then
						if empty_count == 1 then
							empty_itemstack:clear()
						else
							empty_itemstack:take_item(1)
						end
						player:set_wielded_item(empty_itemstack)
						inv:add_item("main", full_itemstack)
						count = count - 1
						if max_count > 0 then
							meta:set_int("count", count)
							storage_barrels.update_barrel_infotext(meta, item, count, max_count, nil)
						end

						storage_barrels.spawn_particles(pos, node, true)
						-- TODO: play sound?
						minetest.log("action", player:get_player_name().." take 1 "..liquid_bucket.." from liquid barrel at "..minetest.pos_to_string(pos))
					end
				end
			end
		end

		if count == 0 and max_count > 0 then
			minetest.chat_send_player(player:get_player_name(), msg_take_barrel_is_empty)
		end
	end
end



local function barrel_can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	if meta ~= nil and meta:get_int("count") == 0 then
		return true
	end
	return false
end



local function barrel_on_blast(pos, intensity)
	local node = minetest.get_node(pos)
	if node ~= nil then
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			local ndef = minetest.registered_nodes[node.name]
			if ndef.is_storage_item_barrel then
				local item = meta:get_string("item")
				local count = meta:get_int("count")
				local stack_max = ItemStack(item):get_stack_max()
				if count/stack_max > 16 then return end -- barrel is immune to explosions if it contains more than 16 stacks
				local drops = {}
				local i = 1
				while(count > 0) do
					local n = stack_max
					if n > count then n = count end
					drops[i] = item.." "..n
					count = count - n
					i = i + 1
				end
				drops[#drops+1] = node.name
				minetest.remove_node(pos)
				return drops
			elseif ndef.is_storage_liquid_barrel then
				local item = meta:get_string("item")
				local count = meta:get_int("count")
				local drops = {node.name}
				minetest.remove_node(pos)
				if count > 0 then
					minetest.set_node(pos, {name=item}) -- only drop one liquid block, the rest are lost
				end
				return drops
			end
		end
	end
end



local player_yaw_to_side_axis = {
	[0] = 2*4 + 0,	-- -Z
	[1] = 4*4 + 1,	-- -X
	[2] = 1*4 + 2,	-- +Z
	[3] = 3*4 + 3,	-- +X
}
local player_yaw_to_bottom_axis = {
	[0] = 5*4 + 0,	-- -Z
	[1] = 5*4 + 3,	-- -X
	[2] = 5*4 + 2,	-- +Z
	[3] = 5*4 + 1,	-- +X
}
storage_barrels.get_barrel_placement_param2 = function(node_name, placer, pointed_thing)
	local p0 = pointed_thing.under
	local p1 = pointed_thing.above
	local yaw = 0
	if placer then
		local placer_pos = placer:getpos()
		if placer_pos then
			yaw = minetest.dir_to_facedir(vector.subtract(p1, placer_pos))
		end
	end

	local ndef = minetest.registered_nodes[node_name]

	if p0.y == p1.y then
		-- barrel placed on side of block, face hole towards player
		if ndef.is_storage_liquid_barrel then return yaw end
		return player_yaw_to_side_axis[yaw]
	elseif p0.y < p1.y then
		-- barrel placed on top of block, face hole up
		return yaw
	else
		-- barrel placed on bottom of block, face hole down
		if ndef.is_storage_liquid_barrel then return yaw end
		return player_yaw_to_bottom_axis[yaw]
	end
end



local max_y = storage_barrels.max_y

storage_barrels.item_groups = {choppy = 1, oddly_breakable_by_hand = 1, storage_item_barrel = 1}
storage_barrels.liquid_groups = {choppy = 1, oddly_breakable_by_hand = 1, storage_liquid_barrel = 1}

storage_barrels.base_ndef = {
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -- {x1, y1, z1, x2, y2, z2}
			{-0.5, -0.5, -0.5, -0.375, max_y, 0.5},	-- -X
			{-0.5, -0.5, -0.5, 0.5, max_y, -0.375},	-- -Z
			{0.375, -0.5, -0.5, 0.5, max_y, 0.5},	-- +X
			{-0.5, -0.5, 0.375, 0.5, max_y, 0.5},	-- +Z
			{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}	-- bottom
		}
	},
	paramtype = "light", -- entities inside the barrel are black without this
	paramtype2 = "facedir",
	selection_box = {type = "fixed", fixed = {{-0.5, -0.5, -0.5, 0.5, max_y, 0.5}}},
	collision_box = {type = "fixed", fixed = {{-0.5, -0.5, -0.5, 0.5, max_y, 0.5}}}, -- prevent item drops from falling into barrel
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,

	node_dig_prediction = "", -- disable client-side dig prediction - requires 0.5.0

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		return minetest.item_place(itemstack, placer, pointed_thing, storage_barrels.get_barrel_placement_param2(itemstack:get_name(), placer, pointed_thing))
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			meta:set_string("item", "")
			meta:set_int("count", 0)
			meta:set_string("infotext", "")
		end
	end,

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		return barrel_on_rightclick_put_items(pos, node, clicker, itemstack)
	end,
	on_punch = function(pos, node, puncher)
		barrel_on_punch_take_items(pos, node, puncher)
	end,
	on_rotate = storage_barrels.barrel_on_rotate,
	can_dig = barrel_can_dig,
	on_blast = barrel_on_blast,
	on_destruct = storage_barrels.remove_barrel_entity
}



storage_barrels.configure_item_barrel_ndef = function(ndef, top, allow_put, allow_take)
	ndef.tiles = {top,"storage_barrels_bottom_item.png","storage_barrels_side_item.png","storage_barrels_side_item.png","storage_barrels_side_item.png","storage_barrels_side_item.png"}
	ndef.is_storage_item_barrel = true

	if minetest.get_modpath("node_io") then
		if allow_put then
			ndef.node_io_can_put_item = function(pos, node, side) return true end
			ndef.node_io_room_for_item = function(pos, node, side, itemstack, count)
				local meta = minetest.get_meta(pos)
				local item = meta:get_string("item")
				if not meta or (item ~= "" and itemstack:get_name() ~= item) then return 0 end
				local room = minetest.registered_nodes[node.name].max_count - meta:get_int("count")
				if room >= count then return count end
				return room
			end
			ndef.node_io_put_item = function(pos, node, side, putter, itemstack)
				local meta = minetest.get_meta(pos)
				local item = meta:get_string("item")
				if not meta or (item ~= "" and itemstack:get_name() ~= item) then return itemstack end
				return storage_barrels.api.put_itemstack_in_barrel(pos, node, putter, itemstack)
			end
		end
		if allow_take then
			ndef.node_io_can_take_item = function(pos, node, side) return true end
			ndef.node_io_get_item_size = function(pos, node, side)
				return 1
			end
			ndef.node_io_get_item_name = function(pos, node, side, index)
				local meta = minetest.get_meta(pos)
				if not meta then return "" end -- no item
				return meta:get_string("item")
			end
			ndef.node_io_take_item = function(pos, node, side, taker, want_item, want_count)
				local meta = minetest.get_meta(pos)
				if not meta then return nil end -- no item
				local item = meta:get_string("item")
				if item == "" or (want_item ~= nil and item ~= want_item) then return nil end -- no item
				return storage_barrels.api.take_itemstack_from_barrel(pos, node, taker, want_count)
			end
		end
	end
end
storage_barrels.configure_liquid_barrel_ndef = function(ndef, top, allow_put, allow_take)
	ndef.tiles = {top,"storage_barrels_bottom_liquid.png","storage_barrels_side_liquid.png","storage_barrels_side_liquid.png","storage_barrels_side_liquid.png","storage_barrels_side_liquid.png"}
	ndef.is_storage_liquid_barrel = true

	if minetest.get_modpath("node_io") then
		if allow_put then
			ndef.node_io_can_put_liquid = function(pos, node, side) return true end
			ndef.node_io_room_for_liquid = function(pos, node, side, liquid, millibuckets)
				local meta = minetest.get_meta(pos)
				local item = meta:get_string("item")
				if not meta or (item ~= "" and liquid ~= item) then return 0 end
				local buckets = math.floor(millibuckets / 1000)
				if buckets*1000 ~= millibuckets then return 0 end -- only accept full buckets
				local room = (minetest.registered_nodes[node.name].max_count - meta:get_int("count"))*1000
				if room >= millibuckets then return millibuckets end
				return room
			end
			ndef.node_io_put_liquid = function(pos, node, side, putter, liquid, millibuckets)
				local meta = minetest.get_meta(pos)
				local item = meta:get_string("item")
				if not meta or (item ~= "" and liquid ~= item) then return millibuckets end
				local buckets = math.floor(millibuckets / 1000)
				if buckets*1000 ~= millibuckets then return millibuckets end -- only accept full buckets
				return storage_barrels.api.put_itemstack_in_barrel(pos, node, putter, ItemStack(liquid.." "..buckets))
			end
		end
		if allow_take then
			ndef.node_io_can_take_liquid = function(pos, node, side) return true end
			ndef.node_io_get_liquid_size = function(pos, node, side)
				return 1
			end
			ndef.node_io_get_liquid_name = function(pos, node, side, index)
				local meta = minetest.get_meta(pos)
				if not meta then return "" end -- no liquid
				return meta:get_string("item")
			end
			ndef.node_io_take_liquid = function(pos, node, side, taker, want_liquid, want_millibuckets)
				local meta = minetest.get_meta(pos)
				if not meta then return nil end -- no liquid
				local liquid = meta:get_string("item")
				if liquid == "" or (want_liquid ~= nil and liquid ~= want_liquid) then return nil end -- no liquid
				local want_buckets = math.floor(want_millibuckets / 1000)
				local itemstack = storage_barrels.api.take_liquid_from_barrel(pos, node, taker, want_buckets)
				if not itemstack then return nil end
				return {name=itemstack:get_name(), millibuckets=itemstack:get_count()*1000}
			end
		end
	end
end

storage_barrels.configure_locked_barrel_ndef = function(ndef)
	local side_texture = ""
	if ndef.is_storage_item_barrel then
		side_texture = "storage_barrels_side_item_locked.png"
	elseif ndef.is_storage_liquid_barrel then
		side_texture = "storage_barrels_side_liquid_locked.png"
	end
	ndef.tiles[3] = side_texture
	ndef.tiles[4] = side_texture
	ndef.tiles[5] = side_texture
	ndef.tiles[6] = side_texture

	ndef.is_storage_locked_barrel = true

	ndef.after_place_node = function(pos, placer, itemstack, pointed_thing)
		local owner = placer:get_player_name() or ""
		if owner ~= "" then
			local meta = minetest.get_meta(pos)
			if meta ~= nil then
				meta:set_string("owner", owner)
				storage_barrels.update_barrel_infotext(meta, "", 0, 0, owner)
			end
		end
	end
	ndef.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			local owner = meta:get_string("owner")
			if owner ~= "" and owner ~= clicker:get_player_name() then return end
		end
		return barrel_on_rightclick_put_items(pos, node, clicker, itemstack)
	end
	ndef.on_punch = function(pos, node, puncher)
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			local owner = meta:get_string("owner")
			if owner ~= "" and owner ~= puncher:get_player_name() then return end
		end
		barrel_on_punch_take_items(pos, node, puncher)
	end
	ndef.on_rotate = function(pos, node, player, mode, new_param2)
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			local owner = meta:get_string("owner")
			if owner ~= "" and owner ~= player:get_player_name() then return end
		end
		return storage_barrels.barrel_on_rotate(pos, node, player, mode, new_param2)
	end
	ndef.can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		if meta ~= nil then
			local owner = meta:get_string("owner")
			if owner ~= "" and owner ~= player:get_player_name() then return false end
		end
		return barrel_can_dig(pos, player)
	end
	ndef.on_blast = function(pos, intensity) end -- locked barrels are immune to explosions
end

storage_barrels.configure_protected_barrel_ndef = function(ndef)
	local side_texture = ""
	if ndef.is_storage_item_barrel then
		side_texture = "storage_barrels_side_item_protected.png"
	elseif ndef.is_storage_liquid_barrel then
		side_texture = "storage_barrels_side_liquid_protected.png"
	end
	ndef.tiles[3] = side_texture
	ndef.tiles[4] = side_texture
	ndef.tiles[5] = side_texture
	ndef.tiles[6] = side_texture

	ndef.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if minetest.is_protected(pos, clicker:get_player_name()) then return end
		return barrel_on_rightclick_put_items(pos, node, clicker, itemstack)
	end
	ndef.on_punch = function(pos, node, puncher)
		if minetest.is_protected(pos, puncher:get_player_name()) then return end
		barrel_on_punch_take_items(pos, node, puncher)
	end
	ndef.on_rotate = function(pos, node, player, mode, new_param2)
		if minetest.is_protected(pos, player:get_player_name()) then return end
		return storage_barrels.barrel_on_rotate(pos, node, player, mode, new_param2)
	end
	ndef.can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then return false end
		return barrel_can_dig(pos, player)
	end
	ndef.on_blast = function(pos, intensity)
		-- protected barrels are immune to explosions, if inside a protection
		if minetest.is_protected(pos, "") then return end
		return barrel_on_blast(pos, intensity)
	end
end

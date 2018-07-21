local msg_barrel_mover_full = "[STORAGE BARRELS] Barrel mover has another barrel in it."
local msg_barrel_mover_empty = "[STORAGE BARRELS] Barrel mover doesn't have a barrel in it."
local msg_barrel_mover_invalid = "[STORAGE BARRELS] Barrel mover has invalid contents, did you get it from creative inventory?"

local barrel_mover_uses = tonumber(minetest.settings:get("storage_barrels_barrel_mover_uses")) or 4
if barrel_mover_uses <= 0 then
	barrel_mover_uses = 0
	print("[Storage Barrels] infinite use barrel mover enabled")
end



-- Barrel Mover Item - Empty

minetest.register_tool("storage_barrels:mover", {
	description = "Barrel Mover (sneak left-click to pick up barrel)",
	inventory_image = "storage_barrels_mover.png",
	sound = {breaks = "default_tool_breaks"},

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then return itemstack end
		if not user or not user:get_player_control()["sneak"] then return itemstack end

		local pos = pointed_thing.under

		local player_name = user:get_player_name()
		if minetest.is_protected(pos, player_name) then
			minetest.record_protection_violation(pos, player_name)
			return itemstack
		end

		local node = minetest.get_node(pos)
		local ndef = minetest.registered_nodes[node.name]
		if ndef and (ndef.is_storage_item_barrel or ndef.is_storage_liquid_barrel) then
			local tool_meta = itemstack:get_meta()
			if not tool_meta then return itemstack end

			local node_meta = minetest.get_meta(pos)
			if node_meta ~= nil then
				if ndef.is_storage_locked_barrel then
					local owner = node_meta:get_string("owner")
					if owner ~= "" and owner ~= player_name then return itemstack end
				end

				local item = node_meta:get_string("item")
				local count = node_meta:get_int("count")

				tool_meta:set_string("name", node.name)
				tool_meta:set_string("item", item)
				tool_meta:set_int("count", count)

				node_meta:set_int("count", 0)
				minetest.remove_node(pos)

				-- TODO: play sound?
				minetest.log("action", player_name.." picked up barrel ["..count.." "..item.."] at "..minetest.pos_to_string(pos))

				itemstack:set_name("storage_barrels:mover_full")
			end
		end
		return itemstack
	end,
	on_place = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then return itemstack end
		if not user then return itemstack end

		if not storage_barrels.refresh_barrel_entity(pointed_thing.under) then
			minetest.chat_send_player(user:get_player_name(), msg_barrel_mover_empty)
		end
		return itemstack
	end
})

minetest.register_craft({
	output = "storage_barrels:mover 1",
	recipe = {
		{"storage_barrels:item","",""},
		{"","default:mese_crystal",""},
		{"","","default:mese_crystal"}
	}
})



-- Barrel Mover Item - Full

local player_yaw_to_placement_offset = {
	[0] = {x=0, y=0, z=-1},	-- -Z
	[1] = {x=-1, y=0, z=0},	-- -X
	[2] = {x=0, y=0, z=1},	-- +Z
	[3] = {x=1, y=0, z=0},	-- +X
}

minetest.register_tool("storage_barrels:mover_full", {
	description = "Barrel Mover (right-click to place barrel)",
	inventory_image = "storage_barrels_mover_full.png",
	sound = {breaks = "default_tool_breaks"},
	groups = {not_in_creative_inventory = 1},

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then return itemstack end
		if not user or not user:get_player_control()["sneak"] then return itemstack end

		minetest.chat_send_player(user:get_player_name(), msg_barrel_mover_full)
		return itemstack
	end,
	on_place = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then return itemstack end
		if not user then return itemstack end

		local pos
		local p0 = pointed_thing.under
		local p1 = pointed_thing.above
		if p0.y == p1.y then
			-- barrel placed on side of block
			local yaw = 0
			local user_pos = user:getpos()
			if user_pos then
				yaw = minetest.dir_to_facedir(vector.subtract(p1, user_pos))
			end
			local offset = player_yaw_to_placement_offset[yaw]
			pos = {x = p0.x + offset.x, y = p0.y + offset.y, z = p0.z + offset.z}
		elseif p0.y < p1.y then
			-- barrel placed on top of block
			pos = {x = p0.x, y = p0.y + 1, z = p0.z}
		else
			-- barrel placed on bottom of block
			pos = {x = p0.x, y = p0.y - 1, z = p0.z}
		end

		local player_name = user:get_player_name()
		if minetest.is_protected(pos, player_name) then return itemstack end

		local tool_meta = itemstack:get_meta()
		if tool_meta ~= nil then
			local name = tool_meta:get_string("name")

			if name == "" then
				minetest.chat_send_player(user:get_player_name(), msg_barrel_mover_invalid)
				return itemstack
			end

			minetest.item_place(ItemStack(name), user, pointed_thing, storage_barrels.get_barrel_placement_param2(name, user, pointed_thing))
			local node = minetest.get_node(pos)
			local ndef = minetest.registered_nodes[node.name]
			local node_meta = minetest.get_meta(pos)
			if not ndef or not node_meta then
				minetest.remove_node(pos)
				return itemstack
			end

			local item = tool_meta:get_string("item")
			local count = tool_meta:get_int("count")
			node_meta:set_string("item", item)
			node_meta:set_int("count", count)
			storage_barrels.update_barrel_infotext(node_meta, item, count, ndef.max_count, nil)
			storage_barrels.add_barrel_entity(item, pos)
			-- TODO: play sound?
			minetest.log("action", player_name.." placed barrel ["..count.." "..item.."] at "..minetest.pos_to_string(pos))

			if barrel_mover_uses > 0 or not (creative and creative.is_enabled_for and creative.is_enabled_for(player_name)) then
				itemstack:add_wear(65535 / barrel_mover_uses)
			end

			itemstack:set_name("storage_barrels:mover")
		end
		return itemstack
	end,
})

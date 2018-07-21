if minetest.settings:get_bool("storage_barrels_disable_entities") then
	-- disable entities

	storage_barrels.remove_barrel_entity = function(pos) end
	storage_barrels.add_barrel_entity = function(item, pos) end
	storage_barrels.refresh_barrel_entity = function(pos) end
	storage_barrels.barrel_on_rotate = function(pos, node, player, mode, new_param2) end

else
	-- enable entities



	local item_entity_offset = storage_barrels.entity_offset

	local item_entity_radius
	if item_entity_offset >= 0 then
		item_entity_radius = item_entity_offset + 0.001
	else
		item_entity_radius = 0.001 - item_entity_offset
	end

	minetest.register_entity("storage_barrels:item_entity", {
		hp_max = 1,
		visual = "wielditem",
		visual_size = {x = 0.333, y = 0.333},
		textures = {"air"},
		collisionbox = {0,0,0,0,0,0},
		physical = false,
		on_blast = function(self, damage)
			-- immortal doesn't stop TNT from destroying entity
			return false, false, {} -- do_damage, do_knockback, entity_drops
		end,
		on_activate = function(self, staticdata)
			self.object:set_armor_groups({immortal = 1})
			local meta = minetest.get_meta(self.object:get_pos())
			if meta ~= nil then
				local item = meta:get_string("item")
				self.object:set_properties({textures = {item}})
			end
		end
	})



	local liquid_entity_offset = storage_barrels.entity_offset - 0.0625

	local liquid_entity_radius
	if liquid_entity_offset >= 0 then
		liquid_entity_radius = liquid_entity_offset + 0.001
	else
		liquid_entity_radius = 0.001 - liquid_entity_offset
	end

	if storage_barrels.enable_liquid_barrels then
		minetest.register_entity("storage_barrels:liquid_entity", {
			hp_max = 1,
			visual = "wielditem",
			visual_size = {x = 0.5, y = 0.0},
			textures = {"air"},
			collisionbox = {0,0,0,0,0,0},
			physical = false,
			on_blast = function(self, damage)
				-- immortal doesn't stop TNT from destroying entity
				return false, false, {} -- do_damage, do_knockback, entity_drops
			end,
			on_activate = function(self, staticdata)
				self.object:set_armor_groups({immortal = 1})
				local meta = minetest.get_meta(self.object:get_pos())
				if meta ~= nil then
					local item = meta:get_string("item")
					self.object:set_properties({textures = {item}})
				end
			end
		})
	end



	local entity_yaw = {
		[0] = 0,			-- -Z
		[1] = 1.5*math.pi,	-- -X
		[2] = math.pi,		-- +Z
		[3] = 0.5*math.pi,	-- +X
	}
	local entity_axis = {
		[0] = 0,			-- +Y
		[1] = math.pi,		-- +Z
		[2] = 0,			-- -Z
		[3] = 0.5*math.pi,	-- +X
		[4] = 1.5*math.pi,	-- -X
		[5] = 0,			-- -Y
	}
	local function set_barrel_entity_yaw(entity, rotation, param2)
		if rotation == 0 or rotation == 5 then
			entity:setyaw(entity_yaw[param2 % 4])
		else
			entity:setyaw(entity_axis[rotation])
		end
	end



	storage_barrels.remove_barrel_entity = function(pos)
		local node = minetest.get_node(pos)
		if node ~= nil then
			local ndef = minetest.registered_nodes[node.name]
			local o_name = "storage_barrels:item_entity"
			local radius = item_entity_radius
			if ndef.is_storage_liquid_barrel then
				o_name = "storage_barrels:liquid_entity"
				radius = liquid_entity_radius
			end

			local objects = minetest.get_objects_inside_radius(pos, radius)
			if objects then
				for _,o in ipairs(objects) do
					if o and o:get_luaentity() and o:get_luaentity().name == o_name then
						o:remove()
					end
				end
			end
		end
	end



	local item_entity_offsets = {
		[0] = {x=0, y=item_entity_offset, z=0},		-- +Y
		[1] = {x=0, y=0, z=item_entity_offset},		-- +Z
		[2] = {x=0, y=0, z=-item_entity_offset},	-- -Z
		[3] = {x=item_entity_offset, y=0, z=0},		-- +X
		[4] = {x=-item_entity_offset, y=0, z=0},	-- -X
		[5] = {x=0, y=-item_entity_offset, z=0},	-- -Y
	}
	local function get_barrel_item_entity_position(pos, rotation)
		local p = vector.new(pos)
		p.x = pos.x + item_entity_offsets[rotation].x
		p.y = pos.y + item_entity_offsets[rotation].y
		p.z = pos.z + item_entity_offsets[rotation].z
		return p
	end

	local liquid_entity_offsets = {
		[0] = {x=0, y=liquid_entity_offset, z=0},	-- +Y
		[1] = {x=0, y=0, z=liquid_entity_offset},	-- +Z
		[2] = {x=0, y=0, z=-liquid_entity_offset},	-- -Z
		[3] = {x=liquid_entity_offset, y=0, z=0},	-- +X
		[4] = {x=-liquid_entity_offset, y=0, z=0},	-- -X
		[5] = {x=0, y=-liquid_entity_offset, z=0},	-- -Y
	}
	local function get_barrel_liquid_entity_position(pos, rotation)
		local p = vector.new(pos)
		p.x = pos.x + liquid_entity_offsets[rotation].x
		p.y = pos.y + liquid_entity_offsets[rotation].y
		p.z = pos.z + liquid_entity_offsets[rotation].z
		return p
	end



	storage_barrels.add_barrel_entity = function(item, pos)
		local node = minetest.get_node(pos)
		if node ~= nil then
			local rotation = math.floor((node.param2 % 32) / 4)
			local ndef = minetest.registered_nodes[node.name]
			if ndef.is_storage_item_barrel then
				local position = get_barrel_item_entity_position(pos, rotation)
				local entity = minetest.add_entity(position, "storage_barrels:item_entity")
				set_barrel_entity_yaw(entity, rotation, node.param2)
			elseif ndef.is_storage_liquid_barrel then
				local position = get_barrel_liquid_entity_position(pos, rotation)
				local entity = minetest.add_entity(position, "storage_barrels:liquid_entity")
				set_barrel_entity_yaw(entity, rotation, node.param2)
			end
		end
	end



	storage_barrels.refresh_barrel_entity = function(pos)
		local meta = minetest.get_meta(pos)
		if not meta then return false end -- no item
		local item = meta:get_string("item")
		if item == "" then return false end -- no item

		local node = minetest.get_node(pos)
		if not node then return false end

		local ndef = minetest.registered_nodes[node.name]
		local o_name = "storage_barrels:item_entity"
		local radius = item_entity_radius
		if ndef.is_storage_liquid_barrel then
			o_name = "storage_barrels:liquid_entity"
			radius = liquid_entity_radius
		end

		local objects = minetest.get_objects_inside_radius(pos, radius)
		if objects then
			for _,o in ipairs(objects) do
				if o and o:get_luaentity() and o:get_luaentity().name == o_name then
					return false -- has entity
				end
			end
		end

		storage_barrels.add_barrel_entity(item, pos)
		return true
	end



	-- TODO: if swap_node() ever gets a callback, check for rotation to 1-4 from another rotation
	-- and call swap_node() again different lower 2 bits
	-- rotation 1: 2
	-- rotation 2: 0 -- no swap is needed for this
	-- rotation 3: 3
	-- rotation 4: 1
	-- this will orient the marker on bottom edge when barrel opening is on the side
	-- would be better if screwdriver allowed an adjusted param2 to be be returned
	storage_barrels.barrel_on_rotate = function(pos, node, player, mode, new_param2)
		local ndef = minetest.registered_nodes[node.name]
		if ndef.is_storage_liquid_barrel and new_param2 > 3 then return false end

		local rotation = math.floor((new_param2 % 32) / 4)

		local radius = item_entity_radius
		if ndef.is_storage_liquid_barrel then
			radius = liquid_entity_radius
		end

		local objects = minetest.get_objects_inside_radius(pos, radius)
		if objects then
			for _,o in ipairs(objects) do
				if o and o:get_luaentity() then
					local o_name = o:get_luaentity().name
					if o_name == "storage_barrels:item_entity" then
						o:set_pos(get_barrel_item_entity_position(pos, rotation))
						set_barrel_entity_yaw(o, rotation, new_param2)
					elseif o_name == "storage_barrels:liquid_entity" then
						o:set_pos(get_barrel_liquid_entity_position(pos, rotation))
						set_barrel_entity_yaw(o, rotation, new_param2)
					end
				end
			end
		end
	end

end

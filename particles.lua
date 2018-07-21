local enable_particles = not minetest.settings:get_bool("storage_barrels_disable_particles")

local particle_length = 1.0 -- distance particles travel from/to center of entity
local particle_take_offset = storage_barrels.entity_offset
local particle_put_offset = storage_barrels.entity_offset + particle_length
local particle_time = particle_length

local particle_axis = {
	[0] = {x=0, y=1, z=0},	-- +Y
	[1] = {x=0, y=0, z=1},	-- +Z
	[2] = {x=0, y=0, z=-1},	-- -Z
	[3] = {x=1, y=0, z=0},	-- +X
	[4] = {x=-1, y=0, z=0},	-- -X
	[5] = {x=0, y=-1, z=0},	-- -Y
}

storage_barrels.spawn_particles = function(pos, node, take)
	if not enable_particles then return end

	local rotation = math.floor((node.param2 % 32) / 4)
	local a = particle_axis[rotation]
	local p = {x=pos.x, y=pos.y, z=pos.z}
	local v = {x=a.x, y=a.y, z=a.z}
	if take then
		-- take: particles flow out of barrel
		p.x = p.x + particle_take_offset*a.x
		p.y = p.y + particle_take_offset*a.y
		p.z = p.z + particle_take_offset*a.z
	else
		-- put: particles flow in to barrel
		p.x = p.x + particle_put_offset*a.x
		p.y = p.y + particle_put_offset*a.y
		p.z = p.z + particle_put_offset*a.z
		v.x = v.x * -1
		v.y = v.y * -1
		v.z = v.z * -1
	end

	minetest.add_particlespawner({
		amount = 4,
		time = 0.5,
		minpos = p,
		maxpos = p,
		minvel = v,
		maxvel = v,
		minacc = {x=0, y=0, z=0},
		maxacc = {x=0, y=0, z=0},
		minexptime = particle_time,
		maxexptime = particle_time,
		minsize = 0.2,
		maxsize = 0.2,
		collisiondetection = false,
		vertical = false,
		texture = "storage_barrels_particle.png"
	})
end

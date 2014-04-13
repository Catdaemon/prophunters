local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

local allowClasses = {"prop_physics", "prop_physics_multiplayer"}

function PlayerMeta:CanDisguiseAsProp(ent)
	if !self:Alive() then return false end
	if self:Team() != 3 then return false end
	if !IsValid(ent) then return false end

	if !table.HasValue(allowClasses, ent:GetClass()) then
		return false
	end

	return true
end

function EntityMeta:IsDisguisableAs()
	if !table.HasValue(allowClasses, self:GetClass()) then
		return false
	end

	return true
end

function PlayerMeta:CanFitHull(hullx, hully, hullz)
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:GetPos()
	trace.filter = self
	trace.maxs = Vector(hullx, hully, hullz)
	trace.mins = Vector(-hullx, -hully, 0)
	local tr = util.TraceHull(trace)
	if tr.Hit then 
		return false
	end
	return true
end

function EntityMeta:GetPropSize()
	local hullxy = math.Round(math.Max(self:OBBMaxs().x - self:OBBMins().x, self:OBBMaxs().y - self:OBBMins().y) / 2)
	local hullz = math.Round(self:OBBMaxs().z - self:OBBMins().z)
	return hullxy, hullz
end

function PlayerMeta:GetPropEyePos()
	if !self:IsDisguised() then
		return self:GetShootPos()
	end
	local angles = self:EyeAngles()
	local maxs = self:GetNWVector("disguiseMaxs")
	local mins = self:GetNWVector("disguiseMins")
	local trace = {}
	trace.start = self:GetPos() + Vector(0, 0, 2) // for some reason the player sinks slightly into the ground when he lands
	trace.endpos = self:GetPos() + Vector(0, 0, maxs.z - mins.z + 10)
	local tab = ents.FindByClass("prop_ragdoll")
	table.insert(tab, ply)
	trace.filter = tab
	trace.mask = MASK_SOLID_BRUSHONLY
	local tr = util.TraceLine(trace)
	if tr.Hit then
		return tr.HitPos + (trace.start - trace.endpos):GetNormal() * 5
	else
		return trace.endpos
	end
end

function PlayerMeta:GetPropEyeTrace()
	if !self:IsDisguised() then
		return self:GetEyeTraceNoCursor()
	end
	local maxs = self:GetNWVector("disguiseMaxs")
	local mins = self:GetNWVector("disguiseMins")
	local trace = {}
	trace.start = self:GetPropEyePos()
	trace.endpos = trace.start + self:GetAimVector() * 100000
	trace.filter = self
	local tr = util.TraceLine(trace)
	return tr
end

local function checkCorner(mins, maxs, corner, ang)
	corner:Rotate(ang)
	mins.x = math.min(mins.x, corner.x)
	mins.y = math.min(mins.y, corner.y)
	maxs.x = math.max(maxs.x, corner.x)
	maxs.y = math.max(maxs.y, corner.y)
end

function PlayerMeta:CalculateRotatedDisguiseMinsMaxs()
	local maxs = self:GetNWVector("disguiseMaxs")
	local mins = self:GetNWVector("disguiseMins")
	local ang = self:EyeAngles()
	ang.p = 0

	local nmins, nmaxs = Vector(0, 0, mins.z), Vector(0, 0, maxs.z)
	checkCorner(nmins, nmaxs, Vector(maxs.x, maxs.y), ang)
	checkCorner(nmins, nmaxs, Vector(maxs.x, mins.y), ang)
	checkCorner(nmins, nmaxs, Vector(mins.x, mins.y), ang)
	checkCorner(nmins, nmaxs, Vector(mins.x, maxs.y), ang)

	-- print(mins, maxs, nmins, nmaxs)

	return nmins, nmaxs
end

function PlayerMeta:DisguiseRotationLocked()
	return self:GetNWBool("disguiseRotationLock")
end
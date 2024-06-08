local PLUGIN = PLUGIN
PLUGIN.Name = "Wisp"
PLUGIN.Description = "Creates projectiles to minimize quota consumption"
PLUGIN.Version = 1

PLUGIN.MainMaterial = Material("sprites/splodesprite")
PLUGIN.WispTable = PLUGIN.WispTable or {}
PLUGIN.MaxKeyBitsFilter = 6 --; Used for filter networking
PLUGIN.MaxKeyBits = 13 --; The same as gmod max ents bits, should be more than enough

function PLUGIN.CopyTraceResult(result)
	local copy = {}
	copy.Entity = result.Entity
	copy.Fraction = result.Fraction
	copy.FractionLeftSolid = result.FractionLeftSolid
	copy.Hit = result.Hit
	copy.HitBox = result.HitBox
	copy.HitGroup = result.HitGroup
	copy.HitNoDraw = result.HitNoDraw
	copy.HitNonWorld = result.HitNonWorld
	copy.HitNormal = Vector(result.HitNormal)
	copy.HitPos = Vector(result.HitPos)
	copy.HitSky = result.HitSky
	copy.HitTexture = result.HitTexture
	copy.HitWorld = result.HitWorld
	copy.MatType = result.MatType
	copy.Normal = Vector(result.Normal)
	copy.PhysicsBone = result.PhysicsBone
	copy.StartPos = Vector(result.StartPos)
	copy.SurfaceProps = result.SurfaceProps
	copy.StartSolid = result.StartSolid
	copy.AllSolid = result.AllSolid
	copy.SurfaceFlags = result.SurfaceFlags
	copy.DispFlags = result.DispFlags
	copy.Contents = result.Contents
	
	return copy
end

function PLUGIN.net_writekey(value)
	net.WriteUInt(value, PLUGIN.MaxKeyBits)
end

function PLUGIN.net_readkey()
	return net.ReadUInt(PLUGIN.MaxKeyBits)
end

function PLUGIN.net_writetracefilter(filter)
	if(!istable(filter))then
		filter = {filter}
	end

	local len = #filter
	
	net.WriteUInt(#filter, PLUGIN.MaxKeyBitsFilter)	--; Optimizable
	
	for key = 1, len do
		local value = filter[key]
		
		if(isstring(value))then
			net.WriteBool(true)
			net.WriteString(value)
		elseif(isentity(value))then
			net.WriteBool(false)
			net.WriteEntity(value)
		else
			ErrorNoHaltWithStack("Expected value at key " .. key .. " to be string or Entity, but got " .. type(value) .. "\n")
			return false
		end
	end
end

function PLUGIN.net_readtracefilter()
	local len = net.ReadUInt(PLUGIN.MaxKeyBitsFilter)
	local filter = {}
	
	for key = 1, len do
		local is_str = net.ReadBool()
		
		if(is_str)then
			filter[key] = net.ReadString()
		else
			filter[key] = net.ReadEntity()
		end
	end
	
	return filter
end

PLUGIN.NetworkTableFull = {
	{"Key", PLUGIN.net_writekey, PLUGIN.net_readkey},
	{"CreationTime", net.WriteFloat, net.ReadFloat},
	{"LifeTime", net.WriteFloat, net.ReadFloat},
	{"DieOnHit", net.WriteBool, net.ReadBool},
	{"NoGravity", net.WriteBool, net.ReadBool},
	{"Pos", net.WriteVector, net.ReadVector},
	{"Vel", net.WriteVector, net.ReadVector},
	{"Size", net.WriteFloat, net.ReadFloat},
	{"LoseVelocity", net.WriteFloat, net.ReadFloat},
	{"Color", net.WriteColor, net.ReadColor},
	{"TraceFilter", PLUGIN.net_writetracefilter, PLUGIN.net_readtracefilter},
}

PLUGIN.NetworkTableUpdate = {
	{"Key", PLUGIN.net_writekey, PLUGIN.net_readkey},	--; Always first
	{"Pos", net.WriteVector, net.ReadVector},
	{"Vel", net.WriteVector, net.ReadVector},
}

--; Projectiles to minimize quota consumption
--; and to encourage players to not create "insta-trace-kill" spells cause it costs absolute incredible amounts of quota to do something at a distance

--\\
--; Wisp structure:
--; SpellObject - Class_Spell
--; Size - (number) Hull trace's size
--; Color - Color of the wisp
--; Pos	- Position
--; Vel - Velocity

--; NoNetwork = false - Disable networking?
--; NoNetworkUpdate = false - Disable update networking?
--; LoseVelocity = 1 - Velocity lost per second (scaled to engine.TickInterval)
--; NoGravity = nil - Disable gravity? no gravity does not mean no air friction:troll:
--; TraceFilter = (wisp.SpellObject and wisp.SpellObject.Caster) - Functions are not supported for networking
--; SORCERY_QUOTA = 0
--; LifeTime = 5 - Time for this thing to live

--; DieOnHit = true - Die on hit?
--; CastOnHit = true - Cast Spell on surface hit
--; CastOnDeath = true - Cast Spell on <death>

--; Key = auto - Wisp's key in global table
--; SizeMins = auto - Calculated automatically
--; SizeMaxs = auto - Calculated automatically
--; CreationTime = CurTime() - Time of creation
--; LastThinkTime = CurTime() - Time of last think
--; LastUpdateTime = auto - NetCDUpdateWisp

--; Removed = auto - Set then removed
--//

--\\MetaTable
PLUGIN.Class_Wisp = {}
PLUGIN.Class_Wisp.__index = PLUGIN.Class_Wisp
PLUGIN.Class_Wisp.__tostring = function(self)
	return "Wisp [" .. self.Key .. "]"
end

function PLUGIN.Class_Wisp:Think()
	if(!PLUGIN:RunHook("WispPreThink", self))then
		if(self.LastThinkTime == CurTime())then
			self.LastThinkTime = CurTime()
			return
		end
		
		self.LastThinkTime = CurTime()
	end

	if(PLUGIN:RunHook("WispThink", self) == false)then
		return
	end

	if(self.CreationTime + self.LifeTime <= CurTime())then
		self:Die()
		return
	end

	local interval = nil
	
	if(SERVER)then
		interval = engine.TickInterval()
	else
		interval = FrameTime()
	end
	
	local physenv_gravity = physenv.GetGravity()
	local len = self.Vel:Length()
	
	if(len == 0)then
		len = 1
	end
	
	local dir = self.Vel / len
	local lose_vel = math.min(self.LoseVelocity * interval, len)
	-- self.Vel = self.Vel - dir * lose_vel
	
	if(SORCERY.Utils.IsChanged(self.Size, "Size", self))then
		self.SizeMins = Vector(-self.Size / 2, -self.Size / 2, -self.Size / 2)
		self.SizeMaxs = Vector(self.Size / 2, self.Size / 2, self.Size / 2)
	end
	
	local trace_hit = true
	local vel_vector = self.Vel
	local vel_normal = dir
	len = len - lose_vel
	local len_before = len
	local iteration = 0
	
	while trace_hit and vel_vector do
		local hull_trace = {}
		hull_trace.start = self.Pos
		hull_trace.endpos = self.Pos + vel_vector * interval
		hull_trace.mins = self.SizeMins
		hull_trace.maxs = self.SizeMaxs
		hull_trace.filter = self.TraceFilter
		local trace = util.TraceHull(hull_trace)
		self.Pos = trace.HitPos
		trace_hit = trace.Hit
		
		if(trace_hit)then
			vel_normal, len = self:Hit(trace, len)
		end
		
		if(self.Removed)then
			return
		end
		
		vel_normal = vel_normal or dir
		len = len or len_before
		vel_vector = vel_normal * len
		
		if(len < 0.001)then
			break
		end
		
		iteration = iteration + 1
		
		if(iteration > 10)then
			break
		end
	end
	
	self.Vel = vel_normal * len_before
	
	if(!self.NoGravity)then
		self.Vel = self.Vel + physenv_gravity * interval
	end
	
	if(SERVER and !self.NoNetworkUpdate)then
		if(!self.LastUpdateTime or (self.LastUpdateTime + PLUGIN.NetCDUpdateWisp <= CurTime()))then
			self.LastUpdateTime = CurTime()
			
			PLUGIN.NetworkWispUpdate(self)
		end
	end
	
	PLUGIN:RunHook("WispPostThink", self)
end

if(CLIENT)then
	function PLUGIN.Class_Wisp:Draw()
		render.SetMaterial(PLUGIN.MainMaterial)
		render.DrawSprite(self.Pos, self.Size, self.Size, self.Color)
	end
end

function PLUGIN.Class_Wisp:GetPos()
	return self.Pos	--; WARNING, POINTER
end

function PLUGIN.Class_Wisp:SetPos(pos)
	self.Pos = pos
end

function PLUGIN.Class_Wisp:GetVelocity()
	return self.Vel
end

function PLUGIN.Class_Wisp:SetVelocity(vel)
	self.Vel = vel
end

function PLUGIN.Class_Wisp:ApplyForceCenter(vel)
	self.Vel = self.Vel + vel
end

function PLUGIN.Class_Wisp:RunSpell(callback)
	if(self.SpellObject)then
		self.SpellObject:Run(callback)
	end
end

function PLUGIN.Class_Wisp:Hit(trace, len)
	if(self.CastOnHit)then
		self:RunSpell(function()
			SORCERY_SPELL.CastReason = "OnHit"
			SORCERY_SPELL.HitTrace = PLUGIN.CopyTraceResult(trace)
		end)
	end
	
	if(self.DieOnHit)then
		if(SERVER)then
			self:Die()
			return
		end
	end
	
	local trace_len = trace.Fraction * len
	local len_left = len - trace_len
	local trace_normal = trace.Normal
	local trace_angle = trace_normal:Angle()
	local surface_normal = trace.HitNormal
	
	trace_angle:RotateAroundAxis(surface_normal, 180)
	
	local new_vel_normal = -trace_angle:Forward()
	return new_vel_normal, len_left
end

function PLUGIN.Class_Wisp:Die()
	if(self.CastOnDeath)then
		self:RunSpell(function()
			SORCERY_SPELL.CastReason = "OnDeath"
		end)
	end
	
	self:Remove()
end

function PLUGIN.Class_Wisp:Remove()
	self.Removed = true
	PLUGIN.WispTable[self.Key] = nil
	
	if(SERVER)then
		if(self.CreationTime != CurTime())then
			PLUGIN.NetworkWispRemove(self)
		end
	end
end
--//

local function define_if_not_defined(tbl, key, value)
	if(tbl[key] == nil)then
		tbl[key] = value
	end
end

function PLUGIN.CreateWisp(wisp)
	setmetatable(wisp, PLUGIN.Class_Wisp)

	if(wisp.SpellObject)then
		wisp.SpellObject.Entity = wisp
	end
	
	wisp.LifeTime = wisp.LifeTime or 5
	wisp.SORCERY_QUOTA = wisp.SORCERY_QUOTA or 0
	wisp.LoseVelocity = wisp.LoseVelocity or 1	--; REDO
	define_if_not_defined(wisp, "CastOnHit", true)
	define_if_not_defined(wisp, "CastOnDeath", true)
	define_if_not_defined(wisp, "DieOnHit", true)
	define_if_not_defined(wisp, "NoNetwork", false)
	define_if_not_defined(wisp, "NoNetworkUpdate", false)
	wisp.CreationTime = wisp.CreationTime or CurTime()
	wisp.LastUpdateTime = wisp.LastUpdateTime or wisp.CreationTime
	wisp.TraceFilter = wisp.TraceFilter or (wisp.SpellObject and wisp.SpellObject.Caster)
	wisp.Key = wisp.Key or #PLUGIN.WispTable + 1
	wisp.SORCERY_IsWisp = true
	PLUGIN.WispTable[wisp.Key] = wisp

	PLUGIN:RunHook("WispPostSetup", wisp)
	
	wisp:Think()

	if(SERVER and !wisp.Removed and !wisp.NoNetwork)then
		PLUGIN.NetworkWispFull(wisp, nil)
	end
	
	PLUGIN:RunHook("WispPostCreationNetwork", wisp)

	return wisp
end

--\\Hooks
PLUGIN:AddHook("Think", function()
	for key, wisp in pairs(PLUGIN.WispTable) do
		wisp:Think()
	end
end)

PLUGIN:AddHook("SORCERY(OnQuotaEnd)", function(add)
	if(SORCERY_SPELL.Entity.SORCERY_IsWisp)then
		SORCERY_SPELL.Entity:Remove()
	end
end)

if(CLIENT)then
	PLUGIN:AddHook("PostDrawTranslucentRenderables", function(bDepth, bSkybox)
		if(!bSkybox)then
			for key, wisp in pairs(PLUGIN.WispTable) do
				wisp:Draw()	--; I wasn't able to do the think part and render part at the same time cause then it'll bounce even with game paused
			end
		end
	end)
end
--//

--\\Includes
PLUGIN:Include("sv_plugin.lua")
PLUGIN:Include("cl_plugin.lua")
--//


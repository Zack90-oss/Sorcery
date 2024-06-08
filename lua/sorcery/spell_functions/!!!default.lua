--; SORCERY_SPELL; GLOBAL The currently used spell object
--; { stack - stack of the spell }
--; { caster - player, who casted the spell }

--; SORCERY_FUNC; INTERNAL. Executing functions, Alias to SORCERY.SpellFunctions
--; You should call SORCERY_CF(funcname, preargs) anyways

--; caster now has caster.SORCERY_QUOTA var

--\\NB
--; Remember, that .Caster may not be a player
--; Stack type - Last In Last Out
--; EVERY user executable function should drain quota. even get funcs to not create a loophole to allow free server loading
--//

-- DANGEROUS, THIS WILL BE BROKEN ON LINUX

SORCERY_ClassCheckFunctionsInited = true	--; I mean, if something really fucks up and this file is not executed first.. (LINUX BLYAT)
SORCERY.ClassCheckFunctions = SORCERY.ClassCheckFunctions or {}
local cc = SORCERY.ClassCheckFunctions

SORCERY.SpellSubscriptableTypes = SORCERY.SpellSubscriptableTypes or {}
local ss = SORCERY.SpellSubscriptableTypes

--\\Locals
local function table_Count( t )
	local i = 0
	
	for k in pairs( t ) do 
		i = i + 1
		SORCERY_CF("QUOTA_ADD", -1)
	end
	
	return i
end
--//

--\\Spell Subscriptable Types; The things you can add Sorcery table to
ss["table"] = true
ss["Entity"] = true
ss["Panel"] = true
--//

--\\Generic Class check functions
cc.alwaysTrue = function(any)
	return true
end

cc.isnumber = function(any)	--; Please, do not do what I did here, name your functions like argument types (e.g. "number" and not "isnumber"). But I can still change my mind...
	if(isnumber(any))then
		return true
	else
		return false, "expected:number:got:"..type(any)
	end
end

cc.isvector = function(any)
	if(isvector(any))then
		return true
	else
		return false, "expected:vector:got:"..type(any)
	end
end

cc.isangle = function(any)
	if(isangle(any))then
		return true
	else
		return false, "expected:angle:got:"..type(any)
	end
end


cc.istable = function(any)
	if(istable(any))then
		return true
	else
		return false, "expected:table:got:"..type(any)
	end
end

cc.isstring = function(any)
	if(isstring(any))then
		return true
	else
		return false, "expected:string:got:"..type(any)
	end
end

cc.isSubscriptable = function(any)
	if(type(any) == "table" or getmetatable(any) != nil)then
		return true
	else
		return false, "expected:subscriptable:got:"..type(any)
	end
end

cc.isSpellSubscriptable = function(any) --; Yay I love data mining and exploits (surely this will be exploited one day, or not..?)
	local retval, failcode = cc.isSubscriptable(any)
	if(!retval)then
		return retval, failcode
	elseif(any.SORCERY_SpellTableAllowed or (!any.SORCERY_SpellTableDisallowed and ss[type(any)]))then
		return true
	else
		return false, "expected:spell_subscriptable:got:"..type(any)
	end
end

cc.hasMethod__mul = cc.CompileMethodCheck("__mul", true)
cc.hasMethod__add = cc.CompileMethodCheck("__add", true)
cc.hasMethod__sub = cc.CompileMethodCheck("__sub", true)
cc.hasMethod__div = cc.CompileMethodCheck("__div", true)

cc.hasFunction_GetPos = cc.CompileMethodCheck("GetPos", false)
cc.hasFunction_EyePos = cc.CompileMethodCheck("EyePos", false)
cc.hasFunction_GetAimVector = cc.CompileMethodCheck("GetAimVector", false)
cc.hasFunction_GetAngles = cc.CompileMethodCheck("GetAngles", false)
--//

SORCERY.SpellFunctions = SORCERY.SpellFunctions or {}
local f = SORCERY.SpellFunctions

--\\Generic Stack control
f["PUSH"] = {
	func = function(var)
		SORCERY_SPELL.Stack[#SORCERY_SPELL.Stack + 1] = var
	end,
	quota = -1,
}

f["POP"] = {
	func = function(int)
		int = int or 1
		SORCERY_SPELL.Stack[#SORCERY_SPELL.Stack - (int - 1)] = nil
		
		if(int != 1)then
			SORCERY.Utils.ShiftTable(SORCERY_SPELL.Stack)
		end
	end,
	quota = -1,
}

f["POPMULTI"] = {
	func = function(int)
		int = math.max(int, 1)
		
		for i = 0, int - 1 do
			SORCERY_CF("QUOTA_ADD", -1)
			SORCERY_SPELL.Stack[#SORCERY_SPELL.Stack] = nil
		end
		
		-- SORCERY.Utils.ShiftTable(SORCERY_SPELL.Stack)
	end,
	args = {
		cc.isnumber,
	},
}

f["READ"] = {
	func = function(int)
		return SORCERY_SPELL.Stack[#SORCERY_SPELL.Stack - ((int or 1) - 1)]
	end,
}
--//

--\\Quato(Quata, i mean, Quota (try typing "Quota" yourself and post results in comments)) control
f["QUOTA_ADD"] = {
	func = function(add)
		if(add < 0)then
			if(SORCERY_SPELL.Entity.SORCERY_QUOTA > 0)then
				SORCERY_SPELL.Entity.SORCERY_QUOTA = SORCERY_SPELL.Entity.SORCERY_QUOTA + add
				
				hook.Run("SORCERY(OnQuotaChange)", add)
			else
				hook.Run("SORCERY(OnQuotaChangeFailed)", add)
			end
		else
			SORCERY_SPELL.Entity.SORCERY_QUOTA = SORCERY_SPELL.Entity.SORCERY_QUOTA + add
			
			hook.Run("SORCERY(OnQuotaChange)", add)
		end
	end,
}

f["QUOTA_GET"] = {
	func = function()
		SORCERY_CF("PUSH", SORCERY_SPELL.Entity.SORCERY_QUOTA)
	end,
	quota = -1,
}
--//

--\\Pushers
f["CASTER"] = {
	func = function()
		SORCERY_CF("PUSH", SORCERY_SPELL.Caster)
	end,
	pushvals = "entity",
	quota = -1,
}

f["ENTITY"] = {
	func = function()
		SORCERY_CF("PUSH", SORCERY_SPELL.Entity)
	end,
	pushvals = "entity",
	quota = -1,
}
--//

--\\Spell control
f["STOP"] = {
	func = function(any)
		SORCERY.HaltSpell(any, "STOP")
	end,
	args = {
		cc.alwaysTrue,
	},
}

f["STOP_SILENT"] = {
	func = function()
		SORCERY.HaltSpell(nil, "STOP_SILENT")
	end,
}
--//

--\\Debugers
f["SAY"] = {
	func = function(any)
		SORCERY:ChatPrint(SORCERY_SPELL.Caster, tostring(any))
		--; Yes, there is no POP because it is a debug function
	end,
	args = {
		cc.alwaysTrue,
	},
	quota = -1,
}
--//

--\\Math Pushers
f["M_INF"] = {
	func = function(var, mul)
		SORCERY_CF("PUSH", math.huge)
	end,
	pushvals = "number",
	quota = -1,
}
--//

--\\Maths
f["ADD"] = {
	func = function(var, var2)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", var + var2)
	end,
	args = {
		cc.hasMethod__add,
		cc.hasMethod__add,
	},
	pushvals = "number|vector|+any",
	quota = -1,
}

f["SUB"] = {
	func = function(var, var2)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", var - var2)
	end,
	args = {
		cc.hasMethod__sub,
		cc.hasMethod__sub,
	},
	pushvals = "number|vector|+any",
	quota = -1,
}

f["MUL"] = {
	func = function(var, mul)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", var * mul)
	end,
	args = {
		cc.hasMethod__mul,
		cc.hasMethod__mul,
	},
	pushvals = "number|+any",
	quota = -2,
}

f["DIV"] = {
	func = function(var, div)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", var / div)
	end,
	args = {
		cc.hasMethod__div,
		cc.hasMethod__div,
	},
	pushvals = "number|+any",
	quota = -2,
}

f["POW"] = {
	func = function(var, pow)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", math.pow(pow))
	end,
	args = {
		cc.isnumber,
		cc.isnumber,
	},
	pushvals = "number",
	quota = -2,
}

f["ABS"] = {
	func = function(var)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", math.abs(var))
	end,
	args = {
		cc.isnumber,
	},
	pushvals = "number",
	quota = -1,
}

f["EXP"] = {
	func = function(pow)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", math.exp(pow))
	end,
	args = {
		cc.isnumber,
	},
	pushvals = "number",
	quota = -2,
}
--//

--\\Users
--=\\Sorcery Table
f["STABLE_GET"] = {
	func = function(target, key)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", SORCERY.Utils:GetSorceryTableValue(target, key))
	end,
	args = {
		cc.isSpellSubscriptable,
		cc.alwaysTrue,	--; Is it though....
	},
	pushvals = "any",
	quota = -1,
}

f["STABLE_SET"] = {	--; DANGEROUS UNSUPERVISED MEMORY LOAD
	func = function(target, key, value)
		SORCERY_CF("POPMULTI", 3)
		SORCERY.Utils:SetSorceryTableValue(target, key, value)
	end,
	args = {
		cc.isSpellSubscriptable,
		cc.alwaysTrue,
		cc.alwaysTrue,
	},
	quota = -1,
}

f["STABLE_APPEND"] = {
	func = function(target, value)
		SORCERY_CF("POPMULTI", 2)
		SORCERY.Utils:SetSorceryTableValue(target, SORCERY.Utils:GetSorceryTableSize(target) + 1, value)
	end,
	quota = -1,
}

f["STABLE_SIZE"] = {
	func = function(target)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", SORCERY.Utils:GetSorceryTableSize(target))
	end,
	args = {
		cc.isSpellSubscriptable,
	},
	pushvals = "number",
	quota = -1,
}

f["STABLE_POWER"] = {
	func = function(target)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", SORCERY.Utils:GetSorceryTablePower(target))
	end,
	args = {
		cc.isSpellSubscriptable,
	},
	pushvals = "number",
	quota = -1,
}
--=//

--=\\Table
f["TABLE_CREATE"] = {
	func = function()
		SORCERY_CF("PUSH", {})
	end,
	pushvals = "table",
	quota = -2,
}

f["TABLE_GET"] = {
	func = function(target, key)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", target[key])
	end,
	args = {
		cc.istable,
		cc.alwaysTrue,	--; Is it though....
	},
	pushvals = "any",
	quota = -1,
}

f["TABLE_SET"] = {
	func = function(target, key, value)
		SORCERY_CF("POPMULTI", 3)
		
		target[key] = value
	end,
	args = {
		cc.istable,
		cc.alwaysTrue,
		cc.alwaysTrue,
	},
	quota = -1,
}

f["TABLE_APPEND"] = {
	func = function(target, value)
		SORCERY_CF("POPMULTI", 2)
		
		target[#target + 1] = value
	end,
	args = {
		cc.istable,
		cc.alwaysTrue,
	},
	quota = -1,
}
--=//

--=\\Vectors
f["VECTOR_CREATE"] = {
	func = function(x, y, z)
		SORCERY_CF("POPMULTI", 3)
		SORCERY_CF("PUSH", Vector(x, y, z))
	end,
	args = {
		cc.isnumber,
		cc.isnumber,
		cc.isnumber,
	},
	pushvals = "vector",
	quota = -3,
}

f["VECTOR_LENSQR"] = {
	func = function(vector)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", vector:LengthSqr())
	end,
	args = {
		cc.isvector,
	},
	pushvals = "number",
	quota = -1,
}

f["VECTOR_GET"] = {
	func = function(vector, key)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", vector[key])
	end,
	args = {
		cc.isvector,
		cc.isnumber,	--; Can we get a real vector with more than 3 coordinates?
	},
	pushvals = "number",
	quota = -1,
}

f["VECTOR_SET"] = {
	func = function(vector, key, value)
		SORCERY_CF("POPMULTI", 3)
		
		vector[key] = value
	end,
	args = {
		cc.isvector,
		cc.isnumber,	--; Can we get a real vector with more than 3 coordinates?
		cc.isnumber,
	},
	quota = -1,
}
--=//

--=\\Angles
f["ANGLE_CREATE"] = {
	func = function(p, y, r)
		SORCERY_CF("POPMULTI", 3)
		SORCERY_CF("PUSH", Angle(p, y, r))
	end,
	args = {
		cc.isnumber,
		cc.isnumber,
		cc.isnumber,
	},
	pushvals = "angle",
	quota = -3,
}

f["ANGLE_GET"] = {
	func = function(angle, key)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", angle[key])
	end,
	args = {
		cc.isangle,
		cc.isnumber,
	},
	pushvals = "number",
	quota = -1,
}

f["ANGLE_SET"] = {
	func = function(angle, key, value)
		SORCERY_CF("POPMULTI", 3)
		
		angle[key] = value
	end,
	args = {
		cc.isangle,
		cc.isnumber,
		cc.isnumber,
	},
	quota = -1,
}

f["ANGLE_FORWARD"] = {
	func = function(angle)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", angle:Forward())
	end,
	args = {
		cc.isangle,
	},
	pushvals = "vector",
	quota = -2,
}

f["ANGLE_RIGHT"] = {
	func = function(angle)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", angle:Right())
	end,
	args = {
		cc.isangle,
	},
	pushvals = "vector",
	quota = -2,
}

f["ANGLE_UP"] = {
	func = function(angle)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", angle:Up())
	end,
	args = {
		cc.isangle,
	},
	pushvals = "vector",
	quota = -2,
}
--=//

--=\\Strings
f["STRING_GET"] = {
	func = function(str, key)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", str[key])
	end,
	args = {
		cc.isstring,
		cc.isnumber,
	},
	pushvals = "string",
	quota = -1,
}
--=//

--=\\Misc Functions
f["SIZE"] = {
	func = function(target)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", table_Count(target))
	end,
	args = {
		cc.istable,
	},
	pushvals = "number",
	quota = -1,
}

f["LEN"] = {
	func = function(target)
		SORCERY_CF"POP"
		
		if(isvector(target))then
			SORCERY_CF("QUOTA_ADD", -1)
			SORCERY_CF("PUSH", target:Length())
		else
			SORCERY_CF("PUSH", #target)
		end
	end,
	args = {
		cc.isSubscriptable,
	},
	pushvals = "number",
	quota = -1,
}
--=//

f["QTRACE"] = {
	func = function(start, dir)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", util.QuickTrace(start, dir, SORCERY_SPELL.Entity))
	end,
	args = {
		cc.isvector,
		cc.isvector,
	},
	pushvals = "table",
	quota = -5,
}
--//

--\\Meta Functions
f["POS"] = {
	func = function(ent)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", Vector(ent:GetPos()))	--; Why?, because some people may give access to pos like "return self.Pos" and this can be exploited
	end,
	args = {
		cc.GetCompiledMethodCheck("GetPos"),
	},
	pushvals = "vector",
	quota = -1,
}

f["EYEPOS"] = {
	func = function(ent)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", Vector(ent:EyePos()))
	end,
	args = {
		cc.GetCompiledMethodCheck("EyePos"),
	},
	pushvals = "vector",
	quota = -1,
}

f["AIMVEC"] = {
	func = function(ent)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", Vector(ent:GetAimVector()))
	end,
	args = {
		cc.GetCompiledMethodCheck("GetAimVector"),
	},
	pushvals = "vector",
	quota = -1,
}

f["ANGLES"] = {
	func = function(ent)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", Vector(ent:GetAngles()))
	end,
	args = {
		cc.GetCompiledMethodCheck("GetAngles"),
	},
	pushvals = "angle",
	quota = -1,
}
--//

--\\Run
f["GET_CAST_REASON"] = {
	func = function(info)
		SORCERY_CF("PUSH", SORCERY_SPELL.CastReason)
	end,
	pushvals = "string|nil",
	quota = -1,
}
--//

--\\Wisps
f["WISP_EX"] = {
	func = function(info)
		SORCERY_CF"POP"
		
		if(!isvector(info.Pos) or !isvector(info.Velocity))then
			SORCERY.HaltSpell("invalid_args", "WISP_EX")
		end
		
		if(info.NoGravity)then
			SORCERY_CF("QUOTA_ADD", -30)	--; UNUSED Expensive
		end
		
		local PLUGIN_Wisp = SORCERY.Plugin.Get("wisp")
		local PLUGIN_Spell = SORCERY.Plugin.Get("spell")
		local wisp = {}
		local wisp.Pos = info.Pos
		local wisp.Velocity = info.Velocity
		
		SORCERY_CF("PUSH", PLUGIN_Wisp.CreateWisp(wisp))
	end,
	args = {
		cc.istable,
	},
	pushvals = "wisp",
	quota = -15,
}
--//
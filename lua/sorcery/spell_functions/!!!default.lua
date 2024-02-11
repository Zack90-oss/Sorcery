-- SORCERY_SPELL; GLOBAL The currently used spell table
-- { stack - stack of the spell }
-- { caster - player, who casted the spell }

-- SORCERY_FUNC; Executing functions, Alias to SORCERY.SpellFunctions

--TODO; Make errors occur from here, any exceptions will be marked as "Unknown error"

SORCERY_ClassCheckFunctionsInited = true	--I mean, if something really fucks up and this file is not executed first..
SORCERY.ClassCheckFunctions = SORCERY.ClassCheckFunctions or {}
local cc = SORCERY.ClassCheckFunctions

--\\locals
local function compileMethodCheck(method, cannumber)
	local fc = "local args = { ... } local any = args[1]\n"
	fc = fc.."cc = SORCERY.ClassCheckFunctions"
	if(cannumber)then
	fc = fc..[[
	if(cc.isnumber(any))then
		return true
	end
]]
	end
	fc = fc..[[
	local retval, failcode = cc.isSubscriptable(any)
	if(!retval)then
		return retval, failcode
	end
	if(isfunction(any.]]..method..[[))then
		return true
	else
		return false, "no_method"
	end
]]
	return CompileString(fc, "cc_MethodCheck")
end
--//

--\\Generic Class check functions
cc.alwaysTrue = function(any)
	return true
end

cc.isnumber = function(any)
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

cc.istable = function(any)
	if(istable(any))then
		return true
	else
		return false, "expected:table:got:"..type(any)
	end
end

cc.isSubscriptable = function(any)
	if(getmetatable(any) != nil)then
		return true
	else
		return false, "expected:subscriptable:got:"..type(any)
	end
end

cc.hasMethod__mul = compileMethodCheck("__mul", true)

cc.hasFunction_GetPos = compileMethodCheck("GetPos", false)
cc.hasFunction_EyePos = compileMethodCheck("EyePos", false)
cc.hasFunction_GetAimVector = compileMethodCheck("GetAimVector", false)
--//

SORCERY.SpellFunctions = SORCERY.SpellFunctions or {}
local f = SORCERY.SpellFunctions

--\\Generic Stack control
f["PUSH"] = {
	func = function(var)
		SORCERY_SPELL.stack[#SORCERY_SPELL.stack + 1] = var
	end,
}

f["POP"] = {
	func = function(int)
		SORCERY_SPELL.stack[#SORCERY_SPELL.stack - ((int or 1) - 1)] = nil
		SORCERY:ShiftTable(SORCERY_SPELL.stack)
	end,
}

f["POPMULTI"] = {
	func = function(int)
		int = math.max(int, 1)
		for i = 0, int - 1 do
			SORCERY_SPELL.stack[#SORCERY_SPELL.stack] = nil
		end
		SORCERY:ShiftTable(SORCERY_SPELL.stack)
	end,
	args = {
		cc.isnumber,
	},
}

f["READ"] = {
	func = function(int)
		return SORCERY_SPELL.stack[#SORCERY_SPELL.stack - ((int or 1) - 1)]
	end,
}
--//

--\\Pushers
f["CASTER"] = {
	func = function()
		SORCERY_CF("PUSH", SORCERY_SPELL.caster)
	end,
}

f["ENTITY"] = {
	func = function()
		SORCERY_CF("PUSH", SORCERY_SPELL.entity)
	end,
}
--//

--\\Debugers
f["SAY"] = {
	func = function(any)
		SORCERY:ChatPrint(SORCERY_SPELL.caster, tostring(any))
		--Yes, there is no POP because it is a debug function
	end,
	args = {
		cc.alwaysTrue,
	},
}
--//

--\\Math Pushers
f["M_INF"] = {
	func = function(var, mul)
		SORCERY_CF("PUSH", math.huge)
	end,
}
--//

--\\Maths
f["M_MUL"] = {
	func = function(var, mul)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", var * mul)
	end,
	args = {
		cc.hasMethod__mul,
		cc.hasMethod__mul,
	},
}
--//

--\\Users
f["POS"] = {
	func = function(ent)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", ent:GetPos())
	end,
	args = {
		cc.hasFunction_GetPos,
	},
}

f["EYEPOS"] = {
	func = function(ent)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", ent:EyePos())
	end,
	args = {
		cc.hasFunction_EyePos,
	},
}

f["AIMVEC"] = {
	func = function(ent)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", ent:GetAimVector())
	end,
	args = {
		cc.hasFunction_GetAimVector,
	},
}

f["QTRACE"] = {
	func = function(start, dir)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", util.QuickTrace( start, dir, SORCERY_SPELL.entity).Entity)
	end,
	args = {
		cc.isvector,
		cc.isvector,
	},
}
--//
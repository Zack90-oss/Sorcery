-- SORCERY_SPELL; GLOBAL The currently used spell table
-- { stack - stack of the spell }
-- { caster - player, who casted the spell }

-- SORCERY_FUNC; INTERNAL. Executing functions, Alias to SORCERY.SpellFunctions
-- You should call SORCERY_CF(funcname, preargs) anyways

SORCERY_ClassCheckFunctionsInited = true	--I mean, if something really fucks up and this file is not executed first..
SORCERY.ClassCheckFunctions = SORCERY.ClassCheckFunctions or {}
local cc = SORCERY.ClassCheckFunctions

SORCERY.SpellSubscriptableTypes = SORCERY.SpellSubscriptableTypes or {}
local ss = SORCERY.SpellSubscriptableTypes

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
	elseif(isfunction(any.]]..method..[[))then
		return true
	else
		return false, "no_method"
	end
]]
	return CompileString(fc, "cc_MethodCheck")
end
--//

--\\
ss["table"] = true
ss["Entity"] = true
ss["Panel"] = true
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
	if(type(any) == "table" or getmetatable(any) != nil)then
		return true
	else
		return false, "expected:subscriptable:got:"..type(any)
	end
end

cc.isSpellSubscriptable = function(any) --Yay I love data mining and exploits (surely this will be exploited one day, or not..?)
	local retval, failcode = cc.isSubscriptable(any)
	if(!retval)then
		return retval, failcode
	elseif(any.SORCERY_SpellTableAllowed or (!any.SORCERY_SpellTableDisallowed and ss[type(any)]))then
		return true
	else
		return false, "expected:spell_subscriptable:got:"..type(any)
	end
end
cc.isSpellSetSubscriptable = function(any)
	local retval, failcode = cc.isSpellSubscriptable
	if(!retval)then
		return retval, failcode
	elseif(!isstring(any))then
		return true
	else
		return false, "expected:spell_set_subscriptable:got:"..type(any)
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
		SORCERY.Utils:ShiftTable(SORCERY_SPELL.stack)
	end,
}

f["POPMULTI"] = {
	func = function(int)
		int = math.max(int, 1)
		for i = 0, int - 1 do
			SORCERY_SPELL.stack[#SORCERY_SPELL.stack] = nil
		end
		SORCERY.Utils:ShiftTable(SORCERY_SPELL.stack)
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

--\\Table utilization
f["TABLE_GET"] = {
	func = function(target, key)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", SORCERY.Utils:GetSorceryTableValue(target, key))
	end,
	args = {
		cc.isSpellSubscriptable,
		cc.alwaysTrue,	--Is it though....
	},
}

f["TABLE_SET"] = {
	func = function(target, key, value)
		SORCERY_CF("POPMULTI", 3)
		SORCERY_CF("PUSH", SORCERY.Utils:SetSorceryTableValue(target, key, value))
	end,
	args = {
		cc.isSpellSetSubscriptable,
		cc.alwaysTrue,	--Is it though....
		cc.alwaysTrue,
	},
}

f["TABLE_APPEND"] = {
	func = function(target, value)
		SORCERY_CF("POPMULTI", 2)
		SORCERY_CF("PUSH", SORCERY.Utils:SetSorceryTableValue(target, SORCERY.Utils:GetSorceryTableSize(target) + 1, value))
	end,
	args = {
		cc.isSpellSetSubscriptable,
		cc.alwaysTrue,
	},
}

f["TABLE_SIZE"] = {
	func = function(target)
		SORCERY_CF"POP"
		SORCERY_CF("PUSH", SORCERY.Utils:GetSorceryTableSize(target))
	end,
	args = {
		cc.isSpellSubscriptable,
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
		local trace = {}
		SORCERY.Utils:SetSorceryTable(trace, util.QuickTrace(start, dir, SORCERY_SPELL.entity))
		SORCERY_CF("PUSH", trace)
	end,
	args = {
		cc.isvector,
		cc.isvector,
	},
}
--//
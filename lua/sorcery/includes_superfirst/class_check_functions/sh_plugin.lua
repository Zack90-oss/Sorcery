--\\Generic Class check functions
local cc = SORCERY.ClassCheckFunctions

cc.alwaysTrue = function(any)
	return true
end

cc.isnumber = function(any)	--; Please, do not do what I did here, name your functions like argument types (e.g. "number" and not "isnumber"). But I can still change my mind...
	if(isnumber(any))then
		return true
	else
		return false, "expected:number:got:" .. type(any)
	end
end

cc.isvector = function(any)
	if(isvector(any))then
		return true
	else
		return false, "expected:vector:got:" .. type(any)
	end
end

cc.isangle = function(any)
	if(isangle(any))then
		return true
	else
		return false, "expected:angle:got:" .. type(any)
	end
end


cc.istable = function(any)
	if(istable(any))then
		return true
	else
		return false, "expected:table:got:" .. type(any)
	end
end

cc.isstring = function(any)
	if(isstring(any))then
		return true
	else
		return false, "expected:string:got:" .. type(any)
	end
end

cc.isSubscriptable = function(any)
	if(type(any) == "table" or getmetatable(any) != nil)then
		return true
	else
		return false, "expected:subscriptable:got:" .. type(any)
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
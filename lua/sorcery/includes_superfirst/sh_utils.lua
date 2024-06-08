--\\String Lowering
--; Thanks to noaccess, for pointing me to more performance-friendly approach described in https://github.com/Be1zebub/Small-GLua-Things/blob/master/sh_utf8.lua
--; https://www.charset.org/utf-8
--; TODO; actually check perfomances
SORCERY.String = SORCERY.String or {}
SORCERY.String.StringPattern = utf8.charpattern --; "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"

SORCERY.String.StringLowerMeta = {}
setmetatable(SORCERY.String.StringLowerMeta, {
	__index = function(self, char)
		return rawget(self, char) or string.lower(char)
	end
})

function SORCERY:StringLower(str)
	return (string.gsub(str, SORCERY.String.StringPattern, SORCERY.String.StringLowerMeta))
end

function SORCERY:RegisterStringLowerCodes(start, stop, difference)
	for code = start, stop do
		SORCERY.String.StringLowerMeta[string.char(code)] = string.char(code + difference)
	end
end
--//

--\\Utils
SORCERY.Utils = SORCERY.Utils or {}

--=\\Is ChangedTable
local ChangedTable={}

function SORCERY.Utils.IsChanged(val, id, meta)
	if(meta==nil)then 
		meta = ChangedTable 
	end
	
	if(meta.ChangedTable==nil)then
		meta['ChangedTable']={}
	end
	
	if( meta.ChangedTable[id] == val )then return false end
	
	meta.ChangedTable[id]=val
	return true
end
--=//

--=\\Sorcery table
function SORCERY.Utils.ClearSorceryTablesInSpell()
	if(SORCERY_SPELL)then
		if(SORCERY_SPELL.Var_SpellTablesEnts)then
			for target, _ in pairs(SORCERY_SPELL.Var_SpellTablesEnts)do
				target.Var_SpellTablesEnts = nil
			end
		end
	end
end

function SORCERY.Utils.RegisterSorceryTableEntInSpell(target)
	if(SORCERY_SPELL)then
		SORCERY_SPELL.Var_SpellTablesEnts = SORCERY_SPELL.Var_SpellTablesEnts or {}
		SORCERY_SPELL.Var_SpellTablesEnts[target] = true
	end
end

function SORCERY.Utils:SetSorceryTable(target, value)
	SORCERY.Utils.RegisterSorceryTableEntInSpell(target)

	target.SORCERY_SpellTableSize = table.Count(value)
	target.SORCERY_SpellTable = value
end

function SORCERY.Utils:GetSorceryTableValue(target, key)
	SORCERY.Utils.RegisterSorceryTableEntInSpell(target)

	target.SORCERY_SpellTable = target.SORCERY_SpellTable or {}
	return target.SORCERY_SpellTable[key]
end

function SORCERY.Utils:SetSorceryTableValue(target, key, value)
	SORCERY.Utils.RegisterSorceryTableEntInSpell(target)
	
	target.SORCERY_SpellTable = target.SORCERY_SpellTable or {}
	target.SORCERY_SpellTableSize = target.SORCERY_SpellTableSize or 0
	
	if(target.SORCERY_SpellTable[key] == nil)then
		target.SORCERY_SpellTableSize = target.SORCERY_SpellTableSize + 1
	end
	
	target.SORCERY_SpellTable[key] = value
end

function SORCERY.Utils:GetSorceryTableSize(target)	--; KINDA is table.Count()
	return target.SORCERY_SpellTableSize
end
function SORCERY.Utils:GetSorceryTablePower(target)	--; not table.Count()
	SORCERY.Utils.RegisterSorceryTableEntInSpell(target)

	target.SORCERY_SpellTable = target.SORCERY_SpellTable or {}
	return #target.SORCERY_SpellTable
end

function SORCERY.Utils:AddTableToSorceryTable(target, addtable)
	SORCERY.Utils.RegisterSorceryTableEntInSpell(target)

	target.SORCERY_SpellTable = target.SORCERY_SpellTable or {}
	target.SORCERY_SpellTableSize = target.SORCERY_SpellTableSize or 0
	
	for key, value in pairs(addtable)do
		if(target.SORCERY_SpellTable[key] == nil)then
			target.SORCERY_SpellTableSize = target.SORCERY_SpellTableSize + 1
		end
		
		target.SORCERY_SpellTable[key] = value
	end
end
--=//

--=\\Shifting
-- function SORCERY.Utils.ShiftTable(tbl)	--; WILL NOT WORK REDO ХУЙНЯ ПЕРЕДЕЛЫВАЙ
	-- local lastkey = 0
	
	-- for key, value in pairs(tbl)do
		-- if(key - 1 > lastkey)then
			-- tbl[lastkey + 1] = value
			-- tbl[key] = nil
			-- lastkey = lastkey + 1
		-- else
			-- lastkey = key
		-- end
	-- end
	
	-- return tbl
-- end

function SORCERY.Utils.ShiftTable(tbl)	--; bullshit solution
	local lastkey = 1
	
	while tbl[lastkey + 1] != nil or tbl[lastkey + 2] != nil do
		if(tbl[lastkey] == nil)then		
			if(tbl[lastkey + 1])then
				tbl[lastkey] = tbl[lastkey + 1]
				tbl[lastkey + 1] = nil
			else
				tbl[lastkey] = tbl[lastkey + 2]
				tbl[lastkey + 2] = nil
			end
		end
		
		lastkey = lastkey + 1
	end
	
	return tbl
end
--=//
--//
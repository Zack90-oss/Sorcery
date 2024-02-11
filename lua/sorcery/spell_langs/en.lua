SORCERY.SpellLangsAliases["english"] = "en"
SORCERY.SpellLangsAliases["russian"] = "ru"

hook.Add("SORCERY(StringLowerSymbol)", "SORCERYLanguage(en)", function(id, code, str)
	if(code >= 65 and code <= 90)then
		return string.char(code + 32)
	end
end)

SORCERY.SpellLangs["en"] = SORCERY.SpellLangs["en"] or {}
local l = SORCERY.SpellLangs["en"]

l["default"] = l["default"] or {}
l["default"][" "] = " " -- Defines blank character; SHOULD be in every language, can define multiple blanks
l["default"]["\n"] = " "
l["default"]["\t"] = " "
l["default"]["\v"] = " "
l["default"][","] = " "
-- [":"] = " ",
l["default"]["."] = "."

l["default"]["\""] = "\""	--String
l["default"]["`"] = "`"		--Number

l["default"]["languages:"] = "languages"

l["default"]["pop"] = "pop"
l["default"]["erase"] = "pop"

l["default"]["say"] = "say"
l["default"]["said"] = "say"

--\\Maths
l["default"]["infinity"] = "m_inf"
l["default"]["infinium"] = "m_inf"

l["default"]["multiply"] = "m_mul"
l["default"]["multiplied"] = "m_mul"
--//

--\\Pushers
l["default"]["caster"] = "caster"
l["default"]["me"] = "caster"
l["default"]["mine"] = "caster"
l["default"]["i"] = "caster"
l["default"]["my"] = "caster"

l["default"]["entity"] = "entity"
--//

--\\Users
l["default"]["position"] = "pos"
l["default"]["location"] = "pos"

l["default"]["eyes"] = "eyepos"

l["default"]["look"] = "aimvec"

l["default"]["trace"] = "qtrace"
--//
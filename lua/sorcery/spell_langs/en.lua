local langname = "en"

SORCERY.SpellLangsAliases["space"] = "spacing"
SORCERY.SpellLangsAliases["spec"] = "special"
SORCERY.SpellLangsAliases["english"] = "en"
SORCERY.SpellLangsAliases["russian"] = "ru"

SORCERY:RegisterStringLowerCodes(65, 90, 32)	--From A to Z, look at utf-8 table to create your own lowerings

SORCERY.SpellLangs[langname] = SORCERY.SpellLangs[langname] or {}
local l = SORCERY.SpellLangs[langname]

l["default"] = l["default"] or {}
l["default"]["languages:"] = {Code = "<<languages>>", Special = true}

l["default"]["pop"] = {Code = "POP"}
l["default"]["erase"] = {Code = "POP"}

l["default"]["say"] = {Code = "SAY"}
l["default"]["said"] = {Code = "SAY"}

--\\Quota
l["default"]["say"] = {Code = "SAY"}
--//

--\\Maths
l["default"]["infinity"] = {Code = "M_INF"}
l["default"]["infinium"] = {Code = "M_INF"}

l["default"]["add"] = {Code = "ADD"}
l["default"]["added"] = {Code = "ADD"}
l["default"]["+"] = {Code = "ADD"}

l["default"]["subtract"] = {Code = "SUB"}
l["default"]["subtracted"] = {Code = "SUB"}
l["default"]["-"] = {Code = "SUB"}

l["default"]["multiply"] = {Code = "MUL"}
l["default"]["multiplied"] = {Code = "MUL"}
l["default"]["*"] = {Code = "MUL"}

l["default"]["divide"] = {Code = "DIV"}
l["default"]["divided"] = {Code = "DIV"}
l["default"]["/"] = {Code = "DIV"}
--//

--\\Sorcery Table
l["default"]["get from meta"] = {Code = "STABLE_GET"}

l["default"]["set to meta"] = {Code = "STABLE_SET"}

l["default"]["append to meta"] = {Code = "STABLE_APPEND"}

l["default"]["size of meta"] = {Code = "STABLE_SIZE"}

l["default"]["power of meta"] = {Code = "STABLE_POWER"}
--//

--\\Table
l["default"]["create table"] = {Code = "TABLE_CREATE"}

l["default"]["get"] = {Code = "TABLE_GET"}

l["default"]["set"] = {Code = "TABLE_SET"}

l["default"]["append"] = {Code = "TABLE_APPEND"}
--//

--\\Pushers
l["default"]["caster"] = {Code = "CASTER"}
l["default"]["me"] = {Code = "CASTER"}
l["default"]["mine"] = {Code = "CASTER"}
l["default"]["i"] = {Code = "CASTER"}
l["default"]["my"] = {Code = "CASTER"}

l["default"]["entity"] = {Code = "ENTITY"}
l["default"]["body"] = {Code = "ENTITY"}
--//

--\\Users
l["default"]["size"] = {Code = "SIZE"}

l["default"]["length"] = {Code = "LEN"}

l["default"]["position"] = {Code = "POS"}
l["default"]["location"] = {Code = "POS"}

l["default"]["eyes"] = {Code = "EYEPOS"}

l["default"]["look"] = {Code = "AIMVEC"}

l["default"]["trace"] = {Code = "QTRACE"}
--//

--\\Run
l["default"]["run reason"] = {Code = "GET_CAST_REASON"}
--//
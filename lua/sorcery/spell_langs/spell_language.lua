--; Fucking hell why
--; Unused now and for good

SORCERY.SpellLangs["spell_language"] = SORCERY.SpellLangs["spell_language"] or {}
local l = SORCERY.SpellLangs["spell_language"]

l[" "] = " "
l["\""] = "\""	--; String
l["`"] = "`"	--; Number
l["."] = "."

l["languages"] = "<<languages>>"
l["<<"] = "<<"	--; DANGEROUS Special code to remove 1 symbol from incantation then word is translated

l["pop"] = [[SORCERY_CF"POP"]]		--; REDO THIS IS NOT GOOD table layout and register func
l["say"] = [[SORCERY_CF"SAY"]]

--\\Maths
l["m_inf"] = [[SORCERY_CF"M_INF"]]

l["add"] = [[SORCERY_CF"ADD"]]
l["sub"] = [[SORCERY_CF"SUB"]]
l["mul"] = [[SORCERY_CF"MUL"]]
l["div"] = [[SORCERY_CF"DIV"]]
--//

--\\Table utilization
l["stable_get"] = [[SORCERY_CF"STABLE_GET"]]
l["stable_set"] = [[SORCERY_CF"STABLE_SET"]]
l["stable_append"] = [[SORCERY_CF"STABLE_APPEND"]]
l["stable_size"] = [[SORCERY_CF"STABLE_SIZE"]]
l["stable_power"] = [[SORCERY_CF"STABLE_POWER"]]

l["table_get"] = [[SORCERY_CF"TABLE_GET"]]
l["table_set"] = [[SORCERY_CF"TABLE_SET"]]
l["table_append"] = [[SORCERY_CF"TABLE_APPEND"]]
l["size"] = [[SORCERY_CF"SIZE"]]
l["len"] = [[SORCERY_CF"LEN"]]
--//

l["vector_lensqr"] = [[SORCERY_CF"VECTOR_LENSQR"]]
l["vector_get"] = [[SORCERY_CF"VECTOR_GET"]]
l["string_get"] = [[SORCERY_CF"STRING_GET"]]

l["caster"] = [[SORCERY_CF"CASTER"]]
l["entity"] = [[SORCERY_CF"ENTITY"]]

l["pos"] = [[SORCERY_CF"POS"]]
l["eyepos"] = [[SORCERY_CF"EYEPOS"]]
l["aimvec"] = [[SORCERY_CF"AIMVEC"]]

l["qtrace"] = [[SORCERY_CF"QTRACE"]]

--\\Run
l["get_run_reason"] = [[SORCERY_CF"GET_CAST_REASON"]]
--//


 
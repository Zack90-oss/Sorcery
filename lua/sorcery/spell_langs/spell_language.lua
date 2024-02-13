-- PUSH(var); Pushes var on top of the stack
-- POP(int); Pops the #top - ((int or 1) - 1) of the stack (The nth or first element from the top of stack)
-- READ(); Returns the top of the stack

SORCERY.SpellLangs["spell_language"] = SORCERY.SpellLangs["spell_language"] or {}
local l = SORCERY.SpellLangs["spell_language"]

l[" "] = " "
l["\""] = "\""	--String
l["`"] = "`"	--Number
l["."] = "."

l["languages"] = "<<languages>>"
l["<<"] = "<<"	--Special code to remove 1 symbol from incantation then word is translated

l["pop"] = [[SORCERY_CF"POP"]]
l["say"] = [[SORCERY_CF"SAY"]]

--\\Maths
l["m_inf"] = [[SORCERY_CF"M_INF"]]

l["m_mul"] = [[SORCERY_CF"M_MUL"]]
--//

--\\Table utilization
l["table_get"] = [[SORCERY_CF"TABLE_GET"]]
l["table_set"] = [[SORCERY_CF"TABLE_SET"]]
l["table_append"] = [[SORCERY_CF"TABLE_APPEND"]]
l["table_size"] = [[SORCERY_CF"TABLE_SIZE"]]
--//

l["caster"] = [[SORCERY_CF"CASTER"]]
l["entity"] = [[SORCERY_CF"ENTITY"]]

l["pos"] = [[SORCERY_CF"POS"]]
l["eyepos"] = [[SORCERY_CF"EYEPOS"]]
l["aimvec"] = [[SORCERY_CF"AIMVEC"]]

l["qtrace"] = [[SORCERY_CF"QTRACE"]]


 
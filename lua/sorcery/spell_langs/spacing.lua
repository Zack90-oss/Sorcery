--; Default spacing symbols
local langname = "spacing"

SORCERY.SpellLangs[langname] = SORCERY.SpellLangs[langname] or {}
local l = SORCERY.SpellLangs[langname]

local code_space = {
	Code = " ",
	Special = true
}

l["default"] = l["default"] or {}
l["default"][" "] = code_space -- Defines blank character; SHOULD be in every language, can define multiple blanks
l["default"]["\n"] = code_space
l["default"]["\t"] = code_space
l["default"]["\v"] = code_space
l["default"][","] = code_space
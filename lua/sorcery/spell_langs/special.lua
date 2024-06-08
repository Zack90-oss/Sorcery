--; Default special symbols
local langname = "spacing"

SORCERY.SpellLangs[langname] = SORCERY.SpellLangs[langname] or {}
local l = SORCERY.SpellLangs[langname]

l["default"] = l["default"] or {}

-- [":"] = " ",
l["default"]["."] = {
	Code = ".",
	Special = true
}
l["default"]["\""] = {	--; String
	Code = "\"",
	Special = true
}
l["default"]["`"] = {	--; Number
	Code = "`",
	Special = true
}
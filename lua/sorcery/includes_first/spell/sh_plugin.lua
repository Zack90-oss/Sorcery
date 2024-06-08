local PLUGIN = PLUGIN

--\\
--; Class_Spell structure:
--; Text - Original spell text
--; Function - Compiled spell text
--; Caster - The one who casts
--; Entity - The one who carries (Wisp for example..)
--; <...>
--; Data - Some data, idk, Deprecated
--//

--\\MetaTable
PLUGIN.Class_Spell = SORCERY.Class_Spell or {}
PLUGIN.Class_Spell.__index = PLUGIN.Class_Spell
PLUGIN.Class_Spell.__tostring = function(self)
	return string.format("Spell [%p]", self)
end

function PLUGIN.Class_Spell:Run(callback)
	SORCERY:RunCompiledIncantation(self.Function, self.Caster, self.Entity, self.Data, callback)
end
--//

function PLUGIN.CreateSpell(text, caster, entity, runes)
	local spell = {}
	local t = SORCERY:TranslateIncantationToCode(text, runes)
	local func = SORCERY:CompileIncantationCode(t)
	
	setmetatable(spell, PLUGIN.Class_Spell)
	
	spell.Text = text
	spell.Function = func
	spell.Caster = caster
	spell.Entity = entity
	
	return spell
end

-- local spell = PLUGIN.CreateSpell([["gay nigga" say]], Entity(1), Entity(1), nil)
-- print(spell)
-- print(spell.Text)
-- spell:Run()
SORCERY = SORCERY or {}
SORCERY.PrintName = "Sorcery"

SORCERY.SpellLangsFolder = "sorcery/spell_langs"
SORCERY.SpellLangs = {}
SORCERY.SpellLangsAliases = {}
SORCERY.SpellLanguage = "spell_language"

SORCERY.SpellFunctionsFolder = "sorcery/spell_functions"
SORCERY.SpellFunctions = {}
SORCERY_FUNC = SORCERY.SpellFunctions	--SHORTCUT

SORCERY.ClassCheckFunctions = SORCERY.ClassCheckFunctions or {}
SORCERY_CCHECK = SORCERY.ClassCheckFunctions	--SHORTCUT

function SORCERY:Print(msg)
	print(SORCERY.PrintName..": "..msg)
end

function SORCERY:ChatPrint(ply, msg)
	ply:ChatPrint(msg)
end

function SORCERY:ChatPrintName(ply, msg)
	ply:ChatPrint(SORCERY.PrintName..": "..msg)
end

--\\String Lowering
--[[
:String Lowering

Thanks to noaccess, for pointing me to more performance-friendly approach described in https://github.com/Be1zebub/Small-GLua-Things/blob/master/sh_utf8.lua
https://www.charset.org/utf-8

TODO; actually check perfomances
--]]
SORCERY.String = SORCERY.String or {}
SORCERY.String.StringPattern = "[^%c%d]*"

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

-- SORCERY.Utils:SetSorceryTable;
-- METHOD: Sets the entire "SORCERY_SpellTable" key which will be indexable and setable by the spell
function SORCERY.Utils:SetSorceryTable(target, value)
	target.SORCERY_SpellTable = value
end

-- SORCERY.Utils:GetSorceryTableValue;
-- METHOD: you perfectly understand what this is
function SORCERY.Utils:GetSorceryTableValue(target, key)
	target.SORCERY_SpellTable = target.SORCERY_SpellTable or {}
	return target.SORCERY_SpellTable[key]
end

-- SORCERY.Utils:SetSorceryTableValue;
-- METHOD: Adds value any target table(Entity or anything else) under the "SORCERY_SpellTable" key which will be indexable and setable by the spell
function SORCERY.Utils:SetSorceryTableValue(target, key, value)
	target.SORCERY_SpellTable = target.SORCERY_SpellTable or {}
	target.SORCERY_SpellTable[key] = value
end

function SORCERY.Utils:GetSorceryTableSize(target)	--not table.Count()
	target.SORCERY_SpellTable = target.SORCERY_SpellTable or {}
	return #target.SORCERY_SpellTable
end

-- SORCERY.Utils:AddToSorceryTable;
-- METHOD: Adds table's contents to any target table(Entity or anything else) under the "SORCERY_SpellTable" key which will be indexable and setable by the spell
function SORCERY.Utils:AddTableToSorceryTable(target, addtable)
	target.SORCERY_SpellTable = target.SORCERY_SpellTable or {}
	for key, value in pairs(addtable)do
		target.SORCERY_SpellTable[key] = value
	end
end

function SORCERY.Utils:ShiftTable(tbl)
	local lastkey = 0
	for key, value in pairs(tbl)do
		if(key - 1 > lastkey)then
			tbl[lastkey + 1] = value
			tbl[key] = nil
			lastkey = lastkey + 1
		else
			lastkey = key
		end
	end
	return tbl
end
--//

--[[
SORCERY.Spells={
	["_"]={
		["unus"]	="1",
		["duo"]		="2",
		["tres"]	="3",
		["quattuor"]="4",
		["quinque"]	="5",
		["sex"]		="6",
		["septem"]	="7",
		["octo"]	="8",
		["novem"]	="9",
		
		["ubi ego sum vultus"]=" local pos=Caster:GetEyeTrace().HitPos;",
		["versus im vultus in"]=" local pos=Caster:GetPos()+Caster:GetAimVector()*",
	},
	[""]={
	
	},
}
]]

--\\Registration
function SORCERY:RegisterSpellFunctions()
	local rootFolder = SORCERY.SpellFunctionsFolder.."/"
	local files, directories = file.Find( rootFolder.."*", "LUA" )
	for i,obj in pairs(files) do
		SORCERY:Print('Functions found! '..obj)
		AddCSLuaFile(rootFolder..obj)
		include(rootFolder..obj)
	end
end
SORCERY:RegisterSpellFunctions()

function SORCERY:RegisterSpellLangs()
	local rootFolder = SORCERY.SpellLangsFolder.."/"
	local files, directories = file.Find( rootFolder.."*", "LUA" )
	for i,obj in pairs(files) do
		SORCERY:Print('Language found! '..obj)
		AddCSLuaFile(rootFolder..obj)
		include(rootFolder..obj)
	end
end
SORCERY:RegisterSpellLangs()

function SORCERY:AssembleLangs()
	for langname, lang in pairs(SORCERY.SpellLangs)do
		if(langname != SORCERY.SpellLanguage)then
			for rune, info in pairs(lang)do
				for word, translation in pairs(info)do
					hook.Run("SORCERY(AssembleLangs)", info, word, translation)
				end
			end
		end
	end
end

hook.Add("SORCERY(AssembleLangs)", "SORCERY", function(info, word, translation)
	local len = #word
	
	if(len > 2)then
		local everfoundblank = false
		local blank = true
		local part = ""
		local newinfo = nil
		for key = 1, len + 1 do
			local t = word[key]
			
			if(blank)then
				if(t != " ")then
					blank = false
					part = part..t
				end
			else
				if(t == " ")then
					blank = true
					if(!everfoundblank)then
						word = word.." "	--PLUG; Stupidly looking
						everfoundblank = true
					end
					
					if(newinfo)then
						newinfo.combo[part] = newinfo.combo[part] or {}
						newinfo.combo[part].combo = newinfo.combo[part].combo or {}
						
						if(key == len + 1)then
							newinfo.combo[part].stop = translation
						end
						
						newinfo = newinfo.combo[part]
					else
						if(info[part])then
							if(istable(info[part]))then
								newinfo = info[part]
								
								if(info[part].stop)then
									newinfo.stop = info[part].stop
								end
							else
								newinfo = {}
							end
							newinfo.combo = newinfo.combo or {}
							
							if(isstring(info[part]))then
								newinfo.stop = info[part]
							end
						else
							newinfo = {}
							newinfo.combo = {}
						end
						
						info[part] = newinfo
					end
					
					part = ""
				else
					part = part..t
				end
			end
			
			if(!everfoundblank and key == len)then
				break
			end
		end
	end
end)

SORCERY:AssembleLangs()
--//

--\\Translation
local defaultRune = {"default"}

function SORCERY:TranslateWordToCode(text, runes, languages, worktable, isword)	--; Good luck reading that lol
	runes = runes or defaultRune
	languages = languages or SORCERY.SpellLangs

	local spellang = SORCERY.SpellLangs[SORCERY.SpellLanguage]
	local precode = nil
	local addprecode = nil
	local shouldcheck = true
	local aftercombo = false

	if(worktable and isword)then
		if(worktable.wcombo)then
			local foundinfo = nil
			local stop = nil
			
			for langname, lang in pairs(worktable.wcombo_langs)do
				for rune, info in pairs(lang)do
					if(info.combo)then
						local newinfo = info.combo[text]
						if(newinfo)then
							worktable.wcombo[#worktable.wcombo + 1] = text
							foundinfo = newinfo
							
							if(newinfo.stop)then
								worktable.wcombo_stop[langname][rune] = newinfo.stop
							end
							
							worktable.wcombo_langs[langname][rune] = newinfo
						end
					end
					if(!foundinfo)then
						stop = worktable.wcombo_stop[langname][rune]
					end
				end
			end
			
			if(!foundinfo)then
				precode = stop
				aftercombo = true
				-- local lefttext = string.sub(worktable.text, 0, worktable.textpos)
				-- local righttext = string.sub(worktable.text, 0, worktable.textpos)
				-- shouldcheck = false
				
				worktable.wcombo = nil
				worktable.wcombo_langs = nil
				worktable.wcombo_stop = nil
			end
		end
	end

	if(shouldcheck)then
		for _, rune in ipairs(runes) do
			for langname, _ in pairs(languages) do
				if(langname != SORCERY.SpellLanguage)then
					local lang = SORCERY.SpellLangs[langname]
					local phrases = lang[rune]
					
					if(phrases)then
						local info = phrases[text]
						
						if(info)then
							if(istable(info))then
								if(worktable and isword)then
									worktable.wcombo = worktable.wcombo or {}
									worktable.wcombo[#worktable.wcombo + 1] = text
									
									worktable.wcombo_langs = worktable.wcombo_langs or {}
									worktable.wcombo_langs[langname] = worktable.wcombo_langs[langname] or {}
									worktable.wcombo_langs[langname][rune] = info

									worktable.wcombo_stop = worktable.wcombo_stop or {}
									worktable.wcombo_stop[langname] = worktable.wcombo_stop[langname] or {}
									
									if(info.stop)then
										worktable.wcombo_stop[langname][rune] = info.stop
									end
								elseif(info.stop)then
									precode = info.stop
								end
							else
								if(rune != "default")then
									if(aftercombo)then
										addprecode = info
									else
										precode = info
									end
								elseif(!precode or aftercombo)then
									if(aftercombo)then
										addprecode = info
									else
										precode = info
									end
								end
							end
						end
						
						if(worktable and worktable.wcombo and isword)then
							precode = "<<"
						end
					end
				end
			end
		end
	end
	
	if(precode)then
		if(addprecode)then
			return spellang[precode], spellang[addprecode]
		else
			return spellang[precode]
		end
	end
end

function SORCERY:TranslateIncantationToCode(text, runes)
	local worktable = {}

	worktable.text = text.." <<PLUG>> "	--PLUG; Stupidly looking
	runes = runes or defaultRune
	
	worktable.word = ""
	worktable.blank = true
	worktable.blankamt = 0
	worktable.blanklastamt = 0
	local wholeIncantation = ""
	local len = #worktable.text
	local spellang = SORCERY.SpellLangs[SORCERY.SpellLanguage]
	
	worktable.languages = nil
	
	for key = 1, len do
		local t = worktable.text[key]
		worktable.textpos = key
		local code = SORCERY:TranslateWordToCode(t, runes, worktable.languages, worktable)
		
		local retval = hook.Run("SORCERY(PreTranslateSymbolToCode)", wholeIncantation, t, code, runes, worktable.text, worktable)
		if(retval)then
			wholeIncantation = retval
		else
			local retval = hook.Run("SORCERY(TranslateSymbolToCode)", wholeIncantation, t, code, runes, worktable.text, worktable)
			if(retval)then
				wholeIncantation = retval
			end
			
			--\\Default executing code
			if(worktable.blank)then
				if(code != " ")then
					worktable.blank = false
					worktable.blanklastamt = worktable.blankamt 
					worktable.blankamt = 0
					worktable.word = t
				elseif(code)then
					worktable.blankamt = worktable.blankamt + 1
					if(!worktable.wcombo)then
						wholeIncantation = wholeIncantation..code
					end
				end
			else
				if(code == " ")then
					local retval = hook.Run("SORCERY(PreTranslateWordToCode)", wholeIncantation, t, code, runes, worktable.text, worktable)
					if(retval)then
						wholeIncantation = retval
					else
						worktable.blank = true
						worktable.blankamt = worktable.blankamt + 1
						worktable.word = SORCERY:StringLower(worktable.word)
						local wordcode, addcode = SORCERY:TranslateWordToCode(worktable.word, runes, worktable.languages, worktable, true)
						-- print(wordcode, addcode)
						if(wordcode)then
							wholeIncantation = wholeIncantation..wordcode
						end
						
						-- print(1,wholeIncantation)
						
						if(addcode)then
							wholeIncantation = wholeIncantation..string.rep(" ", worktable.blanklastamt)..addcode
						end
						-- print(2,wholeIncantation)
						
						wholeIncantation = wholeIncantation..code
						
						local retval = hook.Run("SORCERY(PostTranslateWordToCode)", wholeIncantation, t, code, wordcode, runes, worktable.text, worktable)
						if(retval)then
							wholeIncantation = retval
						end
						
						worktable.word = ""
					end
				else
					worktable.word = worktable.word..t
				end
			end
			--//
			
			local retval = hook.Run("SORCERY(PostTranslateSymbolToCode)", wholeIncantation, t, code, runes, worktable.text, worktable)
			if(retval)then
				wholeIncantation = retval
			end
		end
	end
	
	return wholeIncantation
end
--//

--\\Compiler and Run
function SORCERY:CompileIncantationCode(code)
	-- for funcname, func in pairs(SORCERY.SpellFunctions)do --; holy moly
		-- code = "local "..funcname.."=SORCERY.SpellFunctions."..funcname.."\n"..code
	-- end
	
	return CompileString(code, "Sorcery_Incantation")
end

function SORCERY.HaltSpell(failcode, funcname)
	hook.Run("SORCERY(HaltSpell)", failcode, funcname)
	coroutine.yield()
end

function SORCERY.CallFunc(funcname, ...)
	local functbl = SORCERY.SpellFunctions[funcname]
	if(functbl)then
		local preargs = {...}
		local prearglen = #preargs
		local args = preargs
		
		if(functbl.args)then
			local loops = #functbl.args - prearglen
			for key = 1, loops, 1 do
				arg = SORCERY_CF("READ", loops - key + 1)
				
				local allowed, failcode = functbl.args[key](arg)
				if(allowed)then
					args[#args + 1] = arg
				else
					SORCERY_SPELL.failcode = failcode
					SORCERY_SPELL.failfunc = funcname
					SORCERY.HaltSpell(failcode, funcname)
				end
			end
		end
		
		return functbl.func(unpack(args))
	end
end

SORCERY_CF = SORCERY.CallFunc	--SHORTCUT

function SORCERY.OnRunError(msg)
	hook.Run("SORCERY(OnRunError)", msg)
end

function SORCERY:RunCompiledIncantation(func, caster, entity, data, callback)
	SORCERY_SPELL = {}
	SORCERY_SPELL.caster = caster
	SORCERY_SPELL.stack = {}
	SORCERY_SPELL.entity = entity or caster
	SORCERY_SPELL.data = data
	
	if(callback)then
		callback()
	end
	
	local thread = coroutine.create(function()
		xpcall(func, SORCERY.OnRunError)
	end)
	coroutine.resume(thread)
end
--//

--\\Hooks
local function addLanguage(worktable)
	worktable.word = SORCERY:StringLower(worktable.word)
	worktable.PreLanguages = worktable.PreLanguages or {}
	worktable.PreLanguages[string.Trim(worktable.word)] = true
end

hook.Add("SORCERY(HaltSpell)", "SORCERY", function(failcode, funcname)
	local msg = funcname.." ->"
	
	for _, fc in ipairs(string.Split(failcode,":"))do
		msg = msg.." "..fc
	end
	
	msg = "FAIL: "..msg
	
	if(IsValid(SORCERY_SPELL.caster))then
		SORCERY:ChatPrintName(SORCERY_SPELL.caster, msg)
	end
end)

hook.Add("SORCERY(OnRunError)", "SORCERY", function(msg)
	MsgC(Color(255,0,0), "*Sorcery Lua Error:", msg, "\n")
	if(IsValid(SORCERY_SPELL.caster))then
		SORCERY:ChatPrintName(SORCERY_SPELL.caster, "Lua error!")
	end
end)

hook.Add("SORCERY(PreTranslateSymbolToCode)", "SORCERY", function(wholeIncantation, t, code, runes, text, worktable)
	if(code == "\"")then
		local addstring = [[SORCERY_CF("PUSH",]]
		if(!worktable.WritingString)then
			wholeIncantation = wholeIncantation..addstring..code	--DANGEROUS; Should not be executable
			worktable.WritingString = true
		else
			wholeIncantation = wholeIncantation..code..")"
			worktable.WritingString = false
		end
		
		worktable.word = ""
		worktable.blank = false
		
		return wholeIncantation
	end
	
	if(code == "`")then
		local addstring = [[SORCERY_CF("PUSH",]]
		if(!worktable.WritingNumber)then
			wholeIncantation = wholeIncantation..addstring	--EXTREMELY FUCKING ABSOLUTELY BRUTALY DANGEROUS
			worktable.NumberToWrite = ""
			worktable.WritingNumber = true
		else
			local num = tonumber(worktable.NumberToWrite)
			if(num)then
				wholeIncantation = wholeIncantation..num..")"
				worktable.WritingNumber = false
			else
				wholeIncantation = string.Left(wholeIncantation, #wholeIncantation - #addstring - 1)
				worktable.WritingNumber = false
				--ERROR
			end
		end
		
		worktable.word = ""
		worktable.blank = false
		
		return wholeIncantation
	end
	
	if(code == ".")then
		if(worktable.WritingLanguages)then
			addLanguage(worktable)
			if(worktable.PreLanguages)then
				for langname, _ in pairs(worktable.PreLanguages)do
					if(SORCERY:GetLanguage(langname))then
						worktable.languages = worktable.languages or {}
						worktable.languages[SORCERY.SpellLangsAliases[langname] or langname] = true
					end
				end
			end
			worktable.PreLanguages = nil
			
			worktable.WritingLanguages = false
		end
		
		worktable.word = ""
		worktable.blank = false
		
		return wholeIncantation
	end
	
	if(t)then
		if(worktable.WritingString)then
			wholeIncantation = wholeIncantation..t
			
			worktable.word = ""
			worktable.blank = false
			
			return wholeIncantation
		end
		if(worktable.WritingNumber)then
			worktable.NumberToWrite = worktable.NumberToWrite or ""
			worktable.NumberToWrite = worktable.NumberToWrite..t
			
			worktable.word = ""
			worktable.blank = false
			
			return wholeIncantation
		end
	end
end)

hook.Add("SORCERY(PreTranslateWordToCode)", "SORCERY", function(wholeIncantation, t, code, runes, text, worktable)
	if(worktable.WritingLanguages)then
		addLanguage(worktable)
		
		return wholeIncantation
	end
end)

hook.Add("SORCERY(PostTranslateWordToCode)", "SORCERY", function(wholeIncantation, t, code, wordcode, runes, text, worktable)
	if(wordcode == "<<languages>>")then
		worktable.WritingLanguages = true
		return string.Left(wholeIncantation, #wholeIncantation - #wordcode - 1)
	end
	
	if(wordcode == "<<")then
		return string.Left(wholeIncantation, #wholeIncantation - 3)
	end
end)
--//

if(SERVER)then
	local cf = SORCERY:TranslateIncantationToCode([[from my eyes and my own look with `123` multiplied, give the trace, which "Entity" you will get and say it]], nil)
	print(cf)
	SORCERY:RunCompiledIncantation(SORCERY:CompileIncantationCode(cf), Entity(1), nil, nil, nil)
end

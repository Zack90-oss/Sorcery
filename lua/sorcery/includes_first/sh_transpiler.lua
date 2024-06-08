--; PLUGIN ???

--\\Registration
function SORCERY.RegisterSpellFunctions()
	local rootFolder = SORCERY.SpellFunctionsFolder .. "/"
	local files, directories = file.Find( rootFolder .. "*", "LUA" )
	
	for i, obj in pairs(files) do
		SORCERY:Print('Functions found! ' .. obj)
		
		AddCSLuaFile(rootFolder .. obj)
		include(rootFolder .. obj)
	end
end

SORCERY.RegisterSpellFunctions()

function SORCERY.RegisterSpellLangs()
	local rootFolder = SORCERY.SpellLangsFolder .. "/"
	local files, directories = file.Find( rootFolder .. "*", "LUA" )
	
	for i, obj in pairs(files) do
		SORCERY:Print('Language found! ' .. obj)
		
		AddCSLuaFile(rootFolder .. obj)
		include(rootFolder .. obj)
	end
end

SORCERY.RegisterSpellLangs()

function SORCERY.RegisterSpellFunctionInfo(funcspell, descr, langname, rune, word)
	SORCERY.SpellFunctionsInfo[funcspell] = SORCERY.SpellFunctionsInfo[funcspell] or {}
	
	if(descr)then
		SORCERY.SpellFunctionsInfo[funcspell].Description = descr
	end
	
	if(langname and rune and word)then
		SORCERY.SpellFunctionsInfo[funcspell][langname] = SORCERY.SpellFunctionsInfo[funcspell][langname] or {}
		SORCERY.SpellFunctionsInfo[funcspell][langname][rune] = SORCERY.SpellFunctionsInfo[funcspell][langname][rune] or {}
		SORCERY.SpellFunctionsInfo[funcspell][langname][rune][word] = true
	end
end

function SORCERY.RegisterSpellFunctionInfoDescription(funcspell, descr)
	SORCERY.SpellFunctionsInfo[funcspell] = SORCERY.SpellFunctionsInfo[funcspell] or {}
	SORCERY.SpellFunctionsInfo[funcspell].Description = descr or "fdescr_" .. funcspell
end

function SORCERY.AssembleLangs()
	local newtable = SORCERY.SpellLangs
	local lookupkeys = {}

	for langname, lang in pairs(SORCERY.SpellLangs)do
		if(langname != SORCERY.SpellLanguage)then
			lookupkeys[langname] = lookupkeys[langname] or {}
			
			for rune, info in pairs(lang)do
				lookupkeys[langname][rune] = lookupkeys[langname][rune] or {}
				
				for word, _ in pairs(info)do
					lookupkeys[langname][rune][word] = true	--; We basically just copied an entire table at this point lol
				end
			end
		end
	end

	for langname, lang in pairs(lookupkeys)do
		for rune, info in pairs(lang)do
			for word, _ in pairs(info)do
				local translation = SORCERY.SpellLangs[langname][rune][word]
				
				hook.Run("SORCERY(AssembleLangs)", info, langname, rune, word, translation)	--; you can declare spell with words (e.g. "say my name"), so "word" and "words" are synonyms here, don't get confused
			end
		end
	end
	
	SORCERY.SpellLangs = newtable
end

hook.Add("SORCERY(AssembleLangs)", "SORCERY", function(info, langname, rune, word, translation)
	if(!translation)then
		return
	end
	
	translation = SORCERY.GetRawFunctionCallCode(translation)	--; DEPRECATED (это значит "оспаривается", а не "удалено")
	local len = #word
	
	if(len > 2)then
		local everfoundblank = false
		local blank = true
		local part = ""
		local newinfo = nil
		local fullword = nil	--; Used for spaced spells
		
		for key = 1, len + 1 do
			local t = word[key]
			
			if(blank)then
				if(t != " ")then
					blank = false
					part = part .. t
				end
			else
				if(t == " ")then
					blank = true
					fullword = fullword or ""
					fullword = fullword .. (#fullword != 0 and " " or "") .. part
					
					if(!everfoundblank)then
						word = word .. " "	--; PLUG Stupidly looking
						everfoundblank = true
					end
					
					if(newinfo)then
						newinfo.combo[part] = newinfo.combo[part] or {}
						newinfo.combo[part].combo = newinfo.combo[part].combo or {}
						
						if(key == len + 1)then
							newinfo.combo[part].stop = translation
							
							SORCERY.RegisterSpellFunctionInfo(translation, nil, langname, rune, fullword)
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
					part = part .. t
				end
			end
			
			if(!everfoundblank and key == len)then
				SORCERY.RegisterSpellFunctionInfo(translation, nil, langname, rune, word)
				
				break
			end
		end
	end
end)

SORCERY.AssembleLangs()
--//

--\\Translation
local defaultRune = {"default"}

function SORCERY.ConstructFunctionCallCode(tbl)
	if(tbl.Special)then
		return tbl.Code
	elseif(tbl.BuildFunc)then
		return tbl.BuildFunc(tbl)
	else
		return [[SORCERY_CF"]] .. tbl.Code .. [["]]
	end
end

function SORCERY.GetRawFunctionCallCode(tbl)
	return tbl.Code 
end


function SORCERY:TranslateWordToCode(text, runes, languages, worktable, isword)	--; Good luck reading that lol
	runes = runes or defaultRune
	languages = languages or SORCERY.SpellLangs

	local spellang = SORCERY.SpellLangs[SORCERY.SpellLanguage]
	local precode = nil
	local addprecode = nil
	-- local shouldcheck = true
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
				precode = SORCERY.ConstructFunctionCallCode(stop)
				aftercombo = true
				worktable.wcombo = nil
				worktable.wcombo_langs = nil
				worktable.wcombo_stop = nil
			end
		end
	end

	-- if(shouldcheck)then
	for _, rune in ipairs(runes) do
		for langname, _ in pairs(languages) do
			if(langname != SORCERY.SpellLanguage)then
				local lang = SORCERY.SpellLangs[langname]
				local phrases = lang[rune]
				
				if(phrases)then
					local info = phrases[text]
					
					if(info)then
						if(istable(info) and info.combo)then
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
								precode = SORCERY.ConstructFunctionCallCode(info.stop)
							end
						else
							if(rune != "default")then
								if(aftercombo)then
									addprecode = SORCERY.ConstructFunctionCallCode(info)
								else
									precode = SORCERY.ConstructFunctionCallCode(info)
								end
							elseif(!precode or aftercombo)then
								if(aftercombo)then
									addprecode = SORCERY.ConstructFunctionCallCode(info)
								else
									precode = SORCERY.ConstructFunctionCallCode(info)
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
	-- end
	
	if(precode)then
		if(addprecode)then
			-- return spellang[precode], spellang[addprecode]
			return precode, addprecode
		else
			-- return spellang[precode]
			return precode
		end
	end
end

function SORCERY:TranslateIncantationToCode(text, runes)
	local worktable = {}

	worktable.text = text .. " <<PLUG>> "	--; PLUG Stupidly looking
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
		worktable.textpos = key
		
		local t = worktable.text[key]
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
						wholeIncantation = wholeIncantation .. code
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
						
						if(wordcode)then
							wholeIncantation = wholeIncantation .. wordcode
						end
						
						if(addcode)then
							wholeIncantation = wholeIncantation .. string.rep(" ", worktable.blanklastamt) .. addcode
						end
						
						wholeIncantation = wholeIncantation .. code
						local retval = hook.Run("SORCERY(PostTranslateWordToCode)", wholeIncantation, t, code, wordcode, runes, worktable.text, worktable)
						
						if(retval)then
							wholeIncantation = retval
						end
						
						worktable.word = ""
					end
				else
					worktable.word = worktable.word .. t
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
	return CompileString(code, "Sorcery_Incantation")
end

function SORCERY.HaltSpell(failcode, funcname)
	hook.Run("SORCERY(HaltSpell)", failcode, funcname)
	coroutine.yield()
end

function SORCERY.IgnoreQuota(ignore_untli_unset)	--; Stop using quota for the next (and possibly forever) function call
	SORCERY.IgnoringQuota = true
	
	if(ignore_untli_unset)then
		SORCERY.IgnoringQuotaUntilUnset = ignore_untli_unset
	end
end

function SORCERY.DontIgnoreQuota(recurse_untli_unset)	--; Opposite to the thing above (why would you use this?), use this above the function you call to use quota recursevely
	SORCERY.RecurseUsingQuota = true
	
	if(recurse_untli_unset)then
		SORCERY.RecurseUsingQuotaUntilUnset = recurse_untli_unset
	end
end

function SORCERY.CallFunc(funcname, ...)
	local functbl = SORCERY.SpellFunctions[funcname]
	
	if(functbl)then
		local preargs = {...}
		local prearglen = #preargs
		local args = preargs
		
		if(!SORCERY.IgnoringQuota)then
			if(functbl.quota and funcname != "QUOTA_ADD")then	--; SAFECHECK
				SORCERY_CF("QUOTA_ADD", functbl.quota)
			end
		end
		
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
		
		local systime = SysTime()	--; funny fuck to make it only work for this scope
		
		if(!SORCERY.RecurseUsingQuota)then
			SORCERY.IgnoreQuota(true)
			SORCERY.IgnoringQuotaUntilUnsetScope = systime
		end
		
		functbl.func(unpack(args))
		
		if(SORCERY.IgnoringQuotaUntilUnset)then
			if(SORCERY.IgnoringQuotaUntilUnsetScope == systime)then
				SORCERY.IgnoringQuotaUntilUnsetScope = nil
				SORCERY.IgnoringQuota = false
			end
		else
			SORCERY.IgnoringQuota = false
		end
	end
end

SORCERY_CF = SORCERY.CallFunc	--; SHORTCUT

function SORCERY.OnRunError(msg)
	hook.Run("SORCERY(OnRunError)", msg)
end

function SORCERY:RunCompiledIncantation(func, caster, entity, data, callback)
	SORCERY_SPELL = {}
	SORCERY_SPELL.Stack = {}
	SORCERY_SPELL.Caster = caster
	SORCERY_SPELL.Entity = entity or caster
	SORCERY_SPELL.Data = data	--; DEPRECATED
	caster.SORCERY_QUOTA = caster.SORCERY_QUOTA or SORCERY.DefaultQuota
	SORCERY_SPELL.Entity.SORCERY_QUOTA = SORCERY_SPELL.Entity.SORCERY_QUOTA or 0
	
	if(callback)then
		callback()
	end
	
	if(hook.Run("SORCERY(RunCompiledIncantation)", func, caster, entity, data, callback) == false)then
		SORCERY_SPELL = nil
	else
		local thread = coroutine.create(function()
			xpcall(func, SORCERY.OnRunError)
		end)
		
		coroutine.resume(thread)
		
		hook.Run("SORCERY(PostRunCompiledIncantation)")
		
		SORCERY.Utils.ClearSorceryTablesInSpell()
	end
end
--//

--\\Other Hooks
local function addLanguage(worktable)
	worktable.word = SORCERY:StringLower(worktable.word)
	worktable.PreLanguages = worktable.PreLanguages or {}
	worktable.PreLanguages[string.Trim(worktable.word)] = true
end

hook.Add("SORCERY(HaltSpell)", "SORCERY", function(failcode, funcname)
	if(SORCERY.IgnoringQuotaUntilUnset)then
		if(SORCERY.IgnoringQuotaUntilUnsetScope)then
			SORCERY.IgnoringQuotaUntilUnsetScope = nil
			SORCERY.IgnoringQuota = false
		end
	end

	if(failcode)then
		local msg = funcname .. " ->"
		
		for _, fc in ipairs(string.Split(failcode,":"))do
			msg = msg .. " " .. fc
		end
		
		msg = "FAIL: " .. msg
		
		if(IsValid(SORCERY_SPELL.Caster))then
			SORCERY:ChatPrintName(SORCERY_SPELL.Caster, msg)
		end
	end
end)

hook.Add("SORCERY(OnRunError)", "SORCERY", function(msg)
	if(SORCERY.IgnoringQuotaUntilUnset)then
		if(SORCERY.IgnoringQuotaUntilUnsetScope)then
			SORCERY.IgnoringQuotaUntilUnsetScope = nil
			SORCERY.IgnoringQuota = false
		end
	end
	
	MsgC(Color(255, 0, 0), "*Sorcery Lua Error:", msg, "\n")
	
	if(IsValid(SORCERY_SPELL.Caster))then
		SORCERY:ChatPrintName(SORCERY_SPELL.Caster, "Lua error!")
	end
end)

hook.Add("SORCERY(OnQuotaEnd)", "SORCERY", function(add)
	SORCERY_SPELL.failcode = "quota_end"
	SORCERY_SPELL.failfunc = "QUOTA"
	SORCERY.HaltSpell(SORCERY_SPELL.failcode, SORCERY_SPELL.failfunc)
end)

function SORCERY.OnQuotaUpdate(add)
	if(SORCERY_SPELL.Entity.SORCERY_QUOTA <= 0)then
		hook.Run("SORCERY(OnQuotaEnd)", add)
	end
end

hook.Add("SORCERY(OnQuotaChange)", "SORCERY", SORCERY.OnQuotaUpdate)

hook.Add("SORCERY(OnQuotaChangeFailed)", "SORCERY", SORCERY.OnQuotaUpdate)

hook.Add("SORCERY(PreTranslateSymbolToCode)", "SORCERY", function(wholeIncantation, t, code, runes, text, worktable)
	if(code == "\"")then
		local addstring = [[SORCERY_CF("PUSH",]]	--; EXTREMELY FUCKING ABSOLUTELY BRUTALY DANGEROUS, CARRIAGE RETURN CHARACTERS AND etc.
		
		if(!worktable.WritingString)then
			wholeIncantation = wholeIncantation .. addstring .. code	--; WARNING Should not be executable
			worktable.WritingString = true
		else
			wholeIncantation = wholeIncantation .. code .. ")"
			worktable.WritingString = false
		end
		
		worktable.word = ""
		worktable.blank = false
		
		return wholeIncantation
	end
	
	if(code == "`")then
		local addstring = [[SORCERY_CF("PUSH",]]
		if(!worktable.WritingNumber)then
			wholeIncantation = wholeIncantation .. addstring	--; EXTREMELY FUCKING ABSOLUTELY BRUTALY DANGEROUS
			worktable.NumberToWrite = ""
			worktable.WritingNumber = true
		else
			local num = tonumber(worktable.NumberToWrite)
			if(num)then
				wholeIncantation = wholeIncantation .. num .. ")"
				worktable.WritingNumber = false
			else
				wholeIncantation = string.Left(wholeIncantation, #wholeIncantation - #addstring - 1)
				worktable.WritingNumber = false
				--; ERROR
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
			wholeIncantation = wholeIncantation .. t
			worktable.word = ""
			worktable.blank = false
			
			return wholeIncantation
		end
		if(worktable.WritingNumber)then
			worktable.NumberToWrite = worktable.NumberToWrite or ""
			worktable.NumberToWrite = worktable.NumberToWrite .. t
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
	
	if(wordcode == "<<")then	--; DANGEROUS
		return string.Left(wholeIncantation, #wholeIncantation - 3)
	end
end)
--//
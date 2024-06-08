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

--\\Header
SORCERY = SORCERY or {}
SORCERY.PrintName = "Sorcery"
SORCERY.Version = 1

SORCERY.SpellLangsFolder = "sorcery/spell_langs"
SORCERY.SpellLangs = {}
SORCERY.SpellLangsAliases = {}
SORCERY.SpellLanguage = "spell_language"

SORCERY.SpellFunctionsFolder = "sorcery/spell_functions"
SORCERY.SpellFunctions = {}
SORCERY_FUNC = SORCERY.SpellFunctions	--; SHORTCUT

SORCERY.SpellFunctionsInfo = {}

SORCERY.ClassCheckFunctions = SORCERY.ClassCheckFunctions or {}
SORCERY_CCHECK = SORCERY.ClassCheckFunctions	--; SHORTCUT

SORCERY.DefaultQuota = 100
--//

--\\ClassCheck index
function SORCERY.ClassCheckFunctions.CompileMethodCheck(method, cannumber)
	local fc = "local args = {...} local any = args[1]\n"
	fc = fc .. "local cc = SORCERY.ClassCheckFunctions"
	
	if(cannumber)then
		fc = fc..[[
	if(cc.isnumber(any))then
		return true
	end
]]
	end
	
	fc = fc..[[
	local retval, failcode = cc.isSubscriptable(any)
	if(!retval)then
		return retval, failcode
	elseif(isfunction(any.]]..method..[[))then
		return true
	else
		return false, "no_method"
	end
]]
	return CompileString(fc, "cc_MethodCheck")
end

function SORCERY.ClassCheckFunctions.GetCompiledMethodCheck(method, cannumber)
	if(SORCERY.ClassCheckFunctions["hasFunction_" .. method])then
		return SORCERY.ClassCheckFunctions["hasFunction_" .. method]
	else
		SORCERY.ClassCheckFunctions["hasFunction_" .. method] = compileMethodCheck(method, cannumber)
		return SORCERY.ClassCheckFunctions["hasFunction_" .. method]
	end
end
--//

--\\Misc functions
function SORCERY:Print(msg)
	print(SORCERY.PrintName .. ": " .. msg)
end

function SORCERY:ChatPrint(ply, msg)
	if(ply:IsPlayer())then	--; Caster may not be a player, What if you have a robot that spawn on the start of the map?
		ply:ChatPrint(msg)
	end
end

function SORCERY:ChatPrintName(ply, msg)
	SORCERY:ChatPrint(ply, SORCERY.PrintName .. ": " .. msg)
end
--//

--\\Default includes (Plugins)
SORCERY.Plugin = SORCERY.Plugin or {}
SORCERY.Plugin.List = SORCERY.Plugin.List or {}

--=\\Plugin Meta
SORCERY.Plugin.Class_Plugin = {}
SORCERY.Plugin.Class_Plugin.__index = SORCERY.Plugin.Class_Plugin
SORCERY.Plugin.Class_Plugin.__tostring = function(self)
	return "Plugin [" .. self.ID .. "]"
end

function SORCERY.Plugin.Class_Plugin:AddHook(id, func)
	hook.Add(id, "SORCERY.Plugin.List[" .. self.ID .. "].Hooks[" .. id .. "]", func)
end

function SORCERY.Plugin.Class_Plugin:RunHook(id, ...)
	return hook.Run("SORCERY.Plugin.List[" .. self.ID .. "].Hooks[" .. id .. "]", ...)
end

function SORCERY.Plugin.Class_Plugin:Include(path)
	local obj = string.GetFileFromFilename(path)
	
	if(string.StartsWith(obj, "sh_"))then
		AddCSLuaFile(path)
		include(path)
	elseif(string.StartsWith(obj, "cl_"))then
		AddCSLuaFile(path)
		
		if(CLIENT)then
			include(path)
		end
	else
		if(SERVER)then
			include(path)
		end
	end
end
--=//

function SORCERY.Plugin.Setup(id)
	_G["PLUGIN"] = SORCERY.Plugin.List[id] or {}
	_G["PLUGIN"].ID = id
	
	setmetatable(_G["PLUGIN"], SORCERY.Plugin.Class_Plugin)

	hook.Run("SORCERY(PluginSetup)", _G["PLUGIN"])
end

function SORCERY.Plugin.Register(plugin, id)
	SORCERY.Plugin.List[id] = plugin
	
	plugin.Name = plugin.Name or "No name"
	plugin.Description = plugin.Description or "No description"
	plugin.Version = plugin.Version or 1
	
	hook.Run("SORCERY(PluginRegistered)", id, plugin)
end

function SORCERY.Plugin.Get(id)
	return SORCERY.Plugin.List[id]
end

function SORCERY.Plugin.IncludePlugin(rootFolder, obj)
	if(string.StartsWith(obj, "sh_"))then
		local id = string.StripExtension(obj)
		
		SORCERY.Plugin.Setup(id)
		AddCSLuaFile(rootFolder .. obj)
		include(rootFolder .. obj)
		SORCERY.Plugin.Register(PLUGIN, id)
	elseif(string.StartsWith(obj, "cl_"))then
		AddCSLuaFile(rootFolder .. obj)
		
		if(CLIENT)then
			local id = string.StripExtension(obj)
			
			SORCERY.Plugin.Setup(id)
			include(rootFolder .. obj)
			SORCERY.Plugin.Register(PLUGIN, id)
		end
	else
		if(SERVER)then
			local id = string.StripExtension(obj)
			
			SORCERY.Plugin.Setup(id)
			include(rootFolder .. obj)
			SORCERY.Plugin.Register(PLUGIN, id)
		end
	end
end

function SORCERY.Plugin.LoadPluginsDir(rootFolder)
	local files, directories = file.Find(rootFolder .. "*", "LUA")
	
	for _, obj in ipairs(files) do
		SORCERY.Plugin.IncludePlugin(rootFolder, obj)
	end
	
	for _, dir in ipairs(directories) do
		SORCERY.Plugin.Setup(dir)
		PLUGIN:Include(rootFolder .. dir .. "/sh_plugin.lua")
		SORCERY.Plugin.Register(PLUGIN, dir)
	end
end

--; These functions will not do any safety against scripthooks (or they will?)
function SORCERY.Plugin.IncludeSuperFirst()
	SORCERY.Plugin.LoadPluginsDir("sorcery/includes_superfirst/")
end

function SORCERY.Plugin.IncludeFirst()
	SORCERY.Plugin.LoadPluginsDir("sorcery/includes_first/")
end

function SORCERY.Plugin.Include()
	SORCERY.Plugin.LoadPluginsDir("sorcery/includes/")
end

SORCERY.Plugin.IncludeSuperFirst()
SORCERY.Plugin.IncludeFirst()
--; SORCERY.Include() will occur later in the file
--//

--\\Plugins
SORCERY.Plugin.Include()
--//

if(SERVER)then
	concommand.Add( "sorcery_test", function( ply, cmd, args )
		local PLUGIN_Wisp = SORCERY.Plugin.Get("wisp")
		local PLUGIN_Spell = SORCERY.Plugin.Get("spell")
		
		local wisp = PLUGIN_Wisp.CreateWisp{
			SpellObject = PLUGIN_Spell.CreateSpell([[entity position say]], Entity(1), Entity(1), nil),
			Size = 10,
			LifeTime = 10,
			Color = Color(55, 55, 44, 100),
			Pos = Entity(1):EyePos(),
			Vel = Entity(1):GetAimVector() * 1000,
			LoseVelocity = 100,
			DieOnHit = false,
			SORCERY_QUOTA = 100,
		}
		
		print(wisp)
	end)
end


if(SERVER)then
	-- local cf = SORCERY:TranslateIncantationToCode([[from my eyes and my own look with `123` multiplied, give the trace, which "Entity" you will get and say it]], nil)
	local cf = SORCERY:TranslateIncantationToCode([[from my eyes and my own look with `123` multiplied, give the trace, which "Entity" you will get and say it]], nil)
	
	print(cf)
	
	SORCERY:RunCompiledIncantation(SORCERY:CompileIncantationCode(cf), Entity(1), nil, nil, nil)
end

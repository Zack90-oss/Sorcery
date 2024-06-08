local PLUGIN = PLUGIN

function PLUGIN.NetworkReceivedWispCreate()
	local wisp = {}

	for _, info in ipairs(PLUGIN.NetworkTableFull)do
		local key = info[1]
		local read = info[3]
		
		wisp[key] = read()
	end
	
	if(PLUGIN.WispTable[wisp.Key])then
		PLUGIN.WispTable[wisp.Key]:Remove()
	end
	
	PLUGIN.CreateWisp(wisp)
end

function PLUGIN.NetworkReceivedWispUpdate()
	local wisp = nil
	local wisp_key = nil

	for _, info in ipairs(PLUGIN.NetworkTableUpdate)do
		local key = info[1]
		local read = info[3]
		
		if(!wisp_key)then
			wisp_key = read()
			wisp = PLUGIN.WispTable[wisp_key]
		else
			if(wisp)then
				wisp[key] = read()
			else
				break
			end
		end
	end
	
	net.Start("SORCERY.Plugin[wisp](CreateWisp)")
		PLUGIN.net_writekey(wisp_key)
	net.SendToServer()
end

net.Receive("SORCERY.Plugin[wisp](CreateWisp)", function(len)
	PLUGIN.NetworkReceivedWispCreate()
end)

net.Receive("SORCERY.Plugin[wisp](UpdateWisp)", function(len)
	PLUGIN.NetworkReceivedWispUpdate()
end)

net.Receive("SORCERY.Plugin[wisp](RemoveWisp)", function(len)
	local wisp_key = PLUGIN.net_readkey()
	local wisp = PLUGIN.WispTable[wisp_key]
	
	if(wisp)then
		wisp:Remove()
	end
end)
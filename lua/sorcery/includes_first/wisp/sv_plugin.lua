local PLUGIN = PLUGIN
PLUGIN.NetCDCreateWisp = 0.1
PLUGIN.NetCDUpdateWisp = 1
PLUGIN.NetCDRemoveWisp = 0.1 --; Unused

util.AddNetworkString("SORCERY.Plugin[wisp](CreateWisp)")
util.AddNetworkString("SORCERY.Plugin[wisp](UpdateWisp)")
util.AddNetworkString("SORCERY.Plugin[wisp](RemoveWisp)")

function PLUGIN.NetworkWriteWispTable(wisp, net_table)
	for _, info in ipairs(net_table)do
		local key = info[1]
		local write = info[2]
		
		if(write(wisp[key]) == false)then
			return false
		end
	end
end

function PLUGIN.NetworkWispUpdate(wisp, ply)
	net.Start("SORCERY.Plugin[wisp](UpdateWisp)", true)
		if(PLUGIN.NetworkWriteWispTable(wisp, PLUGIN.NetworkTableUpdate) == false)then
			net.Abort()
			return false
		end
	
	if(ply)then
		net.Send(ply)
	else
		net.SendPVS(wisp.Pos)
	end
end

function PLUGIN.NetworkWispFull(wisp, ply)
	net.Start("SORCERY.Plugin[wisp](CreateWisp)", true)
		if(PLUGIN.NetworkWriteWispTable(wisp, PLUGIN.NetworkTableFull) == false)then
			net.Abort()
			return false
		end
	
	if(ply)then
		net.Send(ply)
	else
		net.SendPVS(wisp.Pos)
	end
end

function PLUGIN.NetworkWispRemove(wisp, ply)
	net.Start("SORCERY.Plugin[wisp](RemoveWisp)", true)
		PLUGIN.net_writekey(wisp.Key)
	
	if(ply)then
		net.Send(ply)
	else
		net.SendPVS(wisp.Pos)
	end
end

net.Receive("SORCERY.Plugin[wisp](CreateWisp)", function(len, ply)
	if(!ply.SORCERY_WISP_LastFullNet or (ply.SORCERY_WISP_LastFullNet + PLUGIN.NetCDCreateWisp) <= CurTime())then
		local wisp_key = PLUGIN.net_readkey()
		local wisp = PLUGIN.WispTable[wisp_key]
		
		if(wisp)then
			PLUGIN.NetworkWispFull(wisp, ply)
		end
	end
end)
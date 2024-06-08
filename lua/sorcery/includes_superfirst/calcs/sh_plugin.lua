local PLUGIN = PLUGIN
PLUGIN.Version = 1
-- PLUGIN.QuotaForVelocitySqrCost = 0.0002
PLUGIN.QuotaForVelocityCost = 1

--=\\Quota calcs
function PLUGIN.CalcQuotaForVelocity(len, instant)
	if(instant)then
		return len * PLUGIN.QuotaForVelocityCost
	else
		local interval = engine.TickInterval()	--; Calcs based on last tick interval (Looks shitty)
		
		return len * interval * PLUGIN.QuotaForVelocityCost
	end
end
--=//
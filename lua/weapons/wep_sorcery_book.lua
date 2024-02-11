SWEP.PrintName		= "Sorcery Book"
SWEP.Instructions	= [[This book may contain your incantation pages.

Hold ATTACK to begin invocation on selected page.
Hold RELOAD to change the pages.]]
if(CLIENT)then
	SWEP.WepSelectIcon=surface.GetTextureID("vgui/wep_jack_hmcd_smallpistol")
	SWEP.BounceWeaponIcon=false
end
SWEP.ViewModelFOV	= 62
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 1
SWEP.SlotPos = 1

SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/weapons/c_crowbar.mdl"
SWEP.WorldModel		= "models/demonssouls/weapons/battle_axe.mdl"

SWEP.Spawnable		= false
SWEP.AdminOnly		= false

SWEP.Primary.ClipSize		= 0
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

--Stop giving ammo--
SWEP.Secondary.Delay		= 0.9
SWEP.Secondary.Recoil		= 0
SWEP.Secondary.Damage		= 0
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic   	= false
SWEP.Secondary.Ammo         = "none"
--				  --

SWEP.HoldType = "slam"

function SWEP:Initialize()
	self:SetNextPrimaryFire( CurTime() )
	self:SetHoldType( self.HoldType )
	self.Pages={}
	self.ActiveLights={}
end

function SWEP:Deploy()
	self:SetHoldType( self.HoldType )
	self:SetNextPrimaryFire( CurTime() )
	return true
end

function SWEP:DrawHUD()
		--
end

function SWEP:PrimaryAttack()

end

function SWEP:Think()
	
end

function SWEP:SelectPage(Page)
	
end
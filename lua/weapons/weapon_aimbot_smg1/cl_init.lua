include('shared.lua')

SWEP.PrintName = "Aimbot SMG1";
SWEP.Slot = 2;
SWEP.SlotPos = 1;
SWEP.DrawAmmo = true;
SWEP.DrawCrosshair = false;

function SWEP:Initialize()
	self:InitAimbotGun("weapon_aimbot_smg1")
end

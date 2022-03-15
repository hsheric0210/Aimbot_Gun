include('shared.lua')

SWEP.PrintName = "Aimbot .357 MAGNUM";
SWEP.Slot = 1;
SWEP.SlotPos = 1;
SWEP.DrawAmmo = true;
SWEP.DrawCrosshair = false;

function SWEP:Initialize()
	self:InitAimbotGun("weapon_aimbot_357")
end

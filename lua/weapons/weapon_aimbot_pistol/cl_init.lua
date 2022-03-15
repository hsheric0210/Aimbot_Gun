include('shared.lua')

SWEP.PrintName = "Aimbot Pistol";
SWEP.Slot = 1;
SWEP.SlotPos = 1;
SWEP.DrawAmmo = true;
SWEP.DrawCrosshair = false;

function SWEP:Initialize()
	self:InitAimbotGun("weapon_aimbot_pistol")
end

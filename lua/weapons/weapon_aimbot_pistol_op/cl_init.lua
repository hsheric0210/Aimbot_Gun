include('shared.lua')

SWEP.PrintName = "Aimbot Pistol (OP)";
SWEP.Slot = 1;
SWEP.SlotPos = 1;
SWEP.DrawAmmo = false;
SWEP.DrawCrosshair = false;

function SWEP:Initialize()
	self:InitAimbotGun("weapon_aimbot_pistol_op")
end

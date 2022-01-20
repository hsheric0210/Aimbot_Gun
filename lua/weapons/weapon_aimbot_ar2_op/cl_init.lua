include('shared.lua')

SWEP.PrintName = "Aimbot AR2 (OP)";
SWEP.Slot = 2;
SWEP.SlotPos = 1;
SWEP.DrawAmmo = false;
SWEP.DrawCrosshair = false;

function SWEP:Initialize()
	self:InitAimbotGun("weapon_aimbot_ar2_op")
end

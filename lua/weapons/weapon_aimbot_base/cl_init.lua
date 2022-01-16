include('shared.lua')

SWEP.PrintName = "Aimbot Gun v2";
SWEP.Slot = 1;
SWEP.SlotPos = 1;
SWEP.DrawAmmo = false;
SWEP.DrawCrosshair = false;

function SWEP:Initialize()
	surface.CreateFont("Arial",
					   {
						   font = "Arial",
						   size = ScreenScale(10),
						   weight = 400
					   })

	killicon.Add("weapon_aimbot_ar2", "aimbot/killico", color_white)
end

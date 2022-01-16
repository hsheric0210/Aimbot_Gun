AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

SWEP.Weight = 5;
SWEP.AutoSwitchTo = false;
SWEP.AutoSwitchFrom = false;

resource.AddFile("materials/aimbot/killico.png")

function SWEP:Initialize()

end

function SWEP:OnRemove()

end

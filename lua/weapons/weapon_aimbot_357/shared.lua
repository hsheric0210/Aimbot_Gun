SWEP.Base = "weapon_aimbot_base"
SWEP.Spawnable = true;
SWEP.AdminSpawnable = true;
SWEP.AdminOnly = true
SWEP.Category = "uacport Sweps"
SWEP.IconLetter = "D"
SWEP.Contact = ""
SWEP.Purpose = "Helps shooting at enemies"
SWEP.Instructions = "Left Click to shoot.\n\nDoes not req. CS:S. :D"

SWEP.ViewModel = "models/weapons/v_357.mdl"
SWEP.WorldModel = "models/weapons/w_357.mdl"

SWEP.HoldType = "revolver"

SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = 9999999
SWEP.Primary.Delay = 0.5
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "357"
-- There was a bug here that occured when I removed the sound. Should be fixed now.
SWEP.Primary.Sound = Sound("Weapon_357.Single") -- If someone's got a better idea than this sound I'll try it out.
SWEP.Primary.Recoil = 5
SWEP.Primary.Force = 10000
SWEP.Primary.Damage = 10000
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.0
SWEP.Primary.AmmoTook = 0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

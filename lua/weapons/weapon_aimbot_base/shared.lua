SWEP.Spawnable = false;
SWEP.AdminSpawnable = false;
SWEP.AdminOnly = false
SWEP.Category = ""
SWEP.IconLetter = ""
SWEP.Author = "Ai2, Orig: LuaStoned, Ported by uacnix, improved by eric0210"
SWEP.Contact = ""
SWEP.Purpose = "Helps shooting at enemies"
SWEP.Instructions = "Left Click to shoot.\n\nDoes not req. CS:S. :D"

SWEP.ViewModelFlip = false -- I don't like left-side SWEPs either.

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Delay = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 0
SWEP.Primary.Cone = 0.0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
	self:SetNWInt("LastShoot", 0)
end

----------------------------------------------------------------------------------------------------
-- The rest of the code I don't have to really bother with as the following is aimbot code.
----------------------------------------------------------------------------------------------------

SWEP.Aimbot = {}
SWEP.Aimbot.Target = nil

function SWEP:UpdateTarget()
	local target = AimbotGun.GetClosestBone(self:GetOwner())
	local available = target.Entity ~= 0
	self.Aimbot.Target = available and target or nil

	if available and self:Clip1() > 0 and GetConVar("aimbotgun_triggerbot"):GetInt() ~= 0 and CurTime() - self:GetNWInt("LastAimbotActive", 0) >= math.max(self.Primary.Delay, GetConVar("aimbotgun_aimbot_reflick_delay"):GetFloat() * 1.2) then
		self:ShootAt(target, true)
	end
end

function SWEP:Think()
	self:UpdateTarget()
end

function SWEP:ShootAt(target, disallowNoTargetShot)
	if not self:CanPrimaryAttack() then
		return
	end

	local targetEnt = target ~= nil and target.Entity or nil
	local targetAvailable = targetEnt ~= nil and targetEnt ~= 0
	if not targetAvailable and disallowNoTargetShot then
		return
	end

	self:SetNWInt("LastAimbotActive", CurTime())

	-- Debug codes
	--if targetAvailable then
	--	print("Class: " .. targetEnt:GetClass() .. ", Model: " .. targetEnt:GetModel())
	--	print("Attachments:")
	--	PrintTable(targetEnt:GetAttachments())
	--	print("Bones:")
	--	for i = 0, targetEnt:GetBoneCount() - 1 do
	--		print(i, targetEnt:GetBoneName(i))
	--	end
	--	print("Sequences:")
	--	PrintTable(targetEnt:GetSequenceList())
	--end

	local owner = self:GetOwner()
	local silent = GetConVar("aimbotgun_aimbot_silent"):GetInt() ~= 0
	local prevAngle = owner:LocalEyeAngles()

	local dir = targetAvailable and (target.Bone.Pos - owner:GetShootPos()) or owner:GetAimVector()
	if targetAvailable and not silent then
		owner:SetEyeAngles(dir:Angle())
	end

	self:FirePrimary(dir)

	if targetAvailable and not silent and GetConVar("aimbotgun_aimbot_reflick"):GetInt() ~= 0 then
		timer.Simple(GetConVar("aimbotgun_aimbot_reflick_delay"):GetFloat(), function()
			owner:SetEyeAngles(prevAngle)
		end)
	end

	-- Check if all ammo is spent
	self:CanPrimaryAttack()
end

function SWEP:FirePrimary(dir)
	self:EmitSound(self.Primary.Sound)

	local bullet = {}
	bullet.Num = self.Primary.NumShots
	bullet.Src = self:GetOwner():GetShootPos()
	bullet.Dir = dir
	bullet.Spread = Vector(self.Primary.Cone, self.Primary.Cone, 0)
	bullet.Tracer = 1
	bullet.Force = self.Primary.Force
	bullet.Damage = self.Primary.Damage

	self:GetOwner():FireBullets(bullet)
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:GetOwner():MuzzleFlash()
	self:GetOwner():SetAnimation(PLAYER_ATTACK1)

	self:TakePrimaryAmmo(self.Primary.AmmoTook)
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if self.Primary.Recoil > 0 and SERVER and not self:GetOwner():IsNPC() then
		self:GetOwner():ViewPunch(Angle(-self.Primary.Recoil + self.Primary.Recoil * math.Rand(-0.5, 0.5), 0, 0))
	end
end

function SWEP:Reload()
	self:DefaultReload(ACT_VM_RELOAD)
end

function SWEP:PrimaryAttack()
	if self.Primary.AmmoTook > 0 and not self:CanPrimaryAttack() then
		return
	end
	self:ShootAt(self.Aimbot.Target, false)
end

function SWEP:SecondaryAttack()
end

function SWEP:ShouldDropOnDie()
	return false
end

function SWEP:DrawWeaponSelection(x, y, wide, tall, _)
	draw.SimpleText("Aimbot Gun", "Arial", x + wide / 2, y + tall * 0.35, Color(0, 255, 0, 255), TEXT_ALIGN_CENTER) -- is this right?
end

function SWEP:DrawRotatingCrosshair(x, y, time, length, gap)
	surface.DrawLine(
			x + (math.sin(math.rad(time)) * length),
			y + (math.cos(math.rad(time)) * length),
			x + (math.sin(math.rad(time)) * gap),
			y + (math.cos(math.rad(time)) * gap)
	)
end

function SWEP:GetBoneCoordiantes(pos)
	local expand = Vector(1, 1, 1)
	local min = pos - expand
	local max = pos + expand
	local corners = {
		Vector(min.x, min.y, min.z),
		Vector(min.x, min.y, max.z),
		Vector(min.x, max.y, min.z),
		Vector(min.x, max.y, max.z),
		Vector(max.x, min.y, min.z),
		Vector(max.x, min.y, max.z),
		Vector(max.x, max.y, min.z),
		Vector(max.x, max.y, max.z)
	}

	local minx, miny, maxx, maxy = ScrW() * 2, ScrH() * 2, 0, 0
	for _, corner in pairs(corners) do
		local screen = corner:ToScreen()
		minx, miny = math.min(minx, screen.x), math.min(miny, screen.y)
		maxx, maxy = math.max(maxx, screen.x), math.max(maxy, screen.y)
	end
	return minx, miny, maxx, maxy
end

function SWEP:GetVerboseText(target)
	return "targetBone: " .. target.Bone.Name .. " boneAngularOffset: " .. target.Entity.AimbotData.BoneAngularOffset .. " fov: " .. target.FOV
end

function SWEP:DrawHUD()
	local x, y = ScrW(), ScrH()
	local w, h = x / 2, y / 2

	surface.SetDrawColor(Color(0, 0, 0, 235))
	surface.DrawRect(w - 1, h - 3, 3, 7)
	surface.DrawRect(w - 3, h - 1, 7, 3)

	surface.SetDrawColor(Color(0, 255, 10, 230))
	surface.DrawLine(w, h - 2, w, h + 3)
	surface.DrawLine(w - 2, h, w + 3, h)

	local time = CurTime() * -180 * GetConVar("aimbotgun_visual_crosshair_spin_speed"):GetFloat()
	local scale = 10 * 0.02 -- self.Cone
	local gap = 40 * scale
	local length = gap + 20 * scale

	local crosshairAlpha = GetConVar("aimbotgun_visual_crosshair_color_alpha"):GetInt()
	if GetConVar("aimbotgun_visual_crosshair_rainbow"):GetInt() ~= 0 then
		local rainbow = HSVToColor(CurTime() * 360 * GetConVar("aimbotgun_visual_crosshair_rainbow_speed"):GetFloat() % 360, 1, 1)
		surface.SetDrawColor(rainbow.r, rainbow.g, rainbow.b, crosshairAlpha)
	else
		surface.SetDrawColor(GetConVar("aimbotgun_visual_crosshair_color_red"):GetInt(), GetConVar("aimbotgun_visual_crosshair_color_green"):GetInt(), GetConVar("aimbotgun_visual_crosshair_color_blue"):GetInt(), crosshairAlpha)
	end

	self:DrawRotatingCrosshair(w, h, time, length, gap)
	self:DrawRotatingCrosshair(w, h, time + 90, length, gap)
	self:DrawRotatingCrosshair(w, h, time + 180, length, gap)
	self:DrawRotatingCrosshair(w, h, time + 270, length, gap)

	local target = self.Aimbot.Target
	if target ~= nil then
		surface.SetFont("Default")

		local text = "Target locked... (" .. AimbotGun.GetTargetName(target) .. ")"
		local size = surface.GetTextSize(text)
		draw.RoundedBox(4, 36, y - 135, size + 10, 20, Color(0, 0, 0, 100))
		draw.DrawText(text, "Default", 40, y - 132, Color(255, 255, 255, 200), TEXT_ALIGN_LEFT)

		local verboseText = self:GetVerboseText(target)
		local verboseSize = surface.GetTextSize(verboseText)
		draw.RoundedBox(4, 36, y - 155, verboseSize + 10, 20, Color(0, 0, 0, 100))
		draw.DrawText(verboseText, "Default", 40, y - 152, Color(255, 255, 255, 200), TEXT_ALIGN_LEFT)

		local x1, y1, x2, y2 = self:GetBoneCoordiantes(target.Bone.Pos)
		local edgesize = 8

		local targetMarkAlpha = GetConVar("aimbotgun_visual_target_mark_color_alpha"):GetInt()
		if GetConVar("aimbotgun_visual_target_mark_rainbow"):GetInt() ~= 0 then
			local rainbow = HSVToColor(CurTime() * 360 * GetConVar("aimbotgun_visual_target_mark_rainbow_speed"):GetFloat() % 360, 1, 1)
			surface.SetDrawColor(rainbow.r, rainbow.g, rainbow.b, targetMarkAlpha)
		else
			surface.SetDrawColor(GetConVar("aimbotgun_visual_target_mark_color_red"):GetInt(), GetConVar("aimbotgun_visual_target_mark_color_green"):GetInt(), GetConVar("aimbotgun_visual_target_mark_color_blue"):GetInt(), targetMarkAlpha)
		end
		-- Top left.
		surface.DrawLine(x1, y1, math.min(x1 + edgesize, x2), y1)
		surface.DrawLine(x1, y1, x1, math.min(y1 + edgesize, y2))

		-- Top right.
		surface.DrawLine(x2, y1, math.max(x2 - edgesize, x1), y1)
		surface.DrawLine(x2, y1, x2, math.min(y1 + edgesize, y2))

		-- Bottom left.
		surface.DrawLine(x1, y2, math.min(x1 + edgesize, x2), y2)
		surface.DrawLine(x1, y2, x1, math.max(y2 - edgesize, y1))

		-- Bottom right.
		surface.DrawLine(x2, y2, math.max(x2 - edgesize, x1), y2)
		surface.DrawLine(x2, y2, x2, math.max(y2 - edgesize, y1))
	end
end

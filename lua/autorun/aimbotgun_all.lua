
local AimbotGun_ConVars = {
	-- global aimbot
	["aimbotgun_global"] = "0",
	["aimbotgun_global_spreadmultiplier"] = "0.5",
	-- general
	["aimbotgun_aimbot_silent"] = "0",
	["aimbotgun_aimbot_reflick"] = "0",
	["aimbotgun_aimbot_reflick_delay"] = "0.01",
	["aimbotgun_triggerbot"] = "0",
	["aimbotgun_aimbot_fov"] = "2",
	["aimbotgun_wallcheck"] = "1",
	["aimbotgun_bone"] = "2",
	-- target
	["aimbotgun_target_player"] = "1",
	["aimbotgun_friendly_fire"] = "1",
	["aimbotgun_target_bird"] = "1",
	["aimbotgun_target_combine"] = "1",
	["aimbotgun_target_hunter"] = "1",
	["aimbotgun_target_manhack"] = "1",
	["aimbotgun_target_scanner"] = "1",
	["aimbotgun_target_antlion"] = "1",
	["aimbotgun_target_headcrab"] = "1",
	["aimbotgun_target_zombie"] = "1",
	["aimbotgun_target_barnacle"] = "1",
	-- crosshair
	["aimbotgun_visual_crosshair_spin_speed"] = "1",
	["aimbotgun_visual_crosshair_color_red"] = "255",
	["aimbotgun_visual_crosshair_color_green"] = "0",
	["aimbotgun_visual_crosshair_color_blue"] = "0",
	["aimbotgun_visual_crosshair_color_alpha"] = "150",
	["aimbotgun_visual_crosshair_rainbow"] = "0",
	["aimbotgun_visual_crosshair_rainbow_speed"] = "1",
	-- target mark
	["aimbotgun_visual_target_mark_color_red"] = "0",
	["aimbotgun_visual_target_mark_color_green"] = "255",
	["aimbotgun_visual_target_mark_color_blue"] = "1",
	["aimbotgun_visual_target_mark_color_alpha"] = "200",
	["aimbotgun_visual_target_mark_rainbow"] = "0",
	["aimbotgun_visual_target_mark_rainbow_speed"] = "1"
}

CreateConVar("aimbotgun_enabled", "1", FCVAR_ARCHIVE)

for k, v in pairs(AimbotGun_ConVars) do
	CreateConVar(k, v, FCVAR_ARCHIVE)
end

local ENT_META = FindMetaTable("Entity")

local RandomSphere = function(radius)
	if (radius == 0) then return Vector(0, 0, 0) end
	
	local x = 2 * radius * math.asin(2 * math.asin(math.Rand(-1.0, 1.0)) / math.pi) / math.pi
	local y = 2 * math.sqrt(radius^2 - x^2) * math.asin(math.Rand(-1.0, 1.0)) / math.pi
	local z = math.sqrt(radius^2 - x^2 - y^2) * math.Rand(-1.0, 1.0)
	
	return Vector(x, y, z)
end

local ApplyAimGod = function(self, bulletdata)
	if bulletdata.Aimbotted then
		return false
	end
	if self:IsPlayer() and GetConVar("aimbotgun_global"):GetBool() then
		if not self.AimTarget then
			self.AimTarget = nil
		end
		local owner = bulletdata.Attacker
		if owner == nil then
			owner = self
		end
		local silent = GetConVar("aimbotgun_aimbot_silent"):GetInt() ~= 0
		local prevAngle = owner:LocalEyeAngles()

		local target = owner.AimbotTarget
		if target == nil then
			target = AimbotGun.GetClosestBone(owner)
		end
		if target.Entity ~= 0 then
			-- let's aim!
			local dir = target.Bone.Pos - owner:EyePos()
			if not silent then
				owner:SetEyeAngles(dir:Angle())
			end

			local spreadMul = GetConVar("aimbotgun_global_spreadmultiplier"):GetFloat()
			if bulletdata.Spread then
				if spreadMul == 0.0 then
					bulletdata.Spread = Vector(0, 0, 0)
				else
					local rand = RandomSphere(math.sqrt((bulletdata.Spread.x ^ 2 + bulletdata.Spread.y ^ 2) / 2)) * spreadMul
					local norm = dir:GetNormalized()
					dir = (norm + (rand - norm * rand:Dot(norm))):GetNormal()
				end
			end
			bulletdata.Dir = dir
			bulletdata.Aimbotted = true

			if not owner.ReflickWait and not silent and GetConVar("aimbotgun_aimbot_reflick"):GetInt() ~= 0 then
				timer.Simple(GetConVar("aimbotgun_aimbot_reflick_delay"):GetFloat(), function()
					owner:SetEyeAngles(prevAngle)
					owner.ReflickWait = false
				end)
			end
			owner.ReflickWait = true

			return true
		end
	end

	return false
end

EntityFireAimbotBullets = function(self, data, ...)
	if ApplyAimGod(self, data) then
		print("Aim by Hook!")
		return true
	end
end

EntityTriggerbotUpdate = function(self)
	if GetConVar("aimbotgun_triggerbot"):GetInt() ~= 0 then
		for _, ent in pairs(ents.GetAll()) do
			if ent and ent:IsValid() and ent:IsPlayer() and ent:GetActiveWeapon() and ent:GetActiveWeapon():IsScripted() and ent:GetActiveWeapon():Clip1() > 0 and ent:GetActiveWeapon():GetNextPrimaryFire() < CurTime() then
				ent.AimbotTarget = AimbotGun.GetClosestBone(ent)
				if ent.AimbotTarget and ent.AimbotTarget.Entity ~= 0 then
					ent.Trigger = true
				end
			end
		end
	end
end

EntityTriggerbotApply = function(self, move)
	if self.Trigger then
		if CLIENT then
			chat.AddText("Attack!")
		end
		move:AddKey(IN_ATTACK)
		self.Trigger = false
	end
end

hook.Add("EntityFireBullets", "AimbotGun_EntityFireBullets", EntityFireAimbotBullets)
hook.Add("Think", "AimbotGun_Think", EntityTriggerbotUpdate)
hook.Add("StartCommand", "AimbotGun_FinishMove", EntityTriggerbotApply)

print("AimbotGun global autorun initialized")

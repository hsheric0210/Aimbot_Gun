
local AimbotGun_ConVars = {
	-- global aimbot
	["aimbotgun_global"] = "0",
	["aimbotgun_global_spreadmultiplier"] = "0.5",
	["aimbotgun_global_triggerdelay"] = "0.1",
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
	["aimbotgun_target_all"] = "0",
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

		local target = nil
		if GetConVar("aimbotgun_triggerbot"):GetInt() ~= 0 then
			target = owner.AimbotTarget
		end
		if target == nil or target.Entity == 0 or not IsValid(target.Entity) then
			target = AimbotGun.GetClosestBone(owner)
			owner.AimbotTarget = target
		end
		if target.Entity ~= 0 then
			-- let's aim!
			local tpos = target.Bone.Pos
			local dir = tpos - owner:EyePos()
			if not silent then
				owner.AimbotAngle = dir:Angle()
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

			if not silent and GetConVar("aimbotgun_aimbot_reflick"):GetInt() ~= 0 then
				timer.Simple(GetConVar("aimbotgun_aimbot_reflick_delay"):GetFloat(), function()
					owner.ReflickAngle = prevAngle
					owner.ReflickWait = false
				end)
			end
			owner.ReflickWait = true

			net.Start("AimbotGunResult")
			net.WriteVector(tpos)
			net.WriteString(AimbotGun.GetTargetName(target))
			net.Send(self)

			return true
		end
	end

	return false
end

local FireBullets = function(self, data, ...)
	if ApplyAimGod(self, data) then
		return true
	end
end

local TriggerbotTick = function(self)
	if GetConVar("aimbotgun_triggerbot"):GetInt() ~= 0 then
		for _, ent in pairs(ents.GetAll()) do
			if ent and ent:IsValid() and ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) then
				if ent:GetActiveWeapon():Clip1() > 0 and ent:GetActiveWeapon():GetNextPrimaryFire() < CurTime() then
					local target = AimbotGun.GetClosestBone(ent)
					if target and target.Entity ~= 0 and IsValid(target.Entity) then
						ent.Trigger = true
						ent.AimbotTarget = target
					end
				elseif ent:GetActiveWeapon():Clip1() <= 0 and ent:GetActiveWeapon().CanPrimaryAttack ~= nil then
					-- ent:GetActiveWeapon():CanPrimaryAttack() -- Reload
				end
			end
		end
	end
end

local LastTrigger = 0

local ApplyAimAndTriggerbot = function(self, move)
	local delay = CurTime() - LastTrigger
	if self.Trigger and delay > GetConVar("aimbotgun_global_triggerdelay"):GetFloat() then
		move:AddKey(IN_ATTACK)
		self.Trigger = false
		if CLIENT then
			-- chat.AddText("Pressed Trigger! delay=" .. delay)
		end
		LastTrigger = CurTime()
	end

	if self.AimbotAngle ~= nil then
		move:SetViewAngles(self.AimbotAngle)
		self:SetEyeAngles(self.AimbotAngle)
		self.AimbotAngle = nil
	elseif self.ReflickAngle ~= nil then
		move:SetViewAngles(self.ReflickAngle)
		self:SetEyeAngles(self.ReflickAngle)
		self.ReflickAngle = nil
	end
end

local DrawMark = function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local text = ply.ClientAimbotTargetString
	if text == nil then return end

	local targetpos = ply.ClientAimbotTargetPos
	if targetpos == nil then return end

	local x, y = ScrW(), ScrH()
	local w, h = x / 2, y / 2

	surface.SetFont("Default")

	local size = surface.GetTextSize(text)
	draw.RoundedBox(4, 36, y - 135, size + 10, 20, Color(0, 0, 0, 100))
	draw.DrawText(text, "Default", 40, y - 132, Color(255, 255, 255, 200), TEXT_ALIGN_LEFT)

	local x1, y1, x2, y2 = AimbotGun.ProjectPosition2D(targetpos)
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

local AimbotGunCommReceived = function(len, ply)
	local aimtarget = net.ReadVector()
	local targetstring = net.ReadString()
	chat.AddText("[AimbotGun] ", targetstring)
	local plr = LocalPlayer()
	plr.ClientAimbotTargetString = targetstring
	plr.ClientAimbotTargetPos = aimtarget
end

if SERVER then
	util.AddNetworkString("AimbotGunResult")
elseif CLIENT then
	net.Receive("AimbotGunResult", AimbotGunCommReceived)
end

hook.Add("EntityFireBullets", "AimbotGunFireBullets", FireBullets)
hook.Add("Think", "AimbotGunTick", TriggerbotTick)
hook.Add("StartCommand", "AimbotGunApply", ApplyAimAndTriggerbot)
hook.Add("PostDrawHUD", "AimbotRenderHUD", DrawMark)

print("AimbotGun global autorun initialized")

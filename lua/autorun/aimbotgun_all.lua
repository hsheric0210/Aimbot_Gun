
local AimbotGun_ConVars = {
	-- global aimbot
	["aimbotgun_global"] = "0",
	["aimbotgun_global_bind_aimassist"] = "0",
	["aimbotgun_global_bind_flick"] = "0",
	["aimbotgun_global_nospread"] = "0",
	["aimbotgun_global_triggerdelay"] = "0.1",
	["aimbotgun_global_spreadmultiplier"] = "0.5",
	-- general
	["aimbotgun_aimbot_mode"] = "0",
	["aimbotgun_aimbot_minyawspeed"] = "180",
	["aimbotgun_aimbot_maxyawspeed"] = "180",
	["aimbotgun_aimbot_minpitchspeed"] = "180",
	["aimbotgun_aimbot_maxpitchspeed"] = "180",
	["aimbotgun_aimbot_yawsmooth"] = "1",
	["aimbotgun_aimbot_pitchsmooth"] = "1",
	["aimbotgun_aimbot_silent"] = "0",
	["aimbotgun_aimbot_reflick"] = "0",
	["aimbotgun_aimbot_reflick_delay"] = "0.01",
	["aimbotgun_aimbot_fov"] = "2",
	["aimbotgun_aimbot_wallcheck"] = "1",
	["aimbotgun_aimbot_bone"] = "2",
	["aimbotgun_aimbot_smooth"] = "0",
	["aimbotgun_triggerbot"] = "0",
	["aimbotgun_aimbot_predictsize"] = "0.1",
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
	["aimbotgun_visual_target_mark_rainbow_speed"] = "1",
	-- debugging
	["aimbotgun_debug_targetdata"] = "0",
	["aimbotgun_debug_triggerbot"] = "0"
}

CreateConVar("aimbotgun_enabled", "1", FCVAR_ARCHIVE)

for k, v in pairs(AimbotGun_ConVars) do
	CreateConVar(k, v, FCVAR_ARCHIVE)
end

-- Utility functions

local Smoothing = {
	[0] = function(angchange, minspeed, maxspeed, smooth) -- simple
		return angchange / smooth
	end,
	[1] = function(angchange, minspeed, maxspeed, smooth) -- line
		return (angchange / 180) * maxspeed + (1 - angchange / 180) * minspeed
	end,
	[2] = function(angchange, minspeed, maxspeed, smooth) -- quad
		return math.pow(angchange / 180, 2) * maxspeed + (1 - math.pow(angchange / 180, 2)) * minspeed
	end,
	[3] = function(angchange, minspeed, maxspeed, smooth) -- sine
		return (-math.cos(angchange / 180 * math.pi) * 0.5 + 0.5) * maxspeed + (math.cos(angchange / 180 * math.pi) * 0.5 + 0.5) * minspeed
	end,
	[4] = function(angchange, minspeed, maxspeed, smooth) -- quad sine
		return math.pow(-math.cos(angchange / 180 * math.pi) * 0.5 + 0.5, 2) * maxspeed + (1 - math.pow(-math.cos(angchange / 180 * math.pi) * 0.5 + 0.5, 2)) * minspeed
	end
}

local RandomSphere = function(radius)
	if (radius == 0) then return Vector(0, 0, 0) end
	
	local x = 2 * radius * math.asin(2 * math.asin(math.Rand(-1.0, 1.0)) / math.pi) / math.pi
	local y = 2 * math.sqrt(radius^2 - x^2) * math.asin(math.Rand(-1.0, 1.0)) / math.pi
	local z = math.sqrt(radius^2 - x^2 - y^2) * math.Rand(-1.0, 1.0)
	
	return Vector(x, y, z)
end

local IsTargetValid = function(target)
	return target ~= nil and target.Entity ~= 0 and IsValid(target.Entity)
end

local GetAngleDelta = function(a, b)
	return ((((a - b) % 360) + 540) % 360) - 180
end

local FireAimbotBullets = function(self, bulletdata)
	if bulletdata.Aimbotted then
		return false
	end
	if self:IsPlayer() and GetConVar("aimbotgun_aimbot_mode"):GetInt() == 0 and GetConVar("aimbotgun_global"):GetBool() then
		if not self.AimTarget then
			self.AimTarget = nil
		end
		local owner = bulletdata.Attacker
		if owner == nil then
			owner = self
		end
		local silent = GetConVar("aimbotgun_aimbot_silent"):GetBool()
		local prevAngle = owner:LocalEyeAngles()

		local target = nil
		if GetConVar("aimbotgun_triggerbot"):GetBool() then
			target = owner.ServerAimbotTarget
		end

		if not IsTargetValid(target) then
			target = AimbotGun.GetClosestBone(owner)
			owner.ServerAimbotTarget = target
		end

		if IsTargetValid(target) then
			-- let's aim!
			local tpos = target.Bone.Pos
			local dir = tpos - owner:EyePos()
			if not silent then
				owner.AimbotAngle = dir:Angle()
			end

			if GetConVar("aimbotgun_debug_targetdata"):GetBool() then
				net.Start("AimbotGunDebugTargetData")
				net.WriteVector(tpos)
				net.WriteString(AimbotGun.GetTargetName(target))
				net.Send(self)
			end

			local spreadMul = GetConVar("aimbotgun_global_spreadmultiplier"):GetFloat()
			if bulletdata.Spread then
				if spreadMul == 0.0 or GetConVar("aimbotgun_global_nospread"):GetBool() then
					bulletdata.Spread = Vector(0, 0, 0)
				else
					local rand = RandomSphere(math.sqrt((bulletdata.Spread.x ^ 2 + bulletdata.Spread.y ^ 2) / 2)) * spreadMul
					local norm = dir:GetNormalized()
					dir = (norm + (rand - norm * rand:Dot(norm))):GetNormal()
				end
			end
			bulletdata.Dir = dir
			bulletdata.Aimbotted = true

			if not silent and GetConVar("aimbotgun_aimbot_reflick"):GetBool() then
				timer.Simple(GetConVar("aimbotgun_aimbot_reflick_delay"):GetFloat(), function()
					owner.ReflickAngle = prevAngle
					owner.ReflickWait = false
				end)
			end
			owner.ReflickWait = true

			return true
		end
	end

	return false
end

-- Hook handlers

local LastTrigger = 0

local ApplyTriggerbot = function(self, move)
	local delay = CurTime() - LastTrigger
	if self.Triggerbot and delay > GetConVar("aimbotgun_global_triggerdelay"):GetFloat() then
		move:AddKey(IN_ATTACK)
		self.Triggerbot = false
		if CLIENT and GetConVar("aimbotgun_debug_triggerbot"):GetBool() then
			chat.AddText("[AimbotGun] Pressed Trigger! [delay=" .. delay .. "]")
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

local RenderTargetAndMarks = function()
	if not GetConVar("aimbotgun_debug_targetdata"):GetBool() then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local target = ply.ClientAimbotTarget
	if not IsTargetValid(target) then return end

	local x, y = ScrW(), ScrH()
	local w, h = x / 2, y / 2

	surface.SetFont("Default")

	local text = AimbotGun.GetTargetName(target)
	local size = surface.GetTextSize(text)
	draw.RoundedBox(4, 36, y - 135, size + 10, 20, Color(0, 0, 0, 100))
	draw.DrawText(text, "Default", 40, y - 132, Color(255, 255, 255, 200), TEXT_ALIGN_LEFT)

	local x1, y1, x2, y2 = AimbotGun.ProjectPosition2D(target.Bone.Pos)
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

local Tick = function()
	if SERVER and GetConVar("aimbotgun_aimbot_mode"):GetInt() == 0 and GetConVar("aimbotgun_triggerbot"):GetBool() then
		for _, ent in pairs(ents.GetAll()) do
			if ent and ent:IsValid() and ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) then
				if ent:GetActiveWeapon():Clip1() > 0 and ent:GetActiveWeapon():GetNextPrimaryFire() < CurTime() then
					local target = AimbotGun.GetClosestBone(ent)
					if IsTargetValid(target) then
						ent.Triggerbot = true
						ent.ServerAimbotTarget = target
					end
				end
			end
		end
	elseif CLIENT and GetConVar("aimbotgun_aimbot_mode"):GetInt() == 1 then
		local player = LocalPlayer()
		local target = AimbotGun.GetClosestBone(LocalPlayer())
		player.ClientAimbotTarget = target
		if IsTargetValid(target) then
			player.Trigger = true
		end
	end
end

local ApplyAim = function()
	local ply = LocalPlayer()
	if IsValid(ply) and IsTargetValid(ply.ClientAimbotTarget) and input.IsButtonDown(GetConVar("aimbotgun_global_bind_aimassist"):GetInt()) then
		local predict = GetConVar("aimbotgun_aimbot_predictsize"):GetFloat()
		local bonepos = ply.ClientAimbotTarget.Bone.Pos + ply.ClientAimbotTarget.Entity:GetVelocity() * predict
		local pangle = ply:EyeAngles()
		local tangle = (bonepos - ply:GetShootPos()):Angle()
		local yawDelta = GetAngleDelta(tangle.y, pangle.y)
		local pitchDelta = GetAngleDelta(tangle.p, pangle.p)

		local smoothing = Smoothing[GetConVar("aimbotgun_aimbot_smooth"):GetInt()]
		local yawlimit = math.Clamp(smoothing(yawDelta, GetConVar("aimbotgun_aimbot_minyawspeed"):GetFloat(), GetConVar("aimbotgun_aimbot_maxyawspeed"):GetFloat(), GetConVar("aimbotgun_aimbot_yawsmooth"):GetFloat()), -180, 180)
		local pitchlimit = math.Clamp(smoothing(pitchDelta, GetConVar("aimbotgun_aimbot_minpitchspeed"):GetFloat(), GetConVar("aimbotgun_aimbot_maxpitchspeed"):GetFloat(), GetConVar("aimbotgun_aimbot_yawsmooth"):GetFloat()), -180, 180)

		yawDelta = math.Clamp(yawDelta, -yawlimit, yawlimit)
		pitchDelta = math.Clamp(pitchDelta, -pitchlimit, pitchlimit)
		local ang = Angle(pangle.p + pitchDelta, pangle.y + yawDelta, pangle.r)
		ang:Normalize()
		ply:SetEyeAngles(ang)
	end
end

local FireBullets = function(ent, data, ...)
	if FireAimbotBullets(ent, data) then
		return true
	elseif IsValid(ent) and ent:IsPlayer() and GetConVar("aimbotgun_global_nospread"):GetBool() then
		data.Spread = Vector()
		data.Dir = ent:GetAimVector()
		return true
	end
end


-- net handlers

local DebugTargetDataReceive = function(len, ply)
	local aimtarget = net.ReadVector()
	local targetstring = net.ReadString()
	chat.AddText("[AimbotGun] ", targetstring)
	local plr = LocalPlayer()
	plr.ClientAimbotTargetString = targetstring
	plr.ClientAimbotTargetPos = aimtarget
end

if SERVER then
	util.AddNetworkString("AimbotGunDebugTargetData")
elseif CLIENT then
	net.Receive("AimbotGunDebugTargetData", DebugTargetDataReceive)
end

hook.Add("Tick", "AimbotGunTick", Tick)
hook.Add("PostRender", "AimbotGunApplyAim", ApplyAim)
hook.Add("PostDrawHUD", "AimbotGunRenderHUD", RenderTargetAndMarks)
hook.Add("StartCommand", "AimbotGunApplyTriggerbot", ApplyTriggerbot)
hook.Add("EntityFireBullets", "AimbotGunFireBullets", FireBullets)

print("AimbotGun global autorun initialized")

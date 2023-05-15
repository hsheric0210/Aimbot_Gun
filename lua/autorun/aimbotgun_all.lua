
--region Unregister hooks
if SERVER then
	hook.Remove("Tick", "AG_ServerTick")
end
if CLIENT then
	hook.Remove("Tick", "AG_ClientTick")
	hook.Remove("Think", "AG_ClientThink")
    hook.Remove("CreateMove", "AG_CreateMove")
    hook.Remove("CalcView", "AG_CalcView")
	hook.Remove("PostDrawHUD", "AG_PostDrawHUD")
end
hook.Remove("StartCommand", "AG_StartCommand")
hook.Remove("EntityFireBullets", "AG_EntityFireBullets")
--endregion

--region Convars
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
	["aimbotgun_aimbot_speedmode"] = "0",
	["aimbotgun_aimbot_minsmooth"] = "1",
	["aimbotgun_aimbot_maxsmooth"] = "1",
	["aimbotgun_aimbot_minyawsmooth"] = "1",
	["aimbotgun_aimbot_maxyawsmooth"] = "1",
	["aimbotgun_aimbot_minpitchsmooth"] = "1",
	["aimbotgun_aimbot_maxpitchsmooth"] = "1",
	["aimbotgun_aimbot_easetime"] = "1",
	["aimbotgun_aimbot_silent"] = "0",
	["aimbotgun_aimbot_reflick"] = "0",
	["aimbotgun_aimbot_reflick_delay"] = "0.01",
	["aimbotgun_aimbot_fov_b"] = "2",
	["aimbotgun_aimbot_fov_k"] = "2",
	["aimbotgun_aimbot_wallcheck"] = "1",
	["aimbotgun_aimbot_bone"] = "2",
	["aimbotgun_aimbot_smooth"] = "0",
	["aimbotgun_aimbot_predictsize"] = "0.1",
	["aimbotgun_aimbot_locktarget"] = "1",
	["aimbotgun_triggerbot"] = "0",
	["aimbotgun_triggerbot_keycheck"] = "1",
	["aimbotgun_triggerbot_raycheck"] = "1",
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
	-- optimization
	["aimbotgun_optimization_searchifbindpressed"] = "1",
	-- debugging
	["aimbotgun_debug_targetpos"] = "0",
	["aimbotgun_debug_targetdata"] = "0",
	["aimbotgun_debug_triggerbot"] = "0"
}

CreateConVar("aimbotgun_enabled", "1", FCVAR_ARCHIVE)

for k, v in pairs(AimbotGun_ConVars) do
	CreateConVar(k, v, FCVAR_ARCHIVE)
end
--endregion

--region net I/O
local function bool2int(bl)
	return bl and 1 or 0
end

local PreviousBindPress = 0
local function SendState(bindpress, trigger)
	if PreviousBindPress == bindpress and not trigger then
		return
	end
	local flags = bit.bor(bit.lshift(bool2int(bindpress), 1), bool2int(trigger))
	net.Start("AimbotGunAutoTrigger")
	net.WriteInt(flags, 4)
	net.SendToServer()
	PreviousBindPress = bindpress
end
--endregion

--region Utilities
local RandomSphere = function(radius)
	if (radius == 0) then return Vector(0, 0, 0) end
	local x = 2 * radius * math.asin(2 * math.asin(math.Rand(-1.0, 1.0)) / math.pi) / math.pi
	local y = 2 * math.sqrt(radius^2 - x^2) * math.asin(math.Rand(-1.0, 1.0)) / math.pi
	local z = math.sqrt(radius^2 - x^2 - y^2) * math.Rand(-1.0, 1.0)
	return Vector(x, y, z)
end

local IsTargetValid = function(target)
	return target ~= nil and target.Entity ~= 0 and target.Entity:IsValid()
end

local GetAngleDelta = function(a, b)
	return ((((a - b) % 360) + 540) % 360) - 180
end

local function ShouldClientAim()
	--1 = Keybind and Bullet
	--2 = Keybind
	return GetConVar("aimbotgun_aimbot_mode"):GetInt() >= 1
end

local function ShouldServerAim()
	--0 = Bullet
	--1 = Keybind and Bullet
	return GetConVar("aimbotgun_aimbot_mode"):GetInt() <= 1
end
--endregion

local function EaseSmoothing(delta, smooth, time, func)
	return delta * func(math.Clamp(time / GetConVar("aimbotgun_aimbot_easetime"):GetFloat(), 0, 1)) / smooth
end

--region Smoothing
local Smoothing = {
	[0] = function(delta, smooth, time) --Clamp
		return math.min(delta, 180 / smooth * (180/20)) --max(smooth) = 20
	end,
	[1] = function(delta, smooth, time) --Divide
		return delta / smooth
	end,
	[2] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.InOutBack)
	end,
	[3] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.InOutCirc)
	end,
	[4] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.InOutCubic)
	end,
	[5] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.InOutElastic)
	end,
	[6] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.InOutExpo)
	end,
	[7] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.InOutQuad)
	end,
	[8] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.InOutQuart)
	end,
	[9] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.InOutQuint)
	end,
	[10] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.InOutSine) 
	end,
	[11] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.OutBack)
	end,
	[12] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.OutCirc)
	end,
	[13] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.OutCubic)
	end,
	[14] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.OutElastic)
	end,
	[15] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.OutExpo)
	end,
	[16] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.OutQuad)
	end,
	[17] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.OutQuart)
	end,
	[18] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.OutQuint)
	end,
	[19] = function(delta, smooth, time)
		return EaseSmoothing(delta, smooth, time, math.ease.OutSine)
	end
}

local GetDelta = function(target, shootPos, shootAngle)
	local predict = GetConVar("aimbotgun_aimbot_predictsize"):GetFloat()
	local targetPos = target.Bone.Pos + target.Entity:GetVelocity() * predict
	local targetAngle = (targetPos - shootPos):Angle()
	local yawDelta = GetAngleDelta(targetAngle.y, shootAngle.y)
	local pitchDelta = GetAngleDelta(targetAngle.p, shootAngle.p)

	local smoothingType = GetConVar("aimbotgun_aimbot_smooth"):GetInt()
	if smoothingType == 0 then --No smoothing
		return { Yaw = yawDelta, Pitch = pitchDelta }
	end

	local smoothing = Smoothing[smoothingType - 1]
	local speedMode = GetConVar("aimbotgun_aimbot_speedmode"):GetBool()
	local yawMin = GetConVar(speedMode and "aimbotgun_aimbot_minsmooth" or "aimbotgun_aimbot_minyawsmooth"):GetFloat()
	local yawMax = GetConVar(speedMode and "aimbotgun_aimbot_maxsmooth" or "aimbotgun_aimbot_maxyawsmooth"):GetFloat()
	local pitchMin = GetConVar(speedMode and "aimbotgun_aimbot_minsmooth" or "aimbotgun_aimbot_minpitchsmooth"):GetFloat()
	local pitchMax = GetConVar(speedMode and "aimbotgun_aimbot_maxsmooth" or "aimbotgun_aimbot_maxpitchsmooth"):GetFloat()
	local time = SysTime() - LocalPlayer().EaseTime
	local yawlimit = math.Clamp(smoothing(yawDelta, math.random(yawMin, yawMax), time), -180, 180)
	local pitchlimit = math.Clamp(smoothing(pitchDelta, math.random(pitchMin, pitchMax), time), -180, 180)

	yawDelta = math.Clamp(yawDelta, -yawlimit, yawlimit)
	pitchDelta = math.Clamp(pitchDelta, -pitchlimit, pitchlimit)

	return { Yaw = yawDelta, Pitch = pitchDelta }
end
--endregion

local function FireAimbotBullets(self, bulletdata)
	if bulletdata.Aimbotted then
		return false
	end
	if self:IsPlayer() and GetConVar("aimbotgun_aimbot_mode"):GetInt() <= 1 and GetConVar("aimbotgun_global"):GetBool() then
		if not self.AimTarget then
			self.AimTarget = nil
		end
		local owner = bulletdata.Attacker
		if owner == nil then
			owner = self
		end
		local silent = GetConVar("aimbotgun_aimbot_silent"):GetBool() or GetConVar("aimbotgun_aimbot_mode"):GetInt() == 1
		local prevAngle = owner:LocalEyeAngles()

		local target = nil
		if GetConVar("aimbotgun_triggerbot"):GetBool() then
			target = owner.ServerAimbotTarget
		end

		if not IsTargetValid(target) then
			target = AimbotGun.GetClosestBone(owner, nil, GetConVar("aimbotgun_aimbot_fov_b"):GetFloat())
			owner.ServerAimbotTarget = target
		end

		if IsTargetValid(target) then
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

--region Triggerbot
local LastTrigger = 0

local function OnStartCommand(self, move)
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
--endregion

--region Target box render
local function OnPostDrawHUD()
	if not GetConVar("aimbotgun_debug_targetdata"):GetBool() then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local target = ply.ClientAimbotTarget
	if not IsTargetValid(target) then return end

	local x, y = ScrW(), ScrH()
	local w, h = x / 2, y / 2

	surface.SetFont("Default")

	local text = AimbotGun.GetTargetName(target) .. " lock=" .. tostring(ply.FirstTarget) .. " changed=" .. tostring(ply.TargetChanged)
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
--endregion

--Update server-side aimbot target and triggerbot enabled state
local function OnServerTick()
	if not ShouldServerAim() then return end
	if not GetConVar("aimbotgun_triggerbot"):GetBool() then return end
	local keycheck = GetConVar("aimbotgun_triggerbot_keycheck"):GetBool()
	--If aimbot mode is 'Bullet and Keybind' and triggerbot ray-check is enabled, the client will press the trigger instead of the server.
	local clientWillTrigger = GetConVar("aimbotgun_aimbot_mode"):GetInt() == 1 and GetConVar("aimbotgun_triggerbot_raycheck"):GetBool()

	for _, ent in pairs(ents.GetAll()) do
		(function()
			if (not ent) or (not ent:IsValid()) or (not ent:IsPlayer()) then return end --target validity
			if (not IsValid(ent:GetActiveWeapon())) or (ent:GetActiveWeapon():Clip1() == 0) or (ent:GetActiveWeapon():GetNextPrimaryFire() < CurTime()) then return end --weapon validity
			
			--update target and re-check validity
			local target = AimbotGun.GetClosestBone(ent, nil, GetConVar("aimbotgun_aimbot_fov_b"):GetFloat())
			if not IsTargetValid(target) then return end

			if not clientWillTrigger and (not keycheck or ent.AimKeyPress) then
				ent.Triggerbot = true
			end
			ent.ServerAimbotTarget = target
		end)()
	end
end

local function OnClientTick()
	if not ShouldClientAim() then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	if GetConVar("aimbotgun_optimization_searchifbindpressed"):GetBool() and not (input.IsButtonDown(GetConVar("aimbotgun_global_bind_aimassist"):GetInt()) or input.IsButtonDown(GetConVar("aimbotgun_global_bind_flick"):GetInt())) then
		ply.ClientAimbotTarget = nil
		ply.FirstTarget = nil
		return
	end

	local priorityEntityID
	if GetConVar("aimbotgun_aimbot_locktarget"):GetBool() and IsValid(ply.FirstTarget) then
		priorityEntityID = ply.FirstTarget:EntIndex()
	else
		priorityEntityID = nil
	end
	
	local target = AimbotGun.GetClosestBone(ply, priorityEntityID, GetConVar("aimbotgun_aimbot_fov_k"):GetFloat())
	if IsTargetValid(target) and (ply.ClientAimbotTarget == nil or not target.Entity.Targetted) then
		ply.EaseTime = SysTime()
		--chat.AddText("EaseTime update: "..(ply.EaseTime))
	end
	ply.ClientAimbotTarget = target
	ply.TargetChanged = ply.FirstTarget ~= nil and target.Entity ~= 0 and ply.FirstTarget:EntIndex() ~= target.Entity:EntIndex()
	if ply.EaseTime == nil then
		ply.EaseTime = 0
	end
end

--TODO: Merge with OnClientTick
local OnClientThink = function()
	local ply = LocalPlayer()

	if not IsValid(ply) then
		SendState(false, false)
		return
	end

	local raycheck = false
	local bindchecker = GetConVar("aimbotgun_triggerbot_keycheck"):GetBool()
	local bindcheck = input.IsButtonDown(GetConVar("aimbotgun_global_bind_aimassist"):GetInt())
	if not bindchecker then
		local trace = ply:GetEyeTrace()
		raycheck = IsTargetValid(ply.ClientAimbotTarget) and trace.HitNonWorld and AimbotGun.IsTargetValid(ply, trace.Entity)
	end
	if bindcheck and IsTargetValid(ply.ClientAimbotTarget) then
		if not GetConVar("aimbotgun_aimbot_locktarget"):GetBool() or not ply.TargetChanged then
			local smoothingType = GetConVar("aimbotgun_aimbot_smooth"):GetInt()
			local ang
			ply.ClientAimbotTarget.Entity.Targetted = true
			if smoothingType == 0 then
				local pos = ply.ClientAimbotTarget.Bone.Pos
				ang = (pos - ply:GetShootPos()):Angle()
			else
				local pangle = ply:EyeAngles()
				local deltas = GetDelta(ply.ClientAimbotTarget, ply:GetShootPos(), pangle)
				local yawDelta = deltas.Yaw
				local pitchDelta = deltas.Pitch
				ang = Angle(pangle.p + pitchDelta, pangle.y + yawDelta, pangle.r)
			end
			ply:SetEyeAngles(ang)
			if GetConVar("aimbotgun_triggerbot"):GetBool() then
				if GetConVar("aimbotgun_triggerbot_raycheck"):GetBool() then
					if bindchecker then
						local trace = ply:GetEyeTrace()
						raycheck = trace.HitNonWorld and AimbotGun.IsTargetValid(ply, trace.Entity)
					end
				else
					raycheck = true
				end
			end
		end

		if ply.FirstTarget == nil then
			ply.FirstTarget = ply.ClientAimbotTarget.Entity
		end
	else
		ply.FirstTarget = nil
		if IsTargetValid(ply.ClientAimbotTarget) then
			ply.ClientAimbotTarget.Entity.Targetted = false
		end
	end
	SendState(bindcheck, raycheck)
end

local function OnCreateMove(user)
	local ply = LocalPlayer()
	local bindcheck = input.IsButtonDown(GetConVar("aimbotgun_global_bind_aimassist"):GetInt())
	if GetConVar("aimbotgun_aimbot_smooth"):GetInt() == 0 and input.IsButtonDown(GetConVar("aimbotgun_global_bind_aimassist"):GetInt()) and IsTargetValid(ply.ClientAimbotTarget) and (not GetConVar("aimbotgun_aimbot_locktarget"):GetBool() or not ply.TargetChanged) then
		user:SetViewAngles((ply.ClientAimbotTarget.Bone.Pos - ply:GetShootPos()):Angle())
	end
end

local function OnCalcView(ply, origin, angles, fov, znear, zfar)
	if GetConVar("aimbotgun_aimbot_smooth"):GetInt() == 0 and input.IsButtonDown(GetConVar("aimbotgun_global_bind_aimassist"):GetInt()) and IsTargetValid(ply.ClientAimbotTarget) and (not GetConVar("aimbotgun_aimbot_locktarget"):GetBool() or not ply.TargetChanged) then
		return {
			origin = origin,
			angles = (ply.ClientAimbotTarget.Bone.Pos - ply:GetShootPos()):Angle(),
			fov = fov,
			znear = znear,
			zfar = zfar
		}
	end
end

local function OnEntityFireBullets(ent, data, ...)
	if FireAimbotBullets(ent, data) then
		return true
	elseif IsValid(ent) and ent:IsPlayer() and GetConVar("aimbotgun_global_nospread"):GetBool() then
		data.Spread = Vector()
		data.Dir = ent:GetAimVector()
		return true
	end
end

--region net I/O
local DebugTargetDataReceive = function(len, ply)
	local aimtarget = net.ReadVector()
	local targetstring = net.ReadString()
	chat.AddText("[AimbotGun] ", targetstring)
	local plr = LocalPlayer()
	plr.ClientAimbotTargetString = targetstring
	plr.ClientAimbotTargetPos = aimtarget
end

local AutoTrigger = function(len, ply)
	local flags = net.ReadInt(4)
	ply.Triggerbot = bit.band(flags, 1) ~= 0
	ply.AimKeyPress = bit.band(flags, 2) ~= 0
end

if SERVER then
	util.AddNetworkString("AimbotGunDebugTargetData")
	util.AddNetworkString("AimbotGunAutoTrigger")
	net.Receive("AimbotGunAutoTrigger", AutoTrigger)
elseif CLIENT then
	net.Receive("AimbotGunDebugTargetData", DebugTargetDataReceive)
end
--endregion

--region Hook registerers
if SERVER then
	hook.Add("Tick", "AG_ServerTick", OnServerTick)
end
if CLIENT then
	hook.Add("Tick", "AG_ClientTick", OnClientTick)
	hook.Add("Think", "AG_ClientThink", OnClientThink)
    hook.Add("CreateMove", "AG_CreateMove", OnCreateMove)
    hook.Add("CalcView", "AG_CalcView", OnCalcView)
	hook.Add("PostDrawHUD", "AG_PostDrawHUD", OnPostDrawHUD)
end
hook.Add("StartCommand", "AG_StartCommand", OnStartCommand)
hook.Add("EntityFireBullets", "AG_EntityFireBullets", OnEntityFireBullets)
--endregion

print("AimbotGun global autorun initialized")

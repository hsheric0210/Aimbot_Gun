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
SWEP.Aimbot.DeathSequences = {
	["models/barnacle.mdl"] = { 4, 15 },
	["models/antlion_guard.mdl"] = { 44 },
	["models/hunter.mdl"] = { 124, 125, 126, 127, 128 },
	["models/headcrabclassic.mdl"] = { 13, 14, 15, 16, 17, 18, 19 },
	["models/headcrab.mdl"] = { 10, 11, 12, 13, 14 },
	["models/headcrabblack.mdl"] = { 16, 17, 18, 20, 22 },
	["models/manhack.mdl"] = { 4, 12, 13 }
}
SWEP.Aimbot.DefaultAttachmentNames = { "head", "eyes", "eye" }
SWEP.Aimbot.BoneNames = {
	["models/crow.mdl"] = "Crow.Head",
	["models/pigeon.mdl"] = "Crow.Head",
	["models/seagull.mdl"] = "Seagull.Head",
	["models/headcrabclassic.mdl"] = "HeadcrabClassic.SpineControl",
	["models/antlion.mdl"] = "Antlion.Back_Bone",
	["models/barnacle.mdl"] = "Barnacle.body"
}
SWEP.Aimbot.BoneBlacklists = {
	["models/barnacle.mdl"] = {
		"Barnacle.tongue1",
		"Barnacle.tongue2",
		"Barnacle.tongue3",
		"Barnacle.tongue4",
		"Barnacle.tongue5",
		"Barnacle.tongue6",
		"Barnacle.tongue7",
		"Barnacle.tongue8"
	}
}

function SWEP:SetupAimbotDataForEntity(ent)
	local attachmentName
	local boneName = self.Aimbot.BoneNames[string.lower(ent:GetModel() or "")] or nil
	local excludedBoneNames = self.Aimbot.BoneBlacklists[string.lower(ent:GetModel() or "")] or {}
	local boneAngularOffset = 3.5

	local model = ent:GetModel() or ""
	if model:find("manhack") then
		attachmentName = "light"
	elseif model:find("stalker") then
		boneName = "ValveBiped.Bip01_Head1"
	elseif model:find("poison") then
		boneName = "ValveBiped.Bip01_Spine4"
	elseif not model:find("scanner") then
		for _, name in pairs(self.Aimbot.DefaultAttachmentNames) do
			if ent:LookupAttachment(name) > 0 then
				attachmentName = name
				break
			end
		end
	end

	ent.AimbotData = {}
	ent.AimbotData.IsBoneAttachment = attachmentName ~= nil
	ent.AimbotData.BoneName = ent.AimbotData.IsBoneAttachment and attachmentName or boneName
	ent.AimbotData.ExcludedBoneNames = excludedBoneNames
	ent.AimbotData.BoneAngularOffset = boneAngularOffset
end

function SWEP:IsVisible(ent, pos)
	local trace = {}
	trace.start = self:GetOwner():GetShootPos()
	trace.endpos = pos
	trace.filter = { self:GetOwner(), ent }
	trace.mask = MASK_SHOT
	local tr = util.TraceLine(trace)
	return tr.Fraction > 0.99
end

function SWEP:FindAvailableBones(ent, boneName, isBoneAttachment, boneAngularOffset, excludedBoneNames)
	local available = {}
	local alreadySeenBones = { 0 }

	local headPriority = (GetConVar("aimbotgun_bone"):GetInt() > 0) and 2 or 1

	if boneName ~= nil then
		if isBoneAttachment then
			-- Search head by attachment names
			local attachment = ent:GetAttachment(ent:LookupAttachment(boneName))
			if attachment ~= nil then
				local pos = attachment.Pos
				if self:IsVisible(ent, pos) then
					table.insert(available, { Name = "Attachment." .. boneName, Priority = headPriority, Pos = pos })
				end
			end
		else
			--Search head by bone name
			local boneIndex = ent:LookupBone(boneName)
			if boneIndex and not table.HasValue(alreadySeenBones, boneIndex) then
				local boneMatrix = ent:GetBoneMatrix(boneIndex)
				if boneMatrix ~= nil then
					local pos = boneMatrix:GetTranslation() + boneMatrix:GetForward() * boneAngularOffset
					if self:IsVisible(ent, pos) then
						table.insert(available, { Name = boneName, Priority = headPriority, Pos = pos })
						table.insert(alreadySeenBones, boneIndex)
					end
				end
			end
		end
	end

	local pos = ent:GetBonePosition(0)
	if pos and self:IsVisible(ent, pos) then
		table.insert(available, { Name = "Root_Bone", Priority = 1, Pos = pos })
	end

	if GetConVar("aimbotgun_bone"):GetInt() < 2 then
		-- Search for each bone
		for boneIndex = 1, ent:GetBoneCount() - 1 do
			if not table.HasValue(alreadySeenBones, boneIndex) and not table.HasValue(excludedBoneNames, ent:GetBoneName(boneIndex)) then
				local boneMatrix = ent:GetBoneMatrix(boneIndex)
				if boneMatrix then
					pos = boneMatrix:GetTranslation()
					if self:IsVisible(ent, pos) then
						table.insert(available, { Name = ent:GetBoneName(boneIndex), Priority = 0, Pos = pos })
					end
				end
			end
		end
	end

	return available
end

function SWEP:GetClosestBone()
	local pos = self:GetOwner():GetShootPos()
	local ang = self:GetOwner():GetAimVector()

	local fovLimit = GetConVar("aimbotgun_aimbot_fov"):GetFloat()

	local closest = { Entity = 0, FOV = 0, Bone = 0 }
	local closestEachEntity = {}

	for _, target in pairs(self:GetValidTargets()) do
		local entityid = target:EntIndex()
		closestEachEntity[entityid] = { FOV = 0, Bone = 0 }
		for _, bone in pairs(self:FindAvailableBones(target, target.AimbotData.BoneName, target.AimbotData.IsBoneAttachment, target.AimbotData.BoneAngularOffset, target.AimbotData.ExcludedBoneNames)) do
			local empty = table.IsEmpty(closestEachEntity)
			if empty or closestEachEntity[entityid].Bone == 0 or bone.Priority >= closestEachEntity[entityid].Bone.Priority then
				local delta = bone.Pos - pos
				delta:Normalize()
				delta = delta - ang
				delta = delta:Length()
				delta = math.abs(delta)

				if (delta <= fovLimit) and (empty or (closestEachEntity[entityid].Bone == 0) or (delta < closestEachEntity[entityid].FOV)) then
					closestEachEntity[entityid] = { FOV = delta, Bone = bone }
				end
			end
		end

		for _, bestBone in pairs(closestEachEntity) do
			if bestBone.Bone ~= 0 then
				local delta = bestBone.FOV
				if ((closest.Entity == 0) or (delta < closest.FOV)) then
					closest = { Entity = target, FOV = delta, Bone = bestBone.Bone }
				end
			end
		end
	end

	return closest
end

function SWEP:IsHostile(ent)
	local class = ent:GetClass()

	local classPatternAvoid = { "ship", "maker", "item", "rollermine" }
	for _, avoid in pairs(classPatternAvoid) do
		if class:find(avoid) then
			return false
		end
	end

	local classPattern = {}

	if GetConVar("aimbotgun_target_bird"):GetInt() ~= 0 then
		table.Add(classPattern, { "crow", "pigeon", "seagull" })
	end

	if GetConVar("aimbotgun_target_combine"):GetInt() ~= 0 then
		table.Add(classPattern, { "combine", "police", "hunter", "stalker" })
	end

	if GetConVar("aimbotgun_target_hunter"):GetInt() ~= 0 then
		table.insert(classPattern, "hunter")
	end

	if GetConVar("aimbotgun_target_manhack"):GetInt() ~= 0 then
		table.insert(classPattern, "manhack")
	end

	if GetConVar("aimbotgun_target_scanner"):GetInt() ~= 0 then
		table.insert(classPattern, "scanner")
	end

	if GetConVar("aimbotgun_target_antlion"):GetInt() ~= 0 then
		table.insert(classPattern, "antlion")
	end

	if GetConVar("aimbotgun_target_headcrab"):GetInt() ~= 0 then
		table.insert(classPattern, "headcrab")
	end

	if GetConVar("aimbotgun_target_zombie"):GetInt() ~= 0 then
		table.Add(classPattern, { "zombie", "zombine" })
	end

	if GetConVar("aimbotgun_target_barnacle"):GetInt() ~= 0 then
		table.insert(classPattern, "barnacle")
	end

	if class:find("turret") then
		return false -- Don't target turrets - they're buggy
	end

	for _, pattern in pairs(classPattern) do
		if class:find(pattern) then
			return true
		end
	end
	return GetConVar("aimbotgun_friendly_fire"):GetInt() ~= 0
end

function SWEP:IsTargetValid(entity)
	if not IsValid(entity) then
		return false
	end

	if entity:IsPlayer() then
		if GetConVar("aimbotgun_target_player"):GetInt() == 0 then
			return false
		end

		if entity:Health() < 1 then
			return false
		end

		if entity == self:GetOwner() then
			return false
		end

		return true
	end

	if entity:IsNPC() then
		if entity:GetMoveType() == 0 then
			return false
		end

		if table.HasValue(self.Aimbot.DeathSequences[string.lower(entity:GetModel() or "")] or {}, entity:GetSequence()) then
			return false
		end

		if not self:IsHostile(entity) then
			return false
		end

		return true
	end

	return false
end

function SWEP:GetValidTargets()
	local targets = {}
	for _, ent in pairs(ents.GetAll()) do
		if self:IsTargetValid(ent) then
			self:SetupAimbotDataForEntity(ent)
			table.insert(targets, ent)
		end
	end
	return targets
end

function SWEP:UpdateTarget()
	local target = self:GetClosestBone()
	local available = target.Entity ~= 0
	self.Aimbot.Target = available and target or nil

	if available and self:CanPrimaryAttack() and GetConVar("aimbotgun_triggerbot"):GetInt() ~= 0 and CurTime() - self:GetNWInt("LastShoot", 0) >= math.max(self.Primary.Delay, 0.15) then
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

	self:SetNWInt("LastShoot", CurTime())

	if targetAvailable and not silent and GetConVar("aimbotgun_aimbot_reflick"):GetInt() ~= 0 then
		timer.Simple(GetConVar("aimbotgun_aimbot_reflick_delay"):GetFloat(), function()
			owner:SetEyeAngles(prevAngle)
		end)
	end
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

function SWEP:GetTargetName(target)
	local targetEnt = target.Entity

	if targetEnt:IsPlayer() then
		return targetEnt:Name()
	end

	if targetEnt:IsNPC() then
		local seqID = targetEnt:GetSequence()
		local seqName = targetEnt:GetSequenceName(seqID)
		return targetEnt:GetClass() .. " (" .. targetEnt:GetModel() .. ")" .. ", sequence: #" .. seqID .. " - " .. seqName
	end

	return ""
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

		local text = "Target locked... (" .. self:GetTargetName(target) .. ")"
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

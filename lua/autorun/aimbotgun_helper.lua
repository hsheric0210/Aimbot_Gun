if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("aimbotgun_all.lua")
	AddCSLuaFile("autorun/client/aimbotgun_menu.lua")
end

if not istable(AimbotGun) then
	AimbotGun = {}
	AimbotGun.DeathSequences = {
		["models/barnacle.mdl"] = { 4, 15 },
		["models/antlion_guard.mdl"] = { 44 },
		["models/hunter.mdl"] = { 124, 125, 126, 127, 128 },
		["models/headcrabclassic.mdl"] = { 13, 14, 15, 16, 17, 18, 19 },
		["models/headcrab.mdl"] = { 10, 11, 12, 13, 14 },
		["models/headcrabblack.mdl"] = { 16, 17, 18, 20, 22 },
		["models/manhack.mdl"] = { 4, 12, 13 }
	}
	AimbotGun.DefaultAttachmentNames = { "head", "eyes", "eye" }
	AimbotGun.BoneNames = {
		["models/crow.mdl"] = "Crow.Head",
		["models/pigeon.mdl"] = "Crow.Head",
		["models/seagull.mdl"] = "Seagull.Head",
		["models/headcrabclassic.mdl"] = "HeadcrabClassic.SpineControl",
		["models/antlion.mdl"] = "Antlion.Back_Bone",
		["models/barnacle.mdl"] = "Barnacle.body"
	}
	AimbotGun.BoneBlacklists = {
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
end

function AimbotGun.SetupAimbotDataForEntity(ent)
	if istable(ent.AimbotData) then
		return
	end

	local attachmentName
	local boneName = AimbotGun.BoneNames[string.lower(ent:GetModel() or "")] or nil
	local excludedBoneNames = AimbotGun.BoneBlacklists[string.lower(ent:GetModel() or "")] or {}
	local boneAngularOffset = 3.5

	local model = ent:GetModel() or ""
	if model:find("manhack") then
		attachmentName = "light"
	elseif model:find("stalker") then
		boneName = "ValveBiped.Bip01_Head1"
	elseif model:find("poison") then
		boneName = "ValveBiped.Bip01_Spine4"
	elseif not model:find("scanner") then
		for _, name in pairs(AimbotGun.DefaultAttachmentNames) do
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

function AimbotGun.IsVisible(ply, ent, pos)
	local trace = {}
	trace.start = ply:GetShootPos()
	trace.endpos = pos
	trace.filter = { ply, ent }
	trace.mask = MASK_SHOT
	local tr = util.TraceLine(trace)
	return tr.Fraction > 0.99
end

function AimbotGun.FindAvailableBones(ply, ent, boneName, isBoneAttachment, boneAngularOffset, excludedBoneNames)
	local available = {}
	local alreadySeenBones = { 0 }

	local headPriority = (GetConVar("aimbotgun_bone"):GetInt() > 0) and 2 or 1
	local wallCheck = GetConVar("aimbotgun_wallcheck"):GetInt() > 0

	if boneName ~= nil then
		if isBoneAttachment then
			-- Search head by attachment names
			local attachment = ent:GetAttachment(ent:LookupAttachment(boneName))
			if attachment ~= nil then
				local pos = attachment.Pos
				if not wallCheck or AimbotGun.IsVisible(ply, ent, pos) then
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
					if not wallCheck or AimbotGun.IsVisible(ply, ent, pos) then
						table.insert(available, { Name = boneName, Priority = headPriority, Pos = pos })
						table.insert(alreadySeenBones, boneIndex)
					end
				end
			end
		end
	end

	local pos = ent:GetBonePosition(0)
	if pos and (not wallCheck or AimbotGun.IsVisible(ply, ent, pos)) then
		table.insert(available, { Name = "Root_Bone", Priority = 1, Pos = pos })
	end

	if GetConVar("aimbotgun_bone"):GetInt() < 2 then
		-- Search for each bone
		for boneIndex = 1, ent:GetBoneCount() - 1 do
			if not table.HasValue(alreadySeenBones, boneIndex) and not table.HasValue(excludedBoneNames, ent:GetBoneName(boneIndex)) then
				local boneMatrix = ent:GetBoneMatrix(boneIndex)
				if boneMatrix then
					pos = boneMatrix:GetTranslation()
					if not wallCheck or AimbotGun.IsVisible(ply, ent, pos) then
						table.insert(available, { Name = ent:GetBoneName(boneIndex), Priority = 0, Pos = pos })
					end
				end
			end
		end
	end

	return available
end

function AimbotGun.GetClosestBone(ply)
	local pos = ply:GetShootPos()
	local ang = ply:GetAimVector()

	local fovLimit = GetConVar("aimbotgun_aimbot_fov"):GetFloat()

	local closest = { Entity = 0, FOV = 0, Bone = 0 }
	local closestEachEntity = {}

	for _, target in pairs(AimbotGun.GetValidTargets(ply)) do
		local entityid = target:EntIndex()
		closestEachEntity[entityid] = { FOV = 0, Bone = 0 }
		for _, bone in pairs(AimbotGun.FindAvailableBones(ply, target, target.AimbotData.BoneName, target.AimbotData.IsBoneAttachment, target.AimbotData.BoneAngularOffset, target.AimbotData.ExcludedBoneNames)) do
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

function AimbotGun.IsHostile(ent)
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

function AimbotGun.IsTargetValid(ply, entity)
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

		if entity == ply then
			return false
		end

		return true
	end

	if entity:IsNPC() then
		if entity:GetMoveType() == 0 then
			return false
		end

		if table.HasValue(AimbotGun.DeathSequences[string.lower(entity:GetModel() or "")] or {}, entity:GetSequence()) then
			return false
		end

		if not AimbotGun.IsHostile(entity) then
			return false
		end

		return true
	end

	return false
end

function AimbotGun.GetValidTargets(ply)
	local targets = {}
	-- todo: max distance
	for _, ent in pairs(ents.GetAll()) do
		if AimbotGun.IsTargetValid(ply, ent) then
			AimbotGun.SetupAimbotDataForEntity(ent)
			table.insert(targets, ent)
		end
	end
	return targets
end


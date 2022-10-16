if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("aimbotgun_all.lua")
	AddCSLuaFile("autorun/client/aimbotgun_menu.lua")
end

if not istable(AimbotGun) then
	AimbotGun = {}
	AimbotGun.DeathSequences = {
		["models/barnacle.mdl"] = { [4] = true, [15] = true },
		["models/antlion_guard.mdl"] = { [44] = true },
		["models/hunter.mdl"] = { [124] = true, [125] = true, [126] = true, [127] = true, [128] = true },
		["models/headcrabclassic.mdl"] = { [13] = true, [14] = true, [15] = true, [16] = true, [17] = true, [18] = true, [19] = true },
		["models/headcrab.mdl"] = { [10] = true, [11] = true, [12] = true, [13] = true, [14] = true },
		["models/headcrabblack.mdl"] = { [16] = true, [17] = true, [18] = true, [20] = true, [22] = true },
		["models/manhack.mdl"] = { [4] = true, [12] = true, [13] = true }
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
			["Barnacle.tongue1"] = true,
			["Barnacle.tongue2"] = true,
			["Barnacle.tongue3"] = true,
			["Barnacle.tongue4"] = true,
			["Barnacle.tongue5"] = true,
			["Barnacle.tongue6"] = true,
			["Barnacle.tongue7"] = true,
			["Barnacle.tongue8"] = true
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
	if model:find("stalker") then
		boneName = "ValveBiped.Bip01_Head1"
	elseif model:find("combine") and model:find("soldier") then
		boneName = "ValveBiped.Bip01_Head1"
		boneAngularOffset = 4.5
	elseif model:find("poison") then
		boneName = "ValveBiped.Bip01_Spine4"
	elseif not model:find("scanner") and not model:find("manhack") then
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
	local alreadySeenBones = { [0] = true }

	local headPriority = (GetConVar("aimbotgun_aimbot_bone"):GetInt() > 0) and 2 or 1
	local wallCheck = GetConVar("aimbotgun_aimbot_wallcheck"):GetInt() > 0

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
			if boneIndex and not alreadySeenBones[boneIndex] then
				local boneMatrix = ent:GetBoneMatrix(boneIndex)
				if boneMatrix ~= nil then
					local pos = boneMatrix:GetTranslation() + boneMatrix:GetForward() * boneAngularOffset
					if not wallCheck or AimbotGun.IsVisible(ply, ent, pos) then
						table.insert(available, { Name = boneName, Priority = headPriority, Pos = pos })
						table.Add(alreadySeenBones, { [boneIndex] = true })
					end
				end
			end
		end
	end

	local pos = ent:GetBonePosition(0)
	if pos and (not wallCheck or AimbotGun.IsVisible(ply, ent, pos)) then
		table.insert(available, { Name = "Root_Bone", Priority = 1, Pos = pos })
	end

	if GetConVar("aimbotgun_aimbot_bone"):GetInt() < 2 then
		-- Search for each bone
		for boneIndex = 1, ent:GetBoneCount() - 1 do
			if not alreadySeenBones[boneIndex] then
				local boneName = ent:GetBoneName(boneIndex)
				if not excludedBoneNames[boneName] then
					local boneMatrix = ent:GetBoneMatrix(boneIndex)
					if boneMatrix then
						pos = boneMatrix:GetTranslation()
						if not wallCheck or AimbotGun.IsVisible(ply, ent, pos) then
							table.insert(available, { Name = boneName, Priority = 0, Pos = pos })
						end
					end
				end
			end
		end
	end

	return available
end

function AimbotGun.GetClosestBone(ply, priorityEntityID)
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

		for eid, bestBone in pairs(closestEachEntity) do
			if bestBone.Bone ~= 0 then
				local delta = bestBone.FOV
				if eid == priorityEntityID then
					delta = delta - 100
				end
				if (closest.Entity == 0) or (delta < closest.FOV) then
					closest = { Entity = target, FOV = delta, Bone = bestBone.Bone }
				end
			end
		end
	end

	return closest
end

function AimbotGun.IsHostile(ent)
	local class = ent:GetClass()

	local classPatternAvoid = { "ship", "maker", "item", "rollermine", "turret", "monster" }
	for _, avoid in pairs(classPatternAvoid) do
		if class:find(avoid) then
			return false
		end
	end

	if GetConVar("aimbotgun_target_all"):GetInt() ~= 0 then
		return true
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

	for _, pattern in pairs(classPattern) do
		if class:find(pattern) then
			return true
		end
	end

	return false
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
		if entity:GetMoveType() == MOVETYPE_NONE then
			return false
		end

		if (AimbotGun.DeathSequences[string.lower(entity:GetModel() or "")] or {})[entity:GetSequence()] then
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

function AimbotGun.GetTargetName(target)
	local targetEnt = target.Entity
	local boneName = target.Bone.Name

	if not IsValid(targetEnt) then
		return "Invalid part=" .. boneName
	end

	local name = "[" .. targetEnt:EntIndex() .. "]" .. targetEnt:GetClass()

	if targetEnt:IsPlayer() then
		name = targetEnt:Name()
	end

	local seqID = targetEnt:GetSequence() or -1
	local seqName = targetEnt:GetSequenceName(seqID) or "Unknown"
	return name .. " model=" .. targetEnt:GetModel() .. ", part=" .. boneName .. ", sequence=[" .. seqID .. "]" .. seqName
end

function AimbotGun.ProjectPosition2D(pos)
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
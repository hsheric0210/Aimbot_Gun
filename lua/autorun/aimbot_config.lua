if CLIENT then
	-- Global settings
	if not ConVarExists("aimbotgun_aimbot_silent") then
		CreateClientConVar("aimbotgun_aimbot_silent", 0, true, false, "Enable silent aimbot in Aimbot Gun")
	end

	-- Reflick
	if not ConVarExists("aimbotgun_aimbot_reflick") then
		CreateClientConVar("aimbotgun_aimbot_reflick", 0, true, false, "Enable aimbot re-flick(flick back to the original aim after shotting the target) in Aimbot Gun")
	end

	-- Reflick Delay
	if not ConVarExists("aimbotgun_aimbot_reflick_delay") then
		CreateClientConVar("aimbotgun_aimbot_reflick_delay", 0.01, true, false, "A few delay before re-flick in Aimbot Gun (in seconds)")
	end

	-- Triggerbot
	if not ConVarExists("aimbotgun_triggerbot") then
		CreateClientConVar("aimbotgun_triggerbot", 0, true, false, "Automatically shot the target immediately (if exists)")
	end

	-- FoV
	if not ConVarExists("aimbotgun_aimbot_fov") then
		CreateClientConVar("aimbotgun_aimbot_fov", 2, true, false, "FoV(Field-of-View) of aimbot in Aimbot Gun")
	end

	-- Wall check
	if not ConVarExists("aimbotgun_wallcheck") then
		CreateClientConVar("aimbotgun_wallcheck", 1, true, false, "Check if there's any wall between target and player")
	end

	-- Bone
	if not ConVarExists("aimbotgun_bone") then
		CreateClientConVar("aimbotgun_bone", 2, true, false, "Aimbot bone preference; 0 = Closest, 1 = Prefer Head, 2 = Only Head")
	end

	-- Aimbot targets
	if not ConVarExists("aimbotgun_target_player") then
		CreateClientConVar("aimbotgun_target_player", 1, true, false, "Attack players")
	end
	if not ConVarExists("aimbotgun_friendly_fire") then
		CreateClientConVar("aimbotgun_friendly_fire", 0, true, false, "Attack non-hostile NPCs")
	end

	if not ConVarExists("aimbotgun_target_bird") then
		CreateClientConVar("aimbotgun_target_bird", 1, true, false, "Attack crow, pigeon and seagull NPCs")
	end

	if not ConVarExists("aimbotgun_target_combine") then
		CreateClientConVar("aimbotgun_target_combine", 1, true, false, "Attack combine NPCs")
	end
	if not ConVarExists("aimbotgun_target_hunter") then
		CreateClientConVar("aimbotgun_target_hunter", 1, true, false, "Attack combine hunter NPCs")
	end
	if not ConVarExists("aimbotgun_target_manhack") then
		CreateClientConVar("aimbotgun_target_manhack", 1, true, false, "Attack manhack NPCs")
	end
	if not ConVarExists("aimbotgun_target_scanner") then
		CreateClientConVar("aimbotgun_target_scanner", 1, true, false, "Attack city scanner and claw scanner NPCs")
	end

	if not ConVarExists("aimbotgun_target_antlion") then
		CreateClientConVar("aimbotgun_target_antlion", 1, true, false, "Attack antlion NPCs")
	end
	if not ConVarExists("aimbotgun_target_headcrab") then
		CreateClientConVar("aimbotgun_target_headcrab", 1, true, false, "Attack headcrab NPCs")
	end
	if not ConVarExists("aimbotgun_target_zombie") then
		CreateClientConVar("aimbotgun_target_zombie", 1, true, false, "Attack zombie NPCs")
	end
	if not ConVarExists("aimbotgun_target_barnacle") then
		CreateClientConVar("aimbotgun_target_barnacle", 1, true, false, "Attack barnacle NPCs")
	end

	-- Crosshair spin speed
	if not ConVarExists("aimbotgun_visual_crosshair_spin_speed") then
		CreateClientConVar("aimbotgun_visual_crosshair_spin_speed", 1, true, false, "Crosshair spin speed")
	end

	-- Custom crosshair colors
	if not ConVarExists("aimbotgun_visual_crosshair_color_red") then
		CreateClientConVar("aimbotgun_visual_crosshair_color_red", 255, true, false, "Custom crosshair color red")
	end
	if not ConVarExists("aimbotgun_visual_crosshair_color_green") then
		CreateClientConVar("aimbotgun_visual_crosshair_color_green", 0, true, false, "Custom crosshair color green")
	end
	if not ConVarExists("aimbotgun_visual_crosshair_color_blue") then
		CreateClientConVar("aimbotgun_visual_crosshair_color_blue", 0, true, false, "Custom crosshair color blue")
	end
	if not ConVarExists("aimbotgun_visual_crosshair_color_alpha") then
		CreateClientConVar("aimbotgun_visual_crosshair_color_alpha", 150, true, false, "Custom crosshair color opacity(alpha)")
	end

	if not ConVarExists("aimbotgun_visual_crosshair_rainbow") then
		CreateClientConVar("aimbotgun_visual_crosshair_rainbow", 0, true, false, "Enable rainbow crosshair")
	end
	if not ConVarExists("aimbotgun_visual_crosshair_rainbow_speed") then
		CreateClientConVar("aimbotgun_visual_crosshair_rainbow_speed", 1, true, false, "Rainbow crosshair - rainbow speed")
	end

	-- Custom target mark colors
	if not ConVarExists("aimbotgun_visual_target_mark_color_red") then
		CreateClientConVar("aimbotgun_visual_target_mark_color_red", 0, true, false, "Custom target mark color red")
	end
	if not ConVarExists("aimbotgun_visual_target_mark_color_green") then
		CreateClientConVar("aimbotgun_visual_target_mark_color_green", 255, true, false, "Custom target mark color green")
	end
	if not ConVarExists("aimbotgun_visual_target_mark_color_blue") then
		CreateClientConVar("aimbotgun_visual_target_mark_color_blue", 0, true, false, "Custom target mark color blue")
	end
	if not ConVarExists("aimbotgun_visual_target_mark_color_alpha") then
		CreateClientConVar("aimbotgun_visual_target_mark_color_alpha", 200, true, false, "Custom target mark color opacity(alpha)")
	end

	if not ConVarExists("aimbotgun_visual_target_mark_rainbow") then
		CreateClientConVar("aimbotgun_visual_target_mark_rainbow", 0, true, false, "Enable rainbow target mark")
	end
	if not ConVarExists("aimbotgun_visual_target_mark_rainbow_speed") then
		CreateClientConVar("aimbotgun_visual_target_mark_rainbow_speed", 1, true, false, "Rainbow target mark - rainbow speed")
	end

	hook.Add("PopulateToolMenu", "AimbotGunSettings", function()
		spawnmenu.AddToolMenuOption("Options", "Aimbot Gun Settings", "AimbotGunSettings", "Client", "", "", function(panel)
			-- Setup the menu
			local AimbotGunSettings = {
				Options = {},
				CVars = {},
				Label = "#Presets",
				MenuButton = "1",
				Folder = "Aimbot Gun Settings"
			}

			-- Set the default values
			AimbotGunSettings.Options["#Default"] = {
				aimbotgun_aimbot_silent = "0",
				aimbotgun_aimbot_reflick = "0",
				aimbotgun_aimbot_reflick_delay = "0.025",
				aimbotgun_triggerbot = "0",
				aimbotgun_aimbot_fov = "20",
				aimbotgun_only_hostile_npcs = "0"
			}
			panel:AddControl("ComboBox", AimbotGunSettings)

			-- Show the author
			panel:AddControl("Label", { Text = "By buu342(RagdollBlood GUI), eric0210(Transcoder to support Aimbot Gun)" })
			panel:AddControl("Label", { Text = "" })

			panel:AddControl("Header", { Description = "Aimbot Preferences" })

			-- Silent aim
			panel:AddControl("CheckBox", {
				Label = "Enable silent aim",
				Command = "aimbotgun_aimbot_silent",
			})
			panel:AddControl("Label", { Text = "" })

			-- Reflick
			panel:AddControl("CheckBox", {
				Label = "Enable re-flick",
				Command = "aimbotgun_aimbot_reflick",
			})

			-- Reflick delay
			panel:AddControl("Slider", {
				Label = "Delay before re-flick",
				Command = "aimbotgun_aimbot_reflick_delay",
				Type = "Float",
				Min = "0",
				Max = "0.2",
			})
			panel:AddControl("Label", { Text = "" })

			-- Triggerbot
			panel:AddControl("CheckBox", {
				Label = "Enable trigger-bot",
				Command = "aimbotgun_triggerbot",
			})
			panel:AddControl("Label", { Text = "" })

			-- FoV
			panel:AddControl("Slider", {
				Label = "FoV",
				Command = "aimbotgun_aimbot_fov",
				Type = "Float",
				Min = "0.1",
				Max = "2",
			})
			-- Wall check
			panel:AddControl("CheckBox", {
				Label = "Enable wall check",
				Command = "aimbotgun_wallcheck",
			})
			panel:AddControl("Label", { Text = "" })

			panel:AddControl("Label", { Text = "WARNING!" })
			panel:AddControl("Label", { Text = "Closest and Prefer Head bone preference mode will PERFORM VISIBLE CHECKS FOR ALL EACH EXISTING BONES IN ALL EXISTING ENTITIES" })
			panel:AddControl("Label", { Text = "Which can cause EXTREME LAG and even make your game CRASH!" })
			panel:AddControl("Label", { Text = "Use at your own risk!" })

			local boneComboBox = {}
			boneComboBox.Label = "Bone preference"
			boneComboBox.MenuButton = 0
			boneComboBox.Options = {}
			boneComboBox.Options["Closest"] = { aimbotgun_bone = 0 }
			boneComboBox.Options["Prefer Head"] = { aimbotgun_bone = 1 }
			boneComboBox.Options["Head Only"] = { aimbotgun_bone = 2 }
			panel:AddControl("ComboBox", boneComboBox)

			panel:AddControl("Header", { Description = "Aimbot target" })

			panel:AddControl("CheckBox", {
				Label = "Attack players",
				Command = "aimbotgun_target_player",
			})

			panel:AddControl("CheckBox", {
				Label = "Attack non-hostile NPCs",
				Command = "aimbotgun_friendly_fire",
			})

			panel:AddControl("Label", { Text = "" })

			panel:AddControl("CheckBox", {
				Label = "Attack crow, pigeon and seagull NPCs",
				Command = "aimbotgun_target_bird",
			})

			panel:AddControl("Label", { Text = "" })

			panel:AddControl("CheckBox", {
				Label = "Attack combine NPCs",
				Command = "aimbotgun_target_combine",
			})

			panel:AddControl("CheckBox", {
				Label = "Attack combine hunter NPCs",
				Command = "aimbotgun_target_hunter",
			})

			panel:AddControl("CheckBox", {
				Label = "Attack manhack NPCs",
				Command = "aimbotgun_target_manhack",
			})

			panel:AddControl("CheckBox", {
				Label = "Attack city scanner and claw scanner NPCs",
				Command = "aimbotgun_target_scanner",
			})

			panel:AddControl("Label", { Text = "" })

			panel:AddControl("CheckBox", {
				Label = "Attack antlion NPCs",
				Command = "aimbotgun_target_antlion",
			})

			panel:AddControl("Label", { Text = "" })

			panel:AddControl("CheckBox", {
				Label = "Attack headcrab NPCs",
				Command = "aimbotgun_target_headcrab",
			})

			panel:AddControl("CheckBox", {
				Label = "Attack zombie NPCs",
				Command = "aimbotgun_target_zombie",
			})

			panel:AddControl("CheckBox", {
				Label = "Attack barnacle NPCs",
				Command = "aimbotgun_target_barnacle",
			})

			panel:AddControl("Header", { Description = "Visual" })

			panel:AddControl("Slider", {
				Label = "Crosshair spin speed",
				Command = "aimbotgun_visual_crosshair_spin_speed",
				Type = "Float",
				Min = "0.01",
				Max = "100",
			})
			panel:AddControl("Label", { Text = "" })

			panel:AddControl("Color", {
				Label = "Custom crosshair color",
				Red = "aimbotgun_visual_crosshair_color_red",
				Green = "aimbotgun_visual_crosshair_color_green",
				Blue = "aimbotgun_visual_crosshair_color_blue",
				Alpha = "aimbotgun_visual_crosshair_color_alpha"
			})

			panel:AddControl("CheckBox", {
				Label = "Rainbow crosshair",
				Command = "aimbotgun_visual_crosshair_rainbow",
			})

			panel:AddControl("Slider", {
				Label = "Rainbow crosshair - Rainbow speed",
				Command = "aimbotgun_visual_crosshair_rainbow_speed",
				Type = "Float",
				Min = "0.01",
				Max = "20",
			})

			panel:AddControl("Label", { Text = "" })

			panel:AddControl("Color", {
				Label = "Custom target mark color",
				Red = "aimbotgun_visual_target_mark_color_red",
				Green = "aimbotgun_visual_target_mark_color_green",
				Blue = "aimbotgun_visual_target_mark_color_blue",
				Alpha = "aimbotgun_visual_target_mark_color_alpha"
			})

			panel:AddControl("CheckBox", {
				Label = "Rainbow target mark",
				Command = "aimbotgun_visual_target_mark_rainbow",
			})

			panel:AddControl("Slider", {
				Label = "Rainbow target mark - Rainbow speed",
				Command = "aimbotgun_visual_target_mark_rainbow_speed",
				Type = "Float",
				Min = "0.01",
				Max = "20",
			})
		end)
	end)
end

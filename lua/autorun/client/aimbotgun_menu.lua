if CLIENT then
	hook.Add("PopulateToolMenu", "AimbotGunSettings", function()
		-- Aimbot
		spawnmenu.AddToolMenuOption("Utilities", "AimbotGun", "AimbotGunSettingsAimbot", "Aimbot", "", "", function(panel)
			-- Show the author
			panel:Help("By buu342(RagdollBlood GUI), eric0210(Transcoder to support Aimbot Gun)")
			panel:Help("")

			-- FoV
			panel:NumSlider("FoV", "aimbotgun_aimbot_fov", 0.1, 2, 3)
			panel:ControlHelp("Field-of-View filter.")

			panel:CheckBox("Enable silent aim", "aimbotgun_aimbot_silent")
			panel:ControlHelp("Turn your bullets into guided missile (a.k.a. Magic bullets)")

			-- Reflick
			panel:CheckBox("Enable Reflick", "aimbotgun_aimbot_reflick")
			panel:ControlHelp("Flick to target and quickly flick back to original angle.")

			-- Reflick delay
			panel:NumSlider("Reflick Delay", "aimbotgun_aimbot_reflick_delay", 0, 0.2, 3)
			panel:ControlHelp("The delay to flick back to your original angle. (in seconds)")

			-- Triggerbot
			panel:CheckBox("Enable trigger-bot", "aimbotgun_triggerbot")
			panel:ControlHelp("Automatically shoot target(s) on sight.")

			-- Wall check
			panel:CheckBox("Enable wall check", "aimbotgun_wallcheck")
			panel:ControlHelp("Enable/disable wall checks. Disable it to shoot your target(s) through walls.")

			local boneComboBox = panel:ComboBox("Bone preference", "aimbotgun_bone")
			boneComboBox:AddChoice("Closest", 0)
			boneComboBox:AddChoice("Prefer Head", 1)
			boneComboBox:AddChoice("Head Only", 2, true)
			panel:ControlHelp("Select which part of the target to aim.")
		end)

		-- Aimbot
		spawnmenu.AddToolMenuOption("Utilities", "AimbotGun", "AimbotGunSettingsGlobal", "Global", "", "", function(panel)
			panel:CheckBox("Enable global aimbot", "aimbotgun_global")
			panel:ControlHelp("If enabled, you can use the aimbot with all weapons which shoots bullets.")

			panel:NumSlider("Spread multiplier", "aimbotgun_global_spreadmultiplier", 0, 2.0, 3)
			panel:ControlHelp("Bullet spread multiplier. Set this to 0 to enable NoSpread.")

			panel:NumSlider("Triggerbot - delay between trigger", "aimbotgun_global_triggerdelay", 0, 2.0, 3)
			panel:ControlHelp("Delay between triggerbot triggers your gun trigger. Setting this value too low might cause some issues especially while reloading.")
		end)

		-- Targets
		spawnmenu.AddToolMenuOption("Utilities", "AimbotGun", "AimbotGunSettingsTarget", "Target", "", "", function(panel)
			panel:CheckBox("Attack all valid entities", "aimbotgun_target_all")
			panel:CheckBox("Attack players", "aimbotgun_target_player")
			panel:CheckBox("Attack bird NPCs", "aimbotgun_target_bird")
			panel:CheckBox("Attack combine NPCs", "aimbotgun_target_combine")
			panel:CheckBox("Attack combine hunter NPCs", "aimbotgun_target_hunter")
			panel:CheckBox("Attack manhack NPCs", "aimbotgun_target_manhack")
			panel:CheckBox("Attack scanner NPCs", "aimbotgun_target_scanner")
			panel:CheckBox("Attack antlion NPCs", "aimbotgun_target_antlion")
			panel:CheckBox("Attack headcrab NPCs", "aimbotgun_target_headcrab")
			panel:CheckBox("Attack zombie NPCs", "aimbotgun_target_zombie")
			panel:CheckBox("Attack barnacle NPCs", "aimbotgun_target_barnacle")
		end)

		-- Visual
		spawnmenu.AddToolMenuOption("Utilities", "AimbotGun", "AimbotGunSettingsVisual", "Visual", "", "", function(panel)
			panel:NumSlider("Crosshair spin speed", "aimbotgun_visual_crosshair_spin_speed", "0.01", "10", 1)
			
			panel:ColorPicker("Custom crosshair color",	"aimbotgun_visual_crosshair_color_red", "aimbotgun_visual_crosshair_color_green", "aimbotgun_visual_crosshair_color_blue", "aimbotgun_visual_crosshair_color_alpha")
			panel:CheckBox("Rainbow crosshair", "aimbotgun_visual_crosshair_rainbow")
			panel:NumSlider("Rainbow crosshair - Rainbow speed", "aimbotgun_visual_crosshair_rainbow_speed", "0.01", "20", 3)

			panel:ColorPicker("Custom target mark color",	"aimbotgun_visual_target_mark_color_red", "aimbotgun_visual_target_mark_color_green", "aimbotgun_visual_target_mark_color_blue", "aimbotgun_visual_target_mark_color_alpha")
			panel:CheckBox("Rainbow target mark", "aimbotgun_visual_target_mark_rainbow")
			panel:NumSlider("Rainbow target mark - Rainbow speed", "aimbotgun_visual_target_mark_rainbow_speed", "0.01", "20", 3)
		end)
	end)
end

if CLIENT then
	hook.Add("PopulateToolMenu", "AimbotGunSettings", function()
		-- Aimbot
		spawnmenu.AddToolMenuOption("Utilities", "AimbotGun", "AimbotGunSettingsAimbot", "Aimbot", "", "", function(panel)
			-- Show the author
			panel:Help("By eric0210(Transcoder to support Aimbot Gun)")
			panel:Help("")

			-- FoV
			panel:NumSlider("B - FoV", "aimbotgun_aimbot_fov_b", 0.1, 2, 4)
			panel:ControlHelp("'Bullets' mode Field-of-View.")

			panel:NumSlider("K - FoV", "aimbotgun_aimbot_fov_k", 0.1, 2, 4)
			panel:ControlHelp("'Keybind' mode Field-of-View.")

			local modePref = GetConVar("aimbotgun_aimbot_mode"):GetInt()
			local modeComboBox = panel:ComboBox("Bone preference", "aimbotgun_aimbot_mode")
			modeComboBox:AddChoice("0 - Bullets", 0, true)
			modeComboBox:AddChoice("1 - Both (Keybind + Accuracy)", 1)
			modeComboBox:AddChoice("2 - Keybind", 2)
			modeComboBox:ChooseOption(modeComboBox:GetOptionTextByData(modePref), modePref)
			panel:ControlHelp("Aimbot mode.")

			local smodePref = GetConVar("aimbotgun_aimbot_speedmode"):GetInt()
			local smodeComboBox = panel:ComboBox("Aimspeed mode", "aimbotgun_aimbot_speedmode")
			smodeComboBox:AddChoice("0 - Yaw/Pitch separated", 0, true)
			smodeComboBox:AddChoice("1 - Combined", 1)
			smodeComboBox:ChooseOption(smodeComboBox:GetOptionTextByData(smodePref), smodePref)
			panel:ControlHelp("Aimbot speed mode.")

			panel:NumSlider("Min Speed", "aimbotgun_aimbot_minspeed", 0.05, 180, 4)
			panel:ControlHelp("Limit the rotation changes PER A FRAME, for Aimspeed mode '1'.")

			panel:NumSlider("Max Speed", "aimbotgun_aimbot_maxspeed", 0.05, 180, 4)
			panel:ControlHelp("Limit the rotation changes PER A FRAME, for Aimspeed mode '1'.")

			panel:NumSlider("Min Yaw Speed", "aimbotgun_aimbot_minyawspeed", 0.05, 180, 4)
			panel:ControlHelp("Limit the yaw changes PER A FRAME, for Aimspeed mode '0'.")

			panel:NumSlider("Max Yaw Speed", "aimbotgun_aimbot_maxyawspeed", 0.05, 180, 4)
			panel:ControlHelp("Limit the yaw changes PER A FRAME, for Aimspeed mode '0'.")

			panel:NumSlider("Min Pitch Speed", "aimbotgun_aimbot_minpitchspeed", 0.05, 180, 4)
			panel:ControlHelp("Limit the pitch changes PER A FRAME, for Aimspeed mode '0'.")

			panel:NumSlider("Max Pitch Speed", "aimbotgun_aimbot_maxpitchspeed", 0.05, 180, 4)
			panel:ControlHelp("Limit the pitch changes PER A FRAME, for Aimspeed mode '0'.")

			panel:NumSlider("Smoothing", "aimbotgun_aimbot_smoothamount", 1, 20, 3)
			panel:ControlHelp("Aim movement smoothing, for Aimspeed mode '1'.")

			panel:NumSlider("Yaw Smoothing", "aimbotgun_aimbot_yawsmoothamount", 1, 20, 3)
			panel:ControlHelp("Yaw movement smoothing, for Aimspeed mode '0'.")

			panel:NumSlider("Pitch Smoothing", "aimbotgun_aimbot_pitchsmoothamount", 1, 20, 3)
			panel:ControlHelp("Pitch movement smoothing, for Aimspeed mode '0'.")
			
			panel:NumSlider("Prediction", "aimbotgun_aimbot_predictsize", 0, 5, 4)
			panel:ControlHelp("Target movement prediction.")

			local smoothPref = GetConVar("aimbotgun_aimbot_smooth"):GetInt()
			local smoothComboBox = panel:ComboBox("Smoothing algorithm", "aimbotgun_aimbot_smooth")
			smoothComboBox:AddChoice("0 - Simple", 0, true)
			smoothComboBox:AddChoice("1 - Line", 1)
			smoothComboBox:AddChoice("2 - Quad", 2)
			smoothComboBox:AddChoice("3 - Sine", 3)
			smoothComboBox:AddChoice("4 - Quad Sine", 4)
			smoothComboBox:ChooseOption(smoothComboBox:GetOptionTextByData(smoothPref), smoothPref)
			panel:ControlHelp("Only available on 'Keybind' mode.")

			local bonePref = GetConVar("aimbotgun_aimbot_bone"):GetInt()
			local boneComboBox = panel:ComboBox("Bone preference", "aimbotgun_aimbot_bone")
			boneComboBox:AddChoice("0 - Head Only", 0, true)
			boneComboBox:AddChoice("1 - Prefer Head", 1)
			boneComboBox:AddChoice("2 - Closest", 2)
			boneComboBox:ChooseOption(boneComboBox:GetOptionTextByData(bonePref), bonePref)
			panel:ControlHelp("Select which part of the target to aim.")

			-- Wall check
			panel:CheckBox("Enable Wall Check", "aimbotgun_aimbot_wallcheck")
			panel:ControlHelp("Enable/disable wall checks. Disable it to shoot your target(s) through walls.")

			panel:CheckBox("Triggerbot", "aimbotgun_triggerbot")
			panel:ControlHelp("Automatically shoot targets on your sight.")

			panel:CheckBox("Triggerbot - Only shoot when keybind pressed", "aimbotgun_triggerbot_keycheck")
			panel:ControlHelp("Only shoot the target when aimbot key is pressed, only available for 'Keybind' mode.")

			panel:CheckBox("Triggerbot - Only shoot when ray confirmed", "aimbotgun_triggerbot_raycheck")
			panel:ControlHelp("Only shoot the target when it is on your ray of sight.")

			panel:CheckBox("Lock target", "aimbotgun_aimbot_locktarget")
			panel:ControlHelp("Prevent target switching while pressed the keybind. Only available on 'Keybind' mode.")

			panel:Help("")
			panel:Help("")
			panel:Help("These options are only available for 'Bullets' mode:")
			panel:Help("")

			panel:CheckBox("Enable Silent Aim", "aimbotgun_aimbot_silent")
			panel:ControlHelp("Turn your bullets into guided missile. (a.k.a. Magic bullets)")

			-- Reflick
			panel:CheckBox("Enable Reflick", "aimbotgun_aimbot_reflick")
			panel:ControlHelp("Flick to target and quickly flick back to original angle.")

			-- Reflick delay
			panel:NumSlider("Reflick Delay", "aimbotgun_aimbot_reflick_delay", 0, 0.1, 3)
			panel:ControlHelp("The delay to flick back to your original angle. (in seconds)")
		end)

		-- Aimbot
		spawnmenu.AddToolMenuOption("Utilities", "AimbotGun", "AimbotGunSettingsGlobal", "Global", "", "", function(panel)
			panel:CheckBox("Enable global aimbot", "aimbotgun_global")
			panel:ControlHelp("Enable aimbot for all weapons.")

			panel:KeyBinder("Keybind for Aim Assist", "aimbotgun_global_bind_aimassist", "Keybind for Flickshot", "aimbotgun_global_bind_flick")

			panel:NumSlider("Triggerbot - delay between trigger", "aimbotgun_global_triggerdelay", 0, 2.0, 3)
			panel:ControlHelp("Delay between triggerbot triggers your gun trigger. Setting this value too low might cause some issues especially while reloading.")

			panel:CheckBox("No spread mode", "aimbotgun_global_nospread")
			panel:ControlHelp("Disable bullet spreads, for 'Keybind' mode.")

			panel:NumSlider("Bullet spread multiplier", "aimbotgun_global_spreadmultiplier", 0, 2.0, 3)
			panel:ControlHelp("Bullet spread multiplier, for 'Bullets' mode.")
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

		-- Debuggings
		spawnmenu.AddToolMenuOption("Utilities", "AimbotGun", "AimbotGunSettingsOptimization", "Optimization", "", "", function(panel)
			panel:CheckBox("Only search targets when the aimbot keybind pressed", "aimbotgun_optimization_searchifbindpressed")
			panel:ControlHelp("Only available on 'Keybind' mode")
		end)

		-- Debuggings
		spawnmenu.AddToolMenuOption("Utilities", "AimbotGun", "AimbotGunSettingsDebug", "Debugging", "", "", function(panel)
			panel:CheckBox("Print target data", "aimbotgun_debug_targetdata")
			panel:ControlHelp("Print the previously aimed target data")

			panel:CheckBox("Print triggerbot trigger timings", "aimbotgun_debug_triggerbot")
		end)
	end)
end

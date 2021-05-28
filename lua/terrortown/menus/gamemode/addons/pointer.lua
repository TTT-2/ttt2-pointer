CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"

CLGAMEMODESUBMENU.priority = 0
CLGAMEMODESUBMENU.title = "submenu_addons_pointer_title"

function CLGAMEMODESUBMENU:Populate(parent)
	local form = vgui.CreateTTT2Form(parent, "header_addons_pointer")

	form:MakeCheckBox({
		label = "label_pointer_sound_enable",
		convar = "ttt_pointer_sound_local_enable"
	})

	form:MakeHelp({
		label = "help_addons_pointer"
	})

	form:MakeCheckBox({
		label = "label_pointer_global_enable",
		convar = "ttt_pointer_global_local_enable"
	})

	form:MakeCheckBox({
		label = "label_pointer_team_enable",
		convar = "ttt_pointer_team_local_enable"
	})

	form:MakeCheckBox({
		label = "label_pointer_spec_enable",
		convar = "ttt_pointer_spec_local_enable"
	})

	form:MakeHelp({
		label = "help_addons_pointer_detail"
	})
end

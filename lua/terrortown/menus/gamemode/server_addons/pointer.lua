--- @ignore

CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"
CLGAMEMODESUBMENU.title = "submenu_addons_pointer_title"

function CLGAMEMODESUBMENU:Populate(parent)
	local form = vgui.CreateTTT2Form(parent, "header_addons_pointer")

	form:MakeHelp({
		label = "help_server_addons_pointer"
	})

	form:MakeCheckBox({
		label = "label_pointer_global_enable",
		serverConvar = "ttt_pointer_enable_global"
	})

	form:MakeCheckBox({
		label = "label_pointer_team_enable",
		serverConvar = "ttt_pointer_enable_team"
	})

	form:MakeCheckBox({
		label = "label_pointer_spec_enable",
		serverConvar = "ttt_pointer_enable_spec"
	})

	form:MakeHelp({
		label = "help_addons_pointer_detail"
	})

	form:MakeSlider({
		label = "label_pointer_render_time",
		serverConvar = "ttt_pointer_render_time",
		min = 0,
		max = 100,
		decimal = 0
	})

	form:MakeSlider({
		label = "label_pointer_timeout",
		serverConvar = "ttt_pointer_timeout",
		min = 0,
		max = 20,
		decimal = 0
	})

	form:MakeSlider({
		label = "label_pointer_amount_per_type",
		serverConvar = "ttt_pointer_amount_per_type",
		min = 0,
		max = 20,
		decimal = 0
	})
end

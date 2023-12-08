local materialPointerGlobal = Material("vgui/ttt/hudhelp/pointer_global")
local materialPointerTeam = Material("vgui/ttt/hudhelp/pointer_team")

-- HANDLE LOCAL INPUTS
local function TogglePointer(isGlobal)
	local client = LocalPlayer()

	local ignore = {client}
	local spos = client:GetShootPos()
	local epos = spos + client:GetAimVector() * 10000

	local tr = util.TraceLine({
		start = spos,
		endpos = epos,
		filter = ignore,
		mask = MASK_SOLID
	})

	if tr.HitSky then return end

	net.Start("ttt2_pointer_request")
	net.WriteBool(isGlobal)
	net.WriteVector(tr.HitPos)
	net.WriteVector(tr.HitNormal)
	net.WriteEntity(tr.Entity)
	net.SendToServer()
end

hook.Add("TTT2FinishedLoading", "ttt2_pointer_register_binds", function()
	bind.Register(
		"pointer_global",
		function()
			TogglePointer(true)
		end,
		nil, "header_bindings_pointer", "label_bind_pointer_global", KEY_K
	)

	bind.Register(
		"pointer_team",
		function()
			TogglePointer(false)
		end,
		nil, "header_bindings_pointer", "label_bind_pointer_team", KEY_L
	)

	keyhelp.RegisterKeyHelper("pointer_global", materialPointerGlobal, KEYHELP_EXTRA, "label_keyhelper_pointer_global", function(client)
		if client:IsSpec() then return end

		if not GetConVar("ttt_pointer_enable_global"):GetBool() then return end

		return true
	end)

	keyhelp.RegisterKeyHelper("pointer_team", materialPointerTeam, KEYHELP_EXTRA, "label_keyhelper_pointer_spec", function(client)
		if not client:IsSpec() or not GetConVar("ttt_pointer_enable_spec"):GetBool() then return end

		return true
	end)

	keyhelp.RegisterKeyHelper("pointer_team", materialPointerTeam, KEYHELP_EXTRA, "label_keyhelper_pointer_team", function(client)
		if client:IsSpec() then return end

		if not GetConVar("ttt_pointer_enable_team"):GetBool() then return end

		if client:GetTeam() == TEAM_NONE or client:GetSubRoleData().unknownTeam then return end

		return true
	end)
end)

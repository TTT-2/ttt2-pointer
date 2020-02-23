-- HANDLE LOCAL INPUTS
local function StartPointer(isGlobal)
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

hook.Add("Initialize", "ttt2_pointer_register_binds", function()
	bind.Register(
		"ttt2_pointer_global",
		function()
			StartPointer(true)
		end,
		nil, "ttt2_pointer", nil, KEY_K
	)

	bind.Register(
		"ttt2_pointer_team",
		function()
			StartPointer(false)
		end,
		nil, "ttt2_pointer", nil, KEY_L
	)
end)

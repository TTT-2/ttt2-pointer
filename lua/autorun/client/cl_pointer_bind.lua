-- HANDLE LOCAL INPUTS
local function StartPointer(isGlobal)
	local client = LocalPlayer()

	local tr = util.TraceLine({
		start = client:EyePos(),
		endpos = client:EyePos() + EyeAngles():Forward() * 1000,
		filter = {client},
		mask = MASK_SOLID
	})

	net.Start("ttt2_pointer_request")
	net.WriteBool(isGlobal)
	net.WriteVector(tr.HitPos)
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

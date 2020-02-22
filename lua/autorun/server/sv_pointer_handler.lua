util.AddNetworkString("ttt2_pointer_request")
util.AddNetworkString("ttt2_pointer_push")

net.Receive("ttt2_pointer_request", function(len, ply)
	local isGlobal = net.ReadBool()
	local trPos = net.ReadVector()

	-- special handling for post and prep time
	if GetRoundState() ~= ROUND_ACTIVE then
		isGlobal = true
	end

	-- special handling for innocent team
	if ply:GetTeam() == TEAM_INNOCENT then
		isGlobal = true
	end

	local playersToNotify = {}

	if isGlobal then
		playersToNotify = player.GetAll()
	else
		local players = player.GetAll()

		for i = 1, #players do
			local p = players[i]

			if p:GetTeam() ~= ply:GetTeam() then continue end

			playersToNotify[#playersToNotify + 1] = p
		end
	end

	net.Start("ttt2_pointer_push")
	net.WriteBool(isGlobal)
	net.WriteVector(trPos)
	net.Send(playersToNotify)
end)

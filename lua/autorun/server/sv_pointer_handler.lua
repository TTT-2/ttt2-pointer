util.AddNetworkString("ttt2_pointer_request")
util.AddNetworkString("ttt2_pointer_push")

net.Receive("ttt2_pointer_request", function(len, ply)
	local isGlobal = net.ReadBool()
	local trPos = net.ReadVector()
	local trNormal = net.ReadVector()
	local trEnt = net.ReadEntity()
	local texAngle = 0

	-- special handling for post and prep time
	if GetRoundState() ~= ROUND_ACTIVE then
		isGlobal = true
	end

	-- special handling for innocent team
	if ply:GetTeam() == TEAM_INNOCENT then
		isGlobal = true
	end

	-- if the pointer is on a surface, check if it should be
	-- upside or downside
	if not IsValid(trEnt) then
		local dot_a_b = trNormal:Dot(Vector(0, 0, 1))
		local len_a = trNormal:Length()
		local angle = math.acos(dot_a_b / len_a)

		if angle <= 0.5 * math.pi then
			texAngle = 0
		else
			texAngle = 180
		end
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

	-- PRINT LOGGING INFORMATION
	if IsValid(trEnt) then
		local name = (not trEnt.PrintName or tostring(trEnt.PrintName) == "") and trEnt:GetClass() or tostring(trEnt.PrintName)
		print("[TTT2 Pointer] " .. ply:Nick() .. " issued a new pointer at an entity (" .. name .. ") at: [x=" .. tostring(trPos.x) .. ", y=" .. tostring(trPos.y) .. ", z=" .. tostring(trPos.z) .. "], mode: " .. (isGlobal and "global" or "team"))
	else
		print("[TTT2 Pointer] " .. ply:Nick() .. " issued a new pointer at: [x=" .. tostring(trPos.x) .. ", y=" .. tostring(trPos.y) .. ", z=" .. tostring(trPos.z) .. "], mode: " .. (isGlobal and "global" or "team"))
	end

	net.Start("ttt2_pointer_push")
	net.WriteBool(isGlobal)
	net.WriteVector(trPos)
	net.WriteVector(trNormal)
	net.WriteEntity(trEnt)
	net.WriteFloat(texAngle)
	net.Send(playersToNotify)
end)

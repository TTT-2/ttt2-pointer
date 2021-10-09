util.AddNetworkString("ttt2_pointer_request")
util.AddNetworkString("ttt2_pointer_push")

net.Receive("ttt2_pointer_request", function(len, ply)
	local isGlobal = net.ReadBool()
	local trPos = net.ReadVector()
	local trNormal = net.ReadVector()
	local trEnt = net.ReadEntity()
	local texAngle = 0
	local mode = isGlobal and PMODE_GLOBAL or PMODE_TEAM
	local color = COLOR_WHITE
	local tm = ply:GetTeam()

	-- special handling for post and prep time
	if GetRoundState() ~= ROUND_ACTIVE then
		mode = PMODE_GLOBAL
	end

	if ply:IsSpec() then
		-- special handling for spectators
		mode = PMODE_SPEC
	elseif not tm or tm == TEAM_NONE or TEAMS[tm].alone or tm == TEAM_INNOCENT then
		-- special handling for innocent team and no team
		mode = PMODE_GLOBAL
	end

	-- add exterman addon support to block pointer usage
	if hook.Run("TTT2CanUsePointer", ply, mode, trPos, trEnt) == false then return end

	-- make sure a certain amount of time since the last pointer has passed
	local timeout = GetConVar("ttt_pointer_timeout"):GetInt()

	if ply.last_pointer_time and CurTime() - ply.last_pointer_time < timeout then
		LANG.Msg(ply, "ttt2_pointer_timeout", {time = math.ceil(timeout - CurTime() + ply.last_pointer_time)}, MSG_MSTACK_WARN)

		return
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

	if mode == PMODE_SPEC and GetConVar("ttt_pointer_enable_spec"):GetBool() then
		local players = player.GetAll()

		for i = 1, #players do
			local p = players[i]

			-- show only to spectators
			if not p:IsSpec() then continue end

			playersToNotify[#playersToNotify + 1] = p
		end

		color = COLOR_YELLOW
	elseif mode == PMODE_GLOBAL and GetConVar("ttt_pointer_enable_global"):GetBool() then
		playersToNotify = player.GetAll()

		color = TEAMS[TEAM_INNOCENT].color
	elseif mode == PMODE_TEAM and GetConVar("ttt_pointer_enable_team"):GetBool() then
		local players = player.GetAll()

		for i = 1, #players do
			local p = players[i]

			-- show only to teammates and spectators
			if p:GetTeam() ~= ply:GetTeam() and not p:IsSpec() then continue end

			playersToNotify[#playersToNotify + 1] = p
		end

		color = TEAMS[ply:GetTeam()].color
	end

	-- PRINT LOGGING INFORMATION
	if IsValid(trEnt) then
		local name = (not trEnt.PrintName or tostring(trEnt.PrintName) == "") and trEnt:GetClass() or tostring(trEnt.PrintName)
		print("[TTT2 Pointer] " .. ply:Nick() .. " issued a new pointer at an entity (" .. name .. ") at: [x=" .. tostring(trPos.x) .. ", y=" .. tostring(trPos.y) .. ", z=" .. tostring(trPos.z) .. "], mode: " .. (isGlobal and "global" or "team"))
	else
		print("[TTT2 Pointer] " .. ply:Nick() .. " issued a new pointer at: [x=" .. tostring(trPos.x) .. ", y=" .. tostring(trPos.y) .. ", z=" .. tostring(trPos.z) .. "], mode: " .. (isGlobal and "global" or "team"))
	end

	-- SET LAST POINTER
	ply.last_pointer_time = CurTime()

	-- WRITE DATA TO CLIENTS
	net.Start("ttt2_pointer_push")
	net.WriteUInt(mode, 2)
	net.WriteVector(trPos)
	net.WriteVector(trNormal)
	net.WriteEntity(trEnt)
	net.WriteEntity(ply)
	net.WriteFloat(texAngle)
	net.WriteUInt(color.r, 8)
	net.WriteUInt(color.g, 8)
	net.WriteUInt(color.b, 8)
	net.WriteUInt(color.a, 8)
	net.Send(playersToNotify)
end)

---
-- Defines if a player can use the pointer
-- @param Player ply The player that tries to use the pointer
-- @param number mode The pointer mode
-- @param Vector trPos The marked position
-- @param Entity trEnt The marked entity (can be nil)
-- @return boolean Return false to block usage
--[[function GM:TTT2CanUsePointer(ply, mode, trPos, trEnt)

end]]

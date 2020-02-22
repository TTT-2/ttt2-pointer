local LIFE_TIME = 10

-- HANDLE RENDERING
local pointerData = {}

net.Receive("ttt2_pointer_push", function()
	pointerData[#pointerData + 1] = {
		isGlobal = net.ReadBool(),
		pos = net.ReadVector(),
		time = CurTime()
	}
end)

-- check if pointer is still valid
hook.Add("Think", "ttt2_pointer_check_validity", function()
	if #pointerData == 0 then return end

	for i = #pointerData, 1, -1 do
		if CurTime() - pointerData[i].time < LIFE_TIME then continue end

		table.remove(pointerData, i)
	end
end)

hook.Add("PreDrawHUD", "ttt2_pointer_draw_marker", function()
	if #pointerData == 0 then return end

	for i = 1, #pointerData do
		print(pointerData[i].pos)
	end
end)

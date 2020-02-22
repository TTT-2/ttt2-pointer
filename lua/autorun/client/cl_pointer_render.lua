local pointerMat = Material("vgui/ttt/in_world_pointer.png")

local LIFE_TIME = 30
local SIZE_H = 64
local SIZE_W = 32

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

hook.Add("PostDrawEffects", "ttt2_pointer_draw_marker", function()
	if #pointerData == 0 then return end

	for i = 1, #pointerData do
		--local scrpos = pointerData[i].pos:ToScreen()

		--PrintTable(scrpos)

		--if IsOffScreen(scrpos) then
		--	print("offscreen")
		--	continue
		--end

		cam.Start3D() -- Start the 3D function so we can draw onto the screen.
			render.SetMaterial( pointerMat ) -- Tell render what material we want, in this case the flash from the gravgun
			render.DrawSprite( pointerData[i].pos + Vector(0, 0, SIZE_H * 0.5), SIZE_W, SIZE_H, LocalPlayer():GetRoleColor()) -- Draw the sprite in the middle of the map, at 16x16 in it's original colour with full alpha.
		cam.End3D()

		--draw.FilteredTexture(scrpos.x - 64, scrpos.y - 128, 128, 256, pointerMat)
		--draw.FilteredTexture(555, 555, 128, 256, pointerMat)
	end
end)

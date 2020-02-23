local pointerMat = Material("vgui/ttt/in_world_pointer.png")
local pointerOverlayMat = Material("vgui/ttt/in_world_pointer_overlay.png")
local pointerGroundMat = Material("vgui/ttt/in_world_pointer_ground.png")
local pointerGroundOverlayMat = Material("vgui/ttt/in_world_pointer_ground_overlay.png")

local LIFE_TIME = 30
local SIZE_H = 256
local SIZE_W = 128

-- HANDLE RENDERING
local pointerData = {}
local markerData = {}

net.Receive("ttt2_pointer_push", function()
	pointerData[#pointerData + 1] = {
		isGlobal = net.ReadBool(),
		pos = net.ReadVector(),
		normal = net.ReadVector(),
		ent = net.ReadEntity(),
		time = CurTime(),
		texAngle = net.ReadFloat()
	}
end)

local function FilteredTextureRotated(x, y, w, h, material, ang, alpha, color)
	alpha = alpha or 255
	color = color or COLOR_WHITE

	local c = math.cos(math.rad(ang))
	local s = math.sin(math.rad(ang))

	local newx = y * s - x * c
	local newy = y * c + x * s

	surface.SetDrawColor(color.r, color.g, color.b, alpha)
	surface.SetMaterial(material)

	render.PushFilterMag(TEXFILTER.LINEAR)
	render.PushFilterMin(TEXFILTER.LINEAR)

	surface.DrawTexturedRectRotated(newx, newy, w, h, ang or 0)

	render.PopFilterMag()
	render.PopFilterMin()
end

-- check if pointer is still valid
hook.Add("Think", "ttt2_pointer_check_validity", function()
	if #pointerData == 0 then return end

	for i = #pointerData, 1, -1 do
		if CurTime() - pointerData[i].time < LIFE_TIME then continue end

		table.remove(pointerData, i)
	end
end)

hook.Add("PostDrawTranslucentRenderables", "ttt2_pointer_draw_inworld_marker", function()
	if #pointerData == 0 then return end

	local client = LocalPlayer()

	for i = 1, #pointerData do
		local pointer = pointerData[i]

		--local scrpos = pointerData[i].pos:ToScreen()

		--PrintTable(scrpos)

		--if IsOffScreen(scrpos) then
		--	print("offscreen")
		--	continue
		--end

		-- SPECIAL HANDLING IF AN ENTITY IS FOCUSED
		local pointerPos
		if IsValid(pointer.ent) then
			local _, max = pointer.ent:GetModelBounds()
			local scale = pointer.ent:GetModelScale()
			pointerPos = pointer.ent:GetPos() + pointer.ent:OBBCenter() + Vector(0, 0, 0.5 * (scale or 1) * max.z)
		else
			pointerPos = pointer.pos
		end

		-- CHECK IF POINTER IS VISIBLE
		local tr = util.TraceLine({
			start = pointerPos,
			endpos = client:GetShootPos(),
			filter = {client, pointer.ent},
			mask = MASK_SOLID
		})

		-- trace hit world and the pointer might be invisible
		-- therefore we need to draw a marker on screen in another
		-- render context
		if tr.HitWorld then
			markerData[#markerData + 1] = {
				isGlobal = pointer.isGlobal,
				pos = pointerPos
			}
		end

		if IsValid(pointer.ent) then
			-- DRAW OUTLINE AROUND ENTITY IF IT IS AN ENTITY
			outline.Add(pointer.ent, client:GetRoleColor(), OUTLINE_MODE_VISIBLE)
		else
			-- DRAW CIRCLE ON GROUND IF IT IS NOT ENTITY
			cam.Start3D2D(
				pointerPos,
				pointer.normal:Angle() + Angle(90, 0, 0),
				0.3
			)

				draw.FilteredTexture(-0.5 * SIZE_W, -0.5 * SIZE_W, SIZE_W, SIZE_W, pointerGroundMat, 180, client:GetRoleColor())
				draw.FilteredTexture(-0.5 * SIZE_W, -0.5 * SIZE_W, SIZE_W, SIZE_W, pointerGroundOverlayMat, 160, COLOR_WHITE)

			cam.End3D2D()
		end

		-- DRAW POINTER
		cam.Start3D2D(
			pointerPos,
			Angle(0, LocalPlayer():GetAngles().y - 90, 90),
			0.3
		)

			if pointer.texAngle == 180 then
				FilteredTextureRotated(0, -0.365 * SIZE_H, SIZE_W, SIZE_H, pointerMat, 180, 255, client:GetRoleColor())
				FilteredTextureRotated(0, -0.365 * SIZE_H, SIZE_W, SIZE_H, pointerOverlayMat, 180, 150, COLOR_WHITE)
			else
				draw.FilteredTexture(-0.5 * SIZE_W, -0.865 * SIZE_H, SIZE_W, SIZE_H, pointerMat, 255, client:GetRoleColor())
				draw.FilteredTexture(-0.5 * SIZE_W, -0.865 * SIZE_H, SIZE_W, SIZE_H, pointerOverlayMat, 150, COLOR_WHITE)
			end

		cam.End3D2D()
	end
end)

hook.Add("PostDrawHUD", "ttt2_pointer_draw_2d_marker", function()
	if #markerData == 0 then return end

	local client = LocalPlayer()

	for i = 1, #markerData do
		local marker = markerData[i]

		local scrpos = marker.pos:ToScreen()

		local sz = IsOffScreen(scrpos) and (SIZE_W * 0.5) or SIZE_W

		scrpos.x = math.Clamp(scrpos.x, sz, ScrW() - sz)
		scrpos.y = math.Clamp(scrpos.y, sz, ScrH() - sz)

		draw.FilteredTexture(scrpos.x - 0.5 * SIZE_W, scrpos.y - 0.5 * SIZE_W, SIZE_W, SIZE_W, pointerGroundMat, 180, client:GetRoleColor())
	end

	-- reset marker data array
	markerData = {}
end)

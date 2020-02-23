local pointerMat = Material("vgui/ttt/in_world_pointer.png")
local pointerOverlayMat = Material("vgui/ttt/in_world_pointer_overlay.png")
local pointerGroundMat = Material("vgui/ttt/in_world_pointer_ground.png")
local pointerGroundOverlayMat = Material("vgui/ttt/in_world_pointer_ground_overlay.png")
local pointer2dMat = Material("vgui/ttt/2d_pointer.png")
local pointer2dOverlayMat = Material("vgui/ttt/2d_pointer_overlay.png")
local pointer2dOutsideMat = Material("vgui/ttt/2d_pointer_outside.png")
local pointer2dOutsideOverlayMat = Material("vgui/ttt/2d_pointer_outside_overlay.png")

surface.CreateFont("Pointer2DText", {font = "Trebuchet24", size = 24, weight = 900})
surface.CreateFont("PointerTextNick", {font = "Trebuchet24", size = 17, weight = 600})
surface.CreateFont("PointerTextInfo", {font = "Trebuchet24", size = 14, weight = 300})

local MODE_GLOBAL = 0
local MODE_TEAM = 1
local MODE_SPEC = 2

local LIFE_TIME = 45
local FADE_TIME = 1.5
local SIZE_H = 256
local SIZE_W = 128
local SIZE_2D = 128
local SIZE_2D_OUT = 32

-- HANDLE RENDERING
local pointerData = {}
local markerData = {}

net.Receive("ttt2_pointer_push", function()
	pointerData[#pointerData + 1] = {
		mode = net.ReadUInt(2),
		pos = net.ReadVector(),
		normal = net.ReadVector(),
		ent = net.ReadEntity(),
		owner = net.ReadEntity(),
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

local function GetColor(mode)
	local color
	if mode == MODE_GLOBAL then
		color = TEAMS[TEAM_INNOCENT].color
	elseif mode == MODE_TEAM then
		color = TEAMS[LocalPlayer():GetTeam()].color
	else
		color = COLOR_YELLOW
	end

	return color
end

local function DrawInfoBox(refX, refY, ply, pointer, color, remaining, opacity)
	local suffix
	if pointer.mode == MODE_GLOBAL then
		suffix = " [G]"
	elseif pointer.mode == MODE_TEAM then
		suffix = " [T]"
	else
		suffix = " [S]"
	end

	local t_nick = pointer.owner:Nick() .. suffix
	local t_dist = "Distance: " .. tostring(math.Round(ply:GetPos():Distance(pointer.pos), 0))
	local t_time = "Time Remaining: " .. tostring(math.floor(remaining, 0))

	local width_nick, height_nick = draw.GetTextSize(t_nick, "PointerTextNick")
	local width_dist, heigh_dist = draw.GetTextSize(t_dist, "PointerTextInfo")
	local width_time, heigh_time = draw.GetTextSize(t_time, "PointerTextInfo")

	width = math.max(width_nick, width_dist, width_time) + 20
	height = height_nick + heigh_dist + heigh_time + 20

	local boxColor = Color(color.r, color.g, color.b, 160 * opacity)
	local textColor = Color(255, 255, 255, 255 * opacity)

	local posX = refX
	local posY = refY

	draw.RoundedBox(8, posX, posY, width, height, boxColor)

	posX = posX + 10
	posY = posY + 5

	draw.ShadowedText(
		t_nick,
		"PointerTextNick",
		posX,
		posY,
		textColor,
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_TOP
	)

	posY = posY + height_nick + 5

	draw.ShadowedText(
		t_dist,
		"PointerTextInfo",
		posX,
		posY,
		textColor,
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_TOP
	)

	posY = posY + heigh_dist + 5

	draw.ShadowedText(
		t_time,
		"PointerTextInfo",
		posX,
		posY,
		textColor,
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_TOP
	)
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

		local color = GetColor(pointer.mode)

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

		-- trace hit world or pointer is outside of the visible area
		-- therefore we need to draw a marker on screen in another
		-- render context
		if tr.HitWorld or IsOffScreen(pointerPos:ToScreen()) then
			markerData[#markerData + 1] = {
				mode = pointer.mode,
				pos = pointerPos,
				time = pointer.time
			}
		end

		local remaining = LIFE_TIME - (CurTime() - pointer.time)
		local opacity = (remaining > FADE_TIME) and 1 or math.max(remaining / FADE_TIME, 0)

		if IsValid(pointer.ent) then
			-- DRAW OUTLINE AROUND ENTITY IF IT IS AN ENTITY
			outline.Add(pointer.ent, color, OUTLINE_MODE_VISIBLE)
		else
			-- DRAW CIRCLE ON GROUND IF IT IS NOT ENTITY
			cam.Start3D2D(
				pointerPos,
				pointer.normal:Angle() + Angle(90, 0, 0),
				0.3
			)

				draw.FilteredTexture(-0.5 * SIZE_W, -0.5 * SIZE_W, SIZE_W, SIZE_W, pointerGroundMat, 180 * opacity, color)
				draw.FilteredTexture(-0.5 * SIZE_W, -0.5 * SIZE_W, SIZE_W, SIZE_W, pointerGroundOverlayMat, 160 * opacity, COLOR_WHITE)

			cam.End3D2D()
		end

		-- DRAW POINTER
		cam.Start3D2D(
			pointerPos,
			Angle(0, LocalPlayer():GetAngles().y - 90, 90),
			0.3
		)

			if pointer.texAngle == 180 then
				FilteredTextureRotated(0, -0.365 * SIZE_H, SIZE_W, SIZE_H, pointerMat, 180, 255 * opacity, color)
				FilteredTextureRotated(0, -0.365 * SIZE_H, SIZE_W, SIZE_H, pointerOverlayMat, 180, 150 * opacity, COLOR_WHITE)

				DrawInfoBox(0.3 * SIZE_W, 0.45 * SIZE_H, client, pointer, color, remaining, opacity)
			else
				draw.FilteredTexture(-0.5 * SIZE_W, -0.865 * SIZE_H, SIZE_W, SIZE_H, pointerMat, 255 * opacity, color)
				draw.FilteredTexture(-0.5 * SIZE_W, -0.865 * SIZE_H, SIZE_W, SIZE_H, pointerOverlayMat, 150 * opacity, COLOR_WHITE)

				DrawInfoBox(0.3 * SIZE_W, -0.7 * SIZE_H, client, pointer, color, remaining, opacity)
			end

		cam.End3D2D()
	end
end)

hook.Add("PostDrawHUD", "ttt2_pointer_draw_2d_marker", function()
	if #markerData == 0 then return end

	local client = LocalPlayer()

	for i = 1, #markerData do
		local marker = markerData[i]

		local color = GetColor(marker.mode)

		local scrpos = marker.pos:ToScreen()
		local isOffScreen = IsOffScreen(scrpos)
		local sz = 0.5 * (isOffScreen and SIZE_2D_OUT or SIZE_2D)

		scrpos.x = math.Clamp(scrpos.x, sz, ScrW() - sz)
		scrpos.y = math.Clamp(scrpos.y, sz, ScrH() - sz)

		local remaining = LIFE_TIME - (CurTime() - marker.time)
		local opacity = (remaining > FADE_TIME) and 1 or math.max(remaining / FADE_TIME, 0)

		if isOffScreen then
			draw.FilteredTexture(scrpos.x - 0.5 * SIZE_2D_OUT, scrpos.y - 0.5 * SIZE_2D_OUT, SIZE_2D_OUT, SIZE_2D_OUT, pointer2dOutsideMat, 180 * opacity, color)
			draw.FilteredTexture(scrpos.x - 0.5 * SIZE_2D_OUT, scrpos.y - 0.5 * SIZE_2D_OUT, SIZE_2D_OUT, SIZE_2D_OUT, pointer2dOutsideOverlayMat, 140 * opacity, COLOR_WHITE)
		else
			draw.FilteredTexture(scrpos.x - 0.5 * SIZE_2D, scrpos.y - 0.5 * SIZE_2D, SIZE_2D, SIZE_2D, pointer2dMat, 180 * opacity, color)
			draw.FilteredTexture(scrpos.x - 0.5 * SIZE_2D, scrpos.y - 0.5 * SIZE_2D, SIZE_2D, SIZE_2D, pointer2dOverlayMat, 140 * opacity, COLOR_WHITE)

			draw.ShadowedText(math.Round(client:GetPos():Distance(marker.pos), 0), "Pointer2DText", scrpos.x, scrpos.y, Color(color.r, color.g, color.b, 180 * opacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	-- reset marker data array
	markerData = {}
end)

-- CLEAR TEAM MARKER WHEN THE TEAM IS CHANGED
hook.Add("TTT2UpdateTeam", "ttt2_pointer_team_change", function(ply, old, new)
	for i = #pointerData, 1, -1 do
		if pointerData[i].mode ~= MODE_TEAM then continue end

		table.remove(pointerData, i)
	end
end)

-- CLEAR SPEC MARKER WHEN THE IS REVIVED
hook.Add("PlayerSpawn", "ttt2_pointer_respawn", function(ply, old, new)
	for i = #pointerData, 1, -1 do
		if pointerData[i].mode ~= MODE_SPEC then continue end

		table.remove(pointerData, i)
	end
end)

-- CLEAR ALL MARKER WHEN NEW ROUND STARTS
hook.Add("TTTPrepareRound", "ttt2_pointer_prep", function(ply, old, new)
	pointerData = {}
end)

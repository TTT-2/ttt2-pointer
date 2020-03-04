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

local FADE_TIME = 1.5
local VAL_TIME = 0.1
local SIZE_H = 256
local SIZE_W = 128
local SIZE_2D = 128
local SIZE_2D_OUT = 32

-- HANDLE RENDERING
local pointerData = {}
local markerData = {}
local lastValidation = CurTime()

sound.Add({
	name = "new_pointer",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 130,
	sound = "buttons/button9.wav"
})


net.Receive("ttt2_pointer_push", function()
	pointerData[#pointerData + 1] = {
		mode = net.ReadUInt(2),
		pos = net.ReadVector(),
		normal = net.ReadVector(),
		ent = net.ReadEntity(),
		owner = net.ReadEntity(),
		time = CurTime(),
		texAngle = net.ReadFloat(),
		color = Color(
			net.ReadUInt(8),
			net.ReadUInt(8),
			net.ReadUInt(8),
			net.ReadUInt(8)
		)
	}

	-- emit sound on new pointer
	LocalPlayer():EmitSound("new_pointer", 100)
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

local function DrawInfoBox(refX, refY, ply, pointer, remaining, opacity)
	local suffix
	if pointer.mode == PMODE_GLOBAL then
		suffix = " [G]"
	elseif pointer.mode == PMODE_TEAM then
		suffix = " [T]"
	else
		suffix = " [S]"
	end

	local t_nick = pointer.owner:Nick() .. suffix
	local t_dist = LANG.GetParamTranslation("ttt2_pointer_distance", {distance = math.Round(ply:GetPos():Distance(pointer.pos), 0)})
	local t_time = LANG.GetParamTranslation("ttt2_pointer_time", {time = math.floor(remaining, 0)})

	local width_nick, height_nick = draw.GetTextSize(t_nick, "PointerTextNick")
	local width_dist, heigh_dist = draw.GetTextSize(t_dist, "PointerTextInfo")
	local width_time, heigh_time = draw.GetTextSize(t_time, "PointerTextInfo")

	width = math.max(width_nick, width_dist, width_time) + 20
	height = height_nick + heigh_dist + heigh_time + 20

	local boxColor = Color(pointer.color.r, pointer.color.g, pointer.color.b, 160 * opacity)
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

	if CurTime() - lastValidation < VAL_TIME then return end

	lastValidation = CurTime()

	local client = LocalPlayer()

	for i = #pointerData, 1, -1 do
		if CurTime() - pointerData[i].time < GetGlobalInt("ttt_pointer_render_time", 8) then continue end

		table.remove(pointerData, i)
	end

	-- sort table so that far away pointers are rendered first
	table.sort(pointerData, function(a, b)
		return client:GetPos():Distance(a.pos) > client:GetPos():Distance(b.pos)
	end)
end)

hook.Add("PostDrawTranslucentRenderables", "ttt2_pointer_draw_inworld_marker", function()
	if #pointerData == 0 then return end

	local client = LocalPlayer()

	for i = 1, #pointerData do
		local pointer = pointerData[i]

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

		-- the scrpos has to be calculatet inside a non modified cam3D space
		-- to yield correct results
		local scrpos
		cam.Start3D()
			scrpos = pointerPos:ToScreen()
		cam.End3D()

		-- trace hit world or pointer is outside of the visible area
		-- therefore we need to draw a marker on screen in another
		-- render context
		if tr.HitWorld or IsOffScreen(scrpos) then
			markerData[#markerData + 1] = {
				mode = pointer.mode,
				pos = pointerPos,
				scrpos = scrpos,
				time = pointer.time,
				color = pointer.color
			}
		end

		local remaining = GetGlobalInt("ttt_pointer_render_time", 8) - (CurTime() - pointer.time)
		local opacity = (remaining > FADE_TIME) and 1 or math.max(remaining / FADE_TIME, 0)

		if IsValid(pointer.ent) then
			-- DRAW OUTLINE AROUND ENTITY IF IT IS AN ENTITY
			outline.Add(pointer.ent, pointer.color, OUTLINE_PMODE_VISIBLE)
		else
			-- DRAW CIRCLE ON GROUND IF IT IS NOT ENTITY
			cam.Start3D2D(
				pointerPos + pointer.normal * 2,
				pointer.normal:Angle() + Angle(90, 0, 0),
				0.3
			)

				draw.FilteredTexture(-0.5 * SIZE_W, -0.5 * SIZE_W, SIZE_W, SIZE_W, pointerGroundMat, 180 * opacity, pointer.color)
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
				FilteredTextureRotated(0, -0.365 * SIZE_H, SIZE_W, SIZE_H, pointerMat, 180, 255 * opacity, pointer.color)
				FilteredTextureRotated(0, -0.365 * SIZE_H, SIZE_W, SIZE_H, pointerOverlayMat, 180, 150 * opacity, COLOR_WHITE)

				DrawInfoBox(0.3 * SIZE_W, 0.45 * SIZE_H, client, pointer, remaining, opacity)
			else
				draw.FilteredTexture(-0.5 * SIZE_W, -0.865 * SIZE_H, SIZE_W, SIZE_H, pointerMat, 255 * opacity, pointer.color)
				draw.FilteredTexture(-0.5 * SIZE_W, -0.865 * SIZE_H, SIZE_W, SIZE_H, pointerOverlayMat, 150 * opacity, COLOR_WHITE)

				DrawInfoBox(0.3 * SIZE_W, -0.7 * SIZE_H, client, pointer, remaining, opacity)
			end

		cam.End3D2D()
	end
end)

hook.Add("PostDrawHUD", "ttt2_pointer_draw_2d_marker", function()
	if #markerData == 0 then return end

	local client = LocalPlayer()

	for i = 1, #markerData do
		local marker = markerData[i]

		local isOffScreen = IsOffScreen(marker.scrpos)
		local sz = 0.5 * (isOffScreen and SIZE_2D_OUT or SIZE_2D)

		marker.scrpos.x = math.Clamp(marker.scrpos.x, sz, ScrW() - sz)
		marker.scrpos.y = math.Clamp(marker.scrpos.y, sz, ScrH() - sz)

		local remaining = GetGlobalInt("ttt_pointer_render_time", 8) - (CurTime() - marker.time)
		local opacity = (remaining > FADE_TIME) and 1 or math.max(remaining / FADE_TIME, 0)

		if isOffScreen then
			draw.FilteredTexture(
				marker.scrpos.x - 0.5 * SIZE_2D_OUT,
				marker.scrpos.y - 0.5 * SIZE_2D_OUT,
				SIZE_2D_OUT,
				SIZE_2D_OUT,
				pointer2dOutsideMat,
				180 * opacity,
				marker.color
			)
			draw.FilteredTexture(
				marker.scrpos.x - 0.5 * SIZE_2D_OUT,
				marker.scrpos.y - 0.5 * SIZE_2D_OUT,
				SIZE_2D_OUT,
				SIZE_2D_OUT,
				pointer2dOutsideOverlayMat,
				140 * opacity,
				COLOR_WHITE
			)
		else
			draw.FilteredTexture(
				marker.scrpos.x - 0.5 * SIZE_2D,
				marker.scrpos.y - 0.5 * SIZE_2D,
				SIZE_2D,
				SIZE_2D,
				pointer2dMat,
				180 * opacity,
				marker.color
			)
			draw.FilteredTexture(
				marker.scrpos.x - 0.5 * SIZE_2D,
				marker.scrpos.y - 0.5 * SIZE_2D,
				SIZE_2D,
				SIZE_2D,
				pointer2dOverlayMat,
				140 * opacity,
				COLOR_WHITE
			)

			draw.ShadowedText(
				math.Round(client:GetPos():Distance(marker.pos), 0),
				"Pointer2DText",
				marker.scrpos.x,
				marker.scrpos.y,
				Color(marker.color.r, marker.color.g, marker.color.b, 180 * opacity),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER
			)
		end
	end

	-- reset marker data array
	table.Empty(markerData)
end)

-- CLEAR TEAM MARKER WHEN THE TEAM IS CHANGED
hook.Add("TTT2UpdateTeam", "ttt2_pointer_team_change", function(ply, old, new)
	if ply ~= LocalPlayer() then return end

	for i = #pointerData, 1, -1 do
		if pointerData[i].mode ~= PMODE_TEAM then continue end

		table.remove(pointerData, i)
	end
end)

-- CLEAR SPEC MARKER WHEN THE IS REVIVED
hook.Add("PlayerSpawn", "ttt2_pointer_respawn", function(ply, old, new)
	for i = #pointerData, 1, -1 do
		if pointerData[i].mode ~= PMODE_SPEC then continue end

		table.remove(pointerData, i)
	end
end)

-- CLEAR ALL MARKER WHEN NEW ROUND STARTS
hook.Add("TTTPrepareRound", "ttt2_pointer_prep", function(ply, old, new)
	pointerData = {}
end)

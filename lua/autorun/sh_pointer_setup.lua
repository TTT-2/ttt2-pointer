PMODE_GLOBAL = 0
PMODE_TEAM = 1
PMODE_SPEC = 2

if SERVER then
	resource.AddFile("materials/vgui/ttt/2d_pointer_outside_overlay.png")
	resource.AddFile("materials/vgui/ttt/2d_pointer_outside.png")
	resource.AddFile("materials/vgui/ttt/2d_pointer_overlay.png")
	resource.AddFile("materials/vgui/ttt/2d_pointer.png")
	resource.AddFile("materials/vgui/ttt/in_world_pointer_ground_overlay.png")
	resource.AddFile("materials/vgui/ttt/in_world_pointer_ground.png")
	resource.AddFile("materials/vgui/ttt/in_world_pointer_overlay.png")
	resource.AddFile("materials/vgui/ttt/in_world_pointer.png")
end

local cv = {}
cv.render_time = CreateConVar("ttt_pointer_render_time", 8, {FCVAR_NOTIFY, FCVAR_ARCHIVE})

hook.Add("TTTUlxInitCustomCVar", "ttt2_pointer_replicate_convars", function(name)
	ULib.replicatedWritableCvar(cv.render_time:GetName(), "rep_" .. cv.render_time:GetName(), cv.render_time:GetInt(), true, false, name)
end)

if SERVER then
	-- ConVar replication is broken in GMod, so we do this, at least Alf added a hook!
	-- I don't like it any more than you do, dear reader. Copycat!
	hook.Add("TTT2SyncGlobals", "ttt2_pointer_sync_convars", function()
		SetGlobalInt(cv.render_time:GetName(), cv.render_time:GetInt())
	end)

	-- sync convars on change
	cvars.AddChangeCallback(cv.render_time:GetName(), function(cvar, old, new)
		SetGlobalInt(cv.render_time:GetName(), tonumber(new))
	end)
end

-- add to ULX
if CLIENT then
	hook.Add("TTTUlxModifyAddonSettings", "ttt2_pointer_add_to_ulx", function(name)
		local tttrspnl = xlib.makelistlayout{w = 415, h = 318, parent = xgui.null}

		-- Basic Settings
		local tttrsclp = vgui.Create("DCollapsibleCategory", tttrspnl)
		tttrsclp:SetSize(390, 20)
		tttrsclp:SetExpanded(1)
		tttrsclp:SetLabel("Basic Settings")

		local tttrslst = vgui.Create("DPanelList", tttrsclp)
		tttrslst:SetPos(5, 25)
		tttrslst:SetSize(390, 20)
		tttrslst:SetSpacing(5)

		tttrslst:AddItem(xlib.makeslider{
			label = cv.render_time:GetName() .. " (def. 8)",
			repconvar = "rep_" .. cv.render_time:GetName(),
			min = 0,
			max = 100,
			decimal = 0,
			parent = tttrslst
		})

		-- add to ULX
		xgui.hookEvent("onProcessModules", nil, tttrspnl.processModules)
		xgui.addSubModule("3D Pointer", tttrspnl, nil, name)
	end)
end
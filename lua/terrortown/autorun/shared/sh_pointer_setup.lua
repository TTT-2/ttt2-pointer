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

	resource.AddFile("materials/vgui/ttt/hudhelp/pointer_team.vmt")
	resource.AddFile("materials/vgui/ttt/hudhelp/pointer_global.vmt")
end

CreateConVar("ttt_pointer_render_time", 8, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_pointer_timeout", 2, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_pointer_amount_per_type", 3, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_pointer_enable_global", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_pointer_enable_team", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_pointer_enable_spec", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})

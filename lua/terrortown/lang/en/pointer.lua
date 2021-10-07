L = LANG.GetLanguageTableReference("en")

L["ttt2_pointer_new"] = "{playername} added a new 3D pointer!"
L["ttt2_pointer_timeout"] = "You have to wait {time} second(s) to add a new pointer!"
L["ttt2_pointer_distance"] = "Distance: {distance}"
L["ttt2_pointer_time"] = "Time Remaining: {time}"

L["header_bindings_pointer"] = "TTT2 3D Pointer"
L["label_bind_pointer_team"] = "Team Pointer"
L["label_bind_pointer_global"] = "Global Pointer"

L["submenu_addons_pointer_title"] = "3D Pointer"
L["header_addons_pointer"] = "General 3D Pointer Settings"
L["label_pointer_sound_enable"] = "Enable playing a sound if a new pointer is created"
L["label_pointer_global_enable"] = "Enable local rendering of global 3D pointers"
L["label_pointer_team_enable"] = "Enable local rendering of team 3D pointers"
L["label_pointer_spec_enable"] = "Enable local rendering of spectator 3D pointers"
L["help_addons_pointer"] = "By default all added pointers are rendered on the client. However the three types can be disabled individually if you don't want to see them."
L["help_addons_pointer_detail"] = [[
Global: All pointers that are added by anoyone without a team restriction.
Team: All pointers that are added by someone from your team. They have to be added as team pointers and this only works for players that aren't in the innocent team or without a team.
Spectator: All pointers that are added by spectators. They are only visible if you are also a spectator.]]

L["help_server_addons_pointer"] = "By default all pointer types can be added. However the three types can be disabled individually if you don't want to use them on your server."
L["label_pointer_render_time"] = "Time in seconds a pointer is rendered in world"
L["label_pointer_timeout"] = "Timeout in seconds per player for a new pointer"
L["label_pointer_amount_per_type"] = "Amount of pointers per player per type at once"

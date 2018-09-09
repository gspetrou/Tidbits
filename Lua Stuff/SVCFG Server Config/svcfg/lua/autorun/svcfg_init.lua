svcfg = svcfg or {}

--- Lua 5.2 Functions Available for 5.1
-- @section lua52

--- pack an argument list into a table.
-- @param ... any arguments
-- @return a table with field n set to the length
-- @return the length
-- @function table.pack
if not table.pack then
    function table.pack (...)
        return {n=select('#',...); ...}
    end
end


if SERVER then
	AddCSLuaFile("svcfg/cl_menu.lua")
	AddCSLuaFile("svcfg/sh_options.lua")

	AddCSLuaFile("svcfg/cl_imp_paneltypes.lua")
	AddCSLuaFile("svcfg/sh_imp_networkingtypes.lua")
	AddCSLuaFile("svcfg/sh_imp_globalsettings.lua")

	include("svcfg/sh_options.lua")

	include("svcfg/sh_imp_globalsettings.lua")
	include("svcfg/sh_imp_networkingtypes.lua")
else
	include("svcfg/cl_menu.lua")
	include("svcfg/sh_options.lua")

	include("svcfg/cl_imp_paneltypes.lua")
	include("svcfg/sh_imp_globalsettings.lua")
	include("svcfg/sh_imp_networkingtypes.lua")
end


--[[ Till I need it this can chill here.


-- Add our player settings menu.
do
	svcfg.AddSheet("Player Settings", "user", function(dpanel, dpanel_h)

	end)
end
]]
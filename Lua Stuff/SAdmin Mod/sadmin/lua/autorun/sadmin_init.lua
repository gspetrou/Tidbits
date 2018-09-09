sa = sa or {}

if SERVER then
	AddCSLuaFile("sadmin/sh_sadmin.lua")
	include("sadmin/sv_sadmin.lua")
end

include("sadmin/sh_sadmin.lua")
--[[
	SBlocks Init
	Created by George 'Stalker' Petrou (STEAM_0:1:18093014)
	Enjoy!
]]--

SBlocks = SBlocks or {
	-- Define block types
	BOX = 0,
	SPHERE = 1,
	CONVEX = 2,
	MULTICONVEX = 3,

	-- Define point types.
	POINT_A = 1,
	POINT_B = 2,

	Version = 20180303	-- First release!
}

AddCSLuaFile("sblocks/sh_sblocks.lua")
include("sblocks/sh_sblocks.lua")

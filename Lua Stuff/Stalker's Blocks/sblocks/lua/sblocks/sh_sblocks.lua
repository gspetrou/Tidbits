--[[
	SBlocks API
	Created by George 'Stalker' Petrou (STEAM_0:1:18093014)
	Enjoy!
]]--

--------------------------------
-- SBlocks.PointsToMinMaxCenter
--------------------------------
-- Desc:		Given two points, gets the min, max, and center point of a box that would fill the area between the points.
-- Arg One:		Vector, point A.
-- Arg Two:		Vector, point B.
-- Returns:		Vector, min of box.
-- 				Vector, max of box.
-- 				Vector, center of box.
function SBlocks.PointsToMinMaxCenter(pointA, pointB)
	local min = Vector(pointA.x, pointA.y, pointA.z)
	local max = Vector(pointB.x, pointB.y, pointB.z)
	OrderVectors(min, max)

	local center = Vector((max.x+min.x)/2, (max.y+min.y)/2, (max.z+min.z)/2)
	local centerMin = -Vector(center.x-min.x, center.y-min.y, center.z-min.z)
	local centerMax = Vector(max.x-center.x, max.y-center.y, max.z-center.z)

	return centerMin, centerMax, center
end

----------------------------------------
-- SBlocks.GetClosestArrayIndexToNumber
----------------------------------------
-- Desc:		Given an array and a number, finds the closest array index to that number.
-- Arg One:		Sequential table (array).
-- Arg Two:		Number
-- Returns:		Any, value of the array at the index closest to arg two.
function SBlocks.GetClosestArrayIndexToNumber(array, num)
	local distance = math.abs(array[1] - num)
	local index = 0
	for i, v in ipairs(array) do
		curDistance = math.abs(v - num)
		if curDistance < distance then
			index = i
			distance = curDistance
		end
	end
	return array[index]
end

if SERVER then
	util.AddNetworkString("SBlocks.SetBlockMaterial")
	util.AddNetworkString("SBlocks.InitBlockMaterials")

	-- Send newly connected players the materials of all existing SBoxes.
	hook.Add("PlayerInitialSpawn", "SBlocks.SetBlockMaterials", function(ply)
		local boxes = ents.FindByClass("stalker_sbox")
		if #boxes > 0 then
			net.Start("SBlocks.InitBlockMaterials")

			net.WriteUInt(#boxes, 8)
			for i, box in ipairs(boxes) do
				SBlocks.SendBlockMaterial(box, box:GetBlockMaterial():GetName())
			end
			net.Send(ply)
		end
	end)

	---------------------
	-- SBlocks.CreateBox
	---------------------
	-- Desc:		Creates a SBox given a min and max.
	-- Arg One:		Vector, min. Make sure this is in fact a min! You might want to use OrderVectors.
	-- Arg Two:		Vector, max. Make sure this is in fact a max! You mgiht want to use OrderVectors.
	-- Arg Three:	Boolean, should the box have physics.
	-- Returns:		Entity, stalker_sbox.
	-- Note:		If you want to actually see/interact with the box then call ent:Spawn() on it.
	function SBlocks.CreateBox(mins, maxs, havePhysics)
		local box = ents.Create("stalker_sbox")
		box:SetBlockType(SBlocks.BOX)
		box:SetMins(mins)
		box:SetMaxs(maxs)
		if havePhysics then
			box:GivePhysics()
		end

		return box
	end

	----------------------------------
	-- SBlocks.CreateBoxViaDimensions
	----------------------------------
	-- Desc:		Creates a box via the given dimension.
	-- Arg One:		Number, width of the box.
	-- Arg Two:		Number, height of the box.
	-- Arg Three:	Number, depth of the box.
	-- Arg Four:	Boolean, should the box have physics.
	-- Returns:		Entity, stalker_sbox entity.
	-- Note:		If you want to actually see/interact with the box then call ent:Spawn() on it.
	function SBlocks.CreateBoxViaDimensions(width, height, depth, havePhysics)
		local dimensions = Vector(width/2, height/2, depth/2)
		local box = ents.Create("stalker_sbox")
		box:SetBlockType(SBlocks.BOX)
		box:SetMins(-dimensions)
		box:SetMaxs(dimensions)
		if havePhysics then
			box:GivePhysics()
		end

		return box
	end

	------------------------
	-- SBlocks.CreateSphere
	------------------------
	-- Desc:		Creates a sphere.
	-- Arg One:		Number, radius of the sphere.
	-- Arg Two:		(Optional="rock") String, surface material. This is what the surface of the ball is "made of". See more options here: https://developer.valvesoftware.com/wiki/Material_surface_properties
	-- Returns:		Entity, stalker_ssphere entity.
	-- Warning:		This feature is experimental. It is VERY easy to get player/items stuck in this entity.
	-- Note:		If you want to actually see/interact with the box then call ent:Spawn() on it.
	function SBlocks.CreateSphere(r, physMat)
		local dimensions = Vector(r, r, r)
		local sphere = ents.Create("stalker_ssphere")
		sphere:SetBlockType(SBlocks.SPHERE)
		sphere:SetMins(-dimensions)
		sphere:SetMaxs(dimensions)
		sphere:SetRadius(r)
		sphere:SetPhysicsMaterial(physMat or "rock")
		
		return sphere
	end

	-----------------------------
	-- SBlocks.SendBlockMaterial
	-----------------------------
	-- Desc:		Sends an SBlock's material to the client.
	-- Arg One:		Entity, SBlock entity changing material.
	-- Arg Two:		String, material path to send.
	function SBlocks.SendBlockMaterial(ent, matStr)
		net.WriteUInt(ent:EntIndex(), 8)
		net.WriteString(matStr)
	end
end

if CLIENT then
	-- Initialize all current SBlock materials on connect.
	net.Receive("SBlocks.InitBlockMaterials", function()
		local numboxes = net.ReadUInt(8)
		for i = 1, numboxes do
			SBlocks.InitializingBlocks[net.ReadUInt(8)] = net.ReadString()
		end
	end)

	-- Receive's an entity's index and wanted material.
	SBlocks.InitializingBlocks = {}
	net.Receive("SBlocks.SetBlockMaterial", function()
		SBlocks.InitializingBlocks[net.ReadUInt(8)] = net.ReadString()
	end)

	-- Sets the SBlock's material once the block has finished initializing.
	timer.Create("SBlocks.SetBlockMaterials", 0, 0, function()
		for entIndex, matString in pairs(SBlocks.InitializingBlocks) do
			local ent = Entity(entIndex)
			if IsValid(ent) and ent.Initialized then
				ent:SetBlockMaterial(Material(SBlocks.InitializingBlocks[entIndex]))
				SBlocks.InitializingBlocks[entIndex] = nil
			end
		end
	end)

	-- Getter/Setter functions for players drawing their ghost box.
	local PLAYER = FindMetaTable("Player")
	function PLAYER:SBlocks_SetIsDrawingGhost(b) self.SBlocks_DrawingGhost = b end
	function PLAYER:SBlocks_IsDrawingGhost() return self.SBlocks_DrawingGhost end
	function PLAYER:SBlocks_SetGhostPointA(a) self.SBlocks_GhostPointA = a end
	function PLAYER:SBlocks_GetGhostPointA() return self.SBlocks_GhostPointA end
	function PLAYER:SBlocks_SetGhostPointB(b) self.SBlocks_GhostPointB = b end
	function PLAYER:SBlocks_GetGhostPointB() return self.SBlocks_GhostPointB end
	function PLAYER:SBlocks_SetGhostAngle(ang) self.SBlocks_GhostAngle = ang end
	function PLAYER:SBlocks_GetGhostAngle() return self.SBlocks_GhostAngle end
	
	-----------------------------
	-- SBlocks.DrawBoxFromPoints
	-----------------------------
	-- Desc:		Given two points, draws a box inbetween. Should only be used when one or both points are constantly changing.
	-- Arg One:		Vector, point A.
	-- Arg Two:		Vector, point B.
	-- Arg Three:	(Optional=Angle(0,0,0)) Angle, of box's rotation.
	-- Arg Four:	(Optional=white) Color, of box.
	-- Arg Five:	(Optional=false) Boolean, should we draw a wireframe?
	-- Arg Six:		(Optional=black) Color, of wireframe.
	-- Arg Seven:	(Optional=false) Boolean, to enable a debug mode which will draw a small box at point 1/2, box min/max, and box center as well.
	function SBlocks.DrawBoxFromPoints(pointA, pointB, angle, colBox, drawWire, colWire, debugMode)
		local min, max, center = SBlocks.PointsToMinMaxCenter(pointA, pointB)

		if debugMode then
			render.DrawBox(pointA, Angle(0, 0, 0), Vector(-5, -5, -5), Vector(5, 5, 5), Color(0, 255, 0), true)	-- Draw point 1
			render.DrawBox(pointB, Angle(0, 0, 0), Vector(-5, -5, -5), Vector(5, 5, 5), Color(0, 0, 255), true)	-- Draw point 2
			render.DrawBox(min, Angle(0, 0, 0), Vector(-5, -5, -5), Vector(5, 5, 5), Color(0, 0, 0), true)		-- Draw box min
			render.DrawBox(max, Angle(0, 0, 0), Vector(-5, -5, -5), Vector(5, 5, 5), Color(255, 255, 255), true)-- Draw box max
			render.DrawBox(center, Angle(0, 0, 0), Vector(-5, -5, -5), Vector(5, 5, 5), Color(255, 0, 0), true)	-- Draw box center
		end
		
		render.DrawBox(center, angle or angle_zero, min, max, colBox or color_white, true)		-- Draw box encompassing that area
		if drawWire then
			render.DrawWireframeBox(center, angle or angle_zero, min, max, colWire or color_black, true)	-- Wireframe for the box
		end
	end

	-- Will draw the ghost box while the player is drawing their box.
	hook.Add("PostDrawTranslucentRenderables", "SBlocks.DrawGhost", function()
		local ply = LocalPlayer()

		if IsValid(ply) and ply:SBlocks_IsDrawingGhost() then
			local pointA, pointB = ply:SBlocks_GetGhostPointA(), ply:SBlocks_GetGhostPointB()

			if isvector(pointA) and isvector(pointB) then
				render.SetColorMaterial()
				SBlocks.DrawBoxFromPoints(pointA, pointB, ply:SBlocks_GetGhostAngle(), Color(200, 100, 100, 100), true, Color(255, 0, 0), false)
			end
		end
	end)
end

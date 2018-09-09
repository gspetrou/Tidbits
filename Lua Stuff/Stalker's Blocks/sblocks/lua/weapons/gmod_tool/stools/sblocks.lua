--[[
	SBlocks Tool
	Created by George 'Stalker' Petrou (STEAM_0:1:18093014)
	Enjoy!
]]--

-- Define tool variables.
TOOL.Category 						= "Construction"
TOOL.Name 							= "SBlocks"
TOOL.PointA = nil
TOOL.PointB = nil

-- Convars used by tool.
TOOL.ClientConVar["frozen"] 		= 1
TOOL.ClientConVar["pitch"] 		= 0
TOOL.ClientConVar["yaw"] 		= 0
TOOL.ClientConVar["roll"] 		= 0
TOOL.ClientConVar["material"] 		= "metal2"

-- Enums used for tool stages.
TOOL.STAGE_NOPOINTS = 1
TOOL.STAGE_ONEPOINT = 2
TOOL.STAGE_TWOPOINTS = 3

cleanup.Register("sblocks") -- Get cleanups working

-- This was a problem that existed four years ago when I wrote Smart Weld and its still a problem now.
-- These don't exist in singleplayer and we need them there.
if game.SinglePlayer() then
	NOTIFY_GENERIC = 0
	NOTIFY_ERROR = 1
	NOTIFY_UNDO = 2
	NOTIFY_HINT = 3
	NOTIFY_CLEANUP = 4
end

if SERVER then
	util.AddNetworkString("SBlocks.DrawingPoint")
	util.AddNetworkString("SBlocks.StopDrawingPoint")
end

-- Set all the text for the tool and define what hints should show at what stages.
if CLIENT then
	TOOL.Information = {
		{name = "left"},
		{name = "right"},
		{name = "leftuse", stage = 2}, 
		{name = "leftuse", stage = 3},
		{name = "reload", stage = 3}
	}

	language.Add("tool.sblocks.name", "Stalker's Blocks")
	language.Add("tool.sblocks.desc", "Create walls/blocks/physics boxes out of thin air!")

	language.Add("tool.sblocks.left", "Select or update point A of the box.")
	language.Add("tool.sblocks.leftuse", "Clears current selection.")
	language.Add("tool.sblocks.right", "Select or update point B of the box.")
	language.Add("tool.sblocks.reload", "Creates the currently designed box with the given properties.")

	language.Add("tool.sblocks.frozen", "Spawn Frozen")
	language.Add("tool.sblocks.frozen.help", "Should the object spawn frozen in place.")
	language.Add("tool.sblocks.pitch", "Pitch")
	language.Add("tool.sblocks.yaw", "Yaw")
	language.Add("tool.sblocks.roll", "Roll")
	language.Add("tool.sblocks.xadd", "Additional X")
	language.Add("tool.sblocks.yadd", "Additional Y")
	language.Add("tool.sblocks.zadd", "Additional Z")
	language.Add("tool.sblocks.resetrotation", "Reset Block Rotation")

	language.Add("Undone_sblock", "Undone SBlock")
	language.Add("Cleanup_sblocks", "SBlocks")
	language.Add("Cleaned_sblocks", "SBlocks Cleared")

	net.Receive("SBlocks.DrawingPoint", function()
		local ply = LocalPlayer()
		local pointType = net.ReadUInt(2)
		local hitpos = ply:GetEyeTrace().HitPos

		if pointType == SBlocks.POINT_A then
			ply:SBlocks_SetIsDrawingGhost(true)
			ply:SBlocks_SetGhostPointA(hitpos)
			ply.SBlocks_RealSetA = true
		elseif pointType == SBlocks.POINT_B then
			ply:SBlocks_SetIsDrawingGhost(true)
			ply:SBlocks_SetGhostPointB(hitpos)
			ply.SBlocks_RealSetB = true
		end
	end)

	net.Receive("SBlocks.StopDrawingPoint", function()
		local ply = LocalPlayer()
		ply:SBlocks_SetIsDrawingGhost(false)
		ply:SBlocks_SetGhostPointA(nil)
		ply:SBlocks_SetGhostPointB(nil)
		ply.SBlocks_RealSetA = false
		ply.SBlocks_RealSetB = false
	end)

	concommand.Add("sblocks_resetrotation", function()
		local p = GetConVar("sblocks_pitch")
		local y = GetConVar("sblocks_yaw")
		local r = GetConVar("sblocks_roll")
		p:SetFloat(0.00)
		y:SetFloat(0.00)
		r:SetFloat(0.00)
	end)
end

-- Build the C Menu control panel.
function TOOL.BuildCPanel(panel)
	panel:SetName("Stalker's Blocks")

	panel:AddControl("Checkbox", {
		Label = "#tool.sblocks.frozen",
		Help = "#tool.sblocks.frozen",
		Command = "sblocks_frozen"
	})

	panel:AddControl("Slider", {
		Label = "#tool.sblocks.pitch",
		Type = "float",
		Min = "-180",
		Max = "180",
		Command = "sblocks_pitch"
	})

	panel:AddControl("Slider", {
		Label = "#tool.sblocks.yaw",
		Type = "float",
		Min = "-180",
		Max = "180",
		Command = "sblocks_yaw"
	})

	panel:AddControl("Slider", {
		Label = "#tool.sblocks.roll",
		Type = "float",
		Min = "-180",
		Max = "180",
		Command = "sblocks_roll"
	})

	panel:AddControl("Button", {
		Text = "#tool.sblocks.resetrotation",
		Command = "sblocks_resetrotation"
	})

	panel:MatSelect("sblocks_material", list.Get("OverrideMaterials"), true, 0.25, 0.25)
end

-----------------
-- TOOL.SetPoint
-----------------
-- Desc:		Sets a ghost point that can be used to create a box.
-- Arg One:		SBlocks.POINT enum. Options are SBlocks.POINT_A and SBlocks.POINT_B.
function TOOL:SetPoint(point, pos)
	if point == SBlocks.POINT_A then
		self.PointA = pos
		if CLIENT then
			local ply = self:GetOwner()
			ply:SBlocks_SetIsDrawingGhost(true)
			ply:SBlocks_SetGhostPointA(self.PointA)
		end
	elseif point == SBlocks.POINT_B then
		self.PointB = pos
		if CLIENT then
			local ply = self:GetOwner()
			ply:SBlocks_SetIsDrawingGhost(true)
			ply:SBlocks_SetGhostPointB(self.PointB)
		end
	else
		error("Invalid point type given to TOOL.SetPoint!")
	end

	if isvector(self.PointA) and isvector(self.PointB) then
		self:SetStage(self.STAGE_TWOPOINTS)
	else
		self:SetStage(self.STAGE_ONEPOINT)
	end
end

--------------------
-- TOOL.ClearPoints
--------------------
-- Desc:		Clears any selected ghost points currently set.
function TOOL:ClearPoints()
	if CLIENT then
		local ply = self:GetOwner()
		ply:SBlocks_SetIsDrawingGhost(false)
		ply:SBlocks_SetGhostPointA(nil)
		ply:SBlocks_SetGhostPointB(nil)
	end

	self.PointA = nil
	self.PointB = nil
	self:SetStage(self.STAGE_NOPOINTS)
end

---------------
-- TOOL.Notify
---------------
-- Desc:		Puts one of those annoying notifcations on the bottom right of your screen.
-- Arg One:		String, text to put.
-- Arg Two:		NOTIFY enum, icon to display next to notification.
function TOOL:Notify(text, notifyType)
	if IsFirstTimePredicted() then
		if CLIENT and IsValid(self:GetOwner()) then
			notification.AddLegacy(text, notifyType, 5)
			surface.PlaySound("buttons/button15.wav")
		elseif game.SinglePlayer() then
			self:GetOwner():SendLua("GAMEMODE:AddNotify(\"".. text .."\", ".. tostring(notifyType) ..", 5)")	-- Because singleplayer is doodoo.
			self:GetOwner():SendLua("surface.PlaySound(\"buttons/button15.wav\")")	-- Before n00bs scream "EXPLOITABLE" read it, it isn't. Also this only runs in singleplayer anyways.
		end
	end
end

if SERVER then
	----------------
	-- TOOL.MakeBox
	----------------
	-- Desc:		Makes an SBox with the tool's point A and point B.
	-- Note:		Point A and Point B have to be set before calling this.
	function TOOL:MakeBox()
		if not isvector(self.PointA) or not isvector(self.PointB) then
			error("Tried to call TOOL.MakeBox with invalid points!")
		end

		-- Get convars that will be used to modify the created box.
		local isFrozen = tobool(self:GetClientNumber("frozen"))
		local pitch = self:GetClientNumber("pitch")
		local yaw = self:GetClientNumber("yaw")
		local roll = self:GetClientNumber("roll")
		local mat = self:GetClientInfo("material")
		local ply = self:GetOwner()

		undo.Create("sblock")

			-- At long last, create our box.
			local min, max, center = SBlocks.PointsToMinMaxCenter(self.PointA, self.PointB)
			local box = SBlocks.CreateBox(min, max)
			box:SetPos(center)
			box:SetAngles(Angle(pitch, yaw, roll))
			box:Spawn()
			box:SetFrozen(isFrozen)

			box:SetBlockMaterial(Material(mat))
			net.Start("SBlocks.SetBlockMaterial")
				SBlocks.SendBlockMaterial(box, mat)
			net.Broadcast()

			if game.SinglePlayer() then
				net.Start("SBlocks.StopDrawingPoint")
				net.Send(self:GetOwner())
			end

			undo.AddEntity(box)
			cleanup.Add(ply, "sblocks", box)
			undo.SetPlayer(ply)
		undo.Finish()
	end
end

function TOOL:Holster()
	self:ClearPoints()
end

function TOOL:LeftClick(tr)
	if not IsFirstTimePredicted() then return end

	-- If they left-click then select point A.
	-- If they left-click and hold +use then clear their points.
	if self:GetOwner():KeyDown(IN_USE) then
		self:ClearPoints()
		if game.SinglePlayer() then
			net.Start("SBlocks.StopDrawingPoint")
			net.Send(self:GetOwner())
		end

		self:Notify("Selection cleared!", NOTIFY_GENERIC)
		return false
	else
		if game.SinglePlayer() then
			net.Start("SBlocks.DrawingPoint")
				net.WriteUInt(SBlocks.POINT_A, 2)
			net.Send(self:GetOwner())
		end
		self:SetPoint(SBlocks.POINT_A, tr.HitPos)
	end

	return true
end

function TOOL:RightClick(tr)
	if not IsFirstTimePredicted() then return end
	if game.SinglePlayer() then
		net.Start("SBlocks.DrawingPoint")
			net.WriteUInt(SBlocks.POINT_B, 2)
		net.Send(self:GetOwner())
	end
	self:SetPoint(SBlocks.POINT_B, tr.HitPos)
	return true
end

function TOOL:Reload()
	if not IsFirstTimePredicted() then return end
	if not isvector(self.PointA) then
		self:Notify("Point A is not valid, cannot build SBlock!", NOTIFY_ERROR)
		return
	elseif not isvector(self.PointB) then
		self:Notify("Point B is not valid, cannot build SBlock!", NOTIFY_ERROR)
		return
	end

	if SERVER then
		self:MakeBox()
	end

	self:ClearPoints()
end

-- If the player is drawing their ghost box and only one point is set then set the other to where they're looking.
function TOOL:Think()
	local ply = self:GetOwner()

	if CLIENT and ply:SBlocks_IsDrawingGhost() then
		local rotation = Angle(self:GetClientNumber("pitch"), self:GetClientNumber("yaw"), self:GetClientNumber("roll"))
		ply:SBlocks_SetGhostAngle(rotation)

		if game.SinglePlayer() then
			local A = ply:SBlocks_GetGhostPointA()
			local A_ActuallySet = ply.SBlocks_RealSetA
			local B = ply:SBlocks_GetGhostPointB()
			local B_ActuallySet = ply.SBlocks_RealSetB

			if A_ActuallySet and not B_ActuallySet then
				ply:SBlocks_SetGhostPointB(ply:GetEyeTrace().HitPos)
			elseif B_ActuallySet and not A_ActuallySet then
				ply:SBlocks_SetGhostPointA(ply:GetEyeTrace().HitPos)
			end
		else
			if not isvector(self.PointB) and isvector(self.PointA) then
				ply:SBlocks_SetGhostPointB(ply:GetEyeTrace().HitPos)
			elseif not isvector(self.PointA) and isvector(self.PointB) then
				ply:SBlocks_SetGhostPointA(ply:GetEyeTrace().HitPos)
			end
		end
	end
end
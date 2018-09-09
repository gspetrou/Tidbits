--[[
	SBlocks SBox Entity
	Created by George 'Stalker' Petrou (STEAM_0:1:18093014)
	Enjoy!

	Credit To:	Willox
	For:		Most of Initialize, GetRenderMesh, CreateMesh, TestCollision are straight copies from the gmod wiki.
]]--

AddCSLuaFile()
DEFINE_BASECLASS("base_anim")

ENT.PrintName = "SBox"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.IsSBox = true
ENT.Material = Material("metal2")
local backupMat = Material("metal2")

-----------------------
-- ENT.SetupBlockModel
-----------------------
-- Desc:		If you want to give your SBox a model then do it here.
function ENT:SetupBlockModel()
end

------------------------
-- ENT.PhysInitFunction
------------------------
-- Desc:		If you want to change how the physics for this object is defined, do it here.
function ENT:PhysInitFunction()
	self:PhysicsInitBox(self:GetMins(), self:GetMaxs())
end

-----------------
-- ENT.SetFrozen
-----------------
-- Desc:		If you want to freeze the sbox do it with this.
-- Arg One:		Boolean, should the sbox be or not be frozen.
function ENT:SetFrozen(bool)
	self:GetPhysicsObject():EnableMotion(not bool)
	self.SBlock_Frozen = bool
end

----------------
-- ENT.IsFrozen
----------------
-- Desc:		Sees if the sbox is currently frozen.
-- Returns:		Boolean, is the box frozen.
function ENT:IsFrozen()
	return self.SBlock_Frozen or false
end

------------------------
-- ENT.SetBlockMaterial
------------------------
-- Desc:		Sets the material of the block.
-- Arg One:		IMaterial, material.
-- Note:		Make sure this is called clientside and after the box finishes intiating.
function ENT:SetBlockMaterial(mat)
	self.Material = mat
end

------------------------
-- ENT.GetBlockMaterial
------------------------
-- Desc:		Gets the current material of the block.
-- Returns:		IMaterial, current block material.
function ENT:GetBlockMaterial()
	return self.Material
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "BlockType")
	self:NetworkVar("Vector", 0, "Mins")	-- Must be shared for prediction.
	self:NetworkVar("Vector", 1, "Maxs")	-- Must be shared for prediction.
end

function ENT:Initialize()
	self.PhysCollide = CreatePhysCollideBox(self:GetMins(), self:GetMaxs())
	self:SetCollisionBounds(self:GetMins(), self:GetMaxs())

	if SERVER then
		self:PhysInitFunction()
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysWake()
	end

	if CLIENT then
		self:CreateMesh()
		self:CreateMatrix()
		self:SetRenderBounds(self:GetMins(), self:GetMaxs())
	end

	self:EnableCustomCollisions(true)
	self:DrawShadow(false)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetupBlockModel()
	self.Initialized = true
end

-- Used for getting lighting to work.
function ENT:GetRenderMesh()
	return {
		Mesh = self.Mesh,
		Material = self:GetBlockMaterial(),
		--Matrix = self.Matrix Till I get scaling working
	}
end

function ENT:CreateMatrix()
	self.Matrix = Matrix{
		{5, 5, 5, 5},
		{5, 5, 5, 5},
		{5, 5, 5, 5},
		{5, 5, 5, 5}
	}
end

-- Mesh used to get lighting to work.
function ENT:CreateMesh()
	self.Mesh = Mesh()

	local positions = {
		Vector(-0.5, -0.5, -0.5),
		Vector(0.5, -0.5, -0.5),
		Vector(-0.5, 0.5, -0.5),
		Vector(0.5,	0.5, -0.5),
		Vector(-0.5, -0.5, 0.5),
		Vector(0.5, -0.5, 0.5),
		Vector(-0.5, 0.5, 0.5),
		Vector(0.5,	0.5, 0.5)
	}

	local indices = {
		1, 7, 5,
		1, 3, 7,
		6, 4, 2,
		6, 8, 4,
		1, 6, 2,
		1, 5, 6,
		3, 8, 7,
		3, 4, 8,
		1, 4, 3,
		1, 2, 4,
		5, 8, 6,
		5, 7, 8
	}

	local normals = {
		Vector(-1, 0, 0),
		Vector(1, 0, 0),
		Vector(0, -1, 0),
		Vector(0, 1, 0),
		Vector(0, 0, -1),
		Vector(0, 0, 1)
	 }

	local tangents = {
		{0, 1, 0, -1},
		{0, 1, 0, -1},
		{0, 0, 1, -1},
		{1, 0, 0, -1},
		{1, 0, 0, -1},
		{0, 1, 0, -1}
	}

	-- Credits to JVS and Willox for these two tables.
	-- Our texture is a 4x4 grid, divide by 4 so that 1 source unit = 1 texture unit.
	/*local w, h, d = self:GetScaleY()/4, self:GetScaleZ()/4, self:GetScaleX()/4
	local uCoords = {
		0, w, 0,
		0, w, w,
		0, w, 0,
		0, w, w,
		0, h, 0,
		0, h, h,
		0, d, 0,
		0, d, d,
		0, d, 0,
		0, d, d,
		0, w, 0,
		0, w, w
	}

	local vCoords = {
		0, h, h,
		0, 0, h,
		0, h, h,
		0, 0, h,
		0, d, d,
		0, 0, d,
		0, h, h,
		0, 0, h,
		0, w, w,
		0, 0, w,
		0, d, d,
		0, 0, d
	}*/

	-- Till I get scaling working this will do.
	local uCoords = {
		0, 1, 0,
		0, 1, 1,
		0, 1, 0,
		0, 1, 1,
		0, 1, 0,
		0, 1, 1,
		0, 1, 0,
		0, 1, 1,
		0, 1, 0,
		0, 1, 1,
		0, 1, 0,
		0, 1, 1,
	 }

	local vCoords = {
		0, 1, 1,
		0, 0, 1,
		0, 1, 1,
		0, 0, 1,
		0, 1, 1,
		0, 0, 1,
		0, 1, 1,
		0, 0, 1,
		0, 1, 1,
		0, 0, 1,
		0, 1, 1,
		0, 0, 1,
	 }

	local verts = {}
	local scale = self:GetMaxs() - self:GetMins()

	for vert_i = 1, #indices do
		local face_i = math.ceil(vert_i/6)

		verts[vert_i] = {
			pos = positions[indices[vert_i]] * scale,
			normal = normals[face_i],
			u = uCoords[vert_i],
			v = vCoords[vert_i],
			userdata = tangents[face_i]
		}
	end

	self.Mesh:BuildFromTriangles(verts)
end

-- Handles collisions against traces. This includes player movement.
function ENT:TestCollision(startpos, delta, isbox, extents)
	if not IsValid(self.PhysCollide) then
		return
	end

	-- TraceBox expects the trace to begin at the center of the box, but TestCollision is bad
	local max = extents
	local min = -extents
	max.z = max.z - min.z
	min.z = 0

	local hit, norm, frac = self.PhysCollide:TraceBox(self:GetPos(), self:GetAngles(), startpos, startpos + delta, min, max)
	if not hit then
		return
	end

	return {
		HitPos = hit,
		Normal = norm,
		Fraction = frac,
	}
end

-- Some SBlocks use a clientside model, make sure it gets deleted.
function ENT:OnRemove()
	if CLIENT and IsValid(self.CSModel) then
		self.CSModel:Remove()
	end
end
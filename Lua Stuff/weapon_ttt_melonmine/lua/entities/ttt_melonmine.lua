if SERVER then
	AddCSLuaFile()
end

ENT.Type	= "anim"
ENT.Model	= Model("models/props_junk/watermelon01.mdl")

ENT.CanHavePrints	= true
ENT.Avoidable		= true	-- Could they have avoided death (for karma).
ENT.CanUseKey		= false	-- Can they pick it up with E.

if CLIENT then
	ENT.PrintName		= "Melon Mine"
	ENT.Icon			= "lks/icon_lks_melonmine.png"

	ENT.TargetIDHint = {
		name = "Melon Mine",
		hint = "Shoot to explode.",
	}
end

ENT.Melon_Health = 200
ENT.Melon_Damage = 170
ENT.Melon_Radius = 200

------------------------------------------------------------------------------
AccessorFuncDT(ENT, "armed", "Armed")
AccessorFuncDT(ENT, "exploding", "Exploding")
AccessorFuncDT(ENT, "face", "Face")
function ENT:SetupDataTables()
	self:DTVar("Bool", 0, "armed")
	self:DTVar("Bool", 1, "exploding")
	self:DTVar("String", 0, "face")
end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetColor(Color(207, 137, 90))

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:PrecacheGibs()
	end
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:DrawShadow(false)
	self:SetHealth(self.Melon_Health)

	self:SetArmed(false)
	self:SetExploding(false)

	self.Melon_RadiusSquare = math.pow(self.Melon_Radius, 2)

	-- So we only need to get these values once.
	self.Pos = self:GetPos()
	self.Angs = self:GetAngles()
	if CLIENT then
		local anglefix = Vector(0, 270, 0)
		self.FaceAngles = self.Angs
		self.FaceAngles:RotateAroundAxis(self.FaceAngles:Right(), anglefix.x)
		self.FaceAngles:RotateAroundAxis(self.FaceAngles:Up(), anglefix.y)
		self.FaceAngles:RotateAroundAxis(self.FaceAngles:Forward(), anglefix.z)
		self.FacePos = self.Pos + (self:GetUp() * 8) + (self:GetForward() * 6.7)
	end

	if IsFirstTimePredicted() then
		timer.Simple(.02, function()
			if IsValid(self) then
				local effect = EffectData()
					effect:SetOrigin(self.Pos)
					effect:SetMagnitude(1)
					effect:SetScale(.5)
					effect:SetRadius(2)
				util.Effect("cball_explode", effect)
			end
		end)
	end

	timer.Simple(3, function()
		if IsValid(self) then
			if SERVER then
				self:SetFace(self.Face)
			end
			self:SetArmed(true)
		end
	end)
end

function ENT:Think()
	if not self:GetArmed() then
		return
	end

	local d = 0.0
	local diff = 0

	for i, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Team() == TEAM_TERROR then
			local plypos = ply:GetPos()
			diff = self.Pos - plypos
			d = diff:Dot(diff)

			if d <= self.Melon_RadiusSquare then	-- The square of ENT.Melon_Radius.
				local rags = ents.FindByClass("prop_ragdoll")	-- Dont hit ragdolls or self.
				table.insert(rags, self)

				local tr = util.TraceLine({
					start = self.Pos,
					endpos = plypos + Vector(0, 0, 60),
					filter = rags	-- Dont hit self or ragdolls on the map
				})

				if not self:GetExploding() and IsValid(tr.Entity) and tr.Entity == ply then
					self:SetExploding(true)
					timer.Create("melonmine_beeps", 0.1, 8, function()
						if IsValid(self) then
							self:EmitSound("weapons/c4/c4_beep1.wav")
						end
					end)
					timer.Simple(0.9, function()
						if IsValid(self) then
							self:Explode(ply)
						end
					end)
				end
			end
		end
	end
end

function ENT:Explode(victim)
	if IsFirstTimePredicted() then
		self:GibBreakClient(vector_origin)
	end

	if SERVER then
		self:SetNoDraw(true)
		self:SetSolid(SOLID_NONE)

		local pos = self.Pos
		if pos.z < (victim:GetPos().z + 50)  then
			pos.z = pos.z + 30
		end

		local dmgowner = self:GetOwner()
		if not IsValid(dmgowner) then
			dmgowner = self
		end

		local dmginfo = DamageInfo()
			dmginfo:SetDamage(self.Melon_Damage)
			dmginfo:SetAttacker(dmgowner)
			dmginfo:SetInflictor(self)
			dmginfo:SetDamageType(DMG_BLAST)
			dmginfo:SetDamageForce(pos - self.Pos)
			dmginfo:SetDamagePosition(self.Pos)
		
		-- explosion damage
		util.BlastDamageInfo(dmginfo, self.Pos, self.Melon_Radius)
		sound.Play("explode_4", self.Pos, 130, 100)
		  
		local effect = EffectData()
			effect:SetStart(pos)
			effect:SetOrigin(pos)
			effect:SetScale(self.Melon_Radius)
			effect:SetRadius(self.Melon_Radius)
			effect:SetMagnitude(self.Melon_Damage)
			effect:SetOrigin(pos)
		util.Effect("Explosion", effect, true, true)
		util.Effect("HelicopterMegaBomb", effect, true, true)
		
		-- extra push
		local phexp = ents.Create("env_physexplosion")
		phexp:SetPos(pos)
		phexp:SetKeyValue("magnitude", self.Melon_Damage)
		phexp:SetKeyValue("radius", self.Melon_Radius)
		phexp:SetKeyValue("spawnflags", "19")
		phexp:Spawn()
		phexp:Fire("Explode", "", 0)

		timer.Simple(1, function()
			if IsValid(self) then
				self:Remove()
			end
		end)
	end
end

-- I don't want any movement out of you!
function ENT:PhysicsUpdate(phys)
	phys:EnableMotion(false)
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		local face = self:GetFace()

		cam.Start3D2D(self.FacePos, self.FaceAngles, .18)
			draw.SimpleText(face == "" and "-.-" or face, "melon_text", 0, 0, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		cam.End3D2D()
	end
end

if SERVER then
	function ENT:OnTakeDamage(dmginfo)
		self:SetHealth(self:Health() - dmginfo:GetDamage())

		local attacker = dmginfo:GetAttacker()
		if IsValid(attacker) then
			dmginfo:SetInflictor(attacker)
		end

		if self:Health() <= 0 then
			local effect = EffectData()
			effect:SetOrigin(self.Pos)
			util.Effect("cball_explode", effect)

			sound.Play("npc/assassin/ball_zap1.wav", self.Pos)
			self:GibBreakClient(vector_origin)

			if IsValid(self:GetOwner()) then
				TraitorMsg(self:GetOwner(), "YOUR MINE HAS BEEN DESTROYED!")
			end

			self:Remove()
		end
	end
end

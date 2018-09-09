-- Nabs the rank file and returns it as a table.
function sa.GetRankFile()
	return von.deserialize(util.Decompress(file.Read("sadmin/groups.txt", "DATA")))
end

-- Takes the sa.PlayerRanks table, converts it to a string with vON, compresses it, then writes it to the file.
function sa.UpdateRankFile()
	file.Write("sadmin/groups.txt", util.Compress(von.serialize(sa.PlayerRanks)))
end

-- Sets the rank of the user if they are offline.
function sa.SetUserGroupOffline(steamid, rank)
	sa.PlayerRanks[steamid] = rank

	sa.sa.UpdateRankFile()
end

-- Gets the rank of the user if they are offline.
function sa.GetUserGroupOffline(steamid)
	return sa.PlayerRanks[steamid]
end

-- Does the rank exist?
function sa.RankExists(rank)
	if not type(rank) == "string" then
		return false
	end

	local AllRanks = {}
	for k, v in pairs(sa.Ranks) do
		for j, d in pairs(v) do
			table.insert(AllRanks, d)
		end
	end

	for i = 1, #AllRanks do
		if AllRanks[i] == rank then
			return true
		end
	end

	return false
end

local META = FindMetaTable("Player")
if not META then return end

-- Overrided SetUserGroup to use our own system. The second boolean true by default.
-- Making it false will make the change not carry over next map.
function META:SetUserGroup(group, ShouldWrite)
	self:SetNWString("UserGroup", group)
	
	if ShouldWrite or ShouldWrite == nil then
		sa.PlayerRanks[self:SteamID()] = group

		sa.UpdateRankFile()
	end
end

-- Are they admin.
function META:InSuperAdminSection()
	if self:IsLegit() then
		local rank = self:GetUserGroup() or "user"

		for i = 1, #sa.Ranks[PERM_SUPERADMIN] do
			if rank == sa.Ranks[PERM_SUPERADMIN][i] then
				return true
			end
		end
	end

	return false
end

-- Are they superadmin.
function META:InAdminSection()
	if self:IsLegit() then
		local rank = self:GetUserGroup() or "user"

		for i = 1, #sa.Ranks[PERM_ADMIN] do
			if rank == sa.Ranks[PERM_ADMIN][i] then
				return true
			end
		end
	end

	return false
end

-- Do they have the rights of an admin or superadmin.
function META:HasAdminRights()
	return self:PlyInAdminSection() or self:PlyInSuperAdminSection()
end

-- Since ranks have value numbers get their number.
function META:GetRankValue()
	if self:IsLegit() then
		local rank = self:GetUserGroup() or "user"

		for k, v in pairs(sa.Ranks) do
			for i, j in ipairs(v) do
				if j == rank then
					return k
				end
			end
		end
	end
	
	return 0
end

-- Do they have permission in the hiarchy.
function META:MeetsNeededPermission(PERM)
	return self:GetRankValue() >= PERM
end

-- Are they correctly verified.
function META:IsLegit()
	return self:IsValid() and self:IsPlayer() and self:IsFullyAuthenticated()
end

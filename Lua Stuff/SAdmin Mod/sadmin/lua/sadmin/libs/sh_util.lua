-- Checks if two string match or almost match.
function sa.StringMatches(a, b)
	return (string.lower(a) == string.lower(b)) or string.find(string.lower(a), string.lower(b), nil, true)
end

--Finds a player by their name.
function sa.FindPlayerByName(name)
	for k, v in pairs(player.GetAll()) do
		if sa.StringMatches(v:Nick(), name) then
			return v
		end
	end

	return false
end

-- Removes duplicate objects in a table.
function sa.RemoveTableDuplicates(InputTable)
	local OutputTable = {}
	local hash = {}

	for k, v in pairs(InputTable) do
		if not hash[v] then
			hash[v] = true
			table.insert(OutputTable, v)
		end
	end

	return OutputTable
end

-- Removes holes in a table and makes it numeric.
function sa.RemoveTableHoles(InputTable)
	local OutputTable = {}
	local i = 1

	for k, v in pairs(InputTable) do
		OutputTable[i] = v
		i = i + 1
	end

	return OutputTable
end

-- Is the gamemode Trouble in Terrorist Town.
function sa.IsTTT()
	return engine.ActiveGamemode() == "terrortown"
end

-- Returns the number of the current round or -1 if the gamemode isn't TTT
function sa.CurrentRoundNumber()
	if sa.IsTTT() then
		return GetConVar("ttt_round_limit"):GetInt()-math.max(0, GetGlobalInt("ttt_rounds_left", 6))
	end

	return -1
end

-- Checks if the player is actually dead. TTT is stupid.
function sa.PlayerActuallyAlive(ply)
	if not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) then return false end

	if sa.IsTTT() then
		if ply:IsSpec() or ply:Team() == TEAM_SPEC or ply:Team() == TEAM_SPECTATOR then
			return false
		end
	end

	return true
end

-- Converts a table of strings to one big string
function sa.TableOfStringsToLine(tbl)
	local output = ""
	for k, v in pairs(tbl) do
		output = output.." "..v
	end

	return string.sub(output, 2)
end

net.Receive("SendToPlyChat", function()
	local RawChatText = net.ReadTable()
	
	chat.AddText(unpack(RawChatText))
end)

net.Receive("SendToPlyConsole", function()	
	print(net.ReadString())
end)
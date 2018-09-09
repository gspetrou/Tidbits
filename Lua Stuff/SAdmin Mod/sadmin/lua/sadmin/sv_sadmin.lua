include("sadmin/von.lua")
include("sadmin/sv_config.lua")

-- Sets up player chats. If you're an admin and do /cmdname it wont echo in chat.
hook.Add("PlayerSay", "SA_CheckForSAdminCommand", function(ply, text)
	if text[1] == "!" or text[1] == "/" then
		local cmd = string.sub(text, 2)
		local posofspace = string.find(cmd, " ", 1, false)
		local cmdname = posofspace and string.sub(cmd, 1, posofspace-1) or cmd

		if sa.Commands[cmdname] then
			ply:ConCommand("sa "..cmd)

			if text[1] == "/" and ply:InSuperAdminSection() then
				return ""
			end
		end

		return text
	end
end)

hook.Add("Initialize", "SA_CreateDataFiles", function()
	-- Disables Gmod's built in rank system.
	hook.Remove("PlayerInitialSpawn", "PlayerAuthSpawn")

	-- Creates a groups file if none exists.
	if not file.Exists("sadmin/groups.txt", "DATA") then
		sa.PlayerRanks = {["BOT"] = "admin"}
		sa.UpdateRankFile()
	end
	
	-- Read the ranks from the file once at the start of a new map.
	sa.PlayerRanks = sa.GetRankFile()

	-- Create an empty log file if none already exists.
	if not file.Exists("sadmin/log.txt", "DATA") then
		file.Write("sadmin/log.txt", "")
	end
end)

hook.Add("PlayerAuthed", "SA_SetRankOnJoin", function(ply, steamid)
	-- If the player never joinned before set them to the default rank and reflect this change to the file.
	if not sa.PlayerRanks[steamid] then
		sa.PlayerRanks[steamid] = sa.DefaultRank

		sa.UpdateRankFile()
		ply:SetUserGroup(sa.PlayerRanks[steamid])
	else
	-- They already have a rank so set them to it and no need to update the rank file.
		ply:SetUserGroup(sa.PlayerRanks[steamid], false)
	end
end)

-- One of the earliest called hooks for when a player joins. Used checking bans.
--[[ Ban table structure:
[steamid64]:
	time,
	reason
]]
hook.Add("CheckPassword", "testicl", function(steamid64)
	print(steamid64)
end)
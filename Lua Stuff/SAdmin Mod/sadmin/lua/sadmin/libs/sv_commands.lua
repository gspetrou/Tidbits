if SERVER then
	util.AddNetworkString("SendCommand")

	-- Called when a player tried to run a command
	net.Receive("SendCommand", function(len, caller)
		if IsValid(caller) then
			local command, targets, arguements = sa.ProcessCommand(net.ReadTable(), caller)
			sa.RunCommandForClient(command, targets, arguements, caller)
		end
	end)

	-- Checks if it is allowed to and if it is it runs the command. Don't call directly.
	function sa.RunCommand(caller, command, target, arguements)
		if sa.Commands[command].hastarget then
			for i = 1, #target do
				if not IsValid(target[i]) then
					return false
				end
			end
		end

		sa.Commands[command]:Run(caller, arguements, target)

		return true
	end

	-- Call when the client wants to run a command. Calls RunCommand.
	-- Only different (as of now) between this and RunCommandForServer is the prints.
	function sa.RunCommandForClient(command, target, arguements, caller)
		if not sa.PreCommandChecks(command, target, arguements, caller) then
			return
		end

		if not caller:MeetsNeededPermission(sa.Commands[command].permission) then
			sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", color_white, "You aren't allowed to run that command!")

			local targs = target and sa.TellCallerTargetString(target, caller) or "NO TARGS"
			targs = targs == "yourself" and caller:Nick() or targs

			local args = arguements and sa.TableOfStringsToLine(arguements) or "NO ARGS"
			args = args == "" and "NO ARGS" or args

			sa.WriteToLogs(caller:Nick().." ran '"..command.."' on '"..targs.."' with the args: '"..args.."'\nThey are not allowed to!")
			return
		end

		local successful = sa.RunCommand(caller, command, target, arguements)

		if successful then
			sa.LogCommand(command, target, arguements, caller)
		else
			sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", color_white, "Command Failed!")
		end
	end

	-- Call when the server wants to run a command. Calls RunCommand.
	function sa.RunCommandForServer(command, target, arguements)
		if not sa.PreCommandChecks(command, target, arguements) then
			return
		end

		local successful = sa.RunCommand(nil, command, target, arguements)

		if successful then
			sa.LogCommand(command, target, arguements)
		else
			MsgC(sa.Colors.servertag, "[SAdmin] ", color_white, "Command Failed!\n")
		end
	end

	-- If caller is not nil this assumes the client called it.
	-- Returns false if we shouldn't run the command.
	function sa.PreCommandChecks(command, target, arguements, caller)
		if command == "nothing" then
			return false
		end

		if not sa.Commands[command] then
			if caller then
				sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", color_white, "Invalid Command!")
			else
				MsgC(sa.Colors.servertag, "[SAdmin] ", color_white, "Invalid Command!\n")
			end

			return false
		end

		if sa.Commands[command].hastarget and (target == nil or #target < 1) then
			if caller then
				sa.NotifyCaller(caller, sa.Colors.clienttag ,"[SAdmin] ", color_white, "Invalid Target!")
			else
				MsgC(sa.Colors.servertag, "[SAdmin] ", color_white, "Invalid Target!\n")
			end

			return false
		end

		return true
	end

	-- Converts a raw command to a command, target, and arguements.
	-- The second field is only required if a client called the command.
	function sa.ProcessCommand(RawCommand, caller)
		if #RawCommand == 0 then 
			return "nothing"
		end

		local command = false

		for k, v in pairs(sa.Commands) do
			if RawCommand[1] == k then
				command = RawCommand[1]
			end
		end

		if not command then
			return
		end

		if not sa.Commands[command].hastarget then
			local arguements = {}
			for i = 2, #RawCommand do
				table.insert(arguements, RawCommand[i])
			end

			return command, nil, arguements
		end

		-- Time to find the target
		local RawTarget = RawCommand[2]

		if not RawTarget then
			return command
		end

		local target = false
		
		if caller and RawTarget == "^" then
			target = {caller}
		elseif RawTarget == "*" then
			target = player.GetAll()
		elseif RawTarget == "!" then
			if caller then
				local AllButMe, AllPlayers = {}, player.GetAll()

				for i = 1, #AllPlayers do
					if AllPlayers[i] == caller then
						continue
					end
					table.insert(AllButMe, AllPlayers[i])
				end

				target = AllButMe
			else
				target = player.GetAll() 
			end
		elseif sa.FindPlayerByName(RawTarget) then
			target = {sa.FindPlayerByName(RawTarget)}
		elseif player.GetBySteamID(RawTarget) then
			target = {player.GetBySteamID(RawTarget)}
		elseif player.GetBySteamID64(RawTarget) then
			target = {player.GetBySteamID64(RawTarget)}
		elseif string.lower(RawTarget) == "b" then
			target = player.GetBots()
		elseif string.lower(RawTarget) == "h" then
			target = player.GetHumans()
		elseif string.lower(RawTarget) == "y" and caller then
			local tr = caller:GetEyeTraceNoCursor()
			if tr.Entity and tr.Entity:IsPlayer() then
				target = {tr.Entity}
			end
		elseif string.lower(RawTarget) == "a" then
			local AlivePlayers = {}

			for k, v in pairs(player.GetAll()) do
				if sa.PlayerActuallyAlive(v) then
					table.insert(AlivePlayers, v)
				end
			end

			target = AlivePlayers
		end

		if not target then
			return command
		end

		if #RawCommand == 2 then -- No args. Just command and target
			return command, target
		end

		-- Anything bellow here has arguements as well
		local arguements = {}
		for i = 1, #RawCommand do
			arguements[i] = RawCommand[i+2]
		end

		return command, target, arguements
	end
end
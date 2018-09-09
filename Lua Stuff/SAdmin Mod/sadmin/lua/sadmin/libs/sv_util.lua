util.AddNetworkString("SendToPlyChat")
util.AddNetworkString("SendToPlyConsole")

-- Prints to the chat of the calling player.
function sa.NotifyCaller(caller, ...)
	local ChatArgs = {...}

	if IsValid(caller) then
		net.Start("SendToPlyChat")
			net.WriteTable(ChatArgs)
		net.Send(caller)
	else
		print("Invalid Player in sa.NotifyCaller")
	end
end

-- Prints the text to the caller.
function sa.PrintToCaller(caller, text)
	if IsValid(caller) then
		net.Start("SendToPlyConsole")
			net.WriteString(text)
		net.Send(caller)
	else
		print("Invalid Player in sa.PrintToCaller")
	end
end

-- Returns a string of the players who were targetted to the calling player.
-- You don't have to onclude caller if this command is ran for the server.
function sa.TellCallerTargetString(targets, caller)
	local OutputString = ""

	if targets == player.GetAll() then
		OutputString = "everyone"
	elseif #targets == 1 then
		if IsValid(targets[1]) then
			if IsValid(caller) then
				OutputString = caller == targets[1] and "yourself" or targets[1]:Nick()
			else
				OutputString = targets[1]:Nick()
			end
		else
			OutputString = "a NULL Player"
		end
	elseif targets == player.GetBots() then
		OutputString = "the bots"
	elseif targets == player.GetHumans() then
		OutputString = "all of the human players"
	elseif #targets > 2 then
		local AlivePlayers = {}

		for k, v in pairs(player.GetAll()) do
			if sa.PlayerActuallyAlive(v) then
				table.insert(AlivePlayers, v)
			end
		end

		if targets == AlivePlayers then
			OutputString = "all of the alive players"
		else
			for i = 1, #targets do
				if IsValid(targets[i]) then
					local name = targets[i]:Nick()

					if i == #targets - 1 then
						OutputString = OutputString..name..", and "
					else
						OutputString = OutputString..name..", "
					end
				end
			end
			OutputString = string.sub(OutputString, 0, #OutputString-2)
		end
	else
		if IsValid(targets[1] and targets[2]) then
			OutputString = targets[1]:Nick().." and "..targets[2]:Nick()
		end
	end

	return OutputString
end

-- Called when a command is ran to log it.
function sa.LogCommand(command, target, arguements, caller)
	local CallerName = caller and caller:Nick() or "[_SERVER_]"
	local TimeCaller = os.date("[%d/%m/%Y] - [%X]", os.time()).."\nCalled By: "..CallerName
	local CommandString = "Command: "..command.."\nArgs: "..(arguements and sa.TableOfStringsToLine(arguements) or "No Arguements")
	local TargetName = sa.TellCallerTargetString(target, caller)
	TargetName = "yourself" == TargetName and caller:Nick() or TargetName
	TargetName = "Targets: "..TargetName

	local map = "Map: "..game.GetMap()..", Round: "..sa.CurrentRoundNumber()

	file.Append("sadmin/log.txt", TimeCaller.."\n"..CommandString.."\n"..TargetName.."\n"..map.."\n\n")
end

-- Prints the text to the logs.
-- Don't add in line breaks, they are already added.
function sa.WriteToLogs(text)
	local time = os.date("[%d/%m/%Y] - [%X]", os.time())

	file.Append("sadmin/log.txt", time.."\nMESSAGE TO LOGS:\n"..text.."\n\n")
end
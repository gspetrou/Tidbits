if CLIENT then
	-- Sends the command to the server for verification and use.
	function sa.SendCommand(RawCommand)
		net.Start("SendCommand")
			net.WriteTable(RawCommand)
		net.SendToServer()
	end
end

-- A simple wrapper function
function sa.RegisterCommand(COMMAND)
	sa.Commands[COMMAND.name] = COMMAND
end

local function CommandTask(ply, cmd, args, ArgString)
	if not args[1] then
		print("USAGE: sa <command> <targets> <arguements>")
	end

	if CLIENT then
		sa.SendCommand(args)
	else
		local command, targets, arguements = sa.ProcessCommand(args)
		sa.RunCommandForServer(command, targets, arguements)
	end
end

local function CommandAutoComplete(cmd, args)
	local ResultTable = {}
	for k, v in pairs(sa.Commands) do
		table.insert(ResultTable, "sa "..k)
	end

	return ResultTable
end
concommand.Add("sa", CommandTask, CommandAutoComplete, "Stalker's Simple Admin Mod\n - USAGE: sa <command> <targets> <arguements>")
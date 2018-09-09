local COMMAND 		= {}							-- To store the command's info.
COMMAND.name		= "slay"						-- The actual name of the command.
COMMAND.fancyname	= "Slay"						-- Pretty name of the command.
COMMAND.desc		= "Slays the given targets."	-- Description.
COMMAND.hastarget	= true							-- Does the command target someone. True by default.
COMMAND.notifyinchat = true							-- Should we tell the player in chat if it was succesfully called. True by defaul.
COMMAND.permission	= PERM_ADMIN					-- Permission needed to run the command. Can be PERM_USER, PERM_ADMIN, and PERM_SUPERADMIN.
function COMMAND:Run(caller, arguements, targets)	-- Function to run when the command is ready to be ran.
	for i = 1, #targets do							-- targets is always a table and always checked for validity.
		targets[i]:Kill()							-- No need for permission checks and such, they are already done.
	end

	if caller then
		sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", sa.Colors.clientcaller, "You ", color_white, "slayed ", sa.Colors.targetpurple, sa.TellCallerTargetString(targets), color_white, ".")
	else
		MsgC(sa.Colors.servertag, "[SAdmin] ", sa.Colors.servercaller, "You ", color_white, "slayed ", sa.Colors.targetpurple, sa.TellCallerTargetString(targets), color_white, ".\n")
	end
end
sa.RegisterCommand(COMMAND)							-- Registers the command.

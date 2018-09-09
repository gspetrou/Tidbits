////////////////
///// Kick /////
////////////////
local COMMAND 		= {}
COMMAND.name		= "kick"
COMMAND.fancyname	= "Kick"
COMMAND.desc		= "Kicks the given targets."
COMMAND.hastarget	= true
COMMAND.notifyinchat = true
COMMAND.permission	= PERM_ADMIN
function COMMAND:Run(caller, arguements, targets)
	local reason = "No reason given"

	if arguements then
		reason = sa.TableOfStringsToLine(arguements)
	end

	local name = caller and caller:Nick() or "ROOT"
	for i = 1, #targets do
		targets[i]:Kick("You have been kicked by "..name..".\nReason: "..reason)
	end

	if caller then
		sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", sa.Colors.clientcaller, "You ", color_white, "kicked ", sa.Colors.targetpurple, sa.TellCallerTargetString(targets), color_white, " for the reason: "..reason..".")
	else
		MsgC(sa.Colors.servertag, "[SAdmin] ", sa.Colors.servercaller, "You ", color_white, "kicked ", sa.Colors.targetpurple, sa.TellCallerTargetString(targets), color_white, " for the reason: "..reason..".\n")
	end
end
sa.RegisterCommand(COMMAND)


//////////////////////////
///// Set User Group ///// -- NOT DONE
//////////////////////////
COMMAND 			= {}
COMMAND.name		= "setrank"
COMMAND.fancyname	= "Set Rank"
COMMAND.desc		= "Sets the ranks of the given targets."
COMMAND.hastarget	= true
COMMAND.notifyinchat = true
COMMAND.permission	= PERM_SUPERADMIN
function COMMAND:Run(caller, arguements, targets)
	local rank = "user"
	if arguements and sa.RankExists(arguements[1]) then
		rank = arguements[1]
	else
		if caller then
			sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", color_white, "Invalid rank!")
		else
			MsgC(sa.Colors.servertag, "[SAdmin] ", color_white, "Invalid rank!\n")
		end
		return
	end

	for i = 1, #targets do
		targets[i]:SetUserGroup(rank, false) -- Lets not update it every time through.
	end
	sa.UpdateRankFile()


	if caller then
		sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", sa.Colors.clientcaller, "You ", color_white, "set the rank of ", sa.Colors.targetpurple, sa.TellCallerTargetString(targets), color_white, " to: "..rank..".")
	else
		MsgC(sa.Colors.servertag, "[SAdmin] ", sa.Colors.servercaller, "You ", color_white, "set the rank of ", sa.Colors.targetpurple, sa.TellCallerTargetString(targets), color_white, " to: "..rank..".\n")
	end
end
sa.RegisterCommand(COMMAND)


///////////////////////////////////
///// Set User Group (Offline)/////
///////////////////////////////////
COMMAND 			= {}
COMMAND.name		= "setrank_offline"
COMMAND.fancyname	= "Set Rank (Offline)"
COMMAND.desc		= "Sets the ranks of the given target if they are offline."
COMMAND.hastarget	= false
COMMAND.notifyinchat = true
COMMAND.permission	= PERM_SUPERADMIN
function COMMAND:Run(caller, arguements, targets)
	if arguements[1] and sa.StringMatches("STEAM_0:", arguements[1]) then
		if #arguements == 2 then
			sa.SetUserGroupOffline(arguements[1], arguements[2])
		else
			if caller then
				sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", color_white, "Too many arguements!")
			else
				MsgC(sa.Colors.servertag, "[SAdmin] ", color_white, "Too many arguements!\n")
			end
		end

		if caller then
			sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", sa.Colors.clientcaller, "You ", color_white, "set the offline rank of ", sa.Colors.targetpurple, sa.TellCallerTargetString(targets), color_white, ".")
		else
			MsgC(sa.Colors.servertag, "[SAdmin] ", sa.Colors.servercaller, "You ", color_white, "set the offline rank of ", sa.Colors.targetpurple, sa.TellCallerTargetString(targets), color_white, ".\n")
		end
	elseif caller then
		sa.NotifyCaller(caller, sa.Colors.clienttag, "[SAdmin] ", color_white, "Too many arguements!")
	else
		MsgC(sa.Colors.servertag, "[SAdmin] ", color_white, "Too many arguements!\n")
	end
end
sa.RegisterCommand(COMMAND)
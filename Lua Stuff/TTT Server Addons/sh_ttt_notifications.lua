if SERVER then
	util.AddNetworkString("WhoKilledYou")

	hook.Add("TTTBeginRound", "TraitorCountDisplay", function()
		timer.Simple(1, function()
			local color = Color(255, 255, 0, 255)
			local NumTraitors = CountTraitors()
			local text

			if NumTraitors > 1 then
				text = "There are currently "..#player.GetAll().." players on the server. Out of these, "..NumTraitors.." are Traitors."
			else
				text = "There are currently "..#player.GetAll().." players on the server. Out of these, "..NumTraitors.." is a Traitor."
			end
			CustomMsg(nil, text, color)
		end)
	end )

	hook.Add("PlayerInitialSpawn", "PlayerConnectMessage", function(ply)
		local clr = Color(255, 255, 0, 255)
		local text = "Player "..ply:Nick().." has finished joining the server."
		CustomMsg(nil, text, clr)
	end)

	hook.Add("PlayerDeath", "WhoKilledYou", function(victim, _, attacker)
		if not IsValid(victim) or not victim:Alive() or victim == attacker then
			return
		end
		
		local name = ""
		local role = 0

		if attacker:IsPlayer() then
			name = attacker:Nick()

			if attacker:GetRole() == ROLE_INNOCENT then
				role = 1
			elseif attacker:GetRole() == ROLE_DETECTIVE then
				role = 2
			elseif attacker:GetRole() == ROLE_TRAITOR then
				role = 3
			end
		end

		net.Start("WhoKilledYou")
			net.WriteString(name)
			net.WriteUInt(role, 2)
		net.Send(victim)
	end)
end

if CLIENT then
	net.Receive("WhoKilledYou", function()
		local name = net.ReadString()
		local roletype = net.ReadUInt(2)

		if roletype == 0 then
			chat.AddText(color_white, "A ", Color(255, 87, 0), "game entity", color_white, " killed you.")
		elseif roletype == 1 then
			chat.AddText(Color(255, 87, 0), name, color_white, " killed you. He/She was an ", Color(10, 250, 10), "Innocent", color_white, ". If you believe this was RDM then type ", Color(98, 176, 255), "!report", color_white, " in chat, to report them.")
		elseif roletype == 3 then
			chat.AddText(Color(255, 87, 0), name, color_white, " killed you. He/She was a ", Color(250, 10, 10), "Traitor", color_white, ". If you believe this was RDM then type ", Color(98, 176, 255), "!report", color_white, " in chat, to report them.")
		elseif roletype == 2 then
			chat.AddText(Color(255, 87, 0), name, color_white, " killed you. He/She was a ", Color(10, 10, 250), "Detective", color_white, ". If you believe this was RDM then type ", Color(98, 176, 255), "!report", color_white, " in chat, to report them.")
		end
	end)
end
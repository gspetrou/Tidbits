----------------------------------
-----------Config Start-----------
----------------------------------
local AdminAccess = {
	superadmin = true,
	admin = true,
	moderator = true
}
local TagAccess = {
	superadmin = true,
	admin = true,
	moderator = true
}

local RankInfos = {
	superadmin = {
		tagtext = "Super-Admin",
		tagfrom = Color(255, 0, 0),
	},
	admin = {
		tagtext = "Admin",
		tagfrom = Color(255, 255, 0),
	}
}

----------------------------------
------------Config End------------
----------------------------------
SB = SB or {}

local function TableToColor(tbl)
	return Color(tbl.r, tbl.g, tbl.b, tbl.a or 255)
end

if SERVER then
	util.AddNetworkString("SB_SendAllInfo")
	util.AddNetworkString("SB_AddPlayer")
	util.AddNetworkString("SB_UpdateTagText")
	util.AddNetworkString("SB_UpdateTagColor")
	util.AddNetworkString("SB_UpdateNameColor")

	local function GetTagText(ply)
		local fallback = ""
		local rankinfo = RankInfos[ply:GetUserGroup()]
		if istable(rankinfo) and isstring(rankinfo.tagtext) then
			fallback = rankinfo.tagtext
		end

		return ply:GetPData("SB_TagText", fallback)
	end

	function SetTagText(ply, text)
		text = isstring(text) and text or ""

		SB[ply].tagtext = text
		ply:SetPData("SB_TagText", text)

		net.Start("SB_UpdateTagText")
			net.WritePlayer(ply)
			net.WriteString(text)
		net.Broadcast()
	end

	local function GetTagColor(ply)
		local rankinfo = RankInfos[ply:GetUserGroup()]

		local from_fallback = color_black
		if istable(rankinfo) and IsColor(rankinfo.tagfrom) then
			from_fallback = rankinfo.tagfrom
		end
		local from = ply:GetPData("SB_TagFrom", from_fallback)
		if isstring(from) then
			from = string.ToColor(from)
		end

		local to_fallback = color_black
		if istable(rankinfo) and IsColor(rankinfo.tagto) then
			to_fallback = rankinfo.tagto
		end
		local to = ply:GetPData("SB_TagFrom", to_fallback)
		if isstring(to) then
			to = string.ToColor(to)
		end

		return from, to
	end

	local function SetTagColor(ply, from, to)
		from = IsColor(from) and from or color_black
		to = IsColor(to) and to or color_black

		SB[ply].tagfrom = from
		SB[ply].tagto = to
		ply:SetPData("SB_TagFrom", tostring(from))
		ply:SetPData("SB_TagTo", tostring(to))

		net.Start("SB_UpdateTagColor")
			net.WritePlayer(ply)
			net.WriteColor(from)
			net.WriteColor(to)
		net.Broadcast()
	end

	local function GetNameColor(ply)
		local rankinfo = RankInfos[ply:GetUserGroup()]

		local from_fallback = color_black
		if istable(rankinfo) and IsColor(rankinfo.namefrom) then
			from_fallback = rankinfo.namefrom
		end
		local from = ply:GetPData("SB_NameFrom", from_fallback)
		if isstring(from) then
			from = string.ToColor(from)
		end

		local to_fallback = color_black
		if istable(rankinfo) and IsColor(rankinfo.nameto) then
			to_fallback = rankinfo.nameto
		end
		local to = ply:GetPData("SB_NameTo", to_fallback)
		if isstring(to) then
			to = string.ToColor(to)
		end

		return from, to
	end

	local function SetNameColor(ply, from, to)
		from = IsColor(from) and from or color_black
		to = IsColor(to) and to or color_black

		SB[ply].namefrom = from
		SB[ply].nameto = to
		ply:SetPData("SB_NameFrom", tostring(from))
		ply:SetPData("SB_NameTo", tostring(to))

		net.Start("SB_UpdateNameColor")
			net.WritePlayer(ply)
			net.WriteColor(from)
			net.WriteColor(to)
		net.Broadcast()
	end

	hook.Add("PlayerInitialSpawn", "SB_Init", function(ply)
		SB[ply] = {}
		SB[ply].tagtext = GetTagText(ply)
		SB[ply].tagfrom, SB[ply].tagto = GetTagColor(ply)
		SB[ply].namefrom, SB[ply].nameto = GetNameColor(ply)

		local players = player.GetHumans()
		for i, v in ipairs(players) do
			if v == ply then
				table.remove(players, i)
				break
			end
		end

		net.Start("SB_AddPlayer")
			net.WritePlayer(ply)
			net.WriteString(SB[ply].tagtext)
			net.WriteColor(SB[ply].tagfrom)
			net.WriteColor(SB[ply].tagto)
			net.WriteColor(SB[ply].namefrom)
			net.WriteColor(SB[ply].nameto)
		net.Send(players)
	end)

	net.Receive("SB_SendAllInfo", function(_, ply)
		net.Start("SB_SendAllInfo")
			net.WriteTable(SB)
		net.Send(ply)
	end)
	net.Receive("SB_UpdateTagText", function(_, ply)
		if TagAccess[ply:GetUserGroup()] then
			local target = net.ReadPlayer()
			local text = net.ReadString()

			SetTagText(target, text)
		end
	end)
	net.Receive("SB_UpdateTagColor", function(_, ply)
		if TagAccess[ply:GetUserGroup()] then
			local target = net.ReadPlayer()
			local from = net.ReadColor()
			local to = net.ReadColor()

			SetTagColor(target, from, to)
		end
	end)
	net.Receive("SB_UpdateNameColor", function(_, ply)
		if TagAccess[ply:GetUserGroup()] then
			local target = net.ReadPlayer()
			local from = net.ReadColor()
			local to = net.ReadColor()

			SetNameColor(target, from, to)
		end
	end)

	hook.Add("CAMI.PlayerUsergroupChanged", "SB_OnRankChanged", function(ply, old, new)
		if old == new then
			return
		end

		local old_rankinfo = RankInfos[old]
		local new_rankinfo = RankInfos[new]
		if istable(SB[ply]) and istable(old_rankinfo) then
			local TagColorChanged = false
			local tagfrom, tagto = color_black, color_black
			
			if old_rankinfo.tagfrom == SB[ply].tagfrom and IsColor(new_rankinfo.tagfrom) then
				tagfrom = new_rankinfo.tagfrom
				TagColorChanged = true
			end
			if old_rankinfo.tagto == SB[ply].tagto and IsColor(new_rankinfo.tagto) then
				tagto = new_rankinfo.tagto
				TagColorChanged = true
			end
			if TagColorChanged then
				SetTagColor(tagfrom, tagto)
			end

			local NameColorChanged = false
			local namefrom, nameto = color_black, color_black
			if old_rankinfo.namefrom == SB[ply].namefrom and IsColor(new_rankinfo.namefrom) then
				namefrom = new_rankinfo.namefrom
				NameColorChanged = true
			end
			if old_rankinfo.nameto == SB[ply].nameto and IsColor(new_rankinfo.nameto) then
				nameto = new_rankinfo.nameto
				NameColorChanged = true
			end
			if NameColorChanged then
				SetNameColor(namefrom, nameto)
			end
		end
	end)

	hook.Add("CAMI.SteamIDUsergroupChanged", "SB_OnRankChanged_Offline", function(steamid, old, new)
		if old == new then
			return
		end

		local plyinfo = {
			tagfrom = util.GetPData(steamid, "SB_TagFrom"),
			tagto = util.GetPData(steamid, "SB_TagTo"),
			namefrom = util.GetPData(steamid, "SB_NameFrom"),
			nameto = util.GetPData(steamid, "SB_NameTo")
		}

		local old_rankinfo = RankInfos[old]
		local new_rankinfo = RankInfos[new]
		if istable(old_rankinfo) then
			local TagColorChanged = false
			local tagfrom, tagto = color_black, color_black
			
			if old_rankinfo.tagfrom == plyinfo.tagfrom and IsColor(new_rankinfo.tagfrom) then
				tagfrom = new_rankinfo.tagfrom
				TagColorChanged = true
			end
			if old_rankinfo.tagto == plyinfo.tagto and IsColor(new_rankinfo.tagto) then
				tagto = new_rankinfo.tagto
				TagColorChanged = true
			end
			if TagColorChanged then
				SetTagColor(tagfrom, tagto)
			end

			local NameColorChanged = false
			local namefrom, nameto = color_black, color_black
			if old_rankinfo.namefrom == plyinfo.namefrom and IsColor(new_rankinfo.namefrom) then
				namefrom = new_rankinfo.namefrom
				NameColorChanged = true
			end
			if old_rankinfo.nameto == plyinfo.nameto and IsColor(new_rankinfo.nameto) then
				nameto = new_rankinfo.nameto
				NameColorChanged = true
			end
			if NameColorChanged then
				SetNameColor(namefrom, nameto)
			end
		end
	end)
end

if CLIENT then
	net.Receive("SB_AddPlayer", function()
		local ply = net.ReadPlayer()
		SB[ply] = {}
		SB[ply].tagtext = net.ReadString()
		SB[ply].tagfrom = net.ReadColor()
		SB[ply].tagto = net.ReadColor()
		SB[ply].namefrom = net.ReadColor()
		SB[ply].nameto = net.ReadColor()
	end)

	net.Receive("SB_UpdateTagText", function()
		local ply = net.ReadPlayer()
		SB[ply] = SB[ply] or {}

		SB[ply].tagtext = net.ReadString()
	end)

	net.Receive("SB_UpdateTagColor", function()
		local ply = net.ReadPlayer()
		SB[ply] = SB[ply] or {}

		SB[ply].tagfrom = net.ReadColor()
		SB[ply].tagto = net.ReadColor()
	end)

	net.Receive("SB_UpdateNameColor", function()
		local ply = net.ReadPlayer()
		SB[ply] = SB[ply] or {}

		SB[ply].namefrom = net.ReadColor()
		SB[ply].nameto = net.ReadColor()
	end)

	function GetTagText(ply)		
		local rankinfo = RankInfos[ply:GetUserGroup()]
		local fallback = ""

		if istable(rankinfo) and isstring(rankinfo.tagtext) then
			fallback = rankinfo.tagtext
		end

		if not istable(SB[ply]) or not isstring(SB[ply].tagtext) then
			return fallback
		end

		return SB[ply].tagtext ~= "" and SB[ply].tagtext or fallback
	end

	function GetTagColor(ply)
		local rankinfo = RankInfos[ply:GetUserGroup()]
		local fallback_from = color_black
		local fallback_to = color_black

		if istable(rankinfo) then
			if IsColor(rankinfo.tagfrom) then
				fallback_from = rankinfo.tagfrom
			end
			if IsColor(rankinfo.tagto) then
				fallback_to = rankinfo.tagto
			end
		end

		if not istable(SB[ply]) then
			return fallback_from, fallback_to
		end

		local from = fallback_from
		if IsColor(SB[ply].tagfrom) and SB[ply].tagfrom ~= color_black then
			from = SB[ply].tagfrom
		end
		local to = fallback_to
		if IsColor(SB[ply].tagto) and SB[ply].tagto ~= color_black then
			to = SB[ply].tagto
		end

		return from, to
	end

	function GetNameColor(ply)
		local rankinfo = RankInfos[ply:GetUserGroup()]
		local fallback_from = color_black
		local fallback_to = color_black

		if istable(rankinfo) then
			if IsColor(rankinfo.namefrom) then
				fallback_from = rankinfo.namefrom
			end
			if IsColor(rankinfo.nameto) then
				fallback_to = rankinfo.nameto
			end
		end

		if not istable(SB[ply]) then
			return fallback_from, fallback_to
		end

		return SB[ply].namefrom or fallback_from, SB[ply].nameto or fallback_to
	end

	-- Derma
	local function CreateFrame(title, width, height)
		local frame = vgui.Create("DFrame") 
		frame:SetSize(width, height)
		frame:Center()
		frame:MakePopup()
		frame:SetTitle(title)

		return frame
	end

	local function CreateMixer(parent)
		local mixer = vgui.Create("DColorMixer", parent)
		mixer:SetPalette(true) 
		mixer:SetAlphaBar(false)
		mixer:SetWangs(true)

		return mixer
	end

	hook.Add("TTTScoreboardMenu", "SB_RightClickMenu", function(menu)
		local ply = menu.Player
		local local_rank = LocalPlayer():GetUserGroup()

		-- Copy Name
		menu:AddOption("Copy Name", function()
			SetClipboardText(ply:Nick())
		end):SetIcon("icon16/user.png")
		-- Copy SteamID
		menu:AddOption("Copy SteamID", function()
			SetClipboardText(ply:SteamID())
		end):SetIcon("icon16/key.png")
		-- Open Profile
		menu:AddOption("Open Profile", function()
			ply:ShowProfile()
		end):SetIcon("icon16/world.png")

		-- Clientside Mute
		if ply ~= LocalPlayer() then
			local muted = ply:IsMuted()
			menu:AddOption(muted and "Clientside Unmute" or "Clientside Mute", function()
				ply:SetMuted(not muted)
			end):SetIcon(muted and "icon16/sound.png" or "icon16/sound_mute.png")
		end

		-- Tag Options
		if TagAccess[local_rank] then
			menu:AddSpacer()

			menu:AddOption("Modify Tag Text", function()
				local frame = CreateFrame("Set tag text", 267, 60)
				local text = GetTagText(ply)

				local TagText = vgui.Create("DTextEntry", frame)
				TagText:Dock(FILL)
				TagText:RequestFocus()
				TagText:SetText(text)

				function frame:OnClose()
					local output = TagText:GetText()

					if output == text then
						return
					elseif #output > 100 then
						Derma_Message("This tag is too long!")
						return
					end

					net.Start("SB_UpdateTagText")
						net.WritePlayer(ply)
						net.WriteString(output)
					net.SendToServer()
				end
			end):SetIcon("icon16/tag_blue_edit.png")

			menu:AddOption("Edit Tag Color", function()
				local frame = CreateFrame("Select tag color", 258, 394)
				local from, to = GetTagColor(ply)

				local lbl = vgui.Create("DLabel", frame)
				lbl:SetText("Tag Color (set to black to disable):")
				lbl:SetPos(5, 23)
				lbl:SetSize(200, 20)

				local Mixer = CreateMixer(frame)
				Mixer:SetPos(0, 42)
				Mixer:SetSize(258, 166)
				Mixer:SetColor(from)

				local lbl2 = vgui.Create("DLabel", frame)
				lbl2:SetText("Glow color (set to solid black to disable):")
				lbl2:SetPos(5, 207)
				lbl2:SetSize(200, 20)

				local Mixer2 = CreateMixer(frame)
				Mixer2:SetPos(0, 227)
				Mixer2:SetSize(258, 166)
				Mixer2:SetColor(to)

				function frame:OnClose()
					local new_from = TableToColor(Mixer:GetColor())
					local new_to = TableToColor(Mixer2:GetColor())

					if new_from ~= from or new_to ~= to then
						net.Start("SB_UpdateTagColor")
							net.WritePlayer(ply)
							net.WriteColor(new_from)
							net.WriteColor(new_to)
						net.SendToServer()
					end
				end
			end):SetIcon("icon16/color_swatch.png")

			menu:AddOption("Edit Name Color", function()
				local frame = CreateFrame("Select name color", 258, 394)
				local from, to = GetNameColor(ply)

				local lbl = vgui.Create("DLabel", frame)
				lbl:SetText("Name Color (set to black to disable):")
				lbl:SetPos(5, 23)
				lbl:SetSize(200, 20)

				local Mixer = CreateMixer(frame)
				Mixer:SetPos(0, 42)
				Mixer:SetSize(258, 166)
				Mixer:SetColor(from)

				local lbl2 = vgui.Create("DLabel", frame)
				lbl2:SetText("Glow color (set to solid black to disable):")
				lbl2:SetPos(5, 207)
				lbl2:SetSize(200, 20)

				local Mixer2 = CreateMixer(frame)
				Mixer2:SetPos(0, 227)
				Mixer2:SetSize(258, 166)
				Mixer2:SetColor(to)

				function frame:OnClose()
					local new_from = TableToColor(Mixer:GetColor())
					local new_to = TableToColor(Mixer2:GetColor())

					if new_from ~= from or new_to ~= to then
						net.Start("SB_UpdateNameColor")
							net.WritePlayer(ply)
							net.WriteColor(new_from)
							net.WriteColor(new_to)
						net.SendToServer()
					end
				end
			end):SetIcon("icon16/color_wheel.png")
		end

		-- Admin Options
		if AdminAccess[local_rank] then
			menu:AddSpacer()

			if not ply:GetNWBool("ulx_muted") then
				menu:AddOption("Mute", function()
					RunConsoleCommand("ulx", "mute", "$"..ply:SteamID())
				end):SetIcon("icon16/pencil_delete.png")
			else
				menu:AddOption("Unmute", function()
					RunConsoleCommand("ulx", "unmute", "$"..ply:SteamID())
				end):SetIcon("icon16/pencil_add.png")
			end

			if not ply:GetNWBool("ulx_gagged") then
				menu:AddOption("Gag", function()
					RunConsoleCommand("ulx", "gag", "$"..ply:SteamID())
				end):SetIcon("icon16/sound_mute.png")
			else
				menu:AddOption("Ungag", function()
					RunConsoleCommand("ulx", "ungag", "$"..ply:SteamID())
				end):SetIcon("icon16/sound.png")
			end

			menu:AddOption("Slay", function()
				RunConsoleCommand("ulx", "slay", "$"..ply:SteamID())
			end):SetIcon("icon16/user_delete.png")

			menu:AddOption("Kick", function()
				RunConsoleCommand("ulx", "kick", "$"..ply:SteamID())
			end):SetIcon("icon16/door_out.png")
		end
	end)

	hook.Add("TTTScoreboardColorForPlayer", "SB_NameColor", function(ply)
		local from, to = GetNameColor(ply)

		if from ~= color_black then
			if to == color_black then
				return from
			else
				local vfrom = Vector(from.r, from.g, from.b, from.a)
				local vto = Vector(to.r, to.g, to.b, to.a)
				local col = LerpVector((math.sin(RealTime()*1.7)+1)/2, vfrom, vto)
				col = Color(col.x, col.y, col.z)
				
				return col
			end
		end
	end)

	hook.Add("TTTScoreboardColumns", "SB_Tags", function(panel)
		panel:AddColumn("", function() return "" end, 0)

		panel:AddColumn("Rank", function(ply, label)
			local text = GetTagText(ply)

			if text ~= "" then
				local from, to = GetTagColor(ply)

				if from ~= color_black then
					if to == color_black then
						label:SetColor(from)
					else
						local vfrom = Vector(from.r, from.g, from.b, from.a)
						local vto = Vector(to.r, to.g, to.b, to.a)
						local col = LerpVector((math.sin(RealTime()*1.7) + 1)/2, vfrom, vto)
						col = Color(col.x, col.y, col.z)
						label:SetColor(col)
					end
				end
			else
				return ""
			end

			return text
		end, 150)
	end)

	timer.Create("SB_Init", 0, 0, function()
		if IsValid(LocalPlayer()) then
			net.Start("SB_SendAllInfo")
			net.SendToServer()
			timer.Remove("SB_Init")
		end
	end)

	net.Receive("SB_SendAllInfo", function()
		local tbl = net.ReadTable()
		SB = istable(tbl) and tbl or SB
	end)
end
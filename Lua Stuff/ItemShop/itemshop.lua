--[[
	Item shop written for Lord Tyler
	May 26, 2018

	Lord Tyler owns full rights of this store.
	Kyu Yeon "rebel1324" Lee, this is how its done...

	- George "Stalker" Petrou
]]

---------------------- NOTES ----------------------
-- UID is short for Unique ID.
-- Decimal item values are not supported and will be floored.
-- The store front supports as little as a 700x400 UI and can stretch bigger.
-- The admin UI supports as little as a 850x600px UI. The abilitity to stretch
-- 	likely is there since nothing is hardcoded but can definitely leed to
-- 	strange quirks so I'd rather not deal with it since its only an admin UI.
-- Item prices are limited to 2^32 = $4294967296 dollars. Number bits controlled
-- 	by NET_ITEM_MAXPRICEBITS.
-- Number of factions and number of items per faction supported are 2^10 = 1024.
-- 	This value is set by NET_ITEM_BITS. You could theoretically change it if you
-- 	somehow need more than that many. You can also lower it if you dont need the space.

-- Neither of these can be greater than 32 or less than 1!
-- Only change if you know what you're doing.
local NET_ITEM_BITS = 10
local NET_ITEM_MAXPRICEBITS = 32	
-------------------- END NOTES --------------------

local PLUGIN = PLUGIN
PLUGIN.name = "Kraken Shop System 2.0"
PLUGIN.author = "Stalker (STEAM_1:1:18093014)"
PLUGIN.desc = "Store you can buy stuff from."

nut.KrakenShop = nut.KrakenShop or {}

------------------ Notes to self ------------------
-- nut.faction
-- 	Has teams table with faction name as key and info as value.
-- 	Has indices table with index as key and info as value. uniqueID is same as faction name from team table.
-- nut.item.list
-- 	Key is item uniqueID, info table is value.

--[[-------------------------------------------------------------------------
Code related to openning the menu
---------------------------------------------------------------------------]]
local justClosedMenu = isbool(justClosedMenu) and justClosedMenu or false	-- If the client just closed the menu with F4 prevent also openning it because of that same keypress.

-- We're reading the keypress in a predicted hook so make sure it works in singleplayer as well.
local function ReadF4KeyPress(ply, key, singlePlayer)
	if key == KEY_F4 then
		if singlePlayer then
			net.Start("KrakenShop.SPOpenMenu")
			net.Send(ply)
		elseif CLIENT then
			if justClosedMenu then
				justClosedMenu = false	-- Used to prevent openning the menu from the same button press to close the menu.
			else
				nut.KrakenShop.OpenMenu()
			end
		end
	end
end

-- Reads F4 key presses, again, we're using a predicted hook so make sure it works in singleplayer.
if game.SinglePlayer() then
	if SERVER then
		util.AddNetworkString("KrakenShop.SPOpenMenu")

		function PLUGIN:PlayerButtonDown(ply, key)
			ReadF4KeyPress(ply, key, true)
		end
	else
		net.Receive("KrakenShop.SPOpenMenu", function()
			nut.KrakenShop.OpenMenu()
		end)
	end
elseif CLIENT then
	function PLUGIN:PlayerButtonDown(ply, key)
		if IsFirstTimePredicted() then
			ReadF4KeyPress(ply, key, false)
		end
	end
end

-- Concommand that can be used to open the store.
if CLIENT then
	concommand.Add("krakenshop", function()
		nut.KrakenShop.OpenMenu()
	end, nil, "Opens the Kraken Item Shop")
end

--[[-------------------------------------------------------------------------
General Use Functions
---------------------------------------------------------------------------]]

-- Sees if the given player can open the admin menu.
-- Either they are Stalker (me!) or have stafflevel set to 12.
function nut.KrakenShop.CanUseAdminMenu(ply)
	return (Stalker and ply == Stalker()) or (ply:GetNWInt("stafflevel", 0) == 12)
end

-- Returns a table of all item's item info sorted alphabetically by name in their category tables.
function nut.KrakenShop.GetItemsByCategory()
	local categories = {}

	for uniqueID, itemInfo in pairs(nut.item.list) do
		if not istable(categories[itemInfo.category]) then
			categories[itemInfo.category] = {}
		end

		table.insert(categories[itemInfo.category], itemInfo)
	end

	for catName, items in pairs(categories) do
		table.sort(items, function(itemA, itemB)
			return string.lower(itemA.name) < string.lower(itemB.name)
		end)
	end

	return categories
end

-- Gets a list of all categories sorted alphabetically.
function nut.KrakenShop.GetAlphabeticallySortedCategories()
	local categories = {}
	local categoriesAdded = {}
	for _, itemInfo in pairs(nut.item.list) do
		if not categoriesAdded[itemInfo.category] then
			categoriesAdded[itemInfo.category] = true
			table.insert(categories, itemInfo.category)
		end
	end

	table.sort(categories, function(catA, catB)
		return string.lower(catA) < string.lower(catB)
	end)

	return categories
end

-- Gets a list of all factions sorted alphabetically by name.
function nut.KrakenShop.GetAlphabeticallySortedFactions()
	local rawFactions = table.Copy(nut.faction.indices)
	local sortedFactions = {}

	-- Lets first add the nut.items.indices index of this faction to the faction info table for use later and make sure our table is sequential.
	for index, factionInfo in pairs(rawFactions) do
		factionInfo.factionIndex = index
		table.insert(sortedFactions, factionInfo)
	end

	-- Now do what we came here for.
	table.sort(sortedFactions, function(factionInfoA, factionInfoB)
		return factionInfoA.name < factionInfoB.name
	end)

	return sortedFactions
end

-- Gets an item's info table from it's UID.
function nut.KrakenShop.ItemInfoFromUID(itemUID)
	return nut.item.list[itemUID]
end

-- Gets the price of an item. Make the second argument nil if you only want the global price.
function nut.KrakenShop.GetItemPrice(itemUID, factionUID)
	if not factionUID then
		if nut.KrakenShop.Items.GlobalItems[itemUID] then
			return nut.KrakenShop.Items.GlobalItems[itemUID]
		end
	else
		if nut.KrakenShop.Items.FactionItems[factionUID][itemUID] then
			return nut.KrakenShop.Items.FactionItems[factionUID][itemUID]
		elseif nut.KrakenShop.Items.GlobalItems[itemUID] then
			return nut.KrakenShop.Items.GlobalItems[itemUID]
		end
	end

	return nil -- No price set.
end

-- Gets all items that should be available for purchase by a faction, includes global items.
function nut.KrakenShop.GetItemsForFaction(factionUID)
	local availableItems = {}
	local globalItem = {}
	for itemUID in pairs(nut.KrakenShop.Items.GlobalItems) do
		globalItem[itemUID] = true
		table.insert(availableItems, itemUID)
	end
	for itemUID, _ in pairs(nut.KrakenShop.Items.FactionItems[factionUID]) do
		if not globalItem[itemUID] then -- Prevent adding an item twice.
			table.insert(availableItems, itemUID)
		end
	end

	table.sort(availableItems, function(uidA, uidB)
		return nut.KrakenShop.ItemInfoFromUID(uidA).name < nut.KrakenShop.ItemInfoFromUID(uidB).name
	end)

	return availableItems
end

--[[-------------------------------------------------------------------------
Loading/Networking Items
---------------------------------------------------------------------------]]
-- 'Operations' you can send to modify an item. Used internally.
local ITEM_DELETE = 0
local ITEM_SETPRICE = 1
local ITEM_ADD = 2

if SERVER then
	if not istable(pon) then
		error("[KrakenShop] Requires pON to be installed! Store will not function properly.")
	end
	local pon_encode, pon_decode = pon.encode, pon.decode

	util.AddNetworkString("KrakenShop.InitClient")
	util.AddNetworkString("KrakenShop.UpdateChangeForClients")
	util.AddNetworkString("KrakenShop.ModifyItemForFaction")
	util.AddNetworkString("KrakenShop.ModifyItemForAll")
	util.AddNetworkString("KrakenShop.RequestPurchase")

	-- Load store data when our plugin finishes loading.
	function PLUGIN:InitializedPlugins()
		nut.KrakenShop.LoadData()
		nut.KrakenShop.HandleForFactionChanges()
	end

	-- Loads any store data saved in permanent storage.
	function nut.KrakenShop.LoadData()
		nut.KrakenShop.Items = {
			FactionItems = {},
			GlobalItems = {}
		}

		-- We have actual data to load.
		if file.Exists("krakenshop.dat", "DATA") then
			local rawFile = file.Read("krakenshop.dat", "DATA")
			nut.KrakenShop.Items = pon_decode(rawFile)
		else
			-- First time, create our blank table and save.
			for factionUID, data in pairs(nut.faction.teams) do
				nut.KrakenShop.Items.FactionItems[factionUID] = {}
			end

			nut.KrakenShop.Save()
		end
	end

	-- Saves any permanent store data.
	function nut.KrakenShop.Save()
		file.Write("krakenshop.dat", pon_encode(nut.KrakenShop.Items))
	end

	-- When a client connects send them any data they need to know about the store.
	function nut.KrakenShop.InitClient(ply)
		net.Start("KrakenShop.InitClient")

			-- Number of factions we need to send over.
			net.WriteUInt(table.Count(nut.KrakenShop.Items.FactionItems), NET_ITEM_BITS)

			for factionUID, items in pairs(nut.KrakenShop.Items.FactionItems) do
				net.WriteString(factionUID)	-- Name of team we're writing.
				net.WriteUInt(table.Count(nut.KrakenShop.Items.FactionItems[factionUID]), NET_ITEM_BITS)	-- Number of items this team has.

				for itemUID, itemPrice in pairs(items) do
					net.WriteString(itemUID)
					net.WriteUInt(itemPrice, NET_ITEM_MAXPRICEBITS)
				end
			end

			-- Number of global items we need to send over.
			net.WriteUInt(table.Count(nut.KrakenShop.Items.GlobalItems), NET_ITEM_BITS)

			for itemUID, itemPrice in pairs(nut.KrakenShop.Items.GlobalItems) do
				net.WriteString(itemUID)	-- Write the global item name.
				net.WriteUInt(itemPrice, NET_ITEM_MAXPRICEBITS)-- Write it's global price.
			end

		net.Send(ply)
	end

	-- Sees if any factions were added or removed.
	function nut.KrakenShop.HandleForFactionChanges()
		local checkedFactions = {}

		-- If any factions got added from last restart then account for that.
		for factionUID, data in pairs(nut.faction.teams) do
			if not nut.KrakenShop.Items.FactionItems[factionUID] then
				nut.KrakenShop.Items.FactionItems[factionUID] = {}
			end
			checkedFactions[factionUID] = true
		end

		-- If any factions got removed from last restart then account for that.
		for factionUID, data in pairs(nut.KrakenShop.Items.FactionItems) do
			if not checkedFactions[factionUID] then
				nut.KrakenShop.Items.FactionItems[factionUID] = nil
			end
		end

		nut.KrakenShop.Save()
	end

	-- Initialize a player when they conenct.
	function PLUGIN:PlayerInitialSpawn(ply)
		nut.KrakenShop.InitClient(ply)
	end

	-- When we make a change to our item store network that change over to the clients. Better option than syncing the entire table over.
	function nut.KrakenShop.UpdateChangeForClients(isGlobal, operation, itemUID, price, factionUID)
		net.Start("KrakenShop.UpdateChangeForClients")
			net.WriteBool(isGlobal)
			net.WriteUInt(operation, 2)
			net.WriteString(itemUID)

			if not isGlobal then
				net.WriteString(factionUID)
			end

			if operation ~= ITEM_DELETE then
				net.WriteUInt(price, NET_ITEM_MAXPRICEBITS)
			end
		net.Broadcast()
	end

	-- Receives a request from the client to perform an operation on an item for a specific faction.
	net.Receive("KrakenShop.ModifyItemForFaction", function(_, ply)
		if not nut.KrakenShop.CanUseAdminMenu(ply) then
			error("[KrakenShop] Player '"..ply:Nick().."' ("..ply:SteamID()..") tried modifying store items when they are not allowed to!")
			return
		end

		local operation = net.ReadUInt(2)
		local factionUID = net.ReadString()
		local itemUID = net.ReadString()

		if not istable(nut.KrakenShop.Items.FactionItems[factionUID]) then
			error("Tried to modify item for a non-existant faction!")
		end
		
		if operation == ITEM_SETPRICE then
			local price = net.ReadUInt(NET_ITEM_MAXPRICEBITS)
			nut.KrakenShop.SetItemPriceForFaction(itemUID, factionUID, price)
		elseif operation == ITEM_ADD then
			nut.KrakenShop.AddItemToFaction(itemUID, factionUID)
		elseif operation == ITEM_DELETE then
			nut.KrakenShop.RemoveItemFromFaction(itemUID, factionUID)
		else
			error("Tried to use non-existant operation on item '"..itemUID.."' for faction '"..factionUID.."'.")
		end
	end)

	-- Adds the given item UID to be purchased by the given faction UID.
	function nut.KrakenShop.AddItemToFaction(itemUID, factionUID)
		nut.KrakenShop.Items.FactionItems[factionUID][itemUID] = nut.KrakenShop.Items.GlobalItems[itemUID] or 0
		nut.KrakenShop.UpdateChangeForClients(false, ITEM_ADD, itemUID, nut.KrakenShop.Items.FactionItems[factionUID][itemUID], factionUID)
		nut.KrakenShop.Save()
	end

	-- Sets the price of a given item for a faction.
	function nut.KrakenShop.SetItemPriceForFaction(itemUID, factionUID, price)
		nut.KrakenShop.Items.FactionItems[factionUID][itemUID] = price
		nut.KrakenShop.UpdateChangeForClients(false, ITEM_SETPRICE, itemUID, price, factionUID)
		nut.KrakenShop.Save()
	end

	-- Removes the item from being able to be purchased by the given faction.
	function nut.KrakenShop.RemoveItemFromFaction(itemUID, factionUID)
		nut.KrakenShop.Items.FactionItems[factionUID][itemUID] = nil
		nut.KrakenShop.UpdateChangeForClients(false, ITEM_DELETE, itemUID, nil, factionUID)
		nut.KrakenShop.Save()
	end

	-- Receives a request from the client to perform an operation on an item for all factions.
	net.Receive("KrakenShop.ModifyItemForAll", function(_, ply)
		if not nut.KrakenShop.CanUseAdminMenu(ply) then
			error("[KrakenShop] Player '"..ply:Nick().."' ("..ply:SteamID()..") tried modifying store items when they are not allowed to!")
			return
		end

		local operation = net.ReadUInt(2)
		local itemUID = net.ReadString()
		if operation == ITEM_SETPRICE then
			local price = net.ReadUInt(NET_ITEM_MAXPRICEBITS)
			nut.KrakenShop.SetItemPriceForAllFactions(itemUID, price)
		elseif operation == ITEM_ADD then
			nut.KrakenShop.AddItemToAllFactions(itemUID)
		elseif operation == ITEM_DELETE then
			nut.KrakenShop.RemoveItemFromAllFactions(itemUID)
		else
			error("Tried to use non-existant operation on item '"..itemUID.."'.")
		end
	end)

	-- Makes the item available for purchase by all factions.
	function nut.KrakenShop.AddItemToAllFactions(itemUID)
		nut.KrakenShop.Items.GlobalItems[itemUID] = 0
		nut.KrakenShop.UpdateChangeForClients(true, ITEM_ADD, itemUID, nut.KrakenShop.Items.GlobalItems[itemUID])
		nut.KrakenShop.Save()
	end

	-- Sets the price of the item for all factions.
	-- NOTE:	If the item price is NOT less than 0 then this price will override the item's global price. If it IS less than 0 then the global price will be used.
	function nut.KrakenShop.SetItemPriceForAllFactions(itemUID, price)
		nut.KrakenShop.Items.GlobalItems[itemUID] = price
		nut.KrakenShop.UpdateChangeForClients(true, ITEM_SETPRICE, itemUID, price)
		nut.KrakenShop.Save()
	end

	-- Removes the item from being able to be purchased by all factions.
	function nut.KrakenShop.RemoveItemFromAllFactions(itemUID)
		nut.KrakenShop.Items.GlobalItems[itemUID] = nil
		nut.KrakenShop.UpdateChangeForClients(true, ITEM_DELETE, itemUID)
		nut.KrakenShop.Save()
	end

	-- Received when a client wants to purcahse an item.
	net.Receive("KrakenShop.RequestPurchase", function(_, ply)
		local itemUID = net.ReadString()
		if not isstring(itemUID) or not IsValid(ply) or not istable(ply:getChar()) or not isnumber(ply:getChar():getFaction()) then
			return
		end

		local plyChar = ply:getChar()
		local factionUID = nut.faction.indices[plyChar:getFaction()].uniqueID
		local price = nut.KrakenShop.GetItemPrice(itemUID, factionUID)
		local canAfford = plyChar:hasMoney(price)

		local hookResult = hook.Run("KrakenShop.CanPlayerPurchaseItem", factionUID, itemUID, ply)
		if hookResult == false then
			return
		end
		
		if canAfford then
			local inv = plyChar:getInv()
			if inv:add(itemUID) then
				local itemTable = nut.item.list[itemUID]

				ply:notify("You've purchased ".. (itemTable.getName and itemTable:getName() or itemTable.name) .. " for " .. nut.currency.get(price) ..".")
				plyChar:giveMoney(-price)
			end
		else
			ply:notifyLocalized("You are too poor for this item!")
		end
	end)
end

if CLIENT then
	-- Loads in the item table.
	net.Receive("KrakenShop.InitClient", function()
		nut.KrakenShop.Items = {
			FactionItems = {},
			GlobalItems = {}
		}

		-- Read in faction items.
		local numFactions = net.ReadUInt(NET_ITEM_BITS)
		for i = 1, numFactions do
			local factionName = net.ReadString()
			local numItems = net.ReadUInt(NET_ITEM_BITS)

			nut.KrakenShop.Items.FactionItems[factionName] = {}

			for j = 1, numItems do
				nut.KrakenShop.Items.FactionItems[factionName][net.ReadString()] = net.ReadUInt(NET_ITEM_MAXPRICEBITS)
			end
		end

		-- - Number of global items we need to send over.
		local numGlobalItems = net.ReadUInt(NET_ITEM_BITS)
		for i = 1, numGlobalItems do
			local itemUID = net.ReadString()
			local itemPrice = net.ReadUInt(NET_ITEM_MAXPRICEBITS)

			nut.KrakenShop.Items.GlobalItems[itemUID] = itemPrice
		end
	end)

	-- Sends to the server that we want to modify this item for the given faction by doing the given operation.
	-- Last argument only necessary if youre using the ITEM_SETPRICE operation.
	function nut.KrakenShop.ModifyItemForFaction(itemUID, factionUID, operation, price)
		net.Start("KrakenShop.ModifyItemForFaction")
			net.WriteUInt(operation, 2)
			net.WriteString(factionUID)
			net.WriteString(itemUID)

			if operation == ITEM_SETPRICE then
				if price == nil then
					error("[KrakenShop] Tried to set price of '"..itemUID.."' with an invalid price argument!")
				elseif price < 0 then
					error("[KrakenShop] Must set a positive price to item '"..itemUID.."'!")
				elseif price > 4294967296 then
					error("[KrakenShop] Can't set price of '"..itemUID.."' to a number larger than 4294967296!")
				else
					net.WriteUInt(price or 0, NET_ITEM_MAXPRICEBITS)
				end
			end

		net.SendToServer()
	end

	-- Adds an item to the given faction name.
	function nut.KrakenShop.AddItemToFaction(itemUID, factionUID)
		if nut.KrakenShop.Items.FactionItems[factionUID][itemUID] then
			chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "This item is already available for that faction!")
		else
			nut.KrakenShop.ModifyItemForFaction(itemUID, factionUID, ITEM_ADD)
		end
	end

	-- Sets the price of an item for the given faction.
	function nut.KrakenShop.SetPriceOfItemForFaction(itemUID, factionUID, price)
		if not nut.KrakenShop.Items.FactionItems[factionUID][itemUID] then
			chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "You must add the item to the given faction before setting it's price!")
		else
			nut.KrakenShop.ModifyItemForFaction(itemUID, factionUID, ITEM_SETPRICE, price)
		end
	end

	-- Removes an item from the given faction.
	function nut.KrakenShop.RemoveItemFromFaction(itemUID, factionUID)
		if not nut.KrakenShop.Items.FactionItems[factionUID][itemUID] then
			chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "This item is already not available for that faction!")
		else
			nut.KrakenShop.ModifyItemForFaction(itemUID, factionUID, ITEM_DELETE)
		end
	end

	-- Modifies the item with the given operation for all factions.
	function nut.KrakenShop.ModifyItemForAll(itemUID, operation, price)
		net.Start("KrakenShop.ModifyItemForAll")
			net.WriteUInt(operation, 2)
			net.WriteString(itemUID)

			if operation == ITEM_SETPRICE then
				if price == nil then
					error("[KrakenShop] Tried to set price of '"..itemUID.."' with an invalid price argument!")
				elseif price < 0 then
					error("[KrakenShop] Must set a positive price to item '"..itemUID.."'!")
				elseif price > 4294967296 then
					error("[KrakenShop] Can't set price of '"..itemUID.."' to a number larger than 4294967296!")
				else
					net.WriteUInt(price or 0, NET_ITEM_MAXPRICEBITS)
				end
			end
		net.SendToServer()
	end

	-- Adds the item to be available to purchase for all factions.
	function nut.KrakenShop.AddItemToAll(itemUID)
		if nut.KrakenShop.Items.GlobalItems[itemUID] then
			chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "This is already a global item!")
		else
			nut.KrakenShop.ModifyItemForAll(itemUID, ITEM_ADD)
		end
	end

	-- Sets the price of the item for all factions.
	function nut.KrakenShop.SetPriceOfItemForAll(itemUID, price)
		if not nut.KrakenShop.Items.GlobalItems[itemUID] then
			chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "You must add this item to the global faction before setting it's price!")
		else
			nut.KrakenShop.ModifyItemForAll(itemUID, ITEM_SETPRICE, price)
		end
	end

	-- Removes the item for purchase from all factions.
	function nut.KrakenShop.RemoveItemFromAll(itemUID)
		if not nut.KrakenShop.Items.GlobalItems[itemUID] then
			chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "This item is already not available globally!")
		else
			nut.KrakenShop.ModifyItemForAll(itemUID, ITEM_DELETE)
		end
	end

	-- When there is a change to the item table the server will send us what changed. Handle that data here.
	net.Receive("KrakenShop.UpdateChangeForClients", function()
		local isGlobalChange = net.ReadBool()
		local operation = net.ReadUInt(2)
		local itemUID = net.ReadString()
		local factionUID = (not isGlobalChange) and net.ReadString()

		if operation == ITEM_SETPRICE or operation == ITEM_ADD then
			local price = net.ReadUInt(NET_ITEM_MAXPRICEBITS)
			if isGlobalChange then
				nut.KrakenShop.Items.GlobalItems[itemUID] = price
			else
				nut.KrakenShop.Items.FactionItems[factionUID][itemUID] = price
			end
		elseif operation == ITEM_DELETE then
			if isGlobalChange then
				nut.KrakenShop.Items.GlobalItems[itemUID] = nil
			else
				nut.KrakenShop.Items.FactionItems[factionUID][itemUID] = nil
			end
		else
			error("Attempted to run invalid operation on item '"..itemUID.."'.")
			return
		end

		if IsValid(nut.KrakenShop.MenuPanel) then
			nut.KrakenShop.MenuPanel:UpdateItems()
		end
	end)
end

--[[-------------------------------------------------------------------------
Menu panel code
---------------------------------------------------------------------------]]
if CLIENT then
	-- nut.KrakenShop.MenuPanel 	- If the menu is open this variable stores the KrakenShop panel.
	-- nut.KrakenShop.AdminPanel	- If the admin menu is open this variable stores the KrakenShop.AdminPanel panel.

	-- If the main panel or admin panels are open on lua auto-refresh then close and re-open them
	local reopenMenu, reopenAdminMenu = false, false
	if IsValid(nut.KrakenShop.MenuPanel) then
		nut.KrakenShop.CloseMenu()
		reopenMenu = true

		-- Wait till full remove.
		timer.Simple(0.1, function()
			nut.KrakenShop.OpenMenu()
		end)
	end

	if IsValid(nut.KrakenShop.AdminPanel) then
		nut.KrakenShop.CloseAdminMenu()
		reopenAdminMenu = true
	end

	-- Wait till full remove, then re-open these panels..
	timer.Simple(0.1, function()
		if reopenMenu then
			nut.KrakenShop.OpenMenu()
		end

		if reopenAdminMenu then
			nut.KrakenShop.OpenAdminMenu()
		end
	end)

	-- Opens the main store menu.
	function nut.KrakenShop.OpenMenu()
		nut.KrakenShop.CloseMenu()
		nut.KrakenShop.MenuPanel = vgui.Create("KrakenShop")
		nut.KrakenShop.MenuPanel:Center()
	end

	-- Closes the main store menu.
	function nut.KrakenShop.CloseMenu()
		if IsValid(nut.KrakenShop.MenuPanel) then
			nut.KrakenShop.MenuPanel:Remove()
		end
	end

	-- Opens the admin menu for the store.
	function nut.KrakenShop.OpenAdminMenu()
		nut.KrakenShop.AdminPanel = vgui.Create("KrakenShop.AdminPanel")
		nut.KrakenShop.AdminPanel:Center()
	end

	-- Closes the admin menu for the store.
	function nut.KrakenShop.CloseAdminMenu()
		if IsValid(nut.KrakenShop.AdminPanel) then
			nut.KrakenShop.AdminPanel:Remove()
		end
	end

	--[[-------------------------------------------------------------------------
	Kraken Store Button
	---------------------------------------------------------------------------]]
	-- Desc:	Creates a stylized button, nothing more.
	do
		local PANEL = {
			mat_Button = Material("kraken_icons/2_ui/ui/window/red_button.png"),
			mat_ButtonHover = Material("kraken_icons/2_ui/ui/window/red_button_hover.png"),
			mat_ButtonPressed = Material("kraken_icons/2_ui/ui/window/red_button_push.png")
		}

		function PANEL:Init()
			self:SetFont("nutMediumFont")
			self:SetTextColor(color_white)
		end

		-- Set true to show the bigger font.
		function PANEL:SetLargeFont(bool)
			if bool then
				self:SetFont("nutBigFont")
			else
				self:SetFont("nutMediumFont")
			end
		end

		function PANEL:Paint(w, h)
			surface.SetDrawColor(color_white)

			surface.SetMaterial(self.mat_Button)
			surface.DrawTexturedRect(0, 0, w, h)

			if self:IsHovered() then
				if input.IsButtonDown(MOUSE_FIRST) then
					surface.SetMaterial(self.mat_ButtonPressed)
					surface.DrawTexturedRect(0, 0, w, h)
				else
					surface.SetMaterial(self.mat_ButtonHover)
					surface.DrawTexturedRect(0, 0, w, h)
				end	
			end
		end

		vgui.Register("KrakenShop.Button", PANEL, "DButton")
	end

	--[[-------------------------------------------------------------------------
	A panel that supports drag and drop icons on a tabular scroll panel
	---------------------------------------------------------------------------]]
	-- Creates a panel that has tabs. Inside each tab we have a scrollable panel that supports drag and drop features in a grid layout.
	do
		local PANEL = {
			numIconsPerLine = 4,
			iconXSpace = 2,
			iconYSpace = 2
		}

		function PANEL:Init()
			self:SetFadeTime(0)
			self.Categories = {}
			self.SuppressDragHooks = true
			self.IsGlobalFaction = false
		end

		-- Adds an item, should be called on a category!
		function PANEL:AddItem(itemInfo)
			local iconHolder = self.iconLayout:Add("DPanel")
			iconHolder.UID = itemInfo.uniqueID
			iconHolder.name = itemInfo.name
			iconHolder.Price = nut.KrakenShop.GetItemPrice(itemInfo.uniqueID)
			iconHolder.parentScrollPanel = self
			function iconHolder:GetScrollPanel()
				return self.parentScrollPanel
			end

			function iconHolder:DoRightClick(factionName, fUID)
				if not self:HasParent(nut.KrakenShop.AdminPanel.AssignedItemsScrollPanel) then
					return
				end

				local isGlobalFaction = iconHolder:GetScrollPanel().IsGlobalFaction
				local currentPrice = nut.KrakenShop.GetItemPrice(itemInfo.uniqueID, not isGlobalFaction and fUID)

				if not currentPrice then
					currentPrice = "UNSET"
				else
					currentPrice = "$"..tostring(currentPrice)
				end

				local priceSetPanelWide, priceSetPanelHeight = 480, 140
				local priceSetFrame = vgui.Create("DFrame")
				priceSetFrame:SetSize(priceSetPanelWide, priceSetPanelHeight)
				priceSetFrame:MakePopup()
				priceSetFrame:Center()
				priceSetFrame:SetTitle("Set price of item")

				local priceSetPanel = vgui.Create("DPanel", priceSetFrame)
				priceSetPanel:Dock(FILL)
				priceSetPanel:InvalidateLayout(true)

				local nameLength = #iconHolder.name
				local factLength = #factionName
				local priceLength = #currentPrice
				local labelText = string.format("Item:%"..(nameLength + 19).."s\nFaction:%"..(factLength + 14).."s\nCurrent Price:%"..(priceLength + 4).."s\nNew Price:%10s", iconHolder.name, factionName, currentPrice, "$")
				local priceSetLabel = vgui.Create("DLabel", priceSetPanel)
				priceSetLabel:SetFont("nutMediumFont")
				priceSetLabel:SetText(labelText)
				priceSetLabel:SetPos(5, 0)
				priceSetLabel:SizeToContents()
				priceSetLabel:InvalidateLayout(true)

				local priceSetBox = vgui.Create("DTextEntry", priceSetPanel)
				priceSetBox:SetNumeric(true)
				priceSetBox:SetWide(200)
				priceSetBox:SetPos(150, 78)
				priceSetBox:SetPlaceholderText(" -1 for global value, blank for no change.")

				local submitButton = vgui.Create("DButton", priceSetPanel)
				submitButton:SetText("Submit")
				submitButton:SetPos(355, 77)
				submitButton:SetWide(60)
				submitButton:SetTextColor(color_white)
				function submitButton:DoClick()
					local price = priceSetBox:GetText()
					if price == nil or price == "" then
						priceSetFrame:Remove()
						return
					end

					local success = pcall(function()
						price = tonumber(price)
					end)

					if not success or not price then
						chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "Looks like you entered a number with multiple decimal points! Please retry.")
						priceSetFrame:Remove()
						return
					end

					price = math.floor(price)

					if price ~= price or price == math.huge then
						chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "You think you're funny huh?")
						return
					elseif price > 4294967296 or price < -1 then
						chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "Sorry! The price of an item must be between 0 and 4294967296!")
						return
					end

					if price == -1 then
						price = nut.KrakenShop.GetItemPrice(itemInfo.uniqueID)
						if not price then
							chat.AddText(Color(255, 0, 0), "[KrakenShop] ", color_white, "Item does not have a global price to fall back on.")
							priceSetFrame:Remove()
							return
						end
					end

					if isGlobalFaction then
						nut.KrakenShop.SetPriceOfItemForAll(iconHolder.UID, price)
					else
						nut.KrakenShop.SetPriceOfItemForFaction(iconHolder.UID, fUID, price)
					end

					priceSetFrame:Remove()
				end
			end

			local icon = iconHolder:Add("DModelPanel")
			icon:SetModel(itemInfo.model)
			icon:Dock(FILL)
			if itemInfo.desc ~= "noDesc" then
				icon:SetTooltip("NAME: "..itemInfo.name.."\nDESCRIPTION: "..itemInfo.desc.."\nMODEL: "..itemInfo.model)
			else
				icon:SetTooltip("NAME: "..itemInfo.name.."\nMODEL: "..itemInfo.model)
			end

			-- Model positionning taken from Pointshop :)
			local PrevMins, PrevMaxs = icon.Entity:GetRenderBounds()
			icon:SetCamPos(PrevMins:Distance(PrevMaxs) * Vector(0.5, 0.5, 0.5))
			icon:SetLookAt((PrevMaxs + PrevMins) / 2 + Vector(0, 0, -3))

			-- Draw out item name on hover and keep it showing on drag.
			local labelBoxTall = 0.2
			function icon:PaintOver(w, h)
				local textBGH = h*labelBoxTall	-- Text Background Height

				surface.SetTextColor(255, 255, 255, 255)
				surface.SetFont("TargetIDSmall")

				surface.SetDrawColor(40, 40, 40, 150)
				surface.DrawRect(1, h - textBGH, w-2, textBGH)

				if IsValid(iconHolder:GetParent()) and not self:HasParent(nut.KrakenShop.AdminPanel.ItemCategories) then
					local cat
					if not iconHolder:GetScrollPanel().IsGlobalFaction then
						cat = iconHolder:GetScrollPanel().uniqueID
					end

					local price = nut.KrakenShop.GetItemPrice(iconHolder.UID, cat)
					if not price then
						price = 0
					end

					price = "$"..tostring(price)
				
					surface.SetTextPos(2, 2)
					surface.DrawText(price)
				end

				local text = itemInfo.name
				if #text > 13 then
					text = string.sub(text, 1, 11) .. "..."
				end

				local tw, th = surface.GetTextSize(text)
				surface.SetTextPos((w-2)/2 - tw/2 + 1, (h - textBGH) + textBGH/2 - th/2)
				surface.DrawText(text)
			end

			-- Want to click straight through to panel behind.
			function icon:OnMousePressed(code)
				self:GetParent():OnMousePressed(code)
				if code == MOUSE_RIGHT then
					local iconHolder = self:GetParent()
					local scrollPanel = iconHolder:GetScrollPanel()
					iconHolder:DoRightClick(scrollPanel.CategoryName, scrollPanel.uniqueID)
				end
			end
			function icon:OnMouseReleased(code) self:GetParent():OnMouseReleased(code) end
		end

		-- Called when an item is dragged into our scroll panel.
		function PANEL:OnDraggedItemIntoPanel(scrollPanel, iconHolder)
			-- Override
		end

		-- Call when an item is dragged out of out scroll panel.
		function PANEL:OnDraggedItemOutOfPanel(scrollPanel, iconHolder)
			-- Override
		end
		
		-- Adds a category to our panel.
		function PANEL:AddCategory(categoryName, categoryUID)
			local scrollPanel = vgui.Create("DScrollPanel")
			scrollPanel.CategoryName = categoryName
			scrollPanel.uniqueID = categoryUID
			scrollPanel.iconLayout = vgui.Create("DIconLayout", scrollPanel)
			scrollPanel.iconLayout:Dock(FILL)
			scrollPanel.iconLayout.CategoryName = categoryName
			scrollPanel.iconLayout.scroll = scrollPanel
			scrollPanel.iconLayout:SetSpaceX(self.iconXSpace)
			scrollPanel.iconLayout:SetSpaceY(self.iconYSpace)
			scrollPanel.iconLayout:MakeDroppable("KrakenShop", false)
			self.scrollPanel = scrollPanel

			local oldOnAdd = scrollPanel.iconLayout.OnChildAdded
			local oldOnRemove = scrollPanel.iconLayout.OnChildRemoved
			function scrollPanel.iconLayout:OnChildAdded(iconHolder)
				oldOnAdd(self, iconHolder)
				iconHolder.parentScrollPanel = scrollPanel -- Update the scroll panel this icon is parented to.

				if scrollPanel:IsVisible() and not scrollPanel:GetParent().SuppressDragHooks then
					scrollPanel:GetParent():OnDraggedItemIntoPanel(scrollPanel, iconHolder)
				end
			end

			function scrollPanel.iconLayout:OnChildRemoved(iconHolder)
				oldOnRemove(self, iconHolder)

				if scrollPanel:IsVisible() and not scrollPanel:GetParent().SuppressDragHooks then
					scrollPanel:GetParent():OnDraggedItemOutOfPanel(scrollPanel, iconHolder)
				end
			end

			scrollPanel.AddItem = self.AddItem
			scrollPanel.numIconsPerLine = self.numIconsPerLine

			-- Sadly have to copy some of the default dscrollpanel code over because we need to edit how some laying out is done.
			scrollPanel.iconLayout.PerformLayout = function(selfPanel, w, h)
				local ShouldLayout = false

				if selfPanel.LastW ~= selfPanel:GetWide() or selfPanel.LastH ~= selfPanel:GetTall() then
					ShouldLayout = true
				end

				selfPanel.LastW = selfPanel:GetWide()
				selfPanel.LastH = selfPanel:GetTall()

				selfPanel:SetMinimumSize(nil, self:GetTall() - 38)

				local childrenIcons = selfPanel:GetChildren()
				if #childrenIcons > 0 then
					selfPanel:SizeToChildren(selfPanel:GetStretchWidth(), selfPanel:GetStretchHeight())

					for i, icon in ipairs(childrenIcons) do
						if not IsValid(scrollPanel) then
							return
						end
						local scrollbar = scrollPanel:GetVBar()
						local scrollbarW = 0
						if scrollbar.Enabled then
							scrollbarW = scrollPanel:GetVBar():GetWide()
						end

						local availableWidth = scrollPanel:GetWide() - scrollbarW - (self.numIconsPerLine * PANEL.iconXSpace)
						local panelSize = availableWidth / self.numIconsPerLine
						icon:SetSize(panelSize, panelSize)
					end
				end

				if ShouldLayout then
					if selfPanel.m_iLayoutDir == LEFT then
						selfPanel:LayoutIcons_LEFT()
					elseif selfPanel.m_iLayoutDir == TOP then
						selfPanel:LayoutIcons_TOP()
					end
				end
			end

			local tab = self:AddSheet(categoryName, scrollPanel)
			return scrollPanel, tab
		end

		vgui.Register("KrakenShop.DNDScrollablePropertySheet", PANEL, "DPropertySheet")
	end

	--[[-------------------------------------------------------------------------
	Admin Menu
	---------------------------------------------------------------------------]]
	-- Desc:		Creates the admin menu panel.
	do
		local PANEL = {
			mainWidth = 850,
			mainHeight = 600
		}

		function PANEL:Init()
			self:SetTitle("Kraken Shop Admin")
			self:SetVisible(true)
			self:SetDraggable(true)
			self:SetSizable(false)
			self:SetSize(self.mainWidth, self.mainHeight)
			self:MakePopup()

			self.Container = vgui.Create("DPanel", self)
			self.Container:DockMargin(0,0,0,0)
			self.Container:Dock(FILL)

			local itemsByCategory = nut.KrakenShop.GetItemsByCategory()
			local sortedCategories = nut.KrakenShop.GetAlphabeticallySortedCategories()
			local sortedFactions = nut.KrakenShop.GetAlphabeticallySortedFactions()

			-- Create a scrollable, droppable, tabbed sheet of items and their categories.
			self.ItemCategories = vgui.Create("KrakenShop.DNDScrollablePropertySheet", self.Container)
			self.ItemCategories:Dock(LEFT)
			self.ItemCategories.Categories = {}
			for _, catName in ipairs(sortedCategories) do
				local scrollpanel, tab = self.ItemCategories:AddCategory(catName)
				for _, itemInfo in ipairs(itemsByCategory[catName]) do
					if not nut.KrakenShop.Items.GlobalItems[itemInfo.uniqueID] then
						scrollpanel:AddItem(itemInfo)
					end
				end

				self.ItemCategories.Categories[catName] = {}
				self.ItemCategories.Categories[catName].ScrollPanel = scrollpanel
				self.ItemCategories.Categories[catName].Tab = tab
			end

			-- Create another one of those fancy sheets but of factions and their items.
			self.AssignedItemsScrollPanel = vgui.Create("KrakenShop.DNDScrollablePropertySheet", self.Container)
			self.AssignedItemsScrollPanel:Dock(RIGHT)
			local globalFaction, globalFactionTab = self.AssignedItemsScrollPanel:AddCategory("All Factions", "allfactions")
			globalFaction.IsGlobalFaction = true
			for itemUID, _ in pairs(nut.KrakenShop.Items.GlobalItems) do
				globalFaction:AddItem(nut.KrakenShop.ItemInfoFromUID(itemUID))
			end

			for i, factionInfo in ipairs(sortedFactions) do
				local scrollPanel = self.AssignedItemsScrollPanel:AddCategory(factionInfo.name, factionInfo.uniqueID)
			end

			self.AssignedItemsScrollPanel.OnActiveTabChanged = function(_, _, newTab)
				local newCategory = newTab:GetPanel()
				local iconLayout = newCategory.iconLayout
				iconLayout:Clear()

				for categoryName, categoryInfo in pairs(self.ItemCategories.Categories) do
					categoryInfo.ScrollPanel.iconLayout:Clear()
				end

				if not newCategory.IsGlobalFaction then
					for factionItemUID in pairs(nut.KrakenShop.Items.FactionItems[newCategory.uniqueID]) do
						newCategory:AddItem(nut.KrakenShop.ItemInfoFromUID(factionItemUID))
					end

					for catName, catInfo in pairs(self.ItemCategories.Categories) do
						for _, itemInfo in ipairs(itemsByCategory[catName]) do
							if not nut.KrakenShop.Items.FactionItems[newCategory.uniqueID][itemInfo.uniqueID] then
								catInfo.ScrollPanel:AddItem(itemInfo)
							end
						end
					end
				else
					for globalItemUID, _ in pairs(nut.KrakenShop.Items.GlobalItems) do
						newCategory:AddItem(nut.KrakenShop.ItemInfoFromUID(globalItemUID))
					end

					for catName, catInfo in pairs(self.ItemCategories.Categories) do
						for _, itemInfo in ipairs(itemsByCategory[catName]) do
							if not nut.KrakenShop.Items.GlobalItems[itemInfo.uniqueID] then
								catInfo.ScrollPanel:AddItem(itemInfo)
							end
						end
					end
				end

				self.ItemCategories:InvalidateLayout(true)
				self.ItemCategories:InvalidateChildren(true)
			end

			-- When we move an item into the weapon list.
			function self.ItemCategories:OnDraggedItemIntoPanel(scrollpanel, iconPanel)
				
			end

			-- When we move an item out of the weapon list.
			function self.ItemCategories:OnDraggedItemOutOfPanel(scrollpanel, iconPanel)
				
			end

			-- When we move an item into the faction weapon list.
			function self.AssignedItemsScrollPanel:OnDraggedItemIntoPanel(scrollpanel, iconPanel)
				local factionUID = scrollpanel.uniqueID
				local itemUID = iconPanel.UID
				local isglobal = scrollpanel.IsGlobalFaction or false

				if isglobal then
					nut.KrakenShop.AddItemToAll(itemUID)
				else
					nut.KrakenShop.AddItemToFaction(itemUID, factionUID)
				end
			end

			-- When we move an item out of the faction weapon list.
			function self.AssignedItemsScrollPanel:OnDraggedItemOutOfPanel(scrollpanel, iconPanel)
				local factionUID = scrollpanel.uniqueID
				local itemUID = iconPanel.UID
				local isglobal = scrollpanel.IsGlobalFaction or false

				if isglobal then
					nut.KrakenShop.RemoveItemFromAll(itemUID)
				else
					nut.KrakenShop.RemoveItemFromFaction(itemUID, factionUID)
				end
			end

			self.ItemCategories.SuppressDragHooks = false
			self.AssignedItemsScrollPanel.SuppressDragHooks = false
		end

		function PANEL:PerformLayout(mainW, mainH)
			self.BaseClass.PerformLayout(self, mainW, mainH)

			local containerW, containerH = self.Container:GetSize()
			self.ItemCategories:SetSize(containerW/2, containerH)
			self.AssignedItemsScrollPanel:SetSize(containerW/2, containerH)
		end
		vgui.Register("KrakenShop.AdminPanel", PANEL, "DFrame")
	end

	--[[-------------------------------------------------------------------------
	Item row in the store
	---------------------------------------------------------------------------]]
	do
		local PANEL = {
			frameMaterial = Material("kraken_icons/2_ui/ui/select/input_select_frame.png")
		}

		function PANEL:Init()
			self.ItemName = vgui.Create("DLabel", self)
			self.ItemName:SetFont("nutMediumFont")
			self.ItemName:SetText("Unset Item Name")

			self.SelectButton = vgui.Create("KrakenShop.Button", self)
			self.SelectButton:SetText("SELECT")
			self.SelectButton.DoClick = function()
				self:ItemSelected(self.ItemInfo)
			end

			self.ItemInfo = nil
		end

		-- Called when you press select on the item row.
		function PANEL:ItemSelected(itemInfo)
			-- override
		end

		-- Sets the item info of the row.
		function PANEL:SetItem(itemInfo)
			self.ItemInfo = itemInfo
			self.ItemName:SetText(itemInfo.name)
			self.ItemName:SizeToContents()
		end

		-- Gets the item info of the row.
		function PANEL:GetItem()
			return self.ItemInfo
		end
		
		function PANEL:Paint(w, h)
			surface.SetDrawColor(color_white)
			surface.SetMaterial(self.frameMaterial)
			surface.DrawTexturedRect(0, 0, w, h)
		end

		function PANEL:PerformLayout(w, h)
			self.ItemName:SetPos(10, h/2 - self.ItemName:GetTall()/2)
			self.SelectButton:SetSize(w * 0.3, h * 0.8)
			self.SelectButton:SetPos(w - self.SelectButton:GetWide() - 10, h/2 - self.SelectButton:GetTall()/2)
		end
		vgui.Register("KrakenShop.ItemRow", PANEL, "DPanel")
	end

	--[[-------------------------------------------------------------------------
	Item info panel
	---------------------------------------------------------------------------]]
	do
		local PANEL = {
			panelFrame = Material("kraken_icons/2_ui/ui/select/input_select_frame.png")
		}
		function PANEL:Init()
			self.ModelPreview = vgui.Create("DModelPanel", self)
			self.ItemInfo = nil

			self.ItemDescPanel = vgui.Create("DPanel", self)
			self.ItemDescPanel.Paint = function(selfPanel, w, h)
				surface.SetDrawColor(color_white)
				surface.SetMaterial(self.panelFrame)
				surface.DrawTexturedRect(0, 0, w, h)
			end

			self.ItemNameLabel = vgui.Create("DLabel", self.ItemDescPanel)
			self.ItemNameLabel:SetFont("nutMediumFont")

			self.ItemDescLabel = vgui.Create("DLabel", self.ItemDescPanel)
			self.ItemDescLabel:SetFont("nutSmallFont")

			self.ItemPriceLabel = vgui.Create("DLabel", self.ItemDescPanel)
			self.ItemPriceLabel:SetFont("nutMediumFont")

			if nut.KrakenShop.CanUseAdminMenu(LocalPlayer()) then
				self.AdminMenuButton = vgui.Create("KrakenShop.Button", self)
				self.AdminMenuButton:SetText("Admin Menu")
				self.AdminMenuButton.DoClick = function()
					if IsValid(nut.KrakenShop.AdminPanel) then
						nut.KrakenShop.CloseAdminMenu()

						-- Wait for full remove.
						timer.Simple(0.05, function()
							nut.KrakenShop.OpenAdminMenu()
						end)
					else
						nut.KrakenShop.OpenAdminMenu()
					end
				end
			end

			self.PurchaseButton = vgui.Create("KrakenShop.Button", self)
			self.PurchaseButton:SetText("Purchase")
			self.PurchaseButton.DoClick = function(selfPanel)
				if not istable(self.ItemInfo) or not isstring(self.ItemInfo.uniqueID) then
					error("Tried to purchase nil item!")
				end

				net.Start("KrakenShop.RequestPurchase")
					net.WriteString(self.ItemInfo.uniqueID)
				net.SendToServer()
			end
		end
		
		-- Sets the active item to show info about.
		function PANEL:SetActiveItem(itemInfo)
			self.ItemInfo = itemInfo
			self.ModelPreview:SetModel(itemInfo.model)

			self.ItemNameLabel:SetText(itemInfo.name)
			self.ItemNameLabel:SizeToContents()

			local desc = itemInfo.desc
			if desc == "noDesc" then
				desc = ""
			end
			self.ItemDescLabel:SetText(desc)
			self.ItemDescLabel:SetAutoStretchVertical(true)
			self.ItemDescLabel:SetWrap(true)

			local faction = nut.faction.indices[LocalPlayer():getChar():getFaction()].uniqueID
			self.ItemPriceLabel:SetText("$"..tostring(nut.KrakenShop.GetItemPrice(itemInfo.uniqueID, faction)))
			self.ItemPriceLabel:SizeToContents()

			-- Thanks Pointshop.
			local prevMins, prevMaxs = self.ModelPreview.Entity:GetRenderBounds()
			self.ModelPreview:SetCamPos(prevMins:Distance(prevMaxs) * Vector(0.5, 0.5, 0.5))
			self.ModelPreview:SetLookAt((prevMaxs + prevMins) / 2)
			self:InvalidateLayout()
		end

		function PANEL:Paint()
		end

		function PANEL:PerformLayout(w, h)
			self.ModelPreview:SetSize(w, h * .65)
			self.ModelPreview:SetPos(0,0)

			self.ItemDescPanel:SetPos(0, h * .68)
			self.ItemDescPanel:SetSize(w, h * 0.20)
			local itemDescPanelWide = self.ItemDescPanel:GetWide()

			self.ItemNameLabel:SetPos(10, 15)
			self.ItemDescLabel:SetPos(10, 15 + self.ItemNameLabel:GetTall())
			self.ItemDescLabel:SetWide(itemDescPanelWide - 10)
			self.ItemPriceLabel:SetPos(itemDescPanelWide - self.ItemPriceLabel:GetWide() - 10, self.ItemDescPanel:GetTall() - self.ItemPriceLabel:GetTall() - 10)

			self.PurchaseButton:SetSize(w*.4, h*.12)
			self.PurchaseButton:SetPos(w - self.PurchaseButton:GetWide(), h * .87)

			if IsValid(self.AdminMenuButton) then
				self.AdminMenuButton:SetSize(w*.4, h*.12)
				self.AdminMenuButton:SetPos(5, h * .87)
			end
		end
		
		vgui.Register("KrakenShop.ItemInfo", PANEL, "DPanel")
	end

	--[[-------------------------------------------------------------------------
	Main Kraken Store panel
	---------------------------------------------------------------------------]]
	-- Creates the main Kraken Store front.
	do
		local PANEL = {
			mat_ItemFrame = Material("kraken_icons/2_ui/ui/select/input_select_frame.png"),
			mat_MenuBackground = Material("kraken_icons/2_ui/ui/window/window.png"),
			mat_CloseButton = Material("kraken_icons/2_ui/ui/window/window_close_btn.png"),
			mat_CloseButtonHover = Material("kraken_icons/2_ui/ui/window/window_close_btn_hover.png"),
			mat_CloseButtonPressed = Material("kraken_icons/2_ui/ui/window/window_close_btn_push.png"),

			screenScale = 0.75,	-- Percentage of screen the menu takes up, used to scale properly on all screen sizes.

			width = 700,	-- My 2nd gen ipod touch had a better resolution than this.
			height = 400	-- Not going to support anything smaller.
		}

		function PANEL:Init()
			local ply = LocalPlayer()
			if not IsValid(ply) or not istable(ply:getChar()) then
				self:Remove()
				return
			end

			local plyChar = ply:getChar()

			self:MakePopup()
			self:SetTitle("")
			self:SetVisible(true)
			self:SetDraggable(true)
			self:ShowCloseButton(false)
			self:SetSizable(true)
			self:SetMinWidth(self.width)
			self:SetMinHeight(self.height)

			-- The only size that should be set in init, so that the rest of the UI can bet laid out in PerformLayout.
			self:SetSize(ScrW() * self.screenScale, ScrH() * self.screenScale)

			-- Close button
			self.CloseButton = vgui.Create("DButton", self)
			self.CloseButton:SetMouseInputEnabled(true)
			self.CloseButton:SetCursor("hand")
			self.CloseButton:SetText("")
			self.CloseButton.DoClick = function()
				self:Remove()
			end
			self.CloseButton.Paint = function(btn, w, h)
				surface.SetDrawColor(color_white)

				surface.SetMaterial(self.mat_CloseButton)
				surface.DrawTexturedRect(0, 0, w, h)

				-- If pressed make it darker, if hovered make it lighter.
				if btn:IsHovered() then
					if input.IsButtonDown(MOUSE_FIRST) then
						surface.SetMaterial(self.mat_CloseButtonPressed)
						surface.DrawTexturedRect(24, 6, 26, 26)
					else
						surface.SetMaterial(self.mat_CloseButtonHover)
						surface.DrawTexturedRect(24, 6, 26, 26)	
					end
				end
			end

			local plyFaction = nut.faction.indices[plyChar:getFaction()].uniqueID

			self.ContentPanel = vgui.Create("DPanel", self)
			self.ContentPanel:Dock(FILL)
			self.ContentPanel:DockMargin(20, 5, 20, 15)
			function self.ContentPanel:Paint() end

			self.ItemList = vgui.Create("DScrollPanel", self.ContentPanel)
			self.ItemList:Dock(LEFT)
			self.ItemList.Rows = {}

			self.ItemInfoPanel = vgui.Create("KrakenShop.ItemInfo", self.ContentPanel)
			self.ItemInfoPanel:Dock(RIGHT)
			self.ItemInfoPanel:SetVisible(false)

			self:UpdateItems()
		end

		function PANEL:PerformLayout(mainW, mainH)
			self.CloseButton:SetSize(70, 40)
			self.CloseButton:SetPos(mainW - self.CloseButton:GetWide(), 0)

			self.ItemInfoPanel:SetWide(self.ContentPanel:GetWide()/2)
			self.ItemList:SetWide(self.ContentPanel:GetWide()/2)

			for i, row in ipairs(self.ItemList.Rows) do
				row:SetWide(self.ItemList:GetWide())
				row:SetTall(self.ItemList:GetTall() * .1)
			end

			if IsValid(self.NoItemsLabel) then
				self.NoItemsLabel:SetPos(mainW/2 - self.NoItemsLabel:GetWide()/2, mainH/2 - self.NoItemsLabel:GetTall()/2)
			end

			if IsValid(self.NoItemsAdminButton) then
				self.NoItemsAdminButton:SetSize(mainW * 0.25, mainH * 0.15)
				self.NoItemsAdminButton:SetPos(mainW/2 - self.NoItemsAdminButton:GetWide()/2, mainH/2 + self.NoItemsLabel:GetTall()/2)
			end
		end

		function PANEL:Paint(w, h)
			surface.SetDrawColor(color_white)
			surface.SetMaterial(self.mat_MenuBackground)
			surface.DrawTexturedRect(0, 0, w, h)
		end

		function PANEL:OnKeyCodePressed(key)
			if key == KEY_F4 then
				self:Remove()
				justClosedMenu = true
			end
		end

		-- Updates what items should display in the player's store.
		function PANEL:UpdateItems()
			self.ItemList:GetChild(0):Clear()

			local ply = LocalPlayer()
			local plyChar = ply:getChar()
			local plyFaction = nut.faction.indices[plyChar:getFaction()].uniqueID
			local firstButton
			self.ItemList.Rows = {}

			for _, itemUID in ipairs(nut.KrakenShop.GetItemsForFaction(plyFaction)) do
				local row = vgui.Create("KrakenShop.ItemRow", self.ItemList)
				row:Dock(TOP)
				row:SetItem(nut.KrakenShop.ItemInfoFromUID(itemUID))
				row.ItemSelected = function(selfPanel, itemInfo)
					self.ItemInfoPanel:SetVisible(true)
					self.ItemInfoPanel:SetActiveItem(itemInfo)
				end

				if not firstButton then
					firstButton = row
				end

				table.insert(self.ItemList.Rows, row)
			end

			if firstButton then
				firstButton.SelectButton:DoClick()

				if IsValid(self.NoItemsLabel) then
					self.NoItemsLabel:Remove()
				end

				if IsValid(self.NoItemsAdminButton) then
					self.NoItemsAdminButton:Remove()
				end
			else
				self.ItemInfoPanel:SetVisible(false)

				self.NoItemsLabel = vgui.Create("DLabel", self)
				self.NoItemsLabel:SetFont("nutBigFont")
				self.NoItemsLabel:SetTextColor(color_white)
				self.NoItemsLabel:SetText("No items available!")
				self.NoItemsLabel:SizeToContents()

				if nut.KrakenShop.CanUseAdminMenu(LocalPlayer()) then
					self.NoItemsAdminButton = vgui.Create("KrakenShop.Button", self)
					self.NoItemsAdminButton:SetLargeFont(true)
					self.NoItemsAdminButton:SetText("Admin Menu")
					self.NoItemsAdminButton.DoClick = function()
						if IsValid(nut.KrakenShop.AdminPanel) then
							nut.KrakenShop.CloseAdminMenu()

							-- Wait for full remove.
							timer.Simple(0.1, function()
								nut.KrakenShop.OpenAdminMenu()
							end)
						else
							nut.KrakenShop.OpenAdminMenu()
						end
					end
				end
			end

			self:InvalidateLayout()
		end

		function PANEL:OnRemove()
			surface.PlaySound("ui/buttonclick.wav")
		end
		vgui.Register("KrakenShop", PANEL, "DFrame")
	end
end
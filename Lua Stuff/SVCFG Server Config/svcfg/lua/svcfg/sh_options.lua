if SERVER then
	util.AddNetworkString("SVCFG.NetworkCallback")
end

svcfg.options = {
	SettingsPanels = {}
}
svcfg.menu = svcfg.menu or {sheets = {}}


-----------------------
-- svcfg.menu.AddSheet
-----------------------
-- Desc:		Adds a sheet to the top of the svcfg menu.
-- Arg One:		String, name of sheet.
-- Arg Two:		String, icon16 name.
-- Arg Thr:		Function, will be called when the sheet is made.
-- 				Arguements to the function are dpanel, dpanel_height.
function svcfg.menu.AddSheet(nm, icn, fn)
	local sheet = {
		SettingsPanels = {},
		name = nm,
		icon = icn,
		func = fn
	}

	function sheet:AddSettingsPanel(name, desc)
		local SettingsPanel = {}
		SettingsPanel.label = name
		SettingsPanel.label_hover = desc
		SettingsPanel.Items = {}
		table.insert(svcfg.options.SettingsPanels, SettingsPanel)
		table.insert(sheet.SettingsPanels, SettingsPanel)

		local SettingsPnlIndex = #svcfg.options.SettingsPanels
		SettingsPanel.SettingsPanelIndex = SettingsPnlIndex

		function SettingsPanel:AddItem(itemType, item)
			item = item or {}
			item.type = itemType
			item.SettingsPanelIndex = SettingsPnlIndex
			item.SettingsPanelItemIndex = #self.Items + 1
			item.clCallbacks = {}
			item.svCallbacks = {}

			------------------------------------------------
			-- SVCFGSettingsPanelItem:AddClientsideCallback
			------------------------------------------------
			-- Desc:		Adds a clientside callback to one of the panel's functions.
			-- Arg One:		String, name of the callback to listen on.
			-- Arg Two:		String, a unique name for the callback in case you want to remove it later.
			-- Arg Three:	Function, call with the arguements to the callback plus the panel as the last callback.
			function item:AddClientsideCallback(callbackName, uniqueName, func)
				if not istable(item.clCallbacks[callbackName]) then
					item.clCallbacks[callbackName] = {}
				end
				item.clCallbacks[callbackName][uniqueName] = func
			end

			---------------------------------------------------
			-- SVCFGSettingsPanelItem:RemoveClientsideCallback
			---------------------------------------------------
			-- Desc:		Removes a clientside callback.
			-- Arg One:		String, name of the callback to remove.
			-- Arg Two:		String, the unique identifier of the callback.
			function item:RemoveClientsideCallback(callbackName, uniqueName)
				if not istable(item.clCallbacks[callbackName]) then
					return
				end
				item.clCallbacks[callbackName][uniqueName] = nil
			end

			------------------------------------------------
			-- SVCFGSettingsPanelItem:AddServersideCallback
			------------------------------------------------
			-- Desc:		Adds a clientside callback to one of the panel's functions.
			-- Arg One:		String, name of the callback to listen on.
			-- Arg Two:		String, a unique name for the callback in case you want to remove it later.
			-- Arg Three:	Function, call with the arguements to the callback plus the panel as the last callback.
			function item:AddServersideCallback(callbackName, uniqueName, func)
				if not istable(item.svCallbacks[callbackName]) then
					item.svCallbacks[callbackName] = {}
				end
				item.svCallbacks[callbackName][uniqueName] = func
			end

			---------------------------------------------------
			-- SVCFGSettingsPanelItem:RemoveServersideCallback
			---------------------------------------------------
			-- Desc:		Removes a clientside callback.
			-- Arg One:		String, name of the callback to remove.
			-- Arg Two:		String, the unique identifier of the callback.
			function item:RemoveServersideCallback(callbackName, uniqueName)
				if not istable(item.svCallbacks[callbackName]) then
					return
				end
				item.svCallbacks[callbackName][uniqueName] = nil
			end

			table.insert(self.Items, item)
			return item
		end

		return SettingsPanel
	end

	table.insert(svcfg.menu.sheets, sheet)
	return sheet
end

function svcfg.menu.GetSheet(name)
	for k, v in pairs(svcfg.options.SettingsPanels) do
		if v.label == name then
			return v
		end
	end
end

---------------------------------------
-- svcfg.options.RunClientsideCallback
---------------------------------------
-- Desc:		Called when a clientside callback should be ran.
-- Arg One:		Table, contains info on the item.
-- Arg Two:		String, the name of the callback to be ran.
-- Arg Three:	Varargs, the arguements to the callback function.
function svcfg.options.RunClientsideCallback(info, callbackName, ...)
	if istable(info.clCallbacks[callbackName]) then
		for k, v in pairs(info.clCallbacks[callbackName]) do
			v(...)
		end
	end
end

svcfg.options.ServersideCallbackNetworkHandlers = {
	count = -1
}
function svcfg.options.AddServersideCallbackNetworkHandler(panelType, panelCallbackName, write, read)
	if not istable(svcfg.options.ServersideCallbackNetworkHandlers[panelType]) then
		local cnt = svcfg.options.ServersideCallbackNetworkHandlers.count + 1
		svcfg.options.ServersideCallbackNetworkHandlers.count = cnt

		svcfg.options.ServersideCallbackNetworkHandlers[panelType] = {
			PanelTypeID = svcfg.options.ServersideCallbackNetworkHandlers.count,
			count = -1
		}
	end
 
	svcfg.options.ServersideCallbackNetworkHandlers[panelType].count = svcfg.options.ServersideCallbackNetworkHandlers[panelType].count + 1
	local CallbackIDNum = svcfg.options.ServersideCallbackNetworkHandlers[panelType].count
	svcfg.options.ServersideCallbackNetworkHandlers[panelType][CallbackIDNum] = panelCallbackName

	svcfg.options.ServersideCallbackNetworkHandlers[panelType][panelCallbackName] = {}
	svcfg.options.ServersideCallbackNetworkHandlers[panelType][panelCallbackName].Write = write
	svcfg.options.ServersideCallbackNetworkHandlers[panelType][panelCallbackName].Read = read
	svcfg.options.ServersideCallbackNetworkHandlers[panelType][panelCallbackName].CallbackID = CallbackIDNum
end

function svcfg.options.SendServersideCallbackInfo(callbackName, item, ...)
	if not istable(item.svCallbacks[callbackName]) then
		return
	end

	net.Start("SVCFG.NetworkCallback")
		-- Which settings panel ID.
		net.WriteUInt(item.SettingsPanelIndex, 9)

		-- Which item index in that settings panel.
		net.WriteUInt(item.SettingsPanelItemIndex, 9)

		-- Which callback of that item.
		net.WriteUInt(svcfg.options.ServersideCallbackNetworkHandlers[item.type][callbackName].CallbackID, 5)

		-- The callback arguements.
		svcfg.options.ServersideCallbackNetworkHandlers[item.type][callbackName].Write(...)
	net.SendToServer()
end

if SERVER then
	net.Receive("SVCFG.NetworkCallback", function(_, ply)
		local panelIndex = net.ReadUInt(9)
		local SettingsPanel = svcfg.options.SettingsPanels[panelIndex]

		local itemIndex = net.ReadUInt(9)
		local item = SettingsPanel.Items[itemIndex]

		local itemType = item.type
		local CallbackID = net.ReadUInt(5)
		local callbackName = svcfg.options.ServersideCallbackNetworkHandlers[itemType][CallbackID]
		local args = table.pack(svcfg.options.ServersideCallbackNetworkHandlers[itemType][callbackName].Read())

		for k, v in pairs(item.svCallbacks[callbackName]) do
			v(unpack(args), ply)
		end
	end)
end
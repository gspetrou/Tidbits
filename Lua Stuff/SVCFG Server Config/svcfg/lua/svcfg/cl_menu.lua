-- THIS FILE:
-- Accounts for how the menu appears and should look.

local frame_w, frame_h = 770, 500

svcfg.menu = {}
svcfg.menu.sheets = {}
local dpropertysheet_header_h = 38	-- Theres no way to get this number so we just have to make it a constant sadly.

---------------------
-- svcfg.menu.OpenUI
---------------------
-- Desc:		Opens the UI, duh.
function svcfg.menu.OpenUI()
	local frame = vgui.Create("DFrame")
	frame:SetSize(frame_w, frame_h)
	frame:Center()
	frame:SetTitle("Server Configuration Menu v1.0")
	frame:MakePopup()

	local sheet = vgui.Create("DPropertySheet", frame)
	sheet:Dock(FILL)
	sheet:InvalidateParent(true)
	local innerDPanel_h = sheet:GetTall() - dpropertysheet_header_h

	for i, v in ipairs(svcfg.menu.sheets) do
		local dpanel = vgui.Create("DPanel", sheet)
		v.func(v.SettingsPanels, dpanel, innerDPanel_h)
		sheet:AddSheet(v.name, dpanel, "icon16/"..v.icon..".png")
	end
end

concommand.Add("svcfg", function()
	svcfg.menu.OpenUI()
end)


--------------------------
-- svcfg.menu.ClearDPanel
--------------------------
-- Desc:		Clears a of its children, how sad.
-- Arg One:		The panel to clear of children.
function svcfg.menu.ClearDPanel(panel)
	local children = panel:GetChildren()
	for i, v in ipairs(children) do
		v:Remove()
	end
end


------------------------------
-- svcfg.menu.PanelOperations
------------------------------
-- Desc:		Table containning many instructions for how to impliment certain panels. Used with svcfg.menu.PopuladteDPanelFromTable.
svcfg.menu.PanelOperations = {}

--------------------------------
-- svcfg.menu.AddPanelOperation
--------------------------------
-- Desc:		Adds a panel operation to svcfg.menu.PanelOperations. For use with svcfg.menu.PopuldateDPanelFromTable.
-- Arg One:		String, operation name. (Ex: slider, checkbox, combobox)
-- Arg Two:		Function, will be used to build the sub-panel
--				Arg One:	Table, info on the settings for the panel they want to make.
--				Return:		Make sure you return the panel you make.
function svcfg.menu.AddPanelOperation(operationName, func)
	svcfg.menu.PanelOperations[operationName] = func
end

--------------------------------------
-- svcfg.menu.PopulateDPanelFromTable
--------------------------------------
-- Desc:		Given a table fitting the documenation and a dpanel this will populate the dpanel with children.
-- Arg One:		Panel, dpanel we are going to populate.
-- Arg Two:		Table, must be structured in a certain way, will be used to populate the dpanel.
function svcfg.menu.PopulateDPanelFromTable(ParentDPanel, Instructions)
	for i, v in ipairs(Instructions) do
		if not v.type or not isfunction(svcfg.menu.PanelOperations[v.type]) then
			error("SVCFG: Attempted to create invalid panel type '".. (v.type or "MISSING TYPE") .."'.")
		else
			local subpanel = svcfg.menu.PanelOperations[v.type](v)
			subpanel:SetParent(ParentDPanel)
			subpanel:DockMargin(5, 0, 5, 5)
			subpanel:Dock(TOP)

			if v.convar then
				if not ConVarExists(v.convar) then
					CreateClientConVar(v.convar, v.convar_default or 0)
				end

				subpanel:SetConVar(v.convar)
			end
		end
	end
end
-- These will be the same for both player and game settings
-- so might as well define them here.
local scrollbar_w = 15
local button_w, button_h = 135, 20
local header_h = 25

-- Add our game settings menu.
local SHEET = svcfg.menu.AddSheet("Game Settings", "world", function(parentTable, parent_dpanel, parent_dpanel_h)
	-- First lets make a scrollpanel to contain all of our settings.
	local SettingsBar = {}

	-- Calculate how wide the scrollpanel should be if it needs a scrollbar.
	SettingsBar.w = button_w
	SettingsBar.NumOptions = #parentTable
	if (button_h * SettingsBar.NumOptions) > parent_dpanel_h then
		SettingsBar.w = SettingsBar.w + scrollbar_w
	end

	-- Make the scrollpanel for the settings bar.
	SettingsBar.ScrollPanel = vgui.Create("DScrollPanel", parent_dpanel)
	SettingsBar.ScrollPanel:SetSize(SettingsBar.w, 0)
	SettingsBar.ScrollPanel:Dock(LEFT)

	-- Now make a second scrollpanel to contain all of our options. 
	local OptionsPanel = {}
	OptionsPanel.ScrollPanel = vgui.Create("DScrollPanel", parent_dpanel)
	OptionsPanel.ScrollPanel:Dock(FILL)
	OptionsPanel.ScrollPanel_InnerDPanel = OptionsPanel.ScrollPanel:GetChild(1)
	OptionsPanel.ScrollPanel_InnerDPanel:DockPadding(0, 5, 0, 5)

	-- Lastly, populate both scrollpanels with what they should contain.
	local LastButtonClicked
	for i, v in ipairs(parentTable) do
		local SettingButton = vgui.Create("DButton", SettingsBar.ScrollPanel)
		SettingButton:SetIsToggle(true)
		SettingButton:SetSize(button_w, button_h)
		SettingButton:SetPos(0, (i-1) * button_h)
		SettingButton:SetText(v.label)
		SettingButton:SetTooltip(v.label_hover or "MISSING LABEL_HOVER")
		SettingButton.SettingsBarIndex = i

		local oldDoClick = SettingButton.DoClick
		function SettingButton:DoClick()
			oldDoClick(self)

			if IsValid(LastButtonClicked) then
				LastButtonClicked:SetToggle(false)
			end

			svcfg.menu.ClearDPanel(OptionsPanel.ScrollPanel_InnerDPanel)
			svcfg.menu.PopulateDPanelFromTable(OptionsPanel.ScrollPanel, v.Items)
			LastButtonClicked = self
		end
	end
end)

local SETTINGSPANEL = SHEET:AddSettingsPanel("Physics", "Edit the physics in the game.")

local slider = SETTINGSPANEL:AddItem("slider", {
	label = "Here is a test value",
	min = 0,
	max = 40
})

slider:AddClientsideCallback("OnValueChanged", "CLTest", function(newval, panel)
	print("CL: New value: ".. newval)
end)

slider:AddServersideCallback("OnValueChanged", "SVTest", function(newval, ply)
	print("SV: New value: ".. newval)
end)


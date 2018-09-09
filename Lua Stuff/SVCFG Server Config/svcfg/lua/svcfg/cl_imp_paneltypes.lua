svcfg.menu.AddPanelOperation("text", function(info)
	local dlabel
	if info.IsURL then
		dlabel = vgui.Create("DLabelURL")
		dlabel:SetURL(info.URL or "You forgot to set a URL, dumbfuck.")
	else
		dlabel = vgui.Create("DLabel")
	end
	dlabel:SetText(info.text or "MISSING TEXT")
	dlabel:SizeToContents()
	
	if info.font then
		dlabel:SetFont(info.font)
	end

	if IsColor(info.color) then
		dlabel:SetColor(info.color)
	end

	return dlabel
end)

svcfg.menu.AddPanelOperation("textentry", function(info)
	local spacer = vgui.Create("Panel", dpanel)
	spacer:SetHeight(info.height or 100)

	return spacer
end)

svcfg.menu.AddPanelOperation("textentry", function(info)
	local dtextentry = vgui.Create("DTextEntry")
	dtextentry:SetNumeric(info.NumbersOnly or false)

	function dtextentry:OnValueChange(text)
		-- impliment callbacks later.
	end

	return dtextentry
end)

svcfg.menu.AddPanelOperation("richtext", function(info)
	local richtext = vgui.Create("RichText")

	if type(info.SetupText) ~= "function" then
		error("SVCFG: RichText panel missing SetupText function.")
	else
		info.SetupText(richtext)
	end
	
	if not info.EnableScrolling then
		richtext:SetVerticalScrollbarEnabled(false)
	end

	if info.FullHeight then
		timer.Simple(0, function()
			if IsValid(richtext) then
				richtext:SetToFullHeight(true)
			end
		end)
	end

	return richtext
end)

svcfg.menu.AddPanelOperation("slider", function(info)
	local dslider = vgui.Create("DNumSlider")
	dslider:SetText(info.label or "MISSING LABEL")
	dslider:SetMin(info.min or 0)
	dslider:SetMax(info.max or 100)
	dslider:SetDecimals(info.decimals or 0)
	dslider:SizeToContents()

	function dslider:OnValueChanged(newval)
		svcfg.options.RunClientsideCallback(info, "OnValueChanged", newval, self)
		svcfg.options.SendServersideCallbackInfo("OnValueChanged", info, newval)
	end

	return dslider
end)

svcfg.menu.AddPanelOperation("checkbox", function(info)
	local dcheckbox = vgui.Create("DCheckBoxLabel")
	dcheckbox:SetText(info.label or "MISSING LABEL")
	dcheckbox:SetValue(info.StartValue or 0)

	function dcheckbox:OnChange(ischecked)

	end

	return dcheckbox
end)

svcfg.menu.AddPanelOperation("dropdown", function(info)
	local dcombobox = vgui.Create("DComboBox")
	dcombobox:SetValue(info.label or "MISSING LABEL")

	if #info.choices == 0 then
		error("SVCFG: Attempted to build a DComboBox without any choices.")
	else
		for i, v in ipairs(info.choices) do
			dcombobox:AddChoice(v)
		end
	end

	function dcombobox:OnSelect(index, value)

	end

	return dcombobox
end)

svcfg.menu.AddPanelOperation("numberbox", function(info)
	local dnumwang = vgui.Create("DNumberWang")
	dnumwang:SetMin(info.min or 0)
	dnumwang:SetMax(info.max or 100)
	dnumwang:SetDecimals(info.decimals or 0)

	function dnumwang:OnValueChanged(val)
		
	end

	return dnumwang
end)

svcfg.menu.AddPanelOperation("button", function(info)
	local dbutton = vgui.Create("DButton")
	dbutton:SetText(info.label or "MISSING LABEL")

	function dbutton:DoClick()
		
	end

	return dbutton
end)

svcfg.menu.AddPanelOperation("colormixer", function(info)
	local dcolormixer = vgui.Create("DColorMixer")
	dcolormixer:SetWangs(info.WangsDisabled or false)
	dcolormixer:SetPalette(info.PaletteDisabled or false)
	dcolormixer:SetAlphaBar(info.AlphaBarDisabled or false)

	if IsColor(info.DefaultColor) then
		dcolormixer:SetColor(info.DefaultColor)
	end

	if type(info.ConVarR) == "string" then dcolormixer:SetConVarG(info.ConVarR) end
	if type(info.ConVarG) == "string" then dcolormixer:SetConVarG(info.ConVarG) end
	if type(info.ConVarB) == "string" then dcolormixer:SetConVarG(info.ConVarB) end
	if type(info.ConVarA) == "string" then dcolormixer:SetConVarG(info.ConVarA) end

	function dcolormixer:ValueChanged(col)
		
	end

	return dcolormixer
end)

svcfg.menu.AddPanelOperation("listview", function(info)
	local dlistview = vgui.Create("DListView")
	dlistview:SetHideHeaders(info.hideheader or false)
	dlistview:SetMultiSelect(info.multiselect or false)
	dlistview:SetSortable(info.sortable or true)

	for i, v in ipairs(info.columns) do
		dlistview:AddColumn(v)
	end

	for i, v in ipairs(info.lines) do
		dlistview:AddLine(unpack(v))
	end

	if type(info.PostInit) == "function" then
		info.PostInit(dlistview)
	end

	function dlistview:OnRowSelected(index, linePanel)
		
	end


	function dlistview:OnRowRightClick(index, linePanel)
		
	end

	local numLines = #dlistview:GetLines()
	dlistview:SetHeight(numLines*dlistview:GetDataHeight() + dlistview:GetHeaderHeight())

	return dlistview
end)

local default_derma = derma.GetDefaultSkin()
svcfg.menu.AddPanelOperation("tree", function(info)
	local dtree = vgui.Create("DTree", dpanel)
	dtree:SetShowIcons(info.showicons or false)
	dtree:SetHeight(info.Panelheight or 200)

	if type(info.PostInit) == "function" then
		info.PostInit(dtree)
	end

	if type(info.OnNodeSelected) == "function" then
		-- We have to do some borderline stupidity to fix how nodes are highlighted when selected.
		function dtree:OnNodeSelected(node)
			local lbl = node.Label
			function lbl:Paint(w, h)
				if lbl.m_bSelected then
					w = self:GetTextSize()
					default_derma.tex.Selection(20, 0, w, h)
				else
					derma.SkinHook("Paint", "TreeNodeButton", self, w, h)
					return false
				end
			end

			info.OnNodeSelected(self, node)
		end
	end

	function dtree:DoClick(node)
		
	end

	function dtree:DoRightClick(node)
		
	end

	return dtree
end)

svcfg.menu.AddPanelOperation("filebrowser", function(info)
	local dfilebrowser = vgui.Create("DFileBrowser", dpanel)
	dfilebrowser:SetPath(info.path)
	dfilebrowser:SetBaseFolder(info.BaseFolder)
	dfilebrowser:SetCurrentFolder(info.StartFolder)
	dfilebrowser:SetName(info.StartFolderName or info.BaseFolder)
	dfilebrowser:SetFileTypes(info.Filetypes or "*.*")
	dfilebrowser:SetOpen(info.StartOpen or false)
	dfilebrowser:SetModels(info.ShowModels or false)
	dfilebrowser:SetHeight(info.PanelHeight or 200)

	if type(info.PostInit) == "function" then
		info.PostInit(dfilebrowser)
	end

	function dfilebrowser:OnSelect(filepath, selectedpaneL)

	end

	function dfilebrowser:OnDoubleClick(filepath, selectedpaneL)

	end

	function dfilebrowser:OnRightClick(filepath, selectedpaneL)

	end

	return dfilebrowser
end)

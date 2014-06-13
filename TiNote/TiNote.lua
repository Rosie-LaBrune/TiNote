
local TN		= {}
TN.default		= {
	anchor 		= { TOPLEFT, TOPLEFT, 0, 0},
	movable		= true,
	width			= 200,
	height		= 400,
	hideNote		= false,
	hideMainPanel 	= false,
	text			= "Drag and drop the bottom right corner to change the dimensions \n\n No mousewheel interaction, use page up and page down, sorry :( \n\n The text is saved when you click outside the window"
			}
	
TN.movable = true
TN.hideNote = false
TN.moveCorner = false
--TN.width = 200
--TN.height = 400
TN.offsetX = 0
TN.offsetY = 2
TN.lastOffsetX = 0
TN.lastOffsetY = 2

function TN:OnAddOnLoaded( eventCode, addOnName )
	
	if ( addOnName ~= "TiNote") then return end
	
	TiNote:SetHandler( "OnMouseUp", function()  TN:SaveAnchor() end )
		
	TN.vars = ZO_SavedVars:New("TiNote_Vars",1,"TiNote",TN.default)
	
	-- Need to clear anchors, since SetAnchor() will just keep adding new ones.
	TiNote:ClearAnchors()
	TiNote:SetAnchor(TN.vars.anchor[1], TiNote.parent, TN.vars.anchor[2], TN.vars.anchor[3], TN.vars.anchor[4])
	
	TN.movable = TN.vars.movable
		
	-- fix or movable
	self:UpdateMovable()
	
	-- init config panel
	self:InitConfigPanel()
	
	-- init corner
	TiNoteCorner:SetHandler("OnMouseDown", function() TN:MoveCorner(true) end)
	TiNoteCorner:SetHandler("OnMouseUp", function() TN:MoveCorner(false) end)
	
	-- init note panel
	self:InitNotePanel()
	
	-- init edit box
	TiNoteEditBox:SetHandler("OnFocusLost", function() TN:SaveText() end)
	
	-- keybinding
	ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_TINOTE", "Toggle TiNote")
	
	-- init main panel visibility
	self:UpdateMainVisibility()
	
end

function ToggleTiNote()
	local isHidden = not TN.vars.hideMainPanel
	TN.vars.hideMainPanel = isHidden
	TiNote:SetHidden(isHidden)
end

function TN:UpdateMainVisibility()
	TiNote:SetHidden(self.vars.hideMainPanel)
end

function TN:OnReticleHidden(eventCode, hidden)
	TiNoteEditBox:SetEditEnabled(hidden)
end


EVENT_MANAGER:RegisterForEvent("TiNote" , EVENT_ADD_ON_LOADED , function(_event, _name) TN:OnAddOnLoaded(_event, _name) end)
EVENT_MANAGER:RegisterForEvent("TiNote" , EVENT_RETICLE_HIDDEN_UPDATE, function(_event, _hidden) TN:OnReticleHidden(_event, _hidden) end)

function TiNoteUpdate()
	if not TN.moveCorner then
		return
	end
	
	TN:UpdateNoteDimension()
end

function TiNoteToggleNote()
	TN.hideNote = not TN.hideNote
	TN.vars.hideNote = TN.hideNote
	TN:UpdateNoteVisibility()
end

function TN:UpdateNoteVisibility()
	TiNotePanel:SetHidden(self.hideNote)
end

function TN:InitNotePanel()
	local xx = self.vars.width
	local yy = self.vars.height
	--TiNote:SetDimensions(xx,yy+20)
	TiNotePanel:SetDimensions(xx,yy)
	TiNoteBG:SetDimensions(xx,yy)
	TiNoteEditBox:SetDimensions(xx-10,yy-10)
		
	TiNoteEditBox:SetText(self.vars.text)
	
	TiNoteCorner:ClearAnchors()
	TiNoteCorner:SetAnchor(BOTTOMRIGHT,TiNoteBG ,BOTTOMRIGHT, TN.offsetX, TN.offsetY)
	
	TN.hideNote = TN.vars.hideNote
	self:UpdateNoteVisibility()
end

function TN:SaveNotePanel()
	local xx, yy = TiNotePanel:GetDimensions()
	self.vars.width = xx
	self.vars.height = yy
end

function TN:SaveText()
	self.vars.text = TiNoteEditBox:GetText()
end

function TN:SaveAnchor()
	
	-- Get the new position
	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = TiNote:GetAnchor()
	
	-- Save the anchors
	if ( isValidAnchor ) then
	
	TN.vars.anchor = { point, relativePoint, offsetX, offsetY }
	
	else
	
	d("TiNote - anchor not valid")
	
	end
end

function TN:UpdateMovable()
	TiNote:SetMovable(TN.movable)
end

function TN:ToggleMovable()
	TN.movable = not TN.movable
	self:UpdateMovable()
	TN.vars.movable = TN.movable
	return TN.movable
end


function TN:InitConfigPanel()
	
	local cPanelId="TiNoteConfigPanel"
	local panelId = _G[cPanelId]
	
	if not panelId then
		ZO_OptionsWindow_AddUserPanel(cPanelId, "TiNote")
		panelId = _G[cPanelId]
	end
	
	-- movable
	local checkbox = CreateControlFromVirtual("TiNoteMovableCheckbox", ZO_OptionsWindowSettingsScrollChild, "ZO_Options_Checkbox")
	checkbox:SetAnchor(TOPLEFT, checkbox.parent, TOPLEFT, 0, 20)
	checkbox.controlType = OPTIONS_CHECKBOX
	checkbox.panel = panelId
	checkbox.system = SETTING_TYPE_UI
	checkbox.settingId = _G["SETTING_TiNoteMovableCheckbox"]
	checkbox.text = "Movable"
	
	local checkboxButton = checkbox:GetNamedChild("Checkbox")
	
	
	ZO_PreHookHandler(checkbox, "OnShow", function()
			checkboxButton:SetState(TN.movable and 1 or 0)
			checkboxButton:toggleFunction(TN.movable)
		end)
		
	ZO_PreHookHandler(checkboxButton, "OnClicked", function()  
					TN:ToggleMovable()
				end)
	
	ZO_OptionsWindow_InitializeControl(checkbox)
	
end

function TN:MoveCorner(bmove)
	--d(bmove)
	TN.moveCorner = bmove
	
	if not bmove then
		TiNoteCorner:ClearAnchors()
		TiNoteCorner:SetAnchor(BOTTOMRIGHT,TiNoteBG ,BOTTOMRIGHT, TN.offsetX, TN.offsetY)
		TiNoteCorner:SetAlpha(1)
		TN.lastOffsetX = TN.offsetX
		TN.lastOffsetY = TN.offsetY
		self:SaveNotePanel()
	else
		TiNoteCorner:SetAlpha(0)
	end
end

function TN:UpdateNoteDimension()

	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = TiNoteCorner:GetAnchor()
	
	if ( isValidAnchor ) then
	
	--d(tostring(offsetX).." , "..tostring(offsetY))
	local x, y = TiNotePanel:GetDimensions()
	local xx = x
	local yy = y
	
	local xdiff = offsetX-TN.lastOffsetX
	if xdiff ~= 0 then
		xx = xx + xdiff
		if xx < 100 then -- limit min width
			xx = xx - xdiff
		else
			TN.lastOffsetX = offsetX
		end
	end
	
	local ydiff = offsetY - TN.lastOffsetY
	if ydiff ~= 0 then
		yy = yy + ydiff
		if yy < 30 then -- limit min height
			yy = yy - ydiff 
		else
			TN.lastOffsetY = offsetY
		end
	end
	
	--TiNote:SetDimensions(xx,yy+20)
	TiNotePanel:SetDimensions(xx,yy)
	TiNoteBG:SetDimensions(xx,yy)
	TiNoteEditBox:SetDimensions(xx-10,yy-10)
	--TiNoteCorner:ClearAnchors()
	--TiNoteCorner:SetAnchor(point,relativeTo ,relativePoint, 0, 2)
	
	else
	
	d("TiNote - corner anchor not valid")
	
	end

end

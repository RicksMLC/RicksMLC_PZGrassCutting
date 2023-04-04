require "ISUI/ISCollapsableWindow"

_Test_RicksMLC_UI_Window = ISCollapsableWindow:derive("_Test_RicksMLC_UI_Window")
_Test_RicksMLC_UI_Window.windows = {}

function _Test_RicksMLC_UI_Window:createChildren()
	ISCollapsableWindow.createChildren(self)
	self.panel = ISToolTip:new()
	self.panel.followMouse = false
	self.panel:initialise()
	self:setObject(self.object)
	self:addView(self.panel)
end

function _Test_RicksMLC_UI_Window:update()
	ISCollapsableWindow.update(self)
	
	self.panel.maxLineWidth = 400
	self.panel.description = _Test_RicksMLC_UI_Window.getRichText(self.object);

	--if self:getIsVisible() and (not self.object or self.object:getObjectIndex() == -1) then
	--	if self.joyfocus then
	--		self.joyfocus.focus = nil
	--		updateJoypadFocus(self.joyfocus)
	--	end
	--	self:removeFromUIManager()
	--	return
	--end

	--if self.fuel ~= self.object:getFuel() or self.condition ~= self.object:getCondition() then
		self:setObject(self.object)
	--end
	self:setWidth(self.panel:getWidth())
	self:setHeight(self:titleBarHeight() + self.panel:getHeight())
end

function _Test_RicksMLC_UI_Window:setObject(object)
	self.object = object
	self.panel:setName(self.title) --getText("IGUI_Generator_TypeGas"))
	-- FIXME: Remove
	--self.panel:setTexture(object:getTextureName())
	--self.fuel = object:getFuel()
	--self.condition = object:getCondition()
--	self.panel.description = _Test_RicksMLC_UI_Window.getRichText(object, true)
end

function _Test_RicksMLC_UI_Window.getRichText(testResults)
	local text = "Test Results: "
	for i = 1, #testResults do
		text = text .. " <LINE> <INDENT:0> " .. testResults[i] .. " "
	end
	--TODO: FAIL:	text = text .. " <LINE> <RED> " .. getText("IGUI_Generator_IsToxic")
	return text
end

function _Test_RicksMLC_UI_Window:onGainJoypadFocus(joypadData)
	self.drawJoypadFocus = true
end

function _Test_RicksMLC_UI_Window:onJoypadDown(button)
	if button == Joypad.BButton then
		self:removeFromUIManager()
		setJoypadFocus(self.playerNum, nil)
	end
end

function _Test_RicksMLC_UI_Window:close()
	self:removeFromUIManager()
end

function _Test_RicksMLC_UI_Window:new(x, y, character, object, title)
	local width = 600
	local height = 16 + 64 + 16 + 16
	local o = ISCollapsableWindow:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.playerNum = character:getPlayerNum() -- FIXME: We only need the playerNum
	o.object = object
	o.panelTitle = title
	o:setResizable(false)
	return o
end

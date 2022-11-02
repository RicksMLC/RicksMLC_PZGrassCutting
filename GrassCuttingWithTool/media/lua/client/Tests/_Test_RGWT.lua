-- Test ISRemoveGrassWithTool.lua
-- Rick's MLC

-- [ ] Test the RemoveGrassWithTool mod 
--

require "ISBaseObject"
require "ISRemoveGrassWithTool"

local MockPlayer = ISBaseObject:derive("MockPlayer");
function MockPlayer:new(player)
    local o = {} 
    setmetatable(o, self)
    self.__index = self

    o.realPlayer = player
    o.lastThought = nil

    return o
end

function MockPlayer:getPerkLevel(perkType)
    return self.realPlayer:getPerkLevel(perkLevel)
end

function MockPlayer:getXp()
    return self.realPlayer:getXp()
end

function MockPlayer:getPrimaryHandItem()
    return self.realPlayer:getPrimaryHandItem()
end

function MockPlayer:setPrimaryHandItem(item)
    self.realPlayer:setPrimaryHandItem(item)
end

function MockPlayer:getSecondaryHandItem()
    return self.realPlayer:getSecondaryHandItem()
end

function MockPlayer:setSecondaryHandItem(item)
    self.realPlayer:setSecondaryHandItem(item)
end

function MockPlayer:isTimedActionInstant()
    return false
end

function MockPlayer:getTimedActionTimeModifier()
    return self.realPlayer:getTimedActionTimeModifier()
end

function MockPlayer:Say(text, r, g, b, font, n, preset)
    self.realPlayer:Say(text, r, g, b, font, n, preset)
    self.lastThought = text
    DebugLog.log(DebugType.Mod, "MockPlayer:Say() end: " .. text)
end

function MockPlayer:getMoodles()
    return self.realPlayer:getMoodles()
end

function MockPlayer:getBodyDamage()
    return self.realPlayer:getBodyDamage()
end

----------------------------------------------------------------------

-- RGWTool_Test is RemoveGrassWithTool_Test
local RGWTool_Test = ISBaseObject:derive("RGWTool_Test")
local iTest = nil

function RGWTool_Test:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.player = nil
    o.isReady = false
    o.ISRemoveGrassInstance = nil
    o.preTestPrimaryItem = nil
    o.preTestSecondaryItem = nil

    return o
end

function RGWTool_Test:newInventoryItem(type)
	local item = nil
    if type ~= nil then 
        item = InventoryItemFactory.CreateItem(type)
    end
	return item
end

function RGWTool_Test:setPrimaryItem(type)
	local item = self:newInventoryItem(type)
	self.player:setPrimaryHandItem(item)
	return item
end

function RGWTool_Test:setSecondaryItem(type)
	local item = self:newInventoryItem(type)
	self.player:setSecondaryHandItem(item)
	return item
end

function RGWTool_Test:Init()
    DebugLog.log(DebugType.Mod, "RGWTool_Test:Init()")
    -- Create the test instance of the ISRemoveGrass

    self.player = MockPlayer:new(getPlayer())
    self.preTestPrimaryItem = self.player:getPrimaryHandItem()
    self.preTestSecondaryItem = self.player:getSecondaryHandItem()

    local square = nil

    self.ISRemoveGrassInstance = ISRemoveGrass:new(self.player, square)
    if not self.ISRemoveGrassInstance then
        DebugLog.log(DebugType.Mod, "RGWTool_Test:Init(): ERROR self.ISRemoveGrassInstance is nil")
        return
    end
    self.isReady = true
end


local function cmpNltO(orig, new) return new < orig end
local function cmpNeqO(orig, new) return orig == new end

local testAdjustMaxTimeCases = {
    {1, "base.HandScythe", nil,             cmpNltO, "new >= orig. orig: <orig> new: <new>", "Using this Hand Scythe is much faster"},
    {2, nil,               nil,             cmpNeqO, "new ~= orig. orig: <orig> new: <new>", "I wish I had a Hand Scythe"},
    {3, "base.HandScythe", "base.Saucepan", cmpNeqO, "new ~= orig. orig: <orig> new: <new>", "I can't use this Hand Scythe to cut grass unless the other hand is empty"},
    {4, "base.Saucepan",   nil,             cmpNeqO, "new ~= orig. orig: <orig> new: <new>", "This is not a Hand Scythe. It's a Saucepan"}
}
function RGWTool_Test:TestAdjustMaxTime(testId, testCase)
    self:setPrimaryItem(testCase[2])
    self:setSecondaryItem(testCase[3])
    local maxTime = 1
    local newMaxTime = self.ISRemoveGrassInstance:adjustMaxTime(maxTime) 
    if testCase[4](maxTime, newMaxTime) then
        if self.player.lastThought == testCase[6] then
            DebugLog.log(DebugType.Mod, " [ ] Test: "  .. testId .. " Passed")
        else
            DebugLog.log(DebugType.Mod, " [x] Test: "  .. testId .. " Failed - Mismatched Say text")
            DebugLog.log(DebugType.Mod, "  expected: " .. testCase[6])
            DebugLog.log(DebugType.Mod, "  actual:   " .. (self.player.lastThought or "nil"))
        end
    else
        local failMsg = string.gsub(testCase[5], "<orig>", tostring(maxTime))
        failMsg = string.gsub(failMsg, "<new>", tostring(newMaxTime))
        DebugLog.log(DebugType.Mod, " [x] Test: "  .. testId .. " Failed " .. failMsg)
    end
end

function RGWTool_Test:Run()
    DebugLog.log(DebugType.Mod, "RGWTool_Test:Run()")
    if not self.isReady then
        DebugLog.log(DebugType.Mod, "RGWTool_Test:Run() not ready")
        return
    end
    DebugLog.log(DebugType.Mod, "RGWTool_Test:Run() begin")
    for i = 1, #testAdjustMaxTimeCases do
        self:TestAdjustMaxTime(i, testAdjustMaxTimeCases[i])
    end
    DebugLog.log(DebugType.Mod, "RGWTool_Test:Run() end")
end

function RGWTool_Test:Teardown()
    DebugLog.log(DebugType.Mod, "RGWTool_Test:Teardown()")
    self.player:setPrimaryHandItem(self.preTestPrimaryItem)
    self.player:setSecondaryHandItem(self.getSecondaryHandItem)
    self.preTestPrimaryItem = nil
    self.preTestSecondaryItem = nil
    self.ISRemoveGrassInstance = nil
    self.isReady = false
end

-- Static --

function RGWTool_Test.IsTestSave()
    local saveInfo = getSaveInfo(getWorld():getWorld())
    DebugLog.log(DebugType.Mod, "RGWTool_Test.OnLoad() '" .. saveInfo.saveName .. "'")
	return saveInfo.saveName and saveInfo.saveName == "RicksMLC_RGWTool_Test"
end

function RGWTool_Test.Execute()
    iTest = RGWTool_Test:new()
    iTest:Init()
    if iTest.isReady then 
        DebugLog.log(DebugType.Mod, "RGWTool_Test.Execute() isReady")
        iTest:Run()
        DebugLog.log(DebugType.Mod, "RGWTool_Test.Execute() Run complete.")
    end
    iTest:Teardown()
    iTest = nil
end

function RGWTool_Test.OnLoad()
    -- Check the loaded save is a test save?
    DebugLog.log(DebugType.Mod, "RGWTool_Test.OnLoad()")
	if RGWTool_Test.IsTestSave() then
        DebugLog.log(DebugType.Mod, "  - Test File Loaded")
        --FIXME: This is auto run: RGWTool_Test.Execute()
    end
end

function RGWTool_Test.OnGameStart()
    DebugLog.log(DebugType.Mod, "RGWTool_Test.OnGameStart()")
end

function RGWTool_Test.HandleOnKeyPressed(key)
	-- Hard coded to F9 for now
	if key == nil then return end

	if key == Keyboard.KEY_F9 and RGWTool_Test.IsTestSave() then
        DebugLog.log(DebugLog.Mod, "RGWTool_Test.HandleOnKeyPressed() Execute test")
        RGWTool_Test.Execute()
    end
end

Events.OnKeyPressed.Add(RGWTool_Test.HandleOnKeyPressed)

Events.OnGameStart.Add(RGWTool_Test.OnGameStart)
Events.OnLoad.Add(RGWTool_Test.OnLoad)

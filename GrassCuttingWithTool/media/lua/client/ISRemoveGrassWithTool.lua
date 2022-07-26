--- Rick's MLC Grass Removal with a Tool

require "TimedActions/ISRemoveGrass"

local handScytheType = "base.HandScythe"
local function GetHandScytheName()
    local item = ScriptManager.instance:getItem(handScytheType)
    if item then
        return item:getDisplayName()
    end
    return "[Error: Cannot find " .. handScytheType .. "]"
end

-- Added the ISRemoveGrass:adjustMaxTime to perform the base operation then adjust it if we have an appropriate tool.
-- A scyte will reduce the maxTime by 50%
-- TODO:
--      [ ] Make configurable in the item definition
--      [+] A short blade will reduce the maxTime by %
--      [+] Give a little short blade xp for every use
--      [+] Make the scythe reduce time a function of the base amount and the short blade skill
--      [+] Fix languange bug: Use the type instead of the name.
--      [+] Modify the messages to use the language name for HandScythe
local baseHandScytheFactor = 0.5
local oneHandEmptyMessageCount = 3
local wishForScytheMessageCount = 2
local muchFasterMessageCount = 1
local notAHandScytheMessageCount = 2
function ISRemoveGrass:adjustMaxTime(maxTime) 
    maxTime = ISBaseTimedAction.adjustMaxTime(self, maxTime)
    -- Get the character inventory to check for a HandScythe
    local player = getPlayer()
    local primaryItem = player:getPrimaryHandItem()
    local secondaryItem = player:getSecondaryHandItem()
    -- Is HandScythe equipped in the primary hand?
    -- Nothing in the secondary hand - can't use a scythe one-handed to cut grass.
    if primaryItem then
        local primaryItemCategories = primaryItem:getCategories()
        if primaryItem:getType() == "HandScythe" then
            if secondaryItem then 
                if oneHandEmptyMessageCount > 0 then
                    HaloTextHelper.addText(player, "I can't use a " .. GetHandScytheName() .. " to cut grass unless the other hand is empty")
                    oneHandEmptyMessageCount = oneHandEmptyMessageCount - 1
                end
            else
                if muchFasterMessageCount > 0 then
                    HaloTextHelper.addText(player, "Using this " .. GetHandScytheName() .. " is much faster")
                    muchFasterMessageCount = muchFasterMessageCount - 1
                end
                -- HandScythe category: SmallBlade
                local smallBladeLvl = player:getPerkLevel(Perks.SmallBlade);
                local timeFactor = baseHandScytheFactor - (smallBladeLvl / 40) -- lvl is 0 to 10, so divide by 40 to make 0 to 0.25
                -- Have a 10% chance to give a little XP for SmallBlade
                if ZombRand(9) == 0 then
                    self.character:getXp():AddXP(Perks.SmallBlade, 1);
                end
                return maxTime * timeFactor
            end
        else 
            if notAHandScytheMessageCount > 0 then
                HaloTextHelper.addText(player, "This is not a " .. GetHandScytheName() .. ". It's a " .. primaryItem:getDisplayName())
                notAHandScytheMessageCount = notAHandScytheMessageCount - 1 
            end
        end
    else
        if wishForScytheMessageCount > 0 then
            HaloTextHelper.addText(player, "I wish I had a " .. GetHandScytheName())
            wishForScytheMessageCount = wishForScytheMessageCount - 1
        end
    end
    return maxTime
end
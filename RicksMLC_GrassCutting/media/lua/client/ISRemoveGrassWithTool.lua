--- Rick's MLC Grass Removal with a Tool

require "TimedActions/ISRemoveGrass"

-- Added the ISRemoveGrass:adjustMaxTime to perform the base operation then adjust it if we have an appropriate tool.
-- A scyte will reduce the maxTime by 50%
-- TODO:
--      Make configurable in the item definition
--      A short blade will reduce the maxTime by %
--      Give a little short blade xp for every use
--      Make the scythe reduce time a function of the base amount and the short blade skill
local baseHandScytheFactor = 0.5
local oneHandEmptyMessageCount = 2
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
        if primaryItem:getName() == "Hand Scythe" then
            if secondaryItem then 
                if oneHandEmptyMessageCount > 0 then
                    HaloTextHelper.addText(player, "I can't use a hand scythe to cut grass unless the other hand is empty")
                    oneHandEmptyMessageCount = oneHandEmptyMessageCount - 1
                end
            else
                if muchFasterMessageCount > 0 then
                    HaloTextHelper.addText(player, "This is much faster with a hand scythe")
                    muchFasterMessageCount = muchFasterMessageCount - 1
                end
                -- HandScythe category: SmallBlade
                local smallBladeLvl = character:getPerkLevel(Perks.SmallBlade);
                local timeFactor = baseHandScytheFactor - (smallBladeLvl / 40) -- lvl is 0 to 10, so divide by 40 to make 0 to 0.25

                return maxTime * timeFactor
            end
        else 
            if notAHandScytheMessageCount > 0 then
                HaloTextHelper.addText(player, "Not a hand scythe. Primary is '" .. primaryItem:getName() .. "'")
                notAHandScytheMessageCount = notAHandScytheMessageCount - 1 
            end
        end
    else
        if wishForScytheMessageCount > 0 then
            HaloTextHelper.addText(player, "I wish I had a hand scythe")
            wishForScytheMessageCount = wishForScytheMessageCount - 1
        end
    end
    return maxTime
end
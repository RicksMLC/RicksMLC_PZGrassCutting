-- Rick's MLC Grass Removal with a Tool
-- Having a hand scythe will reduce the remove grass time by 50% - 75% depending on the short blade level.
--
-- Specification:
--  [+] Auto-equip the hand scythe if it is in the inventory but not in the primary hand
--  
--  [+] self:setOverrideHandModels(nil, nil) needs override so the hand scythe stays in the hand.
--  [+] A short blade will reduce the maxTime by %
--  [+] Give a little short blade xp for every use
--  [+] Make the scythe reduce time a function of the base amount and the short blade skill
--  [+] Fix languange bug: Use the type instead of the name.
require "TimedActions/ISRemoveGrass"
require "ISBaseObject"

RicksMLC_RemoveGrass = ISBaseObject:derive("RicksMLC_RemoveGrass")

local baseHandScytheFactor = 0.4

function RicksMLC_RemoveGrass.ChanceXPGain(player)
    -- Have a 10% chance to give a little XP for SmallBlade
    if ZombRand(0, 9) <= 1 then
        player:getXp():AddXP(Perks.SmallBlade, 1);
    end
end

local handScytheType = "HandScythe"
local handScytheFullType = "base.HandScythe"
local function GetHandScytheName()
    local item = ScriptManager.instance:getItem(handScytheFullType)
    if item then
        return item:getDisplayName()
    end
    return "[Error: Cannot find " .. handScytheFullType .. "]"
end

function RicksMLC_RemoveGrass.RequiresInvMove(primaryItem, secondaryItem, typeName, itemInInv)
    local primaryIsItem = primaryItem and primaryItem:getType() == typeName
    return (not primaryIsItem or secondaryItem) and itemInInv
end

-- Override.  Note ISRemoveGrass does not have an adjustMaxTime() so just call the base class adjustMaxTime()
function ISRemoveGrass:adjustMaxTime(maxTime) 
    local primaryItem = self.character:getPrimaryHandItem()
    local secondaryItem = self.character:getSecondaryHandItem()
    local handScytheItem = self.character:getInventory():getFirstTypeRecurse(handScytheType)
    if RicksMLC_RemoveGrass.RequiresInvMove(primaryItem, secondaryItem, handScytheType, handScytheItem) then
        -- A hand scythe exists and needs to move to the primary hand, which is handled in the perform() method.
        -- Return 0 time so this current ISRemoveGrass timed action is aborted immediately.
        return 0
    end

    local maxTime = ISBaseTimedAction.adjustMaxTime(self, maxTime)

    if (primaryItem and primaryItem:getType() == handScytheType) and not secondaryItem then
        -- HandScythe category: SmallBlade
        local smallBladeLvl = self.character:getPerkLevel(Perks.SmallBlade);
        local timeFactor = baseHandScytheFactor - (smallBladeLvl / 40) -- lvl is 0 to 10, so divide by 40 to make 0 to 0.25
        maxTime = maxTime * timeFactor
    end
    return maxTime
end

-- Override start() to set the hand models
local baseISRemoveGrassStart = ISRemoveGrass.start
function ISRemoveGrass:start()

    local primaryItem = self.character:getPrimaryHandItem()
    local secondaryItem = self.character:getSecondaryHandItem()
    local handScytheItem = self.character:getInventory():getFirstTypeRecurse(handScytheType)
    if RicksMLC_RemoveGrass.RequiresInvMove(primaryItem, secondaryItem, handScytheType, handScytheItem) then
        self.maxTime = 0
        return -- because the perform will initiate the inventory transfer and create a new ISRemoveGrass to replace this one.
    end

    if primaryItem and primaryItem:getType() == handScytheType and not secondaryItem then
        baseISRemoveGrassStart(self)
        self:setOverrideHandModels(primaryItem, nil)
        return
    end

    -- No scythe so just proceed as normal
    baseISRemoveGrassStart(self)
end

function RicksMLC_RemoveGrass.CalcEquipTime(item, character)
    local hotbar = getPlayerHotbar(character:getPlayerNum())
    if hotbar:isItemAttached(item) then
        return 5
    end
    return 25 -- default time
end

-- Override perform() to check for and use the hand scythe if it is in inventory.
local baseISRemoveGrassPerform = ISRemoveGrass.perform
function ISRemoveGrass:perform()
    local primaryItem = self.character:getPrimaryHandItem()
    local secondaryItem = self.character:getSecondaryHandItem()
    local handScytheItem = self.character:getInventory():getFirstTypeRecurse(handScytheType)

    -- Proceed with the base RemoveGrass if the primary is a hand scythe and secondary is empty, or there is no handScythe
    if not RicksMLC_RemoveGrass.RequiresInvMove(primaryItem, secondaryItem, handScytheType, handScytheItem) then
        RicksMLC_RemoveGrass.ChanceXPGain(self.character)
        baseISRemoveGrassPerform(self)
        return
    end

    -- If the hand scythe is in the inventory, push an equip item action and abort this one... similar to the ISFixGeneratory
    local finalAction = self
    if (secondaryItem) then
        -- Force Unequip
        local unEquipAction = ISUnequipAction:new(self.character, secondaryItem, RicksMLC_RemoveGrass.CalcEquipTime(secondaryItem, self.character))
        ISTimedActionQueue.addAfter(finalAction, unEquipAction)
        finalAction = unEquipAction
    end

    if not (primaryItem and primaryItem:getType() == handScytheType) then
        if handScytheItem then
            if handScytheItem:getContainer() ~= self.character:getInventory() then
                -- We have one, but not in-hand, so add an inventory transfer
                local action = ISInventoryTransferAction:new(self.character, handScytheItem, handScytheItem:getContainer(), self.character:getInventory(), nil)
                ISTimedActionQueue.addAfter(self, action)
                finalAction = action
            end
            -- Equip the hand scythe.
            local equipAction = ISEquipWeaponAction:new(self.character, handScytheItem, RicksMLC_RemoveGrass.CalcEquipTime(handScytheItem, self.character), true, false)   
            ISTimedActionQueue.addAfter(finalAction, equipAction)
            finalAction = equipAction
        end
    end
    -- Changing the hand settings means recalculating the adjustMaxTime, so spawn a new ISRemoveGrass.
    ISTimedActionQueue.addAfter(finalAction, ISRemoveGrass:new(self.character, self.square));

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end


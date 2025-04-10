local addonName, addonTable = ...
local majorVersion = select(4, GetBuildInfo())

local LOOT_DELAY = 0.3 -- delay between looting actions
local epoch = 0
local currentLootIndex = nil

-- Check if the player's bags are full
if majorVersion >= 10 then
    IsBagFull = function()
        local freeSlots = C_Container.GetContainerFreeSlots()
        return #freeSlots == 0
    end
else
    IsBagFull = function()
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                if not GetContainerItemID(bag, slot) then
                    return false
                end
            end
        end
        return true
    end
end

-- Loot items one by one with a delay
local function LootNextItem()
    if not currentLootIndex then return end
    if currentLootIndex < 1 then
        currentLootIndex = nil
        return
    end

    -- Skip locked loot (e.g., need/greed or master loot)
    local _, _, locked = GetLootSlotInfo(currentLootIndex)
    if not locked then
        LootSlot(currentLootIndex)
    end

    currentLootIndex = currentLootIndex - 1

    if currentLootIndex >= 1 then
        C_Timer.After(LOOT_DELAY, LootNextItem)
    end
end

-- Event handler
local EventFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            if not GetCVarBool("autoLootDefault") then
                SetCVar("autoLootDefault", "1")
                print("Auto loot has been enabled.")
            end
            self:UnregisterEvent('ADDON_LOADED')
            print(addonName .. " loaded.")
        end
    elseif event == "LOOT_OPENED" then
        if IsBagFull() then
            LootFrame:Hide()
            print("🎒 Inventory is full! Looting skipped.")
            return
        end

        if GetCVarBool("autoLootDefault") and (GetTime() - epoch) >= LOOT_DELAY then
            local totalItems = GetNumLootItems()
            currentLootIndex = totalItems
            LootNextItem()
            epoch = GetTime()
        end
    end
end

-- Register events
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("LOOT_OPENED")
EventFrame:SetScript("OnEvent", OnEvent)

local addonName, addonTable = ...
local majorVersion = select(4, GetBuildInfo())

local LOOT_DELAY = 0.3
local epoch = 0
local currentLootIndex = nil
local allLooted = true

if majorVersion >= 10 then
    IsBagFull = function()
        for bag = 0, 4 do
            local freeSlots = C_Container.GetContainerFreeSlots(bag)
            if freeSlots and #freeSlots > 0 then
                return false
            end
        end
        return true
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

local lootEnded = false

local function LootNextItem()
    if not currentLootIndex then return end
    if currentLootIndex < 1 then
        if not lootEnded then
            lootEnded = true
            currentLootIndex = nil
            if allLooted then
                LootFrame:Hide()
            else
                print("⚠️ Some items could not be looted. Loot window will remain open.")
            end
        end
        return
    end

    local _, _, locked = GetLootSlotInfo(currentLootIndex)
    if not locked then
        local before = GetNumLootItems()
        LootSlot(currentLootIndex)

        C_Timer.After(0.05, function()
            local after = GetNumLootItems()
            if after >= before then
                allLooted = false
            end
            currentLootIndex = currentLootIndex - 1
            C_Timer.After(LOOT_DELAY, LootNextItem)
        end)
    else
        allLooted = false
        currentLootIndex = currentLootIndex - 1
        C_Timer.After(LOOT_DELAY, LootNextItem)
    end
end

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
        allLooted = true
        lootEnded = false

        if IsBagFull() then
            print("🎒 Inventory is full! Looting skipped.")
            return
        end

        if GetCVarBool("autoLootDefault") and (GetTime() - epoch) >= LOOT_DELAY then
            currentLootIndex = GetNumLootItems()
            C_Timer.After(0.05, LootNextItem)
            epoch = GetTime()
        end
    end
end

EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("LOOT_OPENED")
EventFrame:SetScript("OnEvent", OnEvent)

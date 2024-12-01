local addonName, addonTable = ...

local majorVersion = select(4, GetBuildInfo())

local LOOT_DELAY = 0.3
local epoch = 0

-- Визначення функцій залежно від версії WoW
local IsBagFull

if majorVersion >= 10 then
    -- Сучасний WoW (10.0+)
    IsBagFull = function()
        for bag = 0, 4 do
            local numSlots = C_Container.GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                if not itemInfo then
                    return false
                end
            end
        end
        return true
    end
else
    -- Старі версії WoW (до 10.0)
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

-- Створюємо фрейм для обробки подій
local EventFrame = CreateFrame('Frame')

local function OnEvent(self, event, ...)
    if event == 'ADDON_LOADED' then
        local name = ...
        if name == addonName then
            if not GetCVarBool("autoLootDefault") then
                SetCVar("autoLootDefault", "1")
                print("Auto loot has been enabled.")
            end
            self:UnregisterEvent('ADDON_LOADED')
        end
    elseif event == 'LOOT_OPENED' or event == 'LOOT_READY' then
        if GetCVarBool("autoLootDefault") and (GetTime() - epoch) >= LOOT_DELAY then
            for i = GetNumLootItems(), 1, -1 do
                if LootSlotHasItem(i) then
                    LootSlot(i)
                end
            end
            epoch = GetTime()

            if event == 'LOOT_OPENED' and not IsBagFull() then
                LootFrame:Hide()  -- Переконатися, що LootFrame існує
            end
        end
    end
end

-- Реєструємо події
EventFrame:RegisterEvent('ADDON_LOADED')
EventFrame:RegisterEvent('LOOT_OPENED')
EventFrame:RegisterEvent('LOOT_READY')
EventFrame:SetScript('OnEvent', OnEvent)
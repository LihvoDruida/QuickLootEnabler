local addonName, addonTable = ...

local epoch = 0
local LOOT_DELAY = 0.3

-- Функція перевірки, чи повний інвентар
local function IsBagFull()
    for bag = 0, 4 do  -- Перевіряємо всі сумки гравця (0-4)
        for slot = 1, GetContainerNumSlots(bag) do
            if not GetContainerItemID(bag, slot) then
                return false  -- Знайшли вільний слот
            end
        end
    end
    return true  -- Інвентар повний
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
                if LootSlotHasItem(i) then  -- Перевірка наявності предмета
                    LootSlot(i)
                end
            end
            epoch = GetTime()

            -- Якщо подія LOOT_OPENED і інвентар не повний, приховуємо фрейм луту
            if event == 'LOOT_OPENED' and not IsBagFull() then
                LootFrame:Hide()
            end
        end
    end
end

-- Реєструємо події
EventFrame:RegisterEvent('ADDON_LOADED')
EventFrame:RegisterEvent('LOOT_OPENED')
EventFrame:RegisterEvent('LOOT_READY')
EventFrame:SetScript('OnEvent', OnEvent)


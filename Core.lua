local addonName, addonTable = ...

local epoch = 0
local LOOT_DELAY = 0.3

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
                if LootSlotHasItem(i) then  -- Перевірка наявності предмета в слоті
                    LootSlot(i)
                end
            end
            epoch = GetTime()

            if event == 'LOOT_OPENED' then
                LootFrame:Hide()  -- Приховуємо фрейм луту
            end
        end
    end
end

-- Реєструємо події
EventFrame:RegisterEvent('ADDON_LOADED')
EventFrame:RegisterEvent('LOOT_OPENED')
EventFrame:RegisterEvent('LOOT_READY')
EventFrame:SetScript('OnEvent', OnEvent)

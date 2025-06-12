local addonName, addonTable = ...
local majorVersion = select(4, GetBuildInfo())

local LOOT_DELAY = 0.3
local epoch = 0
local currentLootIndex = nil
local allLooted = true
local lootEnded = false

-- Оптимізована перевірка на заповнення сумок
local IsBagFull = (majorVersion >= 10) and function()
    for bag = 0, 4 do
        local slots = C_Container.GetContainerFreeSlots(bag)
        if slots and #slots > 0 then return false end
    end
    return true
end or function()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            if not GetContainerItemID(bag, slot) then return false end
        end
    end
    return true
end

-- Логіка луту
local function LootNextItem()
    while currentLootIndex and currentLootIndex >= 1 do
        local _, _, locked = GetLootSlotInfo(currentLootIndex)
        if not locked then
            local preCount = GetNumLootItems()
            LootSlot(currentLootIndex)

            -- Чекаємо завершення
            C_Timer.After(0.05, function()
                local postCount = GetNumLootItems()
                if postCount >= preCount then
                    allLooted = false
                end

                currentLootIndex = currentLootIndex - 1
                if currentLootIndex >= 1 then
                    C_Timer.After(LOOT_DELAY, LootNextItem)
                elseif not lootEnded then
                    lootEnded = true
                    if allLooted then
                        -- Успішний лут
                        StaticPopup_Hide("LOOT_BIND")
                        LootFrame:Hide()
                        CloseLoot()
                    else
                        -- Покажи LootFrame вручну
                        ShowUIPanel(LootFrame)
                    end
                end
            end)
            return
        else
            allLooted = false
        end
        currentLootIndex = currentLootIndex - 1
    end

    -- Якщо цикл завершено
    if not lootEnded then
        lootEnded = true
        if allLooted then
            StaticPopup_Hide("LOOT_BIND")
            LootFrame:Hide()
            CloseLoot()
        else
            ShowUIPanel(LootFrame)
            print("⚠️ Some items could not be looted. Loot window will remain open.")
        end
    end
end

-- Події
local EventFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            if not GetCVarBool("autoLootDefault") then
                SetCVar("autoLootDefault", "1")
                print("Auto loot has been enabled.")
            end
            self:UnregisterEvent("ADDON_LOADED")
            print(addonName .. " loaded.")
        end

    elseif event == "LOOT_OPENED" then
        -- Сховай LootFrame одразу
        LootFrame:Hide()
        StaticPopup_Hide("LOOT_BIND")

        if IsBagFull() then
            print("🎒 Inventory is full! Looting skipped.")
            CloseLoot()
            return
        end

        if GetCVarBool("autoLootDefault") and (GetTime() - epoch) >= LOOT_DELAY then
            allLooted = true
            lootEnded = false
            currentLootIndex = GetNumLootItems()
            C_Timer.After(0.05, LootNextItem)
            epoch = GetTime()
        end
    end
end

EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("LOOT_OPENED")
EventFrame:SetScript("OnEvent", OnEvent)

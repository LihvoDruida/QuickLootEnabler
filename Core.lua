local addonName, addonTable = ...

local epoch = 0
local LOOT_DELAY = 0.3

-- Create a frame for handling events
local EventFrame = CreateFrame('Frame')

-- Function to handle events
local function OnEvent(self, event, ...)
    if event == 'ADDON_LOADED' then
        local name = ...
        if name == addonName then
            -- Check AutoLoot and turn it On if necessary
            if not GetCVarBool("autoLootDefault") then
                SetCVar("autoLootDefault", "1")
                print("Auto loot has been enabled.")
            end
            -- Unregister the ADDON_LOADED event and cleanup
            self:UnregisterEvent('ADDON_LOADED')
        end
    elseif event == 'LOOT_OPENED' or event == 'LOOT_READY' then
        -- Handle LOOT_OPENED and LOOT_READY events
        if GetCVarBool("autoLootDefault") then
            if (GetTime() - epoch) >= LOOT_DELAY then
                for i = GetNumLootItems(), 1, -1 do
                    LootSlot(i)
                end
                epoch = GetTime()
            end

            -- For LOOT_OPENED, perform additional actions
            if event == 'LOOT_OPENED' then
                -- Ensure LootFrame script is removed and events are unregistered
                LootFrame:SetScript("OnEvent", nil)
                LootFrame:UnregisterAllEvents()
                LootFrame:Hide()
            end
        end
    end
end

-- Register events and set script
EventFrame:RegisterEvent('ADDON_LOADED')
EventFrame:RegisterEvent('LOOT_OPENED')
EventFrame:RegisterEvent('LOOT_READY')
EventFrame:SetScript('OnEvent', OnEvent)

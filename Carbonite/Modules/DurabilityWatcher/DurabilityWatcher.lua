-- Carbonite | Modules / DurabilityWatcher
-- Watches the player's gear durability and fires events when it
-- crosses thresholds. Not present as a discrete subsystem in
-- legacy Carbonite, but pieces of the data live in the saved-
-- variable Visited-Vendor table; this class is the public surface
-- for new code (especially Warehouse + Guide) to consume.
--
-- Public API:
--   DurabilityWatcher:GetMinimumPercent()  -> int 0..100
--   DurabilityWatcher:OnThreshold(threshold, fn)
--   DurabilityWatcher:GetAveragePercent()
--   DurabilityWatcher:GetSlotPercent(invSlot)

local Carbonite = _G.Carbonite
local DurabilityWatcher = {}
Carbonite.Modules.DurabilityWatcher = DurabilityWatcher

local INV_SLOTS = {
    "HeadSlot", "ShoulderSlot", "ChestSlot", "WaistSlot", "LegsSlot",
    "FeetSlot", "WristSlot", "HandsSlot", "MainHandSlot", "SecondaryHandSlot",
    "RangedSlot",
}

local function slotID(name)
    if not _G.GetInventorySlotInfo then return nil end
    local id = _G.GetInventorySlotInfo(name)
    return id
end

function DurabilityWatcher:GetSlotPercent(invSlotName)
    if not _G.GetInventoryItemDurability then return nil end
    local id = slotID(invSlotName)
    if not id then return nil end
    local cur, max = _G.GetInventoryItemDurability(id)
    if not cur or not max or max == 0 then return nil end
    return math.floor(cur * 100 / max)
end

function DurabilityWatcher:GetAveragePercent()
    local total, count = 0, 0
    for _, name in ipairs(INV_SLOTS) do
        local pct = self:GetSlotPercent(name)
        if pct then total = total + pct; count = count + 1 end
    end
    if count == 0 then return 100 end
    return math.floor(total / count)
end

function DurabilityWatcher:GetMinimumPercent()
    local minPct = 100
    for _, name in ipairs(INV_SLOTS) do
        local pct = self:GetSlotPercent(name)
        if pct and pct < minPct then minPct = pct end
    end
    return minPct
end

local thresholdSubs = {}        -- threshold -> { fns... }
local lastCheck = 100

function DurabilityWatcher:OnThreshold(threshold, fn)
    if type(threshold) ~= "number" or type(fn) ~= "function" then return end
    thresholdSubs[threshold] = thresholdSubs[threshold] or {}
    table.insert(thresholdSubs[threshold], fn)
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local f = CreateFrame("Frame", "CarbDurabilityWatcher")
    f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    f:RegisterEvent("PLAYER_DEAD")
    f:SetScript("OnEvent", function()
        local now = DurabilityWatcher:GetMinimumPercent()
        for threshold, subs in pairs(thresholdSubs) do
            if lastCheck >= threshold and now < threshold then
                for _, fn in ipairs(subs) do pcall(fn, now) end
            end
        end
        lastCheck = now
        Carbonite.Core.EventBus:Fire("DURABILITY_UPDATED", now)
    end)
end)

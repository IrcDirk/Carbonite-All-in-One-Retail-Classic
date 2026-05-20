-- Carbonite | Modules / CurrencyTracker
-- Money + currency accessors. The Warehouse plugin tracks
-- per-character money; this class is the centralized accessor so
-- other modules (Quests for repair-cost estimates, Gather for
-- profit-per-hour) can read the live value without each calling
-- the API.
--
-- Public API:
--   CurrencyTracker:GetMoney()                -> int (copper)
--   CurrencyTracker:GetMoneyString()
--   CurrencyTracker:GetCurrencyCount(id)
--   CurrencyTracker:OnMoneyChanged(fn)        - fn(newCopper, delta)

local Carbonite = _G.Carbonite
local CurrencyTracker = {}
Carbonite.Modules.CurrencyTracker = CurrencyTracker

local lastMoney

function CurrencyTracker:GetMoney()
    if _G.GetMoney then return _G.GetMoney() or 0 end
    return 0
end

function CurrencyTracker:GetMoneyString()
    if Carbonite.Util.LegacyStrings then
        return Carbonite.Util.LegacyStrings.MoneyString(self:GetMoney())
    end
    local copper = self:GetMoney()
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return ("%dg %ds %dc"):format(g, s, c)
end

function CurrencyTracker:GetCurrencyCount(currencyID)
    if not currencyID then return 0 end
    if _G.C_CurrencyInfo and _G.C_CurrencyInfo.GetCurrencyInfo then
        local info = _G.C_CurrencyInfo.GetCurrencyInfo(currencyID)
        return info and info.quantity or 0
    end
    if _G.GetCurrencyInfo then
        local _, amount = _G.GetCurrencyInfo(currencyID)
        return amount or 0
    end
    return 0
end

function CurrencyTracker:OnMoneyChanged(fn)
    if type(fn) == "function" then
        Carbonite.Core.EventBus:Subscribe("MONEY_CHANGED", fn)
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    lastMoney = CurrencyTracker:GetMoney()
    local f = CreateFrame("Frame", "CarbCurrencyTracker")
    f:RegisterEvent("PLAYER_MONEY")
    f:SetScript("OnEvent", function()
        local now = CurrencyTracker:GetMoney()
        local delta = now - (lastMoney or now)
        lastMoney = now
        Carbonite.Core.EventBus:Fire("MONEY_CHANGED", now, delta)
    end)
end)

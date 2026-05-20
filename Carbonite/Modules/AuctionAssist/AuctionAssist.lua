-- Carbonite | Modules / AuctionAssist
-- Auction house browse-assistant. Hooks AuctionFrameBrowse_Update to
-- display per-item buyout cost. The legacy code lived as a plain
-- table Nx.AuctionAssist with embedded AceEvent-3.0 callbacks; this
-- module gives it a proper Module subclass with a clean enable flag
-- (`Nx.AuctionShowBOPer`) wrapped as a property.
--
-- Public API:
--   AuctionAssist:Enable(on)    - toggle the per-item buyout column
--   AuctionAssist:IsEnabled()
--   AuctionAssist:GetLowest()   - returns the cheapest current auction
--                                 (best name + price-per-item) for the
--                                 last browse page, or nil

local Carbonite = _G.Carbonite
local Module = Carbonite.Core.Module

local AuctionAssist = Module:New("AuctionAssist", {
    defaults = {
        char = {
            AuctionAssist = {
                ShowBuyoutPerItem = false,
            },
        },
    },
})

-- Cached lowest-price snapshot from the last AuctionFrameBrowse update.
local lastLow = {
    price = nil,
    name  = nil,
    perItem = nil,
}

function AuctionAssist:IsEnabled()
    local db = self:DB() and self:DB().char or {}
    return db.ShowBuyoutPerItem == true or _G.Nx and _G.Nx.AuctionShowBOPer
end

function AuctionAssist:Enable(on)
    local db = self:DB() and self:DB().char
    if db then db.ShowBuyoutPerItem = on and true or false end
    -- Mirror to the legacy global so the AuctionFrameBrowse_Update
    -- hook on Nx.AuctionAssist still sees the new state.
    if _G.Nx then _G.Nx.AuctionShowBOPer = on end
    if _G.AuctionFrame and _G.AuctionFrame:IsShown() and _G.AuctionFrameBrowse_Update then
        _G.AuctionFrameBrowse_Update()
    end
    Carbonite.Core.EventBus:Fire("AUCTION_ASSIST_TOGGLED", on == true)
end

function AuctionAssist:GetLowest()
    return lastLow.price and {
        price = lastLow.price,
        name = lastLow.name,
        perItem = lastLow.perItem,
    } or nil
end

-- Wire the legacy storage to the new module. AuctionAssist's own
-- AceEvent registrations (in Carbonite.lua) hook
-- AUCTION_HOUSE_SHOW/CLOSED + the item-list update event; we leave
-- those alone and only expose accessors here.
function AuctionAssist:OnEnable()
    Carbonite.Core.SlashCommands:Register("ah", function(rest)
        rest = (rest or ""):lower()
        if rest == "on" then self:Enable(true)
        elseif rest == "off" then self:Enable(false)
        else self:Enable(not self:IsEnabled()) end
        self.log:info("auction buyout-per-item: %s", self:IsEnabled() and "on" or "off")
    end, "toggle the per-item buyout column at the auction house")

    -- Record the lowest-price entry each time the browse list updates
    -- so other code can ask GetLowest() without re-scanning. The hook
    -- itself stays on Nx.AuctionAssist because Blizzard_AuctionUI is
    -- the trigger.
    local Nx = _G.Nx
    if Nx and Nx.AuctionAssist then
        Nx.AuctionAssist.OnLowestRecorded = function(price, name, perItem)
            lastLow.price   = price
            lastLow.name    = name
            lastLow.perItem = perItem
            Carbonite.Core.EventBus:Fire("AUCTION_LOW_RECORDED", lastLow)
        end
    end
end

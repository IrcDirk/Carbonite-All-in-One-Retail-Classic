-- Carbonite | Modules / ItemRegistry
-- Asynchronous item-info cache. WoW's C_Item.GetItemInfo can return
-- nil the first time an item is queried (the client hasn't yet
-- fetched the data from the server). The legacy `Nx.Item` table
-- batched retries through a tooltip-scan timer; this module gives
-- that the same behavior behind a callback-style API.
--
-- Public API:
--   ItemRegistry:Get(id)              -> name or nil
--   ItemRegistry:Request(id, fn)      -> fn(name, link) when ready
--   ItemRegistry:Cached(id)           -> name or nil, no fetch
--   ItemRegistry:Each(fn)             -> iterate cached entries
--   ItemRegistry:Forget(id)
--   ItemRegistry:ShowTooltip(idOrLink, owner)
--
-- We never use GameTooltip directly - tooltip queries go through
-- Carbonite.UI.Tooltip, which owns the dedicated Nx.TooltipText
-- frame and avoids tainting Blizzard's own tooltip.

local Carbonite = _G.Carbonite

local ItemRegistry = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.ItemRegistry = ItemRegistry

local cache = {}                       -- itemID -> name
local pending = {}                     -- itemID -> { fn1, fn2, ... }

local function callbackFor(id, name, link)
    local list = pending[id]
    if not list then return end
    pending[id] = nil
    for _, fn in ipairs(list) do
        local ok, err = pcall(fn, name, link, id)
        if not ok and Carbonite.Core.Logger then
            Carbonite.Core.Logger:Get("ItemRegistry"):error("callback failed for %s: %s", tostring(id), err)
        end
    end
end

local function lookup(id)
    local fn = (_G.C_Item and _G.C_Item.GetItemInfo) or _G.GetItemInfo
    if not fn then return nil end
    return fn(id)
end

function ItemRegistry:Cached(id)
    return cache[id]
end

function ItemRegistry:Get(id)
    if not id then return nil end
    if cache[id] then return cache[id] end
    local name, link = lookup(id)
    if name then
        cache[id] = name
        return name, link
    end
end

function ItemRegistry:Request(id, fn)
    if not id then return end
    local name, link = self:Get(id)
    if name then
        if fn then pcall(fn, name, link, id) end
        return
    end
    if fn then
        pending[id] = pending[id] or {}
        table.insert(pending[id], fn)
    end
end

function ItemRegistry:Forget(id)
    cache[id] = nil
    pending[id] = nil
end

function ItemRegistry:Each(fn)
    for id, name in pairs(cache) do fn(id, name) end
end

-- Tooltip helper. Routes through Carbonite.UI.Tooltip so we never
-- touch GameTooltip directly.
function ItemRegistry:ShowTooltip(idOrLink, owner)
    if not idOrLink then return end
    local s = tostring(idOrLink)
    if not s:find("item:") then
        if not s:find("quest:") then
            s = "item:" .. s .. ":0:0:0:0:0:0:0"
        end
    end
    local tt = Carbonite.UI.Tooltip and Carbonite.UI.Tooltip:Get()
    if not tt then return end
    tt:ClearLines()
    tt:SetOwner(owner or UIParent, "ANCHOR_RIGHT")
    if tt.SetHyperlink then tt:SetHyperlink(s) end
    tt:Show()
end

-- Item-data poll: fires GET_ITEM_INFO_RECEIVED when items come back
-- from the server. We listen on a private frame so we don't fight
-- the legacy Nx.Item retry timer.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local listener = CreateFrame("Frame", "CarbItemRegistryListener")
    listener:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    listener:SetScript("OnEvent", function(_, _, id, success)
        if not success then return end
        local name, link = lookup(id)
        if name then
            cache[id] = name
            callbackFor(id, name, link)
        end
    end)
end)

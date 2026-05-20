-- Carbonite | Compat / ApiShims
-- Polyfills for WoW API functions that were moved into the C_*
-- namespaces. Old code uses the bare global names; modern clients
-- only expose the namespaced versions. Aliases here mean module
-- code can call the bare name and have it work everywhere.
--
-- Only add a shim if there is a meaningful API drift. Aliasing
-- something purely for style cost is unnecessary.

local function ensure(globalName, candidates)
    if _G[globalName] then return end
    for _, candidate in ipairs(candidates) do
        local fn = candidate
        if type(candidate) == "string" then
            local ns, sub = candidate:match("^([^%.]+)%.(.+)$")
            if ns and _G[ns] and _G[ns][sub] then
                fn = _G[ns][sub]
            else
                fn = _G[candidate]
            end
        end
        if type(fn) == "function" then
            _G[globalName] = fn
            return
        end
    end
end

-- Addon load state. WoW migrated these into C_AddOns on retail.
ensure("IsAddOnLoaded",    { "C_AddOns.IsAddOnLoaded" })
ensure("LoadAddOn",        { "C_AddOns.LoadAddOn" })
ensure("EnableAddOn",      { "C_AddOns.EnableAddOn" })
ensure("DisableAddOn",     { "C_AddOns.DisableAddOn" })
ensure("GetAddOnInfo",     { "C_AddOns.GetAddOnInfo" })
ensure("GetAddOnMetadata", { "C_AddOns.GetAddOnMetadata" })

-- Item info. The legacy bare globals still work on most clients,
-- but on retail some have been replaced with C_Item variants.
ensure("GetItemInfo",         { "C_Item.GetItemInfo" })
ensure("GetItemQualityColor", { "C_Item.GetItemQualityColor" })
ensure("GetItemIcon",         { "C_Item.GetItemIconByID" })

-- Mouse focus. GetMouseFocus was removed in 11.0 in favor of GetMouseFoci
-- (returns an array). Old Carbonite code called GetMouseFocus directly.
if not _G.GetMouseFocus and _G.GetMouseFoci then
    _G.GetMouseFocus = function()
        local foci = GetMouseFoci()
        return foci and foci[1] or nil
    end
end

-- Container API. Many container functions moved to C_Container.
local C_Container = _G.C_Container
if C_Container then
    ensure("GetContainerNumSlots",  { "C_Container.GetContainerNumSlots" })
    ensure("GetContainerItemID",    { "C_Container.GetContainerItemID" })
    ensure("GetContainerItemInfo",  { "C_Container.GetContainerItemInfo" })
    ensure("GetContainerItemLink",  { "C_Container.GetContainerItemLink" })
    ensure("PickupContainerItem",   { "C_Container.PickupContainerItem" })
    ensure("UseContainerItem",      { "C_Container.UseContainerItem" })
end

-- Map info. The C_Map namespace is present on every modern client
-- but the rate of churn means we wrap the common reads.
local Carbonite = _G.Carbonite
local MapApi = {}
Carbonite.Compat.MapApi = MapApi

local C_Map = _G.C_Map

function MapApi:GetPlayerMapID()
    if C_Map and C_Map.GetBestMapForUnit then
        return C_Map.GetBestMapForUnit("player")
    end
    return nil
end

function MapApi:GetMapInfo(mapID)
    if not mapID then return nil end
    if C_Map and C_Map.GetMapInfo then return C_Map.GetMapInfo(mapID) end
    return nil
end

function MapApi:GetPlayerPosition(mapID)
    if not C_Map or not C_Map.GetPlayerMapPosition then return nil, nil end
    local mid = mapID or self:GetPlayerMapID()
    if not mid then return nil, nil end
    local pos = C_Map.GetPlayerMapPosition(mid, "player")
    if not pos then return nil, nil end
    return pos:GetXY()
end

function MapApi:GetMapWorldSize(mapID)
    if not C_Map or not C_Map.GetMapWorldSize then return nil, nil end
    return C_Map.GetMapWorldSize(mapID)
end

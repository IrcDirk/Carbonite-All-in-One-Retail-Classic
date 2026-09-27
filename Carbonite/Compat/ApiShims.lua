-- Carbonite | Compat / ApiShims
-- Transitional global aliases for legacy Carbonite call sites.
--
-- New or refactored code should use Carbonite.Compat.Api directly. These
-- globals remain only until legacy files are migrated, and they are installed
-- without overwriting a Blizzard-provided implementation.

local Carbonite = _G.Carbonite
local Api = Carbonite.Compat and Carbonite.Compat.Api

local function ensure(globalName, fn)
    if _G[globalName] ~= nil or type(fn) ~= "function" then
        return
    end
    _G[globalName] = fn
end

if Api then
    local AddOn = Api.AddOn
    local Item = Api.Item
    local Container = Api.Container

    if AddOn then
        ensure("IsAddOnLoaded", function(name)
            return AddOn:IsLoaded(name)
        end)
        ensure("LoadAddOn", function(name)
            return AddOn:Load(name)
        end)
        ensure("EnableAddOn", function(name, character)
            return AddOn:Enable(name, character)
        end)
        ensure("DisableAddOn", function(name, character)
            return AddOn:Disable(name, character)
        end)
        ensure("GetAddOnInfo", function(nameOrIndex)
            return AddOn:GetInfo(nameOrIndex)
        end)
        ensure("GetAddOnMetadata", function(name, field)
            return AddOn:GetMetadata(name, field)
        end)
    end

    if Item then
        ensure("GetItemInfo", function(item)
            return Item:GetInfo(item)
        end)
        ensure("GetItemQualityColor", function(quality)
            return Item:GetQualityColor(quality)
        end)
        ensure("GetItemIcon", function(item)
            return Item:GetIcon(item)
        end)
    end

    if Container then
        ensure("GetContainerNumSlots", function(bag)
            return Container:GetNumSlots(bag)
        end)
        ensure("GetContainerItemID", function(bag, slot)
            return Container:GetItemID(bag, slot)
        end)
        ensure("GetContainerItemInfo", function(bag, slot)
            -- The removed global used the legacy multi-return signature.
            -- Preserve that shape even though C_Container returns a table.
            return Container:GetLegacyItemInfo(bag, slot)
        end)
        ensure("GetContainerItemLink", function(bag, slot)
            return Container:GetItemLink(bag, slot)
        end)
        ensure("PickupContainerItem", function(bag, slot)
            return Container:PickupItem(bag, slot)
        end)
        ensure("UseContainerItem", function(bag, slot)
            return Container:UseItem(bag, slot)
        end)
    end
end

-- Mouse focus. GetMouseFocus was removed in favor of GetMouseFoci.
if not _G.GetMouseFocus and _G.GetMouseFoci then
    _G.GetMouseFocus = function()
        local foci = _G.GetMouseFoci()
        return foci and foci[1] or nil
    end
end

-- Map info remains on the historical MapApi name for existing map modules.
-- This will migrate independently because map coordinate behavior requires its
-- own regression pass.
local MapApi = Carbonite.Compat.MapApi or {}
Carbonite.Compat.MapApi = MapApi

local C_Map = _G.C_Map

function MapApi:GetPlayerMapID()
    if C_Map and C_Map.GetBestMapForUnit then
        return C_Map.GetBestMapForUnit("player")
    end
end

function MapApi:GetMapInfo(mapID)
    if mapID and C_Map and C_Map.GetMapInfo then
        return C_Map.GetMapInfo(mapID)
    end
end

function MapApi:GetPlayerPosition(mapID)
    if not C_Map or not C_Map.GetPlayerMapPosition then
        return nil, nil
    end

    local resolvedMapID = mapID or self:GetPlayerMapID()
    if not resolvedMapID then
        return nil, nil
    end

    local position = C_Map.GetPlayerMapPosition(resolvedMapID, "player")
    if not position then
        return nil, nil
    end
    return position:GetXY()
end

function MapApi:GetMapWorldSize(mapID)
    if C_Map and C_Map.GetMapWorldSize then
        return C_Map.GetMapWorldSize(mapID)
    end
end

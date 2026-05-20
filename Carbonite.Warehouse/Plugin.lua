-- Carbonite.Warehouse | Plugin entry
-- New front door for the Warehouse plugin (inventory tracking across
-- characters and guild bank). Wraps the legacy CarboniteWarehouse
-- AceAddon and Nx.Warehouse namespace with the new Carbonite Plugin
-- pattern: shared logger, EventBus, options registration.

local Carbonite = _G.Carbonite
if not Carbonite then return end

local AceAddon = LibStub("AceAddon-3.0")
local Plugin = Carbonite.Core.Plugin

local WHAddon = AceAddon:GetAddon("CarboniteWarehouse", true)
if not WHAddon then
    WHAddon = AceAddon:NewAddon("CarboniteWarehouse",
        "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0", "AceHook-3.0")
end

local Warehouse = {}
WHAddon.Public = Warehouse
-- Cross-plugin access slot. Carbonite == Nx, and NxWarehouse.lua
-- populates Nx.Warehouse with the legacy method table (Init,
-- ConvertData, RecordCharacter, ...). Don't overwrite it.
Carbonite.Plugins = Carbonite.Plugins or {}
Carbonite.Plugins.Warehouse = Warehouse

-- Returns the canonical inventory table for a character. Defers to
-- the legacy storage so we are interoperable with users upgrading
-- from old Carbonite installs.
function Warehouse:GetCharacterInventory(charName)
    local Nx = _G.Nx
    if not Nx or not Nx.WHdb then return nil end
    local chars = Nx.WHdb.global.Characters
    return chars and chars[charName]
end

function Warehouse:EachCharacter(fn)
    local Nx = _G.Nx
    if not Nx or not Nx.WHdb or not Nx.WHdb.global.Characters then return end
    for name, data in pairs(Nx.WHdb.global.Characters) do fn(name, data) end
end

function Warehouse:CountItem(itemID)
    local total = 0
    self:EachCharacter(function(_, char)
        if not char.Items then return end
        for _, entry in ipairs(char.Items) do
            if entry.id == itemID then total = total + (entry.count or 0) end
        end
    end)
    return total
end

function Warehouse:ToggleWindow()
    local Nx = _G.Nx
    if Nx and Nx.Warehouse and Nx.Warehouse.ToggleShow then Nx.Warehouse:ToggleShow() end
end

Plugin.Bind(WHAddon, "Warehouse", {
    displayName = "Warehouse",
    order       = 50,
    options = function()
        local Nx = _G.Nx
        local function whDB()
            if Nx and Nx.WHdb then return Nx.WHdb.profile.Warehouse or {} end
            return {}
        end
        return {
            type = "group",
            name = "Warehouse",
            args = {
                blurb = {
                    order = 1, type = "description",
                    name = "Carbonite Warehouse tracks bag, bank, mail, and guild-bank inventories for every character on your account.\n\nThe full options panel still ships from the legacy module while the rewrite is in progress.",
                },
                openWindow = {
                    order = 2, type = "execute", name = "Open Warehouse window",
                    func = function() Warehouse:ToggleWindow() end,
                },
                showRarity = {
                    order = 3, type = "toggle", name = "Color items by rarity",
                    get = function() return whDB().ShowRarity end,
                    set = function(_, v) whDB().ShowRarity = v end,
                },
                showCount = {
                    order = 4, type = "toggle", name = "Show stack count",
                    get = function() return whDB().ShowCount end,
                    set = function(_, v) whDB().ShowCount = v end,
                },
                trackMail = {
                    order = 5, type = "toggle", name = "Track items in mail",
                    get = function() return whDB().TrackMail end,
                    set = function(_, v) whDB().TrackMail = v end,
                },
                trackAH = {
                    order = 6, type = "toggle", name = "Track auction house purchases",
                    get = function() return whDB().TrackAH end,
                    set = function(_, v) whDB().TrackAH = v end,
                },
            },
        }
    end,
})

-- LDB tooltip helper: other plugins (Quests, Map) can ask the
-- Warehouse plugin to count an item without depending on private
-- legacy paths.
Carbonite.Core.EventBus:Subscribe("WAREHOUSE_QUERY_ITEM", function(itemID, callback)
    if callback then callback(Warehouse:CountItem(itemID)) end
end)

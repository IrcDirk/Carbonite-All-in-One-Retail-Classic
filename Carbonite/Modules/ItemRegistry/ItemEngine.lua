-- Carbonite | Modules / ItemRegistry / ItemEngine
-- The legacy Nx.Item class extracted from Carbonite.lua. Handles:
--   * caching item names by id via C_Item.GetItemInfo
--   * the "ask server for the visited-vendor items" flow used to
--     populate vendor windows on first login
--   * a thin Nx.Item:ShowTooltip wrapper around Nx.TooltipText
--
-- Methods remain on Nx.Item because SetupEverything calls Init,
-- timers reference these methods via Nx.Item.X, and external
-- code may call Nx.Item:ShowTooltip / Nx.Item:Load.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")


-------------------------------------------------------------------------------
-- ITEM HANDLING
-- Item info loading and tooltip management
-------------------------------------------------------------------------------

---
-- Initialize item management
--
function Nx.Item:Init()
    self.Asked = {}
end

---
-- Load item info by ID
-- Caches result to avoid repeated queries
-- @param id  Item ID
--
function Nx.Item:Load (id)
    if not self.Asked[id] then
        local name, link = C_Item.GetItemInfo (id)
        if name then
            self.Asked[id] = name
        end
    end
end

---
-- Enable server-side item loading
-- Sets up tooltip for query and timer for update
--
function Nx.Item.EnableLoadFromServer()

--    Nx.prt ("EnableLoadFromServer")

    local self = Nx.Item

    self.TooltipFrm = CreateFrame ("GameTooltip", "NxTooltipItem", UIParent, "GameTooltipTemplate")
    self.TooltipFrm:SetOwner (UIParent, "ANCHOR_NONE")        -- We won't see with this anchor

    self.ItemsRequested = 0

    Item = Nx:ScheduleTimer (self.Timer, 1)
end

function Nx.Item.DisableLoadFromServer()

--    Nx.prt ("DisableLoadFromServer")

    local self = Nx.Item
    self.Needed = {}
    self.Load = function() end        -- Nuke function

    AskDeleteVV = Nx:ScheduleTimer (self.AskDeleteVV, 0)
end

function Nx.Item.AskDeleteVV()

    local function func()
            Nx.db.profile.VendorV = nil
            Nx.Map.Guide:UpdateVisitedVendors()
    end

    Nx:ShowMessage (Nx.TXTBLUE.."Carbonite:\n|cffffff60" .. L["Delete visited vendor data?"] .. "\n" .. L["This will stop the attempted retrieval of items on login."], L["Delete"], func, L["Cancel"])
end

---
-- Show item tooltip by ID
-- @param id       Item ID or link
-- @param compare  Show comparison tooltips if true
--
function Nx.Item:ShowTooltip (id, compare)

--    Nx.prtVar ("ShowTooltip", id)

    local id = tostring (id)

    id = Nx.Split ("^", id)

    if not strfind (id, "item:") then
        if strfind (id, "quest:") then
        else
            id = "item:" .. id .. ":0:0:0:0:0:0:0"        -- Without the 7 ":0" Pawn prints an error
        end
    end

    Nx.TooltipText:SetHyperlink (id)
end

function Nx.Item:DrawTimer()

    if next (self.Needed) then        -- More?
        Nx.prt (" %d " .. L["items retrieved"], self.ItemsRequested)

    else
        Nx.prt (L["Item retrieval from server complete"])
    end

    local g = Nx.Map:GetMap (1).Guide
    g:UpdateVisitedVendors()
    g:Update()
end


-- Carbonite | Modules / UserEvents
-- Player-event log (deaths, kills, honor, herb / mine / timber
-- gathering, opens). The legacy implementation was Nx.UEvents +
-- Nx.UEvents.List - a window with sortable rows. This class wraps
-- the verb surface so other modules can add events and query the
-- log without poking the legacy table directly.
--
-- Public API:
--   UserEvents:AddInfo(name)             -> mapID
--   UserEvents:AddDeath(name)
--   UserEvents:AddKill(name, npcID)
--   UserEvents:AddHonor(name)
--   UserEvents:AddHerb(name)
--   UserEvents:AddMine(name)
--   UserEvents:AddTimber(name)
--   UserEvents:AddOpen(type, name)
--   UserEvents:OpenWindow()
--   UserEvents:GetPlayerPosition()       -> mapID, x, y, level
--   UserEvents:Refresh()                 -> redraw the window
--
-- Every Add* fires a USER_EVENTS_ADDED EventBus signal so the
-- minimap-button glow / chat alerter / quest tracker can react.

local Carbonite = _G.Carbonite

local UserEvents = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.UserEvents = UserEvents

local function legacy() return _G.Nx and _G.Nx.UEvents end

local function fireAdded(kind, name, payload)
    Carbonite.Core.EventBus:Fire("USER_EVENT_ADDED", kind, name, payload)
end

function UserEvents:GetPlayerPosition()
    local L = legacy()
    if not L or not L.GetPlyrPos then return nil end
    return L:GetPlyrPos()
end

function UserEvents:Refresh()
    local L = legacy()
    if L and L.UpdateAll then L:UpdateAll() end
end

local function delegate(name, kind)
    UserEvents[name] = function(self, arg1, arg2)
        local L = legacy()
        if not L or not L[name] then return nil end
        local result = L[name](L, arg1, arg2)
        fireAdded(kind, arg1, { arg2 = arg2, mapID = result })
        return result
    end
end

delegate("AddInfo",   "info")
delegate("AddDeath",  "death")
delegate("AddKill",   "kill")
delegate("AddHonor",  "honor")
delegate("AddHerb",   "herb")
delegate("AddMine",   "mine")
delegate("AddTimber", "timber")
delegate("AddOpen",   "open")

function UserEvents:OpenWindow()
    local L = legacy()
    if L and L.List and L.List.Open then L.List:Open() end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if Carbonite.Core.SlashCommands then
        Carbonite.Core.SlashCommands:Register("events", function()
            UserEvents:OpenWindow()
        end, "open the user events window")
    end
end)

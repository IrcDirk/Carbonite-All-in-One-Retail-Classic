-- Carbonite | Modules / Map / MapOpen
-- Window lifecycle for the Carbonite map. The legacy implementation
-- spread Open / Close / ToggleSize / RestoreSize / MaxSize across
-- Nx.Map and Nx.Map.Maps[1].Win with subtle interactions between
-- the two scopes. This class is the single public API for "show /
-- hide / resize the map".
--
-- The legacy logic is intricate (size-mode argument, MaxCenter
-- option, RestoreBlizzBountyMap side effect, UISpecialFrames
-- registration). We delegate to it via Nx.Map.Maps[1] rather than
-- reimplementing all of it, because subtle behavior here would
-- break user muscle memory. What this class adds:
--   * EventBus fires on every transition so other modules can react.
--   * Clean Open/Close/Toggle verbs with no positional flags.
--   * Bug fix: ToggleSize guards against being called before
--     Nx.Map.Maps exists (early Map() command during login).
--
-- Public API:
--   MapOpen:Open()             - just show (current size kept)
--   MapOpen:Close()            - just hide
--   MapOpen:Toggle()           - show/hide
--   MapOpen:Maximize()         - force maximized
--   MapOpen:Restore()          - force normal size
--   MapOpen:IsShown()
--   MapOpen:IsMaximized()
--   MapOpen:ToggleSize(mode)   - legacy passthrough; mode is
--                                nil/0/1 (toggle/normal/max)

local Carbonite = _G.Carbonite

local MapOpen = {}
Carbonite.Modules.Map.MapOpen = MapOpen

local function legacy() return _G.Nx and _G.Nx.Map end
local function map1()
    local m = legacy()
    return m and m.Maps and m.Maps[1]
end

function MapOpen:IsShown()
    local map = map1()
    return map and map.Win and map.Win.IsShown and map.Win:IsShown() or false
end

function MapOpen:IsMaximized()
    local map = map1()
    return map and map.Win and map.Win.IsSizeMax and map.Win:IsSizeMax() or false
end

function MapOpen:Open()
    local m = legacy()
    if not m then return end
    if not m.Created and m.Open then m:Open() end           -- first-time creation
    local map = map1()
    if map and map.Win and map.Win.Show then map.Win:Show(true) end
    Carbonite.Core.EventBus:Fire("MAP_OPENED")
end

function MapOpen:Close()
    local map = map1()
    if map and map.Win and map.Win.Show then map.Win:Show(false) end
    Carbonite.Core.EventBus:Fire("MAP_CLOSED")
end

function MapOpen:Toggle()
    if self:IsShown() then self:Close() else self:Open() end
end

function MapOpen:Maximize()
    local map = map1()
    if map and map.MaxSize then map:MaxSize() end
    Carbonite.Core.EventBus:Fire("MAP_MAXIMIZED")
end

function MapOpen:Restore()
    local map = map1()
    if map and map.RestoreSize then map:RestoreSize() end
    Carbonite.Core.EventBus:Fire("MAP_RESTORED")
end

-- Passthrough to legacy ToggleSize. Adds a guard for early calls
-- (the legacy version errors when self.Maps is still nil during
-- early /carb invocations).
function MapOpen:ToggleSize(mode)
    local m = legacy()
    if not m or not m.Maps then return end
    if m.ToggleSize then m:ToggleSize(mode) end
end

local function rewireLegacy()
    -- Nothing to rewire here yet: the legacy Open / ToggleSize remain
    -- the canonical implementations. This module is the *public face*
    -- that other modules and slash commands talk to.
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    rewireLegacy()
    if Carbonite.Core.SlashCommands then
        Carbonite.Core.SlashCommands:Register("max", function() MapOpen:Maximize() end,
            "maximize the Carbonite map")
        Carbonite.Core.SlashCommands:Register("restore", function() MapOpen:Restore() end,
            "restore the Carbonite map to normal size")
    end
end)

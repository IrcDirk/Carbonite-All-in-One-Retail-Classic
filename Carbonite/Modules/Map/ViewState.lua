-- Carbonite | Modules / Map / ViewState
-- Named map-view persistence. The legacy implementation stored every
-- saved view in Nx.Map.Maps[1].ViewSavedData with the BG-prefix
-- baked into the key string. This class gives those views a stable
-- public API and isolates the BG-key construction in one place.
--
--   ViewState:Save(name)        - capture current pos/scale under `name`
--   ViewState:Restore(name)     - move the map back to that pos/scale
--   ViewState:Has(name)         - bool: does a view exist under that key
--   ViewState:Clear(name)       - delete a saved view (or all when nil)
--   ViewState:Names()           - array of saved view names
--
-- The "BG namespace" mechanic is preserved verbatim: when the player
-- is in a battleground, saves and reads are scoped under a prefix so
-- exiting the BG restores the user's normal-world view automatically.

local Carbonite = _G.Carbonite

local ViewState = {}
Carbonite.Modules.Map.ViewState = ViewState

local function legacyMap()
    return _G.Nx and _G.Nx.Map and _G.Nx.Map.Maps and _G.Nx.Map.Maps[1]
end

local function viewKey(name)
    local Nx = _G.Nx
    local prefix = (Nx and Nx.InBG) and Nx.InBG or ""
    return ("%s%s"):format(prefix, name or "")
end

local function viewStore(map)
    map.ViewSavedData = map.ViewSavedData or {}
    return map.ViewSavedData
end

function ViewState:Save(name)
    local map = legacyMap()
    if not map then return end
    local key = viewKey(name)
    local store = viewStore(map)
    local v = store[key]
    if not v then v = {}; store[key] = v end
    v.Scale = map.Scale
    v.X     = map.MapPosX
    v.Y     = map.MapPosY
    Carbonite.Core.EventBus:Fire("MAP_VIEW_SAVED", name, key)
end

function ViewState:Restore(name)
    local map = legacyMap()
    if not map then return false end
    local store = viewStore(map)
    local v = store[viewKey(name)]
    if not v then return false end
    if map.Move then
        map:Move(v.X, v.Y, v.Scale, 30)
    else
        map.MapPosX, map.MapPosY, map.Scale = v.X, v.Y, v.Scale
    end
    Carbonite.Core.EventBus:Fire("MAP_VIEW_RESTORED", name, viewKey(name))
    return true
end

function ViewState:Has(name)
    local map = legacyMap()
    if not map then return false end
    return viewStore(map)[viewKey(name)] ~= nil
end

function ViewState:Clear(name)
    local map = legacyMap()
    if not map then return end
    local store = viewStore(map)
    if name == nil then
        for k in pairs(store) do store[k] = nil end
        return
    end
    store[viewKey(name)] = nil
end

function ViewState:Names()
    local map = legacyMap()
    if not map then return {} end
    local out = {}
    for k in pairs(viewStore(map)) do out[#out + 1] = k end
    table.sort(out)
    return out
end

-- Legacy rewire so the old SaveView/RestoreView entry points keep working.
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end
    NxMap.SaveView    = function(_, name) ViewState:Save(name) end
    NxMap.RestoreView = function(_, name) return ViewState:Restore(name) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)

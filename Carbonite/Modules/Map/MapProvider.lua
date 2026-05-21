-- Carbonite | Modules / Map / MapProvider
-- Public API for plugging icons into the Carbonite map. Wraps the
-- internal Pin / Layer system so third-party addons (and Carbonite's
-- own plugins) don't have to reach into private modules.
--
-- A Provider owns one named Layer plus a set of Pin classes scoped
-- to that provider. Layer isolation means providers can't trample
-- each other's pins; clearing one doesn't affect the others.
--
-- Usage:
--
--   local provider = Carbonite.Map:CreateProvider("MyAddon")
--   provider:DefinePin("Treasure", {
--       tex      = "Interface\\Icons\\INV_Misc_Map02",
--       w        = 16,
--       h        = 16,
--       drawMode = "WP",       -- "WP" world | "ZP" zone | "ZR" rect
--       onClick  = function(pin, mouseButton) ... end,
--       onEnter  = function(pin) return "Tooltip text" end,
--   })
--
--   function provider:OnMapChanged(mapID)
--       self:Clear()
--       for _, item in ipairs(myData[mapID] or {}) do
--           self:Add("Treasure", item.wx, item.wy, {
--               tip = item.label,
--           })
--       end
--   end
--
-- Carbonite will invoke OnMapChanged when the player opens a new
-- map, switches dungeon level, etc. Providers can also drive their
-- own updates and call provider:Add/provider:Clear directly.
--
-- See Docs/MapProvider.md for the full API reference.

local Carbonite = _G.Carbonite

Carbonite.Modules         = Carbonite.Modules or {}
Carbonite.Modules.Map     = Carbonite.Modules.Map or {}

local MapProvider = {}
Carbonite.Modules.Map.MapProvider = MapProvider

-- Public alias on Carbonite.Map for the conventional entry point.
Carbonite.Map = Carbonite.Map or {}
function Carbonite.Map:CreateProvider(name)
    return MapProvider.CreateProvider(name)
end

local Provider = {}
Provider.__index = Provider

MapProvider.providers = {}   -- name -> Provider

local function pinKindFor(providerName, kind)
    -- Prefix with "!" so the renderer's `computeEnabled` always
    -- treats provider layers as visible regardless of the
    -- `drawNonGuide` mode flag — matches the convention used by
    -- the built-in integration layers (!HANDY, !QUE, !RSR, etc.).
    -- Without this, provider pins silently fail to render whenever
    -- drawNonGuide is false (e.g. KillShow off).
    return "!" .. providerName .. ":" .. kind
end

-- Register / look up a provider by name. Calling twice with the same
-- name returns the existing instance, so callers don't need to track
-- their own singleton.
function MapProvider.CreateProvider(name)
    assert(type(name) == "string" and name ~= "",
        "Carbonite.Map:CreateProvider: name must be a non-empty string")
    local existing = MapProvider.providers[name]
    if existing then return existing end

    -- One Layer per pin kind (created in DefinePin), not one per
    -- provider. The renderer maps Pin class to Layer by matching
    -- their name strings (`Pin.GetClass(layer.name)` in
    -- Renderer.lua:Render), so each layer must share its name with
    -- a registered Pin class. With multiple pin kinds per provider
    -- we need per-kind layers.
    local p = setmetatable({
        name         = name,
        layers       = {},   -- full pin-class kind -> Layer
        pinDefs      = {},   -- short kind -> full pin-class kind string
        currentMapID = nil,
    }, Provider)
    MapProvider.providers[name] = p
    return p
end

function MapProvider.Get(name)
    return MapProvider.providers[name]
end

-- ---------------------------------------------------------------
-- Pin class registration
-- ---------------------------------------------------------------

-- Define a pin class scoped to this provider. `kind` is a short
-- string used by Add()/the provider's own code; internally the class
-- is registered as "<providerName>:<kind>" so providers can't
-- collide on common names like "Quest".
function Provider:DefinePin(kind, opts)
    assert(type(kind) == "string" and kind ~= "",
        "Provider:DefinePin: kind must be a non-empty string")
    local Pin   = Carbonite.Modules.Map.Pin
    local Layer = Carbonite.Modules.Map.Layer
    local fullKind = pinKindFor(self.name, kind)
    local def = {}
    for k, v in pairs(opts or {}) do def[k] = v end
    -- Sensible defaults for the renderer's required fields.
    def.drawMode = def.drawMode or "WP"
    def.scale    = def.scale or 1
    -- Pin class + matching Layer (same name) so the renderer's
    -- `Pin.GetClass(layer.name)` lookup resolves.
    Pin.Define(fullKind, def)
    self.layers[fullKind] = Layer.Get(fullKind)
    self.pinDefs[kind] = fullKind
    return def
end

-- ---------------------------------------------------------------
-- Pin lifecycle
-- ---------------------------------------------------------------

-- Acquire a pin of the given kind, fill in user-supplied fields,
-- and append it to the provider's layer.
--
-- Required positional: kind, wx, wy. (For "ZP" / "ZR" drawModes the
-- coordinates are zone-percent rather than world; for "WP" they're
-- world coordinates produced by Map:GetWorldPos.)
--
-- `opts` is a flat table of pin fields:
--   tip       string (tooltip; supports \n + \t for multi-line)
--   color     "AARRGGBB" string or {r,g,b,a}
--   tex       per-pin texture override
--   level     frame-level offset (default from class)
--   mapID     pin's source map (required for some drawMode/clip combos)
--   userData  arbitrary value carried back to onClick / onEnter
--   x2 / y2   second endpoint (LINE drawMode only)
-- Transient fields the renderer / onStamp callbacks read. Cleared
-- on every Add so a recycled pin from a previous use can't leak
-- stale values into a call site that didn't set them. (E.g. a
-- distance-arrow pin sets pin.w; if it's later reused as a regular
-- POI pin that doesn't set w, the renderer would otherwise still
-- see the old per-pin size and skip the class default.)
local TRANSIENT_FIELDS = {
    "tip", "tex", "color", "w", "h", "level", "mapID",
    "NXType", "NXData", "x2", "y2", "userData",
    "vertexColor", "showGlow", "label",
    "tx1", "ty1", "tx2", "ty2",
}

function Provider:Add(kind, wx, wy, opts)
    local Pin = Carbonite.Modules.Map.Pin
    local fullKind = self.pinDefs[kind]
    assert(fullKind, "Provider " .. self.name
        .. ": unknown pin kind " .. tostring(kind)
        .. " (DefinePin first)")
    local pin = Pin.Acquire(fullKind, self.currentMapID, wx, wy)
    for i = 1, #TRANSIENT_FIELDS do pin[TRANSIENT_FIELDS[i]] = nil end
    pin.x, pin.y = wx, wy
    if opts then
        for k, v in pairs(opts) do pin[k] = v end
    end
    self.layers[fullKind]:Add(pin)
    return pin
end

-- Remove every pin across every kind from this provider's layers.
-- Pin instances go back into their per-kind freelist for reuse.
function Provider:Clear()
    for _, layer in pairs(self.layers) do layer:Clear() end
end

-- Iterate live pins across every kind. `fn` receives each pin.
function Provider:Each(fn)
    for _, layer in pairs(self.layers) do layer:Each(fn) end
end

function Provider:Count()
    local n = 0
    for _, layer in pairs(self.layers) do n = n + layer:Count() end
    return n
end

-- ---------------------------------------------------------------
-- Visibility / lifecycle hooks
-- ---------------------------------------------------------------

-- Show / hide the whole provider without dropping its pins. Useful
-- for "toggle this layer" UI without losing state.
function Provider:SetEnabled(on)
    for _, layer in pairs(self.layers) do layer:SetVisible(on) end
end

function Provider:IsEnabled()
    for _, layer in pairs(self.layers) do
        if not layer.visible then return false end
    end
    return true
end

-- Returns the set of underlying Layer names (one per kind). Mostly
-- useful for tests / debug overlays.
function Provider:GetLayerNames()
    local names = {}
    for fullKind in pairs(self.layers) do names[#names+1] = fullKind end
    return names
end

-- Tell Carbonite that the visible map has changed. Carbonite's
-- internal Map module calls this on every provider it knows about
-- when MapID flips; third-party providers can also call it
-- themselves if they want to drive updates from their own events.
-- The default implementation just records the mapID and dispatches
-- to a user-supplied :OnMapChanged override if present.
function Provider:NotifyMapChanged(mapID)
    if self.currentMapID == mapID then return end
    self.currentMapID = mapID
    if type(self.OnMapChanged) == "function" then
        self:OnMapChanged(mapID)
    end
end

-- Convenience for "force redraw on the next render pass". Most
-- providers don't need it because Add/Clear already mutate the
-- layer; useful if a provider's data changed externally and it
-- wants to rebuild without flipping the map.
function Provider:Refresh()
    if type(self.OnRefresh) == "function" then
        self:OnRefresh()
    elseif type(self.OnMapChanged) == "function" and self.currentMapID then
        self:OnMapChanged(self.currentMapID)
    end
end

-- ---------------------------------------------------------------
-- Internal: broadcast a map change to every registered provider.
-- Called from MapEngine when the player opens a new map / changes
-- dungeon level. Third-party code should NOT call this directly —
-- use provider:NotifyMapChanged for self-driven updates.
-- ---------------------------------------------------------------
function MapProvider.BroadcastMapChanged(mapID)
    for _, p in pairs(MapProvider.providers) do
        p:NotifyMapChanged(mapID)
    end
end

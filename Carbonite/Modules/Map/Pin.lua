-- Carbonite | Modules / Map / Pin
-- Base class for every icon that gets drawn on the Carbonite map and
-- minimap. The legacy code stamped every icon as a raw table with
-- different keys at every call site; this Pin class gives them all
-- a common shape so the pin renderer can iterate without per-source
-- conditionals.
--
-- Pin types extend this base via Carbonite.UI.Mixin.Apply (see
-- Pins/*.lua). Concrete pins live in Pins/<Kind>Pin.lua and only
-- override `OnAcquire`, `OnRelease`, and optionally `Update`.

local Carbonite = _G.Carbonite
local Mixin = Carbonite.UI.Mixin

local Pin = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.Map = Carbonite.Modules.Map or {}
Carbonite.Modules.Map.Pin = Pin

-- All known pin classes by kind string.
Pin.classes = {}

function Pin.Define(kind, mixin)
    mixin.kind = kind
    Pin.classes[kind] = mixin
    return mixin
end

-- Static factory. Allocates a generic table, applies the kind's
-- mixin chain, calls OnAcquire. Pool is a flat array indexed by kind.
local pools = {}

function Pin.Acquire(kind, ...)
    local cls = Pin.classes[kind]
    if not cls then
        error("Pin.Acquire: unknown kind " .. tostring(kind), 2)
    end
    local pool = pools[kind] or {}
    pools[kind] = pool
    local pin = table.remove(pool)
    if not pin then
        pin = Mixin.Apply({}, Pin, cls)
        pin.kind = kind
    end
    pin:OnAcquire(...)
    return pin
end

function Pin.Release(pin)
    if not pin or not pin.kind then return end
    if pin.OnRelease then pin:OnRelease() end
    local pool = pools[pin.kind] or {}
    pools[pin.kind] = pool
    pool[#pool + 1] = pin
end

-- Default lifecycle methods. Concrete pin classes can override.
function Pin:OnAcquire(mapID, x, y, icon, text)
    self.mapID = mapID
    self.x     = x
    self.y     = y
    self.icon  = icon
    self.text  = text
    self.show  = true
end

function Pin:OnRelease()
    self.mapID, self.x, self.y, self.icon, self.text = nil, nil, nil, nil, nil
    self.show = false
end

-- Updates rendered position. Renderer calls this each frame; cheap
-- by default so individual pin classes can override only when they
-- need to (e.g. moving group-member pins).
function Pin:Update() end

-- Returns true when the pin should be drawn at the current zoom.
-- Hot-path; keep it allocation-free.
function Pin:ShouldDraw(viewMapID, scale)
    if not self.show then return false end
    if self.mapID ~= viewMapID then return false end
    if self.minScale and scale < self.minScale then return false end
    if self.maxScale and scale > self.maxScale then return false end
    return true
end

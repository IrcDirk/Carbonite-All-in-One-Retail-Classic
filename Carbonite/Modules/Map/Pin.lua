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
--
-- Per-class metadata lives directly on the class table (set via
-- Pin.Define). The renderer reads these fields to know how to draw
-- every pin of this kind:
--   drawMode      "ZP" zone-point, "WP" world-point, "ZR" zone-rect
--   w, h          pixel size at scale 1
--   tex           default texture path (per-instance .tex overrides)
--   scale         per-type scale multiplier (default 1)
--   scaleMode     "navigation" uses fixed IconNavScale instead of map zoom
--   atScale       min map zoom below which the whole class is hidden
--   alpha         base alpha
--   alphaNear     pulse alpha when player within 80yd (nil = no pulse)
--   frameLvl      frame-level offset added to map base level
--   clipKind      "z" / "map" / "w" / "chop" / "tl"; defaults from drawMode
--   noDockMinimap when true, hide pins overlapping the docked minimap
--   enabled       per-class visibility (mutable; see Pin.SetClassEnabled)

local Carbonite = _G.Carbonite
local Mixin = Carbonite.UI.Mixin

local Pin = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.Map = Carbonite.Modules.Map or {}
Carbonite.Modules.Map.Pin = Pin

-- All known pin classes by kind string.
Pin.classes = {}

local DEFAULT_CLIP_KIND = { ZP = "z", WP = "map", ZR = "tl", LINE = "none" }

function Pin.Define(kind, mixin)
    mixin.kind = kind
    if mixin.clipKind == nil and mixin.drawMode then
        mixin.clipKind = DEFAULT_CLIP_KIND[mixin.drawMode]
    end
    if mixin.scale == nil then mixin.scale = 1 end
    if mixin.enabled == nil then mixin.enabled = true end
    Pin.classes[kind] = mixin
    return mixin
end

function Pin.GetClass(kind)
    return Pin.classes[kind]
end

-- Mutates a per-class field. Used by the legacy IconType setters
-- (SetIconTypeAlpha / SetIconTypeAtScale / ...) and by anything that
-- wants to retune a whole pin kind at runtime.
function Pin.SetClassField(kind, field, value)
    local c = Pin.classes[kind]
    if c then c[field] = value end
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

-- Wipe the recycled-pin pool for a kind. Needed when the kind's
-- class is being re-defined (e.g. an icon size slider runs
-- ClearIconType + InitIconType): Mixin.Apply only stamps cls.w/h
-- onto a pin at fresh allocation, so without a pool wipe the next
-- AddIconPt would hand back a pooled pin still carrying the old
-- pin.w / pin.h and the size change would be invisible.
function Pin.ClearPool(kind)
    pools[kind] = nil
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
    -- Older Renderer revisions cached atlas state on the pin; clear
    -- so a recycled pin starts fresh.
    self._isAtlas, self._atlasName = nil, nil
end

-- Updates rendered position. Renderer calls this each frame; cheap
-- by default so individual pin classes can override only when they
-- need to (e.g. moving group-member pins).
function Pin:Update() end

-- Returns true when the pin should be drawn at the current zoom.
-- Hot-path; keep it allocation-free.
function Pin:ShouldDraw(viewMapID, scale)
    if not self.show then return false end
    if self.mapID and viewMapID and self.mapID ~= viewMapID then return false end
    if self.minScale and scale < self.minScale then return false end
    if self.maxScale and scale > self.maxScale then return false end
    return true
end

-- Carbonite | Modules / Map / Layer
-- A Layer is a visibility group for pins. The renderer iterates only
-- the active layers' pins, which keeps the per-frame cost predictable.
-- Old code mixed every pin source into a single flat array and
-- toggled visibility by mutating a `show` field on each individual
-- pin, which made bulk toggles (e.g. "hide all herbs") O(n).

local Carbonite = _G.Carbonite
local Layer = {}
Carbonite.Modules.Map.Layer = Layer

Layer.__index = Layer

function Layer.New(name)
    return setmetatable({
        name    = name,
        visible = true,
        pins    = {},
        version = 0,           -- bumped on any mutation; renderer uses
                               -- it to know when to rebuild caches.
    }, Layer)
end

function Layer:Add(pin)
    self.pins[#self.pins + 1] = pin
    self.version = self.version + 1
end

function Layer:Remove(pin)
    for i, p in ipairs(self.pins) do
        if p == pin then
            table.remove(self.pins, i)
            self.version = self.version + 1
            return
        end
    end
end

function Layer:Clear()
    local Pin = Carbonite.Modules.Map.Pin
    for _, pin in ipairs(self.pins) do Pin.Release(pin) end
    self.pins = {}
    self.version = self.version + 1
end

function Layer:SetVisible(v)
    if self.visible == v then return end
    self.visible = v
    self.version = self.version + 1
    Carbonite.Core.EventBus:Fire("MAP_LAYER_VISIBILITY_CHANGED", self.name, v)
end

function Layer:Each(fn)
    for _, pin in ipairs(self.pins) do fn(pin) end
end

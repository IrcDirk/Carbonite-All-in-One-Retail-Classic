-- Carbonite | Modules / Map / Layer
-- A Layer is a visibility group for pins. The renderer iterates only
-- the active layers' pins, which keeps the per-frame cost predictable.
-- Old code mixed every pin source into a single flat array and
-- toggled visibility by mutating a `show` field on each individual
-- pin, which made bulk toggles (e.g. "hide all herbs") O(n).
--
-- Layer.lua owns the layer *registry*. Map.lua delegates GetLayer /
-- Layers / RemoveLayer here so other modules (notably the Renderer)
-- don't need a runtime reference to the Map module instance.

local Carbonite = _G.Carbonite
local Layer = {}
Carbonite.Modules.Map.Layer = Layer

Layer.__index = Layer

-- Registry of layers by name. Renderer iterates this each frame.
Layer.registry = {}

function Layer.New(name)
    return setmetatable({
        name    = name,
        visible = true,
        pins    = {},
        version = 0,           -- bumped on any mutation; renderer uses
                               -- it to know when to rebuild caches.
    }, Layer)
end

function Layer.Get(name)
    local l = Layer.registry[name]
    if not l then
        l = Layer.New(name)
        Layer.registry[name] = l
    end
    return l
end

function Layer.Remove(name)
    local l = Layer.registry[name]
    if l then l:Clear() end
    Layer.registry[name] = nil
end

function Layer.All()
    return Layer.registry
end

function Layer:Add(pin)
    self.pins[#self.pins + 1] = pin
    self.version = self.version + 1
end

-- Note: must NOT be called `Remove`. Lua method tables don't
-- separate static and instance namespaces — `Layer.Remove(name)`
-- and `Layer:Remove(pin)` would both write to the same key in
-- the Layer table, and the second definition would clobber the
-- first.
function Layer:RemovePin(pin)
    for i, p in ipairs(self.pins) do
        if p == pin then
            table.remove(self.pins, i)
            self.version = self.version + 1
            return
        end
    end
end

function Layer:Clear()
    -- Truncate in place rather than reallocating `self.pins = {}` —
    -- under heavy per-frame churn (NxQuest's icon producer in
    -- particular) the new-table allocation was the dominant GC
    -- source for the whole render loop.
    local Pin  = Carbonite.Modules.Map.Pin
    local pins = self.pins
    for i = #pins, 1, -1 do
        Pin.Release(pins[i])
        pins[i] = nil
    end
    self.version = self.version + 1
end

function Layer:Count()
    return #self.pins
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

-- Carbonite | UI / Mixin
-- Small reimplementation of Blizzard's Mixin / CreateFromMixins
-- pattern so Carbonite can use the same pattern on every client,
-- including older Classic flavors where the global helpers are
-- missing or behave inconsistently.
--
--   local Foo = {}
--   function Foo:Bar() ... end
--   Carbonite.UI.Mixin.Apply(frame, Foo, OtherMixin)
--   frame:Bar()

local Carbonite = _G.Carbonite
local Mixin = {}
Carbonite.UI.Mixin = Mixin

-- Copies every function/value from each `mixin` onto `target`. Later
-- mixins win on key conflicts. Returns the target for chaining.
function Mixin.Apply(target, ...)
    for i = 1, select("#", ...) do
        local m = select(i, ...)
        if type(m) == "table" then
            for k, v in pairs(m) do target[k] = v end
        end
    end
    return target
end

-- Creates a fresh table with the supplied mixins applied, then calls
-- `:OnLoad()` if the resulting object defines one. Mirrors the
-- common Blizzard pattern used by templated frames.
function Mixin.New(...)
    local obj = Mixin.Apply({}, ...)
    if type(obj.OnLoad) == "function" then obj:OnLoad() end
    return obj
end

-- Convenience: create a Frame, apply mixins, run :OnLoad().
function Mixin.NewFrame(frameType, name, parent, template, ...)
    local frame = CreateFrame(frameType or "Frame", name, parent or UIParent, template)
    Mixin.Apply(frame, ...)
    if type(frame.OnLoad) == "function" then frame:OnLoad() end
    return frame
end

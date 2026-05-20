-- Carbonite | UI / Mixins / Draggable
-- Drop-in mixin that makes any Frame movable by left-click drag.
-- Persists position into the frame's `dbAnchor` table (if provided)
-- so user-positioned windows survive a /reload.

local Carbonite = _G.Carbonite
local Draggable = {}
Carbonite.UI.Mixins = Carbonite.UI.Mixins or {}
Carbonite.UI.Mixins.Draggable = Draggable

function Draggable:EnableDragging(dbAnchor)
    self.dbAnchor = dbAnchor
    self:SetMovable(true)
    self:EnableMouse(true)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", function(f) f:StartMoving() end)
    self:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if f.dbAnchor then
            local point, _, relPoint, x, y = f:GetPoint(1)
            f.dbAnchor.point    = point
            f.dbAnchor.relPoint = relPoint
            f.dbAnchor.x        = x
            f.dbAnchor.y        = y
        end
    end)
end

function Draggable:RestoreAnchor(parent, fallback)
    local a = self.dbAnchor or fallback
    if not a then return end
    self:ClearAllPoints()
    self:SetPoint(a.point or "CENTER", parent or UIParent, a.relPoint or "CENTER", a.x or 0, a.y or 0)
end

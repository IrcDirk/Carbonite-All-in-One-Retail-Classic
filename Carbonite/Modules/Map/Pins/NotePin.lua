-- Carbonite | Modules / Map / Pins / NotePin
-- A user-created waypoint / favourite note. The Notes module
-- supplies the storage; this class is just the visual layer.

local Carbonite = _G.Carbonite
local Pin = Carbonite.Modules.Map.Pin
local Tooltip = Carbonite.UI.Tooltip

local NotePin = Pin.Define("Note", {
    minScale = 0.3,
})

function NotePin:OnAcquire(opts)
    self.mapID = opts.mapID
    self.x     = opts.x
    self.y     = opts.y
    self.text  = opts.text or ""
    self.icon  = opts.icon or "Interface\\Minimap\\Minimap_skull_normal"
    self.color = opts.color
    self.show  = true
end

function NotePin:OnRelease()
    Pin.OnRelease(self)
    self.color = nil
end

function NotePin:ShowTooltip(owner)
    if self.text == "" then return end
    Tooltip:Show(owner, "ANCHOR_RIGHT", { self.text })
end

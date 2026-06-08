-- Carbonite | Modules / Map / Pins / NotePin
-- A user-created waypoint / favourite note. The Notes module
-- supplies the storage; this class is just the visual layer.

local Carbonite = _G.Carbonite
local Pin = Carbonite.Modules.Map.Pin
local Tooltip = Carbonite.UI.Tooltip

local NotePin = Pin.Define("Note", {
    -- Renderer metadata. Matches the legacy "!Fav" iconType. The
    -- "Note" layer name is canonical; NxFav.lua's MapIcons producer
    -- now writes here instead of the legacy "!Fav" iconType.
    drawMode = "WP",
    w = 17, h = 17,
    clipKind = "chop",
    minScale = 0.3,
    -- User-created notes must show regardless of guide/KillShow mode,
    -- matching the legacy "!Fav" iconType (which was always-on via its
    -- "!" prefix). See computeEnabled in Renderer.lua.
    alwaysShow = true,
})

function NotePin:OnAcquire(opts)
    -- Field names mirror what Renderer.lua's renderWP reads on each
    -- pin: pin.x / pin.y / pin.level / pin.tex / pin.color / pin.tip.
    -- Legacy callers used "text" + "icon"; both spellings are accepted
    -- so old call sites don't break during migration.
    self.mapID  = opts.mapID
    self.x      = opts.x
    self.y      = opts.y
    self.level  = opts.level
    self.tex    = opts.icon or "Interface\\Minimap\\Minimap_skull_normal"
    self.tip    = opts.text or opts.tip
    self.color  = opts.color
    self.favRef = opts.favRef     -- click-target user data (NxFav fav table)
    self.favIdx = opts.favIdx
    self.text   = self.tip        -- alias for old ShowTooltip code
    self.icon   = self.tex
    self.show   = true
end

function NotePin:OnRelease()
    Pin.OnRelease(self)
    self.level, self.tex, self.tip, self.color, self.favRef, self.favIdx, self.icon, self.text =
        nil, nil, nil, nil, nil, nil, nil, nil
end

function NotePin:ShowTooltip(owner)
    if self.text == "" then return end
    Tooltip:Show(owner, "ANCHOR_RIGHT", { self.text })
end

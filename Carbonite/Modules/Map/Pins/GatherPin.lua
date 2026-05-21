-- Carbonite | Modules / Map / Pins / GatherPin
-- A herbalism / mining / timber / treasure node pin. The legacy
-- Gathermate2_Data module ships flat arrays of {x,y,nodeId} per
-- map; this class wraps each entry so renderer code does not have
-- to know the source schema.

local Carbonite = _G.Carbonite
local Pin = Carbonite.Modules.Map.Pin
local Tooltip = Carbonite.UI.Tooltip
local Expansion = Carbonite.Compat.Expansion

local GatherPin = Pin.Define("Gather", {
    -- Renderer metadata. Matches the legacy "!Ga" iconType:
    -- world-point + chop, 12x12 base, atScale-gated so the dense
    -- node fields disappear when the map is zoomed way out.
    drawMode = "WP",
    w = 12, h = 12,
    clipKind = "chop",
    minScale = 0.6,
})

local KIND_TO_DIR = {
    herb   = "Herbalism",
    mine   = "Mining",
    timber = "Timber",
    treasure = "Treasure",
}

function GatherPin:OnAcquire(opts)
    self.mapID    = opts.mapID
    self.x        = opts.x
    self.y        = opts.y
    self.nodeID   = opts.nodeID
    self.nodeKind = opts.nodeKind        -- "herb" / "mine" / "timber" / "treasure"
    self.skill    = opts.skill or 0
    self.name     = opts.name
    self.icon     = opts.icon
    self.show     = true
end

function GatherPin:OnRelease()
    Pin.OnRelease(self)
    self.nodeID, self.nodeKind, self.skill, self.name = nil, nil, nil, nil
end

function GatherPin:IsRelevantToCurrentClient()
    if not self.skill then return true end
    local cap = Expansion:GetMaxGatherSkill()
    return self.skill <= cap
end

function GatherPin:ShouldDraw(viewMapID, scale)
    if not Pin.ShouldDraw(self, viewMapID, scale) then return false end
    return self:IsRelevantToCurrentClient()
end

function GatherPin:ShowTooltip(owner)
    if not self.name then return end
    Tooltip:Show(owner, "ANCHOR_RIGHT", { self.name })
end

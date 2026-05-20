-- Carbonite | Modules / Map / Pins / QuestPin
-- A pin representing a quest objective or quest giver. Looks up its
-- icon from the registry, scales with zoom, and routes tooltip
-- rendering through Carbonite.UI.Tooltip.

local Carbonite = _G.Carbonite
local Pin = Carbonite.Modules.Map.Pin
local Tooltip = Carbonite.UI.Tooltip

local QuestPin = Pin.Define("Quest", {
    minScale = 0.4,
})

local ICONS = {
    giver      = "Interface\\GossipFrame\\AvailableQuestIcon",
    turnin     = "Interface\\GossipFrame\\ActiveQuestIcon",
    objective  = "Interface\\AddOns\\Carbonite\\Gfx\\MMBut.tga",
}

function QuestPin:OnAcquire(opts)
    self.mapID    = opts.mapID
    self.x        = opts.x
    self.y        = opts.y
    self.questID  = opts.questID
    self.role     = opts.role or "objective"
    self.title    = opts.title
    self.icon     = opts.icon or ICONS[self.role]
    self.show     = true
end

function QuestPin:OnRelease()
    Pin.OnRelease(self)
    self.questID, self.role, self.title = nil, nil, nil
end

function QuestPin:ShowTooltip(owner)
    if not self.title then return end
    Tooltip:Show(owner, "ANCHOR_RIGHT", { self.title, "Quest: " .. tostring(self.questID) })
end

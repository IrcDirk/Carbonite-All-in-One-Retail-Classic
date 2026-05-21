-- Carbonite | Modules / Map / Pins / TrainerPin
-- Class trainer and profession trainer pins. The trainer database
-- still lives in Data/<flavor>/NxMapData.lua; this pin class just
-- describes how a single entry renders on the map.

local Carbonite = _G.Carbonite
local Pin = Carbonite.Modules.Map.Pin
local Tooltip = Carbonite.UI.Tooltip

local TrainerPin = Pin.Define("Trainer", {
    -- Renderer metadata. Trainers were "!T" in legacy: world-point,
    -- 16x16, chop so the city overlay doesn't bleed off the map.
    drawMode = "WP",
    w = 16, h = 16,
    clipKind = "chop",
    minScale = 0.5,
})

local ROLE_ICONS = {
    class      = "Interface\\Minimap\\Tracking\\Class",
    profession = "Interface\\Minimap\\Tracking\\Profession",
}

function TrainerPin:OnAcquire(opts)
    self.mapID    = opts.mapID
    self.x        = opts.x
    self.y        = opts.y
    self.name     = opts.name
    self.faction  = opts.faction        -- "Alliance" / "Horde" / "Both"
    self.role     = opts.role or "class"
    self.skill    = opts.skill          -- class name or profession key
    self.icon     = opts.icon or ROLE_ICONS[self.role]
    self.show     = true
end

function TrainerPin:OnRelease()
    Pin.OnRelease(self)
    self.name, self.faction, self.role, self.skill = nil, nil, nil, nil
end

function TrainerPin:ShowTooltip(owner)
    if not self.name then return end
    Tooltip:Show(owner, "ANCHOR_RIGHT", {
        self.name,
        ("%s trainer (%s)"):format(self.skill or self.role, self.faction or "Both"),
    })
end

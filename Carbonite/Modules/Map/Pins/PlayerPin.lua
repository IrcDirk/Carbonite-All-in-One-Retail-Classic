-- Carbonite | Modules / Map / Pins / PlayerPin
-- A player or group-member pin. Position updates each frame from
-- the live player table, so this overrides Update().

local Carbonite = _G.Carbonite
local Pin = Carbonite.Modules.Map.Pin
local MapApi = Carbonite.Compat.MapApi

local PlayerPin = Pin.Define("Player", {
    -- Renderer metadata. Player arrows draw on top of everything so
    -- frameLvl sits high; they pulse to be visible.
    drawMode = "WP",
    w = 20, h = 20,
    clipKind = "chop",
    frameLvl = 10,
})

function PlayerPin:OnAcquire(opts)
    self.unit  = opts.unit or "player"
    self.mapID = opts.mapID
    self.icon  = opts.icon or "Interface\\Minimap\\MinimapArrow"
    self.color = opts.color or { 1, 1, 0, 1 }
    self.show  = true
end

function PlayerPin:OnRelease()
    Pin.OnRelease(self)
    self.unit, self.color = nil, nil
end

function PlayerPin:Update()
    if not self.unit then return end
    local mapID = self.mapID or MapApi:GetPlayerMapID()
    if not mapID then return end
    local x, y = MapApi:GetPlayerPosition(mapID)
    if x and y then
        self.x, self.y = x, y
        self.mapID = mapID
    end
end

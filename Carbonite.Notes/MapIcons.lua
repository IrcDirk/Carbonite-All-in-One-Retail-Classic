-- Carbonite.Notes | MapIcons
-- Per-frame map-icon producer for the Notes plugin. Called from the
-- map's main update path (see MapEngine:Update). Responsibilities:
--   * `!Fav2`  - the currently-selected note's pulse marker
--   * `!Fav`   - every note in the current zone, plus addon-bridged
--                notes from `Nx.Notes.addonNotes`
--   * delegate to Questie / RareScanner / HandyNotes integrations
--   * `ShowIconNote` for opening the Notes window on an icon click
--   * `UpdateTargets` for the "T"/"t" goto-target follow-on

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Notes", true)

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

-- Bust an integration's per-tick dirty-check cache. Each integration
-- evolved its own field layout; rather than make every toggle
-- handler / size-change setter remember which fields belong to which
-- addon, callers just say `Nx.Notes:BustIntegrationCache("Questie")`
-- and we wipe whatever's needed. Safe to call when the integration's
-- cache fields don't exist yet (initial bootstrap before the
-- integration file has loaded). Pass nil/"all" to bust everything.
local INTEGRATION_FIELDS = {
    Questie = {
        QuestieCache     = "table",
        QuestieLastMapId = "nil",
        PrevQuestiePins  = "nil",
    },
    HandyNotes = {
        HandyNotesLastMapId = "nil",
        HandyNotesLastLevel = "nil",
    },
    RareScanner = {
        RSCache        = "table",
        RSLastMapId    = "nil",
        PrevRSPins     = "nil",
        RSNeedsRefresh = "true",
    },
    RXP = {
        RXPCache     = "table",
        RXPLastMapId = "nil",
        PrevRXPPins  = "nil",
    },
}

function Nx.Notes:BustIntegrationCache(name)
    if not name or name == "all" then
        for k in pairs(INTEGRATION_FIELDS) do self:BustIntegrationCache(k) end
        return
    end
    local fields = INTEGRATION_FIELDS[name]
    if not fields then return end
    for field, kind in pairs(fields) do
        if     kind == "table" then self[field] = {}
        elseif kind == "true"  then self[field] = true
        else                        self[field] = nil
        end
    end
end

-- Side-effects: opens the Notes window (or refreshes it) and selects
-- the favorite-item the icon belongs to. Called by MapEngine when
-- the user left-clicks a note icon.
function Nx.Notes:ShowIconNote(icon)
    local fav, index = Nx.Map:GetIconFavData(icon)

    self:OpenFoldersToFav(fav)
    self.FavToSelect = fav

    self.CurFolder      = self:GetParent(fav)
    self.CurFav         = fav
    self.CurItemI       = index
    self.CurFavOrFolder = fav

    if not (self.Win and self.Win:IsShown()) then
        self:ToggleShow()
        if not self.Win then return end   -- Not validated?
    else
        self:Update()
    end

    self:SelectItems(index)
end

-- Walk forward from CurItemI emitting goto-targets ("T" = primary,
-- "t" = secondary) onto the map until a non-target entry breaks the
-- run. The first target's `keep=false` clears any pre-existing
-- queue; subsequent ones pass `keep=true` so they accumulate.
function Nx.Notes:UpdateTargets()
    local shown = self.Win and self.Win:IsShown()
    if not (self.CurFav and self.CurItemI and (self.Recording or shown)) then
        return
    end

    self.InUpdateTarget = true

    local map = Nx.Map:GetMap(1)
    local keep

    for n = self.CurItemI, #self.CurFav do
        local str = self.CurFav[n]
        local typ, flags, name, data = self:ParseItem(str)
        if typ == "T" then
            if n ~= self.CurItemI then break end   -- another 1st target?
            local mapId, x, y = self:ParseItemTarget(data)
            map:SetTargetXY(mapId, x, y, name, keep)
            keep = true
        elseif typ == "t" then
            local mapId, x, y = self:ParseItemTarget(data)
            map:SetTargetXY(mapId, x, y, name, keep)
            keep = true
        else
            break
        end
    end

    if keep then map:GotoPlayer() end

    self.InUpdateTarget = false
end

-- Per-frame producer. Two parts:
--   1. The "selected note" pulse (!Fav2) which re-init's every frame
--      and either pulses one icon or clears the layer.
--   2. The full notes layer (!Fav) plus addon integrations. Re-built
--      only when the player's map or dungeon level changes (cheap
--      early-exit otherwise).
function Nx.Notes:UpdateIcons()
    local Map = Nx.Map
    local map = Map:GetMap(1)

    if self.CurFav and self.CurItemI then
        map:InitIconType("!Fav2", "WP", "", 21, 21)
        local typ, name, data
        if type(self.CurFav) ~= "string" then
            local str = self.CurFav[self.CurItemI]
            local _typ, _, _name, _data = self:ParseItem(str)
            typ, name, data = _typ, _name, _data
        end

        if typ == "N" then
            local icon, mapId, x, y, level = self:ParseItemNote(data)
            local relevant = not Map.IsMapRelevantToInstance
                or Map:IsMapRelevantToInstance(mapId, map.MapId)
            if relevant then
                icon = self:GetIconFile(icon)
                local wx, wy = Map:GetWorldPos(mapId, x, y)

                local pin = map:AddIconPt("!Fav2", wx, wy, level, nil, icon)
                pin.mapID, pin.MapId = mapId, mapId
                map:SetIconTip(pin, L["Note"] .. ": " .. name)
                map:SetIconFavData(pin, self.CurFav, self.CurItemI)

                map:SetIconTypeAlpha("!Fav2", abs((GetTime() * 100 % 100 - 50) / 50))
            end
        end
    else
        map:ClearIconType("!Fav2")
    end

    local mapId = map.MapId
    local draw  = map.ScaleDraw > .3 and Nx.fdb.profile.Notes.ShowMap

    -- Integrations fire every frame; each owns its own dirty-check.
    if Nx.fdb.profile.Notes.Questie and _G.Questie then
        self:Questie(mapId)
    end
    if Nx.fdb.profile.Notes.RareScanner and _G.RareScanner then
        self:RareScanner(mapId)
    end
    if Nx.fdb.profile.Notes.RXP and _G.RXP then
        self:RXP(mapId)
    end

    -- Early-exit when nothing's changed since the last !Fav rebuild.
    if mapId == self.DrawMapId
        and draw == self.Draw
        and self.InstLevelSet == Nx.Map:GetCurrentMapDungeonLevel() then
        return
    end

    self.DrawMapId = mapId
    self.Draw      = draw

    -- Refresh the "Note" layer through the new Pin / Layer API
    -- instead of the legacy map:AddIconPt("!Fav", …). Pin class
    -- metadata (drawMode / w / h / clipKind) lives on NotePin in
    -- Carbonite/Modules/Map/Pins/NotePin.lua.
    local MapMod = Carbonite:GetModule("Map", true)
    local Layer  = Carbonite.Modules.Map.Layer
    Layer.Get("Note"):Clear()

    if not draw and self.InstLevelSet == Nx.Map:GetCurrentMapDungeonLevel() then
        return
    end

    self.InstLevelSet = Nx.Map:GetCurrentMapDungeonLevel()

    -- IdToContZone returns (cont, zone); parens collapse to one value
    -- so tonumber doesn't get the zone as a base argument.
    local cont = tonumber((map:IdToContZone(mapId))) or 0
    if cont <= 0 or cont >= 90 then return end

    local function addNote(label, iconIdx, wx, wy, level, favRef, favIdx)
        if not MapMod then return end
        local pin = MapMod:AddPin("Note", "Note", {
            mapID  = mapId,
            x      = wx,
            y      = wy,
            level  = level,
            icon   = self:GetIconFile(iconIdx),
            text   = label,
            favRef = favRef,
            favIdx = favIdx,
        })
        -- Mirror SetIconFavData onto legacy fields so MapEngine's
        -- IconOnEnter / IconOnMouseDown (which still look up
        -- icon.FavData1/FavData2) keep working.
        if pin then
            pin.FavData1, pin.FavData2 = favRef, favIdx
        end
    end

    local notes = self:FindFolder(L["My Notes"])
    if notes then
        local fav = self:FindFav(mapId, "ID", notes)
        if fav then
            for n, str in ipairs(fav) do
                local typ, flags, name, data = self:ParseItem(str)
                if typ == "N" then
                    local icon, _, x, y, level = self:ParseItemNote(data)
                    local wx, wy = Map:GetWorldPos(mapId, x, y)
                    addNote(L["Note"] .. ": " .. name, icon, wx, wy, level, fav, n)
                end
            end
        end
    end

    local addonNotes = Nx.Notes.addonNotes or {}
    for a in pairs(addonNotes) do
        if a ~= "Hide" then
            for c, d in pairs(addonNotes[a]["notes"]) do
                local icon, zoneid, x, y, level = self:ParseItemNote(d)
                if zoneid == mapId then
                    local wx, wy = Map:GetWorldPos(mapId, x, y)
                    addNote(L["Note"] .. ": " .. c, icon, wx, wy, level, addonNotes[a], d)
                end
            end
        end
    end

    self:HandyNotes(mapId)
    GameTooltip:Hide()
end

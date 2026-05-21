-- Carbonite | Modules / DebugFlags / UnitDataCapture
-- Mouseover-unit debug capture extracted from Carbonite.lua. Three
-- Nx-namespaced methods drive a small NPC-coords + tooltip-text
-- database used when Nx.db.profile.Debug.DebugUnit is on:
--
--   Nx:UnitDGet(target)       fetch (and lazily create) the per-NPC
--                             record; returns data, guid, id, type
--   Nx:UnitDCapture()         stamp current player position onto the
--                             record for the currently targeted NPC
--                             (called from /carb unitc)
--   Nx:UnitDTip()             called during UPDATE_MOUSEOVER_UNIT:
--                             refresh the record with current map id /
--                             interact-distance bucket, append the
--                             live GameTooltip text, optionally drop
--                             a map target on the recorded coords
--
-- Callsites (Carbonite.lua's slashCommand and OnUpdate_mouseover_unit)
-- keep calling `Nx:UnitD*` directly; nothing else in the addon uses
-- these.

local Carbonite = _G.Carbonite
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

---
-- Get the unit-debug data table for `target` and parse the GUID into
-- numeric id / type. Returns nothing when DebugUnit is off.
-- @param target Unit ID to inspect ("mouseover" / "target" / etc.).
-- @return data table, guid string, npc id, type number
--
function Nx:UnitDGet(target)
    if not Nx.db.profile.Debug.DebugUnit then return end

    local guid = UnitGUID(target)
    if not guid then return end

    local id  = tonumber(strsub(guid, 7, 10), 16)
    local typ = tonumber(strsub(guid, 5,  5), 16)

    local data = Nx.db.profile.Debug.DBUnit or {}
    local ver = 2

    if (data["Ver"] or 0) < ver then
        data = {}
        data["Ver"] = ver
    end

    Nx.db.profile.Debug.DBUnit = data

    return data, guid, id, typ
end

---
-- Capture the player's current map + coords onto the targeted NPC's
-- record. Triggered from the /carb unitc slash command.
--
function Nx:UnitDCapture()
    local data, _, id, typ = self:UnitDGet("target")
    if not data or typ ~= 3 then return end

    local mid = Nx.Map:GetCurrentMapAreaID()
    local plZX, plZY = Nx.Map.GetPlayerMapPosition("player")
    if not mid or (plZX <= 0 and plZY <= 0) then
        Nx.prt(L["Unit map error"])
        return
    end

    local s = data[id] or "0~0~~~~"
    local reactA, reactH, _, _, _, tipStr = Nx.Split("~", s)

    data[id] = format("%s~%s~%s~%s~0~%s",
        reactA, reactH, mid, self:PackXY(plZX * 100, plZY * 100), tipStr)

    Nx.prt("UnitDCap: %s, %s, %s", id, plZX * 10000, plZY * 10000)
end

---
-- Run on every UPDATE_MOUSEOVER_UNIT: update the NPC's record with
-- the current map, interact-distance bucket, and full GameTooltip
-- text. Holding Ctrl prints a debug line; Ctrl+Shift drops a map
-- target on the recorded coords.
--
function Nx:UnitDTip()
    local data, _, id, typ = self:UnitDGet("mouseover")
    if not data or typ ~= 3 then return end

    local midCur = Nx.Map:GetCurrentMapAreaID()
    local plZX, plZY = Nx.Map.GetPlayerMapPosition("player")
    if not midCur or (plZX <= 0 and plZY <= 0) then
        Nx.prt(L["Unit map error"])
        return
    end

    local react = UnitReaction("mouseover", "player")

    local reactA, reactH, mid, xy, dist =
        Nx.Split("~", data[id] or "0~0~~000000~9")

    reactA = reactA or 0
    reactH = reactH or 0

    local x, y = self:UnpackXY(xy)

    if Nx.PlFactionNum == 0 then
        reactA = react
    else
        reactH = react
    end

    dist = tonumber(dist)

    -- Bucket distance: 1 = within 9.9yd, 2 = within 28yd, 9 = beyond.
    local dcur = 9
    if CheckInteractDistance("mouseover", 1) then dcur = 2 end
    if CheckInteractDistance("mouseover", 3) then dcur = 1 end

    if dcur <= dist then
        dist = dcur
        mid  = midCur
        x    = plZX * 100
        y    = plZY * 100
    end

    -- Snapshot every line in the current GameTooltip.
    local tipStr = ""
    local tip = GameTooltip
    for n = 1, tip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. n]:GetText()
        if line then tipStr = tipStr .. line .. "^" end
    end

    data[id] = format("%s~%s~%s~%s~%s~%s",
        reactA, reactH, mid, self:PackXY(x, y), dist, tipStr)

    if IsControlKeyDown() then
        Nx.prt("UnitDTip: %s %s, %d, %d (%d)",
            id, react or "nil", x * 100 + .5, y * 100 + .5, dist)
    end

    if IsShiftKeyDown() and IsControlKeyDown() and (x > 0 or y > 0) then
        local Map = Nx.Map
        local mapId = Map:GetCurrentMapId()
        local m = Map:GetMap(1)
        local tar = m:SetTargetXY(mapId, x, y, "UnitD " .. id)
        tar.Radius = 1
    end
end

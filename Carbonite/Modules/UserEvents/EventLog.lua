-- Carbonite | Modules / UserEvents / EventLog
-- Per-character event log: deaths, kills, gathers, "I info" entries.
-- Stored on `Nx.CurCharacter.E` as a packed string array. Each row
-- is "<type>^<time>^<mapId>^<xy>^<name>[^<data>]".
--
-- Extracted out of Carbonite.lua. The Nx.UEvents:Add* methods over
-- in NXOnUpdate still call these as `Nx:Add<Kind>Event`, so the
-- methods stay on the Nx namespace.

---
-- Trim every character's event list to 60 entries. Also drops
-- entries from older saved-variable shapes that used a hashtable
-- with an "Info" key instead of an array.
--
function Nx:DeleteOldEvents()
    for _, ch in pairs(Nx.db.global.Characters) do
        if not ch.E or ch.E["Info"] then
            ch.E = {}
        end
        self:DeleteOldEvent(ch.E, 60)
    end
end

---
-- Trim a single event array to `maxE` entries by removing from the
-- front (oldest first).
--
function Nx:DeleteOldEvent(ev, maxE)
    if #ev > maxE then
        for _ = 1, #ev - maxE do
            tremove(ev, 1)
        end
    end
end

---
-- Append a packed event row to the current character's log.
-- @param event "I" info, "K" kill, "D" death, "H" herb, "M" mine, "T" timber.
-- @param name  Short label / target name.
-- @param time  Timestamp from Nx:Time().
-- @param mapId Numeric map id.
-- @param x,y   Zone coords (0..100).
-- @param data  Optional extra payload string (Kill events stash
--              "<count>" or "<count>|<npcId>" here).
--
function Nx:AddEvent(event, name, time, mapId, x, y, data)
    local ev = Nx.CurCharacter.E

    local xy = Nx:PackXY(x, y)
    name = gsub(name, "^", "")

    local s = format("%s^%.0f^%d^%s^%s", event, time, mapId or 0, xy, name)
    if data then
        s = s .. "^" .. data
    end

    tinsert(ev, s)
end

---
-- Pull the mapId out of a packed event row without unpacking the
-- whole thing (cheap for filtering by map).
--
function Nx:GetEventMapId(evStr)
    local _, _, map = Nx.Split("^", evStr)
    return tonumber(map) or 0
end

---
-- Split a packed event row back into its fields.
-- @return type, time, mapId, x, y, name, data
--
function Nx:UnpackEvent(evStr)
    local typ, tm, map, xy, text, data = Nx.Split("^", evStr)
    tm  = tonumber(tm)
    map = tonumber(map) or 0
    local x, y = Nx:UnpackXY(xy)
    return typ, tm, map, x, y, text, data
end

-- Convenience wrappers for each event kind.

function Nx:AddInfoEvent (name, time, mapId, x, y)
    self:AddEvent("I", name, time, mapId, x, y)
end

function Nx:AddDeathEvent(name, time, mapId, x, y)
    self:AddEvent("D", name, time, mapId, x, y)
end

---
-- AddKillEvent counts how many times this same name has appeared as
-- a Kill in the log so we record a running kill counter alongside
-- the (optional) NPC id. The data field is "<kills>" for legacy
-- rows and "<kills>|<npcId>" for new ones.
--
function Nx:AddKillEvent(name, time, mapId, x, y, npcId)
    local ev = self.CurCharacter.E
    local kills = 1
    for _, item in ipairs(ev) do
        local typ, _, _, _, _, text = self:UnpackEvent(item)
        if typ == "K" and text == name then
            kills = kills + 1
        end
    end

    local data = npcId and format("%d|%d", kills, npcId) or format("%d", kills)
    self:AddEvent("K", name, time, mapId, x, y, data)
end

function Nx:AddHerbEvent  (name, time, mapId, x, y) self:AddEvent("H", name, time, mapId, x, y) end
function Nx:AddMineEvent  (name, time, mapId, x, y) self:AddEvent("M", name, time, mapId, x, y) end
function Nx:AddTimberEvent(name, time, mapId, x, y) self:AddEvent("T", name, time, mapId, x, y) end

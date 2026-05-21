-- Carbonite | Modules / PlayerCharacter / CharacterData
-- Saved-variable side of the per-character store: walks
-- Nx.db.global.Characters, creates a record on first login, finds /
-- copies / deletes character entries, and stamps level/class on the
-- current record. Lifted out of Carbonite.lua so the legacy main
-- file stops carrying ~230 lines of saved-data plumbing.
--
-- Methods stay on the Nx namespace because external callers
-- (CharacterRoster module, OptionsEngine page handlers, NxQuest,
-- NxWarehouse) still call them as Nx:InitCharacter / GetRealmCharName
-- / FindCharacter / CalcRealmChars / RecordCharacter / GetUnitClass /
-- DeleteCharacterData. The public PlayerCharacter accessor module
-- (PlayerCharacter.lua) covers the live-API side of "who is the
-- player"; this file owns the persistent record.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

---
-- Accessor for the per-character "data buckets" used by the legacy
-- code. `name` selects which sub-table to return; `ch` defaults to
-- the current character. Returns nil for unknown buckets.
--
function Nx:GetData(name, ch)
    ch = ch or Nx.CurCharacter

    if name == "Events" then return ch.E end
    if name == "List"   then return ch["L"] end
    if name == "Quests" then return ch.Q end
    if name == "Win"    then return Nx.db.profile.WinSettings end
    if name == "Herb"   then return Nx.db.profile.GatherData.NXHerb end
    if name == "Timber" then return Nx.db.profile.GatherData.NXTimber end
    if name == "Mine"   then return Nx.db.profile.GatherData.NXMine end
end

---
-- Copy List + ToolBar from one character record to another. With
-- a nil srcName, copies the current character's data to every other
-- record in the saved variables (export-to-everyone).
-- @param srcName Source character name (nil = export current to all).
-- @param dstName Destination character name (required if srcName is set).
-- @return true on success.
--
function Nx:CopyCharacterData(srcName, dstName)
    if not srcName then
        local sch = Nx.CurCharacter
        for _, dch in pairs(Nx.db.global.Characters) do
            if dch ~= sch then
                dch["L"]    = sch["L"]
                dch["TBar"] = sch["TBar"]
            end
        end
    else
        local sch = Nx:FindCharacter(srcName)
        local dch = Nx:FindCharacter(dstName)

        if not sch or not dch then
            Nx.prt(L["Missing character data!"])
            return
        end

        -- Reference copy here; SavedVariables write does the deep copy.
        dch["L"]    = sch["L"]
        dch["TBar"] = sch["TBar"]
    end

    return true
end

---
-- Delete a character record and rebuild the realm-character list.
-- Refreshes the Warehouse window if the plugin is loaded.
-- @param srcName Character name or "realm.character" key.
--
function Nx:DeleteCharacterData(srcName)
    self:DeleteCharacter(srcName)
    self:CalcRealmChars()
    if Nx.Warehouse then
        self.Warehouse:Update()
    end
end

---
-- Toolbar layout for the current character.
--
function Nx:GetDataToolBar()
    return Nx.CurCharacter["TBar"]
end

---
-- HUD options table (lives on the AceDB profile).
--
function Nx:GetHUDOpts()
    return Nx.db.profile.HUDOpts
end

---
-- Global capture table (quest / loot / vendor capture recording).
--
function Nx:GetCap()
    return Nx.db.global.Capture
end

---
-- Find or create an entry under `key` in `t`. Always returns the
-- live sub-table so callers can populate it.
--
function Nx:CaptureFind(t, key)
    assert(type(t) == "table" and key)

    local d = t[key] or {}
    t[key] = d
    return d
end

---
-- Initialise the current character's saved-variable record.
-- Creates a fresh entry if missing or stale-versioned, populates
-- the default sub-tables, then refreshes the realm-character list.
--
function Nx:InitCharacter()
    local chars = Nx.db.global.Characters
    local fullName = self:GetRealmCharName()
    local ch = chars[fullName]

    if not ch or ch.Version < Nx.VERSIONCHAR then
        ch = {}
        chars[fullName] = ch
        ch.Version = Nx.VERSIONCHAR
        ch.E = {}    -- Events
    end

    Nx.CurCharacter = ch

    ch["Opts"] = ch["Opts"] or {}
    ch["L"]    = ch["L"]    or {}
    if not ch["TBar"] then
        ch["TBar"] = {}
    end

    self:DeleteOldEvents()
    ch.NXLoggedOnNum = ch.NXLoggedOnNum or 0 + 1
    self:CalcRealmChars()
end

---
-- Stable key for the current player: "RealmName.CharacterName".
--
function Nx:GetRealmCharName()
    return GetRealmName() .. "." .. UnitName("player")
end

---
-- Build the alphabetised list of characters on the current realm
-- (plus connected realms), stored as Nx.RealmChars with the current
-- player pinned at index 1. Backfills missing fields on each record.
--
function Nx:CalcRealmChars()
    local chars     = Nx.db.global.Characters
    local realmName = GetRealmName()
    local fullName  = realmName .. "." .. UnitName("player")

    local t = {}
    for rc, v in pairs(chars) do
        if v ~= Nx.CurCharacter then
            local rname = Nx.Split(".", rc)
            if rname == realmName then
                tinsert(t, rc)
            end
        end
    end

    local connectedrealms = GetAutoCompleteRealms()
    if connectedrealms then
        for i = 1, #connectedrealms do
            for rc, v in pairs(chars) do
                if v ~= Nx.CurCharacter then
                    local rname = Nx.Split(".", rc)
                    if rname == connectedrealms[i] and connectedrealms[i] ~= realmName then
                        tinsert(t, rc)
                    end
                end
            end
        end
    end

    sort(t)                      -- alphabetical
    tinsert(t, 1, fullName)      -- pin self to top
    self.RealmChars = t

    -- Backfill missing fields on every record so older saved-variable
    -- shapes don't error on first access.
    for _, rc in ipairs(self.RealmChars) do
        local ch = chars[rc]
        if ch then
            if ch["XP"] then
                ch["XPMax"]   = ch["XPMax"]   or 1
                ch["XPRest"]  = ch["XPRest"]  or 0
                ch["LXP"]     = ch["LXP"]     or 0
                ch["LXPMax"]  = ch["LXPMax"]  or 1
                ch["LXPRest"] = ch["LXPRest"] or 0
            end
            ch["TimePlayed"] = ch["TimePlayed"] or 0
        end
    end
end

---
-- Look up a character by short name on the current realm, or by
-- full "realm.name" key. Returns the data table or nil.
--
function Nx:FindCharacter(name)
    for _, rc in ipairs(Nx.RealmChars) do
        local ch = Nx.db.global.Characters[rc]
        if ch then
            local _, cname = Nx.Split(".", rc)
            if cname == name then return ch end
        end
    end

    return Nx.db.global.Characters[name]
end

---
-- Remove a character record by short or "realm.name" key.
--
function Nx:DeleteCharacter(name)
    for _, rc in ipairs(Nx.RealmChars) do
        local ch = Nx.db.global.Characters[rc]
        if ch then
            local _, cname = Nx.Split(".", rc)
            if cname == name then
                Nx.db.global.Characters[rc] = nil
                return
            end
        end
    end

    Nx.db.global.Characters[name] = nil
end

---
-- Localised player class name, with the "Deathknight" -> "Death Knight"
-- spacing fix Carbonite's tables rely on.
--
function Nx:GetUnitClass()
    local _, cls = UnitClass("player")
    cls = gsub(Nx.Util_CapStr(cls), L["Deathknight"], L["Death Knight"])
    return cls
end

---
-- Stamp the current character record with the live level and class
-- string. Called periodically from NXOnUpdate.
--
function Nx:RecordCharacter()
    local ch = self.CurCharacter
    ch["Level"] = UnitLevel("player")
    ch["Class"] = Nx:GetUnitClass()
end

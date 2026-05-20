-- Carbonite | Modules / PlayerCharacter
-- Player identity + classification queries. The legacy code peppered
-- Nx.PlFactionNum, UnitClass("player") calls, Nx:UnitIsPlusMob,
-- character-key lookups, and an ad-hoc `Nx.CurCharacter` global
-- across multiple files. This class is the canonical accessor so
-- new code stops reading the live WoW API in 30 places.
--
-- Public API:
--   PlayerCharacter:GetName()         -> "Name-Realm" (or just Name on Classic
--                                        where realm isn't appended for self)
--   PlayerCharacter:GetClass()        -> localizedClass, classToken, classID
--   PlayerCharacter:GetRace()         -> localizedRace, raceToken
--   PlayerCharacter:GetFactionGroup() -> "Alliance" / "Horde" / "Neutral"
--   PlayerCharacter:GetFactionNumber() -> 1 (Alliance) / 0 (Horde) / 2 (other)
--   PlayerCharacter:GetLevel()        -> int
--   PlayerCharacter:GetGUID()
--   PlayerCharacter:GetClassColorStr()-> "|cffrrggbb" prefix
--   PlayerCharacter:IsElite(unit)     -> bool   (incl. rareelite / worldboss)
--   PlayerCharacter:IsPlayerInPVP()   -> bool

local Carbonite = _G.Carbonite

local PlayerCharacter = {}
Carbonite.Modules.PlayerCharacter = PlayerCharacter

function PlayerCharacter:GetName()
    if not _G.UnitFullName then return _G.UnitName and _G.UnitName("player") or "Player" end
    local name, realm = _G.UnitFullName("player")
    if not name then return "Player" end
    return (realm and realm ~= "") and (name .. "-" .. realm) or name
end

function PlayerCharacter:GetClass()
    if not _G.UnitClass then return "?", "WARRIOR", 1 end
    local localized, token, classID = _G.UnitClass("player")
    return localized or "?", token or "WARRIOR", classID or 1
end

function PlayerCharacter:GetRace()
    if not _G.UnitRace then return "?", "?" end
    return _G.UnitRace("player")
end

function PlayerCharacter:GetFactionGroup()
    if not _G.UnitFactionGroup then return "Neutral" end
    return _G.UnitFactionGroup("player") or "Neutral"
end

-- Carbonite's PlFactionNum convention: Horde = 0, Alliance = 1,
-- neutral / other = 2. Preserved from the legacy mapping so old
-- code that compares == 0 still works.
function PlayerCharacter:GetFactionNumber()
    local Nx = _G.Nx
    if Nx and Nx.PlFactionNum ~= nil then return Nx.PlFactionNum end
    local f = self:GetFactionGroup()
    if f == "Alliance" then return 1 end
    if f == "Horde"    then return 0 end
    return 2
end

function PlayerCharacter:GetLevel()
    if _G.UnitLevel then return _G.UnitLevel("player") or 0 end
    return 0
end

function PlayerCharacter:GetGUID()
    if _G.UnitGUID then return _G.UnitGUID("player") end
end

function PlayerCharacter:GetClassColorStr()
    local _, token = self:GetClass()
    local cc = (_G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS)
    local c = cc and cc[token]
    if not c then return "|cffffffff" end
    return ("|cff%02x%02x%02x"):format(
        math.floor((c.r or 1) * 255),
        math.floor((c.g or 1) * 255),
        math.floor((c.b or 1) * 255))
end

-- Elite / rareelite / worldboss classification. Mirrors the legacy
-- Nx:UnitIsPlusMob check; takes any unit token, not just "player".
function PlayerCharacter:IsElite(unit)
    if not _G.UnitClassification then return false end
    local c = _G.UnitClassification(unit or "target")
    return c == "elite" or c == "rareelite" or c == "worldboss"
end

function PlayerCharacter:IsPlayerInPVP()
    if not _G.UnitIsPVP then return false end
    return _G.UnitIsPVP("player") == true
end

-- Slash command: /cb whoami dumps the live profile snapshot.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("whoami", function()
        local log = Carbonite.Core.Logger:Get("PlayerCharacter")
        local localized, token = PlayerCharacter:GetClass()
        log:info("name    : %s", PlayerCharacter:GetName())
        log:info("class   : %s (%s)", localized, token)
        log:info("race    : %s", PlayerCharacter:GetRace())
        log:info("level   : %d", PlayerCharacter:GetLevel())
        log:info("faction : %s (#%d)", PlayerCharacter:GetFactionGroup(),
            PlayerCharacter:GetFactionNumber())
    end, "show this character's identity snapshot")
end)

-- Carbonite | Util / GameVersion
-- Wrapper around GetBuildInfo + the various BFAMaps / SLMaps /
-- TWWMaps boolean checks scattered across legacy code. The
-- canonical source is Compat.Expansion; this util is the simpler
-- accessor for the four-tuple GetBuildInfo returns.
--
-- Public API:
--   GameVersion:GetVersionString()    -> "11.0.0"
--   GameVersion:GetBuildNumber()      -> "55000"
--   GameVersion:GetBuildDate()        -> "Dec 1 2025"
--   GameVersion:GetTocVersion()       -> 110000
--   GameVersion:IsRetail()
--   GameVersion:IsClassic()
--   GameVersion:GetExpansionLevel()   -> int (Compat.Expansion.level)

local Carbonite = _G.Carbonite
local GameVersion = {}
Carbonite.Util.GameVersion = GameVersion

function GameVersion:_split()
    if not _G.GetBuildInfo then return "?", "0", "", 0 end
    return _G.GetBuildInfo()
end

function GameVersion:GetVersionString()
    local v = self:_split(); return v
end

function GameVersion:GetBuildNumber()
    local _, build = self:_split(); return build
end

function GameVersion:GetBuildDate()
    local _, _, date_ = self:_split(); return date_
end

function GameVersion:GetTocVersion()
    local _, _, _, toc = self:_split(); return toc or 0
end

function GameVersion:IsRetail()
    local E = Carbonite.Compat and Carbonite.Compat.Expansion
    return E and E.isMainline or false
end

function GameVersion:IsClassic()
    local E = Carbonite.Compat and Carbonite.Compat.Expansion
    return E and E.isClassic or false
end

function GameVersion:GetExpansionLevel()
    local E = Carbonite.Compat and Carbonite.Compat.Expansion
    return E and E.level or 0
end

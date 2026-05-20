-- Carbonite | Modules / CharacterRoster
-- Cross-character roster operations. Carbonite stores per-character
-- data in Nx.db.global.Characters indexed by realm-name; this
-- class is the public accessor for working with that table.
--
-- Public API:
--   CharacterRoster:GetAll()                  -> name -> data
--   CharacterRoster:Each(fn)
--   CharacterRoster:GetCurrent()              -> current char data
--   CharacterRoster:GetByName(name)
--   CharacterRoster:RecalculateRealmChars()   -> refresh cached set
--   CharacterRoster:Delete(name)
--   CharacterRoster:GetRealmChars()           -> array on current realm

local Carbonite = _G.Carbonite

local CharacterRoster = {}
Carbonite.Modules.CharacterRoster = CharacterRoster

function CharacterRoster:GetAll()
    local DP = Carbonite.Core.DataPersistence
    if DP then return DP:GetCharacters() end
    return (_G.Nx and _G.Nx.db and _G.Nx.db.global and _G.Nx.db.global.Characters) or {}
end

function CharacterRoster:Each(fn)
    for name, data in pairs(self:GetAll()) do fn(name, data) end
end

function CharacterRoster:GetCurrent()
    return _G.Nx and _G.Nx.CurCharacter
end

function CharacterRoster:GetByName(name)
    local DP = Carbonite.Core.DataPersistence
    if DP then return DP:FindCharacter(name) end
    local chars = self:GetAll()
    for key, ch in pairs(chars) do
        if key == name or (ch and ch.Name == name) then return ch, key end
    end
end

function CharacterRoster:RecalculateRealmChars()
    local Nx = _G.Nx
    if Nx and Nx.CalcRealmChars then Nx:CalcRealmChars() end
    Carbonite.Core.EventBus:Fire("ROSTER_RECALCULATED")
end

function CharacterRoster:Delete(name)
    local DP = Carbonite.Core.DataPersistence
    if DP then DP:DeleteCharacter(name) end
    Carbonite.Core.EventBus:Fire("ROSTER_CHARACTER_DELETED", name)
end

function CharacterRoster:GetRealmChars()
    local Nx = _G.Nx
    return Nx and Nx.RealmChars or {}
end

function CharacterRoster:Count()
    local n = 0
    for _ in pairs(self:GetAll()) do n = n + 1 end
    return n
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("roster", function()
        local log = Carbonite.Core.Logger:Get("CharacterRoster")
        log:info("characters tracked: %d", CharacterRoster:Count())
        CharacterRoster:Each(function(name)
            log:info("  %s", tostring(name))
        end)
    end, "list every tracked character")
end)

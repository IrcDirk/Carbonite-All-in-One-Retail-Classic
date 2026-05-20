-- Carbonite | Core / DataPersistence
-- The legacy Nx:GetData / GetDataToolBar / GetCap / GetHUDOpts /
-- CopyCharacterData / DeleteCharacterData helpers were thin
-- accessors around fields scattered across Nx.db.profile.*,
-- Nx.db.global.*, and Nx.CurCharacter.*. This module gives the
-- public surface a single home with documented scope semantics:
--
--   profile   ->  Nx.db.profile         (per-profile/account settings)
--   global    ->  Nx.db.global          (cross-character data)
--   char      ->  Nx.CurCharacter       (current-character data)
--
-- Public API:
--   DataPersistence:Get(name [, char])         -> table or nil
--   DataPersistence:GetToolBarLayout()         -> char "TBar" table
--   DataPersistence:GetHUDOptions()            -> profile.HUDOpts
--   DataPersistence:GetCapture()               -> global.Capture
--   DataPersistence:GetCharacters()            -> global.Characters
--   DataPersistence:FindCharacter(name)        -> char data or nil
--   DataPersistence:CopyCharacter(src, dst)    -> bool
--   DataPersistence:DeleteCharacter(name)
--
-- Every accessor proxies to the legacy implementation when it
-- exists so behavior matches 1:1 across the saved-variable layout
-- variations Carbonite has accumulated over the years.

local Carbonite = _G.Carbonite

local DataPersistence = {}
Carbonite.Core.DataPersistence = DataPersistence

local function nx() return _G.Nx end

-- The legacy Nx:GetData table of name -> scope mappings. We mirror
-- it here so the new module can answer the same question without
-- calling into legacy when avoidable.
local SCOPE = {
    Events    = function() return nx().CurCharacter and nx().CurCharacter.E end,
    List      = function() return nx().CurCharacter and nx().CurCharacter["L"] end,
    Quests    = function() return nx().CurCharacter and nx().CurCharacter.Q end,
    Win       = function() return nx().db and nx().db.profile and nx().db.profile.WinSettings end,
    Herb      = function() return nx().db and nx().db.profile and nx().db.profile.GatherData and nx().db.profile.GatherData.NXHerb end,
    Timber    = function() return nx().db and nx().db.profile and nx().db.profile.GatherData and nx().db.profile.GatherData.NXTimber end,
    Mine      = function() return nx().db and nx().db.profile and nx().db.profile.GatherData and nx().db.profile.GatherData.NXMine end,
}

function DataPersistence:Get(name, char)
    if not nx() then return nil end
    -- Prefer the legacy implementation because plugin code may have
    -- registered extra names via assignment we don't know about.
    if nx().GetData then return nx():GetData(name, char) end
    local fn = SCOPE[name]
    return fn and fn() or nil
end

function DataPersistence:GetToolBarLayout()
    if not nx() then return nil end
    if nx().GetDataToolBar then return nx():GetDataToolBar() end
    return nx().CurCharacter and nx().CurCharacter["TBar"]
end

function DataPersistence:GetHUDOptions()
    if not nx() then return nil end
    if nx().GetHUDOpts then return nx():GetHUDOpts() end
    return nx().db and nx().db.profile and nx().db.profile.HUDOpts
end

function DataPersistence:GetCapture()
    if not nx() then return nil end
    if nx().GetCap then return nx():GetCap() end
    return nx().db and nx().db.global and nx().db.global.Capture
end

function DataPersistence:GetCharacters()
    if not nx() then return {} end
    return (nx().db and nx().db.global and nx().db.global.Characters) or {}
end

function DataPersistence:FindCharacter(name)
    if not nx() then return nil end
    if nx().FindCharacter then return nx():FindCharacter(name) end
    local chars = self:GetCharacters()
    for key, ch in pairs(chars) do
        if key == name or (ch and ch.Name == name) then return ch, key end
    end
end

function DataPersistence:CopyCharacter(srcName, dstName)
    if not nx() or not nx().CopyCharacterData then return false end
    return nx():CopyCharacterData(srcName, dstName)
end

function DataPersistence:DeleteCharacter(name)
    if nx() and nx().DeleteCharacterData then nx():DeleteCharacterData(name) end
end

-- Slash convenience: /cb data <name> prints the data-table size.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("data", function(rest)
        local log = Carbonite.Core.Logger:Get("DataPersistence")
        local name = rest:match("^%s*(%S+)") or ""
        if name == "" then
            log:info("usage: /cb data <Events|List|Quests|Win|Herb|Timber|Mine>")
            return
        end
        local t = DataPersistence:Get(name)
        if type(t) ~= "table" then log:info("%s: %s", name, tostring(t)); return end
        local n = 0; for _ in pairs(t) do n = n + 1 end
        log:info("%s: table with %d entries", name, n)
    end, "inspect a Carbonite saved-data scope")
end)

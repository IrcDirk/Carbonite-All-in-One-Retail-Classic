-- Carbonite | Modules / DebugFlags
-- Public surface for the Carbonite debug-feature toggles. Legacy
-- code reads them as Nx.db.profile.Debug.<Name>; this class is
-- the documented accessor + a slash command that lists them all.
--
-- Known flags (declared by NxOptions defaults):
--   DBGather, DBMapMax, DBUnit, DebugCom, DebugMap, DebugDock,
--   DebugUnit, VerDebug
--
-- Public API:
--   DebugFlags:Get(name)
--   DebugFlags:Set(name, value)
--   DebugFlags:Toggle(name)
--   DebugFlags:Each(fn)
--   DebugFlags:GetKnown()       -> { name1, name2, ... }

local Carbonite = _G.Carbonite

local DebugFlags = {}
Carbonite.Modules.DebugFlags = DebugFlags

local KNOWN = {
    "DBGather", "DBMapMax", "DBUnit", "DebugCom", "DebugMap",
    "DebugDock", "DebugUnit", "VerDebug",
}

local function dbgTable()
    local Nx = _G.Nx
    return Nx and Nx.db and Nx.db.profile and Nx.db.profile.Debug
end

function DebugFlags:Get(name)
    local t = dbgTable()
    return t and t[name] == true
end

function DebugFlags:Set(name, value)
    local t = dbgTable()
    if not t then return end
    t[name] = value and true or false
    Carbonite.Core.EventBus:Fire("DEBUG_FLAG_CHANGED", name, t[name])
end

function DebugFlags:Toggle(name) self:Set(name, not self:Get(name)) end

function DebugFlags:GetKnown() return KNOWN end

function DebugFlags:Each(fn)
    for _, name in ipairs(KNOWN) do fn(name, self:Get(name)) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("flags", function(rest)
        rest = rest or ""
        local name = rest:match("^%s*(%S+)")
        local log = Carbonite.Core.Logger:Get("DebugFlags")
        if name then
            DebugFlags:Toggle(name)
            log:info("%s: %s", name, DebugFlags:Get(name) and "ON" or "OFF")
        else
            log:info("Carbonite debug flags:")
            DebugFlags:Each(function(n, v) log:info("  %s = %s", n, v and "ON" or "OFF") end)
        end
    end, "list / toggle Carbonite debug flags")
end)

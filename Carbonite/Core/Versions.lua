-- Carbonite | Core / Versions
-- Canonical home for every VERSION* constant scattered around the
-- legacy code. Carbonite uses these to detect saved-variable schema
-- bumps; whenever a stored Version is less than the constant here,
-- the corresponding subsystem resets / migrates its data.
--
-- Centralizing them lets us:
--   * see all the migration cliffs in one place
--   * version-bump a single value when introducing a migration
--   * write a generic "did this scope need to migrate?" helper
--
-- The legacy table layout (`Nx.VERMAJOR`, `Nx.VERMINOR`, `Nx.BUILD`,
-- and the `Nx.VERSION*` family) is still populated by Carbonite.lua;
-- this module reads from there and provides the structured API.

local Carbonite = _G.Carbonite

local Versions = {}
Carbonite.Core.Versions = Versions

-- Schema scope -> required version. The legacy code stored these as
-- Nx.VERSION* globals; we mirror the values here so dependent code
-- doesn't have to know the legacy field names.
local KEYS = {
    Data        = "VERSIONDATA",
    Char        = "VERSIONCHAR",
    CharData    = "VERSIONCharData",
    Gather      = "VERSIONGATHER",
    GlobalOpts  = "VERSIONGOPTS",
    HUDOpts     = "VERSIONHUDOPTS",
    List        = "VERSIONList",
    TaxiCap     = "VERSIONTaxiCap",
    Travel      = "VERSIONTRAVEL",
    Win         = "VERSIONWin",
    ToolBar     = "VERSIONTOOLBAR",
    Cap         = "VERSIONCAP",
    VendorV     = "VERSIONVENDORV",
    Transfer    = "VERSIONTransferData",
    Fav         = "VERSIONFAV",
}

function Versions:Required(scope)
    local Nx = _G.Nx
    if not Nx then return nil end
    local field = KEYS[scope]
    return field and Nx[field]
end

function Versions:GetAddonVersion()
    local Nx = _G.Nx
    if not Nx then return "?" end
    local minor = (Nx.VERMINOR or 0) * 10
    return ("%s.%s"):format(Nx.VERMAJOR or "?", minor)
end

function Versions:GetBuild()
    return _G.Nx and _G.Nx.BUILD or "0"
end

-- Returns true when `stored` (the version saved in the user's data)
-- is older than the schema-required version. Use this from migration
-- hooks: `if Versions:NeedsMigration("Win", db.Win.Version) then ...`
function Versions:NeedsMigration(scope, stored)
    local required = self:Required(scope)
    if not required then return false end
    stored = tonumber(stored) or 0
    return stored < required
end

-- Convenience: list every (scope, required) pair so the debug
-- command can dump them in one go.
function Versions:Each(fn)
    for scope in pairs(KEYS) do fn(scope, self:Required(scope)) end
end

-- Slash subcommand: /cb versions
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if Carbonite.Core.SlashCommands then
        Carbonite.Core.SlashCommands:Register("versions", function()
            local log = Carbonite.Core.Logger:Get("Versions")
            log:info("Carbonite %s (build %s)", Versions:GetAddonVersion(), Versions:GetBuild())
            Versions:Each(function(scope, ver) log:info("  %s -> %s", scope, tostring(ver)) end)
        end, "print every Carbonite schema version")
    end
end)

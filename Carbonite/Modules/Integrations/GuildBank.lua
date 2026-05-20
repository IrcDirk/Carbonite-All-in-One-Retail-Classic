-- Carbonite | Modules / Integrations / GuildBank
-- Wraps LibGuildBankComm-1.0, the library Carbonite uses for
-- cross-client guild-bank synchronization. The Warehouse plugin is
-- the primary consumer; this class is the documented entry point so
-- other plugins (Comm, Quests) can listen on the same library
-- without each calling LibStub.
--
-- Public API:
--   GuildBank:Get()                  -> the LibGuildBankComm-1.0 instance
--   GuildBank:RegisterCallback(event, fn, name)
--   GuildBank:UnregisterCallback(event, name)
--   GuildBank:IsAvailable()

local Carbonite = _G.Carbonite

local GuildBank = {}
Carbonite.Modules.Integrations = Carbonite.Modules.Integrations or {}
Carbonite.Modules.Integrations.GuildBank = GuildBank

function GuildBank:Get()
    return LibStub and LibStub("LibGuildBankComm-1.0", true) or nil
end

function GuildBank:IsAvailable()
    return self:Get() ~= nil
end

function GuildBank:RegisterCallback(event, fn, name)
    local lib = self:Get()
    if not lib then return end
    -- LibGuildBankComm exposes the CallbackHandler-1.0 surface as
    -- :RegisterCallback(target, event, methodOrFunc).
    if lib.RegisterCallback then lib:RegisterCallback(name or "carb", event, fn) end
end

function GuildBank:UnregisterCallback(event, name)
    local lib = self:Get()
    if not lib then return end
    if lib.UnregisterCallback then lib:UnregisterCallback(name or "carb", event) end
end

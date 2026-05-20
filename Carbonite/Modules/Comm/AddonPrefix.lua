-- Carbonite | Modules / Comm / AddonPrefix
-- AceComm-3.0 prefix registry. Carbonite + the sibling plugins
-- (Notes, Warehouse, Quests) all share the "carbmodule" prefix for
-- inter-plugin messaging in addition to the protocol-specific
-- "Crb" channels. This class documents that vocabulary and
-- centralizes the AceComm:RegisterComm calls.
--
-- Public API:
--   AddonPrefix:Register(prefix, owner, methodName)
--   AddonPrefix:GetKnown()             -> { "Crb", "carbmodule", ... }
--   AddonPrefix:Send(prefix, msg, channel, target)

local Carbonite = _G.Carbonite
local AddonPrefix = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.AddonPrefix = AddonPrefix

AddonPrefix.PREFIXES = {
    Crb        = "Carbonite core wire format (position / target / quest sync)",
    carbmodule = "Cross-plugin module sync (Notes, Warehouse, Quests)",
}

function AddonPrefix:GetKnown()
    local out = {}
    for k in pairs(self.PREFIXES) do out[#out + 1] = k end
    table.sort(out)
    return out
end

function AddonPrefix:Register(prefix, owner, methodName)
    if not prefix or not owner or not owner.RegisterComm then return end
    owner:RegisterComm(prefix, methodName)
    if not self.PREFIXES[prefix] then self.PREFIXES[prefix] = "(plugin registered)" end
end

function AddonPrefix:Send(prefix, msg, channel, target)
    local com = _G.Nx and _G.Nx
    if not com or not com.SendCommMessage then return end
    com:SendCommMessage(prefix, msg, channel or "PARTY", target)
end

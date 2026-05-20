-- Carbonite | Modules / AutoCompleteRealms
-- Connected-realm awareness. Modern WoW lets multiple realm names
-- share a server cluster; players can interact across all of them
-- as if they were one. Carbonite uses GetAutoCompleteRealms when
-- normalizing player names so "Foo-RealmA" and "Foo-RealmB" are
-- treated as the same person if A and B are connected.
--
-- Public API:
--   AutoCompleteRealms:Get()              -> array of realm names
--   AutoCompleteRealms:Includes(realm)
--   AutoCompleteRealms:NormalizeName(name)
--     "Foo-RealmA" -> "Foo" if RealmA is in the connected set

local Carbonite = _G.Carbonite
local AutoCompleteRealms = {}
Carbonite.Modules.AutoCompleteRealms = AutoCompleteRealms

function AutoCompleteRealms:Get()
    if _G.GetAutoCompleteRealms then return _G.GetAutoCompleteRealms() or {} end
    return {}
end

function AutoCompleteRealms:Includes(realm)
    if not realm then return false end
    for _, r in ipairs(self:Get()) do
        if r:lower() == realm:lower() then return true end
    end
    return false
end

function AutoCompleteRealms:NormalizeName(name)
    if not name then return name end
    local plain, realm = name:match("^(.-)%-(.+)$")
    if not plain then return name end
    if self:Includes(realm) then return plain end
    return name
end

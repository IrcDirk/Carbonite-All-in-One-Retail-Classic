-- Carbonite | Modules / GroupMembers
-- Cached name -> unit-id table for the current party / raid. The
-- legacy Nx.GroupMembers was rebuilt on every PARTY_MEMBERS_CHANGED
-- via Nx.OnParty_members_changed; this class is the canonical owner
-- with a clean event-driven rebuild plus a small lookup API.
--
-- The legacy global Nx.GroupMembers stays populated for any older
-- modules that still poll it (Punks was a notable reader; module is
-- now retired in favour of the Carbonite.Spy integration).
--
-- Public API:
--   GroupMembers:Refresh()              -> rebuild the cache now
--   GroupMembers:Lookup(name)           -> unit-id or nil
--   GroupMembers:Each(fn)               -> iterate (name, unit, idx)
--   GroupMembers:GetType()              -> "party" or "raid"
--   GroupMembers:Count()                -> int
--   GroupMembers:Has(name)              -> bool
--
-- Fires GROUP_MEMBERS_CHANGED on the EventBus after every rebuild.

local Carbonite = _G.Carbonite

local GroupMembers = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.GroupMembers = GroupMembers

local cache = {}                  -- name -> { unit, index, faction, class }
local groupType = "party"

local function rebuild()
    local Nx = _G.Nx

    local isRaid = _G.IsInRaid and _G.IsInRaid()
    local base = isRaid and "raid" or "party"
    local maxN = isRaid and (_G.MAX_RAID_MEMBERS or 40) or (_G.MAX_PARTY_MEMBERS or 4)
    groupType = base

    cache = {}

    for i = 1, maxN do
        local unit = base .. i
        if _G.UnitExists and _G.UnitExists(unit) then
            local name = _G.UnitName and _G.UnitName(unit)
            if name then
                local _, class = _G.UnitClass and _G.UnitClass(unit) or nil
                local faction  = _G.UnitFactionGroup and _G.UnitFactionGroup(unit)
                cache[name] = {
                    unit    = unit,
                    index   = i,
                    class   = class,
                    faction = faction,
                }
            end
        end
    end

    -- Mirror onto Nx.GroupMembers for the legacy reader.
    if Nx then
        local mirror = {}
        for n, info in pairs(cache) do mirror[n] = info.index end
        Nx.GroupMembers = mirror
        Nx.GroupType    = groupType
    end

    Carbonite.Core.EventBus:Fire("GROUP_MEMBERS_CHANGED", groupType, GroupMembers:Count())
end

function GroupMembers:Refresh() rebuild() end

function GroupMembers:Lookup(name)
    local info = cache[name]
    return info and info.unit, info and info.index
end

function GroupMembers:Has(name)
    return cache[name] ~= nil
end

function GroupMembers:Each(fn)
    for name, info in pairs(cache) do
        fn(name, info.unit, info.index, info)
    end
end

function GroupMembers:GetType() return groupType end

function GroupMembers:Count()
    local n = 0
    for _ in pairs(cache) do n = n + 1 end
    return n
end

-- Listen for roster changes. Both GROUP_ROSTER_UPDATE (modern) and
-- PARTY_MEMBERS_CHANGED (legacy Classic) trigger a rebuild.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local f = CreateFrame("Frame", "CarbGroupMembersListener")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    pcall(f.RegisterEvent, f, "PARTY_MEMBERS_CHANGED")  -- Classic-era only
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", rebuild)
    rebuild()
end)

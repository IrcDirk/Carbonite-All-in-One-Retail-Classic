-- Carbonite | Modules / CombatStats
-- Battleground combat tracking (kills / deaths / honor / damage /
-- healing). Replaces the inline Nx.Combat table and OnUpdate_battlefield_score
-- with a proper Module subclass.
--
-- Public API:
--   CombatStats:GetStats()  -> snapshot table { KBs, Deaths, HKs, Honor, DamDone, HealDone }
--   CombatStats:Reset()     -> zero out (called automatically on BG entry)
--   CombatStats:GetKBRank() -> our killing-blow rank among current BG
--
-- EventBus signals:
--   COMBAT_STATS_UPDATED   - any field changed (payload: snapshot)
--   COMBAT_STATS_RESET     - on BG entry

local Carbonite = _G.Carbonite
local Module = Carbonite.Core.Module

local CombatStats = Module:New("CombatStats", {
    defaults = {
        profile = {
            CombatStats = {
                AnnounceUpdates = true,
            },
        },
    },
})

local stats = {
    KBs      = 0,
    Deaths   = 0,
    HKs      = 0,
    Honor    = 0,
    DamDone  = 0,
    HealDone = 0,
}

-- The legacy code wrote to Nx.Combat directly; mirror to that table
-- so any reader that still looks there gets fresh values.
local function mirrorToLegacy()
    local Nx = _G.Nx
    if not Nx then return end
    Nx.Combat = Nx.Combat or {}
    for k, v in pairs(stats) do Nx.Combat[k] = v end
end

function CombatStats:GetStats()
    local snap = {}
    for k, v in pairs(stats) do snap[k] = v end
    return snap
end

function CombatStats:Reset()
    for k in pairs(stats) do stats[k] = 0 end
    mirrorToLegacy()
    Carbonite.Core.EventBus:Fire("COMBAT_STATS_RESET")
end

-- Returns the player's killing-blow rank in the current battlefield
-- (1 = best). Walks the battlefield score table.
function CombatStats:GetKBRank()
    if not _G.GetNumBattlefieldScores or not _G.GetBattlefieldScore then return 1 end
    local plName = _G.UnitName("player")
    local rank = 1
    for n = 1, _G.GetNumBattlefieldScores() do
        local name, kbs = _G.GetBattlefieldScore(n)
        if name ~= plName and (kbs or 0) > stats.KBs then rank = rank + 1 end
    end
    return rank
end

-- Pull the latest scores. Returns true if anything changed.
function CombatStats:Refresh()
    if not _G.GetNumBattlefieldScores or not _G.GetBattlefieldScore then return false end
    local plName = _G.UnitName("player")
    local changed = false

    for n = 1, _G.GetNumBattlefieldScores() do
        local name, kbs, hks, deaths, honor, _, _, _, _, damDone, healDone = _G.GetBattlefieldScore(n)
        if name == plName then
            honor = math.floor(honor or 0)    -- V4 returns weird fractions
            local any = (kbs or 0) + (deaths or 0) + (hks or 0) + honor
            if any > 0 and
               (stats.KBs ~= kbs or stats.Deaths ~= deaths or stats.HKs ~= hks or stats.Honor ~= honor) then
                stats.KBs    = kbs    or 0
                stats.Deaths = deaths or 0
                stats.HKs    = hks    or 0
                stats.Honor  = honor
                changed = true
            end
            stats.DamDone  = damDone  or 0
            stats.HealDone = healDone or 0
            break
        end
    end

    if changed then
        mirrorToLegacy()
        Carbonite.Core.EventBus:Fire("COMBAT_STATS_UPDATED", self:GetStats())
    end
    return changed
end

function CombatStats:OnEnable()
    self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE", "OnBattlefieldScore")

    -- Reset on BG entry/exit so cumulative counters don't carry over.
    Carbonite.Core.EventBus:Subscribe("BG_STATE_CHANGED", function() CombatStats:Reset() end)
end

function CombatStats:OnBattlefieldScore()
    if not self:Refresh() then return end
    local db = self:DB() and self:DB().profile or {}
    if not db.AnnounceUpdates then return end

    -- Per-message announce in the chat frame Carbonite is configured
    -- to use. We don't depend on Nx.prt anymore; use Carbonite's
    -- logger so the new color-prefix is consistent.
    local snap = self:GetStats()
    self.log:info("%d KB (#%d), %d deaths, %d HK, %d honor",
        snap.KBs, self:GetKBRank(), snap.Deaths, snap.HKs, snap.Honor)
end

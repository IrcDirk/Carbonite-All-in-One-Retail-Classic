-- Carbonite | Modules / UserEvents / EventHandlers
-- WoW-event handlers extracted from Carbonite.lua. Nx:InitEvents
-- still registers these as `Nx:RegisterEvent(WOW_EVENT, "OnX")`
-- (AceEvent dispatch), so the methods MUST stay on the Nx namespace
-- to keep resolving. Each one used to live in Carbonite.lua and
-- belongs conceptually with one of the new modules:
--
--   OnPlayer_regen_disabled / enabled    -> CombatLockdown
--   OnUnit_spellcast_sent                -> Gather/GatherEvents
--   OnZone_changed_new_area              -> ZoneTransition
--   OnPlayer_level_up                    -> UserEvents
--   OnParty_members_changed              -> PartyState
--   OnUpdate_battlefield_score           -> Map/Battleground
--
-- Bundled here for now so later commits can move them out one at a
-- time without re-touching Carbonite.lua.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-------------------------------------------------------------------------------
-- Combat lockdown
-------------------------------------------------------------------------------

--- Entering combat -> kick the window-system combat updater.
function Nx:OnPlayer_regen_disabled()
    Nx.Window:UpdateCombat()
end

--- Leaving combat -> same.
function Nx:OnPlayer_regen_enabled()
    Nx.Window:UpdateCombat()
end

-------------------------------------------------------------------------------
-- Gather detection (herb / mining / artifact / gas / logging / opening)
-------------------------------------------------------------------------------

--- UNIT_SPELLCAST_SENT for the player. Maps the spell name onto
--- one of Carbonite's gather kinds and records the node via UEvents.
--- pcall'd because Nx:IsGathering can be called before the gather
--- DB has fully initialised on a fresh install.
function Nx:OnUnit_spellcast_sent(event, arg1, arg2, arg3, arg4)
    pcall(function()
        if arg1 ~= "player" then return end
        local NxL = Nx

        if NxL:IsGathering(arg2) == L["Herb Gathering"] then
            NxL.GatherTarget = NxL.TooltipLastText
            if NxL.db.profile.Debug.DBGather then
                NxL.prt(L["Gather"] .. ": %s %s", arg2, NxL.GatherTarget or "nil")
            end
            if NxL.GatherTarget then
                NxL.UEvents:AddHerb(NxL.GatherTarget)
                NxL.GatherTarget = nil
            end

        elseif NxL:IsGathering(arg2) == L["Mining"] then
            NxL.GatherTarget = NxL.TooltipLastText
            if NxL.db.profile.Debug.DBGather then
                NxL.prt(L["Gather"] .. ": %s %s", arg2, NxL.GatherTarget)
            end
            if NxL.GatherTarget then
                NxL.UEvents:AddMine(NxL.GatherTarget)
                NxL.GatherTarget = nil
            end

        elseif arg2 == L["Searching for Artifacts"] then
            NxL.UEvents:AddOpen("Art", arg4)

        elseif arg2 == L["Extract Gas"] then
            NxL.UEvents:AddOpen("Gas", L["Extract Gas"])

        elseif arg2 == L["Logging"] then
            NxL.GatherTarget = NxL.TooltipLastText
            if NxL.GatherTarget then
                NxL.UEvents:AddTimber(NxL.GatherTarget)
                NxL.GatherTarget = nil
            end

        elseif arg2 == L["Opening"] or arg2 == L["Opening - No Text"] then
            NxL.GatherTarget = NxL.TooltipLastText
            if arg4 == L["Glowcap"] then
                NxL.UEvents:AddHerb(arg4)
            elseif arg4 == L["Everfrost Chip"] then
                NxL.UEvents:AddOpen("Everfrost", arg4)
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- Zone change
-------------------------------------------------------------------------------

--- ZONE_CHANGED_NEW_AREA: stamp an "Entered" entry into the
--- UEvents log and let Nx.Com refresh its zone-monitor state.
function Nx:OnZone_changed_new_area(event)
    Nx.UEvents:AddInfo(L["Entered"])
    Nx.Com:OnEvent(event)
end

-------------------------------------------------------------------------------
-- Player level up
-------------------------------------------------------------------------------

--- PLAYER_LEVEL_UP: log the level in UEvents and broadcast to pals.
function Nx:OnPlayer_level_up(event, arg1)
    Nx.UEvents:AddInfo(format(L["Level"] .. " %d", arg1))
    Nx.Com:OnPlayer_level_up(event, arg1)
end

-------------------------------------------------------------------------------
-- Group / raid roster
-------------------------------------------------------------------------------

--- GROUP_ROSTER_UPDATE: rebuild the name -> unit-index cache used
--- across the addon (raid frames, target tracking, etc.). Mirrors
--- to Quest if the Quests plugin is loaded.
function Nx.OnParty_members_changed()
    local self = Nx

    local members = {}
    self.GroupMembers = members

    local memberCnt = MAX_PARTY_MEMBERS
    local unitName  = "party"

    if IsInRaid() then
        memberCnt = MAX_RAID_MEMBERS
        unitName  = "raid"
    end

    self.GroupType = unitName

    for n = 1, memberCnt do
        local unit = unitName .. n
        local name = UnitName(unit)
        if name then members[name] = n end
    end

    if Nx.Quest then
        Nx.Quest.OnParty_members_changed()
    end
end

-------------------------------------------------------------------------------
-- Battleground score
-------------------------------------------------------------------------------

--- UPDATE_BATTLEFIELD_SCORE: track our own KB/Deaths/HK/Honor and
--- print a chat-line summary when stats change (gated on the
--- profile Battleground.ShowStats toggle).
function Nx:OnUpdate_battlefield_score(event)
    local plName = UnitName("player")
    local scores = GetNumBattlefieldScores()
    local cb = Nx.Combat

    local show

    for n = 1, scores do
        local name, kbs, hks, deaths, honor, _, _, _, _, damDone, healDone = GetBattlefieldScore(n)
        if name == plName then
            honor = floor(honor)    -- WoW returns odd fractions.

            local any = kbs + deaths + hks + honor

            if any > 0 and (cb.KBs ~= kbs or cb.Deaths ~= deaths or cb.HKs ~= hks or cb.Honor ~= honor) then
                cb.KBs    = kbs
                cb.Deaths = deaths
                cb.HKs    = hks
                cb.Honor  = honor
                show = true
            end

            cb.DamDone  = damDone
            cb.HealDone = healDone

            break
        end
    end

    if show and Nx.db.profile.Battleground.ShowStats then
        local kbrank = 1
        for n = 1, scores do
            local name, kbs = GetBattlefieldScore(n)
            if name ~= plName and kbs > cb.KBs then
                kbrank = kbrank + 1
            end
        end

        Nx.prt("%s KB (#%d), %s " .. L["Deaths"] .. ", %s HK, %d " .. L["Bonus"],
            cb.KBs, kbrank, cb.Deaths, cb.HKs, cb.Honor)
    end
end

-------------------------------------------------------------------------------
-- Legacy frame-event dispatcher
-------------------------------------------------------------------------------

--- The Carbonite.xml frame OnEvent script calls this; routes the
--- raw WoW event to whatever handler the legacy code registered in
--- Nx.Events (mostly set up by NxOnLoad / SetupEverything).
function Nx:NXOnEvent(event, ...)
    local h = self.Events[event]
    if h then
        h(nil, event, ...)
    else
        assert(0)
    end
end

-------------------------------------------------------------------------------
-- Player login (PLAYER_LOGIN, dispatched via AceEvent)
-------------------------------------------------------------------------------

--- Wires up the group-member cache, kicks the Com module's
--- login event, builds the post-login windows, and replaces
--- Blizzard's /played handler with a no-op so we can format the
--- response ourselves later.
function Nx:OnPlayer_login(event)
    Nx:OnParty_members_changed()
    Nx.Com:OnEvent(event)
    Nx.InitWins()

    Nx.BlizzChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed
    ChatFrame_DisplayTimePlayed = function() end

    Nx.RequestTime = true
end

-------------------------------------------------------------------------------
-- Mouseover unit (UPDATE_MOUSEOVER_UNIT)
-------------------------------------------------------------------------------

--- On every mouseover unit change: refresh the Quest tooltip (so
--- the watch-window quest text follows mouseover), and append a
--- debug "GUID player/NPC/pet" line + delegate to UnitDTip when
--- DebugUnit is on.
function Nx:OnUpdate_mouseover_unit(event)
    if Nx.Quest then
        Nx.Quest:TooltipProcess(true)
    end

    local _, guid, id, typ = Nx:UnitDGet("mouseover")
    if not guid then return end

    local tip = GameTooltip

    if typ == 0 then
        tip:AddLine(format(L["GUID player"] .. " %s", strsub(guid, 6)))
    elseif typ == 3 then
        tip:AddLine(format(L["GUID NPC"] .. " %d", id))
        Nx:UnitDTip()
    elseif typ == 4 then
        tip:AddLine(format(L["GUID pet"] .. " %s", strsub(guid, 13)))
    end

    tip:AddLine(format(" %s", guid))
    tip:Show()
end

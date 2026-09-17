-- Carbonite.Quests | Tooltips
-- Quest tooltip generation + supporting helpers. Includes the
-- Synthesize block that builds curated Nx.Quests[id] data from
-- Blizzard\'s live API when the bundled DB lacks an entry, the
-- "show quest not in DB" diagnostic, the Troll Patrol special-case,
-- and the user-facing quest hover tooltip itself.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals.
local bit_band   = bit.band
local floor      = math.floor
local strfind    = strfind  or string.find
local strsub     = strsub   or string.sub
local strlower   = strlower or string.lower
local format     = format   or string.format
local gsub       = gsub     or string.gsub
local GetTime    = GetTime
local UnitGUID   = UnitGUID

-- Promoted from NxQuest.lua.
local GetCachedDifficultyColorStr = Nx.Quest.GetCachedDifficultyColorStr

-- Check accessibility before string operations or retaining tooltip data.
-- Classic clients do not expose these APIs and keep their existing behavior.
local canaccessvalue = _G.canaccessvalue
local issecretvalue = _G.issecretvalue
local function CanUseValue(value)
    if canaccessvalue and not canaccessvalue(value) then
        return false
    end
    return not (issecretvalue and issecretvalue(value))
end

-- Return a tooltip's left text region without assuming Blizzard's global
-- GameTooltip naming. Carbonite's private tooltip uses NxTooltipTextLeftN.
local function GetTooltipLeftLine (tooltip, index)
    if not tooltip then
        return nil
    end

    local line = tooltip["TextLeft" .. index]
    if not line and tooltip.GetName then
        local name = tooltip:GetName()
        if name then
            line = _G[name .. "TextLeft" .. index]
        end
    end
    return line
end

local function NormalizeTooltipLineCount (count)
    if count < 0 then
        return 0
    end
    return floor (count)
end

-- Tooltip counts can be secret on current Retail clients. Copy only an
-- accessible count into addon execution before using it as a loop bound.
local function GetSafeTooltipLineCount (tooltip)
    if not tooltip or not tooltip.NumLines then
        return 0
    end

    local ok, count = pcall (tooltip.NumLines, tooltip)
    if not ok then
        return 0
    end

    if not CanUseValue(count) or type(count) ~= "number" then
        return 0
    end
    return NormalizeTooltipLineCount(count)
end

-------------------------------------------------------------------------------
-- Synthesize Carbonite quest data from Blizzard's live API.
--
-- Carbonite ships a bundled quest DB (Nx.Quests[questID]) with curated
-- Start/End/Objective coordinates. On retail every patch adds quests
-- the bundled DB doesn't know about, and many quests have *chained*
-- objectives (the same questID's objectives change in place as the
-- player progresses — e.g. "talk to NPC A" → "talk to NPC B"). For
-- both cases we fall back to whatever C_QuestLog.GetQuestObjectives
-- returns right now, plus the POI x/y from C_QuestLog.GetQuestsOnMap.
--
-- Two patch flag bits live in Nx.Quests[-questID]:
--   bit 1 = End was synthesized
--   bit 2 = Objectives were synthesized
-- Once bit 2 is set we always re-sync from Blizzard so chain progress
-- updates land. For pristine bundled quests we only fill in missing
-- pieces — we don't overwrite curated coordinates with Blizzard's
-- coarser POI x/y.
-------------------------------------------------------------------------------

function Nx.Quest:PatchQuestFromBlizzard (qId)
    if not qId or qId <= 0 then return false end
    if not C_QuestLog or not C_QuestLog.GetQuestObjectives then return false end

    -- Note: a previous iteration of this function aliased renumbered
    -- retail quests onto same-named bundled IDs (e.g. retail 37444
    -- "Inoculation" → TBC 9303 "Inoculation"). That misroutes
    -- tracking — the bundled coords were Outland Hellfire, the
    -- retail remake is in a different zone. The right answer is to
    -- let the patch fall through to its Blizzard-API synthesis
    -- (GetQuestsOnMap / GetNextWaypoint coords) for unknown qIds;
    -- you lose the bundled area-rect detail but tracking lands at
    -- the actual live objective.

    local objectives = C_QuestLog.GetQuestObjectives (qId)
    local lbCnt = (objectives and #objectives) or 0

    local quest = Nx.Quests[qId] or {}
    local patch = Nx.Quests[-qId] or 0
    local touched = false

    -- Pull a sanitized title up front; used in both the header line
    -- and the Start/End entries so the goto-arrow / tooltip show
    -- something meaningful instead of "?". Pipe is the field
    -- separator so we strip it from the title.
    local title = (C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID (qId)) or "?"
    title = (title or "?"):gsub("|", "")
    if title == "" then title = "?" end

    -- Header line (name|faction|level|0|0|0). Synthesize if missing.
    if not quest["Quest"] then
        local fac = UnitFactionGroup ("player") == "Horde" and 1 or 2
        local level = 0
        local qi = GetQuestLogIndexByID and GetQuestLogIndexByID (qId)
        if qi and qi > 0 then
            local _, lvl = GetQuestLogTitle (qi)
            level = lvl or 0
        end
        quest["Quest"] = format ("[[%s|%s|%s|0|0|0]]", title, fac, level)
        touched = true
    end

    -- Try to source x/y from a map Blizzard knows the quest is on.
    local mapId, x, y
    local function tryMap (m)
        if mapId or not m then return end
        local mq = C_QuestLog.GetQuestsOnMap and C_QuestLog.GetQuestsOnMap (m)
        if not mq then return end
        for _, e in ipairs (mq) do
            if e.questID == qId and e.x and e.y then
                mapId, x, y = m, e.x * 100, e.y * 100
                return
            end
        end
    end
    if C_TaskQuest and C_TaskQuest.GetQuestZoneID then
        tryMap (C_TaskQuest.GetQuestZoneID (qId))
    end
    if Nx.Map and Nx.Map.GetCurrentMapId then
        tryMap (Nx.Map:GetCurrentMapId ())
    end

    if lbCnt > 0 then
        -- For each Blizzard objective:
        --   * If our static DB has POIs for this slot already, *rename* them
        --     in place — replace the leading desc field with the live text
        --     so tooltips / watch list show the real objective text instead
        --     of "nil". Don't append a new POI; that would render a ghost
        --     icon next to the real ones.
        --   * If the slot is empty AND we never had any objective data at
        --     all (quest was missing from our DB entirely), write a single
        --     Blizzard-derived POI so the watch list still shows something.
        --   * If our DB had any objectives (even partial), preserve its
        --     structure — don't synthesize over curated data like quest
        --     10302's many-area-rect objective which would otherwise be
        --     reduced to a single type-32 point.
        local hadObjectives = quest["Objectives"] ~= nil
        if not quest["Objectives"] then
            quest["Objectives"] = {}
        end
        for i = 1, lbCnt do
            local objText = (objectives[i] and objectives[i].text) or "?"
            objText = (objText:gsub("|", ""))  -- strip pipes from desc
            local slot = quest["Objectives"][i]
            if not slot then
                if not hadObjectives then
                    local obj
                    if mapId and x and y then
                        obj = format ("%s|%s|32|%f|%f|6|6", objText, mapId, x, y)
                    else
                        -- Best-effort: text-only entry with sentinel zone 0.
                        -- Watch list shows it; map can't pin it until we get
                        -- coords on a later QUEST_POI_UPDATE.
                        obj = format ("%s|0|32|0|0|6|6", objText)
                    end
                    quest["Objectives"][i] = { obj }
                    touched = true
                end
                -- else: bundled quest had partial objectives; respect
                -- the curated DB and skip synthesizing.
            else
                for j, poi in ipairs (slot) do
                    if type(poi) == "string" then
                        local rest = poi:match("^[^|]*(|.*)$")
                        if rest then
                            local renamed = objText .. rest
                            if renamed ~= poi then
                                slot[j] = renamed
                                touched = true
                            end
                        end
                    end
                end
            end
        end
        patch = bit.bor (patch, 2)
    end

    -- Resolve End coords with this priority chain:
    --   1. Bundled End that's close to Blizzard's live POI → keep ours
    --      (curated coordinates, often more precise than POI).
    --   2. Bundled End that's far from Blizzard's POI → switch to live
    --      (DB is stale or quest content changed; Blizz is current).
    --   3. No bundled End but live POI available → synthesize from live.
    --   4. No bundled End and no live POI → leave alone; UpdateIcons
    --      falls back to quest["Start"] downstream.
    --
    -- Case 2 is also what catches "complete quest icon parking at the
    -- in-progress objective spot": when a quest goes Complete, Blizz's
    -- POI moves to the turn-in NPC; if our cached End is still at the
    -- kill zone we'll be far from POI and switch.
    local previouslyPatchedEnd = bit_band(patch, 1) ~= 0
    local liveOK = mapId and x and y

    if liveOK then
        local _, ourMap, _, ourX, ourY = self:UnpackSE(quest["End"])
        local distance = math.huge
        if ourMap and ourX and ourY and ourMap == mapId then
            local dx, dy = ourX - x, ourY - y
            distance = math.sqrt(dx * dx + dy * dy)
        end
        -- Threshold tuned for Carbonite's 0..100 zone-percent scale: 8
        -- units ~= 8% of map dimension, generous enough to keep
        -- bundled coords for most curated entries but tight enough to
        -- catch the start-vs-turn-in NPC mismatch case.
        local farFromLive = distance > 8

        if not quest["End"] then
            -- No End yet: take whatever Blizzard has.
            quest["End"] = format("%s|%s|32|%f|%f", title, mapId, x, y)
            patch = bit.bor(patch, 1)
            touched = true
        elseif previouslyPatchedEnd then
            -- We own this entry: refresh to current live coords so the
            -- complete-state turn-in POI propagates.
            quest["End"] = format("%s|%s|32|%f|%f", title, mapId, x, y)
            patch = bit.bor(patch, 1)
            touched = true
        elseif farFromLive then
            -- Bundled entry exists but is far from Blizzard's POI;
            -- bundled DB is stale. Switch to live and flag as patched
            -- so future refreshes follow Blizzard.
            quest["End"] = format("%s|%s|32|%f|%f", title, mapId, x, y)
            patch = bit.bor(patch, 1)
            touched = true
        end
    end

    if touched then
        Nx.Quests[qId] = quest
        Nx.Quests[-qId] = patch
    end
    return touched
end

-------------------------------------------------------------------------------
-- Show quest is not in DB
-------------------------------------------------------------------------------

function Nx.Quest:MsgNotInDB (typ)

    if typ == "O" then
        UIErrorsFrame:AddMessage (L["This objective is not in the database"], 1, 0, 0, 1)
    elseif typ == "Z" then
        UIErrorsFrame:AddMessage (L["This objective zone is not in the database"], 1, 0, 0, 1)
    else
        UIErrorsFrame:AddMessage (L["This quest is not in the database"], 1, 0, 0, 1)
    end
end

-------------------------------------------------------------------------------

-- Troll Patrol: The Alchemist's Apprentice quest

Nx.Quest.AlchemistsApprenticeData = {

    ["Abomination Guts"] = "3~4~3492~5283",
    ["Amberseed"] = "3~3~3496~5157",
    ["Ancient Ectoplasm"] = "3~2~3498~5157",
    ["Blight Crystal"] = "3~2~3488~5347",
    ["Chilled Serpent Mucus"] = "3~3~3509~5342",
    ["Crushed Basilisk Crystals"] = "4~2~3487~5339",
    ["Crystallized Hogsnot"] = "3~4~3494~5157",
    ["Frozen Spider Ichor"] = "3~2~3472~5309",
    ["Ghoul Drool"] = "4~     4~3490~5100",
    ["Hairy Herring Head"] = "Floor~Crate~3511~5127",
    ["Icecrown Bottled Water"] = "2~1~3499~5157",
    ["Knotroot"] = "4~1~3499~5152",
    ["Muddy Mire Maggots"] = "Floor~Sack~3485~5155",
    ["Pickled Eagle Egg"] = "2~2~3497~5157",
    ["Prismatic Mojo"] = "4~3~3491~5289",
    ["Pulverized Gargoyle Teeth"] = "2~4~3494~5157",
    ["Putrid Pirate Perspiration"] = "2~3~3496~5157",
    ["Raptor Claw"] = "3~2~3489~5283",
    ["Seasoned Slider Cider"] = "Floor~Barrel~3508~5317",
    ["Shrunken Dragon's Claw"] = "3~3~3489~5093",
    ["Speckled Guano"] = "2~3~3490~5093",
    ["Spiky Spider Egg"] = "3~4~3510~5095",
    ["Trollbane"] = "3~1~     3505~5095",
    ["Wasp's Wings"] = "3~1~3499~5157",
    ["Withered Batwing"] = "4~3~3496~5153",
}

function CarboniteQuest:OnChat_msg_raid_boss_whisper (event, arg1)

    if arg1 then

        if GetMinimapZoneText() == "Heb'Valok" then

            local self = Nx.Quest    -- Need?
--            Nx.prt ("%s, %s, %s", arg1, arg2 or "nil", arg3 or "nil")

            local name = gsub (arg1, "!", "")

            local data = self.AlchemistsApprenticeData[name]
            if data then
                local shelf, item, x, y = Nx.Split ("~", data)
                x = tonumber (x) * .01
                y = tonumber (y) * .01

                local s = format (L["%s on %s in %s"], name, shelf, item)

                if tonumber (shelf) then
                    s = format (L["%s, shelf %s, item %s"], name, shelf, item)
                end

                self.Map:SetTargetXY (4011, x, y, s)
            end
        end
    end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Quest tooltips
-------------------------------------------------------------------------------

local function GetQuestTooltipFrame()
    local tip = _G.NxQuestTooltipText
    if tip then
        return tip
    end

    tip = CreateFrame("GameTooltip", "NxQuestTooltipText", UIParent, "GameTooltipTemplate")
    tip:SetFrameStrata("TOOLTIP")
    tip:SetScript("OnUpdate", function(self)
        local source = self.NxSourceTooltip
        if not source then
            self:Hide()
            return
        end
        local shown = source:IsShown()
        if not CanUseValue(shown) or not shown then
            self:Hide()
            self.NxSourceTooltip = nil
        end
    end)
    _G.NxQuestTooltipText = tip
    return tip
end

local function PrepareQuestTooltipFrame(sourceTip)
    local tip = GetQuestTooltipFrame()
    tip:Hide()
    tip:ClearLines()
    -- Never own or anchor an addon frame to Blizzard's GameTooltip on Retail.
    -- The reverse anchor dependency taints its UIWidget layout state and makes
    -- GetNumPoints/GetSize return secret values during AreaPOI cleanup.
    tip:SetOwner(UIParent, "ANCHOR_CURSOR")
    tip.NxSourceTooltip = sourceTip
    return tip
end

function    Nx.Quest.TooltipHook()

    --Nx.prt ("TooltipHook")

    Nx.Quest:TooltipProcess()
end

function    Nx.Quest:TooltipProcess (stripColor, sourceTooltip)

    if InCombatLockdown() then
        return
    end

    local sourceTip = sourceTooltip or GameTooltip
    if not sourceTip then
        return
    end

    -- Blizzard's shared tooltip is read-only to Carbonite on Retail. Carbonite
    -- UI can pass Nx.TooltipText explicitly and safely render into that frame.
    local usePrivateTip = Nx.isRetail and sourceTip == GameTooltip
    local firstLine = GetTooltipLeftLine (sourceTip, 1)
    local tipStr = firstLine and firstLine:GetText()
    if not CanUseValue(tipStr) then
        Nx.TooltipLastDiffText = nil
        Nx.TooltipLastDiffNumLines = 0
        if usePrivateTip and _G.NxQuestTooltipText then
            _G.NxQuestTooltipText:Hide()
            _G.NxQuestTooltipText.NxSourceTooltip = nil
        end
        return
    end

    Nx.TooltipLastDiffText = tipStr
    local outputTip = usePrivateTip and PrepareQuestTooltipFrame(sourceTip) or sourceTip
    local show = Nx.Quest:TooltipProcess2(stripColor, tipStr, outputTip, sourceTip)

    if usePrivateTip then
        if show then
            outputTip:Show()
        else
            outputTip:Hide()
        end
    elseif show then
        sourceTip:Show()
    end

    Nx.TooltipLastDiffNumLines = GetSafeTooltipLineCount (sourceTip)
end

function Nx.Quest:TooltipProcess2 (stripColor, tipStr, outputTip, sourceTip)

    if not Nx.QInit then
        return
    end
    if not Nx.qdb.profile.Quest.AddTooltip or not CanUseValue(tipStr) then
        return
    end

    local tip = outputTip or GameTooltip
    local source = sourceTip or GameTooltip

    -- Check if already added
    local questStr = format (L["|cffffffffQ%suest:"], Nx.TXTBLUE)

    for n = 2, GetSafeTooltipLineCount (source) do
        local textLine = GetTooltipLeftLine (source, n)
        local s = textLine and textLine:GetText()
        if CanUseValue(s) and s then
            if strfind(s, questStr) then
                return
            end
            if strsub(s, 1, 3) == " - " then    -- Blizz added quest info?

                local fstr = GetTooltipLeftLine (source, n - 1)
                local qTitle = fstr and fstr:GetText()

                local i, cur
                if CanUseValue(qTitle) and qTitle then
                    i, cur = self:FindCur (qTitle)
                end
                if cur then
                    local color = GetCachedDifficultyColorStr(cur.Level)
                    local line = format ("%s %s%d %s", questStr, color, cur.Level, cur.Title)
                    if tip == source then
                        if fstr then
                            fstr:SetText (line)
                        end
                        tip:AddLine (" ")
                    else
                        tip:AddLine (line)
                    end
                    return true
                end

                if tip == source then
                    tip:AddLine (" ")        -- Preserve legacy Classic behavior
                    return true
                end
                return
            end
        end
    end

    if tipStr and #tipStr >= 5 and #tipStr < 100 and not self.TTIgnore[tipStr] then
        tipStr = self.TTChange[tipStr] or tipStr
        local tipStrLower = strlower (tipStr)

        local curq = self.CurQ
        local unitName, unit = source:GetUnit()
        local tipAddSuccess = false
        -- Check if our tooltip is on a unit first
        if CanUseValue(unit) and unit then
            local rawGuid = UnitGUID(unit)
            local npcID
            if CanUseValue(rawGuid) and rawGuid then
                local _, _2, _3, _4, _5, parsedID = strsplit('-', rawGuid)
                npcID = parsedID
            end
            local unitQuests = Nx.Units2Quests[tonumber(npcID)]
            if npcID and unitQuests then
                local npcQuests = {Nx.Split('|', unitQuests)};
                for k, str in ipairs (npcQuests) do
                    local id, objn = Nx.Split(',', str)
                    id = tonumber(id)
                    objn = tonumber(objn)
                    local i, cur = self:FindCur (id)
                    if cur then
                        local color = GetCachedDifficultyColorStr(cur.Level)
                        tip:AddLine (format ("%s %s%d %s", questStr, color, cur.Level, cur.Title))
                        tipAddSuccess = true
                        if cur[objn] then
                            local oName, oCount = Nx.Split(':', cur[objn]);
                            if oName and oCount then
                                tip:AddLine (format ("    |cffb0b0b0%s:%s%s", oName, color, oCount))
                            else
                                tip:AddLine (format ("    %s%s", color, cur[objn]))
                            end
                        end
                    end
                end
            end
        end
        if not tipAddSuccess then
            -- Iterate over our current quests to find matches for item objectives
            for curi, cur in ipairs (curq) do

                if not cur.Goto then        -- Skip Goto and Party quests

                    local s1 = strfind (cur.ObjText, tipStr, 1, true)
                    if not s1 then
                        s1 = strfind (cur.DescText, tipStr, 1, true)
                    end
                    if not s1 then
                        s1 = strfind (cur.ObjText, tipStrLower, 1, true)
                    end
                    if not s1 then
                        s1 = strfind (cur.DescText, tipStrLower, 1, true)
                    end
                    if not s1 then
                        for n = 1, cur.LBCnt do
                            if cur[n] then    -- V4
                                s1 = strfind (cur[n], tipStr)
                                if s1 then
                                    break
                                end
                            end
                        end
                    end

                    if s1 then
                        local color = GetCachedDifficultyColorStr(cur.Level)

                        tip:AddLine (format ("%s %s%d %s", questStr, color, cur.Level, cur.Title))
                        tipAddSuccess = true

                        for n = 1, cur.LBCnt do
                            if strfind (cur[n], tipStr) then
                                local color, s1 = self:CalcPercentColor (cur[n], cur[n + 100])
                                if s1 then
                                    local oName = strsub (cur[n], 1, s1 - 1)
                                    tip:AddLine (format ("    |cffb0b0b0%s%s%s", oName, color, strsub (cur[n], s1)))
                                else
                                    tip:AddLine (format ("    %s%s", color, cur[n]))
                                end
                            end
                        end
    --                    Nx.prt ("TTProcess %s #%s", tipStr, tip:NumLines())
                    end
                end
            end
        end
        
        -- Return true if we added quest info so the tooltip gets resized
        if tipAddSuccess then
            return true
        end
    end
end

-------------------------------------------------------------------------------

function Nx.Quest:GetDifficultyColor (level)

    return GetQuestDifficultyColor (level)
end

function Nx.Quest:CalcPercentColor (desc, done)

    local s1, _, i, total = strfind (desc, "(%d+)/(%d+)")

    if done then
        return self.PerColors[9], s1
    else
        i = s1 and floor (tonumber (i) / tonumber (total) * 8.99) + 1 or 1
        return self.PerColors[i], s1
    end
end

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

-- Carbonite | Modules / MainUpdater / NXOnUpdate
-- The legacy per-frame OnUpdate handler from Carbonite.lua.
-- Drives the addon's core tick: post-load init kick, the gossip
-- auto-clicker for the /carb loot debug toggle, Nx.Proc, the
-- GameTooltip-text taint-safe scanner, Nx.Com / Nx.Map / Nx.Quest
-- per-frame work, periodic character-record save, and the one-shot
-- "Whats New!" menu append. Carbonite.xml's NxFrame OnUpdate
-- script calls Nx:NXOnUpdate(elapsed) by name.
--
-- The file-scope `_tt_lenOf` / `_tt_neq` helpers exist to keep the
-- pcall guard around GameTooltip text reads (which can return
-- secure-tainted strings that raise on `#s` or `s ~= other`) while
-- only allocating the wrapper functions once at load time --
-- previous inline closure form leaked one allocation per frame.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

local function _tt_lenOf(s) return #s end
local function _tt_neq(a, b) return a ~= b end

---
-- Main frame update handler
-- Processes tooltips, network updates, and calls module updates
-- @param elapsed  Time since last frame
--
function Nx:NXOnUpdate (elapsed)
    if InCombatLockdown() and not Nx.Initialized and not Nx.CombatMessage then
        Nx.prt("You are in combat! Carbonite will resume loading when your safe.")
        Nx.CombatMessage = true
    end
    local Nx = Nx

    if Nx.Loaded and Nx.PlayerFnd and not Nx.Initialized and not InCombatLockdown() then    -- Safety check
        Nx:SetupEverything()
        return
    end
    if not Nx.Loaded or not Nx.PlayerFnd or not Nx.Initialized then
        return
    end
    Nx.Tick = Nx.Tick + 1
    if Nx.LootOn then
        Nx:LootIt()
    end

    Nx.Proc:OnUpdate (elapsed)

    -- Tooltip stuff

    if not GameTooltip:IsVisible() then
        Nx.TooltipLastDiffText = nil
    end

    -- Where TooltipDataProcessor exists (retail and every Classic flavor except
    -- Classic Era), it delivers tooltip updates without tainting GameTooltip;
    -- the polling fallback below writes to GameTooltip from an OnUpdate path
    -- and would re-introduce the taint.
    if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall) then
        local s = GameTooltipTextLeft1:GetText()
        if s and type(s) == "string" then
            -- pcall through the file-scope _tt_lenOf / _tt_neq helpers
            -- to defend against secure-tainted GameTooltip strings
            -- (`#s` and `s ~= other` both raise on tainted values).
            -- The previous code inlined `function() ... end` closures
            -- here; that allocated a closure every frame and was a
            -- significant contributor to the per-frame leak. Hoisted
            -- helpers keep the guard with zero per-frame allocation.
            local ok, slen = pcall(_tt_lenOf, s)
            if not ok then slen = 0 end
            if Nx.Tick % 4 == 1 and GameTooltipTextLeft1:IsVisible() and slen > 5 then
                local okEq, textDiff = pcall(_tt_neq, Nx.TooltipLastDiffText, s)
                if not okEq then textDiff = true end
                if textDiff or Nx.TooltipLastDiffNumLines ~= GameTooltip:NumLines() then
                    if Nx.Quest then
                        Nx.Quest:TooltipProcess()
                    end
                end
            end
            Nx.TooltipLastText = s
        end
    end

    if Nx.TooltipOwner then
        if not Nx.TooltipOwner:IsVisible() then
            if Nx.TooltipText:IsOwned (Nx.TooltipOwner) then
                Nx.TooltipText:Hide()
            end
            Nx.TooltipOwner = nil
        end
    end

    --

    if self.NetSendPos then

        local t = GetTime()

        if t > self.NetPlyrSendTime then

            local plX, plY = Nx.Map.GetPlayerMapPosition ("player")

            if plX > 0 or plY > 0 then

                local s = format ("Map~%d~%d~%d", plX * 100000000, plY * 100000000, Nx.Map:GetCurrentMapId())
                Nx.prt ("NetSend %s", s)
                Nx.Com:Send ("Z", s)

                self.NetPlyrSendTime = t + 1.5
            end
        end
    end

    local combat = UnitAffectingCombat ("player")
    if Nx.InCombat ~= combat then

        Nx.InCombat = combat
    end

    Nx.Com:OnUpdate (elapsed)
    Nx.Map:MainOnUpdate (elapsed)

    if Nx.Quest then
        Nx.Quest:OnUpdate (elapsed)
    end

    if Nx.Tick % 11 == 0 then
        Nx:RecordCharacter()
        if Nx.Warehouse then
            Nx.Warehouse:RecordCharacter()
        end
    end

    if not Nx.Whatsnew.HasWhatsNew then -- Adding it here to be at bottom of menu always.
        Nx.Whatsnew.HasWhatsNew = true
        Nx.NXMiniMapBut.Menu:AddItem(0,"")
        local function func ()
            Nx.Whatsnew:ToggleShow()
        end
        Nx.NXMiniMapBut.Menu:AddItem(0, L["Whats New!"], func, Nx.NXMiniMapBut)

        -- Auto-open the What's New window on login / reload while there
        -- is an undismissed changelog. The window keeps popping until the
        -- player clicks "Don't show this update again" (which pins
        -- lastreadtime to the newest entry); a newer entry re-arms it.
        -- Closing with the X does not dismiss, so it reappears next login.
        local function showWhatsNew()
            if Nx.Whatsnew and Nx.Whatsnew.DismissedCurrent and not Nx.Whatsnew:DismissedCurrent()
                and Nx.Whatsnew.ToggleShow
                and not (Nx.Whatsnew.Win and Nx.Whatsnew.Win:IsShown()) then
                Nx.Whatsnew:ToggleShow()
            end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(1, showWhatsNew)
        else
            showWhatsNew()
        end
    end

end

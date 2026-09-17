-- Carbonite | Modules / InitFlow / EventRegistration
-- AceEvent-3.0 embedding + WoW event registration for all the
-- subsystems that the legacy code drives via OnX handlers (Nx,
-- Nx.Com, Nx.Map.Guide, Nx.AuctionAssist, Nx.Travel). Lifted out
-- of Carbonite.lua's InitEvents; SetupEverything still calls
-- Nx:InitEvents() during PLAYER_LOGIN.

---
-- Guarded event registration.
--
-- The 12.0 engine ships one UI codebase for every flavor, so an event's
-- existence no longer follows from the expansion. Forever ("camelot") reports
-- TOC 16001, which reads as pre-BFA in every Nx.*Maps flag, yet it runs the
-- modern auction house and therefore has no AUCTION_ITEM_LIST_UPDATE at all.
-- AceEvent turns an unknown event into a hard error, and because all of
-- InitEvents is one call that error aborted the run - every registration after
-- the failing line silently never happened. Validate first (C_EventUtils knows
-- the client's real event list), fall back to pcall on clients without it, and
-- never let one missing event take the rest down.
local skippedEvents = {}

local function safeRegister(target, event, handler)
    if not target or not target.RegisterEvent then
        return false
    end

    local valid = true
    if C_EventUtils and C_EventUtils.IsEventValid then
        local ok, result = pcall(C_EventUtils.IsEventValid, event)
        valid = not ok or result ~= false
    end

    if valid then
        local ok = pcall(target.RegisterEvent, target, event, handler)
        if ok then
            return true
        end
    end

    skippedEvents[#skippedEvents + 1] = event
    return false
end

---
-- Register all addon events
-- Uses Ace3 event system for various game events
--
function Nx:InitEvents()

    local Com = Nx.Com
    local Guide = Nx.Map.Guide
    local AuctionAssist = Nx.AuctionAssist
    local Travel = Nx.Travel

    LibStub("AceEvent-3.0"):Embed(Com)
    LibStub("AceEvent-3.0"):Embed(Guide)
    LibStub("AceEvent-3.0"):Embed(AuctionAssist)
    LibStub("AceEvent-3.0"):Embed(Travel)

    ---------------------------------------------------------------------------
    -- Core Events (all versions)
    ---------------------------------------------------------------------------
    safeRegister(Nx, "PLAYER_LOGIN", "OnPlayer_login")
    safeRegister(Nx, "UPDATE_MOUSEOVER_UNIT", "OnUpdate_mouseover_unit")
    safeRegister(Nx, "PLAYER_REGEN_DISABLED", "OnPlayer_regen_disabled")
    safeRegister(Nx, "PLAYER_REGEN_ENABLED", "OnPlayer_regen_enabled")
    safeRegister(Nx, "ZONE_CHANGED_NEW_AREA", "OnZone_changed_new_area")
    safeRegister(Nx, "PLAYER_LEVEL_UP", "OnPlayer_level_up")
    safeRegister(Nx, "GROUP_ROSTER_UPDATE", "OnParty_members_changed")
    safeRegister(Nx, "UPDATE_BATTLEFIELD_SCORE", "OnUpdate_battlefield_score")

    ---------------------------------------------------------------------------
    -- Communication Events
    ---------------------------------------------------------------------------
    safeRegister(Com, "PLAYER_LEAVING_WORLD", "OnEvent")
    safeRegister(Com, "FRIENDLIST_UPDATE", "OnFriendguild_update")
    safeRegister(Com, "GUILD_ROSTER_UPDATE", "OnFriendguild_update")
    safeRegister(Com, "BN_FRIEND_LIST_SIZE_CHANGED", "OnFriendguild_update")
    safeRegister(Com, "GROUP_ROSTER_UPDATE", "OnFriendguild_update")
    safeRegister(Com, "CHAT_MSG_CHANNEL_JOIN", "OnChatEvent")
    safeRegister(Com, "CHAT_MSG_CHANNEL_NOTICE", "OnChatEvent")
    safeRegister(Com, "CHAT_MSG_CHANNEL_LEAVE", "OnChatEvent")
    safeRegister(Com, "CHAT_MSG_CHANNEL", "OnChat_msg_channel")
    -- Retail 12.1 can deliver CHAT_MSG_SYSTEM text as a secret string. The
    -- unavailable-whisper parser is optional social-cache cleanup and must not
    -- receive that protected payload on Mainline. Classic clients retain the
    -- legacy accessible system-message path.
    if not Nx.isRetail then
        safeRegister(Com, "CHAT_MSG_SYSTEM", "OnChat_msg_channel")
    end

    -- SOCIAL_QUEUE_UPDATE: Available from Legion+ (group finder social queues)
    if Nx.LegionMaps then
        safeRegister(Com, "SOCIAL_QUEUE_UPDATE", "OnFriendguild_update")
    end

    ---------------------------------------------------------------------------
    -- Auction House Events (API changed in BFA 8.3)
    ---------------------------------------------------------------------------
    safeRegister(AuctionAssist, "AUCTION_HOUSE_SHOW", "OnAuction_house_show")
    safeRegister(AuctionAssist, "AUCTION_HOUSE_CLOSED", "OnAuction_house_closed")

    -- REPLICATE_ITEM_LIST_UPDATE is the post-8.3 auction API, and
    -- AUCTION_ITEM_LIST_UPDATE the pre-BFA one. Which exists is a property of
    -- the client's auction house, not of its TOC version: Forever numbers
    -- itself 1.60.1 but ships the modern AH. Ask for the modern event first
    -- and only fall back when this client really has the legacy one.
    if not safeRegister(AuctionAssist, "REPLICATE_ITEM_LIST_UPDATE",
            "OnAuction_item_list_update") then
        safeRegister(AuctionAssist, "AUCTION_ITEM_LIST_UPDATE",
            "OnAuction_item_list_update")
    end

    ---------------------------------------------------------------------------
    -- Guide Events (all versions)
    ---------------------------------------------------------------------------
    safeRegister(Guide, "MERCHANT_SHOW", "OnMerchant_show")
    safeRegister(Guide, "MERCHANT_UPDATE", "OnMerchant_update")
    safeRegister(Guide, "GOSSIP_SHOW", "OnGossip_show")
    safeRegister(Guide, "TRAINER_SHOW", "OnTrainer_show")

    ---------------------------------------------------------------------------
    -- Travel Events (all versions)
    ---------------------------------------------------------------------------
    safeRegister(Travel, "TAXIMAP_OPENED", "OnTaximap_opened")

    ---------------------------------------------------------------------------
    -- Spellcast (player) via a dedicated unit-filtered frame, NOT AceEvent.
    ---------------------------------------------------------------------------
    -- AceEvent funnels every event onto one shared frame registered with the
    -- unfiltered RegisterEvent. That frame sits in the same global secure-
    -- dispatch list as Blizzard's CastingBarFrame / action buttons, so when a
    -- UNIT_SPELLCAST_SENT fires Carbonite's taint can leak onto that secure
    -- code. In instances arg2 (the spell name) is also handed back as a
    -- "secret" value; comparing it (OnUnit_spellcast_sent) from the shared
    -- dispatch is what poisons e.g. ActionButton_ApplyCooldown -> SetCooldown
    -- ("Secret values are only allowed during untainted execution") and
    -- freezes action-bar cooldown swipes. RegisterUnitEvent scoped to "player"
    -- routes us through the filtered-event path, which dispatches separately
    -- and keeps our taint off the secure frames. The handler already bails on
    -- arg1 ~= "player", so behaviour is unchanged. Same remediation as the
    -- CarboniteWarehouse SpellcastFrame (see Carbonite.Warehouse/Init.lua).
    if not Nx.SpellcastSentFrame then
        local f = CreateFrame("Frame", "CarboniteSpellcastSentFrame")
        f:SetScript("OnEvent", function (_, event, ...)
            Nx:OnUnit_spellcast_sent(event, ...)
        end)
        -- On TBC/Classic UNIT_SPELLCAST_SENT is not a "unit event" in the C
        -- engine, so RegisterUnitEvent throws ("unknown event"). A dedicated
        -- frame already isolates us from AceEvent's shared dispatch (the taint
        -- source), and Classic has no "secret values", so falling back to a
        -- plain RegisterEvent on this frame is safe. The handler still bails on
        -- arg1 ~= "player", so behaviour is unchanged.
        local ok = pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_SENT", "player")
        if not ok then
            pcall(f.RegisterEvent, f, "UNIT_SPELLCAST_SENT")
        end
        Nx.SpellcastSentFrame = f
    end

    -- One line per session, so a flavor that lacks an event is visible in the
    -- log instead of being guessed at from missing behaviour.
    if #skippedEvents > 0 and Carbonite and Carbonite.Core
            and Carbonite.Core.Logger then
        Carbonite.Core.Logger:Get("InitFlow"):info(
            "events not available on this client, skipped: %s",
            table.concat(skippedEvents, ", "))
    end
end

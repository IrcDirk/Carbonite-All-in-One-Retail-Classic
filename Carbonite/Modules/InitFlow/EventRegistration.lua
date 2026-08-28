-- Carbonite | Modules / InitFlow / EventRegistration
-- AceEvent-3.0 embedding + WoW event registration for all the
-- subsystems that the legacy code drives via OnX handlers (Nx,
-- Nx.Com, Nx.Map.Guide, Nx.AuctionAssist, Nx.Travel). Lifted out
-- of Carbonite.lua's InitEvents; SetupEverything still calls
-- Nx:InitEvents() during PLAYER_LOGIN.

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
    Nx:RegisterEvent("PLAYER_LOGIN", "OnPlayer_login")
    Nx:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "OnUpdate_mouseover_unit")
    Nx:RegisterEvent("PLAYER_REGEN_DISABLED", "OnPlayer_regen_disabled")
    Nx:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayer_regen_enabled")
    Nx:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZone_changed_new_area")
    Nx:RegisterEvent("PLAYER_LEVEL_UP", "OnPlayer_level_up")
    Nx:RegisterEvent("GROUP_ROSTER_UPDATE", "OnParty_members_changed")
    Nx:RegisterEvent("UPDATE_BATTLEFIELD_SCORE", "OnUpdate_battlefield_score")

    ---------------------------------------------------------------------------
    -- Communication Events
    ---------------------------------------------------------------------------
    Com:RegisterEvent("PLAYER_LEAVING_WORLD", "OnEvent")
    Com:RegisterEvent("FRIENDLIST_UPDATE", "OnFriendguild_update")
    Com:RegisterEvent("GUILD_ROSTER_UPDATE", "OnFriendguild_update")
    Com:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED", "OnFriendguild_update")
    Com:RegisterEvent("GROUP_ROSTER_UPDATE", "OnFriendguild_update")
    Com:RegisterEvent("CHAT_MSG_CHANNEL_JOIN", "OnChatEvent")
    Com:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE", "OnChatEvent")
    Com:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE", "OnChatEvent")
    Com:RegisterEvent("CHAT_MSG_CHANNEL", "OnChat_msg_channel")
    -- Retail 12.1 can deliver CHAT_MSG_SYSTEM text as a secret string. The
    -- unavailable-whisper parser is optional social-cache cleanup and must not
    -- receive that protected payload on Mainline. Classic clients retain the
    -- legacy accessible system-message path.
    if not Nx.isRetail then
        Com:RegisterEvent("CHAT_MSG_SYSTEM", "OnChat_msg_channel")
    end

    -- SOCIAL_QUEUE_UPDATE: Available from Legion+ (group finder social queues)
    if Nx.LegionMaps then
        Com:RegisterEvent("SOCIAL_QUEUE_UPDATE", "OnFriendguild_update")
    end

    ---------------------------------------------------------------------------
    -- Auction House Events (API changed in BFA 8.3)
    ---------------------------------------------------------------------------
    AuctionAssist:RegisterEvent("AUCTION_HOUSE_SHOW", "OnAuction_house_show")
    AuctionAssist:RegisterEvent("AUCTION_HOUSE_CLOSED", "OnAuction_house_closed")

    -- REPLICATE_ITEM_LIST_UPDATE: New auction house API (BFA 8.3+)
    -- AUCTION_ITEM_LIST_UPDATE: Classic auction house API (pre-BFA)
    if Nx.BFAMaps then
        AuctionAssist:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE", "OnAuction_item_list_update")
    else
        AuctionAssist:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", "OnAuction_item_list_update")
    end

    ---------------------------------------------------------------------------
    -- Guide Events (all versions)
    ---------------------------------------------------------------------------
    Guide:RegisterEvent("MERCHANT_SHOW", "OnMerchant_show")
    Guide:RegisterEvent("MERCHANT_UPDATE", "OnMerchant_update")
    Guide:RegisterEvent("GOSSIP_SHOW", "OnGossip_show")
    Guide:RegisterEvent("TRAINER_SHOW", "OnTrainer_show")

    ---------------------------------------------------------------------------
    -- Travel Events (all versions)
    ---------------------------------------------------------------------------
    Travel:RegisterEvent("TAXIMAP_OPENED", "OnTaximap_opened")

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
            f:RegisterEvent("UNIT_SPELLCAST_SENT")
        end
        Nx.SpellcastSentFrame = f
    end
end

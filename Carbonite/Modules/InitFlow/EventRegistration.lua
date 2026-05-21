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
    Nx:RegisterEvent("UNIT_SPELLCAST_SENT", "OnUnit_spellcast_sent")
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

    -- SOCIAL_QUEUE_UPDATE: Available from Legion+ (group finder social queues)
    if Nx.LegionMaps then
        Com:RegisterEvent("SOCIAL_QUEUE_UPDATE", "OnFriendguild_update")
    end

    -- CHAT_MSG_SYSTEM: Classic/older versions only (handled differently in retail)
    if not Nx.BFAMaps then
        Com:RegisterEvent("CHAT_MSG_SYSTEM", "OnChat_msg_channel")
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
end

-- Carbonite | Modules / Comm / ChannelSpamFilter
-- Filters out Carbonite addon-channel messages so they never
-- appear in the user's chat frame. Carbonite uses chat channels
-- "Crb{A|Y|M|B|Z}" as a side-channel for its protocol; raw
-- messages on those channels would be a visual mess if shown.
--
-- The legacy code wires this through ChatFrame_AddMessageEventFilter
-- in NxCom.lua. This class is the public accessor for adding
-- additional filtered prefixes / disabling the filter for debug.
--
-- Public API:
--   ChannelSpamFilter:Enable(on)
--   ChannelSpamFilter:IsEnabled()
--   ChannelSpamFilter:AddPrefix(prefix)   -- e.g. "Crb"

local Carbonite = _G.Carbonite

local ChannelSpamFilter = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.SpamFilter = ChannelSpamFilter

ChannelSpamFilter.prefixes = { Crb = true }
ChannelSpamFilter.enabled = true

local CHAT_EVENTS = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_CHANNEL_JOIN",
    "CHAT_MSG_CHANNEL_LEAVE",
    "CHAT_MSG_CHANNEL_NOTICE",
}

local function matchesPrefix(channelName)
    if type(channelName) ~= "string" then return false end
    for prefix in pairs(ChannelSpamFilter.prefixes) do
        if channelName:sub(1, #prefix) == prefix then return true end
    end
    return false
end

local function filter(self_, event, message, sender, _, _, _, _, _, _, channelName)
    if not ChannelSpamFilter.enabled then return false end
    if matchesPrefix(channelName) then return true end           -- suppress
    return false
end

function ChannelSpamFilter:Enable(on)
    self.enabled = on and true or false
    Carbonite.Core.EventBus:Fire("COMM_SPAM_FILTER_TOGGLED", self.enabled)
end

function ChannelSpamFilter:IsEnabled() return self.enabled end

function ChannelSpamFilter:AddPrefix(prefix)
    if type(prefix) == "string" and prefix ~= "" then self.prefixes[prefix] = true end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not _G.ChatFrame_AddMessageEventFilter then return end
    if ChannelSpamFilter._wired then return end
    ChannelSpamFilter._wired = true
    for _, event in ipairs(CHAT_EVENTS) do
        _G.ChatFrame_AddMessageEventFilter(event, filter)
    end
end)

-- Carbonite | Modules / Comm / CommChat
-- Public surface for chat-channel comm. Legacy NxCom listens on
-- CHAT_MSG_CHANNEL / CHAT_MSG_CHANNEL_JOIN / etc. and routes
-- recognized messages onto the addon-event pipeline. This class
-- gives plugins a way to subscribe to a parsed message without
-- registering their own chat-event listener.
--
-- Public API:
--   CommChat:OnChannelMessage(fn)   - fn(sender, message, channel)
--   CommChat:OnChannelJoin(fn)
--   CommChat:OnChannelLeave(fn)
--   CommChat:IsCarbChannel(channelName)  -> bool (matches "Crb*")
--   CommChat:GetCarbChannelType(name)    -> 'A' / 'Z' / nil

local Carbonite = _G.Carbonite

local CommChat = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.Chat = CommChat

function CommChat:IsCarbChannel(name)
    if type(name) ~= "string" or #name < 4 then return false end
    return name:sub(1, 3) == "Crb"
end

function CommChat:GetCarbChannelType(name)
    if not self:IsCarbChannel(name) then return nil end
    return name:sub(4, 4):upper()        -- 'A' or 'Z'
end

function CommChat:OnChannelMessage(fn)
    Carbonite.Core.EventBus:Subscribe("COMM_CHANNEL_MESSAGE", function(sender, msg, channel)
        fn(sender, msg, channel)
    end)
end

function CommChat:OnChannelJoin(fn)
    Carbonite.Core.EventBus:Subscribe("COMM_CHANNEL_JOIN", fn)
end

function CommChat:OnChannelLeave(fn)
    Carbonite.Core.EventBus:Subscribe("COMM_CHANNEL_LEAVE", fn)
end

-- Bridge from the legacy AceEvent handler so subscribers receive
-- events without each registering their own CHAT_MSG_CHANNEL
-- listener. The legacy Nx.Com:OnChat_msg_channel fires when a
-- message arrives; we hook it via an OnEnable post-hook.
Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", function()
    local Com = _G.Nx and _G.Nx.Com
    if not Com or not Com.OnChat_msg_channel or Com._chatBridgeWired then return end
    Com._chatBridgeWired = true
    local original = Com.OnChat_msg_channel
    Com.OnChat_msg_channel = function(self_, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        original(self_, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        Carbonite.Core.EventBus:Fire("COMM_CHANNEL_MESSAGE", arg2, arg1, arg9 or arg4)
    end
end)

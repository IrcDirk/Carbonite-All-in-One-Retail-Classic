-- Carbonite | Modules / Comm / CommQueue
-- Owns the public API around the rate-limited send queues that live
-- inside Nx.Com (NxCom.lua). The legacy implementation manages four
-- parallel queues (Chan / Guild / Friend / Zone), a per-pal queue,
-- and a numbered-channel queue, with a SendRate throttle. The
-- actual send logic + protocol still lives in NxCom because it has
-- intricate ties to the chat/addon-channel flush state machine; we
-- expose accessors so other modules (Punks, Quests, Notes) can
-- enqueue without poking the Nx.Com.* fields directly.
--
-- Public API:
--   CommQueue:Enqueue(queue, message)   - queue ∈ "Chan"/"Guild"/"Friend"/"Zone"
--   CommQueue:EnqueuePal(message)
--   CommQueue:EnqueueChannel(payload)
--   CommQueue:GetSendRate() / SetSendRate(n)
--   CommQueue:GetDepth(queue)           - int
--   CommQueue:Clear(queue)              - drop everything in a queue

local Carbonite = _G.Carbonite

local CommQueue = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.Queue = CommQueue

local function nxCom() return _G.Nx and _G.Nx.Com end

-- The legacy SendQNames maps queue name -> 1..4 index into Nx.Com.SendQ.
local NAME_INDEX = { Chan = 1, Guild = 2, Friend = 3, Zone = 4 }

local function queueArray(name)
    local com = nxCom()
    if not com then return nil end
    if name == "PalsSendQ" then return com.PalsSendQ end
    if name == "SendChanQ" then return com.SendChanQ end
    local idx = NAME_INDEX[name]
    return idx and com.SendQ and com.SendQ[idx]
end

function CommQueue:Enqueue(queueName, message)
    if not queueName or not message then return false end
    local q = queueArray(queueName)
    if not q then return false end
    q[#q + 1] = message
    Carbonite.Core.EventBus:Fire("COMM_ENQUEUED", queueName, message)
    return true
end

function CommQueue:EnqueuePal(message)
    local com = nxCom()
    if not com or not com.PalsSendQ then return false end
    com.PalsSendQ[#com.PalsSendQ + 1] = message
    Carbonite.Core.EventBus:Fire("COMM_ENQUEUED", "Pals", message)
    return true
end

function CommQueue:EnqueueChannel(payload)
    local com = nxCom()
    if not com or not com.SendChanQ then return false end
    table.insert(com.SendChanQ, payload)
    Carbonite.Core.EventBus:Fire("COMM_ENQUEUED", "Channel", payload)
    return true
end

function CommQueue:GetSendRate()
    local com = nxCom()
    return com and com.SendRate or 1
end

function CommQueue:SetSendRate(n)
    local com = nxCom()
    if not com or not n then return end
    -- 0.25..10 - matching the legacy slider bounds in NxOptions.
    if n < 0.25 then n = 0.25 end
    if n > 10   then n = 10   end
    com.SendRate = n
    Carbonite.Core.EventBus:Fire("COMM_SEND_RATE_CHANGED", n)
end

function CommQueue:GetDepth(queueName)
    local q = queueArray(queueName)
    return q and #q or 0
end

function CommQueue:Clear(queueName)
    local q = queueArray(queueName)
    if not q then return end
    for i = #q, 1, -1 do q[i] = nil end
    Carbonite.Core.EventBus:Fire("COMM_QUEUE_CLEARED", queueName)
end

-- Debug snapshot: returns depths for every queue. Used by `/cb comq`.
function CommQueue:Snapshot()
    return {
        Chan   = self:GetDepth("Chan"),
        Guild  = self:GetDepth("Guild"),
        Friend = self:GetDepth("Friend"),
        Zone   = self:GetDepth("Zone"),
        Pals   = self:GetDepth("PalsSendQ"),
        Chan_  = self:GetDepth("SendChanQ"),
        Rate   = self:GetSendRate(),
    }
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("comq", function()
        local log = Carbonite.Core.Logger:Get("CommQueue")
        local snap = CommQueue:Snapshot()
        log:info("Chan=%d Guild=%d Friend=%d Zone=%d Pals=%d ChanQ=%d rate=%.2f",
            snap.Chan, snap.Guild, snap.Friend, snap.Zone, snap.Pals, snap.Chan_, snap.Rate)
    end, "snapshot the comm send queues")
end)

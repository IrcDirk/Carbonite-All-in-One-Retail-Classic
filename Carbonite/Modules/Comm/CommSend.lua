-- Carbonite | Modules / Comm / CommSend
-- High-level outgoing-message verbs. The legacy NxCom exposes
-- Nx.Com:Send (and its per-channel variants) as the primary
-- broadcast point; this class is the documented surface so
-- callers can target the channel they want without thinking about
-- the SendQ index assignment.
--
-- Public API:
--   CommSend:Channel(payload [, target])    - addon channel ("A")
--   CommSend:Zone(payload)                  - zone channel ("Z")
--   CommSend:Guild(payload)
--   CommSend:Friend(payload [, target])
--   CommSend:Party(payload)
--   CommSend:Raid(payload)
--   CommSend:Whisper(payload, target)

local Carbonite = _G.Carbonite

local CommSend = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.Send = CommSend

local function com() return _G.Nx and _G.Nx.Com end

-- The legacy Nx.Com:Send takes a queue letter or distribution
-- string + a payload. We map our named verbs onto that signature.
local function send(distribution, payload, target)
    local c = com()
    if c and c.Send then c:Send(distribution, payload, target) end
end

function CommSend:Channel(payload, target) send("A", payload, target) end
function CommSend:Zone(payload)            send("Z", payload) end
function CommSend:Guild(payload)           send("GUILD", payload) end
function CommSend:Friend(payload, target)  send("WHISPER", payload, target) end
function CommSend:Party(payload)           send("PARTY", payload) end
function CommSend:Raid(payload)            send("RAID", payload) end
function CommSend:Whisper(payload, target) send("WHISPER", payload, target) end

-- Convenience: encode a typed payload via WireFormat before sending.
-- Mirrors what most callers do today (build a string, call Send).
function CommSend:Typed(distribution, kind, fields, target)
    local wf = Carbonite.Modules.Comm and Carbonite.Modules.Comm.WireFormat
    local payload = (wf and wf:Encode(kind, fields)) or tostring(kind)
    send(distribution, payload, target)
end

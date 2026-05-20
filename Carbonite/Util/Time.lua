-- Carbonite | Util / Time
-- Monotonic event-ordering timestamp + AceTimer left-time helper.
-- The legacy Nx:Time returned `time() * 100 + frac` so events fired
-- within the same `time()` second still kept a stable order. We keep
-- that semantic verbatim so saved-variable ordering stays valid
-- across an upgrade.
--
-- Public API:
--   Time:Now()                 -> int monotonic timestamp
--   Time:Real()                -> time() (delegates to OS clock)
--   Time:Frame()               -> GetTime() / coarse client uptime
--   Time:LeftOnTimer(handle)   -> seconds remaining for an
--                                 AceTimer schedule (mirrors
--                                 the legacy Nx.TimeLeft helper)

local Carbonite = _G.Carbonite

local Time = {}
Carbonite.Util.Time = Time

-- Internal monotonic state, separate from the legacy Nx.TimeLast /
-- TimeFrac so we can run before / after the legacy main file
-- without fighting over the counter. When Nx is present we prefer
-- its implementation so timestamps stay coherent across both code
-- paths.
local lastSecond = 0
local fraction   = 0

function Time:Now()
    local Nx = _G.Nx
    if Nx and Nx.Time then return Nx:Time() end

    if not _G.time then return 0 end
    local now = _G.time()
    if now > lastSecond then
        fraction = 0
    else
        fraction = fraction + 1
    end
    lastSecond = now
    return now * 100 + fraction
end

function Time:Real()
    return (_G.time and _G.time()) or 0
end

function Time:Frame()
    return (_G.GetTime and _G.GetTime()) or 0
end

-- AceTimer left-time. Carbonite's legacy code uses Nx.TimeLeft on
-- timer handles to know when a scheduled callback will fire next.
-- AceTimer-3.0's public API exposes TimeLeft on the addon object;
-- this helper forwards to it if available.
function Time:LeftOnTimer(handle)
    if not handle then return 0 end
    local Nx = _G.Nx
    if Nx and Nx.TimeLeft then return Nx.TimeLeft(handle) or 0 end
    if Nx and Nx.GetTimerLeft then return Nx:GetTimerLeft(handle) or 0 end
    return 0
end

-- Convenience: format a fractional `Nx:Time()` value back into a
-- readable "HH:MM:SS" string for log lines.
function Time:Format(timestamp)
    timestamp = math.floor((timestamp or 0) / 100)
    local d = date and date("*t", timestamp)
    if d then return ("%02d:%02d:%02d"):format(d.hour, d.min, d.sec) end
    return tostring(timestamp)
end

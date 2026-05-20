-- Carbonite | Util / Async
-- Coroutine-friendly helpers. The old NxMap iterates over thousands
-- of map nodes per frame using ad-hoc "process N then yield" loops;
-- this module gives the same behavior a single clean API.

local Carbonite = _G.Carbonite
local Async = {}
Carbonite.Util.Async = Async

-- Spreads an array of work across multiple frames so a single OnUpdate
-- pass never blocks the client. `step(item, index)` is called per item;
-- `done()` is called when the iteration finishes.
function Async.Iterate(array, step, done, perFrame)
    perFrame = perFrame or 50
    local i, n = 0, #array
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self)
        local budget = perFrame
        while budget > 0 and i < n do
            i = i + 1
            budget = budget - 1
            local ok, err = pcall(step, array[i], i)
            if not ok and Carbonite.Core and Carbonite.Core.Logger then
                Carbonite.Core.Logger:Get("Async"):error("iterate step failed: %s", err)
            end
        end
        if i >= n then
            self:SetScript("OnUpdate", nil)
            if done then pcall(done) end
        end
    end)
    return frame
end

-- One-shot scheduler. Returns a token so callers can cancel.
function Async.After(seconds, fn)
    return C_Timer.After(seconds, fn)
end

-- Throttled function wrapper. Subsequent calls within `interval`
-- seconds are coalesced into the last call's arguments.
function Async.Throttle(interval, fn)
    local pending, lastArgs
    return function(...)
        lastArgs = { ... }
        if pending then return end
        pending = true
        C_Timer.After(interval, function()
            pending = false
            fn(unpack(lastArgs))
        end)
    end
end

-- Carbonite | Modules / MainUpdater / ProcScheduler
-- The Nx.Proc lightweight tick scheduler. Lets long-running work
-- (the title-screen animation, Map:StartupZoom, deferred reloads)
-- spread across frames by registering a Func that returns the
-- number of ticks to wait before the next call. Lifted out of
-- Carbonite.lua; the per-tick pump in NXOnUpdate calls
-- Nx.Proc:OnUpdate(elapsed).
--
-- Methods stay on Nx.Proc because external callers
-- (Modules/TitleScreen/TitleScreenEngine, Modules/ScriptProcessor,
-- SetupEverything's Init call, NXOnUpdate's tick) still reach the
-- table by name.

-------------------------------------------------------------------------------
-- PROCESS SCHEDULER
-- Lightweight coroutine-like system for spreading work across frames
-------------------------------------------------------------------------------

---
-- Initialize the process scheduler
--
function Nx.Proc:Init()
    self.Procs = {}
    self.TimeLeft = 0
end

---
-- Create a new scheduled process
-- @param user   Object that owns the process (passed to func)
-- @param func   Function to call each tick
-- @param delay  Initial delay in ticks before first call
--
function Nx.Proc:New (user, func, delay)

    local p = {}
    tinsert (self.Procs, p)
    p.User = user
    p.Func = func
    p.Delay = delay or 1
end

---
-- Change the function for a running process
-- @param proc  Process object
-- @param func  New function to call
--
function Nx.Proc:SetFunc (proc, func)
    proc.Func = func
end

---
-- Process scheduler update
-- Runs pending processes based on elapsed time
-- @param elapsed  Time since last frame
--
function Nx.Proc:OnUpdate (elapsed)

--    Nx.prt ("Proc Elapsed raw %s", elapsed)

    elapsed = min (elapsed, .2) * 60

--    Nx.prt ("Proc Elapsed %s", elapsed)

    elapsed = elapsed + self.TimeLeft

    while elapsed >= 1 do

        elapsed = elapsed - 1

        local n = 1

        while 1 do
            local p = self.Procs[n]
            if not p then
                break
            end

            local d = p.Delay - 1
            if d <= 0 then
                d = p.Func (p.User, p) or 1

                if d < 0 then                -- No time?
                    tremove (self.Procs, n)        -- Kill proc
                    n = n - 1            -- Same index again
                end
            end
            p.Delay = d

            n = n + 1
        end

    end

    self.TimeLeft = elapsed
end

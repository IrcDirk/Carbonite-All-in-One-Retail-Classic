-- Carbonite | Modules / ScriptProcessor
-- Wrapper around Nx.Proc, Carbonite's lightweight tick-scheduling
-- system. Carbonite scripts (Title splash animation, route plotter,
-- etc.) register a function + a tick interval; the Proc dispatcher
-- calls them in the legacy main update loop. This class exposes a
-- documented API.
--
-- Public API:
--   ScriptProcessor:New(self, fn, ticks)
--   ScriptProcessor:SetFunc(proc, fn)
--   ScriptProcessor:Cancel(proc)

local Carbonite = _G.Carbonite
local ScriptProcessor = {}
Carbonite.Modules.ScriptProcessor = ScriptProcessor

local function proc() return _G.Nx and _G.Nx.Proc end

function ScriptProcessor:New(target, fn, ticks)
    local p = proc()
    if not p or not p.New then return nil end
    return p:New(target, fn, ticks)
end

function ScriptProcessor:SetFunc(procHandle, fn)
    local p = proc()
    if not p or not p.SetFunc then return end
    p:SetFunc(procHandle, fn)
end

function ScriptProcessor:Cancel(procHandle)
    local p = proc()
    if p and p.Cancel then p:Cancel(procHandle) end
end

-- Carbonite | Modules / TooltipScanner
-- Public surface for Carbonite's "scan the active tooltip and
-- extract quest objective text" subsystem. The legacy code lives
-- across Nx.Quest:TooltipProcess + the tooltip-scanning poll inside
-- Nx:NXOnUpdate. This class is the documented accessor; the actual
-- scanning logic stays in NxQuest because it needs the quest DB.
--
-- Public API:
--   TooltipScanner:Scan(forceMouseover)
--   TooltipScanner:GetLastText()
--   TooltipScanner:GetLastNumLines()
--   TooltipScanner:HasTooltipDataProcessor()  - bool
--
-- The HasTooltipDataProcessor query lets new code know whether the
-- safe TooltipDataProcessor.AddTooltipPostCall API is available
-- (retail + most Classic flavors) or whether we fall back to the
-- per-frame poll (Classic Era).

local Carbonite = _G.Carbonite
local TooltipScanner = {}
Carbonite.Modules.TooltipScanner = TooltipScanner

function TooltipScanner:Scan(forceMouseover)
    local Nx = _G.Nx
    if Nx and Nx.Quest and Nx.Quest.TooltipProcess then
        Nx.Quest:TooltipProcess(forceMouseover)
    end
end

function TooltipScanner:GetLastText()
    return _G.Nx and _G.Nx.TooltipLastText or ""
end

function TooltipScanner:GetLastNumLines()
    return _G.Nx and _G.Nx.TooltipLastDiffNumLines or 0
end

function TooltipScanner:HasTooltipDataProcessor()
    return _G.TooltipDataProcessor and _G.TooltipDataProcessor.AddTooltipPostCall ~= nil or false
end

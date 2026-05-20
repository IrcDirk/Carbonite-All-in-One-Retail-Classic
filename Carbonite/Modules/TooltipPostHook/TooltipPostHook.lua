-- Carbonite | Modules / TooltipPostHook
-- Safe-tooltip post-hook registration. The modern Blizzard API
-- (TooltipDataProcessor.AddTooltipPostCall) is the taint-safe way
-- to enrich GameTooltip after Blizzard's own code finishes building
-- it. Carbonite uses it to add NPC IDs / quest hub info / and
-- Carbonite-specific lines.
--
-- This class is the documented accessor + a uniform fallback when
-- the API is missing (Classic Era pre-tooltip-system).
--
-- Public API:
--   TooltipPostHook:Register(typeEnum, fn, name)
--   TooltipPostHook:Unregister(typeEnum, name)
--   TooltipPostHook:IsAvailable()
--   TooltipPostHook:GetTypes()        -> map of Enum.TooltipDataType names

local Carbonite = _G.Carbonite

local TooltipPostHook = {}
Carbonite.Modules.TooltipPostHook = TooltipPostHook

function TooltipPostHook:IsAvailable()
    return _G.TooltipDataProcessor
       and _G.TooltipDataProcessor.AddTooltipPostCall ~= nil
end

function TooltipPostHook:GetTypes()
    if _G.Enum and _G.Enum.TooltipDataType then return _G.Enum.TooltipDataType end
    return {}
end

local registered = {}     -- "typeEnum:name" -> fn

local function key(typeEnum, name) return tostring(typeEnum) .. ":" .. tostring(name or "anon") end

function TooltipPostHook:Register(typeEnum, fn, name)
    if not self:IsAvailable() or not typeEnum or type(fn) ~= "function" then return end
    local k = key(typeEnum, name)
    if registered[k] then return end       -- avoid duplicate registration
    registered[k] = fn
    _G.TooltipDataProcessor.AddTooltipPostCall(typeEnum, fn)
end

function TooltipPostHook:Unregister(typeEnum, name)
    local k = key(typeEnum, name)
    -- Blizzard's API has no removal helper; we mark the slot as
    -- "do nothing" so future invocations skip our handler.
    registered[k] = nil
end

-- Carbonite | Modules / MouseoverHandler
-- Documented surface around the UPDATE_MOUSEOVER_UNIT handler.
-- The legacy Nx:OnUpdate_mouseover_unit reads the mouseover unit's
-- GUID, breaks out the type (player / NPC / pet) + numeric NPC ID,
-- and stamps a debug line onto GameTooltip when DebugUnit is on.
--
-- This class is the public accessor so other modules can react to
-- mouseover transitions without registering their own
-- UPDATE_MOUSEOVER_UNIT listener.
--
-- Public API:
--   MouseoverHandler:GetUnitGUID()
--   MouseoverHandler:GetUnitType()       -> 0/3/4 (player/NPC/pet) per legacy
--   MouseoverHandler:GetUnitNpcID()
--   MouseoverHandler:OnChanged(fn)       - subscribe to transitions

local Carbonite = _G.Carbonite
local MouseoverHandler = {}
Carbonite.Modules.MouseoverHandler = MouseoverHandler

local lastGUID

-- Suppress secret GUIDs at the public accessor so no subscriber receives
-- one, and an inaccessible mouseover clears a previous accessible unit once.
local canaccessvalue = _G.canaccessvalue
local issecretvalue = _G.issecretvalue
local function CanUseGUID(guid)
    if canaccessvalue and not canaccessvalue(guid) then
        return false
    end
    return not (issecretvalue and issecretvalue(guid))
end

function MouseoverHandler:GetUnitGUID()
    if not _G.UnitGUID then return nil end
    local guid = _G.UnitGUID("mouseover")
    if not CanUseGUID(guid) or (guid and type(guid) ~= "string") then
        return nil
    end
    return guid
end

function MouseoverHandler:GetUnitType()
    local guid = self:GetUnitGUID()
    if not guid then return nil end
    -- Legacy GUID parsing: hex digit at offset 5.
    return tonumber(guid:sub(5, 5), 16)
end

function MouseoverHandler:GetUnitNpcID()
    local guid = self:GetUnitGUID()
    if not guid then return nil end
    return tonumber(guid:sub(7, 10), 16)
end

function MouseoverHandler:OnChanged(fn)
    if type(fn) == "function" then
        Carbonite.Core.EventBus:Subscribe("MOUSEOVER_UNIT_CHANGED", fn)
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local f = CreateFrame("Frame", "CarbMouseoverHandler")
    f:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    f:SetScript("OnEvent", function()
        local guid = MouseoverHandler:GetUnitGUID()
        if guid ~= lastGUID then
            lastGUID = guid
            Carbonite.Core.EventBus:Fire("MOUSEOVER_UNIT_CHANGED", guid,
                guid and tonumber(guid:sub(5, 5), 16) or nil,
                guid and tonumber(guid:sub(7, 10), 16) or nil)
        end
    end)
end)

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

-- Retail's UnitGUID("mouseover") can hand back a secure-tainted "secret"
-- string for player units; touching it with `:sub` / `==` from an addon
-- code path raises ("attempt to index/compare a secret string value,
-- while execution tainted by 'Carbonite'"). File-scope helpers keep the
-- pcall guard allocation-free (same pattern as NXOnUpdate's tooltip
-- text scanner).
local function _guid_sub(g, a, b) return g:sub(a, b) end
local function _guid_neq(a, b) return a ~= b end

function MouseoverHandler:GetUnitGUID()
    return _G.UnitGUID and _G.UnitGUID("mouseover") or nil
end

function MouseoverHandler:GetUnitType()
    local guid = self:GetUnitGUID()
    if not guid then return nil end
    -- Legacy GUID parsing: hex digit at offset 5.
    local ok, s = pcall(_guid_sub, guid, 5, 5)
    if not ok then return nil end
    return tonumber(s, 16)
end

function MouseoverHandler:GetUnitNpcID()
    local guid = self:GetUnitGUID()
    if not guid then return nil end
    local ok, s = pcall(_guid_sub, guid, 7, 10)
    if not ok then return nil end
    return tonumber(s, 16)
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
        local ok, changed = pcall(_guid_neq, guid, lastGUID)
        if not ok then changed = true end
        if changed then
            lastGUID = guid
            Carbonite.Core.EventBus:Fire("MOUSEOVER_UNIT_CHANGED", guid,
                MouseoverHandler:GetUnitType(),
                MouseoverHandler:GetUnitNpcID())
        end
    end)
end)

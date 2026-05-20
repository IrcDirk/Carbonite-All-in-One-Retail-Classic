-- Carbonite | Modules / Map / IconTooltip
-- Per-icon hover tooltip handler for icons drawn on the Carbonite
-- map and minimap. The legacy code wires icon frames' OnEnter
-- handlers to Nx.Map.IconOnEnter, which reads icon.Tip and
-- icon.NxTipBase to assemble a tooltip and routes it through
-- Nx.TooltipText.
--
-- This class is the public accessor + supports replacing the
-- tooltip text for a live icon without rebuilding it.
--
-- Public API:
--   IconTooltip:SetText(icon, text)
--   IconTooltip:GetText(icon)
--   IconTooltip:Show(icon, owner)
--   IconTooltip:Hide()

local Carbonite = _G.Carbonite
local IconTooltip = {}
Carbonite.Modules.Map.IconTooltip = IconTooltip

function IconTooltip:SetText(icon, text)
    if not icon then return end
    icon.Tip = text
end

function IconTooltip:GetText(icon)
    if not icon then return nil end
    return icon.Tip or icon.NxTipBase
end

function IconTooltip:Show(icon, ownerFrame)
    if not icon then return end
    local text = self:GetText(icon)
    if not text or text == "" then return end
    local tt = Carbonite.UI.Tooltip
    if not tt then return end
    -- Split tip text on ~ which the legacy code uses as a line
    -- separator inside the tip string.
    local lines = {}
    for line in text:gmatch("([^~]+)") do lines[#lines + 1] = line end
    tt:Show(ownerFrame, "ANCHOR_RIGHT", lines)
end

function IconTooltip:Hide()
    local tt = Carbonite.UI.Tooltip
    if tt and tt.Hide then tt:Hide() end
end

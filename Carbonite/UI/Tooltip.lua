-- Carbonite | UI / Tooltip
-- Owns the singleton Nx.TooltipText frame and a thin wrapper API.
-- Code that previously called GameTooltip:SetText / GameTooltip:Show
-- should call Carbonite.UI.Tooltip.* so we never taint the game's
-- own tooltip - see [[feedback_gametooltip_taint]].

local Carbonite = _G.Carbonite
local Tooltip = {}
Carbonite.UI.Tooltip = Tooltip

local frame

function Tooltip:Get()
    if frame then return frame end
    frame = CreateFrame("GameTooltip", "NxTooltipText", UIParent, "GameTooltipTemplate")
    frame:SetOwner(UIParent, "ANCHOR_NONE")
    if _G.Nx then _G.Nx.TooltipText = frame end
    return frame
end

function Tooltip:Show(owner, anchor, lines)
    local tt = self:Get()
    tt:ClearLines()
    tt:SetOwner(owner or UIParent, anchor or "ANCHOR_RIGHT")
    if type(lines) == "string" then
        tt:SetText(lines)
    elseif type(lines) == "table" then
        for i, line in ipairs(lines) do
            if i == 1 then
                tt:SetText(line)
            else
                tt:AddLine(line, 1, 1, 1, true)
            end
        end
    end
    tt:Show()
end

function Tooltip:Hide()
    if frame then frame:Hide() end
end

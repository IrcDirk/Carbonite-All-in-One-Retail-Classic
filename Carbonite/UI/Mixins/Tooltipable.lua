-- Carbonite | UI / Mixins / Tooltipable
-- Routes tooltip text through Nx.TooltipText, NOT GameTooltip.
-- Touching GameTooltip from Carbonite has historically tainted
-- Blizzard's own tooltip math, breaking loot-money line widths and
-- a handful of other UI layouts (see [[feedback_gametooltip_taint]]).

local Carbonite = _G.Carbonite
local Tooltipable = {}
Carbonite.UI.Mixins = Carbonite.UI.Mixins or {}
Carbonite.UI.Mixins.Tooltipable = Tooltipable

local function ensureTooltip()
    local tt = _G.NxTooltipText or _G.Nx and _G.Nx.TooltipText
    if not tt then
        tt = CreateFrame("GameTooltip", "NxTooltipText", UIParent, "GameTooltipTemplate")
        tt:SetOwner(UIParent, "ANCHOR_NONE")
        _G.NxTooltipText = tt
        if _G.Nx then _G.Nx.TooltipText = tt end
    end
    return tt
end

-- `provider` may be a string (single line) or a function(frame, tooltip)
-- that calls tooltip:AddLine / SetText / SetHyperlink for richer layouts.
function Tooltipable:SetCarbTooltip(provider, anchor)
    self.carbTooltipProvider = provider
    self.carbTooltipAnchor   = anchor or "ANCHOR_RIGHT"

    self:SetScript("OnEnter", function(f)
        local tt = ensureTooltip()
        tt:ClearLines()
        tt:SetOwner(f, f.carbTooltipAnchor or "ANCHOR_RIGHT")
        if type(f.carbTooltipProvider) == "function" then
            f.carbTooltipProvider(f, tt)
        elseif type(f.carbTooltipProvider) == "string" then
            tt:SetText(f.carbTooltipProvider)
        end
        tt:Show()
    end)

    self:SetScript("OnLeave", function() ensureTooltip():Hide() end)
end

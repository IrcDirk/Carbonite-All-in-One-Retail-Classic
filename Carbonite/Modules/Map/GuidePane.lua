-- Carbonite | Modules / Map / GuidePane
-- Public visibility surface around the legacy guide pane. The
-- guide pane is the right-side panel on the Carbonite map that
-- shows targets, recommended routes, vendor lists, etc.
--
-- Public API:
--   GuidePane:Toggle()
--   GuidePane:Show()
--   GuidePane:Hide()
--   GuidePane:IsShown()
--   GuidePane:Refresh()

local Carbonite = _G.Carbonite
local GuidePane = {}
Carbonite.Modules.Map.GuidePane = GuidePane

local function guide()
    local m = _G.Nx and _G.Nx.Map
    return m and m.Maps and m.Maps[1] and m.Maps[1].Guide
end

function GuidePane:Toggle()
    local g = guide()
    if g and g.ToggleShow then g:ToggleShow() end
end

function GuidePane:Show()
    local g = guide()
    if g and g.Show then g:Show(true) end
end

function GuidePane:Hide()
    local g = guide()
    if g and g.Show then g:Show(false) end
end

function GuidePane:IsShown()
    local g = guide()
    return g and g.IsShown and g:IsShown() or false
end

function GuidePane:Refresh()
    local g = guide()
    if g and g.Update then g:Update() end
end

-- Carbonite | Modules / Whatsnew / WhatsnewWindow
-- Public face for the What's New window. The legacy window
-- implementation in Carbonite.lua (Nx.Whatsnew:Create / ToggleShow /
-- Update etc.) keeps owning the actual UI because it depends on
-- Nx.Window + Nx.List + Nx.Button - widgets we have not yet fully
-- replaced. This class exposes a clean lifecycle API + a runtime
-- "category" registry so plugins can contribute their own pages.
--
-- Public API:
--   WhatsnewWindow:Toggle()
--   WhatsnewWindow:Show()
--   WhatsnewWindow:Hide()
--   WhatsnewWindow:IsShown()
--   WhatsnewWindow:Refresh()         redraws the active category
--   WhatsnewWindow:SelectCategory(n) by 1-based index
--   WhatsnewWindow:GetSelectedCategory()
--   WhatsnewWindow:MarkRead()        records "last read" timestamp +
--                                    clears the minimap-button glow
--   WhatsnewWindow:AddCategory(name) plugin extension

local Carbonite = _G.Carbonite

local WhatsnewWindow = {}
Carbonite.Modules.Whatsnew = Carbonite.Modules.Whatsnew or {}
Carbonite.Modules.Whatsnew.Window = WhatsnewWindow

local function legacy() return _G.Nx and _G.Nx.Whatsnew end

function WhatsnewWindow:Toggle()
    local L = legacy()
    if L and L.ToggleShow then L:ToggleShow() end
end

function WhatsnewWindow:Show()
    local L = legacy()
    if not L then return end
    if not L.Win then L:Create() end
    if L.Win and L.Win.Show then L.Win:Show(true) end
    if L.Update then L:Update() end
end

function WhatsnewWindow:Hide()
    local L = legacy()
    if L and L.Win and L.Win.Show then L.Win:Show(false) end
end

function WhatsnewWindow:IsShown()
    local L = legacy()
    return L and L.Win and L.Win.IsShown and L.Win:IsShown() or false
end

function WhatsnewWindow:Refresh()
    local L = legacy()
    if L and L.Update then L:Update() end
end

function WhatsnewWindow:SelectCategory(n)
    local L = legacy()
    if L and L.Cat_button then L:Cat_button(n) end
end

function WhatsnewWindow:GetSelectedCategory()
    local L = legacy()
    return L and L.WhichCat
end

function WhatsnewWindow:MarkRead()
    local L = legacy()
    if L and L.Recordtime then L:Recordtime() end
    -- Defensive mirror: even if the legacy function moved or was
    -- inlined, ensure our remembered last-read time updates.
    local mod = Carbonite.Modules.Whatsnew
    if mod and mod.SetLastReadTime and _G.time then
        mod:SetLastReadTime(_G.time())
    end
    -- Clear the minimap button glow if the new MinimapButton class
    -- is loaded.
    local mb = Carbonite.Modules.Map and Carbonite.Modules.Map.MinimapButton
    if mb and mb.SetGlow then mb:SetGlow(false) end
end

function WhatsnewWindow:AddCategory(name)
    local mod = Carbonite.Modules.Whatsnew
    if mod and mod.AddCategory then mod:AddCategory(name) end
    local L = legacy()
    if L and L.Win then
        -- Window already exists, would need a re-Create to show the
        -- new tab. Provide a hint rather than rebuilding so we don't
        -- destroy the user's current selection.
        if Carbonite.Core.Logger then
            Carbonite.Core.Logger:Get("WhatsnewWindow"):info(
                "Added category %q; restart UI to see the new tab", name)
        end
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if Carbonite.Core.SlashCommands then
        Carbonite.Core.SlashCommands:Register("changelog", function()
            WhatsnewWindow:Show()
        end, "open the changelog window")
    end
end)

-- Carbonite | Modules / TitleScreen
-- The Carbonite splash that displays version + maintainer text on
-- login. The legacy Nx.Title implementation built a Frame with the
-- Carbonite logo and animated it in via Nx.Proc tick functions.
-- This class exposes the same animation behind a clean API and adds
-- a "skip splash" / "respect user setting" gate.
--
-- Public API:
--   TitleScreen:Show()       - manually trigger (e.g. /cb splash)
--   TitleScreen:Hide()
--   TitleScreen:IsShown()
--   TitleScreen:IsEnabled()  - false if user opted out via options
--
-- The actual animation tick functions still live on Nx.Title because
-- they call into Nx.Proc which is part of the legacy main loop.

local Carbonite = _G.Carbonite

local TitleScreen = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.TitleScreen = TitleScreen

local function legacy() return _G.Nx and _G.Nx.Title end

function TitleScreen:IsEnabled()
    local Nx = _G.Nx
    if not Nx or not Nx.db or not Nx.db.profile or not Nx.db.profile.General then return true end
    return not Nx.db.profile.General.TitleOff
end

function TitleScreen:Show()
    local L = legacy()
    if not L or not L.Frm then return end
    L.Frm:Show()
    Carbonite.Core.EventBus:Fire("TITLE_SCREEN_SHOWN")
end

function TitleScreen:Hide()
    local L = legacy()
    if not L or not L.Frm then return end
    L.Frm:Hide()
    Carbonite.Core.EventBus:Fire("TITLE_SCREEN_HIDDEN")
end

function TitleScreen:IsShown()
    local L = legacy()
    return L and L.Frm and L.Frm:IsShown() or false
end

-- Slash trigger for testing.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if Carbonite.Core.SlashCommands then
        Carbonite.Core.SlashCommands:Register("splash", function()
            TitleScreen:Show()
        end, "show the Carbonite splash screen now")
    end
end)

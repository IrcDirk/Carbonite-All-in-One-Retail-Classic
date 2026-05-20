-- Carbonite | Modules / LootHandler
-- Auto-click "loot" / "complete quest" / first-gossip-button on
-- Carbonite's loot-mode toggle. The legacy implementation lives
-- as Nx:LootIt + a flag Nx.LootOn checked every frame by
-- Nx:NXOnUpdate. This class is the public accessor.
--
-- Public API:
--   LootHandler:IsEnabled()
--   LootHandler:Enable(on)
--   LootHandler:Toggle()
--   LootHandler:LootNow()    -- one-shot click
--
-- Registers `/cb loot on|off|toggle` and feeds the per-frame
-- driver via MainUpdater (interval = 1 frame) when enabled.

local Carbonite = _G.Carbonite

local LootHandler = {}
Carbonite.Modules.LootHandler = LootHandler

function LootHandler:IsEnabled()
    return _G.Nx and _G.Nx.LootOn == true
end

function LootHandler:Enable(on)
    if _G.Nx then _G.Nx.LootOn = on and true or false end
    Carbonite.Core.EventBus:Fire("LOOT_HANDLER_TOGGLED", on == true)
end

function LootHandler:Toggle()
    self:Enable(not self:IsEnabled())
end

function LootHandler:LootNow()
    local Nx = _G.Nx
    if Nx and Nx.LootIt then Nx:LootIt() ; return end

    -- Portable fallback: click the first visible gossip option.
    local b = _G["GossipTitleButton1"]
    if b and b.IsVisible and b:IsVisible() and b.Click then b:Click() end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("loot", function(rest)
        rest = (rest or ""):lower()
        if rest == "on" then LootHandler:Enable(true)
        elseif rest == "off" then LootHandler:Enable(false)
        else LootHandler:Toggle() end
        Carbonite.Core.Logger:Get("LootHandler"):info(
            "loot mode: %s", LootHandler:IsEnabled() and "on" or "off")
    end, "toggle the auto-loot/gossip click handler")
end)

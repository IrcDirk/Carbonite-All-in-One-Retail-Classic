-- Carbonite | Modules / Map / NameplateGlow
-- Driver for the periodic "pulse" effect on the Carbonite minimap
-- button when there are unread events / changelog entries / etc.
-- The legacy code lives as the GlowOn flag + a per-frame check that
-- swaps the minimap button texture between MMBut / MMButFilled.
--
-- This class wraps the Glow lifecycle so plugin code can flip it
-- on/off without poking Nx.GlowOn directly.
--
-- Public API:
--   NameplateGlow:Enable(on)
--   NameplateGlow:IsEnabled()
--   NameplateGlow:Pulse()      -- single one-shot flash
--
-- Triggers MinimapButton:SetGlow on the new architecture so the
-- visual update goes through the documented texture swap.

local Carbonite = _G.Carbonite

local NameplateGlow = {}
Carbonite.Modules.Map.NameplateGlow = NameplateGlow

local function setGlow(on)
    local Nx = _G.Nx
    if Nx then Nx.GlowOn = on and true or false end
    local mb = Carbonite.Modules.Map and Carbonite.Modules.Map.MinimapButton
    if mb and mb.SetGlow then mb:SetGlow(on) end
end

function NameplateGlow:Enable(on)
    setGlow(on)
    Carbonite.Core.EventBus:Fire("MAP_GLOW_TOGGLED", on == true)
end

function NameplateGlow:IsEnabled()
    return _G.Nx and _G.Nx.GlowOn == true
end

function NameplateGlow:Pulse()
    if self:IsEnabled() then return end           -- already on; let it stay
    self:Enable(true)
    C_Timer.After(1.2, function() self:Enable(false) end)
end

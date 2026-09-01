-- Carbonite | Core / Bootstrap
-- Owns the very first lines of code that run for the addon.
-- Creates the AceAddon-3.0 instance and exposes a single namespace
-- on which every subsequent file hangs its public API.
--
-- The legacy Carbonite.lua also calls `LibStub("AceAddon-3.0"):NewAddon`.
-- Loading Bootstrap first means *we* win that race and legacy code
-- falls through to its `GetAddon` branch. The legacy file still owns
-- the OnInitialize / OnEnable methods, so this module does not
-- attach lifecycle hooks - we fire the EventBus from a dedicated
-- listener frame below.

local ADDON_NAME = "Carbonite"

local AceAddon = LibStub("AceAddon-3.0")

local Carbonite = AceAddon:GetAddon(ADDON_NAME, true)
if not Carbonite then
    Carbonite = AceAddon:NewAddon(ADDON_NAME,
        "AceConsole-3.0",
        "AceTimer-3.0",
        "AceEvent-3.0",
        "AceComm-3.0",
        "AceHook-3.0",
        "AceBucket-3.0",
        "AceSerializer-3.0")
end

_G.Carbonite = Carbonite
_G.Nx = Carbonite   -- legacy alias

Carbonite.Core   = Carbonite.Core   or {}
Carbonite.Util   = Carbonite.Util   or {}
Carbonite.UI     = Carbonite.UI     or {}
Carbonite.Compat = Carbonite.Compat or {}
Carbonite.Modules = Carbonite.Modules or {}

function Carbonite:L()
    return LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
end

Carbonite.VERSION_STRING = "v12.1.0-00002"
if Carbonite.VERSION_STRING:find("project%-version") then
    Carbonite.VERSION_STRING = "dev"
end

-- Lifecycle hookup via a private event frame. We do NOT define
-- OnInitialize / OnEnable on the addon object because the legacy
-- Carbonite.lua replaces those. Instead, listen for the standard
-- ADDON_LOADED + PLAYER_LOGIN events and forward to EventBus.
local lifecycle = CreateFrame("Frame", "CarbLifecycle")
lifecycle:RegisterEvent("ADDON_LOADED")
lifecycle:RegisterEvent("PLAYER_LOGIN")
lifecycle:RegisterEvent("PLAYER_ENTERING_WORLD")
lifecycle:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        if Carbonite.Core.EventBus then
            Carbonite.Core.EventBus:Fire("CARBONITE_LOADED", Carbonite)
        end
    elseif event == "PLAYER_LOGIN" then
        if Carbonite.Core.EventBus then
            Carbonite.Core.EventBus:Fire("CARBONITE_INITIALIZE", Carbonite)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if Carbonite.Core.EventBus then
            Carbonite.Core.EventBus:Fire("CARBONITE_ENABLE", Carbonite)
        end
    end
end)
Carbonite._lifecycleFrame = lifecycle

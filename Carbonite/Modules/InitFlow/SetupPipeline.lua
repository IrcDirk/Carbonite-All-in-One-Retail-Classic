-- Carbonite | Modules / InitFlow / SetupPipeline
-- The legacy SetupEverything pipeline + the early ADDON_LOADED /
-- UNIT_NAME_UPDATE handlers + LocaleInit, all extracted from
-- Carbonite.lua. Carbonite.xml's NxFrame OnLoad registers
-- ADDON_LOADED and UNIT_NAME_UPDATE on the Nx AceEvent embed; the
-- per-frame NxOnUpdate keeps calling Nx:SetupEverything().

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

---
-- Main initialization function
-- Sets up all modules and UI components after player is detected
-- Called when addon is loaded, player exists, and not in combat
--
function Nx:SetupEverything()

    if not Nx.FirstTry then
        return
    end
    Nx.FirstTry = false
    local fact = UnitFactionGroup ("player")
    Nx.PlFactionNum = strsub (fact, 1, 1) == "A" and 0 or 1

    Nx.AirshipType = Nx.PlFactionNum == 0 and "Airship Alliance" or "Airship Horde"

    Nx:InitGlobal()

    Nx:prtSetChatFrame()

    if Nx.db.profile.General.LoginHideVer then
        Nx.prt (L["Carbonite"].." |cffffffff"..Nx.VERMAJOR.."."..(Nx.VERMINOR*10).." Build "..Nx.BUILD.." ".. L["Loading"])
    end

    Nx:LocaleInit()

    Nx:InitEvents()

    Nx.Opts:Init()

    Nx:UIInit()
    Nx.Item:Init()
    Nx.Proc:Init()
    Nx.Title:Init()
    Nx.NXMiniMapBut:Init()

    Nx.Com:Init()
    Nx.HUD:Init()
    Nx.Map:Init()

    Nx:GatherInit()        -- Needs map init. May need to do before map open

    Nx.Map:Open()
    Nx.Travel:Init()

    Nx.UEvents:Init()
    Nx.UEvents.List:Open()

    if Nx.db.profile.General.LoginHideVer then
        Nx.prt (L["Loading Done"])
    end
    if Nx.Font.AddonLoaded then
        Nx.Font:AddonLoaded()
    end

    ShowUIPanel(WorldMapFrame)
    HideUIPanel(WorldMapFrame)

    if Nx.db.profile.Map.MaxOverride then Nx.Map:ToggleSize() end

    Nx.Initialized = true
    Nx:OnPlayer_login("PLAYER_LOGIN")

    -- Zygor Guides Viewer arrow integration moved to
    -- Carbonite.Notes/Integrations/ZygorArrow.lua (toggle in the Notes
    -- options, parity with the RXPGuides arrow bridge).

    --GuildControlPopupFrame.initialized = 1
end

---
-- Handle ADDON_LOADED event
-- Marks addon as loaded
--
function Nx:ADDON_LOADED (event, arg1, ...)
    Nx.Loaded = true
    CarbMigr = {}
end

---
-- Handle UNIT_NAME_UPDATE event
-- Called when player name becomes available; enables TomTom emulation
--
function Nx:UNIT_NAME_UPDATE (event, arg1, ...)
    Nx.PlayerFnd = true

    if _G.TomTom then
        Nx.RealTom = true
        SLASH_CBWAY1 = '/cbway'
        SlashCmdList["CBWAY"] = function (msg, editbox)
            Nx:TTWayCmd(msg)
        end
    end

    Nx.EmulateTomTom()
end

---
-- Initialize locale settings
-- Stores current game locale for localization
--
function Nx:LocaleInit()
    local loc = GetLocale()
    Nx.Locale = loc
end

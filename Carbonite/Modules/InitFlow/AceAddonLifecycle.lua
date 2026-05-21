-- Carbonite | Modules / InitFlow / AceAddonLifecycle
-- AceAddon's lifecycle hooks for the Carbonite addon. Defines
-- OnInitialize / OnProfileChanged / OnEnable / OnDisable + the
-- Carbonite.xml frame OnLoad target (NXOnLoad). AceAddon's
-- InitializeAddon (which runs on ADDON_LOADED("Carbonite")) looks
-- these up by name on the Nx/Carbonite table; loading them here
-- via Modules.xml is fine because Modules.xml runs before
-- ADDON_LOADED fires.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

function Nx:OnInitialize()
    local ver = GetBuildInfo()
    local v1, v2, v3 = Nx.Split (".", ver)
    v1 = tonumber (v1) or 0
    v2 = tonumber (v2) or 0
    v3 = tonumber (v3) or 0
    ver = v1 * 10000 + v2 * 100 + v3

    Nx.V30 = true

    if ver < 10000 or ver >= 40003 then        -- Patch 4
        Nx.V403 = true
    end

    if ver > 10000 and ver < 50000 then        -- Old?
        --local s = "|cffff2020" .. L["Carbonite requires v5.0 or higher"]
        --DEFAULT_CHAT_FRAME:AddMessage (s)
        --UIErrorsFrame:AddMessage (s)
        Nx.NXVerOld = true
    end
    Nx.TooltipLastDiffNumLines = 0
    Nx.db = LibStub("AceDB-3.0"):New("CarbData", Nx.Defaults, true)
    tinsert(Nx.dbs,Nx.db)
    Nx.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    Nx.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    Nx.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    Nx.SetupConfig()
    Nx:RegisterComm("carbmodule",Nx.ModChatReceive)
end

function Nx:OnProfileChanged(event, database, newProfileKey)
    if not Nx.db.profile.MapSettings then
        Nx.db:RegisterDefaults(Nx.Defaults)
        Nx.db.profile.MapSettings = NxMapOptsDefaults
        Nx.db.profile.MapSettings.Maps = NXMapOptsMapsDefault
    end
    Nx.db.profile.Version.OptionsVersion = Nx.VERSIONGOPTS
    Nx.Map:VerifySettings()
    Nx.Opts.NXCmdReload()
end

function Nx:OnEnable()
end

function Nx:OnDisable()
end
-------------------------------------------------------------------------------
-- SLASH COMMAND HANDLER
-- Parses /carb command and subcommands
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Nx.slashCommand (the /carb dispatcher) lives in
-- Modules/SlashHandler/SlashCommandEngine.lua.
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- ADDON STARTUP
-- Initial loading and event registration
-------------------------------------------------------------------------------

---
-- Called when the addon frame is created
-- Registers slash commands and initial events
-- @param frm  The addon's main frame
--
function Nx:NXOnLoad (frm)

    SlashCmdList["Carbonite"] = Nx.slashCommand
    SLASH_Carbonite1 = "/Carb"

    self.Frm = frm        --V4 this
    self.TimeLast = 0
    self.ClassColorStrs = Nx.Util_coltrgb2colstr (RAID_CLASS_COLORS)

    Nx:RegisterEvent ("ADDON_LOADED")
    Nx:RegisterEvent ("UNIT_NAME_UPDATE")
    Nx:RegisterEvent ("PLAYER_ENTERING_WORLD", "UNIT_NAME_UPDATE")
    Nx.CalendarDate = 0        -- For safety if Map update happens early
end

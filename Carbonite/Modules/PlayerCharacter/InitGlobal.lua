-- Carbonite | Modules / Core / InitGlobal
-- Saved-variable migration + default-installation pass. Called from
-- SetupEverything at PLAYER_LOGIN. Walks every profile / character
-- /global table that Carbonite owns, resets to defaults when the
-- on-disk version doesn't match the in-source VERSION* constants,
-- and back-fills missing sub-tables so unmigrated saved variables
-- don't error on first access.
--
-- Method stays on Nx because Carbonite.lua's SetupEverything calls
-- it as Nx:InitGlobal().

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

---
-- Initialize global data structures
-- Creates/migrates character data, options, travel data, gather data, etc.
--
function Nx:InitGlobal()
    if Nx.db.profile.Version.OptionsVersion < Nx.VERSIONDATA then

        if Nx.db.profile.Version.OptionsVersion > 0 then
            Nx.prt (L["Reset old data"] .. " %f", Nx.db.profile.Version.OptionsVersion)
        end

        Nx.db:ResetDB("Default")
        Nx.db.profile.Version.OptionsVersion = Nx.VERSIONDATA
        Nx.db.global.Characters = {}        -- Indexed by "Server.Name"
    end

    if not Nx.db.profile.Version.NXVer1 then
        Nx.db.profile.Version.NXVer1 = Nx.VERSION
    end
    Nx:InitCharacter()

    --

--    local unitName = Nx.DemungeStr ("TnjrManc")    -- UnitName
--    Nx.PlayerName = _G[unitName] (Nx.DemungeStr ("olbwdr"))        -- player

    -- Global options

    local opts = Nx.db.profile

    if not opts or opts.Version.OptionsVersion < Nx.VERSIONGOPTS then

        if opts and opts.Version.OptionsVersion < Nx.VERSIONGOPTS then
            Nx.prt (L["Reset old global options"] .. " %f", opts.Version.OptionsVersion)
            Nx:ShowMessage (L["Options have been reset for the new version."] .. "\n" .. L["Privacy or other settings may have changed."], "OK")
        end

        opts = {}
        Nx.db:ResetDB("Default")
        Nx.db.profile.Version.OptionsVersion = Nx.VERSIONGOPTS

--        Nx.Opts:Reset()
    end

    -- Clean old junk

--    opts.NXCleaned = nil

    if not opts.NXCleaned then

        opts.NXCleaned = true

        local keep = {
            ["Characters"] = 1,
            ["NXCap"] = 1,
            ["NXFav"] = 1,
            ["NXGather"] = 1,
            ["NXGOpts"] = 1,
            ["NXHUDOpts"] = 1,
            ["NXInfo"] = 1,
            ["NXQOpts"] = 1,
            ["NXSocial"] = 1,
            ["NXTravel"] = 1,
            ["NXVendorV"] = 1,
            ["NXVendorVVersion"] = 1,
            ["NXVer1"] = 1,
            ["NXVerT"] = 1,
            ["NXWare"] = 1,
            ["Version"] = 1,
        }

        local cnt = 0
        if cnt > 0 then
            Nx.prt (L["Cleaned"] .. " %d " .. L["items"], cnt)
        end
    end

    -- HUD options

    local opts = Nx.db.profile.HUDOpts

    if not opts or opts.Version < Nx.VERSIONHUDOPTS then

        if opts then
            Nx.prt (L["Reset old HUD options"] .. " %f", opts.Version)
        end

        opts = {}
        Nx.db.profile.HUDOpts = opts
        opts.Version = Nx.VERSIONHUDOPTS

--        Nx.HUD:OptsReset()
    end

    -- Travel data

    local tr = Nx.db.char.Travel

    if not tr or tr.Version < Nx.VERSIONTRAVEL then

        if tr then
            Nx.prt (L["Reset old travel data"] .. " %f", tr.Version)
        end

        tr = {}
        Nx.db.char.Travel = tr
        tr.Version = Nx.VERSIONTRAVEL
    end

    tr["TaxiTime"] = tr["TaxiTime"] or {}

    local cd = Nx.db.char.Travel.Taxi

    if not cd or cd.Version < Nx.VERSIONCharData then
        cd = {}
        Nx.db.char.Travel.Taxi = cd
        cd.Version = Nx.VERSIONCharData
        cd["Taxi"] = {}        -- Taxi nodes we have
    end

    --

    -- Gather data

    local gath = Nx.db.profile.GatherData

    if not gath or gath.Version < Nx.VERSIONGATHER then

        if gath and gath.Version < 0 then
            Nx.DoGatherUpgrade = gath.Version

        else
            if gath then
                Nx.prt (L["Reset old gather data"] .. " %f", gath.Version)
            end

            gath = {}
            Nx.db.profile.GatherData = gath
            gath.NXHerb = {}
            gath.NXMine = {}
            gath.NXTimber = {}
        end

        gath.Version = Nx.VERSIONGATHER
    end

    gath["Misc"] = gath["Misc"] or {}
--    gath.NXGas = gath.NXGas or {}

    -- Capture data

    local cap = Nx.db.global.Capture        -- Keep NX

--    cap = nil        -- Nuke test

    if not cap or cap.Version < Nx.VERSIONCAP then

--        if cap then
--            Nx.prt ("Reset old cap %f", cap.Version)
--        end

        cap = {}
        Nx.db.global.Capture = cap
        cap.Version = Nx.VERSIONCAP
        cap["Q"] = {}

--        Nx.HUD:OptsReset()
    end

    cap["NPC"] = cap["NPC"] or {}
end

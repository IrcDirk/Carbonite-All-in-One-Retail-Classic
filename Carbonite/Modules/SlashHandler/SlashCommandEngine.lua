-- Carbonite | Modules / SlashHandler / SlashCommandEngine
-- The big elseif dispatcher behind /carb extracted from
-- Carbonite.lua. NXOnLoad still does
--    SlashCmdList["Carbonite"] = Nx.slashCommand
-- so the function stays on Nx by name.
--
-- The documented surface in SlashHandler.lua wraps newer slash
-- registration patterns; this file owns the original elseif chain.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

---
-- Parse and execute slash commands
-- @param txt  Command string following /carb
--
function Nx.slashCommand (txt)

    local UEvents = Nx.UEvents
    local cmd, a1, a2 = Nx.Split (" ", txt)
    cmd = strlower (cmd)

    a1 = a1 or ""
    a2 = a2 or ""

    if cmd == "" or cmd == "?" or cmd == "help" then

        Nx.prt ("Commands:")
        Nx.prt (" editmode  (toggle quest objective rectangle editor)")
        Nx.prt (" goto [zone] x y  (set map goto)")
        Nx.prt (" gotoadd [zone] x y  (add map goto)")
        Nx.prt (" menu  (open menu)")
        Nx.prt (" note [\"]name[\"] [zone] [x y]  (make map note)")
        Nx.prt (" options  (open options window)")
        Nx.prt (" resetwin  (reset window layouts)")
        Nx.prt (" rl  (reload UI)")
        Nx.prt (" track name  (track the player)")
        Nx.prt (" winpos name x y  (position a window)")
        Nx.prt (" winshow name [0/1]  (toggle or show a window)")
        Nx.prt (" winsize name w h  (size a window)")

    elseif cmd == "goto" then
        local map = Nx.Map:GetMap (1)
        local s = gsub (txt, "goto%s*", "")
        map:SetTargetAtStr (s)

    elseif cmd == "gotoadd" then
        local map = Nx.Map:GetMap (1)
        local s = gsub (txt, "gotoadd %s*", "")
        map:SetTargetAtStr (s, true)

    elseif cmd == "menu" then
        Nx.NXMiniMapBut:OpenMenu()

    elseif cmd == "options" then
        Nx.Opts:Open()

    elseif cmd == "resetwin" then
        Nx.Window:ResetLayouts()

    elseif cmd == "rl" then
        ReloadUI()

    elseif cmd == "track" then
        if a1 then
            local map = Nx.Map:GetMap (1)
            map.TrackPlyrs[a1] = true
        end

    elseif cmd == "winpos" then
        Nx.Window:ConsolePos (gsub (txt, "winpos %s*", ""))

    elseif cmd == "winshow" then
        Nx.Window:ConsoleShow (gsub (txt, "winshow %s*", ""))

    elseif cmd == "winsize" then
        Nx.Window:ConsoleSize (gsub (txt, "winsize %s*", ""))

    elseif cmd == "gatherd" then
        Nx.db.profile.Debug.DBGather = not Nx.db.profile.Debug.DBGather

    elseif cmd == "herb" then
        UEvents:AddHerb (strtrim (a1 .. " " .. a2))

    elseif cmd == "dbmapmax" then
        Nx.db.profile.Debug.DBMapMax = not Nx.db.profile.Debug.DBMapMax

    elseif cmd == "mine" then
        UEvents:AddMine (strtrim (a1 .. " " .. a2))

    elseif cmd == "addopen" then
        UEvents:AddOpen (a1, a2)

    elseif cmd == "cap" then
        Nx.CaptureItems()

    elseif cmd == "crash" then
        assert()

    elseif cmd == "com" then
        Nx.Com.List:Open()

    elseif cmd == "comd" then
        Nx.db.profile.Debug.DebugCom = not Nx.db.profile.Debug.DebugCom
        ReloadUI()

    elseif cmd == "comt" then
        Nx.Com:Test (a1, a2)

    elseif cmd == "comver" then
        if Nx.db.profile.Debug.VerDebug then        -- Stop casual use
            Nx.Com:GetUserVer()
        end

    elseif cmd == "d" then
        Nx.DebugOn = not Nx.DebugOn
        Nx.prt("Carbonite Debug: %s", Nx.DebugOn and "On" or "Off")

    elseif cmd == "dock" then
        Nx.db.profile.Debug.DebugDock = not Nx.db.profile.Debug.DebugDock

    elseif cmd == "events" then
        UEvents.List:Open()

    elseif cmd == "item" then
        local id = format ("Hitem:%s", a1)
        Nx.TooltipText:SetOwner (UIParent, "ANCHOR_LEFT", 0, 0)
        Nx.TooltipText:SetHyperlink (id)
        local name, iLink, iRarity, lvl, minLvl, type, subType, stackCount, equipLoc, tx = C_Item.GetItemInfo (id)
        Nx.prt ("Item: %s %s", name or "nil", iLink or "")

    elseif cmd == "kill" then
        UEvents:AddKill (a1)

    elseif cmd == "loot" then
        Nx.LootOn = not Nx.LootOn
        Nx.prt ("Loot %s", Nx.LootOn and "On" or "Off")

    elseif cmd == "mapd" then
        Nx.db.profile.Debug.DebugMap = not Nx.db.profile.Debug.DebugMap
        ReloadUI()

    elseif cmd == "questclr" then
        Nx.Quest:ClearCaptured()

    elseif cmd == "unitc" then
        Nx.db.profile.Debug.DebugUnit = true
        Nx:UnitDCapture()

    elseif cmd == "unitd" then
        Nx.db.profile.Debug.DebugUnit = not Nx.db.profile.Debug.DebugUnit

    elseif cmd == "vehpos" then
        Nx.Map:GetMap (1):VehicleDumpPos()

    elseif cmd == "editmode" then
        Nx.Map:GetMap(1):ToggleEditMode()

    else
        local s = gsub (txt, "note%s*", "")
        Nx:SendCommMessage("carbmodule","CMD|" .. cmd .. "|" .. s,"WHISPER",UnitName("player"))
    end
end

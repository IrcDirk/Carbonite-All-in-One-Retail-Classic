-- Carbonite.Notes | Init
-- AceAddon lifecycle for the CarboniteNotes plugin. OnInitialize
-- waits for the main Carbonite addon to be ready, creates the
-- AceDB profile (Nx.fdb), calls Nx.Notes:Init for state setup,
-- registers the minimap button, the map toolbar entry, the map
-- right-click "Add Note" menu, and the broker menu.
--
-- Also hosts the cross-addon ("CMD|note|<text>") message handler.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Notes", true)

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

-- AceDB defaults. Lives here because OnInitialize is the only
-- caller; the legacy code kept this as a file-local in NxFav.lua
-- but the whole init flow has moved here.
local defaults = {
    profile = {
        Notes = {
            ShowMap         = true,    -- Show user notes on map
            HandyNotes      = true,    -- Show HandyNotes integration
            HandyNotesSize  = 15,
            RareScanner     = true,    -- Show RareScanner integration
            RareScannerSize = 32,
            Questie         = false,   -- Show Questie quest objectives
            QuestieSE       = false,   -- Show Questie available quests
            QuestieSize     = 32,
            RXP             = true,    -- Show RXPGuides waypoint pins
            RXPSize         = 24,
        },
        Addons = {},
    },
}

---
-- AceAddon initialization callback. Defers itself with AceTimer
-- until the main Carbonite addon has finished its own init.
--
function CarboniteNotes:OnInitialize()
    if not Nx.Initialized then
        CarbNotesInit = Nx:ScheduleTimer(CarboniteNotes.OnInitialize, 1)
        return
    end

    Nx.fdb = LibStub("AceDB-3.0"):New("NXNotes", defaults, true)
    Nx.Notes:Init()

    CarboniteNotes:RegisterComm("carbmodule", Nx.Notes.OnChat_msg_addon)

    -- Map-toolbar button: the "Notes" toggle on the map header bar.
    Nx.Button.TypeData["MapFav"] = {
        Up     = "$INV_Torch_Lit",
        SizeUp = 22,
        SizeDn = 22,
    }

    -- Minimap button menu entry.
    Nx.NXMiniMapBut.Menu:AddItem(0, L["Show Notes"], function()
        Nx.Notes:ToggleShow()
    end, Nx.NXMiniMapBut)

    -- Register Notes as a per-frame icon-updating module.
    tinsert(Nx.ModuleUpdateIcon, "Notes")

    -- Toolbar button on the map header.
    tinsert(Nx.BarData, { "MapFav", L["-Notes-"], Nx.Notes.OnButToggleFav, false })

    -- Add-note entries on the map right-click + gather-icon menus.
    Nx.Map.Maps[1]:CreateToolBar()
    Nx.Map.Maps[1].Menu:AddItem(0, L["Add Note"], Nx.Notes.Menu_OnAddNote, Nx.Map.Maps[1])
    Nx.Map.Maps[1].GIconMenu:AddItem(0, L["Add Note"], Nx.Notes.Menu_OnAddNote, Nx.Map.Maps[1])

    -- Carbonite Options + LibDataBroker dropdown.
    Nx:AddToConfig("Notes Module", Nx.Notes:GetOptionsConfig(), L["Notes Module"])
    tinsert(Nx.BrokerMenuTemplate, {
        text = L["Toggle Notes"],
        func = function() Nx.Notes:ToggleShow() end,
    })
end

---
-- Handle incoming addon messages on the "carbmodule" channel.
-- Currently we only respond to "CMD|note|<text>" — a remote-add
-- note from another player using the same chat-string protocol.
--
function Nx.Notes:OnChat_msg_addon(msg, dist, target)
    local ssplit = { strsplit("|", msg) }
    if ssplit[1] == "CMD" and ssplit[2] == "note" then
        Nx.Notes:SetNoteAtStr(ssplit[3])
    end
end

---
-- Initialize Notes module state. Sets data version, loads folder
-- list, pre-populates the available-icon catalog, and hooks LOOT_CLOSED
-- so the list refreshes after gathering finishes.
--
function Nx.Notes:Init()
    local fav = Nx.fdb.profile.Notes

    if not fav or not fav.Version or fav.Version < Nx.VERSIONFAV then
        if fav and fav.Version then
            Nx.prt(L["Reset old notes data"] .. " %f", fav.Version)
        end
        fav = {}
        Nx.fdb.profile.Notes = fav
        fav.Version = Nx.VERSIONFAV
    end

    self.Folders         = Nx:GetFav()
    self.PrevQuestiePins = 0
    self.PrevRSPins      = 0

    -- Available note icons (raid markers, minimap icons, etc.)
    self.NoteIcons = {
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",   -- Star
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",   -- Circle
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",   -- Diamond
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",   -- Triangle
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",   -- Moon
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",   -- Square
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",   -- Cross
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",   -- Skull
        "Interface\\Minimap\\Tracking\\Auctioneer",
        "Interface\\Minimap\\Tracking\\Banker",
        "Interface\\Minimap\\Tracking\\BattleMaster",
        "Interface\\Minimap\\Tracking\\FlightMaster",
        "Interface\\Minimap\\Tracking\\Innkeeper",
        "Interface\\Minimap\\Tracking\\Mailbox",
        "Interface\\Minimap\\Tracking\\Repair",
        "Interface\\Minimap\\Tracking\\StableMaster",
        "Interface\\Minimap\\Tracking\\Class",
        "Interface\\Minimap\\Tracking\\Profession",
        "Interface\\Minimap\\Tracking\\TrivialQuests",
        "Interface\\Minimap\\Tracking\\Ammunition",
        "Interface\\Minimap\\Tracking\\Food",
        "Interface\\Minimap\\Tracking\\Poisons",
        "Interface\\Minimap\\Tracking\\Reagents",
        "Interface\\TargetingFrame\\UI-PVP-Alliance",
        "Interface\\TargetingFrame\\UI-PVP-Horde",
        "Interface\\TargetingFrame\\UI-PVP-FFA",
        "Interface\\PVPFrame\\PVP-ArenaPoints-Icon",
        "Interface\\Icons\\Spell_Arcane_PortalDalaran",
    }

    CarboniteNotes:RegisterEvent("LOOT_CLOSED", function() Nx.Notes:Update() end)
end

-- Inline-tooltip-style texture string for a stored icon index.
function Nx.Notes:GetIconInline(index)
    local file = self.NoteIcons[index]
    return format("|T%s:16|t", file)
end

-- Raw file path for a stored icon index.
function Nx.Notes:GetIconFile(index)
    return self.NoteIcons[index]
end

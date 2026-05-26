-- Carbonite | Modules / Whatsnew / WhatsnewEngine
-- The legacy "What's New" changelog window engine, extracted from
-- Carbonite.lua. Owns:
--   * the Nx.Whatsnew data table (categories + per-category dated
--     changelog entries)
--   * Nx.WhatsNewUnread() (reads against Nx.db.profile.Whatsnew.lastreadtime)
--   * Nx.Whatsnew:ToggleShow / :Create / :Recordtime / :Cat_button /
--     :OnListEvent / :Update
--
-- The new Whatsnew module (Whatsnew.lua) and its public surface
-- (WhatsnewWindow.lua) already proxy through Nx.Whatsnew; nothing
-- changes from their side beyond seeing the data populated by this
-- file at load time instead of by Carbonite.lua.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-------------------------------------------------------------------------------
-- Data: changelog categories and entries
-------------------------------------------------------------------------------

Nx.Whatsnew = {}
Nx.Whatsnew.Categories = {"Maps"}
Nx.Whatsnew.Maps = {
    [1568657164] = {
        "Sept 16th 2019", "",
        "This is Alpha version of Carbonite Classic, all bugs/issues please report to",
        "GitHub repo: https://github.com/IrcDirk/Carbonite-Classic."
    },
    [1653631200] = {
        "May 27th 2022", "",
        "Fixed map path generation using FlightMasters",
        "Fixed HandyNotes icons disappearing while standing still",
        "Fixed Carbonite Map causing errors while trying to open map in combat",
        "Fixed Carbonite maps going out while traveling between islands/subcontinents in Kalimdor/Eastern Kingdoms/Outlands",
        "Fixed Warehouse module not showing equipped wands",
        "Add tracking of goods bought in Auction House in Warehouse module",
        "Add localizations for various strings (need translators for some languages)",
        "Updated translations for some of the Carbonite modules"
    },
    [1660510987] = {
        "Aug 14th 2022", "",
        "Implemented WotLK Classic support for Pre-patch",
        "Updated Flight Masters data",
        "Updated Flight Masters locales for DE,ES,FR,KO,PT,RU,TW Languages",
        "Fixed various small errors caused by division by zero."
    },
    [1779796800] = {
        "May 26th 2026", "",
        "New map rendering engine (Pin / Layer system plus a",
        "   Map Provider API) that third-party add-ons can",
        "   plug into",
        "",
        "Added Carbonite-map integrations for Questie,",
        "   HandyNotes and RareScanner, each with a toolbar",
        "   toggle button and localized tooltips",
        "",
        "Added RXPGuides integration: its step waypoints now",
        "   show on the Carbonite map, and its navigation",
        "   arrow can be routed through Carbonite's own travel",
        "   arrow with the current step's description (new",
        "   option in the Notes settings)",
        "",
        "Retail & Mists quest database overhaul: rewrote",
        "   ~13,400 outdated map IDs and backfilled ~8,400",
        "   missing quest turn-in points and ~1,500 objective",
        "   locations",
        "",
        "Quest tracking fixes: smoother tracking arrow,",
        "   track-to-end, multi-zone objective handling,",
        "   fewer combat crashes, and a reliable \"?\"",
        "   auto-complete button",
        "",
        "Fixed map icon flickering (world-quest and",
        "   bonus-objective icons blinking on retail)",
        "",
        "Instance maps: correct icon sizing plus",
        "   boss-encounter pins from the Encounter Journal",
        "",
        "Performance: removed per-frame memory allocations in",
        "   path building and the main update loop; pooled",
        "   POIs and throttled title updates",
        "",
        "Various tooltip taint, clipping and localization",
        "   fixes"
    }
}
Nx.Whatsnew.WhichCat = 1
Nx.Whatsnew.HasWhatsNew = nil

-------------------------------------------------------------------------------
-- Unread check (called from Carbonite.lua's NXOnUpdate; kept as Nx.*)
-------------------------------------------------------------------------------

--- Return true if any changelog entry is newer than the saved
--- last-read timestamp.
function Nx:WhatsNewUnread()
    for _, b in pairs(Nx.Whatsnew.Categories) do
        for c in pairs(Nx.Whatsnew[b]) do
            if Nx.db.profile.Whatsnew.lastreadtime < c then
                return true
            end
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- Window
-------------------------------------------------------------------------------

--- Toggle the window's visible state, creating it on first call.
function Nx.Whatsnew:ToggleShow()
    if not self.Win then
        self:Create()
    end

    self.Win:Show(not self.Win:IsShown())

    if self.Win:IsShown() then
        self:Update()
    end
end

--- Build the What's New window: two-pane list view with category
--- buttons across the top.
function Nx.Whatsnew:Create()
    local win = Nx.Window:Create("NxWhatsNew", nil, nil, nil, 1)
    self.Win = win
    self.SelectedLine = 1
    win.Frm.NxInst = self
    win:CreateButtons(true, true)
    win:InitLayoutData(nil, -.25, -.15, -.5, -.6)
    win.Frm:SetToplevel(true)
    win:Show(false)
    -- Note: closing the window no longer marks the update read. Only
    -- the explicit "Don't show this update again" button dismisses it,
    -- so the window keeps popping each login until the player opts out.
    tinsert(UISpecialFrames, win.Frm:GetName())

    Nx.List:SetCreateFont("Font.Medium", 16)

    -- Left list: dated entry index for the currently selected category.
    local list = Nx.List:Create(false, 0, 0, 1, 1, win.Frm)
    self.List = list
    list:SetUser(self, self.OnListEvent)
    list:SetLineHeight(4)
    list:ColumnAdd("", 1, 24)
    list:ColumnAdd("Date", 2, 200)
    list:SetUser(self, self.OnListEvent)
    win:Attach(list.Frm, 0, .2, 0, .94)

    -- Right list: lines of the selected entry.
    local detail = Nx.List:Create(false, 0, 0, 1, 1, win.Frm)
    self.WhatsNewList = detail
    detail:ColumnAdd("", 1, 500)
    win:Attach(detail.Frm, .2, 1, 0, .94)

    -- Category-selector buttons across the top.
    local _, bh = win:GetBorderSize()
    local pos = 150
    for i, name in pairs(Nx.Whatsnew.Categories) do
        local function func() Nx.Whatsnew:Cat_button(i) end
        local but = Nx.Button:Create(win.Frm, "Txt64", name, nil, pos, -bh, "TOPLEFT",
            string.len(name) * 10, 20, func, self)
        pos = pos + but.Frm:GetWidth()
    end

    -- "Don't show this update again" button, bottom-left of the window.
    -- Dismisses the current changelog so it won't auto-pop again until
    -- a newer entry is added.
    local dismissText = L["Don't show for this update again"]
    Nx.Button:Create(win.Frm, "Txt64", dismissText, nil, 12, bh, "BOTTOMLEFT",
        string.len(dismissText) * 8 + 20, 22,
        function() Nx.Whatsnew:DismissUpdate() end, self)

    self:Update()
    self.List:Select(0)
    self.List:FullUpdate()
end

--- Record current time as last-read; clear the minimap-button glow.
function Nx.Whatsnew:Recordtime()
    Nx.db.profile.Whatsnew.lastreadtime = time()
    NXMiniMapBut:SetNormalTexture("Interface\\AddOns\\Carbonite\\Gfx\\MMBut")
end

--- Highest changelog timestamp across all categories.
function Nx.Whatsnew:GetMaxTime()
    local maxTs = 0
    for _, cat in pairs(Nx.Whatsnew.Categories) do
        for ts in pairs(Nx.Whatsnew[cat] or {}) do
            if ts > maxTs then maxTs = ts end
        end
    end
    return maxTs
end

--- True once the player has dismissed the current changelog: lastreadtime
--- equals the newest entry's timestamp. Using equality (not <) means the
--- auto-show fires until the player opts out, and any newer entry (a
--- bigger max timestamp) re-arms it.
function Nx.Whatsnew:DismissedCurrent()
    return (Nx.db.profile.Whatsnew.lastreadtime or 0) == self:GetMaxTime()
end

--- "Don't show this update again": pin lastreadtime to the newest entry
--- so the window stops auto-popping until a newer changelog is added.
function Nx.Whatsnew:DismissUpdate()
    Nx.db.profile.Whatsnew.lastreadtime = self:GetMaxTime()
    NXMiniMapBut:SetNormalTexture("Interface\\AddOns\\Carbonite\\Gfx\\MMBut")
    if self.Win then self.Win:Show(false) end
end

--- Switch to category N (1-based index into Nx.Whatsnew.Categories).
function Nx.Whatsnew:Cat_button(num)
    Nx.Whatsnew.WhichCat = num
    Nx.Whatsnew.SelectedLine = 1
    Nx.Whatsnew:Update()
end

--- List click handler: store selection, refresh the detail pane.
function Nx.Whatsnew:OnListEvent(eventName, sel)
    local data = self.List:ItemGetData(sel) or 0
    self.SelectedLine = data % 1000
    if eventName == "select" then
        self:Update()
    end
end

--- Redraw both panes for the current category + selection.
function Nx.Whatsnew:Update()
    self.Win:SetTitle(L["Carbonite What's New"])

    local list = self.List
    list:Empty()
    local cnt = 1
    local display = {}
    local cat = Nx.Whatsnew.Categories[Nx.Whatsnew.WhichCat]
    -- Numeric timestamp keys: pairs() yields them in hash order, so
    -- sort newest-first before listing or the dates come out jumbled.
    local entries = Nx.Whatsnew[cat] or {}
    local keys = {}
    for ts in pairs(entries) do keys[#keys + 1] = ts end
    table.sort(keys, function(a, b) return a > b end)
    for _, ts in ipairs(keys) do
        list:ItemAdd(cnt)
        list:ItemSet(2, date("%m/%d/%y", ts))
        if cnt == self.SelectedLine then
            display = entries[ts]
        end
        cnt = cnt + 1
    end
    list:Update()

    list = self.WhatsNewList
    list:Empty()
    cnt = 1
    -- ipairs: the entry's lines are an ordered array; pairs() would
    -- shuffle them.
    for _, line in ipairs(display) do
        list:ItemAdd(cnt)
        list:ItemSet(1, line)
        cnt = cnt + 1
    end
    list:Update()
end

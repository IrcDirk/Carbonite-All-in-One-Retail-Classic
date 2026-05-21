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
    win.Frm:SetScript("OnHide", self.Recordtime)
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
    win:Attach(list.Frm, 0, .2, 0, 1)

    -- Right list: lines of the selected entry.
    local detail = Nx.List:Create(false, 0, 0, 1, 1, win.Frm)
    self.WhatsNewList = detail
    detail:ColumnAdd("", 1, 500)
    win:Attach(detail.Frm, .2, 1, 0, 1)

    -- Category-selector buttons across the top.
    local _, bh = win:GetBorderSize()
    local pos = 150
    for i, name in pairs(Nx.Whatsnew.Categories) do
        local function func() Nx.Whatsnew:Cat_button(i) end
        local but = Nx.Button:Create(win.Frm, "Txt64", name, nil, pos, -bh, "TOPLEFT",
            string.len(name) * 10, 20, func, self)
        pos = pos + but.Frm:GetWidth()
    end

    self:Update()
    self.List:Select(0)
    self.List:FullUpdate()
end

--- Record current time as last-read; clear the minimap-button glow.
function Nx.Whatsnew:Recordtime()
    Nx.db.profile.Whatsnew.lastreadtime = time()
    NXMiniMapBut:SetNormalTexture("Interface\\AddOns\\Carbonite\\Gfx\\MMBut")
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
    for ts, entry in pairs(Nx.Whatsnew[cat]) do
        list:ItemAdd(cnt)
        list:ItemSet(2, date("%m/%d/%y", ts))
        if cnt == self.SelectedLine then
            display = entry
        end
        cnt = cnt + 1
    end
    list:Update()

    list = self.WhatsNewList
    list:Empty()
    cnt = 1
    for _, line in pairs(display) do
        list:ItemAdd(cnt)
        list:ItemSet(1, line)
        cnt = cnt + 1
    end
    list:Update()
end

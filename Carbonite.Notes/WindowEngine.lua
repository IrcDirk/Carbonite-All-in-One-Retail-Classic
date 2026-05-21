-- Carbonite.Notes | WindowEngine
-- The entire notes window: layout, button handlers, right-click
-- menus, list-event routing, and the per-frame UI refresh path
-- (Update / UpdateFolder / UpdateItems / AddonFolders).
--
-- This is the bulky end of NxFav.lua. Everything in this file
-- references Nx.Notes state set up by Init.lua (Folders, NoteIcons,
-- safecall) and by Storage.lua (ParseItem / ParseItemNote /
-- ParseItemTarget / AddFolder / AddFavorite / etc.).

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Notes", true)

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

-- Convenience locals for hot-path use.
local safecall  = Nx.Notes.safecall
local addonNotes = Nx.Notes.addonNotes

-- -------------------------------------------------------------------
-- HandyNotes pin handlers
--   Used by Create() (legacy) when wiring per-pin mouse handlers.
-- -------------------------------------------------------------------

local handypin = {}

function handypin:OnEnter(motion)
    WorldMapBlobFrame:SetScript("OnUpdate", nil)
    safecall(HandyNotes.plugins[self.pluginName].OnEnter, self, self.mapFile, self.coord)
end

function handypin:OnLeave(motion)
    WorldMapBlobFrame:SetScript("OnUpdate", WorldMapBlobFrame_OnUpdate)
    safecall(HandyNotes.plugins[self.pluginName].OnLeave, self, self.mapFile, self.coord)
end

-- -------------------------------------------------------------------
-- Window creation
-- -------------------------------------------------------------------

function Nx.Notes:Create()
    self.Side = 1

    local win = Nx.Window:Create("NxFav", 240, nil, nil, 1)
    self.Win = win
    win.Frm.NxInst = self

    win:CreateButtons(true, true)
    win:SetTitleLineH(18)
    win:SetTitleXOff(220)

    win:InitLayoutData(nil, -.23, -.25, -.54, -.5)
    win.Frm:SetToplevel(true)
    win:Show(false)

    tinsert(UISpecialFrames, win.Frm:GetName())

    local bw, bh = win:GetBorderSize()

    -- Header buttons.
    local recBut = Nx.Button:Create(win.Frm, "Txt64B", L["Record"], nil,
                                    bw + 1, -bh, "TOPLEFT", 44, 20,
                                    self.But_OnRecord, self)
    self.RecBut = recBut

    local upBut = Nx.Button:Create(win.Frm, "Txt64", L["Up"], nil,
                                   bw + 48, -bh, "TOPLEFT", 40, 20,
                                   self.But_OnUp, self)
    local dnBut = Nx.Button:Create(upBut.Frm, "Txt64", L["Down"], nil,
                                   42, 0, "TOPLEFT", 40, 20,
                                   self.But_OnDown, self)
    Nx.Button:Create(dnBut.Frm, "Txt64", L["Delete Item"], nil,
                     54, 0, "TOPLEFT", 72, 20, self.But_OnItemDel, self)

    -- Folder list (left side).
    Nx.List:SetCreateFont("Font.Medium", 16)
    local list = Nx.List:Create("FavF", 0, 0, 1, 1, win.Frm)
    self.List = list
    list:SetUser(self, self.OnListEvent)
    list:SetLineHeight(4)
    list:ColumnAdd("", 1, 20)
    list:ColumnAdd(L["Name"], 2, 900)
    win:Attach(list.Frm, 0, .3, 0, 1)

    -- Item list (right side).
    Nx.List:SetCreateFont("Font.Medium", 16)
    list = Nx.List:Create("FavI", 0, 0, 1, 1, win.Frm)
    self.ItemList = list
    list:SetUser(self, self.OnItemListEvent)
    list:SetLineHeight(2)
    list:ColumnAdd("", 1, 17)
    list:ColumnAdd(L["Type"], 2, 90)
    list:ColumnAdd(L["Value"], 3, 250)
    list:ColumnAdd(L["Location"], 4, 900)
    win:Attach(list.Frm, .3, 1, 0, 1)

    self:CreateMenu()
    self:Update()
    self.List:FullUpdate()
end

-- -------------------------------------------------------------------
-- Recording buttons
-- -------------------------------------------------------------------

function Nx.Notes:But_OnRecord(but)
    self:SetRecord(but:GetPressed())
end

function Nx.Notes:SetRecord(on)
    local but = self.RecBut
    if on then
        if self.CurFav then
            self.Recording   = self.CurFav
            self.RecAlphaAnim = 1000
            self.FavRec      = Nx:ScheduleRepeatingTimer(self.RecordAnimTimer, 0.1, self)
            but:SetPressed(true)
        else
            Nx.prt(L["Select a favorite before recording"])
            but:SetPressed(false)
        end
    else
        Nx:CancelTimer(self.FavRec)
        self.Recording = nil
        but:SetAlpha(1)
        but:SetPressed(false)
    end
end

function Nx.Notes:RecordAnimTimer()
    if self.Recording then
        local a = (self.RecAlphaAnim - 35) % 1000
        self.RecAlphaAnim = a
        self.RecBut:SetAlpha(abs(a - 500) / 1000 + .5)
    end
end

function Nx.Notes:But_OnUp()    self:MoveCur(true) end
function Nx.Notes:But_OnDown()  self:MoveCur()     end

function Nx.Notes:MoveCur(low)
    if self.Side == 1 then
        local item = self.CurFavOrFolder
        if item then
            local parent = self:GetParent(item)
            Nx.Util_TMoveItem(parent, item, low)
            local i = self:FindListI(item)
            if i > 0 then
                self.List:Select(i + 1)        -- add one for "Root" entry
            end
        end
    else
        local fav = self.CurFav
        if fav and self.CurItemI then
            local i = Nx.Util_TMoveI(fav, self.CurItemI, low)
            if i then
                self.CurItemI = i
                self.ItemList:Select(i)
            end
        end
    end
    self:Update()
end

function Nx.Notes:But_OnItemDel()
    local fav = self.CurFav
    if fav and self.CurItemI and fav[self.CurItemI] then
        tremove(fav, self.CurItemI)
    end
    self:Update()
end

-- -------------------------------------------------------------------
-- Right-click menus (folder list + item list)
-- -------------------------------------------------------------------

function Nx.Notes:CreateMenu()
    local menu = Nx.Menu:Create(self.List.Frm, 250)
    self.Menu = menu
    menu:AddItem(0, L["Add Folder"],    self.Menu_OnAddFolder,    self)
    menu:AddItem(0, L["Add Favorite"],  self.Menu_OnAddFavorite,  self)
    menu:AddItem(0, "")
    menu:AddItem(0, L["Rename"],        self.Menu_OnRename,       self)
    menu:AddItem(0, L["Cut"],           self.Menu_OnCut,          self)
    menu:AddItem(0, L["Copy"],          self.Menu_OnCopy,         self)
    menu:AddItem(0, L["Paste"],         self.Menu_OnPaste,        self)
    menu:AddItem(0, "")
    menu:AddItem(0, L["Options"] .. "...", function() Nx.Opts:Open("Favorites") end)

    menu = Nx.Menu:Create(self.List.Frm, 250)
    self.ItemMenu = menu
    menu:AddItem(0, L["Add Comment"],   self.IMenu_OnAddComment,  self)
    menu:AddItem(0, "")
    menu:AddItem(0, L["Rename"],        self.IMenu_OnRename,      self)
    menu:AddItem(0, L["Cut"],           self.IMenu_OnCut,         self)
    menu:AddItem(0, L["Copy"],          self.IMenu_OnCopy,        self)
    menu:AddItem(0, L["Paste"],         self.IMenu_OnPaste,       self)
    menu:AddItem(0, "")
    menu:AddItem(0, L["Set Icon"],      self.IMenu_OnSetIcon,     self)
end

function Nx.Notes:Menu_OnAddFolder(item)
    Nx:ShowEditBox(L["Name"], "", self, function(str, ctx)
        ctx:AddFolder(str, ctx.CurFolder)
        ctx:Update()
    end)
end

function Nx.Notes:Menu_OnAddFavorite(item)
    Nx:ShowEditBox(L["Name"], "", self, function(str, ctx)
        ctx:AddFavorite(str, ctx.CurFolder)
        ctx:Update()
    end)
end

function Nx.Notes:Menu_OnRename(item)
    if not self.CurFavOrFolder then return end
    local name = self.CurFavOrFolder["Name"]
    Nx:ShowEditBox(L["Name"], name, self, function(str, ctx)
        if ctx.CurFavOrFolder then
            ctx.CurFavOrFolder["Name"] = str
            ctx:Update()
        end
    end)
end

function Nx.Notes:Menu_OnCut()
    local item = self.CurFavOrFolder
    if not item then return end
    local parent = self:GetParent(item)
    for i, it in ipairs(parent) do
        if it == item then
            tremove(parent, i)
            self.CopyBuf = item
            self:Update()
        end
    end
    self:SelectCur()
end

function Nx.Notes:Menu_OnCopy()
    local item = self.CurFavOrFolder
    if item then
        self.CopyBuf = Nx.Util_TCopyRecurse(item)
    end
end

function Nx.Notes:Menu_OnPaste()
    if not self.CopyBuf then
        Nx.prt(L["Nothing to paste"])
        return
    end
    if type(self.CopyBuf) ~= "table" then
        Nx.prt(L["Can't paste that on the left side"])
        return
    end

    local new  = Nx.Util_TCopyRecurse(self.CopyBuf)
    local item = self.CurFav

    if item then
        local parent = self:GetParent(item)
        local i = Nx.Util_TFindItemI(parent, item)
        tinsert(parent, i, new)
    else
        tinsert(self.CurFolder, 1, new)
    end

    self:Update()
    self:SelectCur()
end

-- ---- Item menu (right list)

function Nx.Notes:IMenu_OnAddComment()
    Nx:ShowEditBox(L["Name"], "", self, function(str, ctx)
        local s = ctx:CreateItem("", 0, str)
        ctx:AddItem(ctx.CurFav, ctx.CurItemI, s)
    end)
end

function Nx.Notes:IMenu_OnRename()
    local _, name = self:GetItemTypeName(self.CurItemI)
    Nx:ShowEditBox(L["Name"], name, self, function(str, ctx)
        if ctx.CurFavOrFolder then
            ctx:SetItemName(ctx.CurItemI, str)
            ctx:Update()
        end
    end)
end

function Nx.Notes:IMenu_OnCut()
    local fav = self.CurFav
    if fav and self.CurItemI and fav[self.CurItemI] then
        self.CopyBuf = fav[self.CurItemI]
        tremove(fav, self.CurItemI)
    end
    self:Update()
end

function Nx.Notes:IMenu_OnCopy()
    local fav = self.CurFav
    if fav then self.CopyBuf = fav[self.CurItemI] end
end

function Nx.Notes:IMenu_OnPaste()
    if not self.CopyBuf then
        Nx.prt(L["Nothing to paste"])
        return
    end
    if type(self.CopyBuf) ~= "string" then
        Nx.prt(L["Can't paste that on the right side"])
        return
    end
    local fav = self.CurFav
    if fav then
        local i = min(self.CurItemI, #fav) + 1
        tinsert(fav, i, self.CopyBuf)
    end
    self:Update()
end

function Nx.Notes:IMenu_OnSetIcon()
    Nx.DropDown:Start(self, self.SetIconAccept)
    for i in ipairs(self.NoteIcons) do
        Nx.DropDown:Add(self:GetIconInline(i), false)
    end
    Nx.DropDown:Show(self.Win.Frm)
end

function Nx.Notes:SetIconAccept(name, sel)
    local fav   = self.CurFav
    local index = self.CurItemI
    if not (fav and index) then return end

    local item = fav[index]
    local typ, flags, _name, data = self:ParseItem(item)
    flags = strbyte(flags) - 35

    if typ == "N" then
        local _, id, x, y, level = self:ParseItemNote(data)
        fav[index] = self:CreateItem("N", flags, _name, sel, id, x, y, level)
        self:Update()
    end
end

-- -------------------------------------------------------------------
-- Window visibility / edit-box passthrough
-- -------------------------------------------------------------------

function Nx:NXFavKeyToggleShow()
    Nx.Notes:ToggleShow()
end

function Nx.Notes:ToggleShow()
    if not self.Win then self:Create() end
    self.Win:Show(not self.Win:IsShown())
    if self.Win:IsShown() then self:Update() end
end

function Nx.Notes:OnEditBox(editbox, message)
    if message == "Changed" then self:Update() end
end

-- -------------------------------------------------------------------
-- List-row event handlers
-- -------------------------------------------------------------------

function Nx.Notes:OnListEvent(eventName, sel, val2, click)
    local data = self.List:ItemGetData(sel)

    if not data then
        self.CurFolder = self.Folders
        self.CurFav    = nil
    else
        if data["T"] == "F" then
            self.CurFolder = data
            self.CurFav    = nil
        else
            self.CurFolder = self:GetParent(data)
            self.CurFav    = data
            self:SelectItems(1)
        end
    end

    self.CurFavOrFolder = data   -- nil at root
    self.Side = 1

    if eventName == "select" or eventName == "mid" or eventName == "menu" then
        if eventName == "menu" then
            if type(self.CurFav) == "string" then
                self.Menu:Show(-1)
            else
                self.Menu:Show(1)
            end
            self.Menu:Open()
        end
        self:Update()

    elseif eventName == "button" then
        self.List:Select(sel)
        if data then
            if type(data) == "string" then data = addonNotes end
            data["Hide"] = not data["Hide"] and true or nil
            self:Update()
        end
    end
end

function Nx.Notes:OnItemListEvent(eventName, sel, val2, click)
    local list = self.ItemList
    local item = list:ItemGetData(sel)

    self.CurItemI = sel
    self.Side     = 2

    if eventName == "select" or eventName == "mid" or eventName == "menu" then
        if eventName == "menu" then
            self.ItemMenu:Show(self.CurFav and true or -1)
            if type(self.CurFav) == "string" then
                self.ItemMenu:Show(-1)
            end
            self.ItemMenu:Open()
        end

    elseif eventName == "button" then
        local flags = val2 and 1 or 0    -- pressed
        self:SetItemFlags(sel, 0xfe, flags)
    end

    self:SelectItems(sel)
    self:Update()
end

-- -------------------------------------------------------------------
-- Window refresh (left list + right list + title)
-- -------------------------------------------------------------------

function Nx.Notes:Update()
    self.Draw = false   -- force the map to re-render icons

    if not self.Win then return end

    local list = self.List
    list:Empty()
    list:ItemAdd()
    list:ItemSet(2, "|cff808080Root")

    self.FavCnt = 0
    self:UpdateFolder(self.Folders, 1)
    self:AddonFolders(1)
    list:Update()

    self:UpdateItems()
    self.Win:SetTitle(format(L["Notes"] .. ": %s", self.FavCnt))
end

function Nx.Notes:AddonFolders(level)
    local list = self.List
    local hide = addonNotes.Hide
    list:ItemAdd("addons")
    list:ItemSet(2, "  " .. L["Note Addons"])
    list:ItemSetButton("QuestHdr", hide)

    if hide then return end

    for a in pairs(addonNotes) do
        if a ~= "Hide" then
            local space = strrep("  ", level + 1)
            list:ItemAdd(a)
            list:ItemSet(2, format("%s|cffdfdfdf%s", space, a))
        end
    end
end

function Nx.Notes:UpdateFolder(folder, level)
    local list = self.List
    local hide = folder["Hide"]

    if level > 1 then
        list:ItemAdd(folder)
        local space = strrep("  ", level - 1)
        list:ItemSet(2, format("%s%s", space, folder["Name"]))
        list:ItemSetButton("QuestHdr", hide)
    end

    if hide then return end

    local space = strrep("  ", level)
    for _, item in ipairs(folder) do
        local typ  = item["T"]
        local name = item["Name"]
        if typ == "F" then
            self:UpdateFolder(item, level + 1)
        else
            self.FavCnt = self.FavCnt + 1
            list:ItemAdd(item)
            list:ItemSet(2, format("%s|cffdfdfdf%s", space, name))

            if self.FavToSelect == item then
                self.FavToSelect = nil
                list:Select(list:ItemGetNum())
            end
        end
    end
end

function Nx.Notes:UpdateItems(selectI)
    local list = self.ItemList
    if not list then return end

    list:Empty()

    if self.CurFav then
        if type(self.CurFav) == "string" then
            if self.CurFav == "addons" then
                selectI = 0
            elseif self.CurFav ~= "Hide" and addonNotes[self.CurFav] then
                for name, data in pairs(addonNotes[self.CurFav]["notes"]) do
                    list:ItemAdd(nil)
                    local icon, id, x, y, level = self:ParseItemNote(data)
                    icon = self:GetIconInline(icon)
                    id = Nx.Map:GetMapNameByID(id) or "?"
                    list:ItemSet(2, "Note:")
                    list:ItemSet(3, format("%s %s", icon, name))
                    list:ItemSet(4, format("|cff80ef80(%s %.1f %.1f)", id, x, y))
                end
            end
        else
            for _, str in ipairs(self.CurFav) do
                local typ, flags, name, data = self:ParseItem(str)
                list:ItemAdd(nil)
                list:ItemSetButton("Chk", bit.band(strbyte(flags) - 35, 1) > 0)

                if typ == "" then            -- comment
                    list:ItemSet(3, format("|cffa0a0a0-- %s", name))
                elseif typ == "N" then       -- note
                    local icon, id, x, y, level = self:ParseItemNote(data)
                    icon = self:GetIconInline(icon)
                    local newid = Nx.Map:GetMapNameByID(id) or "?"
                    list:ItemSet(2, L["Note"] .. ":")
                    list:ItemSet(3, format("%s %s", icon, name))
                    list:ItemSet(4, format("|cff80ef80(%s %.1f %.1f)", newid, x, y))
                elseif typ == "T" or typ == "t" then  -- target
                    local typName = (typ == "T") and "Target 1st" or "Target"
                    local mapId, x, y = self:ParseItemTarget(data)
                    local mapName = Nx.Map:GetMapNameByID(mapId) or "?"
                    list:ItemSet(2, format("%s:", typName))
                    list:ItemSet(3, format("%s", name))
                    list:ItemSet(4, format("|cff80ef80(%s %.1f %.1f)", mapName, x, y))
                end
            end
        end
    end

    if selectI then list:Select(selectI) end
    list:Update()
end

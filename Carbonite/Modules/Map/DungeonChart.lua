local Nx = _G.Nx
if not Nx then return end

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

local DC = {}
Nx.DungeonChart = DC

local BAR_H = 22
local ART_W, ART_H = 1002, 668
local MAX_ZOOM = 6

local function Fojji()
    local ns = _G.FojjiCoreNS
    local dj = ns and ns.DJ
    if dj and dj.Chart and dj.Chart.New and dj.Dungeons and dj.CurrentDungeon then return dj end
end

local function DJ()
    local ns = _G.ForeverDungeonJournal_NS
    if ns and type(ns.DUNGEON_MAPS) == "table" and ns.CurrentDungeon then return ns end
end

local function loadable(name)
    return C_AddOns and C_AddOns.IsAddOnLoadable and C_AddOns.IsAddOnLoadable(name) or false
end

local function prefs()
    local map = Nx.db and Nx.db.profile and Nx.db.profile.Map
    if map and map.DungeonChartAuto == nil then map.DungeonChartAuto = true end
    return map or {}
end

local function source()
    local fojji, dj = Fojji(), DJ()
    if dj and (prefs().DungeonChartUseDJ or not fojji) then return "dj", dj end
    if fojji then return "fojji", fojji end
end

local function djText(dj, key, ...)
    if dj.L then
        local ok, s = pcall(dj.L, key, ...)
        if ok and type(s) == "string" and s ~= key then return s end
    end
end

local function djName(dj, name)
    if dj.LocalizeDungeonName then
        local ok, s = pcall(dj.LocalizeDungeonName, name)
        if ok and type(s) == "string" and s ~= "" then return s end
    end
    return name
end

local function djBoss(dj, name)
    if dj.LocalizeBossName then
        local ok, s = pcall(dj.LocalizeBossName, name)
        if ok and type(s) == "string" and s ~= "" then return s end
    end
    return name
end

local function djFloorLabel(dj, n)
    return djText(dj, "MAP_FLOOR", n) or format("%s %d", LEVEL, n)
end

local function fojjiTitle(fojji, d)
    if fojji.DungeonTitle then return fojji.DungeonTitle(d) end
    return d.family and (d.family .. ": " .. d.name) or d.name
end

local function fojjiFloor(fojji, d)
    local runs = fojji.Runs
    for _, boss in ipairs(d.bosses or {}) do
        if not boss.rare and not (runs and runs.Killed and runs.Killed(boss)) then return boss.f or 1 end
    end
    return 1
end

local function nativeInstanceMap()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then return end
    local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or not id or (_G.issecretvalue and _G.issecretvalue(id)) then return end
    local okInfo, info = pcall(C_Map.GetMapInfo, id)
    local dungeonType = Enum and Enum.UIMapType and Enum.UIMapType.Dungeon or 4
    if not (okInfo and info and info.mapType == dungeonType) then return end
    local okArt, layer = pcall(Nx.Map.GetInstanceMapArt, Nx.Map, id)
    if okArt and layer then return id end
end

function DC:Refresh()
    local here = {}
    local native = nativeInstanceMap()
    self.Native = native
    if native and not (self.NativeSeen and self.NativeSeen[native]) then
        self.NativeSeen = self.NativeSeen or {}
        self.NativeSeen[native] = true
        Nx.prt(L["The game now provides a map for this dungeon (map %d)"], native)
    end
    local fojji, dj = Fojji(), DJ()
    if fojji then
        local ok, d = pcall(fojji.CurrentDungeon)
        here.fojji = ok and d or nil
    end
    if dj then
        local ok, name = pcall(dj.CurrentDungeon)
        here.dj = ok and name and dj.DUNGEON_MAPS[name] and name or nil
    end
    local old = self.Here or {}
    if here.fojji ~= old.fojji or here.dj ~= old.dj then
        self.Dismissed = nil
    end
    self.Here = here
    self.Dirty = true
end

function DC:Current(src)
    if self.Browse then
        return self.Browse.src == src and self.Browse.value or nil
    end
    if self.Native then return nil end
    local here = self.Here and self.Here[src]
    if here and not self.Dismissed and prefs().DungeonChartAuto then return here end
end

function DC:Open(src, value)
    self.Browse = { src = src, value = value }
    self.Dirty = true
end

function DC:Close()
    if self.Browse then
        self.Browse = nil
    else
        self.Dismissed = true
    end
    self.Dirty = true
end

function DC:OpenPicker()
    local src, api = source()
    if not src then
        Nx.prt(L["No dungeon map addon is loaded"])
        return
    end
    self.PickMenu = self.PickMenu or Nx.Menu:Create(UIParent, 260)
    local menu = self.PickMenu
    menu.Items = {}
    local current = self:Current(src)
    if src == "fojji" then
        local family
        for _, d in ipairs(api.Dungeons) do
            if d.family and d.family ~= family then
                menu:AddItem(0, "|cffffd100" .. d.family)
            end
            family = d.family
            local range = d.range and ("  |cff9d9d9d" .. d.range[1] .. "-" .. d.range[2]) or ""
            local item = menu:AddItem(0, (d.family and ("  " .. d.name) or d.name) .. range, function() DC:Open("fojji", d) end)
            if d == current then item:SetChecked(true) end
        end
    else
        local names, seen = {}, {}
        local ok, list = false, nil
        if api.DungeonNavList then ok, list = pcall(api.DungeonNavList) end
        for _, name in ipairs(ok and type(list) == "table" and list or {}) do
            if api.DUNGEON_MAPS[name] and not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
        local rest = {}
        for name in pairs(api.DUNGEON_MAPS) do
            if not seen[name] then rest[#rest + 1] = name end
        end
        table.sort(rest)
        for _, name in ipairs(rest) do names[#names + 1] = name end
        for _, name in ipairs(names) do
            local item = menu:AddItem(0, djName(api, name), function() DC:Open("dj", name) end)
            if name == current then item:SetChecked(true) end
        end
    end
    menu:Open()
end

local function makeButton(parent, text, w, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, BAR_H - 4)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(.2, .2, .2, .9)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, .15)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function showTip(owner, lines)
    local tip = Nx.TooltipText
    if not tip or not lines then return end
    tip:SetOwner(owner, "ANCHOR_RIGHT")
    tip:ClearLines()
    for i, line in ipairs(lines) do
        if i == 1 then tip:AddLine(line, 1, .82, 0) else tip:AddLine(line, 1, 1, 1, true) end
    end
    tip:Show()
end

local function hideTip()
    if Nx.TooltipText then Nx.TooltipText:Hide() end
end

function DC:Build(map)
    local f = CreateFrame("Frame", nil, map.Frm)
    f:EnableMouse(true)
    f:SetClipsChildren(true)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 1)
    f.Map = map

    local bar = CreateFrame("Frame", nil, f)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(BAR_H)
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetColorTexture(.08, .08, .1, .95)
    f.Bar = bar

    local pick = makeButton(bar, "v", 20, function() DC:OpenPicker() end)
    pick:SetPoint("LEFT", 2, 0)
    local close = makeButton(bar, "X", 20, function() DC:Close() end)
    close:SetPoint("RIGHT", -2, 0)
    f.Next = makeButton(bar, ">", 20, function() DC:SetFloor((DC.Floor or 1) + 1) end)
    f.Next:SetPoint("RIGHT", close, "LEFT", -6, 0)
    f.Prev = makeButton(bar, "<", 20, function() DC:SetFloor((DC.Floor or 1) - 1) end)
    f.Prev:SetPoint("RIGHT", f.Next, "LEFT", -2, 0)
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", pick, "RIGHT", 6, 0)
    text:SetPoint("RIGHT", f.Prev, "LEFT", -6, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    f.Title = text

    local holder = CreateFrame("Frame", nil, f)
    holder:SetPoint("TOPLEFT", 0, -BAR_H)
    holder:SetPoint("BOTTOMRIGHT")
    f.Holder = holder
    return f
end

local function djFloorByMapID(dj, mapID)
    for _, data in pairs(dj.DUNGEON_MAPS) do
        for _, fl in ipairs(data.floors or {}) do
            if fl.uiMapID == mapID then return fl end
        end
    end
end

local function fixFojjiTiles(chart, fojji)
    local id = chart:ChartID()
    local list, info = fojji.ChartTiles and fojji.ChartTiles(id or 0)
    if not list or not info or info.image then return end
    local first = chart.tiles and chart.tiles[1]
    if not first then return end
    local loaded = first:SetTexture(list[1], nil, nil, "TRILINEAR")
    first:SetTexCoord(0, 1, 0, 1)
    local dj = DJ()
    local fl = dj and djFloorByMapID(dj, id)
    local named = fl and fl.tiles and GetFileIDFromPath and GetFileIDFromPath(fl.tiles .. "1")
    if loaded ~= false and not (fl and fl.tiles and GetFileIDFromPath and not named) then return end
    local copy = fl and dj.MapArtCopy and dj.MapArtCopy(fl)
    for i = 2, #chart.tiles do chart.tiles[i]:Hide() end
    first:ClearAllPoints()
    first:SetPoint("TOPLEFT", chart.art, "TOPLEFT", 0, 0)
    first:SetSize(chart.w * chart.zoom, chart.h * chart.zoom)
    if copy then
        first:SetTexture(copy, nil, nil, "TRILINEAR")
        first:SetTexCoord(0, 1002 / 1024, 0, 668 / 1024)
    else
        first:SetColorTexture(.42, .33, .2, 1)
        first:SetTexCoord(0, 1, 0, 1)
    end
    first:Show()
end

function DC:BuildFojji(f, fojji)
    local holder = CreateFrame("Frame", nil, f.Holder)
    holder:SetAllPoints()
    local chart = fojji.Chart.New(holder, 800)
    local drawTiles = chart.DrawTiles
    chart.DrawTiles = function(self, ...)
        drawTiles(self, ...)
        fixFojjiTiles(self, fojji)
    end
    chart.view:SetPoint("CENTER")
    chart.onRightClick = function()
        if f.Map.OpenMenu then f.Map:OpenMenu() end
    end
    chart.onBossClick = function(boss)
        if fojji.Journal and fojji.Journal.Open then fojji.Journal.Open(boss.dungeon, "overview", boss) end
    end
    f.FojjiHolder = holder
    f.Chart = chart
end

function DC:BuildDJ(f)
    local view = CreateFrame("Frame", nil, f.Holder)
    view:SetAllPoints()
    view:SetClipsChildren(true)
    view:EnableMouse(true)
    view:EnableMouseWheel(true)
    local canvas = CreateFrame("Frame", nil, view)
    view.Canvas = canvas
    view.Tiles = {}
    view.Pins = {}
    view:SetScript("OnMouseWheel", function(_, delta) DC:ZoomAt(delta > 0 and 1.25 or 0.8) end)
    view:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        DC.DragX, DC.DragY = GetCursorPosition()
        view:SetScript("OnUpdate", function()
            local cx, cy = GetCursorPosition()
            local s = view:GetEffectiveScale()
            DC.PanX = (DC.PanX or 0) + (cx - DC.DragX) / s
            DC.PanY = (DC.PanY or 0) - (cy - DC.DragY) / s
            DC.DragX, DC.DragY = cx, cy
            DC.Dirty = true
        end)
    end)
    view:SetScript("OnMouseUp", function(_, button)
        view:SetScript("OnUpdate", nil)
        if button == "RightButton" and f.Map.OpenMenu then
            f.Map:OpenMenu()
        elseif button == "MiddleButton" then
            DC.Zoom, DC.PanX, DC.PanY = 1, 0, 0
            DC.Dirty = true
        end
    end)
    view:SetScript("OnHide", function() view:SetScript("OnUpdate", nil) end)
    f.DJView = view
end

function DC:ZoomAt(factor)
    local z = max(1, min(MAX_ZOOM, (self.Zoom or 1) * factor))
    local k = z / (self.Zoom or 1)
    self.PanX = (self.PanX or 0) * k
    self.PanY = (self.PanY or 0) * k
    self.Zoom = z
    self.Dirty = true
end

function DC:SetFloor(n)
    local src, api = source()
    local f = self.Frame
    if not f then return end
    if src == "fojji" and f.Chart then
        f.Chart:SetFloor(n)
    elseif src == "dj" then
        local data = api.DUNGEON_MAPS[self:Current("dj") or ""]
        if not data then return end
        n = max(1, min(#(data.floors or {}), n))
        if n ~= self.Floor then
            self.Floor = n
            self.Zoom, self.PanX, self.PanY = 1, 0, 0
        end
    end
    self.Dirty = true
end

local function tile(view, i)
    local t = view.Tiles[i]
    if not t then
        t = view.Canvas:CreateTexture(nil, "ARTWORK")
        view.Tiles[i] = t
    end
    t:ClearAllPoints()
    t:SetVertexColor(1, 1, 1)
    t:SetAlpha(1)
    t:SetDrawLayer("ARTWORK", 0)
    t:Show()
    return t
end

local function drawDJArt(view, dj, fl, w, h)
    for _, t in ipairs(view.Tiles) do t:Hide() end
    if fl.texture then
        local t = tile(view, 1)
        t:SetAllPoints(view.Canvas)
        t:SetTexture(fl.texture)
        t:SetTexCoord(0, fl.texRight or 1, 0, fl.texBottom or 1)
        return
    end
    local fid = fl.tiles and GetFileIDFromPath and GetFileIDFromPath(fl.tiles .. "1")
    if fid then
        local size = 256 * w / ART_W
        for i = 1, 12 do
            local t = tile(view, i)
            t:SetSize(size, size)
            t:SetPoint("TOPLEFT", view.Canvas, "TOPLEFT", ((i - 1) % 4) * size, -floor((i - 1) / 4) * size)
            t:SetTexture(fl.tiles .. i)
            t:SetTexCoord(0, 1, 0, 1)
        end
        for p, patch in ipairs(fl.patches or {}) do
            local t = tile(view, 12 + p)
            t:SetDrawLayer("ARTWORK", 1)
            t:SetPoint("TOPLEFT", view.Canvas, "TOPLEFT", patch.x0 * w, -patch.y0 * h)
            t:SetPoint("BOTTOMRIGHT", view.Canvas, "TOPLEFT", patch.x1 * w, -patch.y1 * h)
            t:SetTexture(patch.tex)
            t:SetTexCoord(0, 1, 0, 1)
            t:SetAlpha(patch.alpha or 1)
        end
        return
    end
    local copy = dj.MapArtCopy and dj.MapArtCopy(fl)
    local t = tile(view, 1)
    t:SetAllPoints(view.Canvas)
    if copy then
        t:SetTexture(copy)
        t:SetTexCoord(0, 1002 / 1024, 0, 668 / 1024)
    else
        t:SetColorTexture(.42, .33, .2, 1)
    end
end

local PIN_BOSS = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local PIN_ENTRANCE = "Interface\\Buttons\\UI-MicroStream-Green"
local PIN_LINK = "Interface\\Buttons\\UI-MicroStream-Yellow"
local PIN_NOTE = "Interface\\GossipFrame\\AvailableQuestIcon"
local PIN_TURNIN = "Interface\\GossipFrame\\ActiveQuestIcon"

local function pin(view, i)
    local p = view.Pins[i]
    if not p then
        p = CreateFrame("Button", nil, view.Canvas)
        p.Icon = p:CreateTexture(nil, "ARTWORK")
        p.Icon:SetAllPoints()
        p.Num = p:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        p.Num:SetPoint("BOTTOMRIGHT", 4, -2)
        p:SetScript("OnEnter", function(self) showTip(self, self.Tip) end)
        p:SetScript("OnLeave", hideTip)
        p:SetScript("OnClick", function(self) if self.ToFloor then DC:SetFloor(self.ToFloor) end end)
        view.Pins[i] = p
    end
    p:Show()
    return p
end

local function drawDJPins(view, dj, data, floorN, w, h, scale)
    for _, p in ipairs(view.Pins) do p:Hide() end
    local n = 0
    local size = max(14, min(26, 18 * scale))
    local function add(tex, x, y, tip, num, toFloor, color)
        n = n + 1
        local p = pin(view, n)
        p.Icon:SetTexture(tex)
        if color then p.Icon:SetVertexColor(color[1], color[2], color[3]) else p.Icon:SetVertexColor(1, 1, 1) end
        p.Num:SetText(num or "")
        p.Tip = tip
        p.ToFloor = toFloor
        p:SetSize(size, size)
        p:ClearAllPoints()
        p:SetPoint("CENTER", view.Canvas, "TOPLEFT", x * w, -y * h)
    end
    for i, b in ipairs(data.bosses or {}) do
        if (b.floor or 1) == floorN and b.x and b.y then
            add(PIN_BOSS, b.x, b.y, { djBoss(dj, b.name) }, i)
        end
    end
    local entrances = data.entrances or (data.entrance and { data.entrance }) or {}
    for _, e in ipairs(entrances) do
        if (e.floor or 1) == floorN and e.x and e.y then
            add(PIN_ENTRANCE, e.x, e.y, { djText(dj, e.labelKey or "MAP_ENTRANCE") or L["Entrance"] }, nil, nil, e.color)
        end
    end
    for _, t in ipairs(data.transitions or {}) do
        if (t.floor or 1) == floorN and t.x and t.y then
            local label = t.labelKey and djText(dj, t.labelKey, t.to) or (t.to and djFloorLabel(dj, t.to))
            add(t.to and PIN_LINK or PIN_NOTE, t.x, t.y, { label or "" }, nil, t.to)
        end
    end
    for _, t in ipairs(data.turnins or {}) do
        if (t.floor or 1) == floorN and t.x and t.y then
            add(PIN_TURNIN, t.x, t.y, { t.npc or "" })
        end
    end
end

function DC:UpdateDJ(f, dj, name, W, H)
    if not f.DJView then self:BuildDJ(f) end
    local view = f.DJView
    view:Show()
    if f.FojjiHolder then f.FojjiHolder:Hide() end
    local data = dj.DUNGEON_MAPS[name]
    local floors = data.floors or {}
    if self.Shown ~= name then
        self.Shown = name
        self.Floor = dj.SavedMapFloor and dj.SavedMapFloor(name, data) or 1
        self.Zoom, self.PanX, self.PanY = 1, 0, 0
    end
    local floorN = max(1, min(#floors, self.Floor or 1))
    self.Floor = floorN
    local fl = floors[floorN]
    if not fl then return end

    local fit = min(W / ART_W, H / ART_H)
    local zoom = self.Zoom or 1
    local cw, ch = ART_W * fit * zoom, ART_H * fit * zoom
    local maxX, maxY = max(0, (cw - W) / 2), max(0, (ch - H) / 2)
    self.PanX = max(-maxX, min(maxX, self.PanX or 0))
    self.PanY = max(-maxY, min(maxY, self.PanY or 0))
    view.Canvas:SetSize(cw, ch)
    view.Canvas:ClearAllPoints()
    view.Canvas:SetPoint("CENTER", view, "CENTER", self.PanX, -self.PanY)
    drawDJArt(view, dj, fl, cw, ch)
    drawDJPins(view, dj, data, floorN, cw, ch, fit * zoom)

    local title = djName(dj, name)
    if #floors > 1 then title = title .. "  |cff9d9d9d" .. djFloorLabel(dj, floorN) end
    f.Title:SetText(title)
    f.Prev:SetShown(#floors > 1)
    f.Next:SetShown(#floors > 1)
    f.Prev:SetEnabled(floorN > 1)
    f.Next:SetEnabled(floorN < #floors)
end

function DC:UpdateFojji(f, fojji, d, W, H)
    if not f.Chart then self:BuildFojji(f, fojji) end
    f.FojjiHolder:Show()
    if f.DJView then f.DJView:Hide() end
    f.Chart:Resize(W, H)
    if self.Shown ~= d then
        self.Shown = d
        f.Chart:SetDungeon(d, fojjiFloor(fojji, d))
    end
    f.Title:SetText(fojjiTitle(fojji, d))
    f.Prev:Hide()
    f.Next:Hide()
end

function DC:Update(map)
    if map ~= Nx.Map:GetMap(1) then return end
    local src, api = source()
    local value = src and self:Current(src)
    local frame = self.Frame
    if not value then
        if frame and frame:IsShown() then
            frame:Hide()
            hideTip()
        end
        return
    end
    if not frame then
        frame = self:Build(map)
        self.Frame = frame
        self.Dirty = true
    end
    local W, H = map.MapW or 0, map.MapH or 0
    if W <= BAR_H or H <= BAR_H * 2 then
        frame:Hide()
        return
    end
    if not frame:IsShown() then
        frame:Show()
        self.Dirty = true
    end
    local level = (map.Level or map.Frm:GetFrameLevel()) + 60
    local sig = format("%s|%d|%d|%d", src, W, H, level)
    if sig ~= self.Sig then
        self.Sig = sig
        self.Dirty = true
        frame:SetFrameLevel(level)
        frame.Bar:SetFrameLevel(level + 50)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", map.Frm, "TOPLEFT", map.PadX or 0, -(map.TitleH or 0))
        frame:SetSize(W, H)
    end
    if value ~= self.Shown then self.Dirty = true end
    if not self.Dirty then return end
    self.Dirty = nil
    if src == "fojji" then
        self:UpdateFojji(frame, api, value, W, H - BAR_H)
    else
        self:UpdateDJ(frame, api, value, W, H - BAR_H)
    end
end

function DC:IsActive()
    return self.Frame and self.Frame:IsShown() or false
end

function DC:AddMenu(menu, parentFrm)
    local hasFojji = loadable("FojjiCore_DungeonJournal") or Fojji() ~= nil
    local hasDJ = loadable("ForeverDungeonJournal") or DJ() ~= nil
    if not (hasFojji or hasDJ) then return end
    local sub = Nx.Menu:Create(parentFrm, 240)
    menu:AddSubMenu(sub, L["Dungeon Maps..."])
    local item = sub:AddItem(0, L["Show In Dungeons"], function() DC.Dirty = true end)
    item:SetChecked(prefs(), "DungeonChartAuto")
    sub:AddItem(0, L["Choose Dungeon..."], function() DC:OpenPicker() end)
    if hasFojji and hasDJ then
        local use = sub:AddItem(0, L["Use DungeonJournal Maps"], function()
            DC.Browse, DC.Shown, DC.Floor, DC.Sig = nil, nil, nil, nil
            DC.Dirty = true
        end)
        use:SetChecked(prefs(), "DungeonChartUseDJ")
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent", function()
    C_Timer.After(0, function() DC:Refresh() end)
    C_Timer.After(2, function() DC:Refresh() end)
end)

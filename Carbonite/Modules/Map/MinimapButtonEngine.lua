-- Carbonite | Modules / Map / MinimapButtonEngine
-- The behaviour behind the Carbonite minimap button: the right-
-- click menu builder, mouse handlers, drag-to-reposition, the
-- "show map" / "show events" / "options" menu items, and the
-- profiling toggle. The Frame itself (`_G.NXMiniMapBut`) is still
-- declared in Carbonite.xml; this file owns the methods.
--
-- Methods stay on Nx.NXMiniMapBut because the XML script handlers
-- (`OnClick`, `OnEnter`, `OnUpdate` in Carbonite.xml) call
-- Nx.NXMiniMapBut:X(...) by name. The documented surface
-- Modules/Map/MinimapButton.lua reads / drives this engine.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-------------------------------------------------------------------------------
-- MINIMAP BUTTON
-- Main addon button on the minimap
-------------------------------------------------------------------------------

---
-- Initialize the minimap button
-- Sets up right-click menu with addon options
--
function Nx.NXMiniMapBut:Init()
    local f = NXMiniMapBut

    if not Nx.db.profile.MiniMap.ButOwn then
        f:RegisterForDrag ("LeftButton")
    end

    -- Create menu

    local menu = Nx.Menu:Create (f)
    self.Menu = menu
    menu:AddItem (0, L["Options"], self.Menu_OnOptions, self)
    menu:AddItem (0, L["Show Map"], self.Menu_OnShowMap, self)
    menu:AddItem (0, L["Show Events"], self.Menu_OnShowEvents, self)
    menu:AddItem (0, "", nil, self)

    local item = menu:AddItem (0, L["Show Auction Buyout Per Item"], self.Menu_OnShowAuction, self)
    item:SetChecked (false)

    if Nx.db.profile.Debug.DebugCom then
        menu:AddItem (0, "", nil, self)
        menu:AddItem (0, L["Show Com Window"], self.Menu_OnShowCom, self)
    end
    if Nx.db.profile.Debug.DebugMap then
        menu:AddItem (0, "", nil, self)
        menu:AddItem (0, L["Toggle Profiling"], self.Menu_OnProfiling, self)
    end

    -- Fix position if bad (does not work)

    NXMiniMapBut:SetClampedToScreen (true)

--    self:Move()

    -- Ask to disable profiling

    local ok, var = pcall (GetCVar, "scriptProfile")
    if ok and var ~= "0" then
        Nx:ShowMessage ("Profiling is on. This decreases game performance. Disable?", "Disable and Reload", self.ToggleProfiling, "Cancel")
    end
end

function Nx.NXMiniMapBut:Menu_OnOptions()
    Nx.Opts:Open()
end

function Nx.NXMiniMapBut:Menu_OnShowMap()
    Nx.Map:ToggleSize()
end

function Nx.NXMiniMapBut:Menu_OnShowEvents()
    Nx.UEvents.List:Open()
end

function Nx.NXMiniMapBut:Menu_OnHideWatch (item)
    local hide = item:GetChecked()
    Nx.Quest.Watch.Win:Show (not hide)
end

function Nx.NXMiniMapBut:Menu_OnShowAuction (item)
    Nx.AuctionShowBOPer = item:GetChecked()

    if AuctionFrame and AuctionFrame:IsShown() then
        AuctionFrameBrowse_Update()
    end
end

function Nx.NXMiniMapBut:Menu_OnShowCom()
    Nx.Com.List:Open()
end

function Nx.NXMiniMapBut:Menu_OnProfiling()
    Nx:ShowMessage ("Toggle profiling? Reloads UI", "Reload", self.ToggleProfiling, "Cancel")
end

function Nx.NXMiniMapBut:ToggleProfiling()

    RegisterCVar ("scriptProfile")

    local var = GetCVar ("scriptProfile")
--    Nx.prtVar ("v:", var)
    var = var == "0" and "1" or "0"
    SetCVar ("scriptProfile", var)

--    Nx.prt (format ("Profiling %s", var))
    ReloadUI()
end

function Nx.NXMiniMapBut:NXOnEnter (frm)

    local mmown = Nx.db.profile.MiniMap.ButOwn
    local tip = Nx.TooltipText

    --V4 this
    tip:SetOwner (frm, "ANCHOR_LEFT")
    tip:SetText (NXTITLEFULL .. " " .. Nx.VERMAJOR .. "." .. Nx.VERMINOR*10)
    tip:AddLine (L["Left click toggle Map"], 1, 1, 1, true)

    if mmown then
        tip:AddLine (L["Shift left click toggle minimize"], 1, 1, 1, true)
    end

    tip:AddLine (L["Alt left click toggle Watch List"], 1, 1, 1, true)
    tip:AddLine (L["Middle click toggle Guide"], 1, 1, 1, true)
    tip:AddLine (L["Right click for Menu"], 1, 1, 1, true)

    if not mmown then
        tip:AddLine (L["Shift drag to move"], 1, 1, 1, true)
    end
    tip:AppendText ("")
end

function Nx.NXMiniMapBut:NXOnClick (button, down)

--    Nx.prt (button)

    if button == "LeftButton" then

        if IsShiftKeyDown() then
            Nx.db.profile.MiniMap.ButWinMinimize = not Nx.db.profile.MiniMap.ButWinMinimize
            Nx.Map.Dock:UpdateOptions()
        elseif IsAltKeyDown() and Nx.Quest then
            local w = Nx.Quest.Watch.Win
            w:Show (not w:IsShown())
        else
            Nx.Map:ToggleSize (0)
        end

    elseif button == "MiddleButton" then

        Nx.Map:GetMap (1).Guide:ToggleShow()

    else
        self:OpenMenu()
    end
end

function Nx.NXMiniMapBut:OpenMenu()
    if self.Menu then            -- Someone had error with this nil
        self.Menu:Open()
    end
end

---
-- Update handler for minimap button dragging
-- @param frm  The button frame
--
function Nx.NXMiniMapBut:NXOnUpdate (frm)

--    Nx.prtVar ("NXOnUpdate", frm)

    --V4 this
    if frm.NXDrag then

--        Nx.prt ("Drag")

        local mm = _G["Minimap"]

        local x, y = GetCursorPosition()
        local s = mm:GetEffectiveScale()
        self:Move (x / s, y / s)
    end
end

---
-- Position the minimap button around the minimap edge
-- @param x  Cursor X position
-- @param y  Cursor Y position
--
function Nx.NXMiniMapBut:Move (x, y)
    local but = NXMiniMapBut        -- 32x32

    local mm = _G["Minimap"]

    local l = mm:GetLeft() + 70        -- Minimap is 140x140
    local b = mm:GetBottom() + 70
--[[
    if not x then
        x = but:GetLeft()
        y = but:GetTop()
        Nx.prt ("xy %s %s", x, y)
    end
--]]
    x = x - l
    y = y - b

    local ang = atan2 (y, x)
    local r = (x ^ 2 + y ^ 2) ^ .5
    r = max (r, 79)
    r = min (r, 110)

    x = r * cos (ang)
    y = r * sin (ang)
    but:SetPoint ("TOPLEFT", mm, "TOPLEFT", x + 54, y - 54)
    but:SetUserPlaced (true)
end

---
-- Handle inter-addon communication (stub)
--
function Nx.ModChatReceive(msg,dist,target)
end

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

    NXMiniMapBut:SetClampedToScreen (true)

    -- Blizzard's minimap is 198x198 on Retail 12.1 but remains 140x140 on
    -- the supported Classic clients. Keep the launcher on the live minimap
    -- boundary whenever Edit Mode or Carbonite changes those dimensions.
    if not Nx.db.profile.MiniMap.ButOwn then
        local mm = _G.Minimap
        if mm and mm.HookScript and not f.NxBoundaryHooked then
            f.NxBoundaryHooked = true
            mm:HookScript("OnSizeChanged", function()
                if not f.NXDrag then
                    self:Move()
                end
            end)
        end

        if _G.C_Timer and type(_G.C_Timer.After) == "function" then
            _G.C_Timer.After(0, function()
                self:Move()
            end)
        else
            self:Move()
        end
    end

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

-- True means the corresponding minimap quadrant has a round edge. This is
-- the shape contract used by minimap-button libraries and supports skinned
-- minimaps without introducing a dependency on one of those libraries.
local MINIMAP_SHAPE_QUADRANTS = {
    ROUND = { true, true, true, true },
    SQUARE = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function IsUsableNumber(value)
    return type(value) == "number"
        and (not _G.issecretvalue or not _G.issecretvalue(value))
end

local function GetActiveMinimapShape()
    local db = Nx.db and Nx.db.profile and Nx.db.profile.MiniMap
    local map = Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1]

    -- Carbonite replaces Blizzard's mask while the minimap is combined. Its
    -- own live state is therefore authoritative over GetMinimapShape().
    if map and map.MMOwn and db then
        local square = map.MMZoomType == 0 and db.DockSquare or db.Square
        return square and "SQUARE" or "ROUND"
    end

    if type(_G.GetMinimapShape) == "function" then
        local ok, shape = pcall(_G.GetMinimapShape)
        if ok and type(shape) == "string"
            and (not _G.issecretvalue or not _G.issecretvalue(shape))
            and MINIMAP_SHAPE_QUADRANTS[shape] then
            return shape
        end
    end

    return db and db.Square and "SQUARE" or "ROUND"
end

local function GetBoundaryOffset(width, height, padding, deltaX, deltaY, shape)
    local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
    if distance <= 0 then
        deltaX, deltaY, distance = 1, 0, 1
    end

    local unitX = deltaX / distance
    local unitY = deltaY / distance
    local radiusX = width * .5 + padding
    local radiusY = height * .5 + padding

    local quadrant = 1
    if unitX < 0 then quadrant = quadrant + 1 end
    if unitY > 0 then quadrant = quadrant + 2 end

    local quadrants = MINIMAP_SHAPE_QUADRANTS[shape]
        or MINIMAP_SHAPE_QUADRANTS.ROUND
    if quadrants[quadrant] then
        local divisor = math.sqrt(
            unitX * unitX / (radiusX * radiusX)
            + unitY * unitY / (radiusY * radiusY))
        return unitX / divisor, unitY / divisor
    end

    local scaleX = unitX == 0 and math.huge
        or radiusX / math.abs(unitX)
    local scaleY = unitY == 0 and math.huge
        or radiusY / math.abs(unitY)
    local scale = math.min(scaleX, scaleY)
    return unitX * scale, unitY * scale
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
        if IsUsableNumber(x) and IsUsableNumber(y)
            and IsUsableNumber(s) and s > 0 then
            self:Move (x / s, y / s)
        end
    end
end

---
-- Position the minimap button around the minimap edge
-- @param x  Cursor X position
-- @param y  Cursor Y position
--
function Nx.NXMiniMapBut:Move (x, y)
    local but = _G.NXMiniMapBut
    local mm = _G.Minimap
    if not but or not mm or not but.GetParent
        or but:GetParent() ~= mm then
        return false
    end

    local centerX, centerY = mm:GetCenter()
    local width, height = mm:GetWidth(), mm:GetHeight()
    if not IsUsableNumber(centerX) or not IsUsableNumber(centerY)
        or not IsUsableNumber(width) or not IsUsableNumber(height)
        or width <= 0 or height <= 0 then
        return false
    end

    if not IsUsableNumber(x) or not IsUsableNumber(y) then
        x, y = but:GetCenter()
    end
    if not IsUsableNumber(x) or not IsUsableNumber(y) then
        x, y = centerX + width * .5, centerY
    end

    local buttonWidth, buttonHeight = but:GetWidth(), but:GetHeight()
    if not IsUsableNumber(buttonWidth) or buttonWidth <= 0 then
        buttonWidth = 32
    end
    if not IsUsableNumber(buttonHeight) or buttonHeight <= 0 then
        buttonHeight = 32
    end

    -- Nine pixels outside a 140x140 round minimap reproduces Carbonite's
    -- original 79-pixel center radius. Scaling that overlap with the button
    -- itself keeps custom-sized launchers visually attached to the rim.
    local padding = math.min(buttonWidth, buttonHeight) * 9 / 32
    local offsetX, offsetY = GetBoundaryOffset(
        width, height, padding, x - centerX, y - centerY,
        GetActiveMinimapShape())

    but:ClearAllPoints()
    but:SetPoint("CENTER", mm, "CENTER", offsetX, offsetY)
    but:SetUserPlaced (true)
    return true
end

---
-- Handle inter-addon communication (stub)
--
function Nx.ModChatReceive(msg,dist,target)
end

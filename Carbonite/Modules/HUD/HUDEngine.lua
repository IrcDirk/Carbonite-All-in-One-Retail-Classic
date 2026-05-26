-- Carbonite | Modules / HUD / HUDEngine
-- The actual frame for the directional HUD arrow. Lifted out of the
-- legacy NxHUD.lua so the HUD module owns its own implementation.
--
-- Lifecycle responsibilities live in HUD.lua (defaults, Show/Hide/
-- Toggle, the AceConfig page). The read-only public accessors live
-- in HUDArrow.lua. This file owns the frame, options application
-- and the per-frame Update that NxMap drives.
--
-- Existing callsites in NxMap (per-frame `Nx.HUD:Update(self)`),
-- NxOptions (`Nx.HUD:UpdateOptions()`), and Carbonite.lua
-- (`Nx.HUD:Init()`) continue to work because we re-anchor
-- `_G.Nx.HUD` (and the Carbonite alias) at the HUD module after
-- attaching the engine methods.

local Carbonite = _G.Carbonite
local Nx = _G.Nx
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

local HUD = Carbonite:GetModule("HUD", true)
if not HUD then return end

-- Carry forward any state that the legacy Nx.HUD = {} table picked up
-- before the module was wired in (currently empty, but be defensive
-- against future additions in Carbonite.lua's init block).
do
    local prev = _G.Nx and _G.Nx.HUD
    if type(prev) == "table" and prev ~= HUD then
        for k, v in pairs(prev) do
            if HUD[k] == nil then HUD[k] = v end
        end
    end
end

_G.Nx.HUD = HUD
Carbonite.HUD = HUD

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

--- Initialize the HUD. Called from Carbonite.lua's init flow once
--- Nx.Window is available.
function HUD:Init()
    HUD.TexNames = { "", "Chip", "Gloss", "Glow", "Neon" }
    HUD:Open()
end

-------------------------------------------------------------------------------
-- Window management
-------------------------------------------------------------------------------

--- Open and display the HUD window (lazy-creates on first call).
function HUD:Open()
    if not self.Created then
        self:Create()
        self.Created = true
    end
    self.Win:Show()
end

--- Build the HUD window, arrow frame and secure target button.
function HUD:Create()
    local inst = self

    -- ETA update delay counter (prevents per-frame flicker).
    inst.ETADelay = 0

    Nx.Window:SetCreateFade(1, .15)

    -- 4 title rows: the target name can span up to 3 of them (RXP
    -- steps with several sub-objectives stack each on its own line),
    -- with distance / ETA on the row below. Update() lays the caption
    -- out bottom-aligned so unused rows fall at the invisible top.
    local win = Nx.Window:Create("NxHUD", nil, nil, nil, 4, 1, nil, true)
    inst.Win = win

    -- Objective rows are left-aligned so they read as a bulleted list;
    -- the distance / ETA row (always the last title line, per Update's
    -- bottom-aligned layout) stays centred under the arrow.
    for n = 1, win.TitleLines do
        win:SetTitleJustify(n == win.TitleLines and "CENTER" or "LEFT", n)
    end

    -- Transparent background while locked.
    win:SetBGAlpha(0, 1)

    -- Position at top-center (999999 X clamps to right edge of layout).
    win:InitLayoutData(nil, 999999, -.17, 1, 1)

    win.Frm:SetToplevel(true)

    -- Directional arrow frame.
    local f = CreateFrame("Frame", nil, win.Frm)
    inst.Frm = f
    f.NxInst = inst
    f:EnableMouse(false)

    local tex = f:CreateTexture()
    tex:SetAllPoints(f)
    f.texture = tex

    -- Secure target button overlay (click-to-target).
    local but = CreateFrame("Button", nil, UIParent, "SecureUnitButtonTemplate")
    inst.But = but
    but:SetAttribute("type", "target")
    but:SetAttribute("unit", "player")

    local btex = but:CreateTexture()
    btex:SetAllPoints(but)
    btex:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconCircle")
    but.texture = btex
    but:SetWidth(10)
    but:SetHeight(10)

    self:UpdateOptions()

    -- Context menu items for waypoint management.
    local menu = win.Menu
    menu:AddItem(0, "--------------")

    local function removeCurrentPoint()
        local map = Nx.Map:GetMap(1)
        tremove(map.Targets, 1)
    end
    menu:AddItem(0, L["Remove Current Point"], removeCurrentPoint, self)

    local function removeAllPoints()
        local map = Nx.Map:GetMap(1)
        map:Menu_OnClearGoto()
    end
    menu:AddItem(0, L["Remove All Points"], removeAllPoints, self)
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

--- Stub kept for compatibility; fade is owned by the window system.
function HUD:SetFade(fade)
end

--- Show or hide the HUD window.
function HUD:Show(show)
    self.Win:Show(show)
end

--- Get current tracking info (used by external addons via Nx.HUDGetTracking).
local function HUDGetTracking()
    local map = Nx.Map:GetMap(1)
    return map.TrackDir, map.TrackDistYd, map.TrackName
end
Nx.HUDGetTracking = HUDGetTracking
HUD.GetTracking = HUDGetTracking

-------------------------------------------------------------------------------
-- Options application
-------------------------------------------------------------------------------

--- Apply saved-variable options to the HUD frame.
function HUD:UpdateOptions()
    local win = self.Win
    if not win then return end

    -- Window transparency follows lock state in paid builds.
    if not Nx.Free then
        local lock = win:IsLocked()
        win:SetBGAlpha(0, lock and 0 or 1)
    end

    -- Arrow texture per user preference.
    local name = Nx.db.profile.Track.AGfx
    self.Frm.texture:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\HUDArrow" .. name)

    local f = self.Frm
    f:SetPoint("CENTER", Nx.db.profile.Track.AXO, -win.TitleH / 2 - 32 - Nx.db.profile.Track.AYO)

    local wh = Nx.db.profile.Track.ASize
    f:SetWidth(wh)
    f:SetHeight(wh)

    if Nx.db.profile.Track.Lock then
        win:Lock(true, true)
    else
        win:Lock(false, true)
    end

    -- Target button size + colors. Secure frame so combat-gated.
    if not InCombatLockdown() then
        local b = self.But
        b:SetWidth(wh)
        b:SetHeight(wh)
        b:Hide()
    end

    self.ButR,  self.ButG,  self.ButB,  self.ButA  = Nx.Util_str2rgba(Nx.db.profile.Track.TButColor)
    self.ButCR, self.ButCG, self.ButCB, self.ButCA = Nx.Util_str2rgba(Nx.db.profile.Track.TButCombatColor)
end

-------------------------------------------------------------------------------
-- Per-frame update (driven by NxMap)
-------------------------------------------------------------------------------

--- Update the HUD each frame. Called from NxMap's main loop with
--- the primary map instance as the argument.
function HUD:Update(map)
    local win = self.Win
    local noLockDown = not InCombatLockdown()

    local shouldShow = map.TrackDir
        and not Nx.db.profile.Track.Hide
        and not (Nx.InBG and Nx.db.profile.Track.HideInBG)

    if shouldShow then
        local frm = self.Frm
        local but = self.But
        local wfrm = win.Frm

        if not wfrm:IsVisible() then
            if not win:IsCombatHidden() then
                win:Show()
            end
        end

        local dist = map.TrackDistYd
        local dir = (map.TrackDir - map.PlyrDir) % 360

        -- Don't rotate when essentially on top of the target.
        if dist < 1 then
            dir = 0
        end

        -- 0..180 angular distance; how far we are from facing.
        local dirDist = dir <= 180 and dir or 360 - dir

        if map.TrackPlayer and noLockDown then
            but:SetAttribute("unit1",       map.TrackPlayer)
            but:SetAttribute("shift-unit1", map.TrackPlayer .. "-target")
            but:SetAttribute("unit2",       map.TrackPlayer .. "-target")
        end

        local col = dirDist < 5 and "|cffa0a0ff" or ""
        local str = format("%s%d " .. L["yds"], col, dist)

        if Nx.db.profile.Track.ShowDir then
            local fmt = dirDist < 1 and L[" %.1f deg"] or L[" %d deg"]
            str = str .. format(fmt, dirDist)
        end

        if map.PlyrSpeed > .1 then
            self.ETADelay = self.ETADelay - 1
            if self.ETADelay <= 0 then
                self.ETADelay = 10
                local eta = map.TrackETA or dist / map.PlyrSpeed
                if eta < 60 then
                    self.ETAStr = format("|cffdfffdf %.0f " .. L["secs"], eta)
                else
                    self.ETAStr = format("|cffdfdfdf %.1f " .. L["mins"], eta / 60)
                end
            end
            str = str .. self.ETAStr
        else
            self.ETADelay = 3
            self.ETAStr = ""
        end

        -- Caption layout: the target name may span several rows (RXP
        -- sub-objectives joined with "\n"); distance / ETA goes on the
        -- row beneath it. Bottom-align within the fixed title block so
        -- the caption always sits right above the arrow and any unused
        -- rows fall at the (invisible) top.
        local maxLines  = win.TitleLines
        local nameLines = {}
        for ln in (tostring(map.TrackName or "") .. "\n"):gmatch("(.-)\n") do
            nameLines[#nameLines + 1] = ln
        end
        -- Fold any overflow beyond (maxLines - 1) name rows into the last.
        local maxName = maxLines - 1
        if #nameLines > maxName then
            for i = maxName + 1, #nameLines do
                nameLines[maxName] = nameLines[maxName] .. " " .. nameLines[i]
                nameLines[i] = nil
            end
        end
        local used  = #nameLines + 1            -- name rows + distance row
        local first = maxLines - used + 1
        for n = 1, first - 1 do win:SetTitle("", n) end
        for i = 1, #nameLines do win:SetTitle(nameLines[i], first + i - 1) end
        win:SetTitle(str, maxLines)

        -- Resize window to fit the title; anchor side determines
        -- which way the center has to drift.
        local atPt, _, _, x, y = wfrm:GetPoint()
        local w = win:GetSize()
        local tw = win:GetTitleTextWidth() + 2
        local d = (tw - w) / 2
        if strfind(atPt, "LEFT") then
            x = x - d
        elseif strfind(atPt, "RIGHT") then
            x = x + d
        end
        if not InCombatLockdown() then
            wfrm:ClearAllPoints()
            wfrm:SetPoint(atPt, x, y)
            win:SetSize(tw, 0, true)
        end

        -- Paid-build: secure target button on top of the arrow.
        if Nx.db.profile.Track.TBut and not win:IsCombatHidden() then
            if noLockDown then
                but:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", frm:GetLeft(), frm:GetTop())
                but:SetScale(wfrm:GetScale())
                but:Show()
                but.texture:SetVertexColor(self.ButR, self.ButG, self.ButB, self.ButA)
            else
                but.texture:SetVertexColor(self.ButCR, self.ButCG, self.ButCB, self.ButCA)
            end
        end

        -- Rotate the arrow by setting quad texture coordinates.
        local texX1, texX2 = -.5,  .5
        local texY1, texY2 = -.5,  .5
        local co, si = cos(dir), sin(dir)

        local t1x = texX1 *  co + texY1 * si + .5
        local t1y = texX1 * -si + texY1 * co + .5
        local t2x = texX1 *  co + texY2 * si + .5
        local t2y = texX1 * -si + texY2 * co + .5
        local t3x = texX2 *  co + texY1 * si + .5
        local t3y = texX2 * -si + texY1 * co + .5
        local t4x = texX2 *  co + texY2 * si + .5
        local t4y = texX2 * -si + texY2 * co + .5

        local tex = frm.texture
        tex:SetTexCoord(t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y)

        if dirDist < 5 then
            -- Facing the target.
            if dist < 1 then
                -- Very close: faded green.
                tex:SetVertexColor(.2, 1, .2, .4)
                tex:SetBlendMode("BLEND")
            else
                -- Pointed correctly: bright additive blue-white.
                tex:SetVertexColor(.7, .7, 1, 1)
                tex:SetBlendMode("ADD")
            end
        else
            -- Off-axis: warm yellow.
            tex:SetVertexColor(1, 1, .5, .9)
            tex:SetBlendMode("BLEND")
        end
    else
        win:Show(false)
        if noLockDown then
            self.But:Hide()
        end
    end
end

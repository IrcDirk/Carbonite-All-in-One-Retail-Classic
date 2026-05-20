-- Carbonite | Modules / Window / WindowMenu
-- The right-click context menu actions every Carbonite window
-- exposes (Hide in combat, Lock, Fade in/out, Layer, Scale,
-- Transparency). The legacy implementations all sit on Nx.Window
-- and consume `self.MenuWin` (a private reference to the window
-- whose menu was opened) plus a Menu item's slider/checkbox value.
--
-- This class exposes the same actions as plain functions you can
-- bind to any Carbonite menu item or call from custom UI:
--
--   WindowMenu:SetHideInCombat(window, hide)
--   WindowMenu:SetLocked(window, locked)
--   WindowMenu:SetFadeIn(window, alpha)
--   WindowMenu:SetFadeOut(window, alpha)
--   WindowMenu:SetLayer(window, strataIndex)
--   WindowMenu:SetScale(window, scale)        - preserves anchor
--   WindowMenu:SetTransparency(window, alpha) - clamps to [0..1]
--
-- These delegate to the legacy methods (Lock / SetFrmStrata / etc.)
-- so visual behavior matches; the value persistence keeps using
-- the same Nx.Window.SaveData layout so users don't have to
-- migrate settings.

local Carbonite = _G.Carbonite

local WindowMenu = {}
Carbonite.Modules.Window = Carbonite.Modules.Window or {}
Carbonite.Modules.Window.Menu = WindowMenu

local function legacyWindow() return _G.Nx and _G.Nx.Window end

-- Resolve a window argument that might be either a live window
-- object or a name string. Mirrors Layout's lookup pattern.
local function resolve(win)
    if type(win) == "string" then
        local W = legacyWindow()
        return W and W.Find and W:Find(win) or nil
    end
    return win
end

local function saveData(win)
    if not win then return nil end
    win.SaveData = win.SaveData or {}
    return win.SaveData
end

function WindowMenu:SetHideInCombat(win, hide)
    local w = resolve(win)
    local sd = saveData(w)
    if sd then sd.HideC = hide and true or false end
end

function WindowMenu:SetLocked(win, locked)
    local w = resolve(win)
    if w and w.Lock then w:Lock(locked) end
end

function WindowMenu:SetFadeIn(win, alpha)
    local w = resolve(win)
    local sd = saveData(w)
    if sd then sd.FI = alpha end
    if w then w.BackgndFadeIn = alpha end
end

function WindowMenu:SetFadeOut(win, alpha)
    local w = resolve(win)
    local sd = saveData(w)
    if sd then sd.FO = alpha end
    if w then w.BackgndFadeOut = alpha end
end

function WindowMenu:SetLayer(win, layerIndex)
    local w = resolve(win)
    if w and w.SetFrmStrata then w:SetFrmStrata(layerIndex) end
end

-- Scale: needs to preserve the on-screen position because changing
-- the frame's scale changes the meaning of its anchor offset.
-- Implementation mirrors the legacy Nx.Window:Menu_OnScale logic.
function WindowMenu:SetScale(win, scale)
    local w = resolve(win)
    if not w or not w.Frm then return end
    local sd = saveData(w)
    if sd and w.LayoutMode then sd[w.LayoutMode .. "S"] = scale end

    local frm = w.Frm
    local s = frm:GetScale() or 1
    local left = frm:GetLeft() or 0
    local top  = frm:GetTop()  or 0
    local x = left * s
    local y = ((_G.GetScreenHeight and _G.GetScreenHeight()) or 1080) - top * s

    frm:ClearAllPoints()
    frm:SetPoint("TOPLEFT", x / scale, -y / scale)
    frm:SetScale(scale)
end

function WindowMenu:SetTransparency(win, alpha)
    if alpha and alpha < 0 then alpha = 0 end
    if alpha and alpha > 1 then alpha = 1 end
    local w = resolve(win)
    if not w then return end
    local sd = saveData(w)
    if sd and w.LayoutMode then
        sd[w.LayoutMode .. "T"] = (alpha < 1) and alpha or nil
    end
    if w.Frm and w.Frm.SetAlpha then w.Frm:SetAlpha(alpha) end
end

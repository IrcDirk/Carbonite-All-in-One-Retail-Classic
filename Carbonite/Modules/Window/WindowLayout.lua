-- Carbonite | Modules / Window / WindowLayout
-- Public class around the layout/anchor/title verbs of the legacy
-- Nx.Window class. The actual Window implementation in NxUI.lua is
-- 1300 lines and still owns the rendering; this class provides a
-- stable, named-method surface over the part most callers actually
-- use: title text, layout anchor, size, locking, BG alpha.
--
-- Public API (every method takes a Window object as first arg or
-- you can pass a window name and we'll look it up):
--   WindowLayout:Find(name)            -> Window (or nil)
--   WindowLayout:SetTitle(w, text, line)
--   WindowLayout:SetTitleJustify(w, mode, line)
--   WindowLayout:SetTitleColors(w, r, g, b, a)
--   WindowLayout:SetTitleLineH(w, height)
--   WindowLayout:SetTitleXOff(w, x, yo)
--   WindowLayout:GetSize(w)            -> width, height
--   WindowLayout:SetSize(w, width, height, skipChildren)
--   WindowLayout:SetBGAlpha(w, min, max)
--   WindowLayout:Lock(w, locked, fullLockout)
--   WindowLayout:IsLocked(w)
--   WindowLayout:InitLayoutData(w, mode, x, y, h, layer, scale)
--   WindowLayout:GetLayoutMode(w)
--   WindowLayout:Show(w, shown)
--   WindowLayout:IsShown(w)
--
-- These all delegate to the legacy methods so behavior is unchanged.
-- The win argument can be a window object OR a window name string;
-- we resolve names via Nx.Window:Find.

local Carbonite = _G.Carbonite

local WindowLayout = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.Window = Carbonite.Modules.Window or {}
Carbonite.Modules.Window.Layout = WindowLayout

local function resolve(w)
    if type(w) == "string" then
        local NxWindow = _G.Nx and _G.Nx.Window
        return NxWindow and NxWindow.Find and NxWindow:Find(w) or nil
    end
    return w
end

function WindowLayout:Find(name)
    local NxWindow = _G.Nx and _G.Nx.Window
    if not NxWindow or not NxWindow.Find then return nil end
    return NxWindow:Find(name)
end

-- Build a method-style proxy: takes (target, ...) and forwards to
-- the same-named method on the legacy window object.
local function proxy(legacyName)
    return function(_, win, ...)
        local w = resolve(win)
        if not w or type(w[legacyName]) ~= "function" then return nil end
        return w[legacyName](w, ...)
    end
end

WindowLayout.SetTitle           = proxy("SetTitle")
WindowLayout.SetTitleJustify    = proxy("SetTitleJustify")
WindowLayout.SetTitleColors     = proxy("SetTitleColors")
WindowLayout.SetTitleLineH      = proxy("SetTitleLineH")
WindowLayout.SetTitleXOff       = proxy("SetTitleXOff")
WindowLayout.GetSize            = proxy("GetSize")
WindowLayout.SetSize            = proxy("SetSize")
WindowLayout.SetBGAlpha         = proxy("SetBGAlpha")
WindowLayout.Lock               = proxy("Lock")
WindowLayout.IsLocked           = proxy("IsLocked")
WindowLayout.InitLayoutData     = proxy("InitLayoutData")
WindowLayout.GetLayoutMode      = proxy("GetLayoutMode")
WindowLayout.Show               = proxy("Show")
WindowLayout.IsShown            = proxy("IsShown")
WindowLayout.GetTitleTextWidth  = proxy("GetTitleTextWidth")
WindowLayout.SetSizeable        = proxy("SetSizeable")

-- ----------------------------------------------------------------
-- ResetLayouts: nukes all saved window positions and forces them
-- back to their CreateWindow defaults. The legacy implementation
-- iterates every known window and calls ResetLayout on each. This
-- wrapper is the documented entry point from /carb resetwin and
-- the new /cb resetwindows slash.
-- ----------------------------------------------------------------

function WindowLayout:ResetAll()
    local NxWindow = _G.Nx and _G.Nx.Window
    if NxWindow and NxWindow.ResetLayouts then NxWindow:ResetLayouts() end
    Carbonite.Core.EventBus:Fire("WINDOW_LAYOUTS_RESET")
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("resetwindows", function()
        WindowLayout:ResetAll()
        Carbonite.Core.Logger:Get("WindowLayout"):info("window layouts reset")
    end, "reset every Carbonite window layout")
end)

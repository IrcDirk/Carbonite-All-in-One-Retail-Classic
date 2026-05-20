-- Carbonite | Modules / Window / WindowCombat
-- The "hide window during combat" behavior. The legacy
-- Nx.Window:UpdateCombat iterates registered windows and
-- shows / hides them based on their saved HideC flag. This
-- class is the public accessor.
--
-- Public API:
--   WindowCombat:UpdateAll()           - sync visibility now
--   WindowCombat:SetHideInCombat(win, hide)
--   WindowCombat:IsHiddenInCombat(win)
--   WindowCombat:IsAnyHidden()         - bool

local Carbonite = _G.Carbonite
local WindowCombat = {}
Carbonite.Modules.Window = Carbonite.Modules.Window or {}
Carbonite.Modules.Window.Combat = WindowCombat

local function W() return _G.Nx and _G.Nx.Window end
local function resolve(win)
    if type(win) == "string" then
        local w = W()
        return w and w.Find and w:Find(win) or nil
    end
    return win
end

function WindowCombat:UpdateAll()
    local w = W()
    if w and w.UpdateCombat then w:UpdateCombat() end
end

function WindowCombat:SetHideInCombat(win, hide)
    local target = resolve(win)
    if not target then return end
    target.SaveData = target.SaveData or {}
    target.SaveData.HideC = hide and true or false
end

function WindowCombat:IsHiddenInCombat(win)
    local target = resolve(win)
    return target and target.SaveData and target.SaveData.HideC == true or false
end

function WindowCombat:IsAnyHidden()
    local w = W()
    if not w or not w.Wins then return false end
    for win in pairs(w.Wins) do
        if win.SaveData and win.SaveData.HideC then return true end
    end
    return false
end

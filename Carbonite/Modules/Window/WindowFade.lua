-- Carbonite | Modules / Window / WindowFade
-- Class wrapper around the fade-related verbs of Nx.Window.
-- The legacy implementation stores fade speeds on the window
-- object (BackgndFadeIn / BackgndFadeOut) and toggles per-frame
-- alpha during the main update loop. This class is the public
-- surface so plugins can ask "is this window currently fading?"
-- or set fade speeds programmatically.
--
-- Public API:
--   WindowFade:SetCreateFade(fadeIn, fadeOut)
--     Sets the default fade speeds applied to every window
--     created after this point.
--   WindowFade:SetFadeIn(win, alpha)
--   WindowFade:SetFadeOut(win, alpha)
--   WindowFade:GetFade(win)             -> currentAlpha
--   WindowFade:SetBordersFade(win, fade)
--   WindowFade:ResetBackdrops()         -> re-apply skin

local Carbonite = _G.Carbonite

local WindowFade = {}
Carbonite.Modules.Window = Carbonite.Modules.Window or {}
Carbonite.Modules.Window.Fade = WindowFade

local function legacy() return _G.Nx and _G.Nx.Window end

local function resolve(win)
    if type(win) == "string" then
        local W = legacy()
        return W and W.Find and W:Find(win) or nil
    end
    return win
end

function WindowFade:SetCreateFade(fadeIn, fadeOut)
    local W = legacy()
    if W and W.SetCreateFade then W:SetCreateFade(fadeIn, fadeOut) end
end

function WindowFade:SetFadeIn(win, alpha)
    local w = resolve(win)
    if not w then return end
    w.BackgndFadeIn = alpha
end

function WindowFade:SetFadeOut(win, alpha)
    local w = resolve(win)
    if not w then return end
    w.BackgndFadeOut = alpha
end

function WindowFade:GetFade(win)
    local w = resolve(win)
    if w and w.GetFade then return w:GetFade() end
end

function WindowFade:SetBordersFade(win, fade)
    local w = resolve(win)
    if w and w.SetBordersFade then w:SetBordersFade(fade) end
end

function WindowFade:ResetBackdrops()
    local W = legacy()
    if W and W.ResetBackdrops then W:ResetBackdrops() end
end

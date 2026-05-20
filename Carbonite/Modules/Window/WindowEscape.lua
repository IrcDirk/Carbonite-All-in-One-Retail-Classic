-- Carbonite | Modules / Window / WindowEscape
-- ESC-to-close registry. Carbonite manages a private list of
-- frames that should hide when the user presses Escape; the
-- legacy table is HideFramesOnEsc inside NxUI.lua. This class is
-- the public accessor + a helper that registers a frame into
-- Blizzard's UISpecialFrames list too.
--
-- Public API:
--   WindowEscape:Add(frameOrName)
--   WindowEscape:Remove(frameOrName)
--   WindowEscape:Each(fn)
--   WindowEscape:Count()

local Carbonite = _G.Carbonite

local WindowEscape = {}
Carbonite.Modules.Window = Carbonite.Modules.Window or {}
Carbonite.Modules.Window.Escape = WindowEscape

local function resolve(frame)
    if type(frame) == "string" then return _G[frame] end
    return frame
end

local function frameName(frame)
    if type(frame) == "string" then return frame end
    if frame and frame.GetName then return frame:GetName() end
end

function WindowEscape:Add(frameOrName)
    local name = frameName(frameOrName)
    if not name then return end
    if not _G.UISpecialFrames then _G.UISpecialFrames = {} end
    for _, n in ipairs(_G.UISpecialFrames) do if n == name then return end end
    table.insert(_G.UISpecialFrames, name)
    Carbonite.Core.EventBus:Fire("WINDOW_ESC_REGISTERED", name)
end

function WindowEscape:Remove(frameOrName)
    local name = frameName(frameOrName)
    if not name or not _G.UISpecialFrames then return end
    for i = #_G.UISpecialFrames, 1, -1 do
        if _G.UISpecialFrames[i] == name then
            table.remove(_G.UISpecialFrames, i)
            Carbonite.Core.EventBus:Fire("WINDOW_ESC_UNREGISTERED", name)
            return
        end
    end
end

function WindowEscape:Each(fn)
    if not _G.UISpecialFrames then return end
    for _, n in ipairs(_G.UISpecialFrames) do fn(n) end
end

function WindowEscape:Count()
    return _G.UISpecialFrames and #_G.UISpecialFrames or 0
end

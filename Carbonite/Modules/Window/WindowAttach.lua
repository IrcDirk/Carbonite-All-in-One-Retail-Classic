-- Carbonite | Modules / Window / WindowAttach
-- Child-attachment verbs on Nx.Window. Carbonite windows can host
-- arbitrary child frames anchored via fractional offsets
-- (e.g. "occupy 20%-100% of the parent's width"); the legacy code
-- builds those associations through Attach / Detach / Adjust.
-- This class is the public accessor.
--
-- Public API:
--   WindowAttach:Attach(win, child, px1, px2, py1, py2, w, h)
--   WindowAttach:Detach(win, child)
--   WindowAttach:Adjust(win, skipChildren)
--   WindowAttach:GetChildren(win) -> array of attached child frames

local Carbonite = _G.Carbonite
local WindowAttach = {}
Carbonite.Modules.Window = Carbonite.Modules.Window or {}
Carbonite.Modules.Window.Attach = WindowAttach

local function legacy() return _G.Nx and _G.Nx.Window end
local function resolve(win)
    if type(win) == "string" then
        local W = legacy()
        return W and W.Find and W:Find(win) or nil
    end
    return win
end

function WindowAttach:Attach(win, child, px1, px2, py1, py2, w, h)
    local target = resolve(win)
    if not target or not target.Attach then return end
    target:Attach(child, px1, px2, py1, py2, w, h)
end

function WindowAttach:Detach(win, child)
    local target = resolve(win)
    if not target or not target.Detach then return end
    target:Detach(child)
end

function WindowAttach:Adjust(win, skipChildren)
    local target = resolve(win)
    if not target or not target.Adjust then return end
    target:Adjust(skipChildren)
end

function WindowAttach:GetChildren(win)
    local target = resolve(win)
    if not target then return {} end
    return target.Children or target.AttachedChildren or {}
end

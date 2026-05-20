-- Carbonite | Modules / Window / WindowSearch
-- Window-by-name lookup. Wraps Nx.Window:Find (case-sensitive) +
-- FindNoCase (case-insensitive) + an iteration verb across every
-- known window in Nx.Window.Wins.
--
-- Public API:
--   WindowSearch:Find(name)
--   WindowSearch:FindNoCase(name)
--   WindowSearch:Each(fn)
--   WindowSearch:Count()
--   WindowSearch:Exists(name)

local Carbonite = _G.Carbonite
local WindowSearch = {}
Carbonite.Modules.Window = Carbonite.Modules.Window or {}
Carbonite.Modules.Window.Search = WindowSearch

local function W() return _G.Nx and _G.Nx.Window end

function WindowSearch:Find(name)
    local w = W()
    return w and w.Find and w:Find(name) or nil
end

function WindowSearch:FindNoCase(name)
    local w = W()
    return w and w.FindNoCase and w:FindNoCase(name) or nil
end

function WindowSearch:Each(fn)
    local w = W()
    if not w or not w.Wins then return end
    for win in pairs(w.Wins) do fn(win, win.Name or "?") end
end

function WindowSearch:Count()
    local w = W()
    if not w or not w.Wins then return 0 end
    local n = 0
    for _ in pairs(w.Wins) do n = n + 1 end
    return n
end

function WindowSearch:Exists(name)
    return self:Find(name) ~= nil
end

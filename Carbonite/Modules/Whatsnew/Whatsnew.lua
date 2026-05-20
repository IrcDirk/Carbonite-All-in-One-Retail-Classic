-- Carbonite | Modules / Whatsnew
-- Version-history "what's new" pane. Replaces the legacy
-- Nx.Whatsnew table that lived inline in Carbonite.lua with a
-- proper class API:
--
--   Whatsnew:HasUnread()      - bool, true if there's a newer entry
--                               than the saved last-read time
--   Whatsnew:MarkAllRead()
--   Whatsnew:Each(fn)         - iterates entries, newest first
--                               (fn receives timestamp, category, lines)
--   Whatsnew:GetCategories()
--   Whatsnew:AddCategory(name)
--   Whatsnew:AddEntry(category, timestamp, lines)
--
-- The legacy code stored entries as `Nx.Whatsnew.Maps[<timestamp>] = lines`
-- arrays. We preserve that storage so unmigrated readers (the
-- original ToggleShow window) keep working.

local Carbonite = _G.Carbonite
local Whatsnew = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.Whatsnew = Whatsnew

-- Storage proxy onto Nx.Whatsnew so the legacy data survives.
local function root()
    local Nx = _G.Nx
    if not Nx then return nil end
    if not Nx.Whatsnew then
        Nx.Whatsnew = { Categories = {}, WhichCat = 1, HasWhatsNew = nil }
    end
    return Nx.Whatsnew
end

function Whatsnew:GetCategories()
    local r = root()
    return (r and r.Categories) or {}
end

function Whatsnew:AddCategory(name)
    local r = root()
    if not r then return end
    for _, c in ipairs(r.Categories or {}) do if c == name then return end end
    r.Categories = r.Categories or {}
    table.insert(r.Categories, name)
    r[name] = r[name] or {}
end

function Whatsnew:AddEntry(category, timestamp, lines)
    local r = root()
    if not r then return end
    r[category] = r[category] or {}
    r[category][timestamp] = lines
end

function Whatsnew:Each(fn)
    local r = root()
    if not r then return end
    for _, cat in ipairs(r.Categories or {}) do
        local entries = r[cat]
        if entries then
            local keys = {}
            for ts in pairs(entries) do keys[#keys + 1] = ts end
            table.sort(keys, function(a, b) return a > b end)   -- newest first
            for _, ts in ipairs(keys) do fn(ts, cat, entries[ts]) end
        end
    end
end

function Whatsnew:GetLastReadTime()
    local Nx = _G.Nx
    return (Nx and Nx.db and Nx.db.profile and Nx.db.profile.Whatsnew and Nx.db.profile.Whatsnew.lastreadtime) or 0
end

function Whatsnew:SetLastReadTime(ts)
    local Nx = _G.Nx
    if Nx and Nx.db and Nx.db.profile then
        Nx.db.profile.Whatsnew = Nx.db.profile.Whatsnew or {}
        Nx.db.profile.Whatsnew.lastreadtime = ts
    end
end

function Whatsnew:HasUnread()
    local lastRead = self:GetLastReadTime()
    local found = false
    self:Each(function(ts)
        if ts > lastRead then found = true end
    end)
    return found
end

function Whatsnew:MarkAllRead()
    -- Find the max timestamp across all categories and store it.
    local max = self:GetLastReadTime()
    self:Each(function(ts) if ts > max then max = ts end end)
    self:SetLastReadTime(max)
    Carbonite.Core.EventBus:Fire("WHATSNEW_MARKED_READ")
end

function Whatsnew:Show()
    local Nx = _G.Nx
    if Nx and Nx.Whatsnew and Nx.Whatsnew.ToggleShow then Nx.Whatsnew:ToggleShow() end
end

-- Slash command convenience.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if Carbonite.Core.SlashCommands then
        Carbonite.Core.SlashCommands:Register("whatsnew", function() Whatsnew:Show() end,
            "open the What's New window")
    end
end)

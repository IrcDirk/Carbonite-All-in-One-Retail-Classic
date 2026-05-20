-- Carbonite | Modules / Window / WindowConsole
-- The /carb winpos / winshow / winsize console handlers. They take
-- raw strings, parse them via Nx.Window:ParseConsole, and apply the
-- requested operation to a window resolved by case-insensitive name.
-- This class exposes the same verbs cleanly so other code (slash
-- commands, debug tools) can call them without juggling raw input.
--
-- Public API:
--   WindowConsole:Pos(input)          -- "name x y" - move
--   WindowConsole:Show(input)         -- "name [0/1]" - show/hide/toggle
--   WindowConsole:Size(input)         -- "name w h" - resize
--   WindowConsole:Parse(input)        -- returns name, x, y (numbers)
--
-- All four delegate to the legacy implementation when present so
-- behavior matches /carb exactly. The new /cb winpos / winshow /
-- winsize slash commands route through here for consistency.

local Carbonite = _G.Carbonite

local WindowConsole = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.Window = Carbonite.Modules.Window or {}
Carbonite.Modules.Window.Console = WindowConsole

local function nxWindow() return _G.Nx and _G.Nx.Window end

function WindowConsole:Parse(input)
    local w = nxWindow()
    if w and w.ParseConsole then return w:ParseConsole(input or "") end

    -- Portable fallback: tokenize on whitespace/commas, first
    -- non-numeric chunk(s) become the name, the rest become numbers.
    local str = (input or ""):lower():gsub(",", " ")
    local name, x, y
    for token in str:gmatch("%S+") do
        local n = tonumber(token)
        if n then
            if x then y = y or n else x = n end
        else
            name = name and (name .. " " .. token) or token
        end
    end
    return name, x, y
end

function WindowConsole:Pos(input)
    local w = nxWindow()
    if w and w.ConsolePos then return w:ConsolePos(input or "") end
end

function WindowConsole:Show(input)
    local w = nxWindow()
    if w and w.ConsoleShow then return w:ConsoleShow(input or "") end
end

function WindowConsole:Size(input)
    local w = nxWindow()
    if w and w.ConsoleSize then return w:ConsoleSize(input or "") end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("winpos", function(rest)  WindowConsole:Pos(rest)  end,
        "move a window: /cb winpos <name> <x> <y>")
    Carbonite.Core.SlashCommands:Register("winshow", function(rest) WindowConsole:Show(rest) end,
        "show/hide a window: /cb winshow <name> [0/1]")
    Carbonite.Core.SlashCommands:Register("winsize", function(rest) WindowConsole:Size(rest) end,
        "resize a window: /cb winsize <name> <w> <h>")
end)

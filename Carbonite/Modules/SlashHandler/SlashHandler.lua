-- Carbonite | Modules / SlashHandler
-- Wrapper around Nx.slashCommand, the parser that owns the `/Carb`
-- subcommand vocabulary (goto, options, resetwin, rl, track, etc.).
-- The actual parser still lives in Carbonite.lua because every
-- branch ties into legacy Nx.* state; this module gives external
-- code a single way to dispatch a slash command without depending
-- on the global slash table.
--
-- Public API:
--   SlashHandler:Dispatch(commandLine)  - run a /Carb command string
--   SlashHandler:Register(cmd, fn, desc) - extend the parser at runtime
--   SlashHandler:Each(fn)               - iterate (cmd, desc)
--   SlashHandler:GetCommands()          - sorted command list
--
-- Notes on coexistence with Core/SlashCommands.lua:
--   * Core.SlashCommands owns the new `/cb` namespace - per-module
--     subcommands registered via Options:Register etc.
--   * This SlashHandler owns the legacy `/Carb` namespace - the
--     vocabulary documented above (goto / resetwin / track / ...).
--   * Both can coexist because they have different slash prefixes.

local Carbonite = _G.Carbonite

local SlashHandler = {}
Carbonite.Modules = Carbonite.Modules or {}
Carbonite.Modules.SlashHandler = SlashHandler

local extras = {}             -- runtime-registered commands { cmd -> { fn, desc } }

function SlashHandler:Dispatch(line)
    line = line or ""
    local cmd = line:match("^(%S+)") or ""
    cmd = cmd:lower()
    local rest = line:gsub("^%S+%s*", "")

    -- Runtime extension first so plugins can override legacy commands.
    local ext = extras[cmd]
    if ext and ext.fn then
        local ok, err = pcall(ext.fn, rest)
        if not ok and Carbonite.Core.Logger then
            Carbonite.Core.Logger:Get("SlashHandler"):error("%s: %s", cmd, err)
        end
        return
    end

    -- Fall through to legacy slashCommand for the documented vocabulary.
    if _G.Nx and _G.Nx.slashCommand then _G.Nx.slashCommand(line) end
end

function SlashHandler:Register(cmd, fn, desc)
    if not cmd or not fn then return end
    extras[cmd:lower()] = { fn = fn, desc = desc or "" }
end

function SlashHandler:Unregister(cmd)
    if cmd then extras[cmd:lower()] = nil end
end

function SlashHandler:Each(fn)
    -- Built-in vocabulary that lives in Nx.slashCommand. We mirror the
    -- list here for help / discoverability without parsing the legacy
    -- function. Keep in sync when adding to Nx.slashCommand.
    local builtin = {
        { "editmode",  "toggle quest objective rectangle editor" },
        { "goto",      "[zone] x y - set map goto" },
        { "gotoadd",   "[zone] x y - add map goto" },
        { "menu",      "open the Carbonite minimap-button menu" },
        { "note",      "[\"]name[\"] [zone] [x y] - make map note" },
        { "options",   "open options window" },
        { "resetwin",  "reset window layouts" },
        { "rl",        "reload UI" },
        { "track",     "name - track the player" },
        { "winpos",    "name x y - position a window" },
        { "winshow",   "name [0/1] - toggle or show a window" },
        { "winsize",   "name w h - size a window" },
        { "events",    "open the user-events window" },
        { "d",         "toggle Carbonite debug log" },
    }
    for _, e in ipairs(builtin) do fn(e[1], e[2]) end
    for cmd, info in pairs(extras) do fn(cmd, info.desc) end
end

function SlashHandler:GetCommands()
    local list = {}
    self:Each(function(cmd, desc) list[#list + 1] = { cmd = cmd, desc = desc } end)
    table.sort(list, function(a, b) return a.cmd < b.cmd end)
    return list
end

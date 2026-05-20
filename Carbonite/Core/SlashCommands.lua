-- Carbonite | Core / SlashCommands
-- Single owner for the `/carb` slash command. Modules register
-- subcommands via SlashCommands:Register("track", handler, helpText).

local Carbonite = _G.Carbonite
local Logger = Carbonite.Core.Logger:Get("Slash")

local SlashCommands = {}
Carbonite.Core.SlashCommands = SlashCommands

local registry = {}
local helpLines = {}

function SlashCommands:Register(cmd, fn, help)
    registry[cmd:lower()] = fn
    if help then helpLines[#helpLines + 1] = ("  /carb %s - %s"):format(cmd, help) end
end

local function dispatch(input)
    input = (input or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if input == "" or input == "help" or input == "?" then
        Logger:info("Carbonite slash commands:")
        for _, line in ipairs(helpLines) do
            if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(line) end
        end
        return
    end

    local cmd, rest = input:match("^(%S+)%s*(.*)$")
    cmd = cmd:lower()
    local handler = registry[cmd]
    if handler then
        handler(rest)
    else
        Logger:warn("unknown subcommand %q (try /carb help)", cmd)
    end
end

function SlashCommands:Init()
    -- The legacy Carbonite.lua already owns `/Carb` via SlashCmdList["Carbonite"].
    -- We register `/cb` (and `/carb2`) for the new subcommand router so the two
    -- systems coexist while migration is in progress.
    _G.SLASH_CARBONITE2_1 = "/cb"
    _G.SLASH_CARBONITE2_2 = "/carb2"
    _G.SlashCmdList["CARBONITE2"] = dispatch
end

-- Built-in subcommand: toggle debug log level.
SlashCommands:Register("debug", function()
    local Logger_ = Carbonite.Core.Logger
    if Logger_.minLevel == Logger_.LEVEL.DEBUG then
        Logger_:SetLevel("INFO")
        Logger_:info("debug logging OFF")
    else
        Logger_:SetLevel("DEBUG")
        Logger_:info("debug logging ON")
    end
end, "toggle debug logging")

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    SlashCommands:Init()
end)

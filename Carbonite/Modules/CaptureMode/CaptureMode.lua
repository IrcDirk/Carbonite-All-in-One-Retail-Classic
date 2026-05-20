-- Carbonite | Modules / CaptureMode
-- Surface around Carbonite's "capture mode" — the developer-only
-- recording of items, vendor prices, NPC positions, etc. used to
-- populate the shipping data tables. Most users never touch this,
-- but it's part of the legacy /carb cap slash and a few other
-- entry points.
--
-- Public API:
--   CaptureMode:IsEnabled()
--   CaptureMode:SetEnabled(on)
--   CaptureMode:CaptureItems()      - one-shot capture run
--   CaptureMode:IsSharing()         - bool

local Carbonite = _G.Carbonite

local CaptureMode = {}
Carbonite.Modules.CaptureMode = CaptureMode

local function nx() return _G.Nx end

function CaptureMode:IsEnabled()
    local Nx = nx()
    return Nx and Nx.db and Nx.db.profile and Nx.db.profile.General
       and Nx.db.profile.General.CaptureEnable == true
end

function CaptureMode:SetEnabled(on)
    local Nx = nx()
    if Nx and Nx.db and Nx.db.profile and Nx.db.profile.General then
        Nx.db.profile.General.CaptureEnable = on and true or false
    end
    Carbonite.Core.EventBus:Fire("CAPTURE_MODE_TOGGLED", on == true)
end

function CaptureMode:IsSharing()
    local Nx = nx()
    return Nx and Nx.db and Nx.db.profile and Nx.db.profile.General
       and Nx.db.profile.General.CaptureShare == true
end

function CaptureMode:CaptureItems()
    local Nx = nx()
    if Nx and Nx.CaptureItems then Nx:CaptureItems() end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("capture", function(rest)
        rest = (rest or ""):lower()
        if rest == "on" then CaptureMode:SetEnabled(true)
        elseif rest == "off" then CaptureMode:SetEnabled(false)
        elseif rest == "items" then CaptureMode:CaptureItems()
        else
            local log = Carbonite.Core.Logger:Get("CaptureMode")
            log:info("capture mode: %s, sharing: %s",
                CaptureMode:IsEnabled() and "on" or "off",
                CaptureMode:IsSharing() and "on" or "off")
        end
    end, "developer capture-mode toggle (/cb capture [on|off|items])")
end)

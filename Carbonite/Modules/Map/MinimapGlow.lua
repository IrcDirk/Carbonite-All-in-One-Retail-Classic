-- Carbonite | Modules / Map / MinimapGlow
-- Pulsing-blip animation for minimap gathering nodes. Pulled out of
-- NxMap.lua so the lifecycle (start / stop / set rate) is owned by
-- one class instead of being scattered across MinimapNodeGlowInit /
-- OnMinimapNodeGlowTimer / MinimapNodeGlowSet.

local Carbonite = _G.Carbonite

local MinimapGlow = {}
Carbonite.Modules.Map.MinimapGlow = MinimapGlow

local NORMAL_TEX = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\MMOIcons"
local GLOW_TEX   = "Interface\\AddOns\\Carbonite\\Gfx\\Map\\MMOIconsG"
local RESET_TEX  = "Interface\\Minimap\\ObjectIconsAtlas"

local state = {
    active = false,
    timer  = nil,
    phase  = "",         -- "" = normal, "G" = glow
    frame  = nil,        -- preload texture host
}

local function ensurePreloadFrame()
    if state.frame then return state.frame end
    local f = _G.NXMinimapBlinkerFrame or CreateFrame("Frame", "NXMinimapBlinkerFrame")
    local t1 = f:CreateTexture(nil, "OVERLAY")
    t1:SetAllPoints()
    t1:SetTexture(NORMAL_TEX)
    local t2 = f:CreateTexture(nil, "OVERLAY")
    t2:SetAllPoints()
    t2:SetTexture(GLOW_TEX)
    state.frame = f
    return f
end

local function setMinimapBlip(letter)
    local mm = _G.Nx and _G.Nx.Map and _G.Nx.Map.MMFrm
    if mm and mm.SetBlipTexture then
        mm:SetBlipTexture(NORMAL_TEX .. (letter or ""))
    end
end

local function tick()
    if state.phase == "" then
        setMinimapBlip("")
        state.phase = "G"
    else
        setMinimapBlip("G")
        state.phase = ""
    end
end

-- Start the pulse at `interval` seconds per phase. Cancels any prior
-- timer first so callers can safely retrigger from options changes.
function MinimapGlow:Start(interval)
    self:Stop()
    if not interval or interval <= 0 then return end
    ensurePreloadFrame()
    local timerLib = _G.C_Timer
    if timerLib and timerLib.NewTicker then
        state.timer = timerLib.NewTicker(interval * 2, tick)
    elseif _G.Nx and _G.Nx.ScheduleRepeatingTimer then
        state.timer = _G.Nx:ScheduleRepeatingTimer(tick, interval * 2)
    end
    state.active = true
end

function MinimapGlow:Stop()
    if state.timer then
        if state.timer.Cancel then state.timer:Cancel()
        elseif _G.Nx and _G.Nx.CancelTimer then _G.Nx:CancelTimer(state.timer) end
        state.timer = nil
    end
    state.active = false
end

function MinimapGlow:Reset()
    self:Stop()
    local mm = _G.Nx and _G.Nx.Map and _G.Nx.Map.MMFrm
    if mm and mm.SetBlipTexture then mm:SetBlipTexture(RESET_TEX) end
end

function MinimapGlow:IsActive() return state.active end

-- Rewire the legacy methods so any code calling the old names ends
-- up in this class.
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end
    NxMap.MinimapNodeGlowInit = function(self, reset)
        if reset then MinimapGlow:Reset() end
        local delay = _G.Nx.db and _G.Nx.db.profile and _G.Nx.db.profile.MiniMap and _G.Nx.db.profile.MiniMap.NodeGD or 0
        MinimapGlow:Start(delay)
    end
    NxMap.MinimapNodeGlowSet = function(_, letter) setMinimapBlip(letter) end
    NxMap.OnMinimapNodeGlowTimer = function() tick() end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)

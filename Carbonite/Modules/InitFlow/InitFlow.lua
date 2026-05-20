-- Carbonite | Modules / InitFlow
-- Documented surface around Carbonite's startup sequence. The
-- legacy SetupEverything / InitWins functions sit on Nx and run
-- when player loaded + initialized + not in combat. This class is
-- the public accessor + tracks the lifecycle stage so plugins can
-- ask "is Carbonite fully ready yet?" without polling Nx.Initialized.
--
-- Stages:
--   loaded       Nx files parsed + Nx object constructed
--   playerFound  PLAYER_LOGIN fired
--   initialized  SetupEverything completed
--   ready        all subsystems alive, including non-critical UI
--
-- Public API:
--   InitFlow:GetStage()        -> "loaded"|"playerFound"|"initialized"|"ready"
--   InitFlow:IsReady()
--   InitFlow:OnReady(fn)       - fires immediately if already ready
--   InitFlow:RequestStartup()  - force the SetupEverything sequence

local Carbonite = _G.Carbonite

local InitFlow = {}
Carbonite.Modules.InitFlow = InitFlow

local readySubs = {}

function InitFlow:GetStage()
    local Nx = _G.Nx
    if not Nx then return "loaded" end
    if Nx.Initialized then return "ready" end
    if Nx.PlayerFnd then return "playerFound" end
    if Nx.Loaded then return "loaded" end
    return "unloaded"
end

function InitFlow:IsReady()
    return self:GetStage() == "ready"
end

function InitFlow:OnReady(fn)
    if type(fn) ~= "function" then return end
    if self:IsReady() then pcall(fn) ; return end
    readySubs[#readySubs + 1] = fn
end

function InitFlow:RequestStartup()
    local Nx = _G.Nx
    if Nx and Nx.SetupEverything then Nx:SetupEverything() end
end

local function dispatchReady()
    for i, fn in ipairs(readySubs) do
        local ok, err = pcall(fn)
        if not ok and Carbonite.Core.Logger then
            Carbonite.Core.Logger:Get("InitFlow"):error("subscriber %d: %s", i, tostring(err))
        end
    end
    readySubs = {}
end

-- Watch the legacy `Nx.Initialized` flag flipping true. We poll
-- via MainUpdater so we don't need to hook the legacy
-- SetupEverything; once it's been observed true once, fire ready.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    local mu = Carbonite.Modules.MainUpdater
    if not mu then return end
    mu:Subscribe(function()
        if InitFlow:IsReady() then
            mu:Unsubscribe("InitFlow.readyWatch")
            dispatchReady()
            Carbonite.Core.EventBus:Fire("CARBONITE_READY")
        end
    end, "InitFlow.readyWatch", 5)        -- check every ~5 frames
end)

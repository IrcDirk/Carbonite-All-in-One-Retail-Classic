-- Carbonite | Modules / EditModeHooks
-- Centralized Blizzard EditMode integration. Multiple Carbonite
-- subsystems need to know when the user enters/exits EditMode so
-- they can yield ownership of frames they would normally hide /
-- reposition (the quest tracker hider being the obvious case). The
-- legacy code wired one EventRegistry callback per consumer; this
-- class collapses that into a single observer.
--
-- Public API:
--   EditModeHooks:IsActive()           -> bool
--   EditModeHooks:OnEnter(fn)
--   EditModeHooks:OnExit(fn)
--   EditModeHooks:OnChange(fn)         -- fired for both Enter + Exit
--
-- Available everywhere Blizzard's EventRegistry + EditModeManagerFrame
-- exist (retail + Cata Classic onward). On flavors without them the
-- subscriptions install but never fire, which is the correct
-- "EditMode never opens" behavior.

local Carbonite = _G.Carbonite

local EditModeHooks = {}
Carbonite.Modules.EditModeHooks = EditModeHooks

local active = false
local enterSubs, exitSubs = {}, {}

local function notify(list)
    for _, fn in ipairs(list) do
        local ok, err = pcall(fn, active)
        if not ok and Carbonite.Core.Logger then
            Carbonite.Core.Logger:Get("EditModeHooks"):error("%s", tostring(err))
        end
    end
end

function EditModeHooks:IsActive() return active end

function EditModeHooks:OnEnter(fn)
    if type(fn) == "function" then enterSubs[#enterSubs + 1] = fn end
end

function EditModeHooks:OnExit(fn)
    if type(fn) == "function" then exitSubs[#exitSubs + 1] = fn end
end

function EditModeHooks:OnChange(fn)
    if type(fn) ~= "function" then return end
    self:OnEnter(fn); self:OnExit(fn)
end

-- Wire the actual Blizzard callbacks once on enable. Both events
-- update our `active` flag and fan out to subscribers.
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not _G.EventRegistry or not _G.EditModeManagerFrame then return end
    if EditModeHooks._wired then return end
    EditModeHooks._wired = true

    _G.EventRegistry:RegisterCallback("EditMode.Enter", function()
        active = true
        Carbonite.Core.EventBus:Fire("EDITMODE_ENTERED")
        notify(enterSubs)
    end)
    _G.EventRegistry:RegisterCallback("EditMode.Exit", function()
        active = false
        Carbonite.Core.EventBus:Fire("EDITMODE_EXITED")
        notify(exitSubs)
    end)
end)

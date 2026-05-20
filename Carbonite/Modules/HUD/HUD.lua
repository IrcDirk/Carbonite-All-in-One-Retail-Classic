-- Carbonite | Modules / HUD
-- Module shell for the heads-up directional arrow. Defines saved-
-- variable defaults, lifecycle (Show/Hide/Toggle), options page, and
-- the /hud slash command. The frame creation, options application
-- and per-frame Update live in HUDEngine.lua, which attaches its
-- methods to this same module instance and re-anchors Nx.HUD so
-- legacy callers (NxMap, NxOptions, Carbonite.lua) continue to
-- resolve `Nx.HUD:Method()` to the module's methods.

local Carbonite = _G.Carbonite
local Module = Carbonite.Core.Module

local HUD = Module:New("HUD", {
    defaults = {
        profile = {
            HUD = {
                Enabled       = false,
                ArrowStyle    = "",        -- legacy TexNames key, "" = default
                Scale         = 1,
                ShowDistance  = true,
                ShowETA       = true,
                AnchorX       = 0,
                AnchorY       = -200,
                Locked        = false,
            },
        },
    },
})

-- Show / Hide / Toggle wrap the engine in HUDEngine.lua (HUD:Open
-- builds the frame on first call; HUD.Win:Show(false) hides it).
function HUD:ShowWindow()
    if self.Open then self:Open() end
    self.visible = true
    Carbonite.Core.EventBus:Fire("HUD_OPENED")
end

function HUD:HideWindow()
    if self.Win and self.Win.Show then self.Win:Show(false) end
    self.visible = false
    Carbonite.Core.EventBus:Fire("HUD_CLOSED")
end

function HUD:Toggle()
    if self.visible then self:HideWindow() else self:ShowWindow() end
end

function HUD:OnEnable()
    local db = self:DB() and self:DB().profile or {}

    if db.Enabled then self:ShowWindow() end

    Carbonite.Core.SlashCommands:Register("hud", function(rest)
        rest = rest:lower()
        if rest == "show" then self:ShowWindow()
        elseif rest == "hide" then self:HideWindow()
        else self:Toggle() end
    end, "show / hide / toggle the directional HUD")
end

-- Options page registered via the new Options module.
Carbonite.Core.EventBus:Subscribe("MODULE_ENABLED", function(name)
    if name ~= "Options" then return end
    local Options = Carbonite:GetModule("Options", true)
    if not Options then return end
    Options:Register("HUD", function()
        local function get(k) return HUD:DB().profile[k] end
        local function set(k, v) HUD:DB().profile[k] = v end
        return {
            type = "group",
            name = "HUD",
            args = {
                enabled = {
                    order = 1, type = "toggle", name = "Enabled", width = "full",
                    get = function() return get("Enabled") end,
                    set = function(_, v) set("Enabled", v); if v then HUD:ShowWindow() else HUD:HideWindow() end end,
                },
                scale = {
                    order = 2, type = "range", name = "Scale", min = 0.5, max = 3, step = 0.05,
                    get = function() return get("Scale") end,
                    set = function(_, v) set("Scale", v) end,
                },
                showDistance = {
                    order = 3, type = "toggle", name = "Show distance",
                    get = function() return get("ShowDistance") end,
                    set = function(_, v) set("ShowDistance", v) end,
                },
                showETA = {
                    order = 4, type = "toggle", name = "Show ETA",
                    get = function() return get("ShowETA") end,
                    set = function(_, v) set("ShowETA", v) end,
                },
                locked = {
                    order = 5, type = "toggle", name = "Locked",
                    get = function() return get("Locked") end,
                    set = function(_, v) set("Locked", v) end,
                },
            },
        }
    end, { displayName = "HUD", order = 20 })
end)

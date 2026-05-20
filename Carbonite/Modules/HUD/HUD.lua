-- Carbonite | Modules / HUD
-- Module shell for the heads-up directional arrow. The legacy
-- implementation lives in NxHUD.lua and uses the old Nx.HUD table;
-- this module owns lifecycle (Open/Close/Toggle) and saved settings,
-- and forwards the heavy lifting to the legacy code via Nx.HUD.

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

function HUD:Show()
    local legacy = Carbonite.HUD
    if legacy and legacy.Open then legacy:Open() end
    self.visible = true
    Carbonite.Core.EventBus:Fire("HUD_OPENED")
end

function HUD:Hide()
    local legacy = Carbonite.HUD
    if legacy and legacy.Win and legacy.Win.Hide then legacy.Win:Hide() end
    self.visible = false
    Carbonite.Core.EventBus:Fire("HUD_CLOSED")
end

function HUD:Toggle()
    if self.visible then self:Hide() else self:Show() end
end

function HUD:OnEnable()
    local db = self:DB() and self:DB().profile or {}

    if db.Enabled then self:Show() end

    Carbonite.Core.SlashCommands:Register("hud", function(rest)
        rest = rest:lower()
        if rest == "show" then self:Show()
        elseif rest == "hide" then self:Hide()
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
                    set = function(_, v) set("Enabled", v); if v then HUD:Show() else HUD:Hide() end end,
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

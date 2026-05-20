-- Carbonite | Modules / HotkeyBindings
-- Documented registry of Carbonite's key-binding names. The actual
-- BINDING_NAME_* globals are still declared in Carbonite.lua (so
-- WoW's keybind UI sees them at addon-load); this class is the
-- introspection surface. It lists what each binding does, lets
-- new code attach extra bindings, and exposes a `/cb bindings`
-- slash that dumps the current map.
--
-- Public API:
--   HotkeyBindings:Register(action, name, description, handler)
--   HotkeyBindings:Get(action)        -> { name, description, handler }
--   HotkeyBindings:Each(fn)
--   HotkeyBindings:Count()

local Carbonite = _G.Carbonite

local HotkeyBindings = {}
Carbonite.Modules.HotkeyBindings = HotkeyBindings

-- Built-in bindings declared by Carbonite.lua. We mirror the
-- name -> description mapping here for documentation.
local BUILTIN = {
    NxMAPTOGORIGINAL   = "Toggle Carbonite vs. original Blizzard map",
    NxMAPTOGNORMMAX    = "Toggle map between normal and maximized size",
    NxMAPTOGNONEMAX    = "Toggle map between hidden and maximized",
    NxMAPTOGNONENORM   = "Toggle map between hidden and normal",
    NxMAPSCALERESTORE  = "Restore default map zoom",
    NxMAPTOGMINIFULL   = "Toggle minimap between docked and full size",
    NxMAPTOGHERB       = "Toggle herb gather node overlay",
    NxMAPTOGMINE       = "Toggle mining gather node overlay",
    NxTOGGLEGUIDE      = "Toggle the Carbonite guide pane",
    NxMAPSKIPTARGET    = "Skip to the next waypoint target",
}

local extras = {}    -- action -> { name, description, handler }

function HotkeyBindings:Register(action, name, description, handler)
    if not action then return end
    extras[action] = { name = name or action, description = description or "", handler = handler }
end

function HotkeyBindings:Get(action)
    if extras[action] then return extras[action] end
    if BUILTIN[action] then return { name = action, description = BUILTIN[action] } end
end

function HotkeyBindings:Each(fn)
    for k, v in pairs(BUILTIN) do fn(k, { name = k, description = v }) end
    for k, v in pairs(extras)  do fn(k, v) end
end

function HotkeyBindings:Count()
    local n = 0
    for _ in pairs(BUILTIN) do n = n + 1 end
    for _ in pairs(extras)  do n = n + 1 end
    return n
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("bindings", function()
        local log = Carbonite.Core.Logger:Get("HotkeyBindings")
        log:info("Carbonite key bindings:")
        HotkeyBindings:Each(function(action, info)
            log:info("  %s  - %s", action, info.description or "")
        end)
    end, "list Carbonite key bindings")
end)

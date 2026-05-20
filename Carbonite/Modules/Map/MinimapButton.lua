-- Carbonite | Modules / Map / MinimapButton
-- The Carbonite icon attached to the minimap that toggles the main
-- window. The legacy implementation was the `Nx.NXMiniMapBut` table
-- in Carbonite.lua plus a global `NXMiniMapBut` Frame declared in
-- the addon XML. This class wraps that frame with a clean object
-- surface and centralizes the menu-builder + tooltip code.
--
-- The global `NXMiniMapBut` Frame keeps existing because it's the
-- saved-variable anchor and the XML script handlers (`NXOnClick`,
-- `NXOnEnter`) reach it by global name. We only own the *behavior*.
--
-- Public API:
--   MinimapButton:GetFrame()
--   MinimapButton:Refresh()        - reapply normal-texture + menu items
--   MinimapButton:ToggleMap()      - the left-click action
--   MinimapButton:ShowMenu()       - the right-click action
--   MinimapButton:SetGlow(on)      - flash texture for unread events
--   MinimapButton:AddMenuItem(text, fn, checked)
--   MinimapButton:ClearExtraMenu() - drop plugin-added menu items

local Carbonite = _G.Carbonite
local MinimapButton = {}
Carbonite.Modules.Map.MinimapButton = MinimapButton

local extraMenuItems = {}     -- items added by plugins; rebuilt on Refresh

function MinimapButton:GetFrame()
    return _G.NXMiniMapBut
end

-- The two textures the legacy code swaps between: "MMBut" (idle)
-- and "MMButFilled" (glow / unread state).
local TEX_IDLE  = "Interface\\AddOns\\Carbonite\\Gfx\\MMBut"
local TEX_GLOW  = "Interface\\AddOns\\Carbonite\\Gfx\\MMButFilled"

function MinimapButton:SetGlow(on)
    local f = self:GetFrame()
    if not f or not f.SetNormalTexture then return end
    f:SetNormalTexture(on and TEX_GLOW or TEX_IDLE)
    Carbonite.Core.EventBus:Fire("MAP_MINIMAP_BUTTON_GLOW", on == true)
end

function MinimapButton:ToggleMap()
    local Nx = _G.Nx
    if Nx and Nx.Map and Nx.Map.ToggleSize then Nx.Map:ToggleSize(0) end
end

function MinimapButton:ShowMenu()
    local Nx = _G.Nx
    if Nx and Nx.NXMiniMapBut and Nx.NXMiniMapBut.Menu and Nx.NXMiniMapBut.Menu.Open then
        Nx.NXMiniMapBut.Menu:Open()
    elseif self:GetFrame() and self:GetFrame().Menu and self:GetFrame().Menu.Open then
        self:GetFrame().Menu:Open()
    end
end

-- Plugin-registered menu entries. Each plugin (Notes, Warehouse,
-- Quests, Info, Punks) used to call
-- `Nx.NXMiniMapBut.Menu:AddItem(...)` from its OnInitialize. With
-- the new architecture, plugins register through this method and we
-- rebuild the menu on every Refresh() so a /reload-free options
-- change still works.
function MinimapButton:AddMenuItem(text, handler, isChecked)
    extraMenuItems[#extraMenuItems + 1] = { text = text, handler = handler, checked = isChecked }
    self:Refresh()
end

function MinimapButton:ClearExtraMenu()
    for k in pairs(extraMenuItems) do extraMenuItems[k] = nil end
    self:Refresh()
end

-- Rebuilds the menu in place using the legacy Nx.Menu API. We do not
-- replace the menu object, just re-add items so the legacy menu's
-- internal state remains valid.
function MinimapButton:Refresh()
    local Nx = _G.Nx
    if not Nx or not Nx.NXMiniMapBut or not Nx.NXMiniMapBut.Menu then return end
    local menu = Nx.NXMiniMapBut.Menu
    for _, item in ipairs(extraMenuItems) do
        if menu.AddItem then
            local m = menu:AddItem(0, item.text, item.handler, Nx.NXMiniMapBut)
            if item.checked ~= nil and m and m.SetChecked then m:SetChecked(item.checked) end
        end
    end
end

-- Pulls the tooltip lines used by the legacy NXOnEnter into a class
-- method so other code (e.g. a tutorial popup) can render the same
-- text. Uses Carbonite.UI.Tooltip so we never taint GameTooltip.
function MinimapButton:ShowTooltip(ownerFrame)
    local Nx = _G.Nx
    local L = LibStub and LibStub("AceLocale-3.0", true) and LibStub("AceLocale-3.0"):GetLocale("Carbonite", true)
    local mmown = Nx and Nx.db and Nx.db.profile and Nx.db.profile.MiniMap and Nx.db.profile.MiniMap.ButOwn
    local ver = ("%s.%s"):format(Nx and Nx.VERMAJOR or "?", (Nx and Nx.VERMINOR or 0) * 10)
    local title = (_G.NXTITLEFULL or "Carbonite") .. " " .. ver

    local lines = { title }
    local function add(s) lines[#lines + 1] = (L and L[s]) or s end
    add("Left click toggle Map")
    if mmown then add("Shift left click toggle minimize") end
    add("Alt left click toggle Watch List")
    add("Middle click toggle Guide")
    add("Right click for Menu")
    if not mmown then add("Shift drag to move") end

    if Carbonite.UI.Tooltip then Carbonite.UI.Tooltip:Show(ownerFrame, "ANCHOR_LEFT", lines) end
end

-- Legacy rewire so existing handlers route through this class.
local function rewireLegacy()
    local Nx = _G.Nx
    if not Nx or not Nx.NXMiniMapBut then return end

    -- Mark the new entry points without erasing the legacy ones. We
    -- only redirect ToggleMap / ShowMenu / glow because those are the
    -- behaviors most plugins reach for.
    Nx.NXMiniMapBut.Glow = function(_, on) MinimapButton:SetGlow(on) end
    Nx.NXMiniMapBut.ToggleMap = function() MinimapButton:ToggleMap() end
    Nx.NXMiniMapBut.OpenMenu = function() MinimapButton:ShowMenu() end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)

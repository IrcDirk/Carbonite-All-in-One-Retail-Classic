-- Carbonite | UI / MenuActions
-- Class wrapper around Nx.Menu lifecycle verbs. The actual menu
-- rendering still lives in NxUI.lua because it's deeply tied to
-- the legacy frame pool; this class lets new code create / extend /
-- open / close menus through a stable API.
--
-- Public API:
--   MenuActions:Create(parent, width)             -> menu (legacy obj)
--   MenuActions:AddItem(menu, id, text, fn, user) -> item
--   MenuActions:AddSubMenu(menu, text)            -> sub-menu
--   MenuActions:Open(menu)
--   MenuActions:Close(menu)
--   MenuActions:IsAnyOpen()
--   MenuActions:CloseAll()

local Carbonite = _G.Carbonite
local MenuActions = {}
Carbonite.UI.MenuActions = MenuActions

local function NxMenu() return _G.Nx and _G.Nx.Menu end

function MenuActions:Create(parent, width)
    local m = NxMenu()
    if not m or not m.Create then return nil end
    return m:Create(parent, width)
end

function MenuActions:AddItem(menu, id, text, fn, user)
    if not menu or not menu.AddItem then return nil end
    return menu:AddItem(id, text, fn, user)
end

function MenuActions:AddSubMenu(menu, text)
    if not menu or not menu.AddSubMenu then return nil end
    local m = NxMenu()
    if not m or not m.AddSubMenu then return nil end
    return m:AddSubMenu(menu, text)
end

function MenuActions:Open(menu)
    if not menu or not menu.Open then return end
    menu:Open()
    Carbonite.Core.EventBus:Fire("MENU_OPENED", menu)
end

function MenuActions:Close(menu)
    if not menu or not menu.Close then return end
    menu:Close()
    Carbonite.Core.EventBus:Fire("MENU_CLOSED", menu)
end

function MenuActions:IsAnyOpen()
    local m = NxMenu()
    return m and m.IsAnyOpened and m:IsAnyOpened() or false
end

function MenuActions:CloseAll()
    local m = NxMenu()
    if m and m.Menus then
        for menu in pairs(m.Menus) do
            if menu.Close then pcall(menu.Close, menu) end
        end
    end
end

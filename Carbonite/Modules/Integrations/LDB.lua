-- Carbonite | Modules / Integrations / LDB
-- LibDataBroker-1.1 integration. The legacy code creates a single
-- broker object `Nx.Broker` ("Broker_Carbonite") that provides the
-- icon + click/tooltip handlers shown by DataBroker-aware addons
-- (TitanPanel, Bazooka, BFAC, etc.). This class is the public
-- surface so other modules can:
--   * Append items to the broker right-click menu without poking
--     Nx.BrokerMenuTemplate directly.
--   * Read the live broker text / icon so e.g. an overlay can mirror it.
--   * Update the broker text dynamically when state changes.
--
-- Public API:
--   LDB:GetBroker()            -> the legacy Nx.Broker object
--   LDB:SetText(text)
--   LDB:SetIcon(path)
--   LDB:GetMenu()              -> the menu-template array (legacy shape)
--   LDB:AddMenuItem(text, fn, opts)
--   LDB:ClearPluginItems()     -- removes plugin-added entries
--   LDB:ShowMenu(ownerFrame)

local Carbonite = _G.Carbonite

local LDB = {}
Carbonite.Modules.Integrations = Carbonite.Modules.Integrations or {}
Carbonite.Modules.Integrations.LDB = LDB

local function nx() return _G.Nx end

function LDB:GetBroker()
    local Nx = nx()
    return Nx and Nx.Broker
end

function LDB:SetText(text)
    local b = self:GetBroker()
    if b then b.text = text or "" end
end

function LDB:SetIcon(path)
    local b = self:GetBroker()
    if b then b.icon = path end
end

function LDB:GetMenu()
    local Nx = nx()
    return Nx and Nx.BrokerMenuTemplate or {}
end

-- Add a menu entry that survives until the user reloads. `opts` is
-- optional and forwards the standard LDB context-menu fields
-- (isTitle, checked, hasArrow, etc.).
function LDB:AddMenuItem(text, fn, opts)
    if not text then return end
    local menu = self:GetMenu()
    local item = { text = text, func = fn }
    if type(opts) == "table" then
        for k, v in pairs(opts) do if item[k] == nil then item[k] = v end end
    end
    item.__plugin = true
    menu[#menu + 1] = item
end

function LDB:ClearPluginItems()
    local menu = self:GetMenu()
    for i = #menu, 1, -1 do if menu[i] and menu[i].__plugin then table.remove(menu, i) end end
end

function LDB:ShowMenu(ownerFrame)
    if _G.MenuUtil and _G.MenuUtil.CreateContextMenu then
        local menu = self:GetMenu()
        _G.MenuUtil.CreateContextMenu(ownerFrame, function(_, root)
            for _, e in ipairs(menu) do
                if e.isTitle then root:CreateTitle(e.text)
                elseif e.func then root:CreateButton(e.text, e.func) end
            end
        end)
        return
    end
    if _G.EasyMenu and _G.CarboniteMenuFrame then
        _G.EasyMenu(self:GetMenu(), _G.CarboniteMenuFrame, "cursor", 0, 0, "MENU")
    end
end

-- Carbonite | Modules / Integrations / LDBEngine
-- The LibDataBroker-1.1 broker object + base menu template +
-- context-menu helper, extracted from Carbonite.lua.
--
-- Sets up:
--   * Nx.BrokerMenuTemplate (base entries; plugin addons extend
--     this from their OnInitialize)
--   * Nx.Broker = LibStub("LibDataBroker-1.1"):NewDataObject(...)
--     with the tooltip/click handlers from the legacy code
--   * A retail-aware ShowBrokerMenu helper that uses MenuUtil on
--     retail 11.0+ and falls back to EasyMenu on older clients
--
-- Tables stay on Nx because plugin OnInitialize hooks
-- (CarboniteQuests, CarboniteNotes, CarboniteWarehouse) extend
-- Nx.BrokerMenuTemplate by direct tinsert.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

Nx.BrokerMenuTemplate = {
    { text = "Carbonite", icon = icon, isTitle = true },
    { text = L["Options"],       func = function() Nx.Opts:Open() end },
    { text = L["Toggle Map"],    func = function() Nx.Map:ToggleSize(0) end },
    { text = L["Toggle Events"], func = function() Nx.UEvents.List:Open() end },
}

-- Dropdown frame for Classic / pre-11.0 retail. The new MenuUtil
-- in 11.0+ doesn't need this template-backed frame.
local menuFrame
if not Nx.isRetail then
    menuFrame = CreateFrame("Frame", "CarboniteMenuFrame", UIParent, "UIDropDownMenuTemplate")
end

local function ShowBrokerMenu(ownerRegion)
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(ownerRegion, function(_, rootDescription)
            rootDescription:CreateTitle("Carbonite")
            rootDescription:CreateButton(L["Options"],       function() Nx.Opts:Open() end)
            rootDescription:CreateButton(L["Toggle Map"],    function() Nx.Map:ToggleSize(0) end)
            rootDescription:CreateButton(L["Toggle Events"], function() Nx.UEvents.List:Open() end)
        end)
    elseif EasyMenu then
        EasyMenu(Nx.BrokerMenuTemplate, menuFrame, "cursor", 0, 0, "MENU")
    end
end

Nx.Broker = LibStub("LibDataBroker-1.1"):NewDataObject("Broker_Carbonite", {
    type  = "data source",
    icon  = "Interface\\AddOns\\Carbonite\\Gfx\\MMBut",
    label = "Carbonite",
    text  = "Carbonite",

    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine("Carbonite")
        tooltip:AddLine(L["Left-Click to Toggle Map"])
        if Nx.db.profile.MiniMap.ButOwn then
            tooltip:AddLine(L["Shift Left-Click to Toggle Minimize"])
        end
        tooltip:AddLine(L["Middle-Click to Toggle Guide"])
        tooltip:AddLine(L["Right-Click for Menu"])
    end,

    OnClick = function(frame, msg)
        if msg == "LeftButton" then
            if IsShiftKeyDown() then
                Nx.db.profile.MiniMap.ButWinMinimize = not Nx.db.profile.MiniMap.ButWinMinimize
                Nx.Map.Dock:UpdateOptions()
            else
                Nx.Map:ToggleSize(0)
            end
        elseif msg == "MiddleButton" then
            Nx.Map:GetMap(1).Guide:ToggleShow()
        elseif msg == "RightButton" then
            ShowBrokerMenu(frame)
        end
    end,
})

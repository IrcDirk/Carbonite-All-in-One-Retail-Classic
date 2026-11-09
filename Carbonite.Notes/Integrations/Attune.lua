local Nx = _G.Nx
if not Nx then return end

local function canonMid(uiMapID)
    local MapIDs = Carbonite and Carbonite.Modules and Carbonite.Modules.Map and Carbonite.Modules.Map.MapIDs
    local mid = MapIDs and MapIDs:CanonicalizeMapID(uiMapID) or uiMapID
    if Nx.OldMapIDs then
        if mid == 1414 then mid = 12 elseif mid == 1415 then mid = 13 end
    end
    return mid, MapIDs
end

local function gotoPin(uiMapID, x, y)
    local map = Nx.Map and Nx.Map.GetMap and Nx.Map:GetMap(1)
    local mid, MapIDs = canonMid(uiMapID)
    if not (map and Nx.Map.MapWorldInfo and Nx.Map.MapWorldInfo[mid]) then return end
    local zoneName = MapIDs and MapIDs:IdToName(mid)
    local name = format("%s%.1f, %.1f", zoneName and (zoneName .. " ") or "", x, y)
    for _, tar in ipairs(map.Targets or {}) do
        if tar.MapId == mid and tar.TargetName == name then return end
    end
    map:SetTargetXY(mid, x, y, name)
end

local function pinLink(uiMapID, x, y)
    return format("|cffffff00|Hworldmap:%d:%d:%d|h[|A:Waypoint-MapPin-ChatIcon:13:13:0:0|a %s]|h|r",
        uiMapID, floor(x * 100 + 0.5), floor(y * 100 + 0.5), MAP_PIN_HYPERLINK or "Map Pin")
end

local function insertIntoChat(text)
    local eb
    if ChatFrameUtil and ChatFrameUtil.GetActiveWindow then
        eb = ChatFrameUtil.GetActiveWindow()
    elseif ChatEdit_GetActiveWindow then
        eb = ChatEdit_GetActiveWindow()
    end
    if eb then
        eb:Insert(text)
        return true
    end
end

local function showCopyBox(text)
    if not StaticPopupDialogs["NxAttuneCoords"] then
        StaticPopupDialogs["NxAttuneCoords"] = {
            text = "Ctrl+C:",
            button1 = OKAY or "Okay",
            hasEditBox = 1,
            editBoxWidth = 280,
            whileDead = 1,
            hideOnEscape = 1,
            timeout = 0,
            preferredIndex = 3,
            OnShow = function(self)
                local eb = self.EditBox or self.editBox or (self.GetName and _G[self:GetName() .. "EditBox"])
                if eb then
                    eb:SetText(self.data or "")
                    eb:HighlightText()
                    eb:SetFocus()
                end
            end,
            EditBoxOnTextChanged = function(eb)
                local parent = eb:GetParent()
                if eb:GetText() ~= parent.data then
                    eb:SetText(parent.data or "")
                    eb:HighlightText()
                end
            end,
            EditBoxOnEnterPressed = function(eb) eb:GetParent():Hide() end,
            EditBoxOnEscapePressed = function(eb) eb:GetParent():Hide() end,
        }
    end
    StaticPopup_Show("NxAttuneCoords", nil, nil, text)
end

local function onPinClick(self)
    local m, x, y = self.uiMapID, self.pinX, self.pinY
    if not (m and x and y) then return end
    gotoPin(m, x, y)
    if IsModifiedClick("CHATLINK") then
        insertIntoChat(pinLink(m, x, y))
        showCopyBox(format("%s %d %.1f %.1f", SLASH_MAPPIN1 or "/pin", m, x, y))
        if PlaySound and SOUNDKIT and SOUNDKIT.UI_MAP_WAYPOINT_CHAT_SHARE then
            PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_CHAT_SHARE)
        end
    end
end

local hooked
local function hookPin()
    if hooked then return end
    local panel = _G.AttuneQuestDetail
    local pin = panel and panel.map and panel.map.pin
    if not pin then return end
    hooked = true
    pin:SetScript("OnClick", onPinClick)
end

local function install()
    if type(_G.Attune_ShowQuestDetail) ~= "function" then return false end
    hooksecurefunc("Attune_ShowQuestDetail", hookPin)
    hookPin()
    return true
end

if not install() then
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
        if name == "Attune" and install() then self:UnregisterAllEvents() end
    end)
end

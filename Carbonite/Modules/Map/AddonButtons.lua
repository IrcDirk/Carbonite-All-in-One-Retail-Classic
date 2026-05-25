-- Carbonite | Modules / Map / AddonButtons
-- Carbonite-styled toolbar buttons for Questie and HandyNotes. Both
-- addons happen to be drivable without their original button frames:
--
--   * Questie    — state is global (`Questie.db.profile.enabled` +
--                  `QuestieQuest:ToggleNotes`) and its menu anchors
--                  at the cursor (`LibDropDown:EasyMenu`), so calling
--                  `QuestieMenu:Show()` from our button pops it up
--                  next to us without needing the original frame.
--   * HandyNotes — `HandyNotes:Enable()/Disable()` and
--                  `HandyNotes:IsEnabled()` are global. Right-click
--                  opens the AceConfigDialog, identical to fuba's
--                  HandyNotesWorldMapButton.
--
-- Other adopted-addon experiments (RareScanner, HandyNotes plugins)
-- needed frame-anchored DropdownButton menus that we couldn't surface
-- without reimplementing each addon's menu callback. Those stay on
-- their own buttons on the Blizzard worldmap for now.

local Carbonite = _G.Carbonite
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite", true)

local AddonButtons = {}
Carbonite.Modules.Map.AddonButtons = AddonButtons

AddonButtons.Adopted = {}    -- typeId -> { handler = fn }

local QUESTIE_ICON    = "Interface\\AddOns\\Questie\\Icons\\available.blp"
local RARESCAN_ICON   = "Interface\\AddOns\\RareScanner\\Media\\Icons\\OriginalSkull.blp"
local RXP_ICON        = "Interface\\AddOns\\RXPGuides\\Textures\\rxp_logo-128"
local FALLBACK_ICON   = "Interface\\Icons\\INV_Misc_QuestionMark"

-- HandyNotes itself doesn't ship a brandable toolbar texture; the
-- nice "M on parchment" icon comes from the optional
-- HandyNotes_WorldMapButton plugin. Resolve at register time so
-- flavours without that plugin (e.g. MoP Classic users who only
-- have HandyNotes core) get a sensible builtin instead of an
-- empty texture region.
local function handyNotesIcon()
    local isLoaded = (_G.C_AddOns and _G.C_AddOns.IsAddOnLoaded
                        and _G.C_AddOns.IsAddOnLoaded("HandyNotes_WorldMapButton"))
                  or (_G.IsAddOnLoaded and _G.IsAddOnLoaded("HandyNotes_WorldMapButton"))
    if isLoaded then
        return "Interface\\AddOns\\HandyNotes_WorldMapButton\\Buttons\\Default"
    end
    return "Interface\\Icons\\INV_Misc_Map02"
end

local function carboniteMap()
    local Nx = _G.Nx
    return Nx and Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1] or nil
end

-- Toggle Carbonite's own display flag (so its map icon layer
-- responds), AND mirror to the addon's own enabled flag so the two
-- UIs stay in sync. Refresh by either redrawing this map or
-- clearing the integration's icon layer (same code path as the
-- Options.lua toggles).
local function questieHandler(_, _, click)
    local Nx, Q = _G.Nx, _G.Questie
    if not Q or not _G.QuestieLoader or not Nx or not Nx.fdb then return end
    if click == "RightButton" then
        local Menu = _G.QuestieLoader:ImportModule("QuestieMenu")
        if Menu then
            if Menu.IsOpen and Menu.IsOpen() then
                Menu:Hide()
            else
                Menu:Show()
            end
        end
        return
    end
    local enabled = not Nx.fdb.profile.Notes.Questie
    Nx.fdb.profile.Notes.Questie = enabled
    if Q.db and Q.db.profile then
        Q.db.profile.enabled = enabled
        local QQ = _G.QuestieLoader:ImportModule("QuestieQuest")
        if QQ and QQ.ToggleNotes then QQ:ToggleNotes(enabled) end
    end
    -- Bust the integration's dirty-check cache. Without this, the
    -- Questie:UpdateIcons fast path matches the previous hash and
    -- skips the rebuild — icons stay invisible until something else
    -- (zone change, map close/reopen) invalidates the cache.
    if Nx.Notes and Nx.Notes.BustIntegrationCache then
        Nx.Notes:BustIntegrationCache("Questie")
    end
    local map = Nx.Map:GetMap(1)
    if enabled then
        if Nx.Notes and Nx.Notes.Questie then
            Nx.Notes:Questie(Nx.Map:GetCurrentMapAreaID())
        end
    elseif map then
        map:ClearIconType("!QUE")
        map:ClearIconType("!QUE_T")
    end
end

-- RareScanner's own button is a DropdownButton anchored to its source
-- frame, so we can't replay its right-click menu here without
-- reimplementing the whole RSConfigDB-driven option tree. Instead:
--   * left click toggles Carbonite's display flag (busting the
--     integration's dirty-check cache so re-enable redraws),
--   * right click opens RareScanner's Blizzard interface-options
--     category (modern Settings API; falls back to the legacy
--     InterfaceOptionsFrame opener and finally to AceConfigDialog).
local function openRareScannerSettings()
    local RS = _G.RareScanner
    -- Open Blizzard's interface options on RareScanner's category.
    -- RS stashes the categoryID after AddToBlizOptions.
    if _G.Settings and _G.Settings.OpenToCategory and RS and RS.categoryID then
        local ok = pcall(_G.Settings.OpenToCategory, RS.categoryID)
        if ok then return end
    end
    -- Fallback to the standalone AceConfigDialog window if the
    -- Settings API isn't available or rejected the categoryID.
    local LSConfig = _G.LibStub and _G.LibStub("AceConfigDialog-3.0", true)
    if LSConfig then LSConfig:Open("RareScanner General") end
end

local function rareScannerHandler(_, _, click)
    local Nx, RS = _G.Nx, _G.RareScanner
    if not RS or not Nx or not Nx.fdb then return end
    if click == "RightButton" then
        openRareScannerSettings()
        return
    end
    local enabled = not Nx.fdb.profile.Notes.RareScanner
    Nx.fdb.profile.Notes.RareScanner = enabled
    if Nx.Notes and Nx.Notes.BustIntegrationCache then
        Nx.Notes:BustIntegrationCache("RareScanner")
    end
    local map = Nx.Map:GetMap(1)
    if enabled then
        if Nx.Notes and Nx.Notes.RareScanner then
            Nx.Notes:RareScanner(Nx.Map:GetCurrentMapAreaID())
        end
    elseif map then
        map:ClearIconType("!RSR")
    end
end

local function openHandyNotesSettings()
    -- HandyNotes registers its panel via AceConfigDialog:AddToBlizOptions
    -- without stashing the returned categoryID. The modern Settings
    -- API accepts the category name directly, so we don't need it.
    if _G.Settings and _G.Settings.OpenToCategory then
        local ok = pcall(_G.Settings.OpenToCategory, "HandyNotes")
        if ok then return end
    end
    local LSConfig = _G.LibStub and _G.LibStub("AceConfigDialog-3.0", true)
    if LSConfig then LSConfig:Open("HandyNotes") end
end

local function handyNotesHandler(_, _, click)
    local Nx, HN = _G.Nx, _G.HandyNotes
    if not HN or not Nx or not Nx.fdb then return end
    if click == "RightButton" then
        openHandyNotesSettings()
        return
    end
    local enabled = not Nx.fdb.profile.Notes.HandyNotes
    Nx.fdb.profile.Notes.HandyNotes = enabled
    if Nx.Notes and Nx.Notes.BustIntegrationCache then
        Nx.Notes:BustIntegrationCache("HandyNotes")
    end
    if enabled then
        if HN.Enable and not (HN.IsEnabled and HN:IsEnabled()) then HN:Enable() end
        if Nx.Notes and Nx.Notes.HandyNotes then
            Nx.Notes:HandyNotes(Nx.Map:GetCurrentMapAreaID())
        end
    else
        if HN.Disable and HN.IsEnabled and HN:IsEnabled() then HN:Disable() end
        local map = Nx.Map:GetMap(1)
        if map then map:ClearIconType("!HANDY") end
    end
end

-- Dark backdrop behind the icon. Stays inside the button frame so
-- the visible bounds match the rest of the toolbar (extending the
-- backdrop beyond the frame made buttons look 1-2px higher than
-- native MapCombat / MapZIn). Visible only where the icon texture
-- has transparency.
local function addBackdrop(frm)
    if not frm or frm._nxAddonBg then return end
    local bg = frm:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.85)
    bg:SetAllPoints(frm)
    frm._nxAddonBg = bg
end

local function registerOne(typeId, icon, label, handler, initialPressed, tip)
    if AddonButtons.Adopted[typeId] then return end
    local Nx = _G.Nx
    if not Nx or not Nx.Button or not Nx.Button.TypeData then return end

    Nx.Button.TypeData[typeId] = {
        Bool            = true,
        Up              = icon or FALLBACK_ICON,
        Dn              = icon or FALLBACK_ICON,
        SizeUp          = 22,
        SizeDn          = 22,
        Tip             = tip,
        -- Route right-click through our handler instead of opening
        -- the bar's settings menu (Nx.ToolBar:OnBut honors this).
        PassRightClick  = true,
    }

    AddonButtons.Adopted[typeId] = { handler = handler, tip = tip }

    Nx.BarData = Nx.BarData or {}
    local already = false
    for _, b in ipairs(Nx.BarData) do
        if b[1] == typeId then already = true; break end
    end
    if not already then
        table.insert(Nx.BarData,
            { typeId, label, handler, initialPressed and true or false })
    end
end

-- Append our buttons to the existing bar incrementally rather than
-- calling Nx.Map:CreateToolBar a second time. Recreating the bar
-- leaves phantom button frames (the old bar's children stay parented
-- to the reused toolbar Frm), which steal clicks from the new
-- buttons and produce the "left-click does nothing, just highlights"
-- symptom.
local function decorateTool(nxBut, handler, tip)
    local ourFrm = nxBut and nxBut.Frm
    if not (ourFrm and ourFrm.IsObjectType and ourFrm:IsObjectType("Frame")) then return end
    addBackdrop(ourFrm)
    -- (Right-click reaches our handler via the PassRightClick flag
    -- on this button's TypeData — no UserFunc monkey-patch needed.)
    -- Replace OnEnter/OnLeave with our own multi-line tooltip
    -- renderer. Nx:SetTooltipText was only showing the first line for
    -- these buttons (the Nx.Split / SetText+AddLine pipeline returned
    -- early in some path we couldn't trace). Using AddLine directly
    -- gives deterministic multi-line output.
    if tip and tip.title then
        local Nx = _G.Nx
        local TT = Nx and Nx.TooltipText
        local origOnEnter = ourFrm:GetScript("OnEnter")
        local origOnLeave = ourFrm:GetScript("OnLeave")
        ourFrm:SetScript("OnEnter", function(self, motion)
            if origOnEnter then origOnEnter(self, motion) end
            if not TT then return end
            TT:Hide()
            TT:SetOwner(self, "ANCHOR_LEFT", 0, 5)
            TT:ClearLines()
            TT:AddLine(tip.title, 1, 0.84, 0)
            for _, row in ipairs(tip.rows) do
                TT:AddDoubleLine(row[1], row[2],
                    0.5, 0.78, 1, 1, 1, 1)
            end
            TT:Show()
            Nx.TooltipOwner = self
        end)
        ourFrm:SetScript("OnLeave", function(self, motion)
            if origOnLeave then origOnLeave(self, motion) end
            if TT and TT:IsOwned(self) then TT:Hide() end
        end)
    end
end

-- Walks the current bar.Tools, finds the tool whose Nx.Button has the
-- given TypeData, and returns it. Used both for "is our button already
-- in the bar?" and for re-decorating after a toolbar rebuild.
local function findTool(bar, typeId)
    local Nx = _G.Nx
    local typ = Nx and Nx.Button and Nx.Button.TypeData and Nx.Button.TypeData[typeId]
    if not (typ and bar.Tools) then return nil end
    for _, t in ipairs(bar.Tools) do
        if t.But and t.But.Type == typ then return t end
    end
    return nil
end

local function appendOne(typeId, label, handler, initialPressed, tip)
    local map = carboniteMap()
    if not map or not map.ToolBar then return end
    local bar = map.ToolBar
    -- Skip if our button is already a Tool on this bar (Nx.Map's own
    -- CreateToolBar may have already built it from Nx.BarData).
    local existing = findTool(bar, typeId)
    if existing then
        decorateTool(existing.But, handler, tip)
        return
    end
    bar:AddButton(typeId, label, nil, handler, initialPressed and true or false)
    bar:Update()
    local tool = bar.Tools and bar.Tools[#bar.Tools]
    if tool and tool.But then decorateTool(tool.But, handler, tip) end
end

-- Re-apply decorations to every adopted button. Called after a
-- toolbar rebuild — addBackdrop / OnEnter overrides live on the
-- button frame, not on the TypeData, so a fresh frame won't have
-- them. Idempotent thanks to the `frm._nxAddonBg` short-circuit in
-- addBackdrop.
function AddonButtons:RedecorateAll()
    local map = carboniteMap()
    if not map or not map.ToolBar then return end
    for typeId, rec in pairs(self.Adopted) do
        local tool = findTool(map.ToolBar, typeId)
        if tool and tool.But then
            decorateTool(tool.But, rec.handler, rec.tip)
        end
    end
end

local function initialQuestiePressed()
    local Q = _G.Questie
    return Q and Q.db and Q.db.profile and Q.db.profile.enabled or false
end

local function initialHandyNotesPressed()
    local HN = _G.HandyNotes
    return HN and HN.IsEnabled and HN:IsEnabled() or false
end

local QUESTIE_TIP = {
    title = "Questie",
    rows = {
        { L["Left click"],  L["Toggle icons"] },
        { L["Right click"], L["Context menu"] },
    },
}

local HANDYNOTES_TIP = {
    title = "HandyNotes",
    rows = {
        { L["Left click"],  L["Toggle icons"] },
        { L["Right click"], L["Open settings"] },
    },
}

local RARESCAN_TIP = {
    title = "RareScanner",
    rows = {
        { L["Left click"],  L["Toggle icons"] },
        { L["Right click"], L["Open settings"] },
    },
}

local function initialRareScannerPressed()
    local Nx = _G.Nx
    return Nx and Nx.fdb and Nx.fdb.profile and Nx.fdb.profile.Notes
        and Nx.fdb.profile.Notes.RareScanner or false
end

local RXP_TIP = {
    title = "RXPGuides",
    rows = {
        { L["Left click"],  L["Toggle icons"] },
        { L["Right click"], L["Open settings"] },
    },
}

local function initialRXPPressed()
    local Nx = _G.Nx
    return Nx and Nx.fdb and Nx.fdb.profile and Nx.fdb.profile.Notes
        and Nx.fdb.profile.Notes.RXP or false
end

-- Right-click on the RXP button opens RXPGuides' settings panel.
-- RXP exposes the opener at `addon.settings.OpenSettings()` and the
-- internal addon table at `_G.RXP` (RXPGuides.lua line ~2223 stashes
-- it "for debug purposes" but it's stable and the only reliable way
-- to drive the panel programmatically — the public _G.RXPGuides API
-- table doesn't include settings).
local function openRXPSettings()
    local rxp = _G.RXP
    if rxp and rxp.settings and type(rxp.settings.OpenSettings) == "function" then
        pcall(rxp.settings.OpenSettings)
    end
end

local function rxpHandler(_, _, click)
    local Nx, rxp = _G.Nx, _G.RXP
    if not rxp or not Nx or not Nx.fdb then return end
    if click == "RightButton" then
        openRXPSettings()
        return
    end
    local enabled = not Nx.fdb.profile.Notes.RXP
    Nx.fdb.profile.Notes.RXP = enabled
    if Nx.Notes and Nx.Notes.BustIntegrationCache then
        Nx.Notes:BustIntegrationCache("RXP")
    end
    if enabled then
        if Nx.Notes and Nx.Notes.RXP then
            Nx.Notes:RXP(Nx.Map:GetCurrentMapAreaID())
        end
    else
        local map = Nx.Map:GetMap(1)
        if map then map:ClearIconType("!RXP") end
    end
end

-- Make sure decorations survive any future Nx.Map:CreateToolBar
-- rebuild — Notes/Warehouse Init each call it, and #2's phantom
-- cleanup now destroys the old button frames (including our
-- backdrop child texture + OnEnter/OnLeave overrides).
local function ensureCreateToolBarHook()
    if AddonButtons.CreateToolBarHooked then return end
    local Nx = _G.Nx
    if not Nx or not Nx.Map then return end
    if not hooksecurefunc then return end
    hooksecurefunc(Nx.Map, "CreateToolBar", function()
        AddonButtons:RedecorateAll()
    end)
    AddonButtons.CreateToolBarHooked = true
end

local function tryAdopt()
    ensureCreateToolBarHook()
    if _G.Questie and _G.QuestieLoader
        and not AddonButtons.Adopted["AddonBtn_Questie"] then
        registerOne("AddonBtn_Questie", QUESTIE_ICON, "Questie",
            questieHandler, initialQuestiePressed(), QUESTIE_TIP)
        appendOne("AddonBtn_Questie", "Questie",
            questieHandler, initialQuestiePressed(), QUESTIE_TIP)
    end
    if _G.HandyNotes
        and not AddonButtons.Adopted["AddonBtn_HandyNotes"] then
        registerOne("AddonBtn_HandyNotes", handyNotesIcon(), "HandyNotes",
            handyNotesHandler, initialHandyNotesPressed(), HANDYNOTES_TIP)
        appendOne("AddonBtn_HandyNotes", "HandyNotes",
            handyNotesHandler, initialHandyNotesPressed(), HANDYNOTES_TIP)
    end
    if _G.RareScanner
        and not AddonButtons.Adopted["AddonBtn_RareScanner"] then
        registerOne("AddonBtn_RareScanner", RARESCAN_ICON, "RareScanner",
            rareScannerHandler, initialRareScannerPressed(), RARESCAN_TIP)
        appendOne("AddonBtn_RareScanner", "RareScanner",
            rareScannerHandler, initialRareScannerPressed(), RARESCAN_TIP)
    end
    if _G.RXP
        and not AddonButtons.Adopted["AddonBtn_RXP"] then
        registerOne("AddonBtn_RXP", RXP_ICON, "RXPGuides",
            rxpHandler, initialRXPPressed(), RXP_TIP)
        appendOne("AddonBtn_RXP", "RXPGuides",
            rxpHandler, initialRXPPressed(), RXP_TIP)
    end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", function()
    tryAdopt()
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(2, tryAdopt)
        _G.C_Timer.After(5, tryAdopt)
    end
end)

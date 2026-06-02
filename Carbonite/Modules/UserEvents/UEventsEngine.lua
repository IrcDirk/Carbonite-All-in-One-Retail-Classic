-- Carbonite | Modules / UserEvents / UEventsEngine
-- The Nx.UEvents class: per-character "user event" tracking
-- (kills, deaths, gather drops, info entries, achievements) plus
-- the windowed event-list display. Lifted out of Carbonite.lua.
--
-- Public surface lives in UserEvents.lua / EventHandlers.lua /
-- EventLog.lua; this file owns the engine. Methods remain on
-- Nx.UEvents because:
--   * NXOnUpdate calls Nx.UEvents:Sort / UpdateAll
--   * The OnUnit_spellcast_sent handler in EventHandlers.lua calls
--     Nx.UEvents:AddHerb / AddMine / AddOpen / AddTimber
--   * Nx.UEvents.List is a sub-table; List:Open / Update are
--     attached via that table.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-- Kill / Death pin classes. Registered once at file-load so
-- UpdateMap doesn't have to re-declare metadata each pass. The Pin
-- class metadata (drawMode / w / h / tex / clipKind / noDockMinimap)
-- is read by the map renderer; per-event state (X/Y/tip) goes on
-- each pin instance.
do
    local Pin = _G.Carbonite and _G.Carbonite.Modules
        and _G.Carbonite.Modules.Map and _G.Carbonite.Modules.Map.Pin
    if Pin then
        Pin.Define("Kill", {
            drawMode = "WP",
            w = 32, h = 32,
            tex = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
            clipKind = "chop",
            noDockMinimap = true,
        })
        Pin.Define("Death", {
            drawMode = "WP",
            w = 32, h = 32,
            tex = "Interface\\TargetingFrame\\UI-TargetingFrame-Seal",
            clipKind = "chop",
            noDockMinimap = true,
        })
    end
end

-------------------------------------------------------------------------------
-- USER EVENTS SYSTEM
-- Records and displays player activities (kills, deaths, gathering, etc.)
-------------------------------------------------------------------------------

---
-- Initialize user events module
--
function Nx.UEvents:Init()
    -- self.Sorted = {}
end

---
-- Add an info event to the log
-- @param name  Description of the event
-- @return      Map ID where event occurred
--
function Nx.UEvents:AddInfo (name)

    local mapId, x, y = self:GetPlyrPos()

    Nx:AddInfoEvent (name, Nx:Time(), mapId, x, y)

    self:UpdateAll()

    return mapId
end

---
-- Add a player death event
-- @param name  Cause of death description
--
function Nx.UEvents:AddDeath (name)

    local mapId, x, y = self:GetPlyrPos()

    Nx:AddDeathEvent (name, Nx:Time(), mapId, x, y)

    self:UpdateAll()

--    Nx:SendComm (2, "Death "..name)

    if Nx.Map:IsBattleGroundMap (mapId) then
--        Nx.prt ("Req D")
        RequestBattlefieldScoreData()
    end
end

---
-- Add a kill event
-- @param name   Name of killed enemy
-- @param npcId  Optional NPC ID (parsed from the destGUID by the caller)
--
function Nx.UEvents:AddKill (name, npcId)

    local mapId, x, y = self:GetPlyrPos()

    Nx:AddKillEvent (name, Nx:Time(), mapId, x, y, npcId)

    self:UpdateAll()
end

---
-- Add an honor event
-- @param name  Honor event description
--
function Nx.UEvents:AddHonor (name)

    local mapId = self:AddInfo (name)

    if Nx.Map:IsBattleGroundMap (mapId) then
--        Nx.prt ("Req H")
        RequestBattlefieldScoreData()
    end
end

---
-- Add an herb gathering event
-- @param name  Name of the herb gathered
--
function Nx.UEvents:AddHerb (name)

    local mapId, x, y, level = self:GetPlyrPos()
    mapId = Nx.Map:GetCurrentMapAreaID()
    if Nx.db.profile.Guide.GatherEnabled then
        local id = Nx:HerbNameToId (name)
        if id then
            Nx:AddHerbEvent (name, Nx:Time(), mapId, x, y)
            Nx:GatherHerb (id, mapId, x, y, level)
        end
        self:UpdateAll (true)
    end
end

---
-- Add a mining event
-- @param name  Name of the ore mined
--
function Nx.UEvents:AddMine (name)
    local mapId, x, y, level = self:GetPlyrPos()
    mapId = Nx.Map:GetCurrentMapAreaID()
    if Nx.db.profile.Guide.GatherEnabled then
        local id = Nx:MineNameToId (name)
        if id then
            Nx:AddMineEvent (name, Nx:Time(), mapId, x, y)
            Nx:GatherMine (id, mapId, x, y, level)
        end
        self:UpdateAll (true)
    end
end

---
-- Add a timber logging event
-- @param name  Name of the timber logged
--
function Nx.UEvents:AddTimber (name)
    local mapId, x, y, level = self:GetPlyrPos()
    mapId = Nx.Map:GetCurrentMapAreaID()
    if Nx.db.profile.Guide.GatherEnabled then
        local size = false
        if name == L["Small Timber"] then
            size = 1
        elseif name == L["Timber"] or name == L["Medium Timber"] then
            size = 2
        elseif name == L["Large Timber"] then
            size = 3
        end
        if size then
            Nx:AddTimberEvent (name, Nx:Time(), mapId, x, y)
            Nx:GatherTimber (size, mapId, x, y, level)
        end
        self:UpdateAll (true)
    end
end

---
-- Add a chest/container opening event
-- @param typ   Type of opening (e.g., "Art" for artifact)
-- @param name  Name of what was opened
--
function Nx.UEvents:AddOpen (typ, name)

    local mapId = self:AddInfo (name)
    if Nx.db.profile.Guide.GatherEnabled then
        local mapId, x, y, level = self:GetPlyrPos()
        mapId = Nx.Map:GetCurrentMapAreaID()
        Nx:Gather ("Misc", typ, mapId, x, y, level)
        self:UpdateAll()
    end
end

---
-- Get current player map position
-- @return  mapId, x, y, dungeonLevel
--
function Nx.UEvents:GetPlyrPos()
    local mapId = Nx.Map:GetRealMapId()
    local map = Nx.Map:GetMap (1)
    if not map then
        return mapId, nil, nil, Nx.Map.DungeonLevel
    end
    return mapId, map.PlyrRZX, map.PlyrRZY, Nx.Map.DungeonLevel
end

--------

function Nx.UEvents:UpdateAll (upGuide)

    self:Sort()
    self:UpdateMap (upGuide)
    self.List:Update()
end

--------
-- Sort compare

function Nx.UEvents.SortCmp (v1, v2)

--    prtD ("Sort "..v1.Time.." "..v2.Time)

    local _, tm1 = Nx.Split ("^", v1)
    local _, tm2 = Nx.Split ("^", v2)

    return tonumber (tm1) < tonumber (tm2)
end

--------

function Nx.UEvents:Sort()

--    wipe (self.Sorted)

--    Nx:AddAllEvents (self.Sorted)

--    sort (self.Sorted, self.SortCmp)

    sort (Nx.CurCharacter.E, self.SortCmp)        -- Should already be sorted, but whatever
end

--------
-- Open and init or toggle user events list

function Nx.UEvents.List:Open()

    local UEvents = Nx.UEvents

    local win = self.Win

    if win then
        if win:IsShown() then
            win:Show (false)
        else
            win:Show()
        end
        return
    end

    -- Create Window

    local win = Nx.Window:Create ("NxEventsList", nil, nil, nil, nil, nil, true)
    self.Win = win

    win:CreateButtons (true)

    win:InitLayoutData (nil, -.75, -.6, -.25, -.1)

    local list = Nx.List:Create ("Events", 2, -2, 100, 12 * 3, win.Frm)
    self.List = list
    list:ColumnAdd (L["Time"], 1, 70)
    list:ColumnAdd (L["Event"], 2, 140)
    list:ColumnAdd ("#", 3, 30, "CENTER")
    list:ColumnAdd (L["Position"], 4, 500)

    win:Attach (list.Frm, 0, 1, 0, 1)

    UEvents:UpdateAll()
end

------
function Nx.UEvents.List:Update()

    local Nx = Nx
    local UEvents = Nx.UEvents

    if not self.Win then
        return
    end

    local sorted = Nx.CurCharacter.E

    self.Win:SetTitle (format (L["Events"] .. ": %d", #sorted))

    local list = self.List
    local isLast = list:IsShowLast()
    list:Empty()

    for k, item in ipairs (sorted) do

        local typ, tm, mapId, x, y, text, data = Nx:UnpackEvent (item)

        list:ItemAdd()
        list:ItemSet (1, date ("%d %H:%M:%S", tm / 100))

        local eStr = text

        if typ == "D" then

            eStr = "|cffff6060" .. L["Died"] .. "! " .. text

        elseif typ == "K" then

            list:ItemSet (3, data)

            eStr = "|cffff60ff" .. L["Killed"] .. " " .. text

        elseif typ == "H" then

            eStr = "|cff60ff60" .. L["Picked"] .. " " .. text

        elseif typ == "M" then

            eStr = "|cffc0c0c0" .. L["Mined"] .. " " .. text

        elseif typ == "F" then

            eStr = "|cffc0c0c0" .. L["Fished"] .. " " .. text

        end
        list:ItemSet (2, eStr)

        local mapName = Nx.Map:IdToName (mapId)

        local str = format ("%s %.0f %.0f", mapName, x, y)
        list:ItemSet (4, str)
    end

    list:Update (isLast)
end

------
-- Update user event data on map

function Nx.UEvents:UpdateMap (upGuide)

--    Nx.prt ("UEvents:UpdateMap")

    local Nx = Nx
    local Map = Nx.Map

    local mapId = Map:GetCurrentMapId()
    local m = Map:GetMap (1)

    if m then

        if upGuide then
            m.Guide:Update()
        end

        -- Pin classes are declared at file-load (see top of file).
        -- Each UpdateMap pass refreshes the Kill / Death layers from
        -- the saved event list.
        local Pin   = Carbonite.Modules.Map.Pin
        local Layer = Carbonite.Modules.Map.Layer
        local killLayer  = Layer.Get("Kill")
        local deathLayer = Layer.Get("Death")
        killLayer:Clear()
        deathLayer:Clear()

        -- Read kill-icon settings from Carbonite.Info if loaded; default to
        -- "show, no auto-expire" when Info isn't present.
        local killEnabled = true
        local autoClearSecs = 0
        local keepForever = false
        if Nx.idb and Nx.idb.profile and Nx.idb.profile.Info then
            killEnabled = Nx.idb.profile.Info.KillIcons
            autoClearSecs = Nx.idb.profile.Info.KillIconAutoClearSecs or 0
            keepForever = Nx.idb.profile.Info.KillIconKeepForever or false
        end

        local now = Nx:Time()
        local events = Nx.CurCharacter.E

        -- Build a multi-line tooltip for kill/death markers: branding line,
        -- name, kill time (decoded from the *100 Nx:Time() format), and an
        -- optional NPC ID line when the captured destGUID supplied one.
        local function buildKillTip(name, tm, dataField, isDeath)
            local realTm = tm and math.floor(tm / 100) or 0
            local timeStr = realTm > 0 and date("%H:%M:%S  %Y-%m-%d", realTm) or "?"
            local kills, npcId = strsplit("|", dataField or "")
            local label = isDeath
                and ("[Carbonite.Info  " .. (L["death"] or "death") .. "]")
                or  ("[Carbonite.Info  " .. (L["kill"] or "kill") .. "]")
            local lines = {
                "|cff8080ff" .. label .. "|r",
                name or "?",
                "|cffa0a0a0" .. timeStr .. "|r",
            }
            if kills and tonumber(kills) and tonumber(kills) > 1 then
                lines[#lines + 1] = "|cffa0a0a0" .. format(L["kills: %s"] or "kills: %s", kills) .. "|r"
            end
            if npcId and npcId ~= "" then
                lines[#lines + 1] = "|cffa0a0a0" .. format(L["NPC ID: %s"] or "NPC ID: %s", npcId) .. "|r"
            end
            return table.concat(lines, "\n")
        end

        -- Walk in reverse so we can splice expired entries when the user has
        -- NOT opted into "keep history forever". With KeepForever the timer
        -- only suppresses display — the records remain in saved variables.
        for k = #events, 1, -1 do
            local item = events[k]
            local iMapId = Nx:GetEventMapId (item)
            local typ, tm, _, x, y, text, data = Nx:UnpackEvent (item)
            local isKillish = (typ == "K" or typ == "D")

            -- Nx:Time() = time()*100 + frac, so threshold needs *100 too.
            local expired = isKillish and autoClearSecs > 0 and tm
                                and (now - tm) > autoClearSecs * 100

            if expired and not keepForever then
                table.remove(events, k)
            elseif iMapId == mapId and isKillish and killEnabled and not expired then
                local wx, wy = m:GetWorldPos (iMapId, x, y)
                local kind = (typ == "K") and "Kill" or "Death"
                local pin = Pin.Acquire(kind)
                pin.x, pin.y = wx, wy
                pin.X, pin.Y = wx, wy   -- legacy aliases for IconOnEnter
                pin.tip      = buildKillTip(text, tm, data, typ == "D")
                pin.Tip      = pin.tip
                pin.EventIndex = k
                pin.iconType = kind     -- legacy field used by tooltip code
                if typ == "K" then killLayer:Add(pin) else deathLayer:Add(pin) end
            end
            -- expired AND keepForever: silently skip drawing, keep record.
        end

    end
end

-------------------------------------------------------------------------------
-- The Gather subsystem (Nx.GatherInfo / Nx.GatherRemap / Nx.GatherCache /
-- Nx:GatherInit / GetGather / IsGathering / HerbNameToId / MineNameToId /
-- GatherHerb / Mine / Timber / Gather / GatherUnpack / GatherDelete* /
-- GatherImportCarb* / GatherImportBatch / GatherNodeToCarb / GatherConvert)
-- lives in Modules/Gather/GatherStorage.lua.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- The Nx.Item class (Init / Load / EnableLoadFromServer / DisableLoadFromServer
-- / AskDeleteVV / ShowTooltip / DrawTimer) lives in
-- Modules/ItemRegistry/ItemEngine.lua.
--
-- The Nx.NXMiniMapBut class (Init / right-click menu / mouse handlers /
-- drag-to-reposition / profiling toggle / Move) plus the Nx.ModChatReceive
-- stub live in Modules/Map/MinimapButtonEngine.lua.
-------------------------------------------------------------------------------

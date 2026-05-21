-- Carbonite.Notes | Record
-- Note + waypoint recording. The Map's AddTarget pipeline calls
-- Nx.Notes:Record("Target" / "TargetS", ...) whenever a target is
-- added so the Notes window can list them; this file owns those
-- recorders plus the per-zone "My Notes" folder lookup and the
-- chat-string entrypoint Nx.Notes:SetNoteAtStr.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Notes", true)

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

---
-- Record a note or target at the current location.
-- @param typ    Type ("Note", "TargetS", "Target")
-- @param name   Note name
-- @param id     Map ID
-- @param x      X coordinate
-- @param y      Y coordinate
-- @param level  Dungeon level (optional)
--
function Nx.Notes:Record(typ, name, id, x, y, level)
    if self.InUpdateTarget then return end

    self.RecId = id
    self.RecX  = x
    self.RecY  = y
    self.RecL  = level or 0

    if typ == "Note" then

        local function func(noteName, ctx)
            local fav = ctx.Recording or ctx:GetNoteFav(ctx.RecId)
            local s = ctx:CreateItem("N", 0, noteName, 1,
                                     ctx.RecId, ctx.RecX, ctx.RecY, ctx.RecL)
            ctx:AddItem(fav, ctx.CurItemI, s)
            ctx:Update()
        end

        Nx:ShowEditBox("Name", name, self, func)

    elseif typ == "TargetS" then  -- Start

        local fav = self.Recording
        if fav then
            local s = self:CreateItem("T", 0, name,
                                      self.RecId, self.RecX, self.RecY, self.RecL)
            self:AddItem(fav, self.CurItemI, s)
            self:Update()
        end

    elseif typ == "Target" then

        local fav = self.Recording
        if fav then
            local s = self:CreateItem("t", 0, name,
                                      self.RecId, self.RecX, self.RecY, self.RecL)
            self:AddItem(fav, self.CurItemI, s)
            self:Update()
        end
    end
end

-- Returns (creating if needed) the per-zone favorites folder under
-- the user's "My Notes" root. Used by Record() and SetNoteAtStr().
function Nx.Notes:GetNoteFav(mapId)
    local notes = self:FindFolder(L["My Notes"])
    if not notes then
        notes = self:AddFolder(L["My Notes"])
    end

    local name = Nx.Map:IdToName(mapId)
    local fav  = self:FindFav(name, "Name", notes)

    if not fav then
        fav = self:AddFavorite(name, notes)
        fav["ID"] = mapId
        sort(notes, function(a, b) return a["Name"] < b["Name"] end)
    end

    return fav
end

-- Slash-command / chat entrypoint: parse a "name x y" / 'name "x y"'
-- string into a note record at the player's current zone position
-- (or at coords explicitly given as a target string).
function Nx.Notes:SetNoteAtStr(str)
    local words = {}
    local quote
    local strDone
    local curStr = ""

    for s in gmatch(str, ".") do
        if s == quote then
            quote   = false
            strDone = true
        elseif not quote and (s == '"' or s == "'") then
            quote = s
        elseif s == ' ' and not quote then
            strDone = true
        else
            curStr = curStr .. s
        end

        if strDone then
            if #curStr > 0 then tinsert(words, curStr) end
            strDone = false
            curStr  = ""
        end
    end

    if #curStr > 0 then tinsert(words, curStr) end

    local map   = Nx.Map:GetMap(1)
    local mId   = map.RMapId
    local zx    = map.PlyrRZX
    local zy    = map.PlyrRZY
    local level = map.DungeonLevel

    if #words > 1 then
        mId, zx, zy = map:ParseTargetStr(table.concat(words, " ", 2))
    end

    if mId then
        local fav = self.Recording or self:GetNoteFav(mId)
        local s = self:CreateItem("N", 0, words[1] or "", 1, mId, zx, zy, level)
        self:AddItem(fav, nil, s)
        self:Update()
    end
end

-- Carbonite.Notes | Storage
-- Folder / favorite / item data operations. Nothing here touches
-- the map or the window directly; this file owns the tree
-- traversal and the "~" / "|" packed string format used to store
-- individual items inside a favorite list.
--
-- Item formats:
--   Comment:   ~<flags>~<name>
--   Note ("N"): N~<flags>~<name>~<iconIdx>|<mapId>|<x>|<y>|<dLvl>
--   Target ("T" or "t"): T~<flags>~<name>~<mapId>|<x>|<y>|<dLvl>

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

-- Selects the current favorite in the list. Side-effect: drives the
-- List widget to re-run its user-select pipeline and snaps the
-- first item into view.
function Nx.Notes:SelectCur()
    self.List:SendUserSelect()
    self:SelectItems(1)
end

-- Walks the folder tree looking for the parent folder of `item`.
-- Returns the folder table or nil.
function Nx.Notes:GetParent(item, folder)
    folder = folder or self.Folders

    for _, it in ipairs(folder) do
        if it == item then return folder end

        if it["T"] == "F" then
            local v = self:GetParent(item, it)
            if v then return v end
        end
    end
end

-- Linear lookup by folder name.
function Nx.Notes:FindFolder(name, parent)
    parent = parent or self.Folders
    for _, item in ipairs(parent) do
        if item["T"] == "F" and item["Name"] == name then
            return item
        end
    end
end

-- Linear lookup by an arbitrary field name on each fav entry.
function Nx.Notes:FindFav(val, varName, parent)
    parent = parent or self.Folders
    for _, item in ipairs(parent) do
        if item["T"] == nil and item[varName] == val then
            return item
        end
    end
end

-- Expands every folder on the path from the root to `item`. Returns
-- the index within the leaf folder, or nil if not found.
function Nx.Notes:OpenFoldersToFav(item, folder)
    folder = folder or self.Folders

    for index, it in ipairs(folder) do
        if it == item then return index end

        if it["T"] == "F" then
            local found = self:OpenFoldersToFav(item, it)
            if found then
                it["Hide"] = nil
                return found
            end
        end
    end
end

-- Returns the list-row index of `item`. Used by the list widget to
-- scroll-into-view. Returns a negative number when not found; the
-- magnitude is the row count walked, used by recursion to chain.
function Nx.Notes:FindListI(item, folder, index)
    folder = folder or self.Folders
    index  = index or 1

    for _, it in ipairs(folder) do
        if it == item then return index end
        index = index + 1

        if it["T"] == "F" and not it["Hide"] then
            index = self:FindListI(item, it, index)
            if index > 0 then return index end   -- Found
            index = -index
        end
    end

    return -index   -- Failed
end

function Nx.Notes:AddFolder(name, parent, index)
    local folder = { Name = name, T = "F" }
    parent = parent or self.Folders
    if parent then
        index = index or #parent + 1
        tinsert(parent, index, folder)
    end
    return folder
end

function Nx.Notes:AddFavorite(name, parent, index)
    local fav = { Name = name }
    parent = parent or self.Folders
    if parent then
        index = index or #parent + 1
        tinsert(parent, index, fav)
    end
    return fav
end

function Nx.Notes:AddItem(fav, index, item)
    if not fav then return end
    local i = max(min(index or 999999, #fav), 0) + 1
    tinsert(fav, i, item)
    self:SelectItems(i)
end

function Nx.Notes:CreateItem(typ, flags, name, p1, p2, p3, p4, p5)
    p5    = p5 or 0
    flags = flags + 35

    name = gsub(name, "[~^]", "")
    name = gsub(name, "\n", " ")

    if typ == "" then               -- Comment
        return format("~%c~%s", flags, name)
    elseif typ == "N" then          -- Note
        return format("N~%c~%s~%s|%s|%s|%s|%s", flags, name, p1, p2, p3, p4, p5)
    elseif typ == "T" or typ == "t" then  -- Target
        return format("%s~%c~%s~%s|%s|%s|%s", typ, flags, name, p1, p2, p3, p5)
    end
end

function Nx.Notes:MakeXY(x, y)
    local s = Nx:PackXY(x, y % 100)
    return s .. strchar(floor(y / 100) + 35)   -- dungeon level appended
end

function Nx.Notes:ParseItem(item)
    if item then
        return strsplit("~", item)   -- Type ~ Flags ~ Name ~ Data
    end
end

function Nx.Notes:ParseItemNote(data)
    local iconI, zone, x, y, dLvl = Nx.Split("|", data)
    if not dLvl then dLvl = 0 end
    return tonumber(iconI), tonumber(zone), tonumber(x), tonumber(y), tonumber(dLvl)
end

function Nx.Notes:ParseItemTarget(data)
    local zone, x, y, dLvl = Nx.Split("|", data)
    if not dLvl then dLvl = 0 end
    return tonumber(zone), tonumber(x), tonumber(y), tonumber(dLvl)
end

function Nx.Notes:GetItemTypeName(index)
    local fav = self.CurFav
    if fav then
        local typ, _, name = strsplit("~", fav[index])
        return typ, name
    end
end

function Nx.Notes:SetItemFlags(index, mask, orFlags)
    local fav = self.CurFav
    if not fav then return end

    local typ, flags, name, data = strsplit("~", fav[index])
    flags = bit.bor(bit.band(strbyte(flags) - 35, mask), orFlags) + 35

    if data then
        fav[index] = format("%s~%c~%s~%s", typ, flags, name, data)
    else
        fav[index] = format("%s~%c~%s", typ, flags, name)
    end
end

function Nx.Notes:SetItemName(index, name)
    name = gsub(name, "[~^]", "")
    name = gsub(name, "\n", " ")

    local fav = self.CurFav
    if not fav then return end

    local typ, flags, _, data = strsplit("~", fav[index])
    if data then
        fav[index] = format("%s~%s~%s~%s", typ, flags, name, data)
    else
        fav[index] = format("%s~%s~%s", typ, flags, name)
    end
end

---
-- Select an item in the item list.
-- @param index  Item index to select
--
function Nx.Notes:SelectItems(index)
    if not self.CurFav then return end

    if self.Recording ~= self.CurFav then
        self:SetRecord(false)
    end

    self.CurItemI = min(index, #self.CurFav)
    self:UpdateItems(self.CurItemI)
    self:UpdateTargets()
    GameTooltip:Hide()
end

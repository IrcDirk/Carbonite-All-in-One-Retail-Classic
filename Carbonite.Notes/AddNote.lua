-- Carbonite.Notes | AddNote
-- Public entrypoints for adding a note. Three flavors:
--   * Nx.Notes:Menu_OnAddNote    - "Add note here" from the map's
--                                  right-click menu (uses the click
--                                  position)
--   * Nx.Notes:AddNote           - quietly add a note at given
--                                  coords (used by data importers)
--   * Nx.Notes:AddonNote         - cross-addon hook; stores a note
--                                  in Nx.Notes.addonNotes keyed by
--                                  the calling addon's folder name
-- Also hosts Nx.Notes:OnButToggleFav (the minimap button click
-- handler) and Nx:GetFav (legacy public data accessor).

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}
Nx.Notes.addonNotes = Nx.Notes.addonNotes or {}

function Nx.Notes:OnButToggleFav(but)
    Nx.Notes:ToggleShow()
end

-- Returns the favorites data table (the legacy NotesDB profile).
function Nx:GetFav()
    return Nx.fdb.profile.Notes
end

-- Map right-click → "Add note here". Reads the click frame coords
-- back to map space via the legacy FramePos helpers (which now flow
-- through Modules/Map/FrameToWorld), then funnels into AddNote.
function Nx.Notes:Menu_OnAddNote()
    local map     = Nx.Map:GetMap(1)
    local mId     = map.RMapId
    local wx, wy  = self:FramePosToWorldPos(self.ClickFrmX, self.ClickFrmY)
    local zx, zy  = self:GetZonePos(mId, wx, wy)
    local level   = map.DungeonLevel
    Nx.Notes:AddNote("?", mId, zx, zy, level)
end

function Nx.Notes:AddNote(name, id, x, y, level)
    Nx.Notes:Record("Note", name, id, x, y, level)
end

-- Cross-addon entry point. External addons call this with their own
-- folder name; the notes live in Nx.Notes.addonNotes and are drawn
-- by MapIcons.lua's `!Fav` per-frame producer.
function Nx.Notes:AddonNote(folder, name, icon, id, x, y)
    local store = Nx.Notes.addonNotes
    if not store[folder] then
        store[folder] = { notes = {} }
    end
    store[folder].notes[name] = icon .. "|" .. id .. "|" .. x .. "|" .. y
end

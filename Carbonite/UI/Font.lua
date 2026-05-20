-- Carbonite | UI / Font
-- Owns Carbonite's named font registry. Replaces Nx.Font's bespoke
-- font-object cache with a class-based registry that other modules
-- can extend via `Font:Define`. Older code keeps working through the
-- `Nx.Font` alias installed at the bottom of this file.
--
-- A font entry is described by:
--   { fontObjectName, inheritName, dbScope }
-- where:
--   fontObjectName  - global FontObject name created via CreateFont()
--   inheritName     - existing Blizzard font object to copy initial
--                     metrics from
--   dbScope         - which DB on Carbonite ("db", "fdb", "qdb") holds
--                     the user's chosen face/size/spacing for this slot

local Carbonite = _G.Carbonite
local Font = {}
Carbonite.UI.Font = Font

-- Built-in font slots. Modules use them by name (e.g. "Font.Map").
Font.slots = {
    ["Font.Small"]  = { object = "NxFontS",      inherit = "GameFontNormalSmall", scope = "db" },
    ["Font.Medium"] = { object = "NxFontM",      inherit = "GameFontNormal",      scope = "db" },
    ["Font.Map"]    = { object = "NxFontMap",    inherit = "GameFontNormalSmall", scope = "db" },
    ["Font.MapLoc"] = { object = "NxFontMapLoc", inherit = "GameFontNormalSmall", scope = "db" },
    ["Font.Menu"]   = { object = "NxFontMenu",   inherit = "GameFontNormalSmall", scope = "db" },
}

-- Built-in font faces. LibSharedMedia-discovered fonts append here.
Font.faces = {
    { "Arial",    "Fonts\\ARIALN.TTF" },
    { "Friz",     "Fonts\\FRIZQT__.TTF" },
    { "Morpheus", "Fonts\\MORPHEUS.TTF" },
    { "Skurri",   "Fonts\\SKURRI.TTF" },
}

-- Faces sourced from external addons; tracked separately so a rescan
-- does not duplicate them.
Font.facesByName = {
    ["Arial Narrow"]    = true,
    ["Friz Quadrata TT"] = true,
    ["Morpheus"]        = true,
    ["Skurri"]          = true,
}

local function ensureFontObject(slot)
    if slot.fontObject then return slot.fontObject end
    local obj = CreateFont(slot.object)
    obj:SetFontObject(slot.inherit)
    slot.fontObject = obj
    return obj
end

-- Creates every slot's FontObject. Safe to call repeatedly.
function Font:Init()
    for _, slot in pairs(self.slots) do ensureFontObject(slot) end
    self:ScanShared()
    self:Update()
    self.initialized = true
end

-- Add a slot at runtime (used by modules that bring their own font lines).
function Font:Define(key, spec)
    self.slots[key] = {
        object  = spec.object  or ("NxFont" .. key:gsub("%W", "")),
        inherit = spec.inherit or "GameFontNormalSmall",
        scope   = spec.scope   or "db",
    }
    ensureFontObject(self.slots[key])
    if self.initialized then self:Update() end
end

-- LibSharedMedia-3.0 integration. Imports any font face it knows about
-- so users can pick TTFs from other addons (ElvUI, SharedMedia, etc.).
function Font:ScanShared()
    local sm = LibStub("LibSharedMedia-3.0", true)
    if not sm then return false end

    local found = false
    for _, name in ipairs(sm:List("font") or {}) do
        if not self.facesByName[name] then
            local path = sm:Fetch("font", name)
            if path then
                self.facesByName[name] = path
                table.insert(self.faces, { name, path })
                found = true
            end
        end
    end
    return found
end

function Font:GetObject(key)
    local slot = self.slots[key]
    return slot and ensureFontObject(slot) or nil
end

function Font:GetHeight(key)
    local slot = self.slots[key]
    return slot and slot.height or 12
end

function Font:GetFaceIndex(name)
    for i, v in ipairs(self.faces) do if v[1] == name then return i end end
    return 1
end

function Font:GetFaceName(index)
    local v = self.faces[index]
    return v and v[1]
end

function Font:GetFacePath(name)
    for _, v in ipairs(self.faces) do if v[1] == name then return v[2] end end
    return self.faces[2][2]  -- default = Friz
end

-- Apply the user-saved size/face/spacing to each slot. Called on init
-- and whenever the user changes a setting in the Options page.
function Font:Update()
    local Nx = _G.Nx
    if not Nx or not Nx.db then return end

    for key, slot in pairs(self.slots) do
        local obj = ensureFontObject(slot)
        local fname, _, flags = obj:GetFont()
        local profile = Nx[slot.scope] and Nx[slot.scope].profile
        if profile then
            local cat, sub = key:match("^(.-)%.(.+)$")
            local profileCat = cat and profile[cat]
            if profileCat then
                local file = self:GetFacePath(profileCat[sub])
                local size = profileCat[sub .. "Size"] or 12
                obj:SetFont(file, size, flags)
                slot.height = math.max(size + (profileCat[sub .. "Spacing"] or 0), 6)
            end
        end
    end

    -- Tell the legacy List + Window subsystems to redraw. Done by name
    -- so we do not fight the older Nx.List/Nx.Window load order.
    if _G.Nx and _G.Nx.List and _G.Nx.List.NextUpdateFull then _G.Nx.List:NextUpdateFull() end
    if _G.Nx and _G.Nx.Window and _G.Nx.Window.AdjustAll then _G.Nx.Window:AdjustAll() end
end

-- Legacy compatibility: rewire Nx.Font onto this module so existing
-- call sites in NxUI.lua and elsewhere keep functioning.
Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", function()
    if not _G.Nx then return end
    _G.Nx.Font = _G.Nx.Font or {}
    local target = _G.Nx.Font
    target.Init       = function(self) Font:Init() end
    target.ModuleAdd  = function(self, key, value)
        Font:Define(key, { object = value[1], inherit = value[2], scope = value[3] })
    end
    target.AddonLoaded = function()
        if Font.initialized and Font:ScanShared() then Font:Update() end
    end
    target.FontScan    = function(_, libName) return Font:ScanShared(libName) end
    target.GetObj      = function(_, name)  return Font:GetObject(name) end
    target.GetH        = function(_, name)  return Font:GetHeight(name) end
    target.GetIndex    = function(_, name)  return Font:GetFaceIndex(name) end
    target.GetName     = function(_, index) return Font:GetFaceName(index) end
    target.GetFile     = function(_, name)  return Font:GetFacePath(name) end
    target.Update      = function() Font:Update() end
    target.Fonts       = Font.slots
    target.Faces       = Font.faces
    target.AddonFonts  = Font.facesByName
end)

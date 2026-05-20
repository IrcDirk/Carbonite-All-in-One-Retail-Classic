-- Carbonite | Util / ClassColors
-- Wrapper around RAID_CLASS_COLORS and the user's optional
-- CUSTOM_CLASS_COLORS override + the precomputed
-- Nx.ClassColorStrs ("|cff..." string table) the legacy code
-- builds at login.
--
-- Public API:
--   ClassColors:Get(classToken)        -> { r, g, b }
--   ClassColors:GetString(classToken)  -> "|cff..." prefix
--   ClassColors:Each(fn)               - iterate every class
--   ClassColors:UsesCustom()           -> bool

local Carbonite = _G.Carbonite
local ClassColors = {}
Carbonite.Util.ClassColors = ClassColors

local function table_() return _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS end

function ClassColors:UsesCustom() return _G.CUSTOM_CLASS_COLORS ~= nil end

function ClassColors:Get(classToken)
    if not classToken then return nil end
    local t = table_()
    return t and t[classToken]
end

function ClassColors:GetString(classToken)
    local Nx = _G.Nx
    if Nx and Nx.ClassColorStrs and Nx.ClassColorStrs[classToken] then
        return Nx.ClassColorStrs[classToken]
    end
    local c = self:Get(classToken)
    if not c then return "|cffffffff" end
    return ("|cff%02x%02x%02x"):format(
        math.floor((c.r or 1) * 255),
        math.floor((c.g or 1) * 255),
        math.floor((c.b or 1) * 255))
end

function ClassColors:Each(fn)
    local t = table_()
    if not t then return end
    for token, c in pairs(t) do
        if type(c) == "table" and c.r then fn(token, c) end
    end
end

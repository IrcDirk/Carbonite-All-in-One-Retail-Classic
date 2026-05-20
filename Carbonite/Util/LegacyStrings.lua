-- Carbonite | Util / LegacyStrings
-- Compatibility wrappers around the legacy Nx.Split / Nx.Util_str2rgba
-- family. The originals are still defined in Carbonite.lua / NxUI.lua;
-- this module gives them a clean API name so new code doesn't have
-- to know which legacy file owns each helper.
--
-- The functions mirror the legacy semantics 1:1 - we proxy through to
-- the global Nx.* version so any future legacy fix flows through to
-- callers of this module too.

local Carbonite = _G.Carbonite

local LegacyStrings = {}
Carbonite.Util.LegacyStrings = LegacyStrings

local function nx() return _G.Nx end

-- Split `str` by `delim`. Returns up to ~10 values (Lua vararg cap)
-- to mirror the existing strsplit-based implementation.
function LegacyStrings.Split(delim, str)
    if nx() and nx().Split then return nx().Split(delim, str) end
    if not str then return nil end
    return strsplit(delim, str)
end

-- "r|g|b|a" string -> r, g, b, a as floats in [0, 1]. The legacy
-- implementations live in NxUI under Util_str2rgba/_str2rgb/_str2a.
function LegacyStrings.ColorRGBA(s)
    if nx() and nx().Util_str2rgba then return nx().Util_str2rgba(s) end
    if type(s) ~= "string" then return 1, 1, 1, 1 end
    local r, g, b, a = s:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
    return tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1, tonumber(a) or 1
end

function LegacyStrings.ColorRGB(s)
    if nx() and nx().Util_str2rgb then return nx().Util_str2rgb(s) end
    local r, g, b = LegacyStrings.ColorRGBA(s)
    return r, g, b
end

function LegacyStrings.ColorAlpha(s)
    if nx() and nx().Util_str2a then return nx().Util_str2a(s) end
    local _, _, _, a = LegacyStrings.ColorRGBA(s)
    return a
end

-- "r|g|b|a" -> "|cAARRGGBB" Blizzard escape.
function LegacyStrings.ColorString(s)
    if nx() and nx().Util_str2colstr then return nx().Util_str2colstr(s) end
    local r, g, b, a = LegacyStrings.ColorRGBA(s)
    return ("|c%02x%02x%02x%02x"):format(
        math.floor((a or 1) * 255),
        math.floor((r or 0) * 255),
        math.floor((g or 0) * 255),
        math.floor((b or 0) * 255))
end

-- RAID_CLASS_COLORS table -> table of "|cffrrggbb" entries keyed by class.
function LegacyStrings.ClassColorStrings(rgba)
    if nx() and nx().Util_coltrgb2colstr then return nx().Util_coltrgb2colstr(rgba) end
    if type(rgba) ~= "table" then return {} end
    local out = {}
    for k, c in pairs(rgba) do
        if type(c) == "table" and c.r and c.g and c.b then
            out[k] = ("|cff%02x%02x%02x"):format(
                math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
        end
    end
    return out
end

-- Integer -> uppercase hex string.
function LegacyStrings.DecToHex(n)
    if nx() and nx().Util_dec2hex then return nx().Util_dec2hex(n) end
    return ("%X"):format(n or 0)
end

-- "Title Case" first character of each word.
function LegacyStrings.Capitalize(s)
    if nx() and nx().Util_CapStr then return nx().Util_CapStr(s) end
    if not s or s == "" then return s end
    return (s:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

-- Strip realm name from "Name-Realm".
function LegacyStrings.CleanName(name)
    if nx() and nx().Util_CleanName then return nx().Util_CleanName(name) end
    if not name then return "" end
    return (name:gsub("%-.+$", ""))
end

-- Standard money-string formatter (gold/silver/copper) mirroring
-- Blizzard's GetMoneyString look. Honors Carbonite's option to
-- preserve whatever format the legacy helper produces.
function LegacyStrings.MoneyString(copper)
    if nx() and nx().Util_GetMoneyStr then return nx().Util_GetMoneyStr(copper) end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return ("%dg %ds %dc"):format(g, s, c)
end

function LegacyStrings.ElapsedString(seconds)
    if nx() and nx().Util_GetTimeElapsedStr then return nx().Util_GetTimeElapsedStr(seconds) end
    seconds = math.max(0, math.floor(seconds or 0))
    local d = math.floor(seconds / 86400)
    local h = math.floor((seconds % 86400) / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if d > 0 then return ("%dd %dh"):format(d, h) end
    if h > 0 then return ("%dh %dm"):format(h, m) end
    if m > 0 then return ("%dm %ds"):format(m, s) end
    return ("%ds"):format(s)
end

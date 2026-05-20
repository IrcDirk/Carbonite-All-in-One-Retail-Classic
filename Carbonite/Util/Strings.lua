-- Carbonite | Util / Strings
-- String helpers extracted from the old NxUI.lua and Carbonite.lua.
-- Kept pure: no UI side effects, no globals touched.

local Carbonite = _G.Carbonite
local Strings = {}
Carbonite.Util.Strings = Strings

-- Plain (non-pattern) substring search. Returns position or false to
-- mirror the legacy Nx.strpos signature.
function Strings.IndexOf(haystack, needle, offset)
    if not haystack or not needle then return false end
    local pos = string.find(haystack, needle, offset or 1, true)
    return pos or false
end

function Strings.StartsWith(s, prefix)
    if not s or not prefix then return false end
    return s:sub(1, #prefix) == prefix
end

function Strings.EndsWith(s, suffix)
    if not s or not suffix then return false end
    if #suffix == 0 then return true end
    return s:sub(-#suffix) == suffix
end

function Strings.Trim(s)
    if not s then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Splits on a plain separator and returns an array of pieces.
function Strings.Split(s, sep, limit)
    local out, i, n = {}, 1, 0
    sep = sep or ","
    while true do
        n = n + 1
        if limit and n >= limit then
            out[n] = s:sub(i)
            break
        end
        local a, b = s:find(sep, i, true)
        if not a then
            out[n] = s:sub(i)
            break
        end
        out[n] = s:sub(i, a - 1)
        i = b + 1
    end
    return out
end

-- Strips color escapes (|cAARRGGBB...|r) and item link wrappers
-- so two display strings can be compared.
function Strings.StripFormatting(s)
    if not s then return "" end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
    s = s:gsub("|r", "")
    s = s:gsub("|H.-|h", "")
    s = s:gsub("|h", "")
    s = s:gsub("|T.-|t", "")
    return s
end

-- Format a number with thousands separators. Locale-agnostic; uses
-- comma. Matches the look of legacy Carbonite UI text.
function Strings.FormatNumber(n)
    if not n then return "" end
    local sign = n < 0 and "-" or ""
    local s = tostring(math.abs(math.floor(n)))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. out
end

-- Color text with a |cAARRGGBB...|r wrapper. Accepts a hex string
-- like "ff8080" or a table { r=, g=, b= } / { r, g, b }.
function Strings.Colorize(text, color)
    if type(color) == "table" then
        local r = color.r or color[1] or 1
        local g = color.g or color[2] or 1
        local b = color.b or color[3] or 1
        color = string.format("%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    end
    return ("|cff%s%s|r"):format(color, text or "")
end

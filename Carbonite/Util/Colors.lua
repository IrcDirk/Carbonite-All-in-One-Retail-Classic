-- Carbonite | Util / Colors
-- Color manipulation used by skinning, pin coloring, and class-tinted
-- text. Stores everything as floats in [0,1] and converts to hex on
-- demand to match WoW's |cAARRGGBB color escape format.

local Carbonite = _G.Carbonite
local Colors = {}
Carbonite.Util.Colors = Colors

local function clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

function Colors.RGB(r, g, b, a)
    return { r = clamp01(r or 0), g = clamp01(g or 0), b = clamp01(b or 0), a = clamp01(a or 1) }
end

function Colors.FromHex(hex)
    if not hex then return Colors.RGB(1, 1, 1) end
    hex = hex:gsub("^#", ""):gsub("^|c", "")
    local a, r, g, b
    if #hex >= 8 then
        a = tonumber(hex:sub(1, 2), 16)
        r = tonumber(hex:sub(3, 4), 16)
        g = tonumber(hex:sub(5, 6), 16)
        b = tonumber(hex:sub(7, 8), 16)
    else
        a = 255
        r = tonumber(hex:sub(1, 2), 16)
        g = tonumber(hex:sub(3, 4), 16)
        b = tonumber(hex:sub(5, 6), 16)
    end
    return Colors.RGB((r or 0) / 255, (g or 0) / 255, (b or 0) / 255, (a or 255) / 255)
end

function Colors.ToHex(c)
    return string.format("%02x%02x%02x%02x",
        math.floor((c.a or 1) * 255 + 0.5),
        math.floor(c.r * 255 + 0.5),
        math.floor(c.g * 255 + 0.5),
        math.floor(c.b * 255 + 0.5))
end

function Colors.Lerp(a, b, t)
    return Colors.RGB(
        a.r + (b.r - a.r) * t,
        a.g + (b.g - a.g) * t,
        a.b + (b.b - a.b) * t,
        (a.a or 1) + ((b.a or 1) - (a.a or 1)) * t)
end

-- Lookup table for the standard 8 item-quality colors. Built lazily
-- the first time someone asks for one because GetItemQualityColor is
-- not safe to call before PLAYER_LOGIN on some clients.
local qualityCache
function Colors.Quality(quality)
    if not qualityCache then
        qualityCache = {}
        local getColor = (C_Item and C_Item.GetItemQualityColor) or GetItemQualityColor
        if getColor then
            for n = 0, 8 do
                local r, g, b, hex = getColor(n)
                if r then qualityCache[n] = { r = r, g = g, b = b, hex = hex } end
            end
        end
    end
    return qualityCache[quality]
end

-- Carbonite | Util / WaypointFormat
-- Parse + render "x.y, x.y" style waypoint coordinate strings.
-- Used by the /way slash command, the TomTom emulation's
-- HandleWayCommand, and the saved-Notes display.
--
-- Public API:
--   WaypointFormat.Parse(s)         -> mapID, x, y, name  (numbers,
--                                       all optional except x + y)
--   WaypointFormat.Render(x, y, decimals)
--                                   -> "12.3, 45.6" style string
--   WaypointFormat.RenderFull(mapID, x, y, name)

local Carbonite = _G.Carbonite
local WaypointFormat = {}
Carbonite.Util.WaypointFormat = WaypointFormat

-- Render coordinates with `decimals` (default 1) digits of precision.
-- Coordinates passed in are expected to be in zone-percent space
-- (0..100), matching Blizzard's /way convention.
function WaypointFormat.Render(x, y, decimals)
    if not x or not y then return "" end
    local fmt = "%." .. (decimals or 1) .. "f, %." .. (decimals or 1) .. "f"
    return fmt:format(x, y)
end

function WaypointFormat.RenderFull(mapID, x, y, name)
    local coords = WaypointFormat.Render(x, y)
    if mapID and not name then return ("%d %s"):format(mapID, coords) end
    if name then return ("%s %s"):format(name, coords) end
    return coords
end

-- Parse a string like:
--   "55.4, 67.2"
--   "Stormwind 55.4, 67.2"
--   "1453 55.4 67.2 My Note"
-- Returns mapID (or nil), x, y, name. mapID is detected by being the
-- first numeric token whose value is > 1000 (Blizzard map IDs).
function WaypointFormat.Parse(s)
    if type(s) ~= "string" then return nil end
    s = s:gsub(",", " ")

    local mapID, x, y
    local namePieces = {}

    for token in s:gmatch("%S+") do
        local n = tonumber(token)
        if n then
            if not x and n > 1000 and not mapID then
                mapID = n
            elseif not x then
                x = n
            elseif not y then
                y = n
            else
                namePieces[#namePieces + 1] = token
            end
        else
            namePieces[#namePieces + 1] = token
        end
    end

    local name = #namePieces > 0 and table.concat(namePieces, " ") or nil
    return mapID, x, y, name
end

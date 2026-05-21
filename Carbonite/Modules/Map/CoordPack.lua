-- Carbonite | Modules / Map / CoordPack
-- Tiny coordinate-packing utility moved out of Carbonite.lua.
-- Packs a (x, y) pair in 0..100 range into a 6-character hex
-- string "XXXYYY" used by the event log + capture system, and
-- unpacks it back. Resolution is ~1/40th of a percent.
--
-- Methods remain on Nx (Nx:PackXY / Nx:UnpackXY) because every
-- legacy callsite uses that namespace and the Data/Shared
-- guide files reach into Nx:PackXY at runtime.

---
-- Pack x,y coordinates into a hex string
-- @param x  X coordinate (0-100)
-- @param y  Y coordinate (0-100)
-- @return   6-character hex string "XXXYYY"
--
function Nx:PackXY (x, y)

    x = max (0, min (100, x))
    y = max (0, min (100, y))
    return format ("%03x%03x", x * 40.9 + .5, y * 40.9 + .5)        -- Round off
end

---
-- Unpack a hex string to x,y coordinates
-- @param xy  6-character hex string
-- @return    x, y coordinates (0-100 range)
--
function Nx:UnpackXY (xy)
    local x = tonumber (strsub (xy, 1, 3), 16) / 40.9
    local y = tonumber (strsub (xy, 4, 6), 16) / 40.9
    return x, y
end

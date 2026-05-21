-- Carbonite | Modules / Map / Pins / PathPin
-- A line segment drawn by the renderer's LINE drawMode. Used for
-- patrol routes (HandyNotes_BurningCrusade route data) and any
-- other "two points connected by a line" overlay.
--
-- Per-pin fields the Renderer's renderLINE reads:
--   pin.x  / pin.y    world-space coords of one endpoint
--   pin.x2 / pin.y2   world-space coords of the other endpoint
--   pin.mapID         the source mapID (informational; renderer
--                     uses pre-computed world coords directly)
--   pin.color         hex string or {r,g,b,a}, default light blue
--   pin.thickness     in pixels, default 2

local Carbonite = _G.Carbonite
local Pin = Carbonite.Modules.Map.Pin

Pin.Define("!HandyNotesPath", {
    drawMode  = "LINE",
    color     = "FF60C0FF",
    thickness = 2,
})

Pin.Define("!QuestiePath", {
    drawMode  = "LINE",
    color     = "FFFF8060",
    thickness = 2,
})

-- Carbonite | Modules / Map / IconTypes
-- Adapter that lets legacy callers (NxMapGuide, NxFav, UserEvents,
-- etc.) keep their Nx.Map:InitIconType / AddIconPt / SetIconType*
-- vocabulary while every icon flows through the new Pin/Layer/
-- Renderer pipeline.
--
-- Mapping:
--   InitIconType(name, drawMode, tex, w, h)  -> Pin.Define(name,...)
--                                              + Layer.Get(name):Clear()
--   AddIconPt(name, x, y, lvl, color, ...)   -> Map:AddPin(name, name, opts)
--   SetIconTypeXxx                           -> Pin.SetClassField(name, ...)
--   AddIconRect / SetIconTip / etc.          -> Pin instance mutation
--
-- Each legacy "iconType" name becomes both a Pin class name and a
-- Layer name. Pins land in the layer named after their type. The
-- Renderer walks Layer.All() each frame and stamps pool frames.

local Carbonite = _G.Carbonite
local Pin = Carbonite.Modules.Map.Pin
local Layer = Carbonite.Modules.Map.Layer

local IconTypes = {}
Carbonite.Modules.Map.IconTypes = IconTypes

function IconTypes:Define(name, opts)
    opts = opts or {}
    Pin.Define(name, {
        drawMode = opts.drawMode or "ZP",
        w        = opts.width  or opts.w,
        h        = opts.height or opts.h,
        tex      = opts.texture,
        scale    = 1,
        enabled  = true,
    })
    -- Wipe any pins already pooled under this name so re-init starts
    -- from an empty array, matching the legacy `wipe(d[name] or {})`.
    Layer.Get(name):Clear()
    return Pin.GetClass(name)
end

function IconTypes:Clear(name)
    Layer.Remove(name)
    Pin.classes[name] = nil
end

local function assertClass(name)
    local c = Pin.GetClass(name)
    assert(c, ("IconTypes: type %q not defined"):format(tostring(name)))
    return c
end

function IconTypes:SetAlpha(name, alpha, alphaNear)
    assertClass(name)
    Pin.SetClassField(name, "alpha",     alpha)
    Pin.SetClassField(name, "alphaNear", alphaNear)
end

function IconTypes:SetMinScale(name, scale)
    assertClass(name)
    Pin.SetClassField(name, "atScale", scale)
end

function IconTypes:SetLevel(name, level)
    assertClass(name)
    Pin.SetClassField(name, "frameLvl", level)
end

function IconTypes:SetChop(name, on)
    assertClass(name)
    Pin.SetClassField(name, "clipKind", on and "chop" or "w")
end

function IconTypes:SetNoDockMinimap(name, on)
    assertClass(name)
    Pin.SetClassField(name, "noDockMinimap", on)
end

-- Pin instances for the legacy adapter. Same shape as the old icon
-- tables: X/Y, Level, Color, Tex, TX1..TY2, Tip, UData, FavData. Kept
-- with capitalised aliases so legacy code that reaches into icon.X /
-- icon.Tip after AddIconPt keeps working.
Pin.Define("__LegacyPin", {})

local function defineLegacyPin(name)
    -- Lazily clone the legacy mixin under the iconType's own name so
    -- the Renderer can find class metadata via Pin.GetClass(name).
    if not Pin.GetClass(name) then
        Pin.Define(name, { drawMode = "WP" })
    end
end

local function acquireLegacyPin(name, x, y, level, color, texture, tx1, ty1, tx2, ty2)
    defineLegacyPin(name)
    local pin = Pin.Acquire(name)
    pin.x, pin.y       = x, y
    pin.X, pin.Y       = x, y   -- legacy aliases
    pin.level          = level
    pin.Level          = level
    pin.color          = color
    pin.Color          = color
    pin.tex            = texture
    pin.Tex            = texture
    pin.iconType       = name
    -- Legacy AddIconPt only kept texcoords when all four were given.
    -- NxMapGuide:1565 passes a stray `level` into the tx1 slot, so a
    -- truthy tx1 alone isn't sufficient to mean "caller wants
    -- texcoords applied". Always overwrite (including with nil) so
    -- a recycled pin doesn't inherit the previous user's coords.
    if tx1 and ty1 and tx2 and ty2 then
        pin.tx1, pin.ty1, pin.tx2, pin.ty2 = tx1, ty1, tx2, ty2
        pin.TX1, pin.TY1, pin.TX2, pin.TY2 = tx1, ty1, tx2, ty2
    else
        pin.tx1, pin.ty1, pin.tx2, pin.ty2 = nil, nil, nil, nil
        pin.TX1, pin.TY1, pin.TX2, pin.TY2 = nil, nil, nil, nil
    end
    pin.show = true
    return pin
end

function IconTypes:AddPoint(name, x, y, level, color, texture, tx1, ty1, tx2, ty2)
    local cls = assertClass(name)
    assert(cls.tex or texture or color,
        "IconTypes:AddPoint requires either a texture or a color")
    local pin = acquireLegacyPin(name, x, y, level, color, texture, tx1, ty1, tx2, ty2)
    Layer.Get(name):Add(pin)
    return pin
end

function IconTypes:AddRect(name, mapId, x, y, x2, y2, color)
    assertClass(name)
    local pin = Pin.Acquire(name)
    pin.mapID, pin.MapId = mapId, mapId
    pin.x,  pin.y,  pin.x2,  pin.y2  = x, y, x2, y2
    pin.X,  pin.Y,  pin.X2,  pin.Y2  = x, y, x2, y2
    pin.color, pin.Color = color, color
    pin.iconType = name
    pin.show = true
    Layer.Get(name):Add(pin)
    return pin
end

function IconTypes:Count(name)
    local l = Layer.All()[name]
    return l and l:Count() or 0
end

function IconTypes:GetPoint(name, index)
    local l = Layer.All()[name]
    if not l then return nil end
    local pin = l.pins[index]
    if not pin then return nil end
    local NxMap = _G.Nx and _G.Nx.Map
    if pin.level == (NxMap and NxMap.DungeonLevel) then
        return pin.x, pin.y
    end
end

function IconTypes:SetIconTip(pin, tip)
    if pin then pin.tip, pin.Tip = tip, tip end
end

function IconTypes:SetIconUserData(pin, data)
    if pin then pin.udata, pin.UData = data, data end
end

function IconTypes:SetIconFavData(pin, d1, d2)
    if pin then
        pin.favData1, pin.FavData1 = d1, d1
        pin.favData2, pin.FavData2 = d2, d2
    end
end

function IconTypes:GetIconFavData(pin)
    if not pin then return nil end
    return pin.favData1 or pin.FavData1, pin.favData2 or pin.FavData2
end

-- Legacy rewire. Installs Nx.Map: vocabulary so the thousand existing
-- callsites keep working unchanged. Subscribes both to CARBONITE_LOADED
-- (post init) and CARBONITE_ENABLE (every /reload) because MapEngine's
-- own definitions are reinstalled during NXOnLoad and must be
-- overridden afterwards.
local function rewireLegacy()
    local NxMap = _G.Nx and _G.Nx.Map
    if not NxMap then return end

    NxMap.InitIconType            = function(_, name, drawMode, texture, w, h)
        return IconTypes:Define(name, { drawMode = drawMode, texture = texture, width = w, height = h })
    end
    NxMap.ClearIconType           = function(_, name) IconTypes:Clear(name) end
    NxMap.SetIconTypeAlpha        = function(_, name, a, an) IconTypes:SetAlpha(name, a, an) end
    NxMap.SetIconTypeAtScale      = function(_, name, s)     IconTypes:SetMinScale(name, s) end
    NxMap.SetIconTypeLevel        = function(_, name, l)     IconTypes:SetLevel(name, l) end
    NxMap.SetIconTypeChop         = function(_, name, on)    IconTypes:SetChop(name, on) end
    NxMap.SetIconTypeNoDockMinimap= function(_, name, on)    IconTypes:SetNoDockMinimap(name, on) end
    NxMap.AddIconPt               = function(_, name, x, y, lvl, col, tex, tx1, ty1, tx2, ty2)
        return IconTypes:AddPoint(name, x, y, lvl, col, tex, tx1, ty1, tx2, ty2)
    end
    NxMap.AddIconRect             = function(_, name, mapId, x, y, x2, y2, col)
        return IconTypes:AddRect(name, mapId, x, y, x2, y2, col)
    end
    NxMap.GetIconCnt              = function(_, name)        return IconTypes:Count(name) end
    NxMap.GetIconPt               = function(_, name, index) return IconTypes:GetPoint(name, index) end
    NxMap.SetIconTip              = function(_, icon, tip)   IconTypes:SetIconTip(icon, tip) end
    NxMap.SetIconUserData         = function(_, icon, data)  IconTypes:SetIconUserData(icon, data) end
    NxMap.SetIconFavData          = function(_, icon, d1, d2) IconTypes:SetIconFavData(icon, d1, d2) end
    NxMap.GetIconFavData          = function(_, icon)        return IconTypes:GetIconFavData(icon) end
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)

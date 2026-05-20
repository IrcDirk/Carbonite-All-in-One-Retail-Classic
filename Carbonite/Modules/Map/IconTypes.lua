-- Carbonite | Modules / Map / IconTypes
-- The icon-type registry that the legacy NxMap.lua used to manage
-- through Nx.Map:InitIconType / SetIconType*. Each icon type defines
-- the shared draw mode, texture, dimensions, alpha curve, frame
-- level, and clipping behaviour for a class of icons (gather nodes,
-- quest givers, etc.). Individual icons added via AddIconPt /
-- AddIconRect inherit defaults from their type.
--
-- This class owns the *type definitions and the point lists*. The
-- map renderer still reads Nx.Map.Data[<typeName>] each frame; that
-- storage layout is preserved verbatim so we do not have to rewrite
-- the renderer at the same time.
--
-- Public API:
--   IconTypes:Define(name, opts)        register / replace a type
--   IconTypes:Clear(name)               drop a type and its icons
--   IconTypes:SetAlpha(name, a, near)
--   IconTypes:SetMinScale(name, scale)
--   IconTypes:SetLevel(name, frameLvl)
--   IconTypes:SetChop(name, on)
--   IconTypes:SetNoDockMinimap(name, on)
--   IconTypes:AddPoint(name, x, y, level, color, texture, tx1, ty1, tx2, ty2)
--   IconTypes:AddRect(name, mapId, x1, y1, x2, y2, color)
--   IconTypes:Count(name)
--   IconTypes:GetPoint(name, index)     world (x, y) when relevant level
--   IconTypes:SetIconTip(icon, tip)
--   IconTypes:SetIconUserData(icon, data)

local Carbonite = _G.Carbonite

local IconTypes = {}
Carbonite.Modules.Map.IconTypes = IconTypes

local function dataTable()
    local NxMap = _G.Nx and _G.Nx.Map
    return NxMap and NxMap.Data
end

local function typeEntry(name)
    local d = dataTable()
    return d and d[name] or nil
end

function IconTypes:Define(name, opts)
    opts = opts or {}
    local d = dataTable()
    if not d then return nil end
    local existing = d[name]
    if existing then wipe(existing) end
    local t = existing or {}
    d[name] = t

    t.Num      = 0
    t.Enabled  = true
    t.DrawMode = opts.drawMode or "ZP"
    t.Tex      = opts.texture
    t.W        = opts.width  or opts.w
    t.H        = opts.height or opts.h
    t.Scale    = 1
    return t
end

function IconTypes:Clear(name)
    local d = dataTable()
    if d then d[name] = nil end
end

local function requireType(name)
    local t = typeEntry(name)
    assert(t, ("IconTypes: type %q not defined"):format(tostring(name)))
    return t
end

function IconTypes:SetAlpha(name, alpha, alphaNear)
    local t = requireType(name)
    t.Alpha     = alpha
    t.AlphaNear = alphaNear
end

function IconTypes:SetMinScale(name, scale)
    local t = requireType(name)
    t.AtScale = scale
end

function IconTypes:SetLevel(name, level)
    local t = requireType(name)
    t.Lvl = level
end

function IconTypes:SetChop(name, on)
    local t = requireType(name)
    local NxMap = _G.Nx and _G.Nx.Map
    t.ClipFunc = on and NxMap and NxMap.ClipFrameWChop or NxMap and NxMap.ClipFrameW
end

function IconTypes:SetNoDockMinimap(name, on)
    local t = requireType(name)
    t.NoDockMinimap = on
end

function IconTypes:AddPoint(name, x, y, level, color, texture, tx1, ty1, tx2, ty2)
    local t = requireType(name)
    t.Num = t.Num + 1

    local icon = {
        X = x, Y = y,
        iconType = name,
        Level = level,
        Color = color,
        Tex   = texture,
    }
    if tx1 and ty1 and tx2 and ty2 then
        icon.TX1, icon.TY1, icon.TX2, icon.TY2 = tx1, ty1, tx2, ty2
    end
    t[t.Num] = icon
    assert(t.Tex or texture or color, "IconTypes:AddPoint requires either a texture or a color")
    return icon
end

function IconTypes:AddRect(name, mapId, x, y, x2, y2, color)
    local t = requireType(name)
    t.Num = t.Num + 1
    local icon = {
        MapId = mapId,
        X = x,  Y = y,
        X2 = x2, Y2 = y2,
        Color = color,
    }
    t[t.Num] = icon
    return icon
end

function IconTypes:Count(name)
    local t = typeEntry(name)
    if not t then return 0 end
    return #t
end

function IconTypes:GetPoint(name, index)
    local t = typeEntry(name)
    if not t then return nil end
    local icon = t[index]
    if not icon then return nil end
    local NxMap = _G.Nx and _G.Nx.Map
    if icon.Level == (NxMap and NxMap.DungeonLevel) then
        return icon.X, icon.Y
    end
end

function IconTypes:SetIconTip(icon, tip)
    if icon then icon.Tip = tip end
end

function IconTypes:SetIconUserData(icon, data)
    if icon then icon.UData = data end
end

-- Legacy rewire.
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
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_LOADED", rewireLegacy)
Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", rewireLegacy)

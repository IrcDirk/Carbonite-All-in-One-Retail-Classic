-- Carbonite | Util / Mouse
-- Frame mouse-position helpers used by the map drag/zoom code and
-- by tooltip placement. Originally lived as
-- Nx.Util_IsMouseOver / Nx.Util_GetMouseClampedXY / Nx.Util_SnapToScreen
-- in NxUI.lua. This file proxies to those legacy globals if they
-- still exist, and provides a portable fallback otherwise.
--
-- Public API:
--   Mouse:IsOver(frame)               -> x, y offsets from bottom-left
--                                        (relative to frame) or nil
--   Mouse:GetClampedXY(frame)         -> x, y clamped to the frame
--   Mouse:SnapToScreen(frame, ...)    -> snaps a frame to screen edges

local Carbonite = _G.Carbonite

local Mouse = {}
Carbonite.Util.Mouse = Mouse

local function nx() return _G.Nx end

local function frameBounds(frame)
    if not frame then return nil end
    local l = frame:GetLeft()
    local r = frame:GetRight()
    local t = frame:GetTop()
    local b = frame:GetBottom()
    if not l or not r or not t or not b then return nil end
    return l, r, t, b
end

local function cursorScaled(frame)
    if not _G.GetCursorPosition then return 0, 0 end
    local x, y = _G.GetCursorPosition()
    local s = (frame and frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1
    if s == 0 then s = 1 end
    return x / s, y / s
end

function Mouse:IsOver(frame)
    if nx() and nx().Util_IsMouseOver then return nx().Util_IsMouseOver(frame) end
    if not frame or (frame.IsShown and not frame:IsShown()) then return nil end
    local l, r, t, b = frameBounds(frame)
    if not l then return nil end
    local x, y = cursorScaled(frame)
    if x >= l and x <= r and y >= b and y <= t then return x - l, y - b end
end

function Mouse:GetClampedXY(frame)
    if nx() and nx().Util_GetMouseClampedXY then return nx().Util_GetMouseClampedXY(frame) end
    if not frame then return 0, 0 end
    local l, r, t, b = frameBounds(frame)
    if not l then return 0, 0 end
    local x, y = cursorScaled(frame)
    if x < l then x = l end
    if x > r then x = r end
    if y < b then y = b end
    if y > t then y = t end
    return x - l, y - b
end

function Mouse:SnapToScreen(frame, threshold)
    if nx() and nx().Util_SnapToScreen then return nx().Util_SnapToScreen(frame) end
    -- Portable fallback omitted; relies on the legacy implementation
    -- to honor action-bar snap behavior. New code should call into
    -- the legacy implementation directly when present.
end

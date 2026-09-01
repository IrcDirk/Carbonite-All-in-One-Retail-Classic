-------------------------------------------------------------------------------
-- Carbonite UI Code
-- Copyright 2007-2012 Carbon Based Creations, LLC
-------------------------------------------------------------------------------
-- Carbonite - Addon for World of Warcraft(tm)
-- Copyright 2007-2012 Carbon Based Creations, LLC
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Relocation note
-------------------------------------------------------------------------------
-- The 8457-line legacy UI engine: every Nx.prt* / Nx.Util_* helper
-- plus the Nx.Window / Nx.Button / Nx.List / Nx.Item / Nx.Title /
-- Nx.NXMiniMapBut classes, relocated from Carbonite/NxUI.lua.
-- Methods continue to attach to the same legacy tables that
-- Carbonite.lua initialises. A separate, newer UI primitive tree
-- lives in Carbonite/UI/* (Carbonite.UI.Window etc.); the two
-- namespaces don't collide, and the new Modules/Window/* shells
-- lazy-access Nx.Window via accessors so they keep working.

-------------------------------------------------------------------------------
-- LOCAL VARIABLES
-------------------------------------------------------------------------------

-- Windows that need initialization after login
local NotInitializedWins = {}
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-- Frames to hide when ESC is pressed
local HideFramesOnEsc = {}

-- Compatibility for GetMouseFocus API changes
local GetMouseFoci = GetMouseFoci or GetMouseFocus

-------------------------------------------------------------------------------
-- UI INITIALIZATION
-------------------------------------------------------------------------------

---
-- Initialize all UI components
-- Sets up quality colors and initializes all UI modules
--
function Nx:UIInit()
    -- Build quality color lookup table (Poor to Artifact)
    local qc = {}
    self.QualityColors = qc

    for n = 0, 8 do        -- Blizzard max is currently 7
        local r, g, b, hex = C_Item.GetItemQualityColor (n)
        qc[n] = hex
    end

    qc[1] = "|cffe7e7e7"    -- Dim the white (Common quality)

    -- Create a dedicated tooltip frame for Carbonite UI text/item tooltips.
    -- Using a separate frame (instead of GameTooltip) prevents Carbonite from
    -- tainting GameTooltip's width, which would break Blizzard's own tooltip
    -- and loot-money layout code.
    Nx.TooltipText = CreateFrame("GameTooltip", "NxTooltipText", UIParent, "GameTooltipTemplate")
    Nx.TooltipText:SetOwner(UIParent, "ANCHOR_NONE")

    -- Initialize UI subsystems in order
    Nx.Font:Init()
    Nx.Skin:Init()

    Nx.Menu:Init()
    Nx.Window:Init()

    Nx.Button:Init()
    Nx.List:Init()
    Nx.DropDown:Init()
    Nx.ToolBar:Init()
end

-------------------------------------------------------------------------------
-- STRING UTILITY FUNCTIONS
-------------------------------------------------------------------------------

---
-- Find position of needle in haystack string
-- @param haystack  String to search in
-- @param needle    String to search for
-- @param offset    Starting position (optional)
-- @return          Position index or false if not found
--
function Nx.strpos (haystack, needle, offset)
    local i = string.find (haystack, needle, (offset or 0), true)
    return (i ~= nil and i or false)
end

---
-- Print current call stack for debugging
-- @param str  Label for the stack trace
--
function Nx.prtStack (str)
    local s = debugstack (2, 3, 2)
    s = gsub (s, "Interface\\AddOns\\", "")
    Nx.prtD ("%s: %s", str, s)
end

-------------------------------------------------------------------------------
-- ARRAY UTILITY FUNCTIONS
-------------------------------------------------------------------------------

---
-- Concatenate multiple arrays into one
-- Tags each element with its source array index
-- @param ...  Variable number of arrays
-- @return     Combined array
--
function Nx.ArrayConcat(...)
    local t = {}
    for n = 1, select("#", ...) do
        local arg = select(n, ...)
        if type(arg) == "table" then
            for _, v in ipairs(arg) do
                v._type = n
                t[#t + 1] = v
            end
        else
            t[#t + 1] = arg
        end
    end
    return t
end

---
-- Concatenate arrays reusing an existing table (reduces garbage collection)
-- @param reuse  Table to reuse
-- @param ...    Variable number of arrays
-- @return       The reused table with combined data
--
function Nx.ArrayConcatReuse(reuse, ...)
    wipe(reuse)
    for n = 1, select("#", ...) do
        local arg = select(n, ...)
        if type(arg) == "table" then
            for _, v in ipairs(arg) do
                v._type = n
                reuse[#reuse + 1] = v
            end
        else
            reuse[#reuse + 1] = arg
        end
    end
    return reuse
end

-------------------------------------------------------------------------------
-- SOCIAL UTILITY FUNCTIONS
-------------------------------------------------------------------------------

---
-- Check if a player name is on the friend list
-- @param name  Player name to check
-- @return      true if player is a friend
--
function Nx.IsFriend(name)
    for i = 1, C_FriendList.GetNumFriends() do
        local finfo = C_FriendList.GetFriendInfoByIndex(i)
        if finfo.name == name then
            return true
        end
    end
end

-------------------------------------------------------------------------------
-- CHAT PRINTING FUNCTIONS
-- Debug and message output to chat frames
-------------------------------------------------------------------------------

---
-- Get list of available chat frame names
-- @return  Sorted array of chat frame names
--
function Nx:prtGetChatFrames()
    local t = {}

    for n = 1, 10 do
        local cfrm = _G["ChatFrame" .. n]
        if cfrm and cfrm["name"] then
            tinsert(t, cfrm["name"])
        end
    end

    sort(t)
    return t
end

---
-- Set the chat frame to use for Carbonite messages
-- Uses the frame specified in options, or defaults to DEFAULT_CHAT_FRAME
--
function Nx:prtSetChatFrame()
    Nx.prtChatFrm = DEFAULT_CHAT_FRAME
    for n = 1, 10 do
        local cfrm = _G["ChatFrame" .. n]
        if cfrm then
            if cfrm["name"] == Nx.db.profile.General.ChatMsgFrm then
                Nx.prtChatFrm = cfrm
            end
        end
    end
end

---
-- Print formatted message to chat with Carbonite prefix
-- Handles format string validation and type conversion
-- @param ...  Format string followed by arguments
--
function Nx.prt(...)
    local args = {...}
    local i = 1

    -- Replace missing/erroneous placeholders with safe values
    local function replace_placeholders(placeholder, item)
        i = i + 1
        if item ~= 's' and item ~= 'q' then
            if type(args[i]) == 'string' and string.match(args[i], '^[.0-9]+$') then
                return placeholder
            elseif type(args[i]) ~= 'number' then
                return '[not a number]'
            end
        end
        return placeholder
    end
    args[1] = string.gsub((args[1] or 'nil'), '(%%[0-9.]*([cdeEfgGioqsuxX]))', replace_placeholders)

    -- Convert boolean and nil to string for safe output
    for n = 1, #args do
        if n > 1 then
            if type(args[n]) == 'boolean' or type(args[n]) == 'nil' then
                args[n] = tostring(args[n])
            end
        end
    end

    local f = Nx.prtChatFrm or DEFAULT_CHAT_FRAME
    f:AddMessage("|cffff0000[" .. Nx.TXTBLUE .. L["Carbonite"] .. "|cffff0000] |cffffffff" .. format(unpack(args)), 1, 1, 1)
end

---
-- Print raw message without formatting
-- @param msg  Message string
--
function Nx.prtraw(msg)
    local f = Nx.prtChatFrm or DEFAULT_CHAT_FRAME
    f:AddMessage(Nx.TXTBLUE .. L["Carbonite"] .. " |cffffffff" .. msg, 1, 1, 1)
end

---
-- Print error message to UI error frame (center screen)
-- @param msg  Format string
-- @param ...  Format arguments
--
function Nx.prtError(msg, ...)
    UIErrorsFrame:AddMessage(format(msg, ...), 1, 1, 0)
end

---
-- Print debug message (only when debug mode is on)
-- @param ...  Format string and arguments
--
function Nx.prtD(...)
    if Nx.DebugOn then
        Nx.prt(...)
    end
end

---
-- Print debug message when CTRL key is held
-- @param msg  Format string
-- @param ...  Format arguments
--
function Nx.prtCtrl(msg, ...)
    if Nx.DebugOn and IsControlKeyDown() then
        Nx.prt(msg, ...)
    end
end

---
-- Print table contents for debugging
-- @param msg  Label message
-- @param s    Table to print
--
function Nx.prtTable(msg, s)
    Nx.prt(msg .. " Table: " .. type(s))

    if type(s) == "table" then
        for k, v in pairs(s) do
            if type(v) ~= "table" then
                Nx.prtVar(" " .. k, v)
            else
                Nx.prt(" " .. k .. " table")
            end
        end
    end
end

---
-- Print variable with type-appropriate formatting
-- @param msg  Label message
-- @param v    Variable to print
--
function Nx.prtVar(msg, v)
    local prt = Nx.prt

    if v == nil then
        prt(msg .. " nil")
    elseif type(v) == "boolean" then
        prt(msg .. " " .. tostring(v))
    elseif type(v) == "number" then
        prt(format("%s #%d (0x%x)", msg, v, v))
    elseif type(v) == "string" then
        local s = gsub(v, "%%", "%%%%")
        prt(msg .. " '" .. s .. "'")
    elseif type(v) == "table" then
        Nx.prtTable(msg, v)
    else
        prt(msg .. " ? " .. tostring(v))
    end
end

---
-- Print string as hex bytes
-- @param msg  Label message
-- @param str  String to print as hex
--
function Nx.prtStrHex(msg, str)
    local prt = Nx.prt
    prt(msg .. ":")

    for n = 1, #str, 4 do
        local s = ""
        for n2 = n, min(#str, n + 3) do
            s = s .. format(" %x", strbyte(str, n2))
        end
        prt(s)
    end
end

---
-- Print frame information for debugging
-- @param msg  Label message
-- @param frm  Frame to inspect
--
function Nx.prtFrame(msg, frm)
    local prt = Nx.prt
    local parent = frm:GetParent()

    prt(msg .. L[" Frame: %s Shown%d Vis%d P>%s"], frm:GetName() or "nil",
        frm:IsShown() or 0, frm:IsVisible() or 0, parent and parent:GetName() or "nil")
    prt(L[" EScale %f, Lvl %f"], frm:GetEffectiveScale(), frm:GetFrameLevel())
    prt(L[" LR %f, %f"], frm:GetLeft() or -999, frm:GetRight() or -999)
    prt(L[" BT %f, %f"], frm:GetBottom() or -999, frm:GetTop() or -999)

    local reg = { frm:GetRegions() }
    for n, o in ipairs(reg) do
        local str = ""
        if o:IsObjectType("Texture") then
            str = o:GetTexture()
        end
        prt("  %d %s: %s", n, o:GetObjectType(), str)
    end
end

---
-- Print frame children recursively for debugging
-- @param msg  Label message (nil for recursive calls)
-- @param frm  Frame to inspect
-- @param lvl  Recursion level (optional)
--
function Nx.prtFrameChildren(msg, frm, lvl)
    local prt = Nx.prt
    lvl = lvl or 1

    if msg then
        prt(format("FrameChildren (%s)", msg))
    end

    local pad = ""
    for n = 1, lvl do
        pad = pad .. " "
    end

    local ch = { frm:GetChildren() }

    for n = 1, #ch do
        local c = ch[n]

        if c:IsObjectType("Frame") then
            prt(L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"], pad, n, c:GetName() or "nil",
                c:GetID() or "nil", c:GetObjectType(),
                c:IsShown() or 0, frm:GetFrameLevel(),
                c:GetLeft() or -99999, c:GetTop() or -99999
            )
            Nx.prtFrameChildren(nil, c, lvl + 1)
        end
    end
end

-------------------------------------------------------------------------------
-- STRING MANIPULATION UTILITIES
-------------------------------------------------------------------------------

---
-- Capitalize first letter, lowercase the rest
-- @param str  Input string
-- @return     Capitalized string
--
function Nx.Util_CapStr(str)
    return strupper(strsub(str, 1, 1)) .. strlower(strsub(str, 2))
end

---
-- Clean a name by capitalizing and removing special characters
-- @param name  Input name
-- @return      Cleaned name
--
function Nx.Util_CleanName(name)
    name = Nx.Util_CapStr(name)
    name = gsub(name, "[~%^]", "")
    return name
end

-------------------------------------------------------------------------------
-- TABLE UTILITY FUNCTIONS
-------------------------------------------------------------------------------

---
-- Count entries in a table (works with non-sequential keys)
-- @param t  Table to count
-- @return   Number of entries
--
function Nx.Util_tcount(t)
    local n = 0
    if t then
        for k, v in pairs(t) do
            n = n + 1
        end
    end
    return n
end

---
-- Count entries recursively including nested tables
-- @param t  Table to count
-- @return   Total number of entries
--
function Nx.Util_tcountrecurse(t)
    local n = 0
    if t then
        for k, v in pairs(t) do
            n = n + 1
            if type(v) == "table" then
                n = n + Nx.Util_tcountrecurse(v)
            end
        end
    end
    return n
end

---
-- Deep copy a table recursively
-- @param t  Table to copy
-- @return   New table with copied data
--
function Nx.Util_TCopyRecurse(t)
    local tc = {}

    for k, v in pairs(t) do
        if type(v) == "table" then
            tc[k] = Nx.Util_TCopyRecurse(v)
        else
            tc[k] = v
        end
    end

    return tc
end

---
-- Find index of item in array
-- @param t     Array to search
-- @param item  Item to find
-- @return      Index or nil if not found
--
function Nx.Util_TFindItemI(t, item)
    for i, v in ipairs(t) do
        if v == item then
            return i
        end
    end
end

---
-- Move array element up or down by index
-- @param t    Array
-- @param i    Index to move
-- @param low  true to move toward index 1
-- @return     New index or nil if not moved
--
function Nx.Util_TMoveI(t, i, low)
    if low then
        if i > 1 then
            t[i - 1], t[i] = t[i], t[i - 1]
            return i - 1
        end
    else
        if i < #t then
            t[i + 1], t[i] = t[i], t[i + 1]
            return i + 1
        end
    end
end

---
-- Move array element up or down by value
-- @param t     Array
-- @param item  Item to move
-- @param low   true to move toward index 1
-- @return      New index or nil if not moved
--
function Nx.Util_TMoveItem(t, item, low)
    for i, v in ipairs(t) do
        if v == item then
            if low then
                if i > 1 then
                    t[i - 1], t[i] = t[i], t[i - 1]
                    return i - 1
                end
            else
                if i < #t then
                    t[i + 1], t[i] = t[i], t[i + 1]
                    return i + 1
                end
            end
            return
        end
    end
end

---
-- Serialize a table to a Lua-parseable string
-- @param t  Table to serialize
-- @return   String representation
--
function Nx.Util_t2strRecurse(t)
    local str = ""

    if t then
        str = "{"

        for k, v in pairs(t) do
            local kStr = k

            if type(k) == "string" then
                kStr = format("\"%s\"", k)
            end

            if type(v) == "table" then
                str = str .. format("[%s]=%s,", kStr, Nx.Util_t2strRecurse(v))
            elseif type(v) == "string" then
                str = str .. format("[%s]=\"%s\",", kStr, v)
            else
                str = str .. format("[%s]=%s,", kStr, v)
            end
        end

        str = str .. "}"
    end

    return str
end

-------------------------------------------------------------------------------
-- COLOR CONVERSION UTILITIES
-- Convert between color formats (string, RGBA, hex)
-------------------------------------------------------------------------------

---
-- Convert decimal number to hexadecimal string
-- @param input  Decimal number
-- @return       Hex string (minimum 2 characters)
--
function Nx.Util_dec2hex(input)
    local base, key, output, remainder = 16, "0123456789ABCDEF", "", 0
    while input > 0 do
        input, remainder = floor(input / base), mod(input, base) + 1
        output = strsub(key, remainder, remainder) .. output
    end
    return output .. strrep("0", 2 - strlen(output))
end

---
-- Parse "R|G|B|A" string to RGBA floats
-- @param colors  Color string in "R|G|B|A" format (0-1 range)
-- @return        r, g, b, a values
--
function Nx.Util_str2rgba(colors)
    local arr = { Nx.Split("|", colors) }
    return tonumber(arr[1]), tonumber(arr[2]), tonumber(arr[3]), tonumber(arr[4])
end

---
-- Parse "R|G|B" string to RGB floats
-- @param colors  Color string in "R|G|B" format
-- @return        r, g, b values
--
function Nx.Util_str2rgb(colors)
    local arr = { Nx.Split("|", colors) }
    return tonumber(arr[1]), tonumber(arr[2]), tonumber(arr[3])
end

---
-- Extract alpha value from "R|G|B|A" string
-- @param colors  Color string
-- @return        Alpha value
--
function Nx.Util_str2a(colors)
    local arr = { Nx.Split("|", colors) }
    return arr[4]
end

---
-- Convert "R|G|B|A" string to WoW color escape code
-- @param colors  Color string in "R|G|B|A" format
-- @return        "|cAARRGGBB" format string
--
function Nx.Util_str2colstr(colors)
    local arr = { Nx.Split("|", colors) }
    return format("|c%02x%02x%02x%02x", arr[4] * 255, arr[1] * 255, arr[2] * 255, arr[3] * 255)
end

---
-- Convert Blizzard color table to color escape codes
-- @param colors  Table of {r, g, b} color entries
-- @return        Table of "|cffRRGGBB" strings
--
function Nx.Util_coltrgb2colstr(colors)
    local t = {}

    for k, v in pairs(colors) do
        t[k] = format("|cff%02x%02x%02x", v.r * 255, v.g * 255, v.b * 255)
    end

    return t
end

-------------------------------------------------------------------------------
-- VALUE INTERPOLATION
-------------------------------------------------------------------------------

---
-- Step a value toward a target by a fixed amount
-- @param value   Current value
-- @param target  Target value
-- @param step    Step size per call
-- @return        New value (clamped to target)
--
function Nx.Util_StepValue(value, target, step)
    if value < target then
        value = value + step
        if value > target then
            value = target
        end
    elseif value > target then
        value = value - step
        if value < target then
            value = target
        end
    end

    return value
end

-------------------------------------------------------------------------------
-- FRAME MOUSE UTILITIES
-------------------------------------------------------------------------------

---
-- Check if mouse is over a frame
-- @param frm  Frame to check
-- @return     x, y offsets from bottom-left, or nil if not over
--
function Nx.Util_IsMouseOver(frm)
    -- Safety check: frame must exist and be shown
    if not frm or not frm:IsShown() then
        return nil
    end

    local left = frm:GetLeft()
    local right = frm:GetRight()
    local top = frm:GetTop()
    local bottom = frm:GetBottom()

    -- Safety check: frame bounds must be valid
    if not left or not right or not top or not bottom then
        return nil
    end

    local x, y = GetCursorPosition()
    local scale = frm:GetEffectiveScale()
    if scale == 0 then scale = 1 end  -- Avoid division by zero

    x = x / scale
    y = y / scale

    if x >= left and x <= right and y >= bottom and y <= top then
        return x - left, y - bottom
    end
end

---
-- Get mouse position clamped to frame bounds
-- @param frm  Frame to clamp to
-- @return     x, y offsets from bottom-left (clamped)
--
function Nx.Util_GetMouseClampedXY(frm)
    -- Safety check: frame must exist
    if not frm then
        return 0, 0
    end

    local left = frm:GetLeft()
    local right = frm:GetRight()
    local top = frm:GetTop()
    local bottom = frm:GetBottom()

    -- Safety check: frame bounds must be valid
    if not left or not right or not top or not bottom then
        return 0, 0
    end

    local x, y = GetCursorPosition()
    local scale = frm:GetEffectiveScale()
    if scale == 0 then scale = 1 end

    x = x / scale
    y = y / scale

    x = max(x, left)
    x = min(x, right)
    y = max(y, bottom)
    y = min(y, top)

    return x - left, y - bottom
end

---
-- Snap frame position to screen edges and action bars
-- @param frm  Frame to snap
--
function Nx.Util_SnapToScreen(frm)
    -- Safety check
    if not frm then
        return
    end

    local sw = GetScreenWidth()
    local sh = GetScreenHeight()

    local atPt, relTo, relPt, x, y = frm:GetPoint()
    if not x or not y then
        return
    end

    local sc = frm:GetScale()
    if not sc or sc == 0 then sc = 1 end

    local l = frm:GetLeft()
    local r = frm:GetRight()
    local t = frm:GetTop()
    local b = frm:GetBottom()

    -- Safety check: frame bounds must be valid
    if not l or not r or not t or not b then
        return
    end

    l = l * sc
    r = r * sc
    t = t * sc
    b = b * sc

    local dist = 4  -- Snap distance threshold

    -- Snap to left edge
    if abs(l - 0) < dist then
        x = x - l / sc
    end

    -- Snap to right edge
    if abs(r - sw) < dist then
        x = x - (r - sw) / sc
    end

    -- Snap to left action bar
    if MultiBarLeft and MultiBarLeft:IsVisible() then
        local ml = MultiBarLeft:GetLeft()
        if ml and abs(r - ml) < dist then
            x = x - (r - ml) / sc
        end
    end

    -- Snap to right action bar
    if MultiBarRight and MultiBarRight:IsVisible() then
        local ml = MultiBarRight:GetLeft()
        if ml and abs(r - ml) < dist then
            x = x - (r - ml) / sc
        end
    end

    -- Snap to bottom edge
    if abs(b - 0) < dist then
        y = y - b / sc
    end

    -- Snap to top edge
    if abs(t - sh) < dist then
        y = y - (t - sh) / sc
    end

    frm:SetPoint(atPt, x, y)
    return nil
end

---
-- Recursively set frame levels on child frames
-- @param frm  Parent frame
-- @param lvl  Frame level to start at
--
function Nx.Util_SetChildLevels(frm, lvl)
    if frm:GetNumChildren() > 0 then
        local ch = { frm:GetChildren() }

        for n, chf in pairs(ch) do
            chf:SetFrameLevel(lvl)

            if chf:GetNumChildren() > 0 then
                Nx.Util_SetChildLevels(chf, lvl + 1)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- MONEY AND TIME FORMATTING
-------------------------------------------------------------------------------

---
-- Format copper value as gold/silver/copper string
-- @param money  Amount in copper
-- @return       Formatted string like "1g 23s 45c"
--
function Nx.Util_GetMoneyStr(money)
    if not money then
        return "|cffff4040?"
    end

    if money == 0 then
        return "0"
    end

    local pre = money > 0 and "" or "-"
    money = abs(money)

    local str = ""

    -- Gold
    local g = floor(money / 10000)
    if g > 0 then
        str = format(L["|cffffff00%dg"], g)
    end

    -- Silver
    local s = mod(floor(money / 100), 100)
    if s > 0 then
        str = format(L["%s |cffbfbfbf%ds"], str, s)
    end

    -- Copper
    local c = mod(money, 100)
    if c > 0 then
        str = format(L["%s |cff7f7f00%dc"], str, c)
    end

    return pre .. strtrim(str)
end

---
-- Format seconds as human-readable elapsed time
-- @param seconds  Time in seconds
-- @return         Formatted string (days, hours, or mins)
--
function Nx.Util_GetTimeElapsedStr(seconds)
    local secs = seconds
    local mins = secs / 60 % 60
    local hours = secs / 3600

    if hours > 24 then
        return format(L["%.1f days"], hours / 24)
    elseif hours >= 1 then
        return format(L["%.1f hours"], hours)
    end

    return format(L["%d mins"], mins)
end

---
-- Format seconds as full days/hours/minutes/seconds string
-- @param seconds  Time in seconds
-- @return         Formatted string "X days, Y hours, Z minutes, W seconds"
--
function Nx.Util_SecondsToDays(seconds)
    local fdays = math.floor(seconds / 86400)
    local fhours = math.floor((bit.mod(seconds, 86400)) / 3600)
    local fminutes = math.floor(bit.mod((bit.mod(seconds, 86400)), 3600) / 60)
    local fseconds = math.floor(bit.mod(bit.mod((bit.mod(seconds, 86400)), 3600), 60))
    return fdays .. " days, " .. fhours .. " hours, " .. fminutes .. " minutes, " .. fseconds .. " seconds"
end

---
-- Format seconds as MM:SS timer string
-- @param seconds  Time in seconds
-- @return         Formatted string "M:SS"
--
function Nx.Util_GetTimeElapsedMinSecStr(seconds)
    return format("%d:%02d", seconds / 60 % 60, seconds % 60)
end

-------------------------------------------------------------------------------
-- NUMERIC UTILITIES
-------------------------------------------------------------------------------

---
-- Convert NaN or infinity to zero
-- @param somevar  Value to check
-- @return         Zero if NaN/infinity, otherwise the original value
--
function Nx.Util_NanToZero(somevar)
    if somevar == math.huge or somevar == -math.huge then
        return 0
    end
    return (somevar ~= somevar and 0 or somevar)
end

-------------------------------------------------------------------------------
-- TOOLTIP UTILITIES
-------------------------------------------------------------------------------

---
-- Parse and set tooltip text with special formatting
-- Handles items (!), quests (@), enchants (#), and multi-line text
-- @param str  Text to display (may include special prefixes)
--
function Nx:SetTooltipText(str)
    -- Handle item links (prefix: !)
    if strbyte(str) == 33 then
        local link, s = Nx.Split("^", str)

        if not s or #s < 1 or IsAltKeyDown() then
            str = strsub(link, 2)
            Nx.Item:ShowTooltip(str, true)
            return
        end

        str = s

    -- Handle quest links (prefix: @)
    elseif strbyte(str) == 64 then
        str = "quest:" .. strsub(str, 2)
        Nx.Item:ShowTooltip(str, true)
        return

    -- Handle enchant links (prefix: #)
    elseif strbyte(str) == 35 then
        str = strsub(str, 2)
        Nx.TooltipText:SetHyperlink(str)
        return
    end

    -- Handle multi-line text
    local s1, s2 = strfind(str, "\n")
    if s1 then
        local t = { Nx.Split("\n", str) }

        if Nx._dbgTip then
            _G.print("|cffff8800TT|r lines=" .. #t .. " first=" .. tostring(t[1]))
        end

        Nx.TooltipText:SetText(t[1], 1, 1, 1, 1, true)  -- First line with wrap
        tremove(t, 1)

        for _, line in ipairs(t) do
            -- Check for tab-separated double columns
            local s1, s2 = Nx.Split("\t", line)
            if Nx._dbgTip then
                _G.print("|cffff8800TT|r  line=" .. tostring(line)
                    .. " s1=" .. tostring(s1) .. " s2=" .. tostring(s2))
            end
            if s2 then
                Nx.TooltipText:AddDoubleLine(s1, s2, 1, 1, 1, 1, 1, 1)
            else
                Nx.TooltipText:AddLine(line, 1, 1, 1, true)  -- Wrap text
            end
        end
    else
        Nx.TooltipText:SetText(str, 1, 1, 1, 1, true)  -- Single line with wrap
    end

    -- Always call Show() to ensure tooltip is properly sized and displayed
    Nx.TooltipText:Show()
    if Nx._dbgTip then
        _G.print("|cffff8800TT|r shown, lines=" .. tostring(Nx.TooltipText:NumLines()))
    end
end

-------------------------------------------------------------------------------
-- SOUND UTILITIES
-------------------------------------------------------------------------------

---
-- Play a sound file if sound effects are enabled
-- @param file  Sound file path
--
function Nx:PlaySoundFile(file)
    if GetCVar("Sound_EnableSFX") ~= "0" then
        PlaySoundFile(file)
    end
end

-------------------------------------------------------------------------------
-- FONT SYSTEM
-- Manages font objects and shared media integration
-------------------------------------------------------------------------------

---
-- Initialize font system
-- Creates font objects for different UI elements
--
function Nx.Font:Init()

    self.Inited = true

    -- Some code uses the "Nx" named font directly

    self.Fonts = {
        ["Font.Small"] = { "NxFontS", "GameFontNormalSmall", "db" },
        ["Font.Medium"] = { "NxFontM", "GameFontNormal", "db" },
        ["Font.Map"] = { "NxFontMap", "GameFontNormalSmall", "db" },
        ["Font.MapLoc"] = { "NxFontMapLoc", "GameFontNormalSmall", "db" },
        ["Font.Menu"] = { "NxFontMenu", "GameFontNormalSmall", "db" },
    }

    self.Faces = {
        { "Arial", "Fonts\\ARIALN.TTF", },
        { "Friz", "Fonts\\FRIZQT__.TTF", },
        { "Morpheus", "Fonts\\MORPHEUS.TTF", },
        { "Skurri", "Fonts\\SKURRI.TTF", }
    }

    -- Predefine so we dont get dups
    self.AddonFonts = {
        ["Arial Narrow"] = true,
        ["Friz Quadrata TT"] = true,
        ["Morpheus"] = true,
        ["Skurri"] = true,
    }

    for name, v in pairs (self.Fonts) do

        local font = CreateFont (v[1])
        v.Font = font
        font:SetFontObject(v[2])
        v.Font.db = v[3]
    end

    self:Update()
end

function Nx.Font:ModuleAdd (key, value)
  self.Fonts[key] = value
  local font = CreateFont (value[1])
  value.Font = font
  font:SetFontObject(value[2])
  value.Font.db = value[3]
  self:Update()
end

function Nx.Font:AddonLoaded()

    if not self.Inited then
        return
    end

    local found

    found = self:FontScan ("LibSharedMedia-3.0")

    if found then
        self:Update()
    end
end

function Nx.Font:FontScan (libName)

    local sm

    sm = LibStub(libName)

    if sm then

        local found

        local fonts = sm.List(sm, "font")

--        Nx.prtVar ("SM", fonts)

        for k, name in ipairs (fonts) do

            if not self.AddonFonts[name] then
                found = true
--                Nx.prtVar ("Font", name)
--                Nx.prtVar ("Fetch", sm["Fetch"] (sm, "font", name))
                self.AddonFonts[name] = sm.Fetch(sm, "font", name)
                tinsert (self.Faces, { name, self.AddonFonts[name] })
            end
        end

        return found
    end
end

function Nx.Font:GetObj (name)
    return self.Fonts[name].Font
end

function Nx.Font:GetH (name)
--    Nx.prt ("Font %s", name or "nil")
    return self.Fonts[name].H
end

function Nx.Font:GetIndex (name)
    for k, v in ipairs (self.Faces) do
        if v[1] == name then
            return k
        end
    end
    return 1
end

function Nx.Font:GetName (index)
    local t = self.Faces[index]
    return t and t[1]
end

function Nx.Font:GetFile (name)

    for k, v in ipairs (self.Faces) do
        if v[1] == name then
            return v[2]
        end
    end

    return self.Faces[2][2]        -- Default to friz
end

function Nx.Font:Update()

    for name, v in pairs (self.Fonts) do

        local font = v.Font
        local dbloc = v.Font.db
        local fname, size, flags = font:GetFont()
        local optname = "Nx." .. dbloc .. ".profile." .. name
--        Nx.prt ("Font %s %s %s", fname, size, flags)
        local parts1, parts2 = Nx.Split(".",name)
        local file = self:GetFile (Nx[dbloc].profile[parts1][parts2])
        local size = Nx[dbloc].profile[parts1][parts2 .. "Size"]
        font:SetFont (file, size, flags)
        v.H = max (size + (Nx[dbloc].profile[parts1][parts2 .. "Spacing"] or 0), 6)
    end

    Nx.List:NextUpdateFull()
    Nx.Window:AdjustAll()
end

-------------------------------------------------------------------------------
-- SKIN SYSTEM
-- Manages visual themes for windows and UI elements
-------------------------------------------------------------------------------

---
-- Initialize skin system with predefined themes
--
function Nx.Skin:Init()

    Nx.Skins = {
        ["Blackout"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"] = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Addons\\Carbonite\\Gfx\\Skin\\EdgeSquare",
                ["tile"] = true,
                ["tileSize"] = 8,
                ["edgeSize"] = 8,
                ["insets"] = { ["left"] = 0, ["right"] = 0, ["top"] = 0, ["bottom"] = 0 }
            },
            ["BdCol"] = "0|0|0|1",
            ["BgCol"] = "0|0|0|1",
        },
        ["Blackout Blues"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"] = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",
                ["tile"] = true,
                ["tileSize"] = 9,
                ["edgeSize"] = 9,
                ["insets"] = { ["left"] = 1, ["right"] = 1, ["top"] = 1, ["bottom"] = 1 }
            },
            ["BdCol"] = ".8|.8|1|1",
            ["BgCol"] = "0|0|0|1",
        },
        ["Dialog Blue"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"] = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\DialogFrame\\UI-DialogBox-Border",
                ["tile"] = true,
                ["tileSize"] = 16,
                ["edgeSize"] = 16,
                ["insets"] = { ["left"] = 2, ["right"] = 2, ["top"] = 2, ["bottom"] = 2 }
            },
            ["BdCol"] = ".8|.8|1|1",
            ["BgCol"] = ".125|.125|.125|.88",
        },
        ["Dialog Gold"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"] = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                ["tile"] = true,
                ["tileSize"] = 16,
                ["edgeSize"] = 16,
                ["insets"] = { ["left"] = 2, ["right"] = 2, ["top"] = 2, ["bottom"] = 2 }
            },
            ["BdCol"] = "1|1|1|1",
            ["BgCol"] = ".15|.15|0|.88",            -- { .15, .15, 0, .88 },
        },
        ["Simple Blue"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"] = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Addons\\Carbonite\\Gfx\\Skin\\EdgeSquare",
--                ["edgeFile"] = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
                ["tile"] = true,
                ["tileSize"] = 8,
                ["edgeSize"] = 8,
                ["insets"] = { ["left"] = 0, ["right"] = 0, ["top"] = 0, ["bottom"] = 0 }
            },
            ["BdCol"] = "0.7|0.7|1|0.8",
            ["BgCol"] = ".125|.125|.125|.88",        -- { .125, .125, .125, .88 },
        },
        ["Stone"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"] = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Glues\\Common\\TextPanel-Border",
--                ["tile"] = true,
                ["tileSize"] = 256,
                ["edgeSize"] = 16,
                ["insets"] = { ["left"] = 3, ["right"] = 2, ["top"] = 2, ["bottom"] = 2 }
            },
            ["BdCol"] = "1|1|1|1",
            ["BgCol"] = "0.06|0.06|0.06|.9",
        },
        ["Tool Blue"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"] = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",
--                ["edgeFile"] = "Interface\\Minimap\\TooltipBackdrop",
                ["tile"] = true,
                ["tileSize"] = 9,
                ["edgeSize"] = 9,
                ["insets"] = { ["left"] = 1, ["right"] = 1, ["top"] = 1, ["bottom"] = 1 }
            },
            ["BdCol"] = ".8|1|1|.8",
            ["BgCol"] = ".125|.125|.125|.88",        -- { .125, .125, .125, .88 },
        },
        -- Modern themes. The chrome uses Blizzard's ChatBubble border (a
        -- thin, clean 1-pixel-feel edge) which holds up at high UI scales
        -- where the legacy 8x8 EdgeSquare looks fuzzy. BdColResolve is a
        -- function-valued override read by Skin:Update() so themes can
        -- pick up live game state (class, faction).
        ["Modern Dark"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"]   = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",
                ["tile"]     = true,
                ["tileSize"] = 9,
                ["edgeSize"] = 9,
                ["insets"]   = { ["left"] = 1, ["right"] = 1, ["top"] = 1, ["bottom"] = 1 }
            },
            ["BdCol"] = "0.30|0.36|0.46|0.95",
            ["BgCol"] = "0.06|0.07|0.10|0.92",
        },
        ["Modern Light"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"]   = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",
                ["tile"]     = true,
                ["tileSize"] = 9,
                ["edgeSize"] = 9,
                ["insets"]   = { ["left"] = 1, ["right"] = 1, ["top"] = 1, ["bottom"] = 1 }
            },
            ["BdCol"] = "0.50|0.55|0.65|0.95",
            ["BgCol"] = "0.88|0.88|0.92|0.92",
        },
        ["Glass"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"]   = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",
                ["tile"]     = true,
                ["tileSize"] = 9,
                ["edgeSize"] = 9,
                ["insets"]   = { ["left"] = 1, ["right"] = 1, ["top"] = 1, ["bottom"] = 1 }
            },
            ["BdCol"] = "1|1|1|0.40",
            ["BgCol"] = "0|0|0|0.40",
        },
        ["Class Color"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"]   = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",
                ["tile"]     = true,
                ["tileSize"] = 9,
                ["edgeSize"] = 9,
                ["insets"]   = { ["left"] = 1, ["right"] = 1, ["top"] = 1, ["bottom"] = 1 }
            },
            ["BdCol"] = "0.40|0.55|0.95|0.85",  -- fallback
            ["BgCol"] = "0.06|0.07|0.10|0.92",
            ["BdColResolve"] = function()
                local _, class = UnitClass("player")
                local cc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)
                local c = class and cc and cc[class]
                if c then
                    return string.format("%f|%f|%f|0.90", c.r, c.g, c.b)
                end
            end,
        },
        ["Faction"] = {
            ["Folder"] = "",
            ["WinBrH"] = "WinBrH",
            ["WinBrV"] = "WinBrV",
            ["TabOff"] = "TabOff",
            ["TabOn"] = "TabOn",
            ["Backdrop"] = {
                ["bgFile"]   = "Interface\\Buttons\\White8x8",
                ["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",
                ["tile"]     = true,
                ["tileSize"] = 9,
                ["edgeSize"] = 9,
                ["insets"]   = { ["left"] = 1, ["right"] = 1, ["top"] = 1, ["bottom"] = 1 }
            },
            ["BdCol"] = "0.40|0.55|0.95|0.85",  -- fallback (Alliance-ish)
            ["BgCol"] = "0.06|0.07|0.10|0.92",
            ["BdColResolve"] = function()
                local f = UnitFactionGroup("player")
                if f == "Alliance" then return "0.18|0.45|0.95|0.90" end
                if f == "Horde"    then return "0.85|0.20|0.20|0.90" end
            end,
        },
    }
    self:Set (Nx.db.profile.Skin["Name"], true)
end

function Nx.Skin:Set (skinName, init)

    self.Data = Nx.Skins[skinName or ""]

    if not self.Data then
        -- New default for fresh profiles. Existing users keep whatever
        -- they had set; only the empty/missing-name case picks this up.
        skinName = "Modern Dark"
        self.Data = Nx.Skins[skinName]
    end

    Nx.db.profile.Skin.Name = skinName

    local data = self.Data

    self.Path = "Interface\\Addons\\Carbonite\\Gfx\\Skin\\" .. data["Folder"]

    if not init then
        Nx.db.profile.Skin.WinBdColor = data["BdCol"]
        Nx.db.profile.Skin.WinFixedBgColor = ".5|.5|.5|.5"
        Nx.db.profile.Skin.WinSizedBgColor = data["BgCol"]
    end

    self:Update()
end

function Nx.Skin:Update()
    -- Themes can opt into a live-state border color (e.g. class color,
    -- faction color) by exposing a BdColResolve function. When present
    -- it overrides the saved WinBdColor each Update; the saved value
    -- still acts as the fallback when the resolver returns nil.
    local data = self.Data
    local resolved
    if data and type(data["BdColResolve"]) == "function" then
        local ok, val = pcall(data.BdColResolve)
        if ok then resolved = val end
    end
    local bdColStr = resolved or Nx.db.profile.Skin.WinBdColor

    self.BdCol = { Nx.Util_str2rgba (bdColStr) }
    self.BgCol = { Nx.Util_str2rgba (Nx.db.profile.Skin.WinSizedBgColor) }
    self.FixedBgCol = { Nx.Util_str2rgba (Nx.db.profile.Skin.WinFixedBgColor) }

    Nx.Window:ResetBackdrops()
    Nx.Menu:ResetSkins()
end

function Nx.Skin:GetBackdrop()
    return self.Data["Backdrop"]
end

-- Returns the Blizzard NineSlice layout name this theme wants applied,
-- or nil for legacy-backdrop themes. Used by Nx.Window:ResetBackdrops
-- to switch between SetBackdrop and NineSliceUtil.ApplyLayoutByName.
function Nx.Skin:GetNineSliceLayout()
    return self.Data and self.Data["NineSlice"]
end

function Nx.Skin:GetBorderCol()
    return self.BdCol
end

function Nx.Skin:GetBGCol()
    return self.BgCol
end

function Nx.Skin:GetFixedSizeBGCol()
    return self.FixedBgCol
end

function Nx.Skin:GetTex (txName)
    return self.Path .. txName
end

-------------------------------------------------------------------------------
-- WINDOW SYSTEM
-- Creates and manages movable, resizable windows with borders and titles
-------------------------------------------------------------------------------

---
-- Initialize window system
-- Sets up window layout data and creates window context menu
--
function Nx.Window:Init()

    local wd = Nx:GetData ("Win")

    if not wd.Version or wd.Version < Nx.VERSIONWin then

        if wd.Version then
            Nx.prt (L["Reset old layout data"])
        end
        wd.Version = Nx.VERSIONWin

        for k, win in pairs (wd) do
            if type (win) == "table" then
--                Nx.prt (" Reset %s", k)
                wd[k] = nil
            end
        end
    end

    self.Wins = {}        -- All created windows

    self.BORDERW = 7
    self.BORDERH = 7

    self.Borders = {
        "TOPLEFT", "TOPRIGHT", 1, self.BORDERH, "WinBrH",
        "BOTTOMLEFT", "BOTTOMRIGHT", 1, self.BORDERH, "WinBrH",
        "TOPLEFT", "BOTTOMLEFT", self.BORDERW, 1, "WinBrV",
        "TOPRIGHT", "BOTTOMRIGHT", self.BORDERW, 1, "WinBrV",
    }

    self.SideNames = {
        "LEFT", "RIGHT", "", "TOP", "TOPLEFT", "TOPRIGHT", "",
        "BOTTOM", "BOTTOMLEFT", "BOTTOMRIGHT"
    }

    self.StrataNames = {
        "LOW", "MEDIUM", "HIGH", "DIALOG",
        ["LOW"] = 1, ["MEDIUM"] = 2, ["HIGH"] = 3, ["DIALOG"] = 4,
    }

    local menu = Nx.Menu:Create (UIParent)
    self.Menu = menu

    self.MenuIHideInCombat = menu:AddItem (0, L["Hide In Combat"], self.Menu_OnHideInCombat, self)
    self.MenuILock = menu:AddItem (0, L["Lock"], self.Menu_OnLock, self)
    self.MenuIFadeIn = menu:AddItem (0, L["Fade In"], self.Menu_OnFadeIn, self)
    self.MenuIFadeOut = menu:AddItem (0, L["Fade Out"], self.Menu_OnFadeOut, self)
    self.MenuILayer = menu:AddItem (0, L["Layer"], self.Menu_OnLayer, self)
    self.MenuIScale = menu:AddItem (0, L["Scale"], self.Menu_OnScale, self)
    self.MenuITrans = menu:AddItem (0, L["Transparency"], self.Menu_OnTrans, self)

    local function func (item)
        self.MenuWin:ResetLayout()
    end

    menu:AddItem (0, L["Reset Layout"], func, self)
end

---------------------------------------------------------------------------------------

function Nx.Window:Menu_OnHideInCombat (item)
    self.MenuWin.SaveData["HideC"] = item:GetChecked()
end

function Nx.Window:Menu_OnLock (item)
    self.MenuWin:Lock (item:GetChecked())
end

function Nx.Window:Menu_OnFadeIn (item)

    local v = item:GetSlider()
    local svdata = self.MenuWin.SaveData

    svdata["FI"] = v
    self.MenuWin.BackgndFadeIn = v
end

function Nx.Window:Menu_OnFadeOut (item)

    local v = item:GetSlider()
    local svdata = self.MenuWin.SaveData

    svdata["FO"] = v
    self.MenuWin.BackgndFadeOut = v
end

function Nx.Window:Menu_OnLayer (item)

    local layer = item:GetSlider()
    self.MenuWin:SetFrmStrata (layer)
end

function Nx.Window:Menu_OnScale (item)

    local scale = item:GetSlider()
    local svdata = self.MenuWin.SaveData

    svdata[self.MenuWin.LayoutMode.."S"] = scale

    local f = self.MenuWin.Frm
    local s = f:GetScale()
    local x = f:GetLeft() * s
    local y = GetScreenHeight() - f:GetTop() * s

    f:ClearAllPoints()
    f:SetPoint ("TOPLEFT", x / scale, -y / scale)

    f:SetScale (scale)
end

function Nx.Window:Menu_OnTrans (item)

    local trans = item:GetSlider()
    local svdata = self.MenuWin.SaveData
    svdata[self.MenuWin.LayoutMode.."T"] = trans < 1 and trans or nil

    local f = self.MenuWin.Frm
    f:SetAlpha (trans)
end

---------------------------------------------------------------------------------------
-- Reset layouts of all created windows
---------------------------------------------------------------------------------------

function Nx.Window:ResetLayouts()

    for win, v in pairs (self.Wins) do
        win:ResetLayout()
    end
end

---------------------------------------------------------------------------------------
-- Check if ok to copy all window saved data from one character to another
---------------------------------------------------------------------------------------

function Nx.Window:CopyLayoutsCheck (swd, dwd)

    if dwd.Version and (not swd.Version or swd.Version < dwd.Version) then
        Nx.prt (L["Window version mismatch!"])
        return
    end

    self.SaveDisabled = true

    return true
end

---------------------------------------------------------------------------------------
-- Clear a window's saved data
---------------------------------------------------------------------------------------

function Nx.Window:ClrSaveData (name)

    local wd = Nx:GetData ("Win")
    wd[name] = nil
end

---------------------------------------------------------------------------------------
-- Force adjust of all created windows
---------------------------------------------------------------------------------------

function Nx.Window:AdjustAll()

    if self.Wins then
        for win in pairs (self.Wins) do
            win:Adjust()
        end
    end
end

---------------------------------------------------------------------------------------
-- Update hide status for combat
---------------------------------------------------------------------------------------

function Nx.Window:UpdateCombat()

    local combat = UnitAffectingCombat ("player")

    if self.Wins then

        for win in pairs (self.Wins) do
            if win.SaveData["HideC"] then

--                Nx.prt ("UCombat %s", win.Name)

                if combat then
                    win.Frm:Hide()
                else
                    if not win.SaveData["Hide"] and not win.RaidHid then
                        win.Frm:Show()
                    end
                end
            end
        end
    end
end

---------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------

function Nx.Window:ConsolePos (str)

    local name, x, y = self:ParseConsole (str)
    if not (x and y) then
        Nx.prt (L["XY missing (%s)"], str)
        return
    end

    local win = self:FindNoCase (name)
    if win then
        win:SetPos (x, -y)
        return
    end

    Nx.prt (L["Window not found (%s)"], str)
end

---------------------------------------------------------------------------------------
-- Show
---------------------------------------------------------------------------------------

function Nx.Window:ConsoleShow (str)

    local name, mode = self:ParseConsole (str)

    local win = self:FindNoCase (name)
    if win then
        if not mode then
            win:Show (not win:IsShown())
        elseif mode == 0 then
            win:Show (false)
        else
            win:Show()
        end
        return
    end

    Nx.prt (L["Window not found (%s)"], str)
end

---------------------------------------------------------------------------------------
-- Size
---------------------------------------------------------------------------------------

function Nx.Window:ConsoleSize (str)

    local name, x, y = self:ParseConsole (str)
    if not (x and y) then
        Nx.prt (L["XY missing (%s)"], str)
        return
    end

    local win = self:FindNoCase (name)
    if win then
        win:SetTotalSize (x, y)
        return
    end

    Nx.prt (L["Window not found (%s)"], str)
end

---------------------------------------------------------------------------------------
-- Parse
---------------------------------------------------------------------------------------

function Nx.Window:ParseConsole (str)

    local str = gsub (strlower (str), ",", " ")

    local name
    local x, y

    for s in gmatch (str, "%S+") do
        local i = tonumber (s)
        if i then
            if x then
                y = y or i
            else
                x = i
            end
        else
            if name then
                name = name .. " " .. s
            else
                name = s
            end
        end
    end

    local names = {
        ["map"] = "NxMap1",
--        ["watch"] = "NxQuestWatch",
    }

    return names[name] or name, x, y
end

---------------------------------------------------------------------------------------
-- Find a window by name. Case insensitive
---------------------------------------------------------------------------------------

function Nx.Window:FindNoCase (name)

    if self.Wins and name then
        name = strlower (name)
        for win in pairs (self.Wins) do
            if strlower (win.Name) == name then
                return win
            end
        end
    end
end

---------------------------------------------------------------------------------------
-- Find a window by name
---------------------------------------------------------------------------------------

function Nx.Window:Find (name)

    -- Use a name table?

    if self.Wins then
        for win in pairs (self.Wins) do
            if win.Name == name then
                return win
            end
        end
    end
end

---------------------------------------------------------------------------------------
-- Set fade values used for next window create
---------------------------------------------------------------------------------------

function Nx.Window:SetCreateFade (fadein, fadeout)

    self.CFadeIn = fadein
    self.CFadeOut = fadeout
end

---------------------------------------------------------------------------------------
-- Create a Window
-- ()
-- ret: window table
---------------------------------------------------------------------------------------

function Nx.Window:Create (name, minResizeW, minResizeH, secure, titleLines, borderType, hide, noButs)

    local c2rgba = Nx.Util_str2rgba

    local wd = Nx:GetData ("Win")
    local svdata = name and wd[name]

    if not svdata then        -- No data for our name?

        svdata = {}        -- New
        if name then
            wd[name] = svdata
        end

        svdata["Hide"] = hide
        svdata["FI"] = self.CFadeIn or 1
        svdata["FO"] = self.CFadeOut or .75
    end

    -- Debug
--    svdata["FI"] = self.CFadeIn or 1
--    svdata["FO"] = self.CFadeOut or .75

    -- New

    local win = {}

    setmetatable (win, self)
    self.__index = self

    win.SaveData = svdata

    if name then
        assert (self.Wins[win] == nil)
        self.Wins[win] = true

        win.Name = name
    end

    win.Secure = secure        -- Have secure children. Don't move in combat

    win.BorderW = self.BORDERW
    win.BorderH = self.BORDERH

    win.TitleLineH = 10
    win.TitleLines = titleLines or 1
    win.TitleH = win.TitleLines * win.TitleLineH + 2
    win.TopH = win.TitleH + win.BorderH

    win.ButW = 0            -- Top left corner button width

    win.Sizeable = true
    win.Border = true
    if borderType == false then
        win.Sizeable = false
        win.Border = false
    elseif borderType == 1 then
        win.Sizeable = false
    end

    win.MovSizing = false

    win.BackgndAlphaMin = .65
    win.BackgndAlphaDiff = .35    -- Max - min
    win.BackgndFade = .01        -- Current
    win.BackgndFadeTarget = 0    -- Target value
    win.BackgndFadeIn = svdata["FI"]
    win.BackgndFadeOut = svdata["FO"]

    win.ChildFrms = {}

    -- Create window frame

--    local f = CreateFrame ("Frame", name, UIParent, "SecureStateHeaderTemplate")
    local f = CreateFrame ("Frame", name, UIParent, "BackdropTemplate")
    win.Frm = f
    f.NxWin = win

--    f:SetAttribute ("showstates", "1")

    f:SetResizeBounds (minResizeW or 100, minResizeH or 40)

    f:SetWidth (10)
    f:SetHeight (win.TitleH + 50)

    f:SetPoint ("TOPLEFT", 100, -100)
    f:SetMovable (true)
    f:SetResizable (true)
    tinsert(NotInitializedWins,f)
    f:SetScript ("OnEvent", self.OnEvent)
--    f:RegisterEvent ("PLAYER_LOGIN")

    f:SetScript ("OnMouseDown", self.OnMouseDown)
    f:SetScript ("OnMouseUp", self.OnMouseUp)
    f:SetScript ("OnMouseWheel", self.OnMouseWheel)

    f:SetScript ("OnUpdate", self.OnUpdate)

    if not win.Border then

        local t = f:CreateTexture()
        t:SetColorTexture (c2rgba (".125|.125|.125|.75"))
        t:SetAllPoints (f)
        f.texture = t
    end

    -- Create title text

    win.TitleFStr = {}

    for n = 1, win.TitleLines do

        local fstr = f:CreateFontString()
        win.TitleFStr[n] = fstr
        fstr:SetFontObject ("NxFontS")
        fstr:SetJustifyH ("LEFT")
        fstr:SetJustifyV ("MIDDLE")
        fstr:SetHeight (win.TitleLineH)
    end

    win:SetTitleXOff (0)

    -- Create GUI elements

    if win.Border then
        win:CreateBorders()
    end

    if not noButs then

        local y = win.Sizeable and -win.BorderH or -3
--        local but = Nx.Button:Create (win.Frm, "Close", nil, nil, -win.BorderW, y, "TOPRIGHT", 12, 12, win.OnCloseBut, win, "SecureAnchorButtonTemplate")
        local but = Nx.Button:Create (win.Frm, "Close", nil, nil, -win.BorderW, y, "TOPRIGHT", 12, 12, win.OnCloseBut, win)
        win.ButClose = but
        but.Frm:Hide()
--[[
        local bf = but.Frm
        bf:SetAttribute ("anchorchild", "$parent")
        f:SetAttribute ("addchild", bf)
        bf:SetAttribute ("addchild", bf)
--]]
        win.ButW = 15
    else
        win.NoButs = true
    end

    -- Init layout (start false)

    win.LayoutMode = false        -- "" = normal, "Max", "Min", "User"

    --

    win:Lock (svdata["Lk"])
    win:Show (not svdata["Hide"])

    -- Reset creation stuff

    self:SetCreateFade()

    return win
end

---------------------------------------------------------------------------------------
-- Create buttons
---------------------------------------------------------------------------------------

function Nx.InitWins()
    for a,b in pairs(NotInitializedWins) do
        Nx.FixWin(b)
    end
end

function Nx.Window:CreateButtons (closer, maxer, miner)

--    assert (not self.NoButs)

    self.Closer = closer
    self.Maxer = maxer
    self.Miner = miner        -- No buts can be set while min is on

    local x = self.BorderW -26.5

    if self.Closer then
        self.ButClose.Frm:Show()
    end

    local y = self.Sizeable and -self.BorderH

    if self.Sizeable and self.Maxer then
        self.ButMaxer = Nx.Button:Create (self.Frm, "Max", nil, nil, x, y, "TOPRIGHT", 12, 12, self.OnMaxBut, self)
    end

    if self.Miner then
        self.ButMiner = Nx.Button:Create (self.Frm, "Min", nil, nil, x, y, "TOPRIGHT", 12, 12, self.OnMinBut, self)
    end

    self.ButW = -x - self.BorderW

    self:Lock (self:IsLocked())    -- Force button update
end

---------------------------------------------------------------------------------------
-- Create border frames
---------------------------------------------------------------------------------------

function Nx.Window:CreateBorders()

    local c2rgba = Nx.Util_str2rgba
    local Skin = Nx.Skin
--[[
    local winBorders = self.Borders

    for n = 1, 4 do

        local index = n * 5 - 4

        local f = CreateFrame ("Frame", nil, self.Frm)
        self["BorderFrm"..n] = f

        f:SetPoint (winBorders[index], 0, 0)
        f:SetPoint (winBorders[index + 1], 0, 0)

        f:SetWidth (winBorders[index + 2])
        f:SetHeight (winBorders[index + 3])

        local t = f:CreateTexture()
        local txName = Skin:GetTex (winBorders[index + 4])
        t:SetTexture (txName)
--        t:SetTexture ("Interface\\Buttons\\Bluegrad64")
--        t:SetTexture (c2rgba ("507050ff"))
        t:SetAllPoints (f)
        f.texture = t

        f:Show()
    end
--]]

    local bk = Nx.Skin:GetBackdrop()
    self.Frm:SetBackdrop (bk)
end

function Nx.Window:SetBordersFade (fade)

    if self.Border then
--[[
        local f

        for n = 1, 4 do

            f = self["BorderFrm"..n]
            f:SetAlpha (fade * .7)
        end
--]]

        local col = Nx.Skin:GetBorderCol()
        self.Frm:SetBackdropBorderColor (col[1], col[2], col[3], col[4] * fade)
    end
end

---------------------------------------------------------------------------------------
-- Set backdrops of all created windows
---------------------------------------------------------------------------------------

-- Region names NineSliceUtil creates on the container.
local NX_NINESLICE_PIECES = {
    "TopLeftCorner", "TopRightCorner",
    "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
    "Center",
}

local function NxClearNineSlice(frm)
    for i = 1, #NX_NINESLICE_PIECES do
        local p = frm[NX_NINESLICE_PIECES[i]]
        if p and p.Hide then
            p:Hide()
        end
    end
end

function Nx.Window:ResetBackdrops()

    if self.Wins then

        local bk = Nx.Skin:GetBackdrop()
        local nsLayout = Nx.Skin:GetNineSliceLayout()
        -- Verify the named layout actually exists in this flavor's
        -- NineSliceLayouts registry before calling ApplyLayoutByName.
        -- The function exists on Cata Classic / TBC Classic but many
        -- layouts (PortraitFrameTemplate, Dialog, etc.) aren't shipped
        -- there and Blizzard crashes with "attempt to index nil
        -- userLayout" if we pass an unknown name.
        local canNineSlice = false
        if nsLayout and NineSliceUtil and NineSliceUtil.ApplyLayoutByName
           and _G.NineSliceLayouts and _G.NineSliceLayouts[nsLayout] then
            canNineSlice = true
        end

        for win, v in pairs (self.Wins) do

            if win.Border then
                -- Strategy: always apply the legacy backdrop first as a
                -- guaranteed-visible base layer. When the theme also
                -- wants nine-slice atlas chrome we layer it on top —
                -- if atlas resolves it visually replaces the backdrop,
                -- if atlas fails (textureKit missing, layout
                -- incompatible with the frame, regions not rendering)
                -- the legacy backdrop is still there and the window
                -- is never transparent.
                if win.Frm._NxNineSliceApplied and not canNineSlice then
                    NxClearNineSlice(win.Frm)
                    win.Frm._NxNineSliceApplied = false
                end
                win.Frm:SetBackdrop (bk)
                if canNineSlice then
                    local ok = pcall(NineSliceUtil.ApplyLayoutByName, win.Frm, nsLayout)
                    if ok then
                        win.Frm._NxNineSliceApplied = true
                    end
                end

                win.BackgndFade = win.BackgndFadeTarget + .0001        -- Cause refresh
            end
        end
    end
end

---------------------------------------------------------------------------------------
-- Attach a child frame
---------------------------------------------------------------------------------------

function Nx.Window:Attach (childFrm, posX1, posX2, posY1, posY2, width, height)

--    Nx.prt ("AttachA #%s", #self.ChildFrms)

    local f = self.Frm

    if not posX1 then
        posX1 = 0
        posX2 = 1
        posY1 = 0
        posY2 = 1
    end

    local child

    for i, ch in ipairs (self.ChildFrms) do
        if ch.Frm == childFrm then
            child = ch
            break
        end
    end

    if not child then

        child = {}
        tinsert (self.ChildFrms, child)
        child.Frm = childFrm
        childFrm:SetParent (f)        -- Triggers frame updates which can call attach again!
    end

    child.PosX1 = posX1
    child.PosX2 = posX2
    child.PosY1 = posY1
    child.PosY2 = posY2

    if width then
        child.ScaleW = width
        child.ScaleH = height
    end

--    Nx.prtVar ("Attach", child)

    self:Adjust()
end

---------------------------------------------------------------------------------------
-- Detach a child frame
---------------------------------------------------------------------------------------

function Nx.Window:Detach (childFrm)

    Nx.prt (L["Detach %s"], #self.ChildFrms)

    for i, ch in ipairs (self.ChildFrms) do
        if ch.Frm == childFrm then
            tremove (self.ChildFrms, i)
            Nx.prt (L["Detach found %s"], #self.ChildFrms)
            break
        end
    end
end

---------------------------------------------------------------------------------------
-- Adjust title width and child frames to fit our client area
---------------------------------------------------------------------------------------

function Nx.Window:Adjust (skipChildren)
    if InCombatLockdown() and Nx.db.profile.Map.Compatibility then
        return
    end
    local f = self.Frm

    local w = f:GetWidth() - self.BorderW * 2
    local h = f:GetHeight() - self.TitleH - self.BorderH * 2

    for _, fstr in ipairs (self.TitleFStr) do
        fstr:SetWidth (w - self.ButW)
    end

    if not skipChildren then

        local x, y

        for n = 1, #self.ChildFrms do

            local child = self.ChildFrms[n]
            local cf = child.Frm

            if cf and not cf:IsProtected() then
                x = child.PosX1
                if x < 0 then
                    x = w + x    -- Offset from right edge
                elseif x <= 1 then
                    x = w * x    -- Percent
                end

                local x2 = child.PosX2
                if x2 < 0 then
                    x2 = w + x2    -- Offset from right edge
                elseif x2 <= 1 then
                    x2 = w * x2    -- Percent
                end

                y = child.PosY1
                if y <= -10000 then
                    y = y + 10000
                elseif y < 0 then
                    y = h + y
                elseif y <= 1 then
                    y = h * y
                end

                local y2 = child.PosY2
                if y2 <= -10000 then
                    y2 = y2 + 10000
                elseif y2 < 0 then
                    y2 = h + y2
                elseif y2 <= 1 then
                    y2 = h * y2
                end

                cf:SetPoint ("TOPLEFT", f, "TOPLEFT", x + self.BorderW, -y - self.TopH)

                local childW = x2 - x
                local childH = y2 - y

                if child.ScaleW then

                    local sw = childW / child.ScaleW
                    local sh = childH / child.ScaleH
                    local scale = max (min (sw, sh), .001)
                    cf:SetScale (scale)

                    cf:SetPoint ("TOPLEFT", f, "TOPLEFT", (self.BorderW + w * child.PosX1) / scale, (-self.TopH - h * child.PosY1) / scale)

                else

                    local inst = cf.NxInst

                    if inst and inst.SetSize then
                        inst:SetSize (childW, childH)
                    else
                        cf:SetWidth (childW)
                        cf:SetHeight (childH)
                    end
                end

                if cf.NxSetSize then
                    cf:NxSetSize (childW, childH)
                end
            end
            --            prtFrame ("Adj"..n, cf)
        end
    end
end

---------------------------------------------------------------------------------------
-- Get a window attribute
---------------------------------------------------------------------------------------

function Nx.Window:GetAttribute (winName, atName)

    local win = self:Find (winName)

    if win then
        if atName == "L" then        -- Locked
            return "B", win:IsLocked()

        elseif atName == "H" then    -- Hide
            return "B", not win:IsShown()
        end
    end
end

---------------------------------------------------------------------------------------
-- Set a window attribute
---------------------------------------------------------------------------------------

function Nx.Window:SetAttribute (winName, atName, value)

    local win = self:Find (winName)

    if win then
        if atName == "L" then        -- Locked
            win:Lock (value)

        elseif atName == "H" then    -- Hide
            win:Show (not value)
        end
    end
end

---------------------------------------------------------------------------------------
-- Show or hide window
---------------------------------------------------------------------------------------

function Nx.Window:Show (show)

    local svdata = self.SaveData

    if show ~= false then
        self.Frm:Show()
        self.Frm:Raise()
        self.Frm:Raise()
        svdata["Hide"] = nil
    else
        if self.Frm:IsShown() then        -- Check first to avoid taint errors
            self.Frm:Hide()
        end
        svdata["Hide"] = true
    end
end

---------------------------------------------------------------------------------------
-- Check if shown
---------------------------------------------------------------------------------------

function Nx.Window:IsShown()

    local svdata = self.SaveData

    local vis = self.Frm:IsShown()
    if vis == nil then
        vis = false
    end

    return vis, not svdata["Hide"]
end

---------------------------------------------------------------------------------------
-- Restore saved show or hide state
---------------------------------------------------------------------------------------

--[[
function Nx.Window:ShowRestore()

    if self.SaveData["Hide"] then
        self.Frm:Hide()
    else
        self.Frm:Show()
    end
end
--]]

---------------------------------------------------------------------------------------
-- Check if visible (parent must also be visible)
---------------------------------------------------------------------------------------

function Nx.Window:IsVisible()
    return self.Frm:IsVisible()
end

---------------------------------------------------------------------------------------
-- Check if hidden from combat
---------------------------------------------------------------------------------------

function Nx.Window:IsCombatHidden()

    if self.SaveData["HideC"] then
        return UnitAffectingCombat ("player")
    end
end

---------------------------------------------------------------------------------------
-- Lock or unlock window. Cannot move, resize or scale if locked
---------------------------------------------------------------------------------------
function Nx.Window:Lock (lock, fullLockout)

--    Nx.prtVar ("Win:Lock", lock)

    self.Locked = lock
    self.Frm:EnableMouse (not lock)
    self.Frm:EnableMouseWheel (not lock)

    local svdata = self.SaveData

    svdata["Lk"] = lock or nil

    self:SetBordersFade (lock and 0 or self.BackgndFade)

    if self.ButClose then
        if lock then

            if self.Closer then
                self.ButClose:SetType ("CloseLock")
            else
                self.ButClose.Frm:Show()
                self.ButClose:SetType ("Lock")
            end
        else

            if self.Closer then
                self.ButClose:SetType ("Close")
            else
                self.ButClose.Frm:Hide()
            end
        end

        self.ButClose:Update()
    end

    -- Locking can show the close/lock control. Reapply the minimized contract
    -- so registered windows still expose only their restore switch.
    self:ApplyMinimizedFrameVisibility()

    if fullLockout then
        self.FullLock = lock
    end
end

---------------------------------------------------------------------------------------
-- Get lock status of window
---------------------------------------------------------------------------------------

function Nx.Window:IsLocked()
    return self.Locked
end

---------------------------------------------------------------------------------------
-- Set if mouse enabled for window
---------------------------------------------------------------------------------------

function Nx.Window:EnableMouse (on)

    self.FullLock = not on

    if self.MovSizing then
        self.OnMouseUp (self.Frm, "")
    end

    if self.ButClose then
        if on then
            self.ButClose.Frm:Show()
        else
            self.ButClose.Frm:Hide()
        end
    end

    if on then
        self:Lock (self.Locked)        -- Restore
    else
        self.Frm:EnableMouse (on)
        self.Frm:EnableMouseWheel (on)
    end

end

---------------------------------------------------------------------------------------
-- Set if we have a window menu
---------------------------------------------------------------------------------------

function Nx.Window:EnableMenu (on)
    self.MenuDisable = not on
end

---------------------------------------------------------------------------------------
-- Get title text width
---------------------------------------------------------------------------------------

function Nx.Window:GetTitleTextWidth()

    local w = 40

    for n = 1, self.TitleLines do

        local fstr = self.TitleFStr[n]
        fstr:SetWidth (0)

        w = max (self.TitleFStr[n]:GetStringWidth(), w)
    end

    return w
end

---------------------------------------------------------------------------------------
-- Set title text line height
---------------------------------------------------------------------------------------

function Nx.Window:SetTitleLineH (height)

    self.TitleLineH = height
    self.TitleH = self.TitleLines * self.TitleLineH + 2
    self.TopH = self.TitleH + self.BorderH

    local fname = height <= 10 and "NxFontS" or "NxFontM"

    for n = 1, self.TitleLines do

        local fstr = self.TitleFStr[n]
        fstr:SetFontObject (fname)
        fstr:SetHeight (height)
    end
end

---------------------------------------------------------------------------------------
-- Set the title text x offset (also y. rename!)
---------------------------------------------------------------------------------------

function Nx.Window:SetTitleXOff (x, yo)

    yo = yo or 0

    for n = 1, self.TitleLines do

        local fstr = self.TitleFStr[n]
        local y = -self.BorderH - (n - 1) * self.TitleLineH - .4        -- Fudge it so it looks better
        fstr:SetPoint ("TOPLEFT", self.BorderW + x, y - yo)
        fstr:SetPoint ("TOPRIGHT", self.Frm, "TOPRIGHT", -self.BorderW, y)
    end
end

---------------------------------------------------------------------------------------
-- Set our title text
---------------------------------------------------------------------------------------

function Nx.Window:SetTitle (text, line)

    line = line or 1
    if self.TitleFStr[line] then
        self.TitleFStr[line]:SetText (text)
    end
end

---------------------------------------------------------------------------------------
-- Set all title colors
---------------------------------------------------------------------------------------

function Nx.Window:SetTitleColors (r, g, b, a)

    for n = 1, self.TitleLines do

        local fstr = self.TitleFStr[n]
        fstr:SetTextColor (r, g, b, a)
    end
end

---------------------------------------------------------------------------------------
-- Set our title text
---------------------------------------------------------------------------------------

function Nx.Window:SetTitleJustify (mode, line)

    line = line or 1
    self.TitleFStr[line]:SetJustifyH (mode)
end

---------------------------------------------------------------------------------------
-- Get our background min max alpha
---------------------------------------------------------------------------------------

function Nx.Window:GetBGAlpha()

    local m = self.BackgndAlphaMin
    return m, m + self.BackgndAlphaDiff
end

---------------------------------------------------------------------------------------
-- Set our background min max alpha
---------------------------------------------------------------------------------------

function Nx.Window:SetBGAlpha (min, max)

    self.BackgndAlphaMin = min
    self.BackgndAlphaDiff = max - min

    self.BackgndFade = self.BackgndFadeTarget + .0001    -- Cause refresh
end

---------------------------------------------------------------------------------------
-- Get our current fade
---------------------------------------------------------------------------------------

function Nx.Window:GetFade()
    return self.BackgndFade
end

---------------------------------------------------------------------------------------
-- Set our background color
---------------------------------------------------------------------------------------

function Nx.Window:SetBGColor (r, g, b, a)
    if self.Frm.texture then
        self.Frm.texture:SetColorTexture (r, g, b, a or 1)
    end
end

---------------------------------------------------------------------------------------
-- Get win width and height
---------------------------------------------------------------------------------------

function Nx.Window:GetClientOffset()
    return self.BorderW, self.TitleH + self.BorderH
end

---------------------------------------------------------------------------------------
-- Set if win is sizeable
---------------------------------------------------------------------------------------

function Nx.Window:SetSizeable (on)
    self.Sizeable = on
end

---------------------------------------------------------------------------------------
-- Get win width and height (client size)
---------------------------------------------------------------------------------------

function Nx.Window:GetSize()

    return self.Frm:GetWidth() - self.BorderW * 2,
             self.Frm:GetHeight() - self.TitleH + self.BorderH * 2
end

---------------------------------------------------------------------------------------
-- Set win width and height (client size)
---------------------------------------------------------------------------------------

function Nx.Window:SetSize (width, height, skipChildren)
    if InCombatLockdown() then
        return
    end
    self.Frm:SetWidth (width + self.BorderW * 2)
    self.Frm:SetHeight (height + self.TitleH + self.BorderH * 2)

    self:Adjust (skipChildren)
end

---------------------------------------------------------------------------------------
-- Set win width and height (win size)
---------------------------------------------------------------------------------------

function Nx.Window:SetTotalSize (width, height, skipChildren)

    self.Frm:SetWidth (width)
    self.Frm:SetHeight (height)

    self:Adjust (skipChildren)
    self:RecordLayoutData()
end

---------------------------------------------------------------------------------------
-- Set win pos
---------------------------------------------------------------------------------------

function Nx.Window:SetPos (x, y)

    local f = self.Frm
    f:ClearAllPoints()
    f:SetPoint ("TOPLEFT", x, y)

    self:RecordLayoutData()
end

---------------------------------------------------------------------------------------
-- Offset win pos
---------------------------------------------------------------------------------------

function Nx.Window:OffsetPos (xo, yo)

    local f = self.Frm
    local atPt, relTo, relPt, x, y = f:GetPoint()

    f:SetPoint (atPt, relTo, relPt, x + xo, y + yo)

    self:RecordLayoutData()
end

---------------------------------------------------------------------------------------
-- Get size of borders
---------------------------------------------------------------------------------------

function Nx.Window:GetBorderSize()
    return self.BorderW, self.BorderH
end

---------------------------------------------------------------------------------------
-- Set size of borders
---------------------------------------------------------------------------------------

function Nx.Window:SetBorderSize (w, h)

    self.BorderW = w
    self.BorderH = h
    self.TopH = self.TitleH + h
end

---------------------------------------------------------------------------------------
-- Reset layout to default
-- self = Win
---------------------------------------------------------------------------------------

function Nx.Window:ResetLayout()

    local data = self.SaveData

    if data["_X"] then

        for k, v in pairs (data) do

            if k ~= "_X" then
                if strsub (k, -1) == "X" then
                    local mode = strsub (k, 1, #k - 1)

--                    Nx.prt ("Reset %s '%s' %f %f %f %f, %s, %s",
--                            self.Name, mode, data["_X"], data["_Y"], data["_W"], data["_H"], data["_A"] or "nil", data["_S"] or "nil")

                    self:SetLayoutData (mode, data["_X"], data["_Y"], data["_W"], data["_H"], data["_L"], data["_A"], data["_S"])

                    self:SetMaxSizeDefault()
                end
            end
        end

        self.LayoutMode = false
        data["MinUserPlaced"] = nil
        data["IndependentMinimizePositions"] = nil
        self:SetLayoutMode()
--        self.Frm:SetScale (1)
    end

    self:Lock (false)

    if self.Name == "NxMap1" or self.Name == "NxQuestWatch" then
        self.Frm:Show()
        data["Hide"] = nil
    end
end

---------------------------------------------------------------------------------------
-- Set max size to default
-- self = Win
---------------------------------------------------------------------------------------

function Nx.Window:SetMaxSizeDefault()

    local sw = GetScreenWidth()
    local sh = GetScreenHeight()
    self:SetLayoutData ("Max", sw * .1, sh * .1, sw * .8, sh * .8, 2, "TOPLEFT")
end

---------------------------------------------------------------------------------------
-- Get current layout mode name
-- self = Win
---------------------------------------------------------------------------------------

function Nx.Window:GetLayoutMode()
    return self.LayoutMode
end

---------------------------------------------------------------------------------------
-- Copy only the screen anchor shared by normal and minimized layouts
---------------------------------------------------------------------------------------

local function IsLayoutNumber (value)
    return type (value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

function Nx.Window:CopyLayoutPosition (sourceMode, targetMode)

    sourceMode = sourceMode or ""
    targetMode = targetMode or ""

    local data = self.SaveData
    local x = data[sourceMode.."X"]
    local y = data[sourceMode.."Y"]

    if x == nil or y == nil then
        return
    end

    data[targetMode.."A"] = data[sourceMode.."A"]
    data[targetMode.."X"] = x
    data[targetMode.."Y"] = y
    data[targetMode.."S"] = data[sourceMode.."S"]

    -- CopyLayoutPosition intentionally does not copy the full layout size.
    -- A fresh profile can therefore acquire MinX/MinY before a minimized
    -- layout has ever been initialized. Complete that layout here so every
    -- client can safely restore it from SavedVariables.
    if targetMode == "Min" then
        if not IsLayoutNumber (data["MinW"]) then
            data["MinW"] = 125
        end
        if not IsLayoutNumber (data["MinH"]) then
            data["MinH"] = 40
        end
    end
end

local LayoutAnchorFactors = {
    TOPLEFT = { 0, 1 },
    TOP = { .5, 1 },
    TOPRIGHT = { 1, 1 },
    LEFT = { 0, .5 },
    CENTER = { .5, .5 },
    RIGHT = { 1, .5 },
    BOTTOMLEFT = { 0, 0 },
    BOTTOM = { .5, 0 },
    BOTTOMRIGHT = { 1, 0 },
}

---------------------------------------------------------------------------------------
-- Keep a saved window layout inside the current screen bounds
---------------------------------------------------------------------------------------

function Nx.Window:ClampLayoutPositionToScreen (mode, frameW, frameH)

    mode = mode or ""

    local data = self.SaveData
    local x = data[mode.."X"]
    local y = data[mode.."Y"]
    local w = frameW or data[mode.."W"]
    local h = frameH or data[mode.."H"]
    local scale = data[mode.."S"] or 1

    if type (x) ~= "number" or type (y) ~= "number"
        or type (w) ~= "number" or type (h) ~= "number"
        or type (scale) ~= "number" or scale <= 0
        or x ~= x or y ~= y or w ~= w or h ~= h or scale ~= scale then
        return false
    end

    w = math.abs (w)
    h = math.abs (h)
    if w <= 0 or h <= 0 then
        return false
    end

    local sw = GetScreenWidth()
    local sh = GetScreenHeight()
    if type (sw) ~= "number" or type (sh) ~= "number" or sw <= 0 or sh <= 0 then
        return false
    end

    local aPt = data[mode.."A"] or "TOPLEFT"
    local factors = LayoutAnchorFactors[aPt]
    if not factors then
        aPt = "TOPLEFT"
        factors = LayoutAnchorFactors.TOPLEFT
        data[mode.."A"] = nil
    end

    local xFactor = factors[1]
    local yFactor = factors[2]
    local scaledW = w * scale
    local scaledH = h * scale

    -- Saved offsets are in the frame's scaled coordinate system. Convert the
    -- selected anchor into a screen rectangle, move that rectangle on-screen,
    -- then convert only the required correction back to saved offsets.
    local anchorX = sw * xFactor + x * scale
    local anchorY = sh * yFactor - y * scale
    local left = anchorX - scaledW * xFactor
    local bottom = anchorY - scaledH * yFactor

    local targetLeft
    if scaledW <= sw then
        targetLeft = math.max (0, math.min (left, sw - scaledW))
    else
        targetLeft = 0
    end

    local targetBottom
    if scaledH <= sh then
        targetBottom = math.max (0, math.min (bottom, sh - scaledH))
    else
        -- Oversized layouts keep their title edge visible at the top.
        targetBottom = sh - scaledH
    end

    local dx = targetLeft - left
    local dy = targetBottom - bottom
    if math.abs (dx) < .01 and math.abs (dy) < .01 then
        return false
    end

    data[mode.."X"] = x + dx / scale
    data[mode.."Y"] = y - dy / scale
    return true
end

---------------------------------------------------------------------------------------
-- Select shared or independent normal/minimized window anchors
---------------------------------------------------------------------------------------

function Nx.Window:CaptureIndependentMinimizePositions()

    local data = self.SaveData
    data["IndependentMinimizePositions"] = {
        Normal = {
            A = data["A"],
            X = data["X"],
            Y = data["Y"],
            S = data["S"],
        },
        Min = {
            A = data["MinA"],
            X = data["MinX"],
            Y = data["MinY"],
            S = data["MinS"],
        },
    }
end

function Nx.Window:RestoreIndependentMinimizePositions()

    local data = self.SaveData
    local positions = data["IndependentMinimizePositions"]
    if not positions then
        return
    end

    local normal = positions.Normal or {}
    data["A"] = normal.A
    data["X"] = normal.X
    data["Y"] = normal.Y
    data["S"] = normal.S

    local minimized = positions.Min or {}
    data["MinA"] = minimized.A
    data["MinX"] = minimized.X
    data["MinY"] = minimized.Y
    data["MinS"] = minimized.S
end

function Nx.Window:SetShareMinimizePosition (enabled)

    enabled = enabled == true
    self.ShareMinimizePosition = enabled
    self.KeepMinimizePositionsOnScreen = true

    local data = self.SaveData
    if not data then
        return
    end

    local wasEnabled = data["ShareMinimizePositionActive"] == true
    local mode = self.LayoutMode

    if enabled then
        -- Keep the independent anchors intact so disabling this option really
        -- returns to the user's last separate full/minimized positions.
        if not wasEnabled then
            self:CaptureIndependentMinimizePositions()
        end
        data["ShareMinimizePositionActive"] = true

        -- The currently displayed layout becomes authoritative when sharing is
        -- enabled. RecordLayoutData mirrors it to the other layout immediately.
        data["MinUserPlaced"] = nil

        if mode == "" or mode == "Min" then
            self:RecordLayoutData()
        end
    else
        if wasEnabled then
            self:RestoreIndependentMinimizePositions()
        end
        data["ShareMinimizePositionActive"] = nil

        -- Opt out of the legacy first-minimize migration that would otherwise
        -- replace the independently saved MinX/MinY position.
        data["MinUserPlaced"] = true

        -- Apply the restored anchor immediately when the option changes while
        -- the window is open. Avoid recording the shared position over the
        -- restored data during this same-layout refresh.
        local compatibility = Nx.db and Nx.db.profile and Nx.db.profile.Map
            and Nx.db.profile.Map.Compatibility
        if wasEnabled and (mode == "" or mode == "Min")
            and not (InCombatLockdown() and compatibility) then
            self.LayoutMode = false
            self:SetLayoutMode (mode)
        end
    end
end

---------------------------------------------------------------------------------------
-- Register and update controls hidden by the minimized layout
---------------------------------------------------------------------------------------

function Nx.Window:SetMinimizedHideFrames (frames)
    self.MinimizedHideFrames = frames
    self:ApplyMinimizedFrameVisibility()
end

function Nx.Window:ApplyMinimizedFrameVisibility()

    local frames = self.MinimizedHideFrames
    if not frames then
        return
    end

    if self.LayoutMode == "Min" then

        local visibility = self.MinimizedFrameVisibility
        if not visibility then
            visibility = {}
            self.MinimizedFrameVisibility = visibility

            for _, frame in ipairs (frames) do
                visibility[frame] = frame:IsShown() and true or false
            end
        end

        for _, frame in ipairs (frames) do
            frame:Hide()
        end

    elseif self.MinimizedFrameVisibility then

        local visibility = self.MinimizedFrameVisibility
        self.MinimizedFrameVisibility = nil

        for _, frame in ipairs (frames) do
            if visibility[frame] then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end
end

---------------------------------------------------------------------------------------
-- Switch our layout mode if different and not maximized
-- self = Win
---------------------------------------------------------------------------------------

function Nx.Window:SwitchLayoutMode (mode)

    mode = mode or ""

    if self.LayoutMode ~= mode then

        if self.LayoutMode == "Max" then
            self.LayoutModeNormal = mode        -- Remember for later
        else
            self:SetLayoutMode (mode)
        end
    end
end

---------------------------------------------------------------------------------------
-- Set our layout mode and change to size/position
-- (mode or 1 if first time (login))
-- self = Win
---------------------------------------------------------------------------------------

function Nx.Window:SetLayoutMode (mode)
    if InCombatLockdown() and Nx.db.profile.Map.Compatibility then
        return
    end
    local data = self.SaveData

    if mode == 1 then

        mode = data["Mode"]        -- nil, "Min", "Max"

        if mode == "Min" then
            self:SetLayoutMode()
            self:SetMinimize (true)
            return
        end
    end

    if mode == "" then
        mode = nil
    end

    data["Mode"] = mode

    mode = mode or ""

--    Nx.prt ("SetLayoutMode '%s' to '%s'", self.LayoutMode or "nil", mode)

    local f = self.Frm

    local oldMode = self.LayoutMode
    if oldMode then
        self:RecordLayoutData()
    end

    if self.ButMiner then

        if mode == "Min" then
--            mode = ""
            data["Min"] = true
            self.ButMiner:SetPressed (true)

        else
            data["Min"] = nil
            self.ButMiner:SetPressed (false)
        end
    end

    if self.ButMaxer then

        if mode == "Max" then
            self.ButMaxer:SetType ("MaxOn")
        else
            self.ButMaxer:SetType ("Max")
        end
        self.ButMaxer:Update()
    end

    self.LayoutMode = mode

    local sw = GetScreenWidth()
    local sh = GetScreenHeight()

    if mode == "Max" and not data["MaxX"] then
        self:SetMaxSizeDefault()
--        Nx.prt ("Setting win max")
    end

    -- The quest watch uses one screen anchor in both layouts. RecordLayoutData
    -- also mirrors this position immediately after a drag, so reloading while
    -- minimized cannot resurrect an older normal-layout position.
    if self.ShareMinimizePosition then
        local sourceMode = oldMode or ""

        if mode == "Min" and sourceMode ~= "Min" then
            self:CopyLayoutPosition (sourceMode, "Min")
        elseif sourceMode == "Min" and mode ~= "Min" then
            self:CopyLayoutPosition ("Min", mode)
        end

        -- Retire the Phase 30.6 independent-minimized-position marker.
        data["MinUserPlaced"] = nil

    -- Other Carbonite windows retain their existing independent minimized
    -- placement behavior.
    elseif mode == "Min" and oldMode ~= "Min" and not data["MinUserPlaced"] then
        local atPt, _, relPt, minX, minY = f:GetPoint()
        if atPt and minX and minY and (not relPt or atPt == relPt) then
            self:SetLayoutData (mode, minX, -minY, 125, 28,
                data[(oldMode or "").."L"], atPt, f:GetScale())
        end
    end

    local x = data[mode.."X"]
    local y = data[mode.."Y"]
    local w = data[mode.."W"]
    local h = data[mode.."H"]

    -- Saved layout records from older or first-use profiles can be partial.
    -- Validate all four values together before arithmetic or frame setters use
    -- them, preserving every valid coordinate and dimension during repair.
    if not IsLayoutNumber (x) or not IsLayoutNumber (y)
        or not IsLayoutNumber (w) or not IsLayoutNumber (h) then

        if mode == "Min" then
            local atPt, _, relPt, frameX, frameY = f:GetPoint()
            local hasFramePoint = atPt and IsLayoutNumber (frameX)
                and IsLayoutNumber (frameY) and (not relPt or atPt == relPt)

            x = IsLayoutNumber (x) and x
                or (hasFramePoint and frameX or sw * .9)
            y = IsLayoutNumber (y) and y
                or (hasFramePoint and -frameY or sh * .4)
            w = IsLayoutNumber (w) and w or 125
            h = IsLayoutNumber (h) and h or 28

            local attachPt = data[mode.."A"]
            if not attachPt and hasFramePoint then
                attachPt = atPt
            end

            local scale = data[mode.."S"]
            if not IsLayoutNumber (scale) or scale <= 0 then
                scale = f:GetScale()
                if not IsLayoutNumber (scale) or scale <= 0 then
                    scale = 1
                end
            end

            self:SetLayoutData (mode, x, y, w, h,
                data[(oldMode or "").."L"], attachPt, scale)
        else
            x = IsLayoutNumber (x) and x or sw * .4
            y = IsLayoutNumber (y) and y or sh * .4
            w = IsLayoutNumber (w) and w or sw * .2
            h = IsLayoutNumber (h) and h or sh * .2

            self:SetLayoutData (mode, x, y, w, h, false,
                data[mode.."A"], data[mode.."S"])
        end
    end

    if w < 0 then
        w = sw * -w
    end

    if h < 0 then
        h = sh * -h
    end

    if x >= 999999 then                -- Center
        x = (sw - w) * .5

    elseif x >= 300000 then                -- Offset + from screen center
        local s = data[mode.."S"] or 1
        x = (sw * .5 + (x - 300000)) / s

    elseif x >= 200000 then                -- Offset - from screen center
        local s = data[mode.."S"] or 1
        x = (sw * -.5 - (x - 200000)) / s
--        x = sw * .5 - (x - 200000) - w

    elseif x > 100000 then                -- Offset from screen right
        x = sw - x + 100000 - self.BorderW

    elseif x < 0 and x > -1 then            -- % of width
        x = sw * -x
    end

    if y >= 999999 then                -- Center
        y = (sh - h) * .5
    elseif y < 0 and y > -1 then            -- % of height
        y = sh * -y
    end

    self:SetLayoutData (mode, x, y, w, h, false,
        data[mode.."A"], data[mode.."S"])

    if self.KeepMinimizePositionsOnScreen and (mode == "" or mode == "Min") then
        local clampW
        local clampH

        -- In shared mode the smaller minimized strip must be placed where the
        -- full watch can also open. This prevents a valid strip position near
        -- an edge from turning into an unreachable full window on restore.
        if self.ShareMinimizePosition then
            clampW = data["W"]
            clampH = data["H"]
            if type (clampW) ~= "number" or clampW <= 0 then
                clampW = data[mode.."W"]
            end
            if type (clampH) ~= "number" or clampH <= 0 then
                clampH = data[mode.."H"]
            end
        end

        self:ClampLayoutPositionToScreen (mode, clampW, clampH)

        -- A repaired shared anchor remains one anchor. Do not leave the other
        -- layout holding the stale off-screen coordinates that were repaired.
        if self.ShareMinimizePosition then
            self:CopyLayoutPosition (mode, mode == "Min" and "" or "Min")
        end
    else
        local aPt = data[mode.."A"] or "TOPLEFT"

        if aPt == "TOPLEFT" then
            if data[mode.."X"] > sw - 20 then
                data[mode.."X"] = sw - 20
--                Nx.prt ("Fix %s x", self.Name)
            end
        end
        if aPt == "TOPRIGHT" or aPt == "RIGHT" or aPt == "BOTTOMRIGHT" then
            if data[mode.."X"] > 20 then
                data[mode.."X"] = 20
--                Nx.prt ("Fix %s x", self.Name)
            end
        end
    end

    local aPt = data[mode.."A"] or "TOPLEFT"

--    prt ("Y "..data[mode.."Y"])
--    prt ("%s H %f", self.Name, data[mode.."H"])

    self:SetFrmStrata (data[mode.."L"])

    f:ClearAllPoints()
    f:SetPoint (aPt, data[mode.."X"], -data[mode.."Y"])
    f:SetWidth (data[mode.."W"])
    f:SetHeight (data[mode.."H"])
    f:SetScale (data[mode.."S"] or 1)
    f:SetAlpha (data[mode.."T"] or 1)

--    prt ("SetLayoutMode %s WH %f %f", data[mode.."A"] or "nil", data[mode.."W"], data[mode.."H"])

    if mode == "Max" then

        f:Raise()
        f:Raise()
--        prt ("Y "..sh)
    end

    if mode == "Min" then
        f:SetWidth (125)
        f:SetHeight (28)
    end

    self:Adjust()
    self:ApplyMinimizedFrameVisibility()
end

---------------------------------------------------------------------------------------
-- Set strata
-- self = Win
---------------------------------------------------------------------------------------

function Nx.Window:SetFrmStrata (layer)

    local svdata = self.SaveData
    svdata[self.LayoutMode.."L"] = layer

    self.Frm:SetFrameStrata (self.StrataNames[layer] or "MEDIUM")
end

---------------------------------------------------------------------------------------
-- Init default data for a layout mode
-- self = Win

function Nx.Window:InitLayoutData (mode, x, y, w, h, layer, scale)

    local data = self.SaveData

    -- w and h are client size
    if w > 0 then
        w = w + self.BorderW
    end
    if h > 0 then
        h = h + self.BorderH + self.TitleH
    end

--    Nx.prt ("InitLayout %s '%s' %f %f %f %f, %s",
--            self.Name, mode or "_", x, y, w, h, scale or "")

    local attach

    if scale then

        if x >= 300000 then            -- Offset + from screen center
        elseif x >= 200000 then            -- Offset - from screen center
            attach = "TOPRIGHT"
--            x = (x - 200000) * scale + 200000
        end
    end

    if not mode then
        mode = ""
        self:SetLayoutData ("_", x, y, w, h, layer, attach, scale)    -- Original position for reset
    end

    if not data[mode.."X"] then
        self:SetLayoutData (mode, x, y, w, h, layer, attach, scale)
    end

    if self.LoginDone then                -- Already logged in?
        self:SetLayoutMode (1)
    end
end

---------------------------------------------------------------------------------------
-- Set data for a layout mode
-- self = Win
---------------------------------------------------------------------------------------

function Nx.Window:SetLayoutData (mode, x, y, w, h, layer, attachPt, scale)

--    Nx.prt ("SetLayoutData %s %s", self.Name, mode)

    if not Nx.Window.SaveDisabled then

        local data = self.SaveData

--        if self.Name == "NxHUD" and mode == "_" then
--            Nx.prt ("SetLayout %s '%s' %f %f %f %f, %s",
--                    self.Name, mode, x, y, w, h, attachPt or "")
--        end

        if attachPt == "TOPLEFT" then
            attachPt = nil            -- Don't save default
        end

        data[mode.."A"] = attachPt
        data[mode.."X"] = x
        data[mode.."Y"] = y
        data[mode.."W"] = w
        data[mode.."H"] = h < 0 and h or max (h, 40)
        if layer ~= false then
            data[mode.."L"] = layer
        end
        data[mode.."S"] = scale ~= 1 and scale or nil
    end
end

---------------------------------------------------------------------------------------
-- Record current layout
-- self = Win
---------------------------------------------------------------------------------------

function Nx.Window:RecordLayoutData()

    if self.LayoutMode then

        local f = self.Frm
        local atPt, relTo, relPt, x, y = f:GetPoint()
        local scale = f:GetScale()

--        Nx.prt ("Record %s(%s): %s %s %s %s %s %d", self.Name, self.LayoutMode, atPt, (relTo and relTo:GetName()) or "nil", relPt, x, y, scale)

        -- A frame that's mid-drag can return nil from GetPoint when
        -- StartMoving/StopMovingOrSizing fires on a frame with no
        -- anchor. Bail out — there's nothing useful to record.
        if not (atPt and x and y) then return end

        assert (atPt == relPt)

        if x < 0 and x >= -1 then    -- Neg small numbers used for % of screen W
            x = 0
        end

        y = -y

        if y < 0 and y >= -1 then    -- Neg small numbers used for % of screen H
            y = 0
        end

        local w = f:GetWidth()
        local data = self.SaveData

        if self.LayoutMode == "" then

            if self.Name == "NxMap1" and data["MaxW"] and w >= data["MaxW"] then
--                Nx.prt ("Window %s Normal >= Max layout. Not saving", self.Name)
                return
            end

        elseif self.LayoutMode == "Max" then

--            Nx.prt ("Window %s %s", w, data["W"])

            if self.Name == "NxMap1" and data["W"] and w <= data["W"] then
--                Nx.prt ("Window %s Max <= Normal layout. Not saving", self.Name)
                return
            end
        end

        local mode = self.LayoutMode
        self:SetLayoutData (mode, x, y, f:GetWidth(), f:GetHeight(), false, atPt, scale)

        if self.KeepMinimizePositionsOnScreen and (mode == "" or mode == "Min") then
            local clampW
            local clampH

            if self.ShareMinimizePosition then
                clampW = data["W"]
                clampH = data["H"]
                if type (clampW) ~= "number" or clampW <= 0 then
                    clampW = data[mode.."W"]
                end
                if type (clampH) ~= "number" or clampH <= 0 then
                    clampH = data[mode.."H"]
                end
            end

            if self:ClampLayoutPositionToScreen (mode, clampW, clampH) then
                f:ClearAllPoints()
                f:SetPoint (data[mode.."A"] or "TOPLEFT",
                    data[mode.."X"], -data[mode.."Y"])
            end
        end

        -- The watch window has one user-owned location. Mirror a drag at once
        -- so the matching layout is correct even if the UI reloads before the
        -- user toggles minimize/restore again.
        if self.ShareMinimizePosition and (mode == "" or mode == "Min") then
            self:CopyLayoutPosition (mode, mode == "Min" and "" or "Min")
            self.SaveData["MinUserPlaced"] = nil
        end
    end
end

---------------------------------------------------------------------------------------
-- Set user of the window (for event handlers) and generic callback function
-- (user table, function)
---------------------------------------------------------------------------------------

function Nx.Window:SetUser (user, func)

    self.User = user
    self.UserFunc = func
end

---------------------------------------------------------------------------------------
-- Register for hide notify
---------------------------------------------------------------------------------------

function Nx.Window:RegisterHide()

    local function func (self)
        self.NxWin:Notify ("Hide")
    end

    self.Frm:SetScript ("OnHide", func)
end

---------------------------------------------------------------------------------------
-- Notfiy user of the window
-- (name)
---------------------------------------------------------------------------------------

function Nx.Window:Notify (name, ...)

    if self.UserFunc then
        self.UserFunc (self.User, name, ...)
    end
end

---------------------------------------------------------------------------------------
-- Toggle window size
---------------------------------------------------------------------------------------

function Nx.Window:ToggleSize()

    if self.Sizeable then

        if self.LayoutMode ~= "Max" then

            self.LayoutModeNormal = self.LayoutMode
            self:SetLayoutMode ("Max")
            self:Notify ("SizeMax")

        else
            self:SetLayoutMode (self.LayoutModeNormal)
            self:Notify ("SizeNorm")
        end
    end
end

function Nx.Window:OnMinBut (but, id, click)
    self:SetMinimize (but:GetPressed())
    -- SetLayoutMode no-ops in combat with Map.Compatibility on; re-sync the
    -- button to the layout that actually applied, or the stuck press corrupts
    -- the next minimize/restore cycle (issue #536).
    local isMin = self.LayoutMode == "Min"
    if but:GetPressed() ~= isMin then
        but:SetPressed (isMin)
    end
    self.SaveData["Minimized"] = isMin
end

function Nx.Window:ToggleMinimize()
    self:SetMinimize (not self.ButMiner:GetPressed())
end

---------------------------------------------------------------------------------------
-- Toggle window minimize
---------------------------------------------------------------------------------------

function Nx.Window:SetMinimize (minOn)

    if self.ButMiner then

        if minOn then

            -- Never capture "Min" as the mode to restore to: a re-minimize
            -- while already minimized (combat-desynced button, double event)
            -- would otherwise pin every future restore at the hardcoded min
            -- position (issue #536).
            if self.LayoutMode ~= "Min" then
                self.LayoutModeNormal = self.LayoutMode
            end
            self:SetLayoutMode ("Min")
            self:Notify ("SizeMin")

        else
            local mode = self.LayoutModeNormal
            if mode == "Min" then
                mode = ""
            end
            self:SetLayoutMode (mode)
            self:Notify ("SizeNorm")
        end
    end
end

function Nx.Window:IsSizeMax()
    return self.Sizeable and self.LayoutMode == "Max"
end

function Nx.Window:IsSizeMin()
    return self.ButMiner and self.ButMiner:GetPressed()
end

---------------------------------------------------------------------------------------
-- Check for moving or sizing
---------------------------------------------------------------------------------------

function Nx.Window:IsMovingOrSizing()
    return self.MovSizing
end

---------------------------------------------------------------------------------------
-- Handle events
-- self is frame
---------------------------------------------------------------------------------------

function Nx.FixWin (frm)
    local win = frm.NxWin
--    Nx.prt ("Win Event %s", win.Name)
    Nx.Window.LoginDone = true
    win.LayoutMode = false
    win:SetLayoutMode(1)
end

function Nx.Window:OnEvent (event, ...)

    -- V4 this
    local win = self.NxWin
--    local win = self

    Nx.prt ("Win Event %s %s", win.Name, event)

    if win.Events and win.Events[event] then
        securecall(win.Events[event], win.User, event, ...)
    end
end

function Nx.Window:OnMouseDown (button)

--    Nx.prt ("WinMouseDown "..tostring (button))
--    Nx.prtFrame ("Win", this)

    local this = self            -- V4
    local win = this.NxWin

    local x, y = GetCursorPosition()
    x = x / this:GetEffectiveScale()
    y = y / this:GetEffectiveScale()

    ResetCursor()

    if win.Secure and InCombatLockdown() then
        return
    end

    if button == "LeftButton" then

--        Nx.prt (" MouseDown "..x.." "..y.." "..rgt.." "..bot)

        local side = win:IsOnWinUI (x, y)

        if win.Sizeable then
            if side > 0 then
                this:StartSizing (win.SideNames[side])
                win.MovSizing = true
            end
        end

        if not win.MovSizing and side == 0 then
            this:StartMoving()
            win.MovSizing = true
        end

        if win.MovSizing then

            SetCursor ("INSPECT_CURSOR")
            this:SetFrameStrata ("HIGH")
        end

    elseif button == "MiddleButton" then

        win:ToggleSize()

    elseif button == "RightButton" then

        if IsShiftKeyDown() and IsControlKeyDown() then
            win:ResetLayout()
        else
            win:OpenMenu (win.NoButs)
        end

    end
end

---------------------------------------------------------------------------------------
-- Check if xy on window UI elements
-- (x, y)
---------------------------------------------------------------------------------------

function Nx.Window:IsOnWinUI (x, y)

    local f = self.Frm
    local top = f:GetTop()
    local bot = f:GetBottom()

    -- Bits set: 1=Left, 2=Right, 3=Top, 4=Bottom

    if self.Sizeable then

        local left = f:GetLeft()
        local rgt = f:GetRight()
        local bw = self.BorderW
        local bh = self.BorderH

        if x >= rgt - bw then

            if y >= top - bh then
                return 6        -- TOPRIGHT
            elseif y <= bot + bh then
                return 10        -- BOTTOMRIGHT
            end

            return 2            -- RIGHT

        elseif x < left + bw then

            if y >= top - bh then
                return 5        -- TOPLEFT
            elseif y <= bot + bh then
                return 9        -- BOTTOMLEFT
            end

            return 1            -- LEFT

        elseif y <= bot + bh then

            return 8            -- BOTTOM

        elseif y >= top - bh then

            return 4            -- TOP
        end
    else
        if y <= bot + self.BorderH then
            return 0            -- Header
        end
    end

    if y >= top - self.TopH then
        return 0                -- Header
    end

    return -1                    -- None
end

---------------------------------------------------------------------------------------
-- Mouse up message. Enable mouse also calls!
-- self = frame
---------------------------------------------------------------------------------------

function Nx.Window:OnMouseUp (button)

--    prt ("WinMouseUp "..tostring (button))

    local this = self                -- V4
    local win = this.NxWin

    if win.MovSizing then

        this:StopMovingOrSizing()
        win.MovSizing = false

        if win.Secure and InCombatLockdown() then
            win.DeferredMouseUp = true
        else
            win:SetFrmStrata (win.SaveData[win.LayoutMode.."L"])
            this:Raise()
        end

        win:RecordLayoutData()

        -- Windows that do not opt into a shared normal/minimized anchor retain
        -- their existing independently placed minimized layout.
        if win.LayoutMode == "Min" and not win.ShareMinimizePosition then
            win.SaveData["MinUserPlaced"] = true
        end
    end

    ResetCursor()

    win:Adjust()
end

---------------------------------------------------------------------------------------

function Nx.Window:OnMouseWheel (value)

    if not IsShiftKeyDown() then
        return
    end

    if not (IsControlKeyDown() or IsAltKeyDown()) then
        return
    end

    local this = self                -- V4
    local win = this.NxWin
    local f = win.Frm

    value = value > 0 and 1 or -1

    local cx, cy = GetCursorPosition()
    cx = cx / UIParent:GetEffectiveScale()
    cy = GetScreenHeight() - cy / UIParent:GetEffectiveScale()

    local s = f:GetScale()
    local top = GetScreenHeight() - f:GetTop() * s
    local left = f:GetLeft() * s

--    prtFrame ("Win", this)
--    prt ("XY "..left.." "..top)
--    prt ("CXY "..cx.." "..cy)

    news = max (s + value * .025, .5)

    if IsAltKeyDown() then
        news = 1
    end

    local x = ((left - cx) * news / s + cx) / news
    local y = ((top - cy) * news / s + cy) / news

    f:SetScale (news)
    f:ClearAllPoints()
    f:SetPoint ("TOPLEFT", x, -y)

    win:Adjust()
    win:RecordLayoutData()
end

---------------------------------------------------------------------------------------
-- Win update
-- self = frame
---------------------------------------------------------------------------------------

function Nx.Window:OnUpdate (elapsed)

    local this = self                -- V4
    local win = this.NxWin

    local secureOk = not (win.Secure and InCombatLockdown())

    if win.DeferredMouseUp and secureOk then
        win.DeferredMouseUp = nil
        win:SetFrmStrata (win.SaveData[win.LayoutMode.."L"])
        this:Raise()
    end

    if win.MovSizing and secureOk then
        if IsAltKeyDown() then
            Nx.Util_SnapToScreen (this)
        end
    end

    if win.CursorIsSet then
        win.CursorIsSet = false
        ResetCursor()
    end

    local x = not win.FullLock and Nx.Util_IsMouseOver (this)

    if x then
        if GetMouseFoci() == this then

            local x, y = GetCursorPosition()
            x = x / this:GetEffectiveScale()
            y = y / this:GetEffectiveScale()

            local side = win:IsOnWinUI (x, y)

            if side == 0 then
                SetCursor ("ITEM_CURSOR")
                win.CursorIsSet = true

            elseif side > 0 then
                SetCursor ("INTERACT_CURSOR")
                win.CursorIsSet = true
            end
        end
    end

    if (x or win.Sizing) and secureOk then

        win:Adjust()
        win.BackgndFadeTarget = win.BackgndFadeIn
    else

        win.BackgndFadeTarget = win.BackgndFadeOut
    end

    local fade = Nx.Util_StepValue (win.BackgndFade, win.BackgndFadeTarget, elapsed * 2)

    if fade ~= win.BackgndFade then

        if win.UserUpdateFade then
            win.UserUpdateFade (win.User, fade)
        end

        win.BackgndFade = fade

        local a = fade * win.BackgndAlphaDiff + win.BackgndAlphaMin
        if this.texture then
            this.texture:SetVertexColor (1, 1, 1, a)
        else

            local col = Nx.Skin:GetBGCol()
            if not win.Sizeable and win.Border then
                col = Nx.Skin:GetFixedSizeBGCol()
            end

            this:SetBackdropColor (col[1], col[2], col[3], col[4] * a)
        end

        if not win.Locked then
            win:SetBordersFade (fade)
        end

        if win.ButClose then
            win.ButClose.Frm:SetAlpha (fade * .9 + .1)
        end
        if win.ButMaxer then
            win.ButMaxer.Frm:SetAlpha (fade * .9 + .1)
        end
        if win.ButMiner then
            win.ButMiner.Frm:SetAlpha (fade * .9 + .1)
        end

        for n = 1, #win.ChildFrms do

            local child = win.ChildFrms[n]
            local cf = child.Frm

            local inst = cf.NxInst

            if inst and inst.SetFade then
                inst:SetFade (fade)
            else
                if cf.texture then
                    cf.texture:SetVertexColor (1, 1, 1, fade * .7 + .3)
                end
            end
        end
    end
end

function Nx.Window:OnCloseBut (but, id, click)

    if click == "LeftButton" and self.Closer then

        self:Show (false)
        self:RecordLayoutData()
        Nx.TooltipText:Hide()
        self:Notify ("Close")

    else
        if self.Locked then
            self:Lock (false)
        else
            self:OpenMenu()
        end
    end
end

function Nx.Window:OnMaxBut (but, id, click)

    if click == "LeftButton" then
        self:ToggleSize()
    else
        self:OpenMenu()
    end
end

function Nx.Window:OpenMenu (noLock)

--    Nx.prtVar ("LockWinOM", self)

    if not self.MenuDisable then

        local w = Nx.Window

        w.MenuWin = self
        w.MenuIHideInCombat:SetChecked (self.SaveData["HideC"])
        w.MenuILock:SetChecked (self.Locked)
        w.MenuILock:Show (not noLock)
        w.MenuIFadeIn:SetSlider (self.BackgndFadeIn, .25, 1)
        w.MenuIFadeOut:SetSlider (self.BackgndFadeOut, 0, 1)

        local svdata = self.SaveData

        w.MenuILayer:SetSlider (svdata[self.LayoutMode.."L"] or 2, 1, 3, 1)

        w.MenuIScale:SetSlider (svdata[self.LayoutMode.."S"] or 1, .5, 2)

        w.MenuITrans:SetSlider (svdata[self.LayoutMode.."T"] or 1, .01, 1)

        local m = Nx.Window.Menu
        m:Open()
    end
end

---------------------------------------------------------------------------------------
-- Button - A frame that acts like a button
---------------------------------------------------------------------------------------

Nx.Button.TypeData = {
    ["AAItem"] = {
        Up = "$INV_Misc_QuestionMark",
        Dn = "$INV_Misc_QuestionMark",
        SizeUp = 16,
        SizeDn = 16,
    },
    ["Chk"] = {
        Skin = true,
        Bool = true,
        Up = "But",
        Dn = "ButChk",
    },
    ["Close"] = {
        Skin = true,
        Up = "ButClose",
        Dn = "ButClose",
        Tip = L["Close/Menu"]
    },
    ["CloseLock"] = {
        Skin = true,
        Up = "ButLock",
        Dn = "ButLock",
        Tip = L["Close/Unlock"]
    },
    ["Color"] = {
        Tip = L["Pick Color"],
        SizeUp = 22,            -- Temp. Make opts version?
        SizeDn = 22,
    },
    ["Lock"] = {
        Skin = true,
        Up = "ButLock",
        Dn = "ButLock",
        Tip = L["Unlock"]
    },
    ["Guide"] = {
        Bool = true,
        Up = "$INV_Misc_QuestionMark",
        Dn = "$INV_Misc_QuestionMark",
        SizeUp = 24,
        SizeDn = 28,
        AlphaUp = .7,
        AlphaDn = 1,
    },
    ["Max"] = {
        Tip = L["Maximize"],
        Skin = true,
        Up = "ButMax",
        Dn = "ButMax",
        VRGBAUp = "1|1|1|1",
    },
    ["MaxOn"] = {
        Tip = L["Restore"],
        Skin = true,
        Up = "ButMax",
        Dn = "ButMax",
        VRGBAUp = ".5|.5|1|1",
    },
    ["Min"] = {
        Tip = L["Minimize"],
        Bool = true,
        Skin = true,
        Up = "ButWatchShow",
        Dn = "ButWatchMini",
        VRGBAUp = "1|1|1|.5",
        VRGBADn = ".62|.62|1|1",
    },
    ["MapAutoScale"] = {
        Tip = L["Auto Scale"],
        Bool = true,
        Skin = true,
        Up = "But",
        Dn = "ButChk",
    },
    ["MapCombat"] = {
        Up = "$Ability_DualWield",
        SizeUp = 22,
        SizeDn = 22,
    },
    ["MapEvents"] = {
        Up = "$INV_Misc_Note_03",
        SizeUp = 22,
        SizeDn = 22,
    },
    ["MapGuide"] = {
        Up = "$INV_Misc_QuestionMark",
        SizeUp = 22,
        SizeDn = 22,
    },
    ["MapQGivers"] = {
        Up = "$INV_Misc_Note_02",
        SizeUp = 22,
        SizeDn = 22,
    },
    ["MapZIn"] = {
        Up = "$Spell_ChargePositive",
        SizeUp = 22,
        SizeDn = 22,
    },
    ["MapZOut"] = {
        Up = "$Spell_ChargeNegative",
        SizeUp = 22,
        SizeDn = 22,
    },
    ["Opts"] = {
        Skin = true,
        Bool = true,
        Up = "But",
        Dn = "ButChk",
        SizeUp = 22,
        SizeDn = 22,
    },
    ["Scroll"] = {
        Scroll = true,
        Up = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\ScrollUp",
        Dn = "Interface\\Addons\\Carbonite\\Gfx\\Buttons\\ScrollUp",
        SizeUp = 14,
        SizeDn = 12,
    },
    ["Tab"] = {
        Bool = true,
        Skin = true,
        Up = "TabOff",
        Dn = "TabOn",
    },
    ["Toggle"] = {
        Bool = true,
        Skin = true,
        Up = "But",
        Dn = "ButChk",
        SizeUp = 14,
        SizeDn = 14,
    },
    ["Txt"] = {
        RGBUp = "604040",
        RGBDn = "503030",
    },
    ["Txt64"] = {
        Skin = true,
        Up = "ButEmpty64",
        Dn = "ButEmpty64",
        RGBUp = "604040",
        RGBDn = "503030",
    },
    ["Txt64B"] = {
        Bool = true,
        Skin = true,
        Up = "ButEmpty64",
        Dn = "ButEmpty64",
        VRGBAUp = "1|1|1|1",
        VRGBADn = "1|.373|.373|1",
    },
}

---------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
-- BUTTON SYSTEM
-- Creates and manages interactive button controls
-------------------------------------------------------------------------------

---
-- Initialize button system with type definitions
--
function Nx.Button:Init()

    local f = CreateFrame ("Frame", nil, UIParent, "BackdropTemplate")
    self.OverFrm = f

    f:SetFrameStrata ("MEDIUM")
    f:Hide()

    local t = f:CreateTexture()
    t:SetColorTexture (Nx.Util_str2rgba ("0.06|0.06|0.250|1"))
    t:SetAllPoints (f)
    t:SetBlendMode ("ADD")
    f.texture = t
end

---------------------------------------------------------------------------------------
-- Create a Button
-- ()
-- ret: button table
---------------------------------------------------------------------------------------

function Nx.Button:Create (parentFrm, typ, text, tip, bx, by, side, width, height, func, user, template)

    parentFrm = parentFrm or UIParent

    local but = {}        -- New

    setmetatable (but, self)
    self.__index = self

    but:SetUser (user, func)

    but.Type = self.TypeData[typ]

    assert (not typ or but.Type)

    -- Create frame

    local fType = template and "Button" or "Frame"
    local fname = text and ("NxBut" .. text)

    local f = CreateFrame (fType, fname, parentFrm, template)
    but.Frm = f
    f.NxBut = but

    but.Tip = tip
    f.NxTip = tip or (typ and self.TypeData[typ].Tip)

    side = side or "TOPLEFT"
    f:SetPoint (side, bx, by)

    f:SetWidth (width)
    f:SetHeight (height)

--    f:SetFrameStrata ("MEDIUM")

    f:SetScript ("OnMouseDown", self.OnMouseDown)
    f:SetScript ("OnMouseUp", self.OnMouseUp)
    f:SetScript ("OnEnter", self.OnEnter)
    f:SetScript ("OnLeave", self.OnLeave)
    f:EnableMouse (true)

    f:SetScript ("OnUpdate", self.OnUpdate)

    local t = f:CreateTexture()
    f.texture = t
    t:SetAllPoints (f)

    f:Show()

    -- Create text

    if text then

        local fstr = f:CreateFontString()
        but.FStr = fstr
        fstr:SetFontObject ("NxFontS")
        fstr:SetJustifyH ("CENTER")
        fstr:SetHeight (height)
        but:SetText (text, 0, 0)
        fstr:Show()
    end

    ---------------------------------------------------------------------------------------

    but:Update()

    ---------------------------------------------------------------------------------------

    if template then    -- Social frame template?

--        Nx.prt ("But %s", template)
--        Nx.prtFrame ("But", f)

        local reg = { f:GetRegions() }
        for n, o in ipairs (reg) do
            if o:IsObjectType ("Texture") and o ~= f.texture then
                o:Hide()        -- Hide
            end
        end
    end


    return but
end

---------------------------------------------------------------------------------------
-- Set handler to notify user
---------------------------------------------------------------------------------------

function Nx.Button:SetUser (user, func)

    self.User = user
    self.UserFunc = func
end

---------------------------------------------------------------------------------------
-- Get type
---------------------------------------------------------------------------------------

function Nx.Button:GetType()
    return self.Type
end

---------------------------------------------------------------------------------------
-- Set type
-- (Type string or nil)
---------------------------------------------------------------------------------------

function Nx.Button:SetType (typ)

    self.Frm.NxTip = self.Tip or (typ and self.TypeData[typ].Tip)
    self.Type = self.TypeData[typ]
end

---------------------------------------------------------------------------------------
-- Set Id
---------------------------------------------------------------------------------------

function Nx.Button:SetId (id)
    self.Id = id
end

---------------------------------------------------------------------------------------
-- Get pressed state
---------------------------------------------------------------------------------------

function Nx.Button:GetPressed()

    return self.Pressed
end

---------------------------------------------------------------------------------------
-- Set pressed state
---------------------------------------------------------------------------------------

function Nx.Button:SetPressed (down)

    self.Pressed = down
    self:Update()
end

---------------------------------------------------------------------------------------
-- Get state
---------------------------------------------------------------------------------------

function Nx.Button:GetState()

    return self.State
end

---------------------------------------------------------------------------------------
-- Set state
---------------------------------------------------------------------------------------

function Nx.Button:SetState (state)

    self.State = state
    self:Update()
end

---------------------------------------------------------------------------------------
-- Set button text and text position
---------------------------------------------------------------------------------------

function Nx.Button:SetText (text, x, y)

    local fstr = self.FStr

    if strbyte (text) ~= 124 then        -- |
        text = "|cffffbfaf" .. text
    end

    fstr:SetText (text)

    if x then
        fstr:SetPoint ("CENTER", x, y + 1)
    end
end

---------------------------------------------------------------------------------------
-- Set button texture
---------------------------------------------------------------------------------------

function Nx.Button:SetAlpha (a)
    self.Frm:SetAlpha (a)
end

---------------------------------------------------------------------------------------
-- Set button texture
---------------------------------------------------------------------------------------

function Nx.Button:SetTexture (tex)

    self.Tx = tex
end

---------------------------------------------------------------------------------------
-- Set button position
---------------------------------------------------------------------------------------

function Nx.Button:SetPos (side, x, y)

    self.Frm:SetPoint (side, x, y)
end

---------------------------------------------------------------------------------------
-- Set button size
---------------------------------------------------------------------------------------

function Nx.Button:SetSize (w, h)

    self.Frm:SetWidth (w)
    self.Frm:SetHeight (h)
end

---------------------------------------------------------------------------------------

function Nx.Button:OnMouseDown (button)

--    prt ("ButMouseDown "..tostring (button))

    local this = self                -- V4
    local but = this.NxBut

    if button == "LeftButton" or button == "MiddleButton" then

        if but.Type.Bool then

            but.Pressed = not but.Pressed

--            if IsShiftKeyDown() then    -- Force on. Keep?
--                but.Pressed = true
--            end

            if but.UserFunc then
                but.UserFunc (but.User, but, but.Id, button)
            end

        elseif but.Type.States then

            but.State = but.State % but.Type.States + 1

            if but.UserFunc then
                but.UserFunc (but.User, but, but.Id, button)
            end

        else
            but.Pressed = true
            but.MouseDownButton = button

        end
    end

    if but.Type.Scroll then

        local x, y = GetCursorPosition()
        but.ScrollingX = x / this:GetEffectiveScale()
        but.ScrollingY = y / this:GetEffectiveScale()
        but.Scrolling = true

        return

    elseif button == "RightButton" then

        if but.UserFunc then
            but.UserFunc (but.User, but, but.Id, button)
        end
    end

    but:Update()
end

---------------------------------------------------------------------------------------

function Nx.Button:OnMouseUp (button)

--    Nx.prt ("ButMouseUp "..tostring (button))

    local this = self            -- V4
    local but = this.NxBut

    if button == "LeftButton" then

        if not (but.Type.Bool or but.Type.States or but.Type.Scroll) then

            local wasPressed = but.Pressed and but.MouseDownButton == button
            but.Pressed = false
            but.MouseDownButton = nil

            -- Moving or resizing a window can place its close button beneath
            -- the cursor before release. A release without a matching press
            -- must never activate that button and close the entire window.
            if wasPressed and Nx.Util_IsMouseOver (but.Frm) then

                if but.UserFunc then
                    but.UserFunc (but.User, but, but.Id, button)
                end
            end

        elseif but.Type.Scroll then

            but.Pressed = false
        end
    end

    but.Scrolling = false

    but:Update()
end

---------------------------------------------------------------------------------------
-- Handle mouse on button
---------------------------------------------------------------------------------------

function Nx.Button:OnEnter (motion)

    local this = self            -- V4
    local but = this.NxBut

    but.Over = true
    but:Update()

--    Nx.prt ("Enter %s", this.NxTip or "nil")

    local owner = this.NXTipFrm or this

    if Nx.TooltipText:IsOwned (owner) then
        return
    end

    local tip = this.NxTip

    if tip then

        Nx.TooltipOwner = owner

        if this.NXTipFrm then
            Nx.TooltipText:SetOwner (owner, "ANCHOR_TOPLEFT", 0, 0)
        else
            Nx.TooltipText:SetOwner (owner, "ANCHOR_LEFT", 0, 5)
        end

        Nx:SetTooltipText (tip)
    end
end

---------------------------------------------------------------------------------------
-- Handle mouse leaving icon
---------------------------------------------------------------------------------------

function Nx.Button:OnLeave (motion)

    local this = self            -- V4
    local but = this.NxBut

    but.Over = nil
    but:Update()

    if not this:IsVisible() then
        return
    end

    local owner = this.NXTipFrm or this

    if Nx.TooltipText:IsOwned (owner) then
        Nx.TooltipText:Hide()
    end
end

---------------------------------------------------------------------------------------

function Nx.Button:OnUpdate (elapsed)

    local this = self            -- V4
    local but = this.NxBut

    if but.Scrolling then

        local cx, cy = GetCursorPosition()
        cx = cx / this:GetEffectiveScale()
        cy = cy / this:GetEffectiveScale()

        local x = cx - but.ScrollingX
        local y = but.ScrollingY - cy

        if x ~= 0 or y ~= 0 then

            but.ScrollingX = cx
            but.ScrollingY = cy

            if IsShiftKeyDown() then
                x = x * .1
                y = y * .1
            end

            if but.UserFunc then
                but.UserFunc (but.User, but, but.Id, "scroll", x, y)
            end
        end
    end

end

---------------------------------------------------------------------------------------

function Nx.Button:Update()

--    Nx.prt ("But Update: %s", debugstack (2, 3, 0))

    local typ = self.Type
    if not typ then
        return
    end

    local Skin = Nx.Skin

    local f = self.Frm
    local tx = f.texture

    if self.State then

        local stateT = typ[self.State] or typ[1]

        local txName = self.Tx or stateT.Tx or typ.Tx

        if typ.Skin then
            txName = Skin:GetTex (txName)
        else
            if txName then
                if type (txName) == "string" then
                    txName = gsub (txName, "%$", "Interface\\Icons\\")
                else
                    if (strmatch(txName,"|")) then
                        tx:SetColorTexture (Nx.Util_str2rgba (txName))
                    else
                        tx:SetTexture (txName)
                    end
                    txName = nil
                end
            end
        end

        if txName then
            tx:SetTexture (txName)
        else
            local rgb = stateT.RGB
            if rgb then
                tx:SetColorTexture (Nx.Util_str2rgb (rgb))
            end
        end

        if stateT.Alpha then
            tx:SetVertexColor (1, 1, 1, stateT.Alpha)
        elseif stateT.VRGBA then
            tx:SetVertexColor (Nx.Util_str2rgba (stateT.VRGBA))
        end

        local sz = stateT.Size
        if sz then
            f:SetWidth (sz)
            f:SetHeight (sz)
        end

    else

        if self.Pressed then

            local txName = self.Tx or typ.Dn

            if typ.Skin then
                txName = Skin:GetTex (txName)
            else
                if txName then
                    if type (txName) == "string" then
                        txName = gsub (txName, "%$", "Interface\\Icons\\")
                    else
                        if (strmatch(txName,"|")) then
                            tx:SetColorTexture (Nx.Util_str2rgba (txName))
                        else
                            tx:SetTexture (txName)
                        end
                        txName = nil
                    end
                end
            end

            if txName then
                tx:SetTexture (txName)
            else
                local rgb = typ.RGBDn
                if rgb then
                    tx:SetColorTexture (Nx.Util_str2rgb (rgb))
                end
            end

            if typ.AlphaDn then
                tx:SetVertexColor (1, 1, 1, typ.AlphaDn)
            elseif typ.VRGBADn then
                tx:SetVertexColor (Nx.Util_str2rgba (typ.VRGBADn))
            end

            local sz = typ.SizeDn
            if sz then
                f:SetWidth (sz)
                f:SetHeight (sz)
            end

        else

            local txName = self.Tx or typ.Up

            if typ.Skin then
                txName = Skin:GetTex (txName)
            else
                if txName then
                    if type (txName) == "string" then
                        txName = gsub (txName, "%$", "Interface\\Icons\\")
                    else
                        if (strmatch(txName,"|")) then
                            tx:SetColorTexture (Nx.Util_str2rgba (txName))
                        else
                            tx:SetTexture (txName)
                        end
                        txName = nil
                    end
                end
            end

            if txName then
                tx:SetTexture (txName)
                if typ.UpUV then
                    local uv = typ.UpUV
                    tx:SetTexCoord (uv[1], uv[2], uv[3], uv[4])
                end
            else
                local rgb = typ.RGBUp
                if rgb then
                    tx:SetColorTexture (Nx.Util_str2rgb (rgb))
                end
            end

            if typ.AlphaUp then
                tx:SetVertexColor (1, 1, 1, typ.AlphaUp)
            elseif typ.VRGBAUp then
                tx:SetVertexColor (Nx.Util_str2rgba (typ.VRGBAUp))
            end

            local sz = typ.SizeUp
            if sz then
                f:SetWidth (sz)
                f:SetHeight (sz)
            end
        end
    end

    local of = Nx.Button.OverFrm

    if self.Over then

--        tx:SetBlendMode ("ADD")

--        local al = typ.AlphaOv
--        if al then
--            tx:SetVertexColor (1, 1, 1, al)
--        end

        of:ClearAllPoints()
        if self.IsListRow and self.NxListInst and self.NxListInst.Frm then
            -- Span the OverFrm across the whole list row when this is
            -- a list-row icon button, so hovering the button highlights
            -- the entire row (cleaner than just lighting up a 14x14 icon).
            local listFrm = self.NxListInst.Frm
            local lineH = self.NxListInst.GetLineH and self.NxListInst:GetLineH() or f:GetHeight()
            of:SetPoint("TOPLEFT", listFrm, "LEFT", 0, f:GetTop() and (f:GetTop() - listFrm:GetTop() + lineH * 0.5) or 0)
            of:SetPoint("TOPLEFT", f, "LEFT", -2, lineH * 0.5 - 1)
            of:SetWidth(listFrm:GetWidth() - 4)
            of:SetHeight(lineH)
        else
            of:SetPoint ("TOPLEFT", f, -1, 1)
            of:SetWidth (f:GetWidth() + 2)
            of:SetHeight (f:GetHeight() + 2)
        end

        if self.Pressed then
            of.texture:SetColorTexture (Nx.Util_str2rgba (".188|.188|.5|1"))
        elseif self.IsListRow then
            -- Subtler tint for row-wide highlight so it doesn't shout.
            of.texture:SetColorTexture (Nx.Util_str2rgba ("0.5|0.5|0.7|0.18"))
        else
            of.texture:SetColorTexture (Nx.Util_str2rgba ("0.06|0.06|.250|1"))
        end

--        local lev = f:GetFrameLevel()
--        of:SetFrameLevel (lev + 1)        -- Causing glitch when button pressed
        of:SetParent (f)            -- Seems to make us draw in front

        of:Show()
        Nx.Button.OverFrmOwn = f

    else
--        tx:SetBlendMode ("BLEND")

        if Nx.Button.OverFrmOwn == f then
            of:Hide()
        end
    end

    if typ.Dim then
        SetDesaturation (tx, not self.Pressed)
    end
end

---------------------------------------------------------------------------------------
-- Edit box
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Create a edit box
-- ()
-- ret: edit box table
---------------------------------------------------------------------------------------

function Nx.EditBox:Create (parentFrm, user, func, maxLetters)

    local box = {}                    -- New

    setmetatable (box, self)
    self.__index = self

    box:SetUser (user, func)

    local f = CreateFrame ("EditBox", nil, parentFrm)
    box.Frm = f

    f.NxInst = box

    f:SetScript ("OnEditFocusGained", self.OnEditFocusGained)
    f:SetScript ("OnEditFocusLost", self.OnEditFocusLost)
    f:SetScript ("OnTextChanged", self.OnTextChanged)
    f:SetScript ("OnEnterPressed", self.OnEnterPressed)
    f:SetScript ("OnEscapePressed", self.OnEscapePressed)

    f:SetFontObject ("NxFontS")

    local t = f:CreateTexture()
    t:SetColorTexture (.1, .2, .3, 1)
    t:SetAllPoints (f)
    f.texture = t

    f:SetAutoFocus (false)
    f:ClearFocus()

    box.FilterDesc = L["Search: [click]"]
    box.FilterDescEsc = L["Search: %[click%]"]

--    if Nx.Free then
--        box.FilterDesc = "Search: " .. Nx.FreeMsg
--    end

    box.FilterStr = ""
    f:SetText (box.FilterDesc)
    f:SetMaxLetters (maxLetters)

    return box
end

---------------------------------------------------------------------------------------
-- Set handler to notify user
---------------------------------------------------------------------------------------

function Nx.EditBox:SetUser (user, func)

    self.User = user
    self.UserFunc = func
end

---------------------------------------------------------------------------------------
-- Get text
---------------------------------------------------------------------------------------

function Nx.EditBox:GetText()
    return self.FilterStr
end

---------------------------------------------------------------------------------------

function Nx.EditBox:OnEditFocusGained()

    Nx.ShowMessageTrial()

    local this = self            -- V4
    local self = this.NxInst
    if self.FilterStr ~= "" then
        this:SetText (self.FilterStr)
    else
        this:SetText ("")
    end
end

function Nx.EditBox:OnEditFocusLost()

    local this = self            -- V4
    local self = this.NxInst
    if self.FilterStr == "" then
        this:SetText (self.FilterDesc)
    end
end

function Nx.EditBox:OnTextChanged()

    local this = self            -- V4
    local self = this.NxInst
    self.FilterStr = gsub (this:GetText(), self.FilterDescEsc, "")

--    Nx.prt ("Filter=%s", self.FilterStr)

    if self.UserFunc then
        self.UserFunc (self.User, self, "Changed")
    end
end

function Nx.EditBox:OnEnterPressed()
    self:ClearFocus()
end

function Nx.EditBox:OnEscapePressed()

    local this = self            -- V4
    local self = this.NxInst
    self.FilterStr = ""

    this:ClearFocus()
end

---------------------------------------------------------------------------------------
-- Scroll bar
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Create a Scroll Bar
-- ()
-- ret: table
---------------------------------------------------------------------------------------

--[[

function ScrollBar:Create (parentFrm, typ, bx, by, width, height, func, user)

    local c2rgba = Nx.Util_c2rgba

    parentFrm = parentFrm or UIParent

    local sbar = {}            -- New

    setmetatable (sbar, self)
    self.__index = self

    sbar:SetUser (user, func)

    -- Create frame

    local f = CreateFrame ("Frame", nil, parentFrm)
    sbar.Frm = f
    f.NxSBar = but

    f.NxTip = tip or (typ and Button.TypeData[typ].Tip)

    side = side or "TOPLEFT"
    f:SetPoint (side, bx, by)

    f:SetWidth (width)
    f:SetHeight (height)

    f:SetFrameStrata ("MEDIUM")

    f:SetScript ("OnMouseDown", self.OnMouseDown)
    f:SetScript ("OnMouseUp", self.OnMouseUp)
--    f:SetScript ("OnEnter", self.OnEnter)
--    f:SetScript ("OnLeave", self.OnLeave)
    f:EnableMouse (true)

    f:SetScript ("OnUpdate", self.OnUpdate)

    local t = f:CreateTexture()
    f.texture = t
    t:SetAllPoints (f)

    if typ and Button.TypeData[typ] then

        but.Type = Button.TypeData[typ]

        t:SetTexture (but.Type.Up)
    else
        t:SetTexture (c2rgba ("202020c8"))
    end

    f:Show()

    --

--    Button:Create (f, "Close", nil, nil, -Window.BORDERW, -Window.BORDERH + 4, "TOPRIGHT", 20, 20, win.OnCloseButDown, win)

    --

    return sbar
end

---------------------------------------------------------------------------------------

function ScrollBar:OnMouseDown (button)

--    prt ("ButMouseDown "..tostring (button))

    local sb = this.NxSBar


        local x, y = GetCursorPosition()
        sb.ScrollingX = x / this:GetEffectiveScale()
        sb.ScrollingY = y / this:GetEffectiveScale()
        sb.Scrolling = true



    sb:Update()
end

---------------------------------------------------------------------------------------

function ScrollBar:OnMouseUp (button)

--    prt ("ButMouseUp "..tostring (button))

    local sb = this.NxSBar

    sb.Scrolling = false

    sb:Update()
end

---------------------------------------------------------------------------------------

function ScrollBar:Update()

    if self.Scrolling then

        if self.Func then
            self.Func (self.User, self)
        end

    end
end
--]]

-------------------------------------------------------------------------------
-- MENU SYSTEM
-- Creates context menus and popup menus
-------------------------------------------------------------------------------

---
-- Initialize menu system
--
function Nx.Menu:Init()

    self.Menus = {}        -- All created menus

    self.Item_ALPHAFADE = 0
    self.NameNum = 0

    self.__index = self
    Nx.MenuI.__index = Nx.MenuI
end

---------------------------------------------------------------------------------------
-- Check if any menus are opened
---------------------------------------------------------------------------------------

function Nx.Menu:IsAnyOpened()

    -- Only one can be current

    return self.Cur and self.Cur.MainFrm:IsVisible()    -- Esc may have hidden

--[[
    if self.Menus then
        for menu in pairs (self.Menus) do
--            Nx.prt ("%s", menu.MainFrm:GetName())
--            if menu.MainFrm:IsVisible() and not menu.Closing then
            if menu.MainFrm:IsVisible() then
                return true
            end
        end
    end
--]]
end

---------------------------------------------------------------------------------------
-- Create a menu
---------------------------------------------------------------------------------------

function Nx.Menu:Create (parentFrm, width)

    local c2rgba = Nx.Util_str2rgba

    local menu = {}        -- New menu

    self.Menus[menu] = true

    setmetatable (menu, self)

    menu.Items = {}
    menu.Alpha = 1
    menu.CloseTimer = 0    -- In seconds
    menu.Width = width or 210

    self.NameNum = self.NameNum + 1
    local name = format ("NxMenu%d", self.NameNum)

    local f = CreateFrame ("Frame", name, UIParent, "BackdropTemplate")
    menu.MainFrm = f

    tinsert (HideFramesOnEsc, name)

    f.NxMenu = menu

    f:Hide()

--    f:SetToplevel (1)
    f:SetScript ("OnUpdate", self.OnUpdate)
--    f:SetScript ("OnLeave", self.OnLeave)
    f:EnableMouse (true)
--[[
    local t = f:CreateTexture()
    t:SetTexture (c2rgba ("202020e0"))
    t:SetAllPoints (f)
    f.texture = t
--]]

    menu:SetSkin()

    return menu
end

hooksecurefunc("ToggleGameMenu", function()
    for k, v in pairs (HideFramesOnEsc) do
        _G[v]:Hide()
    end
end)

function Nx.Menu:ResetSkins()

    if self.Menus then
        for menu, v in pairs (self.Menus) do
            menu:SetSkin()
        end
    end
end

function Nx.Menu:SetSkin()

    local f = self.MainFrm

    local bk = Nx.Skin:GetBackdrop()
    f:SetBackdrop (bk)

    local col = Nx.Skin:GetBGCol()
    f:SetBackdropColor (col[1], col[2], col[3], tonumber(col[4]))

    local col = Nx.Skin:GetBorderCol()
    f:SetBackdropBorderColor (col[1], col[2], col[3], tonumber(col[4]))
end

function Nx.Menu:OnUpdate (elapsed)

    local this = self            -- V4
    local self = this.NxMenu

--    Nx.prt ("elapsed %f %f", elapsed, self.CloseTimer)

    self.Alpha = Nx.Util_StepValue (self.Alpha, self.AlphaTarget, elapsed * 4)
    this:SetAlpha (self.Alpha)

    if self.Closing then

        if self.Alpha <= 0 then
            self.Closing = nil
            this:Hide()
        end
        return
    end

    local x, y = GetCursorPosition()
    x = x / this:GetEffectiveScale()
    y = y / this:GetEffectiveScale()

    if x < this:GetLeft() - 1 or x > this:GetRight()
            or y < this:GetBottom() or y > this:GetTop() + 1 then

--        prt ("MenuC "..x.." "..y)
--        prtFrame ("Menu", this)

        if not Nx.Menu.SliderMoving then

            self.CloseTimer = self.CloseTimer - elapsed
            if self.CloseTimer <= 0 then
                self:Close()
            end
        end

    else
        self.CloseTimer = .5
    end
end

---------------------------------------------------------------------------------------
-- Add sub menu
---------------------------------------------------------------------------------------

function Nx.Menu:AddSubMenu (menu, text)

    local item = {}
    self.Items[#self.Items + 1] = item

    setmetatable (item, Nx.MenuI)

    item.Menu = self
    item.SubMenu = menu
    item.Text = text
    item.ShowState = 1

    return item
end

---------------------------------------------------------------------------------------
-- Add menu item
---------------------------------------------------------------------------------------

function Nx.Menu:AddItem (id, text, func, user)

    local item = {}
    self.Items[#self.Items + 1] = item

    setmetatable (item, Nx.MenuI)

    item.Menu = self
--    item.Type = "Text"
    item.Id = id
    item.Text = text
    item.Func = func
    item.User = user
    item.ShowState = 1

--    item.GetChecked = self.Item_GetChecked
--    item.SetChecked = self.Item_SetChecked
--    item.GetSlider = self.Item_GetSlider
--    item.SetSlider = self.Item_SetSlider

    if text == "" then
        item.Spacer = true
    end

    return item
end

function Nx.MenuI:SetText (text)
    self.Text = text
end

function Nx.MenuI:GetChecked()
    return self.Checked
end

function Nx.MenuI:SetChecked (checked, varName)

    self.Check = true

    if type (checked) == "table" then
        assert (varName)
        self.Table = checked
        self.VarName = varName
        checked = self.Table[varName]
    end

    self.Checked = checked

    if self.Table then
        self.Table[self.VarName] = checked
    end
end

---------------------------------------------------------------------------------------
-- Get slider position
---------------------------------------------------------------------------------------

function Nx.MenuI:GetSlider()
    return self.SliderPos
end

---------------------------------------------------------------------------------------
-- Set slider position and optionally min and max values
---------------------------------------------------------------------------------------

function Nx.MenuI:SetSlider (pos, min, max, step, varName)
    if type (pos) == "table" then
        assert (varName)
        self.Table = pos
        self.VarName = varName
        pos = self.Table[varName]
    end

    self.Slider = true

    if min then
        self.SliderMin = math.min (min, max)
        self.SliderMax = math.max (min, max)
    end

    if step then
        self.Step = step
    end

    -- Floor to step pos
    if self.Step then
        pos = floor (pos / self.Step + .5) * self.Step
    end

    -- Clamp pos
    pos = math.max (pos, self.SliderMin)
    pos = math.min (pos, self.SliderMax)

    self.SliderPos = pos

    if self.Table then
        self.Table[self.VarName] = pos
    end
end

---------------------------------------------------------------------------------------
-- Set menu item show state
-- (false hides. -1 shows as disabled)
---------------------------------------------------------------------------------------

function Nx.MenuI:Show (show)

--    Nx.prt ("show %s %s", self.Text, show and 1 or 0)

    self.ShowState = false
    if show ~= false then
        self.ShowState = (type (show) == "number") and show or 1
    end
--    Nx.prtVar ("show", self.ShowState)
end

---------------------------------------------------------------------------------------
-- Not used?
---------------------------------------------------------------------------------------

--[[
function Nx.Menu:Item_GetUser (item)
    return item.User
end

function Nx.Menu:Item_SetUser (item, user)
    item.User = user
end
--]]

---------------------------------------------------------------------------------------
-- Open a menu
-- self = menu instance
---------------------------------------------------------------------------------------

-- Returns true if this menu only contains plain text actions and
-- spacers — no sliders, checkboxes, color pickers, or sub-menus.
-- Those are the kinds we can safely render via Blizzard's modern
-- MenuUtil; complex menus fall back to the legacy renderer.
function Nx.Menu:IsSimpleMenu()
    for n = 1, #self.Items do
        local item = self.Items[n]
        if item.Slider or item.Checked or item.ColorTbl
           or item.Sub or item.SubMenu or item.GetState then
            return false
        end
    end
    return true
end

function Nx.Menu:OpenViaMenuUtil()
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        return false
    end
    if not self:IsSimpleMenu() then
        return false
    end

    local items = self.Items
    MenuUtil.CreateContextMenu(UIParent, function(owner, root)
        for n = 1, #items do
            local item = items[n]
            if item.ShowState ~= 0 then
                if item.Spacer or (item.Text or "") == "" then
                    if root.CreateDivider then root:CreateDivider() end
                else
                    root:CreateButton(item.Text or "", function()
                        if item.Func then
                            item.Func(item.User or self, item)
                        end
                    end)
                end
            end
        end
    end)
    return true
end

function Nx.Menu:Open()

    -- Route simple menus through Blizzard's modern MenuUtil for the
    -- native dropdown look. Complex menus (sliders, checkboxes, colour
    -- pickers, sub-menus) keep the legacy renderer because MenuUtil's
    -- API doesn't map cleanly to those widgets.
    local useMenuUtil = Nx.qdb and Nx.qdb.profile and Nx.qdb.profile.Menu
        and Nx.qdb.profile.Menu.UseMenuUtil
    if useMenuUtil and self:OpenViaMenuUtil() then
        return
    end

    if Nx.Menu.Cur then        -- Force current menu to close
        Nx.Menu.Cur:Close()
    end

    Nx.Menu.Cur = self

    local mf = self.MainFrm

    self.Closing = nil
    self.CloseTimer = 60 * 1
    self.Alpha = 0
    self.AlphaTarget = 1

    local menuW = self.Width
    local menuH = self:Update() + 14

    mf:SetFrameStrata ("DIALOG")
    mf:SetClampedToScreen (true)
    mf:SetWidth (menuW)
    mf:SetHeight (menuH)

    local cx, cy = GetCursorPosition()
    cx = cx / UIParent:GetEffectiveScale()
    cy = cy / UIParent:GetEffectiveScale()

--    prt (format ("Menu Open (%f, %f)", cx, cy))

    local x = cx - 4
    local y = cy + 4
    if Nx.db.profile.Menu.CenterH then
        x = cx - menuW * .5
    end
    if Nx.db.profile.Menu.CenterV then
        y = cy + menuH * .5
    end

    mf:SetPoint ("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    mf:Show()

    mf:Raise()
end

function Nx.Menu:Update()

    local mf = self.MainFrm

    local menuX = 14
    local menuY = 14
    local menuW = self.Width

    for n = 1, #self.Items do

        local item = self.Items[n]

        local itemF = item.Frm

--        Nx.prt ("Open %s", item.Text)

        if not item.ShowState then

--            Nx.prt ("Hide %s", item.Text)

            if itemF then
                itemF:Hide()
            end
        else

            local itemH = 12        -- Not counting space between items

            if not item.Spacer then

                item.Alpha = 0
                item.AlphaTarget = self.Item_ALPHAFADE

                if not itemF then
                    item.Frm = CreateFrame ("Frame", nil, mf, "BackdropTemplate")
                    itemF = item.Frm
                    itemF.NxMenuItem = item

--                    itemF:SetFrameStrata ("DIALOG")
                    itemF:SetWidth (menuW - menuX * 2)

                    itemF:SetScript ("OnEnter", self.Item_OnEnter)
                    itemF:SetScript ("OnLeave", self.Item_OnLeave)
                    itemF:SetScript ("OnUpdate", self.Item_OnUpdate)
                    itemF:SetScript ("OnMouseDown", self.Item_OnMouseDown)
                    itemF:SetScript ("OnMouseUp", self.Item_OnMouseUp)

                    local t = itemF:CreateTexture()
                    t:SetColorTexture (1, 1, 1, 1)
                    t:SetAllPoints (itemF)
                    itemF.texture = t
                end

--                if item.SubMenu then
--                    item.SubMenu:Close()
--                end

                if item.Text then

                    local fstr = item.TextFStr

                    if not fstr then

                        fstr = itemF:CreateFontString()
                        item.TextFStr = fstr
                        fstr:SetFontObject ("NxFontMenu")
                        fstr:SetPoint ("TOPLEFT", 20, 0)
                        fstr:SetWidth (menuW - 20)
                        fstr:SetHeight (12)
                        fstr:SetJustifyH ("LEFT")
                    end

                    if item.ShowState < 0 then
                        fstr:SetText ("|cff707070" .. item.Text)
                    else
                        fstr:SetText ("|cfff7f7f7" .. item.Text)
                    end

                    fstr:Show()
                end

                if item.Check then

                    local frm = item.CheckFrm

                    if not frm then
                        frm = CreateFrame ("Frame", nil, itemF, "BackdropTemplate")
                        item.CheckFrm = frm

                        frm:SetWidth (12)
                        frm:SetHeight (12)

                        frm.texture = frm:CreateTexture()
                        frm.texture:SetAllPoints (frm)
                    end

                    frm:SetPoint ("TOPLEFT", 1, 0)
                    frm:Show()

                    self:CheckUpdate (item)
                end

                if item.Slider then

                    itemF:SetScript ("OnMouseWheel", self.Item_OnMouseWheel)
                    itemF:EnableMouseWheel (true)

                    local h = 10

                    local frm = item.SliderFrm

                    if not frm then
                        frm = CreateFrame ("Frame", nil, itemF, "BackdropTemplate")
                        item.SliderFrm = frm

                        frm:SetWidth (102)
                        frm:SetHeight (h)

                        frm.texture = frm:CreateTexture()
                        frm.texture:SetAllPoints (frm)
                        frm.texture:SetColorTexture (0, 0, 0, .5)
                    end

                    local tfrm = item.SliderThumbFrm

                    if not tfrm then
                        tfrm = CreateFrame ("Frame", nil, frm, "BackdropTemplate")
                        item.SliderThumbFrm = tfrm

--                        tfrm:SetFrameStrata ("DIALOG")
                        tfrm:SetWidth (3)
                        tfrm:SetHeight (h)

                        tfrm.texture = tfrm:CreateTexture()
                        tfrm.texture:SetAllPoints (tfrm)
                        tfrm.texture:SetColorTexture (.5, 1, .5, 1)
                    end

                    frm:SetPoint ("TOPLEFT", 12, -itemH - 1)
                    frm:Show()

                    self:SliderUpdate (item)

                    itemH = itemH + h + 2
                end

                itemF:SetPoint ("TOPLEFT", menuX, -menuY)
                itemF:SetHeight (itemH)
                itemF:Show()
                itemF:EnableMouse (true)
            end

            menuY = menuY + itemH + 1
        end
    end

    return menuY
end

---------------------------------------------------------------------------------------

function Nx.Menu:Close()

    self.Closing = true
    self.AlphaTarget = 0

    if Nx.Menu.Cur == self then
        Nx.Menu.Cur = false
    end
end

---------------------------------------------------------------------------------------
-- Set all menu items show state
-- (false hides. -1 shows as disabled)
---------------------------------------------------------------------------------------

function Nx.Menu:Show (show)

    for _, item in ipairs (self.Items) do
        item:Show (show)
    end
end

---------------------------------------------------------------------------------------
-- Update all items check mark

--function Nx.Menu:CheckUpdateAll()
--    for _, item in ipairs (self.Items) do
--        self:CheckUpdate (item)
--    end
--end
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Update check mark
-- self = invalid
---------------------------------------------------------------------------------------

function Nx.Menu:CheckUpdate (item)

    local f = item.CheckFrm
    if f then
        local t = f.texture
        local txName

        if item.Table then
            item.Checked = item.Table[item.VarName]
        end

        if item.Checked then
            txName = Nx.Skin:GetTex ("ButChk")
        else
            txName = Nx.Skin:GetTex ("But")
        end

        t:SetTexture (txName)
    end
end

---------------------------------------------------------------------------------------
-- Update slider
-- self = invalid
---------------------------------------------------------------------------------------

function Nx.Menu:SliderUpdate (item)

    if item.Table then
        item.SliderPos = item.Table[item.VarName]
    end

    local tfrm = item.SliderThumbFrm
    local per = (item.SliderPos - item.SliderMin) / (item.SliderMax - item.SliderMin)

    tfrm:SetPoint ("TOPLEFT", per * 100, 0)

    if item.Text then

        local fstr = item.TextFStr
        fstr:SetText (format ("%s (%.2f)", item.Text, item.SliderPos))
    end
end

---------------------------------------------------------------------------------------

function Nx.Menu:Item_OnEnter (motion)

    local this = self            -- V4
    local item = this.NxMenuItem

    if item.ShowState and item.ShowState < 0 then
        item.AlphaTarget = .5
    else
        item.AlphaTarget = .9
    end
end

function Nx.Menu:Item_OnLeave (motion)

    local this = self            -- V4
    local item = this.NxMenuItem

    item.AlphaTarget = Nx.Menu.Item_ALPHAFADE

--    item.SliderMoving = nil
end

function Nx.Menu:Item_OnUpdate (elapsed)

    local this = self            -- V4
    local item = this.NxMenuItem

    item.Alpha = Nx.Util_StepValue (item.Alpha, item.AlphaTarget, elapsed * 4)

    this.texture:SetVertexColor (.2, .2, .5, item.Alpha)

    if item.Slider and item == Nx.Menu.SliderMoving then
        Nx.Menu:Item_HandleSlider (item)
    end
end

function Nx.Menu:Item_OnMouseDown (button)

    local this = self            -- V4
    local item = this.NxMenuItem

    if button == "LeftButton" then

        if item.Check then

            item:SetChecked (not item.Checked)
            Nx.Menu:CheckUpdate (item)

            if item.Func then
                item.Func (item.User, item, item.User)
            end

        elseif item.Slider then

            Nx.Menu.SliderMoving = item
            Nx.Menu:Item_HandleSlider (item)

        elseif item.SubMenu then

            item.SubMenu:Open()
--            item.Menu:Close()

        else

            if item.ShowState and item.ShowState >= 0 then
                if item.Func then
                    item.Func (item.User, item, item.User)
                end
            end

            item.Menu:Close()
        end
    end
end

function Nx.Menu:Item_OnMouseUp (button)

    local this = self            -- V4
    local item = this.NxMenuItem

    if button == "LeftButton" then
        Nx.Menu.SliderMoving = nil
    end
end

function Nx.Menu:Item_OnMouseWheel (value)

    local this = self            -- V4
    local item = this.NxMenuItem

    value = (value > 0 and 1 or -1) * (item.Step or .01)

    if IsShiftKeyDown() then
        value = value * 10
    end

    local x = item:GetSlider() + value

    if IsAltKeyDown() then
        x = 1
    end

    Nx.Menu:Item_SetUpdateSlider (item, x)
end

function Nx.Menu:Item_HandleSlider (item)

    local frm = item.SliderFrm
    local x = Nx.Util_GetMouseClampedXY (frm)

    if x then

        x = (x - 1) / (frm:GetWidth() - 2) * (item.SliderMax - item.SliderMin) + item.SliderMin

        if IsShiftKeyDown() then
            x = floor (x * 10) / 10
        end

        if IsAltKeyDown() then
            x = 1
        end

        Nx.Menu:Item_SetUpdateSlider (item, x)
    end
end

function Nx.Menu:Item_SetUpdateSlider (item, x)

    local old = item:GetSlider()
    item:SetSlider (x)

--    Nx.prt ("Slider %f", x)

    if item:GetSlider() ~= old then

        Nx.Menu:SliderUpdate (item)

--        Nx.prtVar ("Slider", item.Func)

        if item.Func then
            item.Func (item.User, item, item.User)
        end
    end
end

---------------------------------------------------------------------------------------
-- List
---------------------------------------------------------------------------------------

--[[
Nx.List.FontSizeConvert = {
    10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
    10, 10, 15, 15, 15, 15, 15, 15, 15, 15
}

Nx.List.FontNames = {
    [10] = "FontS",
    [15] = "FontM"
}
--]]

-------------------------------------------------------------------------------
-- LIST SYSTEM
-- Creates scrollable list controls with columns and selection
-------------------------------------------------------------------------------

---
-- Initialize list system
--
function Nx.List:Init()

    local ldata = Nx:GetData ("List")
    self.SaveData = ldata

    if not ldata.Version or ldata.Version < Nx.VERSIONList then

        if ldata.Version then
            Nx.prt (L["Reset old list data"])
        end
        ldata.Version = Nx.VERSIONList

        for k, list in pairs (ldata) do
            if type (list) == "table" then
--                Nx.prt (" Reset %s", k)
                ldata[k] = nil
            end
        end
    end

    self.Lists = {}

    local frms = {}
    self.Frms = frms        -- Table of frame type tables

    self.FrmsUniqueI = 0

    local types = { "Color", "WatchItem", "Info" }

    for n, s in ipairs (types) do
        frms[s] = {}
    end
end

---------------------------------------------------------------------------------------
-- Free list frames by adding back to global list
---------------------------------------------------------------------------------------

-- Creds to Deathcore for frame fix
local visFrms = {}

function Nx.List:FreeFrames (list)
    local frms = self.Frms
    for n, f in ipairs (list.UsedFrms) do
        if not InCombatLockdown() then
            -- Hide everything, including WatchItem. The previous "skip hide
            -- on WatchItem to prevent blink" optimization assumed 1:1 frame
            -- reuse on every render — but renders that need FEWER WatchItem
            -- icons leave the leftovers visible (ghost duplicates floating
            -- on progress bars / next quest's row). Re-render reuses these
            -- frames in the very next instruction so the flash is too short
            -- to perceive in practice.
            f:Hide()
        else
            tinsert(visFrms, f)
        end
        tinsert (frms[f.NXListFType], n, f)
    end
    if not InCombatLockdown() then
        for i, j in ipairs (visFrms) do
            j:Hide()
        end
        wipe(visFrms or {})
    end
    list.UsedFrms = wipe (list.UsedFrms or {})
end

---------------------------------------------------------------------------------------
-- Reset list frames by adding back to global list
---------------------------------------------------------------------------------------

--[[
function Nx.List:FreeFrame (list, frm)

    list.UsedFrms[frm] = nil

    local frms = self.Frms

    frm:Hide()
    tinsert (frms[frm.NXListFType], frm)
end
--]]

---------------------------------------------------------------------------------------
-- Get a list frame from the global list
---------------------------------------------------------------------------------------

function Nx.List:GetFrame (list, typ)
    local frms = self.Frms[typ]
    local f = tremove (frms, 1)
    if not f then
        self.FrmsUniqueI = self.FrmsUniqueI + 1
        if typ == "Color" then
            f = CreateFrame ("ColorSelect", nil, list.Frm)
        elseif typ == "WatchItem" then
                f = CreateFrame ("Button", "NxListFrms" .. self.FrmsUniqueI, list.Frm, "NxWatchListItem")
                f:RegisterForClicks("AnyUp", "AnyDown")
                f:SetAttribute ("type1", "item")
        elseif typ == "Info" then
            f = Nx.Info:CreateFrame (list.Frm)
        end
        f.NXListFType = typ
    end
    f:Show()
    f:SetParent (list.Frm)
    tinsert (list.UsedFrms, f)
    return f
end

---------------------------------------------------------------------------------------
-- Flag next update of all lists for a full update
---------------------------------------------------------------------------------------

function Nx.List:NextUpdateFull()

    if self.Lists then
        for inst in pairs (self.Lists) do
            inst.SSW = nil
        end
    end
end

---------------------------------------------------------------------------------------
-- Setup creation font
---------------------------------------------------------------------------------------

function Nx.List:SetCreateFont (font, baseLineH)
--[[
    if type (font) == "number" then

        local h = self.FontSizeConvert[font]
        self.CFont = self.FontNames[h]
        self.CLineH = h
        self.CBaseLineH = baseLineH or h
        return
    end
--]]
    self.CFont = font
--    self.CLineH = nil
    self.CBaseLineH = baseLineH
end

---------------------------------------------------------------------------------------
-- Create
---------------------------------------------------------------------------------------

function Nx.List:Create (saveName, xpos, ypos, width, height, parentFrm, showAll, noHeader)

    if not self.CFont then                -- Not set?
        self:SetCreateFont ("Font.Small")    -- Default
    end

    local inst = {}                    -- New instance

    setmetatable (inst, self)
    self.__index = self

    if saveName then

        local save = self.SaveData[saveName] or {}
        self.SaveData[saveName] = save
        inst.Save = save

        if save["ColW"] then
            inst.SaveColumnWidths = { Nx.Split ("^", save["ColW"]) }
        end
    end

    inst.Columns = {}
    inst.Strs = {}
    inst.Buts = {}

    inst.Font = self.CFont
    inst.FontObj = Nx.Font:GetObj (inst.Font)
--    inst.LineH = self.CLineH
    inst.LineHPad = 0
    inst.BaseLineH = self.CBaseLineH
    inst.Top = 1
    inst.Vis = 1
    inst.Selected = 1
    inst.ShowAll = showAll

    inst:SetMinSize()

    -- Add to list of lists

    self.Lists[inst] = true
    inst.UsedFrms = {}

    -- Create list frame

    local frm = CreateFrame ("Frame", nil, parentFrm, "BackdropTemplate")
    inst.Frm = frm
    frm.NxInst = inst

    frm:SetScript ("OnMouseDown", self.OnMouseDown)
    frm:EnableMouse (true)
    frm:SetScript ("OnMouseWheel", self.OnMouseWheel)
    frm:EnableMouseWheel (true)

    frm.texture = frm:CreateTexture()
    frm.texture:SetAllPoints (frm)
    frm.texture:SetColorTexture (0, 0, 0, .3)

    frm:SetPoint ("TOPLEFT", xpos, ypos)
    frm:Show()

    -- Create list header

    inst.HdrH = 0

    if not noHeader then

        inst.HdrH = 12

        local hfrm = CreateFrame ("Frame", nil, frm, "BackdropTemplate")
        inst.HdrFrm = hfrm
        hfrm.NxInst = inst

        hfrm:SetScript ("OnMouseDown", self.OnHdrMouseDown)
        hfrm:EnableMouse (true)

        hfrm.texture = hfrm:CreateTexture()
        hfrm.texture:SetAllPoints (hfrm)
        hfrm.texture:SetColorTexture (.2, .2, .3, 1)
        hfrm:SetPoint ("TOPLEFT", 0, 0)
        hfrm:Show()
    end

    -- Create selected line frame

    local sfrm = CreateFrame ("Frame", nil, frm, "BackdropTemplate")
    inst.SelFrm = sfrm
    sfrm.NxInst = inst

    sfrm.texture = sfrm:CreateTexture()
    sfrm.texture:SetAllPoints (sfrm)
    sfrm.texture:SetColorTexture (.4, .4, .5, .4)
    sfrm.texture:SetBlendMode ("Add")

--    sfrm:SetHeight (inst:GetLineH() + 1)
    sfrm:Hide()

    -- Slider

    if not showAll then
        inst.Slider = Nx.Slider:Create (frm, "V", 10, inst.HdrH)
        inst.Slider:SetUser (inst, self.OnSlider)
    end

    -- Finish setup

    inst:Empty()
    inst:SetSize (width, height)

    -- Reset creation data

    self.CFont = nil

    --

    return inst
end

---------------------------------------------------------------------------------------
-- Set user of the list (for event handlers) and generic callback function
-- (instance)
-- self = instance
---------------------------------------------------------------------------------------

function Nx.List:SetUser (user, func)
    self.User = user
    self.UserFunc = func
end

---------------------------------------------------------------------------------------
-- Set list fade
-- self = instance
---------------------------------------------------------------------------------------

function Nx.List:SetFade (fade)

--    prt ("Fade "..fade)

    if not self.NoBGFade then
        self.Frm.texture:SetVertexColor (1, 1, 1, fade)
    end

    local hf = self.HdrFrm
    if hf then
        hf.texture:SetVertexColor (1, 1, 1, fade)
    end

    self.SelFrm:SetAlpha (fade)

    if self.Slider then
        self.Slider.Frm.texture:SetAlpha (fade * .6)
        self.Slider.ThumbFrm.texture:SetAlpha (fade * .9)
    end
end

---------------------------------------------------------------------------------------
-- Set list background color
-- self = instance
---------------------------------------------------------------------------------------

function Nx.List:SetBGColor (r, g, b, a, noFade)
    if self.Frm.texture then
        self.Frm.texture:SetColorTexture (r, g, b, a or 1)
    end

    self.NoBGFade = noFade
end

---------------------------------------------------------------------------------------
-- Set list font size
-- self = instance
---------------------------------------------------------------------------------------

--[[
function Nx.List:SetFont (fontSize)

    local h = self.FontSizeConvert[fontSize]
    self.Font = self.FontNames[h]
    self.LineH = fontSize

    for id, column in ipairs (self.Columns) do
        column.Font = self.Font
    end
end
--]]

---------------------------------------------------------------------------------------
-- Set list line height
-- self = instance
---------------------------------------------------------------------------------------

function Nx.List:SetLineHeight (height, hdrH)

    self.LineHPad = height

    self.HdrH = hdrH or 12

    if self.Slider then
        self.Slider:SetTLOff (self.HdrH)
    end

    self:Update()
end

function Nx.List:GetLineH()
    return Nx.Font:GetH (self.Font) + self.LineHPad
end

---------------------------------------------------------------------------------------
-- Set list item frame info
---------------------------------------------------------------------------------------

function Nx.List:SetItemFrameScaleAlpha (scale, alpha)
    self.ItemFrameScale = scale
    self.ItemFrameAlpha = alpha
end

---------------------------------------------------------------------------------------
-- Lock or unlock list
---------------------------------------------------------------------------------------

function Nx.List:Lock (lock)

    self.Frm:EnableMouse (not lock)
    self.Frm:EnableMouseWheel (not lock)
end

---------------------------------------------------------------------------------------
-- Force a full list update
---------------------------------------------------------------------------------------

function Nx.List:FullUpdate()
    local w = self.SSW
    self.SSW = nil
    self:SetSize (w, self.SSH)
end

---------------------------------------------------------------------------------------
-- Set minimum list size (width or height can be nil)
---------------------------------------------------------------------------------------

function Nx.List:SetMinSize (width, height)
    self.MinW = width or 2
    self.MinH = height or 1
end

---------------------------------------------------------------------------------------
-- Update list size
-- self = instance
---------------------------------------------------------------------------------------

function Nx.List:SetSize (width, height)

    if width == self.SSW and height == self.SSH then
--        Nx.prt ("List SetSize SKIP %s %s", width, height)
        return
    end

--    Nx.prt ("List SetSize %s %s", width, height)

    self.SSW = width
    self.SSH = height

    if not self.ShowAll then
        self:Resize (width, height)
    end

    self:Update()
end

function Nx.List:GetSize()
    return self.SSW, self.SSH
end

---------------------------------------------------------------------------------------
-- Update list size
-- self = instance
---------------------------------------------------------------------------------------

function Nx.List:Resize (width, height)
    local f = self.Frm

    if f:IsProtected() then
        return
    end

    local hdrH = self.HdrH
    local lineH = self:GetLineH()
    local padW = 1
    local padH = 0

    if self.ShowAll then

        height = self.Num * lineH + hdrH + padH * 2

        local last = self.Top + self.Vis - 1
        last = min (last, self.Num)

        local strNum = 1
        local cNum = 1
        width = padW * 2

        local offX = 0

        for k, column in ipairs (self.Columns) do

            local maxCW = column.Width
--            Nx.prt ("colW %s %s", k, maxCW)

            for line = self.Top, last do

                if self.Offsets then
                    offX = self.Offsets[line] or 0
                end

                maxCW = max (maxCW, self.Strs[strNum]:GetWidth() + offX)
--                Nx.prt ("maxCW %s %f", line, maxCW)
                strNum = strNum + 1
            end

            strNum = strNum + (self.Vis * cNum - strNum + 1)

            width = width + maxCW

            cNum = cNum + 1

            self.SSW = width
            self.SSH = height
        end

--        width = min (width, 30)
    end

--    prt ("List WH %d %d", width, height)

    width = max (self.MinW, width)
    height = max (self.MinH, height)

    if(not InCombatLockdown()) then
        f:SetWidth (width)
        f:SetHeight (height)
    end

    local sfrm = self.SelFrm
    sfrm:SetWidth (width - 10)

    height = max (height - hdrH, 1)

    self.Vis = floor ((height - padH * 2) / lineH)
    self.Vis = max (self.Vis, 0)

--    Nx.prt ("List resize vis %s", self.Vis)

    -- Set columns

    local hf = self.HdrFrm
    if hf then
        hf:SetWidth (width)
        hf:SetHeight (hdrH)
    end

    local x = 0
    local clipW = width - padW * 2

    for k, column in ipairs (self.Columns) do

        local colW = min (column.Width, clipW)
        column.ClipW = colW

        local hfstr = column.FStr
        if hfstr then
            hfstr:SetPoint ("TOPLEFT", padW + x, 0)
            hfstr:SetWidth (colW)
        end

        x = x + column.Width
        clipW = clipW - column.Width
    end

    self:CreateStrings()
    self:CreateButtons()
end

---------------------------------------------------------------------------------------
-- Create any needed list strings
-- self = instance
---------------------------------------------------------------------------------------

function Nx.List:CreateStrings()

    local f = self.Frm
    local hdrH = self.HdrH
    local lineH = self:GetLineH()
    local width = f:GetWidth()
    local padW = 1
    local padH = 0

    local x = 0
    local strNum = 1

    for k, column in ipairs (self.Columns) do

        local colW = column.ClipW
        local offX = 0
        local offY = 0

        for n = 1, self.Vis do

            local fstr = self.Strs[strNum]

            if not fstr then
                fstr = f:CreateFontString()
                self.Strs[strNum] = fstr
            end

            fstr:SetFontObject (column.FontObj)
            fstr:SetJustifyH (column.JustifyH)

            if self.Offsets then
                local line = self.Top + n - 1
                offX = self.Offsets[line] or 0
                offY = self.Offsets[-line] or 0
            end

            fstr:SetPoint ("TOPLEFT", padW + x + offX, -(n - 1) * lineH - hdrH - padH - offY)

            if not self.ShowAll then
                fstr:SetWidth (colW - offX)
            end

            fstr:SetHeight (lineH)
            fstr:Show()

            strNum = strNum + 1
        end

        x = x + column.Width
    end

    -- Hide extra strings

--    prt ("ListSetSize "..self.Vis.." "..#self.Strs)

    for n = strNum, #self.Strs do
        self.Strs[n]:Hide()
    end

end

---------------------------------------------------------------------------------------
-- Create any needed list buttons
-- self = instance
---------------------------------------------------------------------------------------

function Nx.List:CreateButtons()

    local butNum = 1

    if self.ButData then

        local scale = self:GetLineH() / self.BaseLineH

--        Nx.prt ("list but scale %s", scale)

        local f = self.Frm
        local offX = 0
        local offY = 0

        for n = 1, self.Vis do

            local but = self.Buts[butNum]

            if not but then

--                Nx.prt ("List resize create but %s", butNum)

                but = Nx.Button:Create (f, nil, nil, nil, 0, 0, "CENTER", 14, 14, self.OnBut, self)
                self.Buts[butNum] = but

                but.Frm:SetFrameLevel (f:GetFrameLevel() + 1)

                -- Flag for OverFrm to render row-wide hover highlight
                -- instead of sized to the small icon button itself.
                but.IsListRow = true
                but.NxListInst = self
            end

            but.Frm:SetScale (scale)

            butNum = butNum + 1
        end
    end

    -- Hide extra buttons

    if self.Buts then
        for n = butNum, table.maxn (self.Buts) do
            if self.Buts[n] then
                self.Buts[n].Frm:Hide()
            end
        end
    end
end

function Nx.List:Update (showLast)

    if self.SortColumnId and not self.Sorted then
        self:Sort()
    end

    local lineH = self:GetLineH()
    local hdrH = self.HdrH

--    Nx.prt ("List lineH %s", lineH)

    if showLast then
        self:ShowLast()
    end

    if self.ShowAll then
        self:Resize (0, 0)
    end

    self.Top = min (self.Top, self.Num - self.Vis + 1)
    self.Top = max (self.Top, 1)

    self.Selected = min (self.Selected, self.Num)

    local last = self.Top + self.Vis - 1
    last = min (last, self.Num)

    if self.Offsets or #self.Strs < self.Vis then
        self:CreateStrings()
    end

    local strNum = 1
    local cNum = 1

    for k, column in ipairs (self.Columns) do

        for line = self.Top, last do

            local txt = column.Data[line]
            self.Strs[strNum]:SetText (txt)

            strNum = strNum + 1
        end

        -- Hide extras

        for n = strNum, self.Vis * cNum do
            self.Strs[n]:SetText ("")
            strNum = strNum + 1
        end

        cNum = cNum + 1
    end

    -- Do final resize and size parent win

    if self.ShowAll then

        self:Resize (0, 0)

        local f = self.Frm
        local win = f:GetParent().NxWin

        if win then
            win:SetSize (f:GetWidth(), -7, true)
        end
    end

    -- Slider

    if not self.ShowAll then
        self.Slider:Set (self.Top, 1, self.Num, self.Vis)
        self.Slider:Update()
    end

    -- Buttons

    if self.ButData then

        if not self.Buts or #self.Buts < self.Vis then
            self:CreateButtons()
        end

--        Nx.prt ("List Update Vis %s", self.Vis)

        local padW = 1
        local padH = 0

        local butNum = 1
        local f = self.Frm
        local offX = 0
        local offY = 0
        local adjY = hdrH + padH + lineH/2 + .5

        for n = 1, self.Vis do

            local line = self.Top + n - 1

            local but = self.Buts[butNum]
            local butType = self.ButData[line]

            if butType then

                if not but then
                    Nx.prt (L["!BUT %s"], #self.Buts)
                end
                assert (but)

--                prt ("ListResize but #%d %s", n, butType)

                but:SetType (butType)
                but:SetId (line)

                local butTx = self.ButData[line + 1000000]

                if butType == "Color" then
                    local t = self.ButData[line + 8000000]
                    butTx = t[self.ButData[line + 9000000]]
                end

--                prtVar ("But Tex", butTx)
                but:SetTexture (butTx)

                local butTip = self.ButData[line + 2000000]
                but.Frm.NxTip = butTip
                but.Frm.NXTipFrm = self.ButData[line + 3000000]

                -- Causes update
                but:SetPressed (self.ButData[-line])

                if self.Offsets then
                    offX = self.Offsets[line] or 0
                    offY = self.Offsets[-line] or 0
                end

                local scale = self:GetLineH() / self.BaseLineH
                local y = (-(n - 1) * lineH - adjY - offY) / scale

                but.Frm:SetPoint ("CENTER", f, "TOPLEFT", (padW + lineH/2 + offX) / scale, y)
                but.Frm:Show()

            elseif but then

                but.Frm:Hide()
            end

            butNum = butNum + 1
        end

    elseif self.Buts then

        self:CreateButtons()        -- Hides all since we have no data
    end

    -- Frames

--[[ Example: (OLD)
      text 1 frm 1 (color)
    --------- Visible
    1 text 2
    2 text 3 frm 2 (color). Get frm to keep until scrolls off visible area of list
    3 text 4
    4 text 5 frm 3 (color). Get frm
    ---------
      text 6
--]]

    if self.FrmData then            -- Only used for Info and Watch Items

        Nx.List:FreeFrames (self)

        local lfrm = self.Frm
        local offX = 3
        local offY = 3
        local adjY = hdrH + .5
        local doBind = true

        for n = 1, self.Vis do

            local line = self.Top + n - 1
            local data = self.FrmData[line]

            if data then

                local typ, v1, v2, v3 = Nx.Split ("~", data)

--                Nx.prt ("%s", -(n - 1) * lineH - adjY - offY)

                if typ == "Info" then

                    if self.UserFunc then
                        self.UserFunc (self.User, "update", v1, -(n - 1) * lineH - adjY)
                    end

                elseif typ == "WatchItem" then
                    if InCombatLockdown() then
                        return
                    end
                    local f = Nx.List:GetFrame (self, typ)
                    f:ClearAllPoints()

                    local scale = self.ItemFrameScale * .07 * lineH / 13

                    f:SetPoint ("TOPRIGHT", lfrm, "TOPLEFT", offX, -(n - 1) * lineH / scale - adjY - offY)

                    f["rangeTimer"] = -1

                    f:SetScale (scale)
                    f:SetWidth (29)
                    f:SetHeight (30)
                    f:SetAlpha (tonumber(self.ItemFrameAlpha))

                    local id = tonumber (v1)
                    f:SetID (id)

                    SetItemButtonTexture (f, v2);
                    SetItemButtonCount (f, tonumber (v3));
                    f["charges"] = tonumber (v3);

                    f["questLogIndex"] = id

                    local start, duration, enable = GetQuestLogSpecialItemCooldown (id)
                    if start then
                        CooldownFrame_Set (f.Cooldown, start, duration, enable)
                        if ( duration > 0 and enable == 0 ) then
                            SetItemButtonTextureVertexColor (itemButton, 0.4, 0.4, 0.4)
                        else
                            SetItemButtonTextureVertexColor (itemButton, 1, 1, 1)
                        end
                     end

                    local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo (tonumber(id))
                    f:SetAttribute ("item", link)

                    if doBind then
                        doBind = false
                        local key = GetBindingKey ("NxWATCHUSEITEM")
                        if key then
                            Nx.qdb.profile.QuestWatch.KeyUseItem = key
                            Nx.prt (L["Key %s transfered to Watch List Item"], key)
                        end

                        if #Nx.qdb.profile.QuestWatch.KeyUseItem > 0 and not InCombatLockdown() then

                            local s = GetBindingAction (Nx.qdb.profile.QuestWatch.KeyUseItem)
                            s = strmatch (s, L["CLICK (.+):"])
--                            Nx.prt ("Key's frm %s", s or "nil")
                            if s ~= f:GetName() then
                                local ok = SetBindingClick (Nx.qdb.profile.QuestWatch.KeyUseItem, f:GetName())
                                Nx.prt (L["Key %s %s #%s %s"], Nx.qdb.profile.QuestWatch.KeyUseItem, f:GetName(), line, ok or "nil")
                                Nx.qdb.profile.QuestWatch.KeyUseItem = ""
                            end
                        end
                    end

                    f:Show()

                end
            end
        end

    end

    -- Position selected line

    local sfrm = self.SelFrm
    local selY = self.Selected - self.Top

    if selY < 0 or selY >= self.Vis then
        sfrm:Hide()

    else
        sfrm:SetHeight (lineH + 1)
        sfrm:SetPoint ("TOPLEFT", 0, -selY * lineH - self.HdrH)
        sfrm:Show()
    end
end

---------------------------------------------------------------------------------------

function Nx.List:SaveColumns()

    if self.Save then

        local str = ""
        local sep = ""

        for id, column in ipairs (self.Columns) do
            str = str .. sep .. column.Width
            sep = "^"
        end

        self.Save["ColW"] = str
    end
end

function Nx.List:ColumnAdd (name, columnId, width, justifyH, font)

    local colId = columnId or 1
    local w = width or 9999

    if self.SaveColumnWidths then
        w = tonumber (self.SaveColumnWidths[colId]) or w
    end

    local column = {}
    column.Name = name
--    column.Max = 0
    column.Width = w
    column.FontObj = Nx.Font:GetObj (font or self.Font)
    column.JustifyH = justifyH or "LEFT"
    column.Data = {}

    if self.HdrFrm then

        local fstr = self.HdrFrm:CreateFontString()
        column.FStr = fstr

        fstr:SetFontObject (self.FontObj)
        fstr:SetJustifyH (column.JustifyH)
        fstr:SetPoint ("TOPLEFT", 0, 0)

        if w >= 0 then
            fstr:SetWidth (w)
        end

        fstr:SetHeight (self.HdrH)

        fstr:SetText (name)
        fstr:SetTextColor (.8, .8, 1, 1)
        fstr:Show()
    end

    self.Columns[colId] = column

    self.SSW = nil            -- Cause resize
end

function Nx.List:ColumnSetWidth (columnId, width)
    local column = self.Columns[columnId]
    column.Width = width
end

function Nx.List:ColumnGetWidth (columnId)
    return self.Columns[columnId].Width
end

function Nx.List:ColumnSetName (columnId, name)

    local colId = columnId or 1
    local column = self.Columns[colId]

    column.Name = name

    local fstr = column.FStr

    if fstr then

        if self.SortColumnId == columnId then
            name = ">" .. name
        end

        fstr:SetText (name)
        fstr:SetTextColor (.8, .8, 1, 1)

        self.SSW = nil        -- Cause resize
    end
end

function Nx.List:ColumnHitTest (x)

    local colX = 0

    for id, column in ipairs (self.Columns) do

        if x >= colX and x < colX + column.Width then
            return id, column
        end

        colX = colX + column.Width
    end
end

---------------------------------------------------------------------------------------
-- Empty the list
---------------------------------------------------------------------------------------

function Nx.List:Empty()

    self.Num = 0
    self.Data = wipe (self.Data or {})

    for k, column in pairs (self.Columns) do
        column.Data = column.Data and wipe (column.Data)
    end

    if self.ButData then
        wipe (self.ButData)
    end

    if self.Offsets then
        wipe (self.Offsets)
    end

    if self.FrmData then
        wipe (self.FrmData)
    end

--    if self.FrmDataFrm then
--        wipe (self.FrmDataFrm)
--    end

    Nx.List:FreeFrames (self)

    self.Sorted = false
end

---------------------------------------------------------------------------------------

function Nx.List:ColumnSort (columnId)

    self.Sorted = false

    if self.SortColumnId == columnId then
        self.SortColumnId = nil
    else
        self.SortColumnId = columnId
    end

    for id, column in pairs (self.Columns) do
        self:ColumnSetName (id, column.Name)
    end
end

---------------------------------------------------------------------------------------
-- Sort list by a columns contents
---------------------------------------------------------------------------------------

function Nx.List:Sort()

    local column = self.Columns[self.SortColumnId]
    local cData = column.Data
    if not cData then        -- or #cData < self.Num then
        return
    end

    self.Sorted = true

    local cNameData = self.Columns[2].Data

    local t = {}
    for n = 1, self.Num do
        local name = gsub (cNameData[n], "|cff......", "")
        t[n] = gsub (cData[n] or "", "|cff......", "") .. " " .. strsub (name, 1, 1) .. "~" .. n
    end

    sort (t)

    -- Convert sorted to number

    for n = 1, #t do
        local _, i = Nx.Split ("~", t[n])
        t[n] = tonumber (i)
    end

    -- Reorder tables

    local data = {}

    for n = 1, #t do
        data[n] = self.Data[t[n]]
    end

    self.Data = data

    for k, column in pairs (self.Columns) do

        if column.Data then
            local data = {}

            for n = 1, #t do
                data[n] = column.Data[t[n]]
            end

            column.Data = data
        end
    end

    if self.ButData then
        local data = {}

        for n = 1, #t do
            local i = t[n]
            data[n] = self.ButData[i]
            data[-n] = self.ButData[-i]
            data[n + 1000000] = self.ButData[i + 1000000]
            data[n + 2000000] = self.ButData[i + 2000000]
            data[n + 3000000] = self.ButData[i + 3000000]
            data[n + 8000000] = self.ButData[i + 8000000]
            data[n + 9000000] = self.ButData[i + 9000000]
        end

        self.ButData = data
    end

    if self.Offsets then
        local data = {}

        for n = 1, #t do
            data[n] = self.Offsets[t[n]]
        end

        self.Offsets = data
    end
end

---------------------------------------------------------------------------------------

function Nx.List:ItemAdd (userData)

    self.Num = self.Num + 1
    self.Data[self.Num] = userData
end

function Nx.List:ItemGetNum()

    return self.Num
end

function Nx.List:ItemSet (columnId, str, index)

    local i = index or self.Num

    local column = self.Columns[columnId]

    column.Data[i] = str
end

--[[
function Nx.List:ItemGetButtonPressed (index)

    if self.ButData then

        local but = self.Buts[index]

        if but then
            return but:GetPressed()
        end
    end

    return false
end
--]]

function Nx.List:ItemSetButton (typ, pressed, tex, tip, func)

    if not self.ButData then
        self.ButData = {}
    end

    local index = self.Num

    self.ButData[index] = typ
    self.ButData[-index] = pressed

    if tex then
        self.ButData[index + 1000000] = tex
    end
    if tip then
        self.ButData[index + 2000000] = tip
    end
    if func then
        self.ButData[index + 5000000] = func
    end
end

function Nx.List:ItemGetButtonTip (index)

    if self.ButData then
        return self.ButData[index + 2000000]
    end
end

function Nx.List:ItemSetButtonTip (tip, index, frm)

    if self.ButData then

        index = index or self.Num
        self.ButData[index + 2000000] = tip
        if frm then
            self.ButData[index + 3000000] = frm
        end
    end
end

function Nx.List:ItemSetFunc(func, index)
    if self.ButData then
        index = index or self.Num
        self.ButData[index + 5000000] = func
    end
end

function Nx.List:ItemGetFunc (index)
    if self.ButData then
        return self.ButData[index + 5000000]
    end
end

---------------------------------------------------------------------------------------
-- Set a solid colored button used to pick colors
-- Table[key] is a "rrggbbaa" hex number
---------------------------------------------------------------------------------------

function Nx.List:ItemSetColorButton (table, key, hasAlpha)

    if not self.ButData then
        self.ButData = {}
    end

    local index = self.Num

    self.ButData[index] = "Color"
    self.ButData[index + 8000000] = table
    self.ButData[index + 9000000] = key

    if not hasAlpha then
        self.ButData[index + 10000000] = true
    end
end

function Nx.List:ItemSetFrame (typ)

    if not self.FrmData then
        self.FrmData = {}
--        self.FrmDataFrm = {}
    end

    self.FrmData[self.Num] = typ
end

function Nx.List:ItemSetOffset (offX, offY)

    if not self.Offsets then
        self.Offsets = {}
    end

    self.Offsets[self.Num] = offX
    self.Offsets[-self.Num] = offY
end

function Nx.List:ItemGetData (index)

    index = index or self.Selected
    return index and self.Data[index]
end

function Nx.List:ItemSetData (index, data)

    self.Data[index] = data
end

---------------------------------------------------------------------------------------
-- Get extended data
-- (num >= 1)
---------------------------------------------------------------------------------------

function Nx.List:ItemGetDataEx (index, num)

    index = index or self.Selected
    return index and self.Data[index + num * 10000000]
end

---------------------------------------------------------------------------------------
-- Set extended data
---------------------------------------------------------------------------------------

function Nx.List:ItemSetDataEx (index, data, num)

    self.Data[(index or self.Num) + num * 10000000] = data
end

---------------------------------------------------------------------------------------
-- Select list line
-- (index or 0)
---------------------------------------------------------------------------------------

function Nx.List:Select (index)

    assert (index >= 0 and index <= self.Num)

    self.Selected = index

    if index < self.Top then
        self.Top = max (index, 1)

    elseif index >= self.Top + self.Vis then
        self.Top = max (index - self.Vis + 1, 1)
    end
end

---------------------------------------------------------------------------------------
-- Get selected list line
---------------------------------------------------------------------------------------

function Nx.List:GetSelected()

    return self.Selected
end

---------------------------------------------------------------------------------------
-- Send select to user
---------------------------------------------------------------------------------------

function Nx.List:SendUserSelect()

    if self.UserFunc then
        self.UserFunc (self.User, "select", self.Selected, 0)
    end
end

---------------------------------------------------------------------------------------
-- Show last item at bottom of list view
---------------------------------------------------------------------------------------

function Nx.List:ShowLast()

    self.Top = self.Num - self.Vis + 1
    self.Top = max (self.Top, 1)
end

---------------------------------------------------------------------------------------
-- Is the last item shown?
---------------------------------------------------------------------------------------

function Nx.List:IsShowLast()

    local top = self.Num - self.Vis + 1
    top = max (top, 1)
    return self.Top == top
end

function Nx.List:OnHdrMouseDown (click)

    local this = self            -- V4

    local x = Nx.Util_IsMouseOver (this)

    if x then

        local self = this.NxInst

        local id, column = self:ColumnHitTest (x)
        if id then
--            Nx.prt ("OnHdrMouseDown %s", id)

            if IsShiftKeyDown() then

                local add = click == "LeftButton" and 10 or -10
                column.Width = max (column.Width + add, 10)
                self:SaveColumns()
                self:FullUpdate()
            else

                if click == "LeftButton" then

                    if id and self.UserFunc then
                        self.UserFunc (self.User, "sort", 0, id)
                    end
                else
                    Nx.prt (L["shift left/right click to change size"])
                end
            end
        end
    end
end

Nx.List.ClickToName = {
    ["LeftButton"] = "select",
    ["MiddleButton"] = "mid",
    ["RightButton"] = "menu",
    ["Button4"] = "back",
}

function Nx.List:OnMouseDown (click)

--    prt ("List MouseDown "..click)

    local this = self            -- V4

    local inst = this.NxInst
    local x, y = Nx.Util_IsMouseOver (this)

    if x then

        y = this:GetHeight() - y

        if y >= inst.HdrH then

            y = floor ((y - inst.HdrH) / inst:GetLineH())
            inst.Selected = min (y + inst.Top, inst.Num)

            local id = inst:ColumnHitTest (x)

            if id and inst.UserFunc then
                inst.UserFunc (inst.User, Nx.List.ClickToName[click], inst.Selected, id)
            end

            inst:Update()
        end
    end
end

function Nx.List:OnMouseWheel (value)

--    prt ("List MouseWheel "..tostring (value))

    if IsShiftKeyDown() then
        value = value * 5

        if IsControlKeyDown() then
            value = value * 20
        end
    end

    local this = self            -- V4

    local inst = this.NxInst
    inst.Top = inst.Top - value
    inst:Update()
end

function Nx.List:OnBut (but, id, click)

    if self.ButData[id] == "Color" then
        self:OpenColorDialog (id)
        return
    end

    self.ButData[-id] = but:GetPressed()

--    prt ("List but %d %s", id, tostring (self.ButData[-id]))
    if self.UserFunc then
        self.UserFunc (self.User, "button", id, self.ButData[-id], click, but)
    end
end

function Nx.List:OpenColorDialog (id)

    local f = ColorPickerFrame

    f:SetMovable (true)

    self.ColorId = id
    f.NXList = self
    f.NXTbl = self.ButData[id + 8000000]
    f.NXVName = self.ButData[id + 9000000]

    local hasAlpha = not self.ButData[id + 10000000]

    f["func"] = function()
            local f = ColorPickerFrame
            local r, g, b = f:GetColorRGB()
            local a = f["hasOpacity"] and (1 - OpacitySliderFrame:GetValue()) or 1
--            Nx.prt ("%s %s %s %s", r, g, b, a)
            f.NXTbl[f.NXVName] = floor (r * 255) * 0x1000000 + floor (g * 255) * 0x10000 + floor (b * 255) * 0x100 + floor (a * 255)

            local self = f.NXList

            self:Update()

            if self.UserFunc then
                self.UserFunc (self.User, "color", self.ColorId)
            end
        end

    f["hasOpacity"] = hasAlpha
    f["opacityFunc"] = f["func"]
    f["cancelFunc"] = function (old)
            f.NXTbl[f.NXVName] = old
            local self = f.NXList
            self:Update()
            if self.UserFunc then
                self.UserFunc (self.User, "color", self.ColorId)
            end
        end

    local col = f.NXTbl[f.NXVName]
    f["previousValues"] = col
    local r, g, b, a = Nx.Util_str2rgba (col)

    f:SetColorRGB (r, g, b)
    f["opacity"] = 1 - a

    ShowUIPanel (f)
end

function Nx.List:OnSlider (slider, pos)

    self.Top = floor (pos)
    self:Update()
end

---------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- DROPDOWN SYSTEM
-- Creates dropdown selection controls
-------------------------------------------------------------------------------

---
-- Initialize dropdown system
--
function Nx.DropDown:Init()

    -- Create Window

    local win = Nx.Window:Create ("NxDD", nil, nil, nil, 0, true, true, true)
    self.Win = win
    local frm = win.Frm

    win:EnableMenu (false)

    win:InitLayoutData (nil, 0, 0, 200, 200)

    tinsert (HideFramesOnEsc, frm:GetName())

    frm:SetClampedToScreen (true)
    frm:SetToplevel (true)
--    self.Win:Show (false)

    -- List

    Nx.List:SetCreateFont ("Font.Medium")

    local list = Nx.List:Create (false, 0, 0, 1, 1, frm, false, true)
    self.List = list

    list:SetUser (self, self.OnListEvent)

    list:ColumnAdd ("", 1)
--    list:SetLineHeight (0, 0)

    win:Attach (list.Frm, 0, 1, 0, 1)
end

function Nx.DropDown:Start (user, func)

    self.User = user
    self.Func = func

    local list = self.List
    list:Empty()
end

function Nx.DropDown:Add (name, select)

--    Nx.prt ("DropDown Add %s", name)

    local list = self.List
    list:ItemAdd (name)
    list:ItemSet (1, name)

    if select then
        list:Select (list:ItemGetNum())
    end
end

function Nx.DropDown:AddT (data, selectI)

    for n, name in ipairs (data) do
        self:Add (name, n == selectI)
    end
end

function Nx.DropDown:Show (parent, x, y)

    local uiparent = UIParent
    if not x then
        x, y = GetCursorPosition()
        x = x / uiparent:GetEffectiveScale() - 80
        y = y / uiparent:GetEffectiveScale() - GetScreenHeight() + 10
    end

--    Nx.prt ("DropDown Show %s %s", x, y)

    local win = self.Win
    local f = win.Frm
    local list = self.List

    win:SetFrmStrata (4)

    f:SetParent (parent)

    f:SetPoint ("TOPLEFT", uiparent, "TOPLEFT", x, y)
    win:Show()

    list:FullUpdate()
end

---------------------------------------------------------------------------------------
-- On list control updates
---------------------------------------------------------------------------------------

function Nx.DropDown:OnListEvent (eventName, sel, val2, click)

    local name = self.List:ItemGetData (sel)
    if name then

--        Nx.prt ("DropDown %s, %s", eventName, name)

        if eventName == "select" or eventName == "mid" then

            self.Func (self.User, name, sel)
        end
    end

    self.Win:Show (false)
end

---------------------------------------------------------------------------------------
-- Tab Bar
---------------------------------------------------------------------------------------

function Nx.TabBar:GetHeight()
    return 22
end

---------------------------------------------------------------------------------------
-- Create a Tab Bar
-- ()
-- ret: tab bar table
---------------------------------------------------------------------------------------

function Nx.TabBar:Create (name, parentFrm, width, height)

    local c2rgba = Nx.Util_str2rgba

    parentFrm = parentFrm or UIParent

    -- New

    local bar = {}

    setmetatable (bar, self)
    self.__index = self

    bar.Name = name
    bar.Tabs = {}

    -- Create window frame

    local f = CreateFrame ("Frame", name, parentFrm, "BackdropTemplate")
    bar.Frm = f
    f.NxInst = bar

--    f:SetMinResize (100, 40)

    f:SetWidth (width)
    f:SetHeight (height)

    f:SetPoint ("TOPLEFT", 100, -100)
--    f:SetFrameStrata ("MEDIUM")

--    f:SetScript ("OnEvent", self.OnEvent)
--    f:RegisterEvent ("PLAYER_LOGIN")

--    f:SetScript ("OnUpdate", self.OnUpdate)

    local t = f:CreateTexture()
    t:SetColorTexture (c2rgba ("0|0|0|.5"))
    t:SetAllPoints (f)
    f.texture = t

    f:Show()

    -- Create GUI elements

    bar:CreateBorders()

    return bar
end

---------------------------------------------------------------------------------------
-- Create border frames
---------------------------------------------------------------------------------------

function Nx.TabBar:CreateBorders()

    local c2rgba = Nx.Util_str2rgba

    local f = CreateFrame ("Frame", nil, self.Frm, "BackdropTemplate")

    self.TopFrm = f

    f:SetPoint ("TOPLEFT", 0, 0)
    f:SetPoint ("TOPRIGHT", 0, 0)

--    f:SetWidth (1)
    f:SetHeight (4)

    local t = f:CreateTexture()
    t:SetColorTexture (c2rgba (".313|.313|.313|1"))
    t:SetAllPoints (f)
    f.texture = t

    f:Show()

end

---------------------------------------------------------------------------------------
-- Set user for notify
---------------------------------------------------------------------------------------

function Nx.TabBar:SetUser (user, func)

    self.User = user
    self.UserFunc = func
end

---------------------------------------------------------------------------------------
-- Add a tab to bar
---------------------------------------------------------------------------------------

function Nx.TabBar:AddTab (name, index, width, press, template, butId)

    local tab = {}
    self.Tabs[index] = tab

    tab.Name = name

    -- (parentFrm, typ, text, tip, bx, by, side, width, height, func, user)

    local w = width or 66
    local x = 1 + (index - 1) * (w + 2)

    tab.W = w

    local but = Nx.Button:Create (self.TopFrm, "Tab", name, nil, x, -1, "TOPLEFT", w, 20, self.OnBut, self, template)
    tab.But = but

    if butId then
        but.Frm:SetID (butId)
    end

    but:SetId (index)

    if press then

        but:SetPressed (true)

        local txt = "|cffffffff" .. name
        but:SetText (txt, 0, 2)
    end
end

---------------------------------------------------------------------------------------
-- Select tab button
---------------------------------------------------------------------------------------

function Nx.TabBar:Select (index, force)

    local selTab = self.Tabs[index]
    if not selTab then
        return
    end

    local but = selTab.But
    if not force and but:GetPressed() then
        return
    end

    local x = 1

    for i, tab in pairs (self.Tabs) do
        if i ~= index then
            tab.But:SetPressed (false)
            tab.But:SetText (tab.Name, 0, 0)
        end

        tab.But:SetPos ("TOPLEFT", x, -1)
        tab.But:SetSize (tab.W, 20)

        x = x + tab.W + 2
    end

    but:SetPressed (true)

    local txt = "|cffffffff" .. selTab.Name
    but:SetText (txt, 0, 2)

    if self.UserFunc then
        self.UserFunc (self.User, index)
    end
end

---------------------------------------------------------------------------------------
-- Enable tab button
---------------------------------------------------------------------------------------

function Nx.TabBar:Enable (index, enable)

    local tab = self.Tabs[index]
    tab.But.Frm:EnableMouse (enable ~= false)
end

---------------------------------------------------------------------------------------
-- Set our fade
---------------------------------------------------------------------------------------

function Nx.TabBar:SetFade (fade)

    local f = self.Frm
    f.texture:SetVertexColor (1, 1, 1, fade * .5)

    local tf = self.TopFrm
    tf.texture:SetVertexColor (1, 1, 1, fade)

    for i, tab in pairs (self.Tabs) do
        local f = tab.But.Frm
        f.texture:SetVertexColor (1, 1, 1, fade)
    end
end

---------------------------------------------------------------------------------------
-- Handle tab button press
---------------------------------------------------------------------------------------

function Nx.TabBar:OnBut (but, id, click)

--    Nx.prt ("TabBar but %d %s", id, click)

    if not but:GetPressed() then
        -- Keep it pressed
        but:SetPressed (true)
        return
    end

--    if but.Frm:GetID() ~= 0 then
--        Nx.prt ("TabBar but id %s", but.Frm:GetID())
--        return
--    end

    self:Select (id, true)
end

---------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- TOOLBAR SYSTEM
-- Creates customizable toolbars with buttons
-------------------------------------------------------------------------------

---
-- Initialize toolbar system
--
function Nx.ToolBar:Init()

    local data = Nx:GetDataToolBar()

    if not data.Version or data.Version < Nx.VERSIONTOOLBAR then

        if data.Version then
            Nx.prt (L["Reset old tool bar data"])
        end

        data.Version = Nx.VERSIONTOOLBAR

        for k, bar in pairs (data) do
            if type (bar) == "table" then
--                Nx.prt (" Reset %s", k)
                data[k] = nil
            end
        end
    end

    self.TBs = {}        -- All created tool bars

    self.BORDERW = 5
    self.BORDERH = 5

    self.Borders = {
        "TOPLEFT", "TOPRIGHT", 1, self.BORDERH, "WinBrH",
        "BOTTOMLEFT", "BOTTOMRIGHT", 1, self.BORDERH, "WinBrH",
        "TOPLEFT", "BOTTOMLEFT", self.BORDERW, 1, "WinBrV",
        "TOPRIGHT", "BOTTOMRIGHT", self.BORDERW, 1, "WinBrV",
    }

    local menu = Nx.Menu:Create (UIParent)
    self.Menu = menu

--    self.MenuIUp = menu:AddItem (0, "Move Up", self.Menu_OnUp, self)
--    self.MenuIDn = menu:AddItem (0, "Move Down", self.Menu_OnDn, self)
--    self.MenuIRemove = menu:AddItem (0, "Remove", self.Menu_OnRemove, self)

    self.MenuISize = menu:AddItem (0, "Size", self.Menu_OnSize, self)
    self.MenuISize:SetSlider (8, 8, 32)
    self.MenuISpace = menu:AddItem (0, "Spacing", self.Menu_OnSpace, self)
    self.MenuISpace:SetSlider (0, 0, 15)
    self.MenuIAlignR = menu:AddItem (0, "Align Right", self.Menu_OnAlignR, self)
    self.MenuIAlignR:SetChecked (true)
    self.MenuIAlignB = menu:AddItem (0, "Align Bottom", self.Menu_OnAlignB, self)
    self.MenuIAlignB:SetChecked (true)
    self.MenuIVert = menu:AddItem (0, "Vertical", self.Menu_OnVertical, self)
    self.MenuIVert:SetChecked (true)
end

--function Nx.ToolBar:Menu_OnUp (item)
--end

--function Nx.ToolBar:Menu_OnDn (item)
--end

--function Nx.ToolBar:Menu_OnRemove (item)
--end

function Nx.ToolBar:Menu_OnSize (item)

    self:MenuDoUpdate ("Size", item:GetSlider())
end

function Nx.ToolBar:Menu_OnSpace (item)

    self:MenuDoUpdate ("Space", item:GetSlider())
end

function Nx.ToolBar:Menu_OnAlignR (item)

    self:MenuDoUpdate ("AlignR", item:GetChecked())
end

function Nx.ToolBar:Menu_OnAlignB (item)

    self:MenuDoUpdate ("AlignB", item:GetChecked())
end

function Nx.ToolBar:Menu_OnVertical (item)

    self:MenuDoUpdate ("Vert", item:GetChecked())
end

function Nx.ToolBar:MenuDoUpdate (varName, value)

    local bar = self.Active
    local data = Nx:GetDataToolBar()
    local svdata = data[bar.Name]
    svdata[varName] = value

    bar:Update()
end

function Nx.ToolBar:OpenMenu (bar)

    local data = Nx:GetDataToolBar()
    local svdata = data[bar.Name]

    self.MenuISize:SetSlider (svdata["Size"])
    self.MenuISpace:SetSlider (svdata["Space"] or 3)
    self.MenuIAlignR:SetChecked (svdata["AlignR"])
    self.MenuIAlignB:SetChecked (svdata["AlignB"])
    self.MenuIVert:SetChecked (svdata["Vert"])

    self.Active = bar
    self.Menu:Open()
end

--function Nx.ToolBar:GetHeight()
--    return 22
--end

---------------------------------------------------------------------------------------
-- Create a Tool Bar
-- ()
-- ret: tool bar table
---------------------------------------------------------------------------------------

function Nx.ToolBar:Create (name, parentFrm, size, alignR, alignB)

    local c2rgba = Nx.Util_str2rgba

    parentFrm = parentFrm or UIParent

    local data = Nx:GetDataToolBar()
    local svdata = data[name]

--    svdata = nil

    if not svdata then        -- No data for our name?

        svdata = {}                -- New
        data[name] = svdata

        svdata["Size"] = size
        svdata["Space"] = 1
        svdata["AlignR"] = alignR
        svdata["AlignB"] = alignB
--        svdata["Vert"] = nil
    end

    -- New

    local bar = {}

    setmetatable (bar, self)
    self.__index = self

    assert (self.TBs[bar] == nil)
    self.TBs[bar] = true

    bar.Name = name
    bar.Tools = {}

    bar.Size = size        -- Default

    -- Create window frame
    local f = nil
    local kids = { parentFrm:GetChildren() };
    for _, child in ipairs(kids) do
        if (child:GetName() == name) then
          f = child
        end
    end
    if f == nil then
        f = CreateFrame ("Frame", name, parentFrm, "BackdropTemplate")
    else
        -- Reused Frm — wipe out any button frames left over from a
        -- previous bar instance. Without this, calling CreateToolBar
        -- again (Notes/Warehouse Init does this on top of the map's
        -- own call) leaves orphaned NxBut* children that still
        -- intercept clicks at the same positions as the new buttons
        -- and carry the old bar's UserFunc (= Nx.ToolBar:OnBut).
        for _, child in ipairs({ f:GetChildren() }) do
            if child.NxBut then
                child:Hide()
                child:ClearAllPoints()
                child:SetParent(nil)
                child:EnableMouse(false)
                child.NxBut = nil
            end
        end
    end
    bar.Frm = f
    f.NxInst = bar

--    f:SetMinResize (100, 40)

    f:SetWidth (size)
    f:SetHeight (10)

    f:SetPoint ("TOPRIGHT", 0, 0)

--    f:SetScript ("OnEvent", self.OnEvent)
--    f:RegisterEvent ("PLAYER_LOGIN")

--    f:SetScript ("OnUpdate", self.OnUpdate)

--    local t = f:CreateTexture()
--    t:SetTexture (c2rgba ("00000080"))
--    t:SetAllPoints (f)
--    f.texture = t

    f:Show()

    --

    return bar
end

---------------------------------------------------------------------------------------
-- Set user for notify
---------------------------------------------------------------------------------------

function Nx.ToolBar:SetUser (user, func)

    self.User = user
    self.UserFunc = func
end

---------------------------------------------------------------------------------------
-- Add a button to bar
---------------------------------------------------------------------------------------

function Nx.ToolBar:AddCustomButton (typ, name, index, func, press)
    tinsert (Nx.BarData,{typ, name, func, press})
    local map = Nx.Map:GetMap (1)
    map:CreateToolBar()
end

function Nx.ToolBar:AddButton (typ, name, index, func, press)

    local tool = {}
    tinsert (self.Tools, tool)

    tool.Name = name
    tool.Func = func

    -- (parentFrm, typ, text, tip, bx, by, side, width, height, func, user)

    local but = Nx.Button:Create (self.Frm, typ, nil, name, 0, 0, "TOPLEFT", 1, 1, self.OnBut, self)
    tool.But = but

    but:SetId (func)

    but:SetPressed (press)
end

---------------------------------------------------------------------------------------
-- Handle toolbar button press
---------------------------------------------------------------------------------------

function Nx.ToolBar:OnBut (but, id, click, x, y)

--    prt ("ToolBar but %d %s", id, click)

    if click == "RightButton" then

        -- Buttons whose TypeData opts into PassRightClick get their
        -- handler called for the right-click as well, instead of the
        -- bar's settings menu. Adopters like AddonButtons (Questie's
        -- right-click opens its quest-menu, RareScanner's opens
        -- AceConfigDialog) need the click; default toolbar buttons
        -- keep the menu.
        if but and but.Type and but.Type.PassRightClick and id then
            id (self.User, but, click, x, y)
            return
        end
        Nx.ToolBar:OpenMenu (self)

    else
        local func = id

        if func then
            func (self.User, but, click, x, y)
        end
    end
end

---------------------------------------------------------------------------------------
-- Update toolbar
---------------------------------------------------------------------------------------

function Nx.ToolBar:Update()

    local data = Nx:GetDataToolBar()
    local svdata = data[self.Name]

    local f = self.Frm

--    Nx.prtVar ("AlignR", svdata["AlignR"])

    f:ClearAllPoints()

    local align = "TOPRIGHT"

    if not svdata["AlignR"] then

        align = "TOPLEFT"

        if svdata["AlignB"] then
            align = "BOTTOMLEFT"
        end
    else
        if svdata["AlignB"] then
            align = "BOTTOMRIGHT"
        end
    end

    f:SetPoint (align, 0, 0)

    local scale = svdata["Size"] / self.Size
    local space = (svdata["Space"] or 0) / scale
    local step = self.Size + space

    local xstep = step
    local ystep = 0

    if svdata["Vert"] then
        xstep = 0
        ystep = step
    end

    local xoff = 0
    local yoff = 0

    for n, tool in ipairs (self.Tools) do

        local but = tool.But
        if but then
            but:SetPos ("TOPLEFT", xoff, -yoff)
        end

        xoff = xoff + xstep
        yoff = yoff + ystep
    end

    if not svdata["Vert"] then
        xoff = xoff - space
    else
        yoff = yoff - space
    end

--    Nx.prt ("scale %f, w %f, xoff %f", scale, self.Size, xoff)

    f:SetWidth (max (xoff, self.Size))
    f:SetHeight (max (yoff, self.Size))

    f:SetScale (scale)
end

---------------------------------------------------------------------------------------
-- Set fade level of toolbar and tools
-- (0-1)
---------------------------------------------------------------------------------------

function Nx.ToolBar:SetFade (fade)

--    Nx.prtVar ("TB Fade", fade)

    self.Frm:SetAlpha (fade)
end

---------------------------------------------------------------------------------------
-- Set level of toolbar and tools
---------------------------------------------------------------------------------------

function Nx.ToolBar:SetLevels (level)

    self.Frm:SetFrameLevel (level)

    for n, tool in ipairs (self.Tools) do

        local but = tool.But
        if but then
            but.Frm:SetFrameLevel (level + 1)
        end
    end
end

---------------------------------------------------------------------------------------
-- Sliders
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Create
-------------------------------------------------------------------------------
-- SLIDER SYSTEM
-- Creates scrollbar/slider controls for lists and value adjustment
-------------------------------------------------------------------------------

---
-- Create a new slider control
-- @param parentFrm  Parent frame
-- @param typ        "H" for horizontal, "V" for vertical
-- @param size       Bar size (width or height)
-- @param tlOff      Top or left offset
-- @return           Slider instance
--
function Nx.Slider:Create(parentFrm, typ, size, tlOff)

--    if 1 then return end

    local inst = {}        -- New instance

    setmetatable (inst, self)
    self.__index = self

    local w = size
    local h = size

    inst.TypeH = typ == "H"

    if inst.TypeH then
        w = 10
    else
        h = 10
    end

    local frm = CreateFrame ("Frame", nil, parentFrm, "BackdropTemplate")
    inst.Frm = frm
    frm.NxInst = inst

    frm:SetScript ("OnUpdate", self.OnUpdate)

    frm:SetScript ("OnMouseDown", self.OnMouseDown)
    frm:SetScript ("OnMouseUp", self.OnMouseUp)
    frm:EnableMouse (true)

    frm:SetWidth (w)
    frm:SetHeight (h)

    frm.texture = frm:CreateTexture()
    frm.texture:SetAllPoints (frm)
    frm.texture:SetColorTexture (.3, .3, .4, .6)

    frm:SetPoint ("TOPRIGHT", parentFrm, "TOPRIGHT", 0, -tlOff)
    frm:SetPoint ("BOTTOMRIGHT", parentFrm, "BOTTOMRIGHT", 0, 0)

    frm:Show()

    -- Thumb

    local tfrm = CreateFrame ("Frame", nil, frm, "BackdropTemplate")
    inst.ThumbFrm = tfrm

    tfrm:SetWidth (w)
    tfrm:SetHeight (h)

    tfrm.texture = tfrm:CreateTexture()
    tfrm.texture:SetAllPoints (tfrm)
    tfrm.texture:SetColorTexture (.3, .3, .7, .9)

    tfrm:SetPoint ("TOPLEFT", 1, 1)
    tfrm:Show()

    --

    inst:Set (0, 0, 9, 1)
    inst:Update()

    return inst
end

---------------------------------------------------------------------------------------
-- Set user of the slider for callback function
-- (user table, function)
---------------------------------------------------------------------------------------

function Nx.Slider:SetUser (user, func)

    self.User = user
    self.UserFunc = func
end

---------------------------------------------------------------------------------------
--
---------------------------------------------------------------------------------------

function Nx.Slider:SetTLOff (tlOff)

    local par = self.Frm:GetParent()
    self.Frm:SetPoint ("TOPRIGHT", par, "TOPRIGHT", 0, -tlOff)
end

---------------------------------------------------------------------------------------
-- Get slider position
-- self = instance
---------------------------------------------------------------------------------------

function Nx.Slider:Get()
    return self.Pos
end

---------------------------------------------------------------------------------------
-- Set slider position and optionally min and max values
-- self = instance
---------------------------------------------------------------------------------------

function Nx.Slider:Set (pos, min, max, visSize)

    if min then
        self.Min = math.min (min, max)
        self.Max = math.max (min, max)
    end

    if visSize then
        self.VisSz = math.max (visSize, 1)
    end

    -- Clamp pos
    pos = math.max (pos, self.Min)
    pos = math.min (pos, self.Max - self.VisSz + 1)
    self.Pos = pos

--    Nx.prt ("Slider Set %f (%f %f) %f", pos, self.Min, self.Max, self.VisSz)

end

function Nx.Util_c2rgb (colors)

    local r = tonumber (strsub (colors, 1, 2), 16) / 255
    local g = tonumber (strsub (colors, 3, 4), 16) / 255
    local b = tonumber (strsub (colors, 5, 6), 16) / 255
    return r, g, b
end

-- Hex colour with alpha. Accepts either:
--   "AARRGGBB" (alpha first, the legacy format used by AddIconRect)
--   {r, g, b, a} as a pre-decoded table
-- Returns r, g, b, a in 0..1 range. Several callers (renderZR, the
-- new renderLINE patrol-path path) need this; the legacy code
-- assumed it existed but never defined it.
function Nx.Util_c2rgba (colors)
    if type(colors) == "table" then
        return colors[1] or 1, colors[2] or 1, colors[3] or 1, colors[4] or 1
    end
    if type(colors) ~= "string" then
        return 1, 1, 1, 1
    end
    if #colors >= 8 then
        local a = tonumber(strsub(colors, 1, 2), 16) / 255
        local r = tonumber(strsub(colors, 3, 4), 16) / 255
        local g = tonumber(strsub(colors, 5, 6), 16) / 255
        local b = tonumber(strsub(colors, 7, 8), 16) / 255
        return r, g, b, a
    end
    -- 6-char fallback: treat as RGB with full alpha.
    local r = tonumber(strsub(colors, 1, 2), 16) / 255
    local g = tonumber(strsub(colors, 3, 4), 16) / 255
    local b = tonumber(strsub(colors, 5, 6), 16) / 255
    return r, g, b, 1
end

function Nx.Slider:OnMouseDown (button)

    local this = self            -- V4
    local self = this.NxInst

    if button == "LeftButton" then

        local frm = self.Frm

        local x, y = Nx.Util_IsMouseOver (frm)

        if x and x >= 0 then

            local tfrm = self.ThumbFrm
            local tx, ty = Nx.Util_IsMouseOver (tfrm)

            if self.TypeH then

                local w = (frm:GetRight() or 0) - (frm:GetLeft() or 0)

                x = (x - 1) / (frm:GetWidth() - 2) * (self.Max - self.Min) + self.Min
                self:Set (x)

            else

                if tx then

                    self.DragX = x
                    self.DragY = y
                    self.DragPos = self.Pos

                else

                    local h = (frm:GetTop() or 0) - (frm:GetBottom() or 0)
                    y = h - y

--                    Nx.prt ("Slider XY %f %f", x, y)

                    local pos = self.Pos

                    if y < -self.TPt then
                        pos = pos - self.VisSz
                    else
                        pos = pos + self.VisSz
                    end

                    self:Set (pos)
                end
            end

            self:Update()

            if self.UserFunc then
                self.UserFunc (self.User, self, self.Pos)
            end
        end

    end
end

function Nx.Slider:OnMouseUp (button)

    local inst = self.NxInst
    inst.DragX = nil
end

function Nx.Slider:OnUpdate (elapsed)

    local this = self            -- V4
    local self = this.NxInst

    self:Drag()

    if self.NeedUpdate then
        self.NeedUpdate = false
        self:DoUpdate()
    end
end

function Nx.Slider:Drag()

    if self.DragX then

        local frm = self.Frm
        local x, y = Nx.Util_GetMouseClampedXY (frm)

        if x then

            local tfrm = self.ThumbFrm

            if self.TypeH then

                local dx = self.DragX - x

            else

                local dy = self.DragY - y

                local h = (frm:GetTop() or 0) - (frm:GetBottom() or 0)
                y = h - y

                if dy ~= 0 then

--                    h = h - tfrm:GetHeight()

                    local i = dy / h * (self.Max - self.Min + 1)
                    self:Set (self.DragPos + i)

                    self:Update()

                    if self.UserFunc then
                        self.UserFunc (self.User, self, self.Pos)
                    end

--                    Nx.prt ("Slider Drag %f %f pos %f", dy, i, self.Pos)
                end
            end

        else
--            self.DragX = nil

        end
    end
end

function Nx.Slider:Update()
    self.NeedUpdate = true
end

---------------------------------------------------------------------------------------
-- Update slider
-- self = instance
---------------------------------------------------------------------------------------

function Nx.Slider:DoUpdate()

    local frm = self.Frm
    local tfrm = self.ThumbFrm

    local range = self.Max - self.Min + 1
    local per = (self.Pos - self.Min) / (max (range - self.VisSz, 1))

--    Nx.prt ("Slider Update per %f", per)

    if self.TypeH then

        local w = (frm:GetRight() or 0) - (frm:GetLeft() or 0)        -- Attached, so GetWidth is wrong
        tfrm:SetPoint ("TOPLEFT", per * w, 0)
    else

        local h = (frm:GetTop() or 0) - (frm:GetBottom() or 0)        -- Attached, so GetHeight is wrong

        local tper = min (self.VisSz / range, 1)
        if tper >= 1 or h < 6 then

            self.TPt = 0
            frm:SetAlpha (.3)
            tfrm:Hide()
        else

            frm:SetAlpha (1)
            tfrm:Show()

            local clip = 0

            local th = tper * h
            if th < 5 then
                clip = 5 - th
                th = 5
            end

--            Nx.prt ("Slider Update tper %f h %f th %f", tper, h, th)

            tfrm:SetHeight (th)

            h = h - tper * h
            self.TPt = -per * h

            tfrm:SetPoint ("TOPLEFT", 0, self.TPt)
        end
    end
end

-------------------------------------------------------------------------------
-- GRAPH SYSTEM
-- Creates interactive bar graphs for data visualization
-------------------------------------------------------------------------------

---
-- Create a new graph control
-- @param width      Graph width in pixels
-- @param height     Graph height in pixels
-- @param parentFrm  Parent frame
-- @return           Graph instance
--
function Nx.Graph:Create(width, height, parentFrm)

    local c2rgba = Nx.Util_str2rgba

--    prt ("Graph "..width)

    local g = {}        -- New graph

    g.Clear = self.Clear
    g.SetLine = self.SetLine
    g.UpdateLine = self.UpdateLine
    g.SetPeak = self.SetPeak
    g.UpdateFrames = self.UpdateFrames
    g.ResetFrames = self.ResetFrames
    g.GetFrame = self.GetFrame

    local f = CreateFrame ("Frame", nil, parentFrm, "BackdropTemplate")
    g.MainFrm = f

    f.NxGraph = g
    f.NxSetSize = self.OnSetSize

    f:EnableMouse (true)

    f:SetFrameStrata ("MEDIUM")
    f:SetWidth (width + 2)
    f:SetHeight (height + 2)
    f:SetPoint ("TOPLEFT", 0, 0)

    local t = f:CreateTexture()
    t:SetColorTexture (c2rgba (".125|.125|.125|.625"))
    t:SetAllPoints (f)
    f.texture = t

    f:Show()

    g.Width = width
    g.Height = height
    g.ScaleX = 8

    g.Frms = {}

    g:Clear()

    local sf = CreateFrame ("Slider", nil, f, "NxSliderFrame" .. (BackdropTemplateMixin and ",BackdropTemplate" or ""))
    g.SliderFrm = sf
    sf.NxGraph = g

    local bd = {
        ["bgFile"] = "Interface\\Buttons\\UI-SliderBar-Background",
        ["edgeFile"] = "Interface\\Buttons\\UI-SliderBar-Border",
        ["tile"] = true,
        ["tileSize"] = 8,
        ["edgeSize"] = 8,
        ["insets"] = { ["left"] = 3, ["right"] = 3, ["top"] = 6, ["bottom"] = 6 }}
    sf:SetBackdrop (bd)

    sf:SetOrientation ("HORIZONTAL")
--    sf:SetThumbTexture ("Interface\Buttons\UI-SliderBar-Button-Horizontal")
    sf:SetFrameStrata ("MEDIUM")
    sf:SetWidth (100)
    sf:SetHeight (10)
    sf:ClearAllPoints()
    sf:SetPoint ("BOTTOMLEFT", 0, -11)
    sf:SetMinMaxValues (1, 25)
    sf:SetValueStep (.5)
    sf:SetValue (g.ScaleX)
    sf:SetScript ("OnValueChanged", Nx.Graph.ScaleSlider_OnValueChanged)
--[[
    local st = sf:CreateTexture()
    st:SetTexture (c2rgba ("202020ff"))
    st:SetAllPoints (sf)
    sf.texture = st
--]]
    sf:Show()

    return g
end

-- Scale slider value changed
-- self = frm

function Nx.Graph:ScaleSlider_OnValueChanged()

    self.NxGraph.ScaleX = self:GetValue()
    self.NxGraph:UpdateFrames()

--    prt ("Slider "..self.NxGraph.ScaleX)
end

-- Clear graph
-- self = graph

function Nx.Graph:Clear()

    -- Clear values
    self.Values = {}
    self.Values.Next = 1
    self.Peak = 1

    -- Hide frames
    self:ResetFrames()

end

-- Set a graph line
-- self = graph

function Nx.Graph:SetLine (time, value, colorStr, infoStr)

    local pos = self.Values.Next
    assert (pos ~= 0)

    self.Values[-pos] = time
    self.Values[pos] = value
    self.Values[pos + 0x1000000] = colorStr
    self.Values[pos + 0x2000000] = infoStr

    self.Values.Next = pos + 1

    self:UpdateLine (pos)

end

---------------------------------------------------------------------------------------
-- Set a graph line
-- self = graph
---------------------------------------------------------------------------------------

function Nx.Graph:UpdateLine (pos)

    local c2rgb = Nx.Util_c2rgb

    assert (pos ~= 0)

    local time = self.Values[-pos]

    local x = time * self.ScaleX
    if x >= 0 and x < self.Width - 1 then

        local value = self.Values[pos]

        local h = value / self.Peak
        if h > 1 or h < 0 then
            h = 1
        end

        h = h * self.Height

        if h >= .1 then

            h = max (h, 4)

            local f = self:GetFrame()
            f.NxGraphPos = pos
            f:SetHeight (h)
            f:SetWidth (self.ScaleX * .25)

            f:SetPoint ("BOTTOMLEFT", x, 1)

            local colorStr = self.Values[pos + 0x1000000]
            f.texture:SetColorTexture (c2rgb (colorStr))

            f:Show()
        end
    end
end

---------------------------------------------------------------------------------------
-- Set peak value of graph
-- self = graph
---------------------------------------------------------------------------------------

function Nx.Graph:SetPeak (peak)

    if peak < 1 then
        peak = 1
    end

    if peak > self.Peak then

--        prt ("Peak: "..peak)

        self.Peak = peak
        self:UpdateFrames()
    end
end

---------------------------------------------------------------------------------------
-- Update all graph frames
-- self = graph
---------------------------------------------------------------------------------------

function Nx.Graph:UpdateFrames()

    self:ResetFrames()

    for n = 1, self.Values.Next - 1 do
        self:UpdateLine (n)
    end
end

---------------------------------------------------------------------------------------
-- Reset frames
-- self = graph
---------------------------------------------------------------------------------------

function Nx.Graph:ResetFrames()

    local n = 1
    local f

    while true do
        f = self.Frms[n]
        if not f then
            break
        end
        f:Hide()
        n = n + 1
    end

    self.Frms.Next = 1

end

---------------------------------------------------------------------------------------
-- Get next available frame or create one
-- self = graph
---------------------------------------------------------------------------------------

function Nx.Graph:GetFrame()

    local pos = self.Frms.Next

    if pos > 1000 then
        pos = 1        -- Reset. Too many used
    end

    local f = self.Frms[pos]
    if not f then

        f = CreateFrame ("Frame", nil, self.MainFrm, "BackdropTemplate")
        self.Frms[pos] = f
        f.NxGraph = self

        f:SetFrameStrata ("MEDIUM")

        local t = f:CreateTexture()
        t:SetAllPoints (f)
        f.texture = t

        f:SetScript ("OnEnter", Nx.Graph.OnEnter)
        f:SetScript ("OnLeave", Nx.Graph.OnLeave)
        f:EnableMouse (true)

    end

    self.Frms.Next = pos + 1

    return f
end

---------------------------------------------------------------------------------------
-- Called when frame size changes
---------------------------------------------------------------------------------------

function Nx.Graph:OnSetSize (w, h)

    local g = self.NxGraph

    if g.Width ~= w or g.Height ~= h then

        g.Width = w
        g.Height = h

        g:UpdateFrames()
    end
end

---------------------------------------------------------------------------------------
-- Handle mouse on graph line
---------------------------------------------------------------------------------------

function Nx.Graph:OnEnter (motion)

    local this = self            -- V4

    if not Nx.TooltipText:IsOwned (this) and this.NxGraphPos then

        local self = this.NxGraph

        Nx.TooltipOwner = this

        Nx.TooltipText:SetOwner (this, "ANCHOR_CURSOR")
        local v = self.Values
        local str = format ("%.2f: %s", v[-this.NxGraphPos], v[this.NxGraphPos + 0x2000000])
--        Nx.prt (str)
        Nx.TooltipText:SetText (str)
        Nx.TooltipText:Show()
    end
end

---------------------------------------------------------------------------------------
-- Handle mouse leaving graph line
---------------------------------------------------------------------------------------

function Nx.Graph:OnLeave (motion)

    -- V4 this

    if Nx.TooltipText:IsOwned (self) then
        Nx.TooltipText:Hide()
    end
end

function NxWatchListItem_OnUpdate(self, elapsed)
    -- Handle range indicator
    local rangeTimer = self.rangeTimer;
    if ( rangeTimer ) then
        rangeTimer = rangeTimer - elapsed;
        if ( rangeTimer <= 0 ) then
            local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(tonumber(self.questLogIndex));
            if ( not charges or charges ~= self.charges ) then
                --ObjectiveTracker_Update(OBJECTIVE_TRACKER_UPDATE_MODULE_QUEST);
                return;
            end
            local count = self.HotKey;
            local valid = IsQuestLogSpecialItemInRange(self.questLogIndex);
            if ( valid == 0 ) then
                count:Show();
                count:SetVertexColor(1.0, 0.1, 0.1);
            elseif ( valid == 1 ) then
                count:Show();
                count:SetVertexColor(0.6, 0.6, 0.6);
            else
                count:Hide();
            end
            rangeTimer = TOOLTIP_UPDATE_TIME;
        end
        self.rangeTimer = rangeTimer;
    end
end

-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------

-- Carbonite | Modules / Comm / WireFormat
-- Documented surface for Carbonite's addon-channel + chat-channel
-- wire format. The legacy NxCom encodes packets as tab-separated
-- field lists prefixed by a single-letter command kind, with a few
-- character substitutions to dodge WoW's chat-string restrictions:
--
--   - byte 35 ('#') is added to bytes that would otherwise collide
--     with '\' (== 92) so a raw escape never appears mid-stream.
--   - byte 124 ('|') would create a Blizzard escape code unless
--     followed by 'c', so all stray bars get prefix-escaped.
--   - byte 128+ would error the chat path (invalid UTF-8), so
--     coordinates are base-32 / base-36 packed into ASCII.
--
-- This class is the canonical encoder/decoder. The real send/recv
-- path still lives in NxCom because of its tie to AceComm + the
-- chat-channel flush state machine; we expose:
--
--   WireFormat:Encode(kind, fields)   -> string
--   WireFormat:Decode(message)        -> kind, { fields... }
--   WireFormat:EscapeChar(byte)       -> string-safe substitute
--   WireFormat:UnescapeString(s)      -> raw bytes restored
--   WireFormat:GetKnownKinds()        -> { "I", "P", "T", "Q", "K", "L" }
--
-- A "field" is an arbitrary string with no embedded tabs; the
-- encoder asserts on tab-in-field to catch protocol violations.

local Carbonite = _G.Carbonite

local WireFormat = {}
Carbonite.Modules.Comm = Carbonite.Modules.Comm or {}
Carbonite.Modules.Comm.WireFormat = WireFormat

local FIELD_SEP = "\t"
local KIND_SEP  = "~"   -- legacy "Map~x~y~mapID" format also exists

-- The full set of message kinds NxCom currently emits. Documented
-- here so other modules can introspect.
WireFormat.KINDS = {
    I = "info",       -- player info packet (level / class / zone / faction)
    P = "position",   -- map position
    T = "target",     -- current target id / name
    Q = "quest",      -- quest sync
    K = "kill",       -- kill announcement
    L = "log",        -- info message for the Com log window
    Map = "map",      -- legacy "Map~x~y~mapID" position broadcast
}

function WireFormat:GetKnownKinds()
    local out = {}
    for k in pairs(self.KINDS) do out[#out + 1] = k end
    table.sort(out)
    return out
end

-- Encode `kind` + `fields` into a wire string. Asserts on tabs in
-- field values because they'd break the decoder.
function WireFormat:Encode(kind, fields)
    if not kind then return nil end
    fields = fields or {}
    local parts = { tostring(kind) }
    for i, v in ipairs(fields) do
        local s = tostring(v)
        if s:find(FIELD_SEP, 1, true) then
            error(("WireFormat:Encode field %d contains tab: %s"):format(i, s), 2)
        end
        parts[#parts + 1] = s
    end
    return table.concat(parts, FIELD_SEP)
end

-- Decode a message string. Returns (kind, fieldsArray) on success or
-- nil on malformed input.
function WireFormat:Decode(message)
    if type(message) ~= "string" or message == "" then return nil end
    local kind, rest = message:match("^([^\t]+)\t?(.*)$")
    if not kind then return nil end
    local fields = {}
    if rest and rest ~= "" then
        for f in rest:gmatch("([^\t]+)") do fields[#fields + 1] = f end
    end
    return kind, fields
end

-- Character escaping to avoid Blizzard's chat-string parser. The
-- legacy NxCom uses ASCII 35 (#) + 57 (9) to represent a literal
-- backslash; this helper exposes the same mapping symmetrically.
function WireFormat:EscapeChar(byte)
    if byte == 92  then return "#9" end    -- '\'
    if byte == 124 then return "#|" end    -- '|'  (prevents |c escape)
    return string.char(byte)
end

function WireFormat:EscapeString(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("[\\|]", function(c)
        local b = c:byte()
        if b == 92 then return "#9" end
        if b == 124 then return "#|" end
        return c
    end))
end

function WireFormat:UnescapeString(s)
    if type(s) ~= "string" then return s end
    s = s:gsub("#9", "\\")
    s = s:gsub("#|", "|")
    return s
end

-- Convenience: a tilde-separated payload used by the legacy
-- position broadcast ("Map~px~py~mapID"). Encode and decode keep the
-- tilde format intact so existing receivers parse it unchanged.
function WireFormat:EncodeTilde(kind, fields)
    local parts = { tostring(kind) }
    for _, v in ipairs(fields or {}) do parts[#parts + 1] = tostring(v) end
    return table.concat(parts, KIND_SEP)
end

function WireFormat:DecodeTilde(message)
    if type(message) ~= "string" then return nil end
    local parts = {}
    for f in message:gmatch("([^~]+)") do parts[#parts + 1] = f end
    if #parts == 0 then return nil end
    return parts[1], { table.unpack(parts, 2) }
end

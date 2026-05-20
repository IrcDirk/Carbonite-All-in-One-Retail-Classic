-- Carbonite | Modules / DataExportImport
-- Public surface around the character-data export / import flow.
-- The legacy code exposes this through the options-menu Import /
-- Export buttons (Nx.Opts:NXCmdImportCharSettings etc.) plus the
-- AceSerializer-3.0 wire format for compressing the character
-- snapshot. This class is the documented entry point.
--
-- Public API:
--   DataExportImport:Export(character)    -> base64 string
--   DataExportImport:Import(text)         -> bool
--   DataExportImport:ExportCurrent()
--   DataExportImport:GetSerializer()      -> AceSerializer-3.0 lib

local Carbonite = _G.Carbonite
local DataExportImport = {}
Carbonite.Modules.DataExportImport = DataExportImport

function DataExportImport:GetSerializer()
    return LibStub and LibStub("AceSerializer-3.0", true)
end

local function compress(text)
    local lib = LibStub and LibStub("LibCompress", true)
    if not lib then return text end
    local encoded = lib:CompressHuffman(text) or text
    -- Carbonite uses base64-style encoding for chat-safe pasting.
    local b64 = lib.GetAddonEncodeTable and lib:GetAddonEncodeTable() or nil
    return b64 and b64:Encode(encoded) or encoded
end

local function decompress(text)
    local lib = LibStub and LibStub("LibCompress", true)
    if not lib then return text end
    local b64 = lib.GetAddonEncodeTable and lib:GetAddonEncodeTable() or nil
    local decoded = b64 and b64:Decode(text) or text
    return lib:Decompress(decoded)
end

function DataExportImport:Export(character)
    local ser = self:GetSerializer()
    if not ser then return nil end
    local raw = ser:Serialize(character or {})
    return compress(raw)
end

function DataExportImport:Import(text)
    if type(text) ~= "string" or text == "" then return false end
    local ser = self:GetSerializer()
    if not ser then return false end
    local decoded = decompress(text)
    local ok, payload = ser:Deserialize(decoded or "")
    if not ok then return false end
    -- The legacy import flow then calls CopyCharacterData; we fire
    -- an event so plugins can wire any additional restoration.
    Carbonite.Core.EventBus:Fire("DATA_IMPORTED", payload)
    return true
end

function DataExportImport:ExportCurrent()
    local ch = _G.Nx and _G.Nx.CurCharacter
    return self:Export(ch)
end

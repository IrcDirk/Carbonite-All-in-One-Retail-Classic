-- Carbonite | Util / NxSplit
-- The legacy Nx.Split function. Returns multiple values via unpack
-- (NOT an array like Util.Strings.Split), with a weak-keyed cache
-- so the same string is only split once per session.
--
-- Lives in Util/ rather than Modules/ because data files
-- (Data/<flavor>/Guides/FlightMaster.lua, etc.) call Nx.Split at
-- file-load time, before Modules.xml runs. Util.xml is loaded
-- right after Bootstrap and Compat, so Nx is already aliased to
-- the AceAddon table by the time this file runs.

-- Cache for split results (weak values for garbage collection).
local TempTable = setmetatable({}, { __mode = "v" })

--- Split `p` by single-character `d`. Returns the pieces as
--- multiple values (use { Nx.Split(...) } to collect).
function Nx.Split(d, p)
    if p and not string.find(p, d) then
        return p
    end
    if not p then
        return nil
    end
    if #p <= 1 then return p end

    if TempTable[p] then
        return unpack(TempTable[p], 1, table.maxn(TempTable[p]))
    end

    local pieces = { strsplit(d, p) }
    TempTable[p] = pieces
    return unpack(pieces)
end

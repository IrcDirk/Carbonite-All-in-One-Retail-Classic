-- Carbonite.Quests | Data / Shared / QuestDataLoader
-- Runtime loader that picks the right per-expansion data set instead
-- of relying on a different TOC per expansion. The TOC declares the
-- list of XML stubs for every flavor (they all live in Data/<flavor>/);
-- this file checks which one matches the running client and forwards
-- the others into a no-op state.
--
-- Each Data/<flavor>/QuestData.xml file pushes its quest tables into
-- the global NXQuestDB_<flavor> namespace; this file aliases the
-- right one to NXQuestDB after detection.

local Carbonite = _G.Carbonite
if not Carbonite then return end

local Expansion = Carbonite.Compat.Expansion
local log = Carbonite.Core.Logger:Get("QuestDataLoader")

local FOLDER_TO_GLOBAL = {
    classic = "NXQuestDB_classic",
    tbc     = "NXQuestDB_tbc",
    wrath   = "NXQuestDB_wrath",
    cata    = "NXQuestDB_cata",
    mop     = "NXQuestDB_mop",
    retail  = "NXQuestDB_retail",
}

local folder = Expansion:GetMapDataFolder()
local source = FOLDER_TO_GLOBAL[folder]

if source and _G[source] then
    _G.NXQuestDB = _G[source]
    log:debug("aliased %s -> NXQuestDB", source)
else
    -- Either the data file did not run (older TOC layout), or this
    -- client's flavor has no shipping DB. Leave NXQuestDB at whatever
    -- existing code populated so we do not erase legacy data.
    log:debug("no per-flavor DB at %s; using existing NXQuestDB", tostring(source))
end

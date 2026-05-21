-- Carbonite | Modules / Gather / GatherEngine
-- The Nx-namespaced gather helpers extracted from Carbonite.lua.
-- These survive because external legacy callsites (NxMapGuide.lua,
-- maybe data files) still call `Nx:ShouldShowGatherNode` /
-- `Nx:GetMaxGatherSkill` / `Nx:GetGatherNodeName`. The new
-- Modules/Gather/Gather.lua module forwards through these too,
-- and Compat/Expansion.lua is the canonical source for the
-- per-expansion skill caps.

local Carbonite = _G.Carbonite

local function Expansion()
    return Carbonite.Compat and Carbonite.Compat.Expansion
end

---
-- Get max gathering skill level for the current game version.
-- Used to filter which gathering nodes are relevant for the current
-- expansion (9999 on retail = show everything).
--
function Nx:GetMaxGatherSkill()
    local e = Expansion()
    if e and e.GetMaxGatherSkill then return e:GetMaxGatherSkill() end
    -- Mirror of Compat.Expansion:GetMaxGatherSkill so we still return
    -- a sensible value if the Compat layer somehow isn't loaded.
    if Nx.isRetail       then return 9999 end
    if Nx.isMoPClassic   then return 600  end
    if Nx.isCataClassic  then return 525  end
    if Nx.isWotlkClassic then return 450  end
    if Nx.isTBCClassic   then return 375  end
    if Nx.isClassicEra   then return 300  end
    return 9999
end

---
-- Check if a gathering node should be shown for the current game version.
-- @param skill           The skill level of the node.
-- @param isExpansionNode true if this is a WoD+ expansion-specific node
--                        (skill=1 expansion herbs/mines).
--
function Nx:ShouldShowGatherNode(skill, isExpansionNode)
    -- WoD+ expansion nodes use skill=1 and are retail/WoD-only.
    -- Classic-era nodes like Silverleaf / Peacebloom / Copper Vein also
    -- have skill=1 but should always be shown (isExpansionNode=false).
    if skill == 1 and isExpansionNode then
        return Nx.isRetail or Nx.WODMaps
    end
    return skill <= Nx:GetMaxGatherSkill()
end

---
-- Get localized name for a gather node by item id.
-- Falls back to the L["..."] name in GatherInfo if the item isn't cached.
-- @param typ   "H" for herbs, "M" for mines, "L" for timber.
-- @param index Index into Nx.GatherInfo[typ].
--
function Nx:GetGatherNodeName(typ, index)
    local nodeData = Nx.GatherInfo and Nx.GatherInfo[typ] and Nx.GatherInfo[typ][index]
    if not nodeData then
        return "Unknown"
    end

    local itemId = nodeData[4]
    if itemId then
        local name
        if C_Item and C_Item.GetItemInfo then
            name = C_Item.GetItemInfo(itemId)
        elseif GetItemInfo then
            name = GetItemInfo(itemId)
        end
        if name then return name end
    end
    return nodeData[3] or "Unknown"
end

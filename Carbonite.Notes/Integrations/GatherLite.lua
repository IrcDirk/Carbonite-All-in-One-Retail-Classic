-- Carbonite.Notes | Integrations / GatherLite
-- Mirrors GatherLite's gathering nodes (its bundled database plus the
-- player's own gathered history) onto the Carbonite map.

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

Nx.Notes.GLVersion    = Nx.Notes.GLVersion or 0
Nx.Notes.GLLastMapId  = nil
Nx.Notes.GLLastSig    = nil
Nx.Notes.PrevGLPins   = 0

local KINDS = { "mining", "herbalism", "containers", "fishing" }
local KIND_LABEL = { mining = "mining", herbalism = "herbalism", fishing = "fish" }

function Nx.Notes:IsGatherLiteAvailable()
    local GL = _G.GatherLite
    return type(GL) == "table"
        and type(GL.GetNodesForMap) == "function"
        and type(GL.GetNodeObject) == "function"
        and type(GL.IsLoaded) == "function"
        and GL.db ~= nil
end

local function bump()
    Nx.Notes.GLVersion = Nx.Notes.GLVersion + 1
end

local function ensureHooks()
    if Nx.Notes.GLHooked then return end
    local GL = _G.GatherLite
    if not GL then return end
    Nx.Notes.GLHooked = true
    for _, fn in ipairs({ "InvalidateNodeCache", "SetNodeTracking", "SetIgnored", "LoadTable" }) do
        if type(GL[fn]) == "function" then
            hooksecurefunc(GL, fn, bump)
        end
    end
    if type(GL.On) == "function" then
        pcall(GL.On, GL, "settings:update", bump)
    end
end

local function translate(GL, key)
    local ok, s = pcall(GL.translate, GL, key)
    return ok and s or key
end

local function buildTip(GL, node, object)
    local name = translate(GL, "node." .. object.name)
    local lines = { "|T" .. object.icon .. ":16:16|t " .. name }
    local label = KIND_LABEL[node.type]
    if label then
        lines[#lines + 1] = "|cff999999" .. translate(GL, label) .. "|r"
    end
    local d = node.date
    if type(d) == "table" and d.year and d.month and d.day then
        lines[#lines + 1] = ("|cff999999%04d-%02d-%02d|r"):format(d.year, d.month, d.day)
    end
    lines[#lines + 1] = "|cff80c0ffGatherLite|r"
    return table.concat(lines, "\n")
end

function Nx.Notes:GatherLite(mapId)
    if not Nx.fdb.profile.Notes.GatherLite then return end
    if not self:IsGatherLiteAvailable() then return end
    local GL = _G.GatherLite
    if not GL:IsLoaded() then return end
    ensureHooks()

    local map = Nx.Map:GetMap(1)
    if not map or not mapId then return end

    local usePredef = GL.db.global.usePredefined and true or false
    local sig = usePredef and 1 or 0
    for i = 1, #KINDS do
        if GL:GetNodeTracking("worldmap", KINDS[i]) then
            sig = sig + 2 ^ i
        end
    end
    sig = self.GLVersion * 64 + sig

    if self.GLLastMapId == mapId and self.GLLastSig == sig then return end

    map:ClearIconType("!GLT")
    self.GLLastMapId = mapId
    self.GLLastSig   = sig
    self.PrevGLPins  = 0

    local size = Nx.fdb.profile.Notes.GatherLiteSize or 14
    map:InitIconType("!GLT", "WP", "", size, size)
    map:SetIconTypeChop("!GLT", true)
    map:SetIconTypeLevel("!GLT", 10)
    local gatherAtScale = Nx.db.profile.Map and Nx.db.profile.Map.IconGatherAtScale
    if gatherAtScale then
        map:SetIconTypeAtScale("!GLT", gatherAtScale)
    end

    local count = 0
    for _, kind in ipairs(KINDS) do
        if GL:GetNodeTracking("worldmap", kind) then
            local nodes = GL:GetNodesForMap(kind, mapId)
            for i = 1, #nodes do
                local node = nodes[i]
                if (usePredef or not node.predefined)
                    and not GL:IsIgnored(node.object)
                    and node.posX and node.posY then
                    local object = GL:GetNodeObject(node.object)
                    if object then
                        local wx, wy = Nx.Map:GetWorldPos(mapId, node.posX * 100, node.posY * 100)
                        local pin = wx and wy and map:AddIconPt("!GLT", wx, wy, nil, nil, object.icon)
                        if pin then
                            pin.mapID, pin.MapId = mapId, mapId
                            map:SetIconTip(pin, buildTip(GL, node, object))
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    self.PrevGLPins = count
end

-- Carbonite.Notes | Integrations / RareScanner
-- Pulls POIs straight from RareScanner's data provider canvas.
-- RareScanner exposes RareScannerDataProviderMixin as a global on
-- both retail and classic; on retail the provider is registered to
-- its own private RSWorldMap canvas (so WorldMapFrame:Enumerate
-- PinsByTemplate doesn't see the pins), on classic it's registered
-- to WorldMapFrame. Reading from mixin.owningMap.pinPools works
-- uniformly without depending on which canvas is in use.

local Nx = _G.Nx
if not Nx then return end
Nx.Notes = Nx.Notes or {}

Nx.Notes.RSCache          = Nx.Notes.RSCache or {}
Nx.Notes.RSLastMapId      = nil
Nx.Notes.RSRequestedMapId = nil
Nx.Notes.RSProviderMapId  = nil
Nx.Notes.RSNeedsRefresh   = true

-- Events that can change which RareScanner POIs should appear or
-- how they look. RareScanner's own provider only refreshes when the
-- user has the world map open, so we need to drive a refresh
-- ourselves on these. Some events (e.g. VIGNETTES_UPDATED) don't
-- exist on older classic flavors; pcall around RegisterEvent so a
-- missing event silently no-ops instead of aborting load.
if not Nx.Notes.RSEventsHooked then
    Nx.Notes.RSEventsHooked = true
    local function markDirty()
        Nx.Notes.RSNeedsRefresh = true
    end
    local function tryRegister(event, handler)
        pcall(_G.CarboniteNotes.RegisterEvent, _G.CarboniteNotes, event, handler)
    end
    -- Achievement completion may hide rares (e.g. Glory-of-the-*
    -- tied entities)
    tryRegister("CRITERIA_EARNED", function()
        Nx.Notes:Update()
        Nx.Notes.RSNeedsRefresh = true
    end)
    -- Combat end fires after each kill; cheap and the obvious
    -- "rare just died" trigger
    tryRegister("PLAYER_REGEN_ENABLED", markDirty)
    -- Vignettes appearing/disappearing (most rares are vignetted) —
    -- retail / cata+ only
    tryRegister("VIGNETTES_UPDATED", markDirty)
end

-- Hook on the actual provider instance (NOT the prototype mixin)
-- so that CreateFromMixins-derived classic instances see the hook
-- too. This must run after the provider is registered, so we
-- install it lazily from ResolveRSProvider when we first locate the
-- instance.
local function ensureRSRefreshHook(provider)
    if Nx.Notes.RSRefreshHooked or not provider then return end
    Nx.Notes.RSRefreshHooked = true
    hooksecurefunc(provider, "RefreshAllData", function()
        Nx.Notes.RSNeedsRefresh = true
    end)
end

-- RareScanner's actual provider instance differs by flavor:
--   retail:  RSProvider.AddDataProvider(RareScannerDataProviderMixin)
--            -- passes the global mixin AS the instance, GetMap()
--            -- closes over RSWorldMap
--   classic: local provider = CreateFromMixins(RareScannerDataProviderMixin)
--            WorldMapFrame:AddDataProvider(provider)
--            -- a fresh table is registered; the global mixin is
--            -- just a prototype
-- Cache the instance + canvas across calls; re-resolve if invalidated.
Nx.Notes.RSProviderInstance = Nx.Notes.RSProviderInstance or nil

local function resolveRSProvider()
    local mixin = _G.RareScannerDataProviderMixin
    if not mixin then return nil, nil end

    -- Retail path: the mixin itself is the instance and its
    -- GetMap() returns the private RSWorldMap canvas without ever
    -- using .owningMap.
    if mixin.GetMap then
        local ok, canvas = pcall(mixin.GetMap, mixin)
        if ok and canvas then
            return mixin, canvas
        end
    end

    -- Classic path: scan WorldMapFrame's data providers for an
    -- instance whose RefreshAllData reference matches the mixin's.
    -- CreateFromMixins copies function refs by value, so equality
    -- holds.
    if _G.WorldMapFrame and _G.WorldMapFrame.dataProviders and mixin.RefreshAllData then
        for prov in pairs(_G.WorldMapFrame.dataProviders) do
            if prov.RefreshAllData == mixin.RefreshAllData then
                local ok, canvas = pcall(prov.GetMap, prov)
                if ok and canvas then
                    return prov, canvas
                end
            end
        end
    end

    return nil, nil
end

local function getRSCanvas()
    local instance = Nx.Notes.RSProviderInstance
    if instance then
        local ok, canvas = pcall(instance.GetMap, instance)
        if ok and canvas then return canvas end
        Nx.Notes.RSProviderInstance = nil  -- stale, drop and re-resolve
    end
    local prov, canvas = resolveRSProvider()
    Nx.Notes.RSProviderInstance = prov
    if prov then ensureRSRefreshHook(prov) end
    return canvas
end

-- Returns the actual provider instance to call RefreshAllData on.
local function getRSProvider()
    if not Nx.Notes.RSProviderInstance then
        getRSCanvas()  -- side-effect: populates RSProviderInstance
    end
    return Nx.Notes.RSProviderInstance
end

-- RareScanner 12.1 uses its own RSPinMixin and stores normalized
-- coordinates on pin.x / pin.y. Older MapCanvas-backed builds use
-- normalizedX / normalizedY instead. Values on POIs can be either
-- 0..1 fractions or RareScanner's four-digit integer format.
local function normalizeMapID(value)
    local ok, result = pcall(function()
        return tonumber(value)
    end)
    return ok and result or nil
end

local function normalizeCoord(value)
    local ok, result = pcall(function()
        local number = tonumber(value)
        if not number then return nil end
        if number > 1 then number = number / 10000 end
        if number < 0 or number > 1 then return nil end
        return number
    end)
    return ok and result or nil
end

local function getPinCoords(pin)
    if not pin then return nil, nil end

    -- Prefer x/y: these are the live fields in RareScanner 12.1.
    -- A pooled pin can still carry old normalizedX/Y values, so
    -- choosing those first can project a new-zone POI at an old-zone
    -- position. Fall back to normalizedX/Y for Classic/older builds.
    local x = normalizeCoord(pin.x)
    local y = normalizeCoord(pin.y)
    if x ~= nil and y ~= nil then return x, y end

    return normalizeCoord(pin.normalizedX), normalizeCoord(pin.normalizedY)
end

-- Force a refresh of the RareScanner provider for `targetMapId`.
-- RareScanner 12.1's private RSWorldMap has no SetMapID method.  Set
-- the requested map only for the synchronous refresh, explicitly empty
-- the provider's pools, and then restore RareScanner's original canvas
-- identity.  Calling RefreshAllData directly is compatible with both
-- the private retail provider and the MapCanvas-backed Classic provider;
-- OnMapChanged is not, because third-party lifecycle hooks can reject a
-- synthetic map transition.  Return success so callers never consume a
-- stale previous-zone pool after combat or a provider error.
local function forceRSRefresh(targetMapId)
    local canvas = getRSCanvas()
    local provider = getRSProvider()
    if not provider or not canvas then return false end
    if _G.InCombatLockdown and InCombatLockdown() then return false end

    local originalMapId = canvas.mapID
    local ok = pcall(function()
        canvas.mapID = targetMapId
        if not provider.RefreshAllData then
            error("RareScanner provider has no refresh lifecycle")
        end
        if provider.RemoveAllData then
            provider:RemoveAllData()
        end
        provider:RefreshAllData()
    end)

    -- Keep RareScanner's own canvas identity aligned with the map the
    -- user has open. Its pin pool intentionally remains populated for
    -- targetMapId long enough for Carbonite to harvest synchronously.
    canvas.mapID = originalMapId

    if ok then
        Nx.Notes.RSProviderMapId = targetMapId
    end
    return ok
end

---
-- Update RareScanner icons on the map.
-- @param mapId  Current map ID
--
function Nx.Notes:RareScanner(mapId)
    if not Nx.fdb.profile.Notes.RareScanner then return end
    if not _G.RareScannerDataProviderMixin then return end

    mapId = normalizeMapID(mapId)
    if not mapId or mapId <= 0 then return end

    local map = Nx.Map:GetMap(1)
    if not map then return end

    -- Retire the old layer before touching RareScanner. Provider refreshes
    -- can be blocked in combat or fail while an API is changing; leaving
    -- the previous zone's Carbonite layer alive in either case is what
    -- makes valid old coordinates look like they belong to the new zone.
    if self.RSRequestedMapId ~= mapId then
        self.RSRequestedMapId = mapId
        self.RSNeedsRefresh = true
        self.PrevRSPins = nil
        map:ClearIconType("!RSR")
    end

    local canvas = getRSCanvas()
    if not canvas or not canvas.pinPools then return end

    -- Force a refresh when our cache is stale for this map. Do not
    -- harvest if it fails: the pool can still contain the prior zone.
    local refreshed = false
    if self.RSNeedsRefresh or self.RSLastMapId ~= mapId
        or self.RSProviderMapId ~= mapId then
        if not forceRSRefresh(mapId) then
            self.RSNeedsRefresh = true
            return
        end
        refreshed = true
        self.RSNeedsRefresh = false
    end

    -- Harvest entries from the canvas's pin pools. Each entry is
    -- either a single-rare pin (RSEntityPinTemplate, POI has
    -- mapID/Texture/etc.) or a group pin (RSGroupPinTemplate, POI
    -- is a synthetic group with .POIs[] of sub-rares and no
    -- mapID/Texture of its own). For groups we expand one Carbonite
    -- icon per sub-POI so the killed rare in a cluster doesn't
    -- vanish just because it shares position with live neighbors.
    --
    -- Coordinate source: RareScanner 12.1's live pin.x/pin.y fields
    -- are preferred, with normalizedX/normalizedY as the legacy
    -- fallback. Group children have no individual frames, so their
    -- raw POI coordinates are normalized independently.
    --
    -- Hash includes kill/open/discovery flags so dead-but-still-shown
    -- rares (red->blue texture swap) trigger an icon rebuild.
    -- Each entry has: pin (the user-data we attach to the icon),
    -- poi (data source for tooltip/state), nx/ny (normalized coords),
    -- tex/color (icon visuals — overrides poi.Texture for overlay
    -- spawn-point pins which carry their own colored texture).
    local entries = {}
    local currentHash = 0
    local function consider(pin, poi, nx, ny, tex, color, isGroupRep, groupPOI)
        -- Current RareScanner POIs carry mapID.  Older builds and a few
        -- third-party POI extensions omit it; those pins are still safe to
        -- assign to the requested map because forceRSRefresh emptied the
        -- pool before building this map's data.
        local ownerMapId = poi and normalizeMapID(
            poi.mapID or poi.mapId or poi.MapID or poi.MapId)
        ownerMapId = ownerMapId or mapId
        nx, ny = normalizeCoord(nx), normalizeCoord(ny)

        -- Every emitted icon must have an exact owner zone. Never let a
        -- synthetic group bypass this check; validate each child POI.
        if poi and ownerMapId == mapId and nx ~= nil and ny ~= nil and tex then
            entries[#entries + 1] = {
                pin = pin, poi = poi, nx = nx, ny = ny,
                tex = tex, color = color, mapId = ownerMapId,
                isGroupRep = isGroupRep, groupPOI = groupPOI,
            }
            local stateBits = (poi.isDead and 1 or 0)
                            + (poi.isOpened and 2 or 0)
                            + (poi.isCompleted and 4 or 0)
                            + (poi.isDiscovered and 8 or 0)
            local idForHash = poi.entityID or (poi.POIs and #poi.POIs) or 0
            currentHash = currentHash + nx * 10000 + ny * 100 + idForHash + stateBits * 0.001
        end
    end

    for _, template in ipairs({"RSEntityPinTemplate", "RSGroupPinTemplate"}) do
        local pool = canvas.pinPools[template]
        if pool then
            for pin in pool:EnumerateActive() do
                local poi = pin.POI
                -- Retail RareScanner's RSPinMixin stores normalized
                -- coords on pin.x / pin.y (not the Blizzard-standard
                -- pin.normalizedX/Y). Classic RS uses
                -- MapCanvasPinMixin which sets normalizedX/Y. Try
                -- both so dragon-glyph pins (retail-only path)
                -- render too.
                local nx, ny = getPinCoords(pin)
                if poi then
                    if poi.isGroup and poi.POIs then
                        -- Render each current-map sub-rare at its OWN
                        -- coords (which differ slightly per
                        -- rare — that's why RareScanner clustered
                        -- them in the first place). This produces
                        -- a visible cluster of distinct icons
                        -- matching the Bliz appearance, instead of
                        -- a single stacked obscured icon. The group
                        -- pin is still attached as user data on
                        -- every sub-icon so mouseover on any of
                        -- them triggers the RS group popup.
                        for _, sub in ipairs(poi.POIs) do
                            consider(pin, sub, sub.x, sub.y,
                                sub.Texture, "FFFFFF", true, poi)
                        end
                    else
                        consider(pin, poi, nx, ny, poi.Texture, "FFFFFF", false)
                    end
                end
            end
        end
    end

    -- Overlay pins are RareScanner's "show all spawn points" markers,
    -- created when the user clicks an entity icon. Each overlay
    -- wraps a parent entity pin via .pin and has its own normalizedX/Y
    -- for the spawn location, and its own colored Texture
    -- (vertex-tinted to identify which entity it belongs to). Skip
    -- overlays sitting on top of their parent entity pin.
    do
        local pool = canvas.pinPools["RSOverlayTemplate"]
        if pool then
            for pin in pool:EnumerateActive() do
                local parent = pin.pin
                -- Entity overlays point at the source pin; 12.1 group
                -- overlays can point directly at a child POI table.
                local poi = parent and (parent.POI or parent)
                local nx, ny = getPinCoords(pin)
                local parentX, parentY = getPinCoords(parent)
                if poi and parent and nx ~= nil and ny ~= nil
                    and (nx ~= parentX or ny ~= parentY) then
                    local tex = pin.Texture and pin.Texture.GetTexture and pin.Texture:GetTexture()
                    local color = "FFFFFF"
                    if pin.Texture and pin.Texture.GetVertexColor then
                        local r, g, b = pin.Texture:GetVertexColor()
                        if r and g and b then
                            color = _G.CreateColor(r, g, b):GenerateHexColor()
                        end
                    end
                    -- Pass the parent entity pin as user-data so
                    -- click / mouseover routes to the entity (not
                    -- the overlay marker).
                    consider(parent, poi, nx, ny, tex, color)
                end
            end
        end
    end

    -- Skip rebuild if nothing changed.
    local cacheKey = mapId .. "_RS"
    if not refreshed and self.RSCache[cacheKey] == currentHash
        and self.RSLastMapId == mapId
        and self.PrevRSPins == #entries then
        return
    end

    map:ClearIconType("!RSR")
    self.RSCache[cacheKey] = currentHash
    self.RSLastMapId       = mapId
    self.PrevRSPins        = #entries

    map:InitIconType("!RSR", "WP", "",
        Nx.fdb.profile.Notes.RareScannerSize or 32,
        Nx.fdb.profile.Notes.RareScannerSize or 32)
    map:SetIconTypeChop("!RSR", true)
    map:SetIconTypeNoDockMinimap("!RSR", true)
    map:SetIconTypeLevel("!RSR", 20)

    for _, e in ipairs(entries) do
        local wx, wy = Nx.Map:GetWorldPos(e.mapId, e.nx * 100, e.ny * 100)
        local rsnote = wx and wy
            and map:AddIconPt("!RSR", wx, wy, nil, e.color or "FFFFFF", e.tex)
        if rsnote then
            rsnote.mapID, rsnote.MapId = e.mapId, e.mapId
            local tip
            if e.isGroupRep then
                -- Plain-text fallback tooltip listing the group's
                -- sub-rares — the hover handler in NxMap will also
                -- trigger RS's own native group popup if it can position
                -- it near the cursor.
                local groupPOI = e.groupPOI or e.poi
                local lines = { ("|cffff8080Group (%d):|r"):format(groupPOI.POIs and #groupPOI.POIs or 0) }
                for _, sub in ipairs(groupPOI.POIs or {}) do
                    lines[#lines + 1] = "  " .. (sub.name or "?")
                end
                tip = table.concat(lines, "\n")
            else
                tip = e.poi.name
            end
            map:SetIconTip(rsnote, tip)
            map:SetIconUserData(rsnote, e.pin)
        end
    end
end

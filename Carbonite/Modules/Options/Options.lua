-- Carbonite | Modules / Options
-- New owner of option-page registration. Replaces the boilerplate
-- around AceConfig that was scattered through NxOptions.lua /
-- Nx:SetupConfig / Nx:AddToConfig.
--
-- Modules now register their own options via this module:
--
--   Carbonite.Modules.Options:Register("Map", function()
--     return { type = "group", args = { ... } }
--   end, { displayName = "Maps", order = 2 })
--
-- Underneath we still call AceConfig + AceConfigDialog, but the
-- caller does not have to know that and we get a single place to
-- inject our profile tab, About tab, etc.

local Carbonite = _G.Carbonite
local Module = Carbonite.Core.Module

local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigReg    = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions    = LibStub("AceDBOptions-3.0")

local Options = Module:New("Options", {
    defaults = {
        profile = {
            Options = {
                LastOpenedPanel = nil,
            },
        },
    },
})

-- Internal registry. Key = stable id ("Map", "Quests"); value =
-- { provider = fn, displayName = string, order = number }.
local registry = {}

-- Root group: built once during OnEnable. Lazily resolves each
-- registered provider so modules can register before AceDB exists.
local function buildRootGroup()
    local args = {
        about = {
            order = 1,
            type  = "group",
            name  = "About",
            args  = {
                blurb = {
                    type = "description",
                    name = ("|cffc0c0ffCarbonite|r  -  version |cffd700ff%s|r\n\nFull featured map and questing addon.\n")
                            :format(Carbonite.VERSION_STRING or "dev"),
                    order = 1,
                },
            },
        },
    }

    -- Sort by user-supplied order then displayName for stability.
    local ids = {}
    for id in pairs(registry) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b)
        local ra, rb = registry[a], registry[b]
        if ra.order ~= rb.order then return (ra.order or 100) < (rb.order or 100) end
        return (ra.displayName or a) < (rb.displayName or b)
    end)

    for _, id in ipairs(ids) do
        local entry = registry[id]
        local ok, table_ = pcall(entry.provider)
        if ok and type(table_) == "table" then
            args[id] = table_
            args[id].order = entry.order or 100
            args[id].name  = entry.displayName or id
        elseif Carbonite.Core.Logger then
            Carbonite.Core.Logger:Get("Options"):error("provider for %s failed: %s", id, tostring(table_))
        end
    end

    -- Profiles tab (every AceAddon addon should expose this).
    if Carbonite.db then
        args.profiles = AceDBOptions:GetOptionsTable(Carbonite.db)
        args.profiles.order = 1000
    end

    return {
        type = "group",
        name = "Carbonite",
        childGroups = "tab",
        args = args,
    }
end

function Options:Register(id, provider, opts)
    opts = opts or {}
    if type(provider) ~= "function" then
        local table_ = provider
        provider = function() return table_ end
    end
    registry[id] = {
        provider    = provider,
        displayName = opts.displayName or id,
        order       = opts.order or 100,
    }
end

function Options:Open(panelId)
    AceConfigDialog:Open("Carbonite")
    if panelId then
        AceConfigDialog:SelectGroup("Carbonite", panelId)
    end
end

function Options:Refresh()
    AceConfigReg:NotifyChange("Carbonite")
end

function Options:OnEnable()
    AceConfig:RegisterOptionsTable("Carbonite", buildRootGroup)
    self.frame, self.panelID = AceConfigDialog:AddToBlizOptions("Carbonite", "Carbonite")

    Carbonite.Core.SlashCommands:Register("opts", function() self:Open() end, "open options panel")
    Carbonite.Core.SlashCommands:Register("options", function() self:Open() end, "open options panel")
    Carbonite.Core.SlashCommands:Register("config", function() self:Open() end, "open options panel")

    -- Mirror onto legacy namespace so old `Nx.Opts:Open` calls keep
    -- working until those callers are migrated.
    Carbonite.Opts = Carbonite.Opts or {}
    Carbonite.Opts.Open    = function(_, panel) self:Open(panel) end
    Carbonite.Opts.Refresh = function() self:Refresh() end
end

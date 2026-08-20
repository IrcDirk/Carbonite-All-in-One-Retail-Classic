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

local function unavailableGroup(name, reason)
    return {
        type = "group",
        name = name,
        args = {
            unavailable = {
                type = "description",
                name = "These settings are not available yet. Reopen the options window after Carbonite finishes loading.\n\n"
                    .. tostring(reason or "The options provider did not return a settings group."),
                order = 1,
                width = "full",
            },
        },
    }
end

-- Root group: built lazily each time AceConfig asks for the table so
-- providers registered after OnEnable (e.g. by plugins loaded later)
-- still appear. The legacy NxOptions section provides a "Main" tab
-- with version blurb and credits; if no module has registered "Main"
-- by the time the panel opens, a small default About tab is rendered
-- instead.
local function buildRootGroup()
    local args = {}
    if not registry["Main"] then
        args.about = {
            order = 0,
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
        }
    end

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
        if not ok or type(table_) ~= "table" or table_.type ~= "group"
            or type(table_.args) ~= "table" then
            local reason = ok and "The options provider returned an invalid settings group." or table_
            table_ = unavailableGroup(entry.displayName or id, reason)
            if Carbonite.Core.Logger then
                pcall(function()
                    Carbonite.Core.Logger:Get("Options"):error("provider for %s failed: %s", id, tostring(reason))
                end)
            end
        end
        args[id] = table_
        args[id].order = entry.order or 100
        args[id].name  = entry.displayName or id
    end

    -- Profiles options should not prevent every other category from rendering
    -- if the saved-variable database has not completed initialization yet.
    if Carbonite.db then
        local ok, profiles = pcall(AceDBOptions.GetOptionsTable, AceDBOptions, Carbonite.db)
        args.profiles = ok and type(profiles) == "table" and profiles
            or unavailableGroup("Profiles", profiles)
        args.profiles.order = 1000
    end

    return {
        type = "group",
        name = "Carbonite",
        -- Top-level sections must stay in AceGUI's scrollable navigation tree.
        -- Tabs remain available inside individual sections where appropriate.
        childGroups = "tree",
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

    -- The Blizzard category can already exist when legacy or plugin sections
    -- register. Invalidate AceConfig's cached root so a panel opened during
    -- early startup cannot remain stuck with an empty options table.
    if self._rootRegistered then
        AceConfigReg:NotifyChange("Carbonite")
    end
end

function Options:Open(panelId)
    if self._rootRegistered then
        self:Refresh()
    end
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
    self._rootRegistered = true
    self.frame, self.panelID = AceConfigDialog:AddToBlizOptions("Carbonite", "Carbonite")

    -- The AceConfigDialog default (700 wide) is too narrow for the
    -- multi-control rows on the font pages. Widen the default ONCE here;
    -- SetDefaultSize overwrites the status size, so it must not run on
    -- every Open or it would clobber the user's manual resize (which
    -- AceConfigDialog otherwise remembers across opens).
    if AceConfigDialog.SetDefaultSize then
        AceConfigDialog:SetDefaultSize("Carbonite", 960, 600)
    end

    Carbonite.Core.SlashCommands:Register("opts", function() self:Open() end, "open options panel")
    Carbonite.Core.SlashCommands:Register("options", function() self:Open() end, "open options panel")
    Carbonite.Core.SlashCommands:Register("config", function() self:Open() end, "open options panel")

    -- Mirror onto legacy namespace so old `Nx.Opts:Open` calls keep
    -- working until those callers are migrated.
    Carbonite.Opts = Carbonite.Opts or {}
    Carbonite.Opts.Open    = function(_, panel) self:Open(panel) end
    Carbonite.Opts.Refresh = function() self:Refresh() end

    -- Providers may have registered before this module was enabled. Force the
    -- first Blizzard-panel render to query the complete live registry.
    self:Refresh()
end

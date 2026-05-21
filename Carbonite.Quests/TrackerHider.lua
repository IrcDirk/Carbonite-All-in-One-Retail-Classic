-- Carbonite.Quests | TrackerHider
-- Hides Blizzard's quest tracker frames (ObjectiveTrackerFrame,
-- WatchFrame, QuestWatchFrame) when the user has the Carbonite
-- tracker enabled. Also owns the EditMode hooks that suspend
-- hiding while the user is editing layouts, and the larger
-- ToggleQuestLog overrides that route Blizzard panel state through
-- Carbonite's map. Lifted from NxQuest.lua to keep the engine file
-- focused.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Quest', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Quest = Nx.Quest or {}

-- WoW globals aliased as locals for hot-path speed.
local InCombatLockdown = _G.InCombatLockdown or _G.InCombatLockdown
local UnitName = _G.UnitName or _G.UnitName

-- BLIZZARD TRACKER HIDING (Retail + Classic + Anniversary + MoP Classic)
-- Checked = hide; Unchecked = show.
-------------------------------------------------------------------------------

local NX_TRACKER_FRAMES = {
    "ObjectiveTrackerFrame", -- Retail / modern
    "WatchFrame",            -- Classic / MoP Classic / Anniversary
    "QuestWatchFrame",       -- Fallback (some UI variants)
}

local function NxTracker_IsProtectedAndLockedDown(frame)
    return frame and frame.IsProtected and frame:IsProtected() and InCombatLockdown()
end

function Nx.Quest:TrackerHider_Init()
    if self._trackerHider then
        return
    end

    local hiddenParent = CreateFrame("Frame", nil, UIParent)
    hiddenParent:Hide()

    self._trackerHider = {
        hiddenParent = hiddenParent,
        hooked = {},
        orig = {},
        pending = false,
    }

    local driver = CreateFrame("Frame", nil, UIParent)
    self._trackerHider.driver = driver

    driver:RegisterEvent("PLAYER_LOGIN")
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("PLAYER_REGEN_ENABLED")
    driver:RegisterEvent("ADDON_LOADED")

    driver:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" and not self._trackerHider.pending then
            return
        end
        self._trackerHider.pending = false
        self:TrackerHider_Apply()
    end)
end

function Nx.Quest:TrackerHider_ShouldHide()
    -- While Blizzard's Edit Mode is open the user almost certainly wants
    -- to position Blizzard's tracker frame, so let it show even if our
    -- "hide blizz tracker" preference is on. We restore the hide on
    -- EditMode exit via the EditMode.Enter / EditMode.Exit hooks.
    if self._editModeActive then
        return false
    end
    local qProfile = Nx.qdb and Nx.qdb.profile
    local enabled = qProfile and qProfile.Quest and qProfile.Quest.Enable
    local watchProfile = qProfile and qProfile.QuestWatch
    return enabled and watchProfile and watchProfile.HideBlizz == true
end

-- Hook EditMode events so TrackerHider yields while the user is
-- positioning frames. Available on retail and Cata Classic onward;
-- the EventRegistry / EditModeManagerFrame check makes this a no-op
-- on flavors without it (Classic Era, TBC).
function Nx.Quest:TrackerHider_BindEditMode()
    if self._editModeBound then return end
    if not (EventRegistry and EditModeManagerFrame) then return end
    self._editModeBound = true
    EventRegistry:RegisterCallback("EditMode.Enter", function()
        Nx.Quest._editModeActive = true
        Nx.Quest:TrackerHider_Apply()
    end)
    EventRegistry:RegisterCallback("EditMode.Exit", function()
        Nx.Quest._editModeActive = false
        Nx.Quest:TrackerHider_Apply()
    end)
end

function Nx.Quest:TrackerHider_CaptureOriginal(frame, key)
    local h = self._trackerHider
    if not h or h.orig[key] then
        return
    end

    local mouseEnabled = true
    if frame.IsMouseEnabled then
        mouseEnabled = frame:IsMouseEnabled()
    end

    h.orig[key] = {
        parent = frame:GetParent(),
        alpha = frame:GetAlpha(),
        mouseEnabled = mouseEnabled,
    }
end

function Nx.Quest:TrackerHider_SetVisible(frame, key, visible)
    local h = self._trackerHider
    if not h or not frame then
        return
    end

    if NxTracker_IsProtectedAndLockedDown(frame) then
        h.pending = true
        return
    end

    self:TrackerHider_CaptureOriginal(frame, key)
    local orig = h.orig[key]

    if visible then
        frame:SetParent((orig and orig.parent) or UIParent)
        frame:SetAlpha((orig and orig.alpha) or 1)
        if frame.EnableMouse then
            frame:EnableMouse(orig and orig.mouseEnabled ~= false or true)
        end
        frame:Show()
        return
    end

    frame:SetParent(h.hiddenParent)
    frame:SetAlpha(0)
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
    frame:Hide()
end

function Nx.Quest:TrackerHider_HookFrame(name)
    local h = self._trackerHider
    if not h or h.hooked[name] then
        return
    end

    local frame = _G[name]
    if not frame or not frame.HookScript then
        return
    end

    h.hooked[name] = true
    frame:HookScript("OnShow", function(f)
        if self:TrackerHider_ShouldHide() then
            self:TrackerHider_SetVisible(f, name, false)
        end
    end)
end

function Nx.Quest:TrackerHider_Apply()
    if not self._trackerHider then
        self:TrackerHider_Init()
    end

    -- Lazy-bind EditMode events; safe to call multiple times.
    self:TrackerHider_BindEditMode()

    local hide = self:TrackerHider_ShouldHide()

    for i = 1, #NX_TRACKER_FRAMES do
        local name = NX_TRACKER_FRAMES[i]
        local frame = _G[name]
        if frame then
            self:TrackerHider_HookFrame(name)
            self:TrackerHider_SetVisible(frame, name, not hide)
        end
    end
end

function Nx.Quest:Init()


    self.Enabled = Nx.qdb.profile.Quest.Enable
    if not self.Enabled then

--        Nx.Quest = nil
        Nx.Quests = nil    -- Data
        -- Ensure the Blizzard tracker is not left hidden when the quest module is disabled.
        self:TrackerHider_Apply()

        return
    end

    -- Keep Blizzard tracker visibility in sync with the profile toggle (cross-version safe).
    self:TrackerHider_Apply()


    self.GOpts = Nx.db.profile

    if Nx.qdb.profile.QuestWatch.BlizzModify then
--        if not GetCVarBool ("advancedWatchFrame") then

--            SetCVar ("questFadingDisable", 1)    --V4 gone
            SetCVar ("autoQuestProgress", 0)
            SetCVar ("autoQuestWatch", 0)
--            SetCVar ("advancedWatchFrame", 1)
--            SetCVar ("watchFrameIgnoreCursor", 0)
--        end
    else
        SetCVar ("autoQuestProgress", 1)
        SetCVar ("autoQuestWatch", 1)
    end

    -- DEBUG
--    self.OldSelectQuestLogEntry = SelectQuestLogEntry
--    SelectQuestLogEntry = Nx.Quest.SelectQuestLogEntry

    -- Force it to create/enable and then we disable
    -- Use QuestMapFrame for retail, QuestLogFrame for classic
    local questFrame = QuestMapFrame or QuestLogFrame
    if questFrame then
        GetUIPanelWidth(questFrame)
        questFrame:SetAttribute("UIPanelLayout-enabled", false)
    end

    if QuestLogDetailFrame then    -- Patch 3.2
        GetUIPanelWidth(QuestLogDetailFrame)
        QuestLogDetailFrame:SetAttribute("UIPanelLayout-enabled", false)
    end

    local Map = Nx.Map

    self.QIds = {}                    -- Our quests by id
    self.QIdsNew = {}                -- Time stamp of getting a new quest. [Id] = time()

    self.Tracking = {}
    self.Sorted = {}

    self.CurQ = {}                    -- Current quests (including gotos)
    self.RealQ = {}                -- Real Blizzard quests
    self.RealQEntries = 0
    self.PartyQ = {}                -- Party quests

    self.IdToCurQ = {}

    self.HeaderExpanded = {}    -- Blizzard quest headers we expanded
    self.HeaderHide = {}            -- Names of quest headers to hide

    self.RcvPlyrLast = "None"
    self.RcvCnt = 0
    self.RcvTotal = 0
    self.FriendQuests = {}

    self.IconTracking = {}
    self.QInit = false

    self:CalcWatchColors()

    self.TagNames = {
        ["Group"] = "+",
        ["Legendary"] = "L",
        ["Heroic"] = "H",
        ["Account"] = "A",
        ["Raid"] = "R",
    }

    self.PerColors = {
        "|cffc00000", "|cffc03000", "|cffc06000", "|cffc09000", "|cffc0c000", "|cff90c000", "|cff60c000", "|cff30c000", "|cff00c000",
    }

    self.CapturePlyrData = {}

    self.CapFactionAbr = {
        ["Argent Crusade"] = 1,
        ["Argent Dawn"] = 2,
        ["Ashtongue Deathsworn"] = 3,
        ["Bloodsail Buccaneers"] = 4,
        ["Booty Bay"] = 5,
        ["Brood of Nozdormu"] = 6,
        ["Cenarion Circle"] = 7,
        ["Cenarion Expedition"] = 8,
        ["Darkmoon Faire"] = 9,
        ["Darkspear Trolls"] = 10,
        ["Darnassus"] = 11,
        ["Everlook"] = 12,
        ["Exodar"] = 13,
        ["Explorers' League"] = 14,
        ["Frenzyheart Tribe"] = 15,
        ["Frostwolf Clan"] = 16,
        ["Gadgetzan"] = 17,
        ["Gelkis Clan Centaur"] = 18,
        ["Gnomeregan Exiles"] = 19,
        ["Honor Hold"] = 20,
        ["Hydraxian Waterlords"] = 21,
        ["Ironforge"] = 22,
        ["Keepers of Time"] = 23,
        ["Kirin Tor"] = 24,
        ["Knights of the Ebon Blade"] = 25,
        ["Kurenai"] = 26,
        ["Lower City"] = 27,
        ["Magram Clan Centaur"] = 28,
        ["Netherwing"] = 29,
        ["Ogri'la"] = 30,
        ["Orgrimmar"] = 31,
        ["Ratchet"] = 32,
        ["Ravenholdt"] = 33,
        ["Sha'tari Skyguard"] = 34,
        ["Shattered Sun Offensive"] = 35,
        ["Shen'dralar"] = 36,
        ["Silvermoon City"] = 37,
        ["Silverwing Sentinels"] = 38,
        ["Sporeggar"] = 39,
        ["Stormpike Guard"] = 40,
        ["Stormwind"] = 41,
        ["Syndicate"] = 42,
        ["The Aldor"] = 43,
        ["The Consortium"] = 44,
        ["The Defilers"] = 45,
        ["The Frostborn"] = 46,
        ["The Hand of Vengeance"] = 47,
        ["The Kalu'ak"] = 48,
        ["The League of Arathor"] = 49,
        ["The Mag'har"] = 50,
        ["The Oracles"] = 51,
        ["The Scale of the Sands"] = 52,
        ["The Scryers"] = 53,
        ["The Sha'tar"] = 54,
        ["The Silver Covenant"] = 55,
        ["The Sons of Hodir"] = 56,
        ["The Taunka"] = 57,
        ["The Violet Eye"] = 58,
        ["The Wyrmrest Accord"] = 59,
        ["Thorium Brotherhood"] = 60,
        ["Thrallmar"] = 61,
        ["Thunder Bluff"] = 62,
        ["Timbermaw Hold"] = 63,
        ["Tranquillien"] = 64,
        ["Undercity"] = 65,
        ["Valiance Expedition"] = 66,
        ["Warsong Offensive"] = 67,
        ["Warsong Outriders"] = 68,
        ["Wildhammer Clan"] = 69,
        ["Wintersaber Trainers"] = 70,
        ["Zandalar Tribe"] = 71,
    }

    self.DailyTypes = {
        ["1"] = L["Daily"],
        ["2"] = L["Daily Dungeon"],
        ["3"] = L["Daily Heroic"],
    }
    self.Reputations = {
        ["A"] = L["Aldor"],
        ["S"] = L["Scryer"],
        ["c"] = L["Consortium"],
        ["e"] = L["Cenarion Expedition"],
        ["g"] = L["Sha'tari Skyguard"],
        ["k"] = L["Keepers of Time"],
        ["l"] = L["Lower City"],
        ["n"] = L["Netherwing"],
        ["o"] = L["Ogri'la"],
        ["s"] = L["Shattered Sun Offensive"],
        ["t"] = L["Sha'tar"],
        ["z"] = L["Honor Hold/Thrallmar"],
        -- WotLK
        ["C"] = L["Argent Crusade"],
        ["E"] = L["Explorers' League"],
        ["F"] = L["Frenzyheart Tribe"],
        ["f"] = L["The Frostborn"],
        ["H"] = L["Horde Expedition"],
        ["K"] = L["The Kalu'ak"],
        ["i"] = L["Kirin Tor"],
        ["N"] = L["Knights of the Ebon Blade"],
        ["O"] = L["The Oracles"],
        ["h"] = L["The Sons of Hodir"],
        ["a"] = L["Alliance Vanguard"],
        ["V"] = L["Valiance Expedition"],
        ["W"] = L["Warsong Offensive"],
        ["w"] = L["The Wyrmrest Accord"],
        ["I"] = L["The Silver Covenant"],        -- Patch 3.1
        ["R"] = L["The Sunreavers"],                -- Patch 3.1
    }
    self.Requirements = {
--        ["1"] = L["Alliance"],        -- Already stripped out by quest side removal code
--        ["2"] = L["Horde"],
        ["oH"] = L["Ogri'la Honored"],
        ["H350"] = L["Herbalism 350"],
        ["M350"] = L["Mining 350"],
        ["S350"] = L["Skining 350"],
        ["G"] = L["Gathering Skill"],
        ["nF"] = L["Netherwing Friendly"],
        ["nH"] = L["Netherwing Honored"],
        ["nRA"] = L["Netherwing Revered (Aldor)"],
        ["nRS"] = L["Netherwing Revered (Scryer)"],
        -- WotLK
        ["hH"] = L["The Sons of Hodir Honored"],
        ["hR"] = L["The Sons of Hodir Revered"],
        ["J375"] = L["Jewelcrafting 375"],
        ["C"] = L["Cooking"],
        ["F"] = L["Fishing"],
    }

    self.DailyIds = {
        -- Type ^ Reward (Gold*100+Silver) ^ Rep letter/Rep amount (000) ^ Requirement
        -- Req - H herb, M mine, S skin, G any gather, F friendly, H honored, R revered

        -- Honor Hold/Thrallmar
        [10106] = "1^70^z150",        -- Hellfire Fortifications
        [10110] = "1^70^z150",        -- Hellfire Fortifications
        -- Ogri'la
        [11023] = "1^1199^o500g500",    -- Bomb Them Again!
        [11066] = "1^1199^o350g350",    -- Wrangle More Aether Rays!
        [11080] = "1^910^o350",        -- The Relic's Emanation
        [11051] = "1^1199^o350^oH",    -- Banish More Demons
        -- Netherwing
        [11020] = "1^1199^n250",    -- A Slow Death
        [11035] = "1^1199^n250",    -- The Not-So-Friendly Skies...
        [11049] = "1^1828^n350",    -- The Great Netherwing Egg Hunt
        [11015] = "1^1199^n250",    -- Netherwing Crystals
        [11017] = "1^1199^n250^H350",    -- Netherdust Pollen (Herbalist)
        [11018] = "1^1199^n250^M350",    -- Nethercite Ore (Miner)
        [11016] = "1^1199^n250^S350",    -- Nethermine Flayer Hide (Skinner)
        [11055] = "1^1199^n350^nF",    -- The Booterang: A Cure For The Common Worthless Peon
        [11076] = "1^1828^n350^nF",    -- Picking Up The Pieces...
        [11086] = "1^1199^n500^nH",    -- Disrupting the Twilight Portal
        [11101] = "1^1828^n500^nRA",    -- The Deadliest Trap Ever Laid (Aldor)
        [11097] = "1^1828^n500^nRS",    -- The Deadliest Trap Ever Laid (Scryer)
        -- Shattered Sun
        [11514] = "1^1010^s250",    -- Maintaining the Sunwell Portal
        [11515] = "1^1199^s250",    -- Blood for Blood
        [11516] = "1^1010^s250",    -- Blast the Gateway
        [11521] = "1^1388^s350",    -- Rediscovering Your Roots
        [11523] = "1^910^s150",        -- Arm the Wards!
        [11525] = "1^910^s150",        -- Further Conversions
        [11533] = "1^910^s150",        -- The Air Strikes Must Continue
        [11536] = "1^1199^s250",    -- Don't Stop Now....
        [11537] = "1^1010^s250",    -- The Battle Must Go On
        [11540] = "1^1199^s250",    -- Crush the Dawnblade
        [11541] = "1^1199^s250",    -- Disrupt the Greengill Coast
        [11543] = "1^759^s250",        -- Keeping the Enemy at Bay
        [11544] = "1^1828^s350",    -- Ata'mal Armaments
        [11546] = "1^1199^s250",    -- Open for Business
        [11547] = "1^1199^s250",    -- Know Your Ley Lines
        [11548] = "1^-1000^s150",    -- Your Continued Support
        [11877] = "1^1010^s250",    -- Sunfury Attack Plans
        [11880] = "1^910^s250",        -- The Multiphase Survey
        [11875] = "1^1639^s250^G",    -- Gaining the Advantage
        -- Skettis
        [11008] = "1^1199^g350",    -- Fires Over Skettis
        [11085] = "1^910^g150",        -- Escape from Skettis

        -- WotLK Borean Tundra
        [11940] = "1^470^w250",        -- Drake Hunt
        [11945] = "1^500^K500",        -- Preparing for the Worst
        [13414] = "1^740^w250",        -- Aces High!
        -- WotLK Howling Fjord
        [11153] = "1^470^a 38V250^1",    -- Break the Blockade
        [11391] = "1^470^E250^1",    -- Steel Gate Patrol
        [11472] = "1^470^K500",        -- The Way to His Heart...
        -- WotLK Dragonblight
        [11960] = "1^500^K500",        -- Planning for the Future
        [12372] = "1^560^w250",        -- Defending Wyrmrest Temple
        -- WotLK Grizzly Hills
        [12437] = "1^560^^1",        -- Riding the Red Rocket
        [12444] = "1^560^a 38V250^1",    -- Blackriver Skirmish
        [12316] = "1^560^^1",        -- Keep Them at Bay!
        [12289] = "1^560^a 38V250^1",    -- Kick 'Em While They're Down
        [12296] = "1^560^a 38V250^1",    -- Life or Death
        [12268] = "1^560^^1",        -- Pieces Parts
        [12244] = "1^560^^1",        -- Shredder Repair
        [12323] = "1^560^^1",        -- Smoke 'Em Out
        [12314] = "1^560^^1",        -- Down With Captain Zorna!
        [12038] = "1^986",        -- Seared Scourge
        [12433] = "1^560",        -- Seeking Solvent
        [12170] = "1^560^H250^2",    -- Blackriver Brawl
        [12284] = "1^560^W250^2",    -- Keep 'Em on Their Heels
        [12280] = "1^560^W250^2",    -- Making Repairs
        [12288] = "1^560^W250^2",    -- Overwhelmed!
        [12270] = "1^560^W250^2",    -- Shred the Alliance
        [12315] = "1^560^^2",        -- Crush Captain Brightwater!
        [12324] = "1^560^^2",        -- Smoke 'Em Out
        [12317] = "1^560^^2",        -- Keep Them at Bay
        [12432] = "1^560^^2",        -- Riding the Red Rocket
        -- WotLK Zul'Drak
        [12501] = "1^620^C250",        -- Troll Patrol
        [12541] = "1^158^C 75",        -- Troll Patrol: The Alchemist's Apprentice
        [12502] = "1^158^C 75",        -- Troll Patrol: High Standards
        [12564] = "1^158^C 75",        -- Troll Patrol: Something for the Pain
        [12588] = "1^158^C 75",        -- Troll Patrol: Can You Dig It?
        [12568] = "1^158^C 75",        -- Troll Patrol: Done to Death
        [12509] = "1^158^C250",        -- Troll Patrol: Intestinal Fortitude
        [12591] = "1^158^C 75",        -- Troll Patrol: Throwing Down
        [12585] = "1^158^C 75",        -- Troll Patrol: Creature Comforts
        [12519] = "1^158^C 25",        -- Troll Patrol: Whatdya Want, a Medal?
        [12594] = "1^158^C 75",        -- Troll Patrol: Couldn't Care Less
        [12604] = "1^1860^C350",    -- Congratulations!
        -- WotLK Sholazar Basin
        [12704] = "1^650^O250",        -- Appeasing the Great Rain Stone
        [12761] = "1^1360^O350",    -- Mastery of the Crystals
        [12762] = "1^1360^O350",    -- Power of the Great Ones
        [12705] = "1^1360^O350",    -- Will of the Titans
        [12735] = "1^740^O500",        -- A Cleansing Song
        [12737] = "1^740^O250",        -- Song of Fecundity
        [12736] = "1^740^O250",        -- Song of Reflection
        [12726] = "1^740^O500",        -- Song of Wind and Water
        [12689] = "1^330^O***",        -- Hand of the Oracles (one time rep bonus)
        [12582] = "1^330^F***",        -- Frenzyheart Champion (one time rep bonus)
        [12702] = "1^650^F500",        -- Chicken Party!
        [12703] = "1^1360^F350",    -- Kartak's Rampage
        [12760] = "1^1360^F350",    -- Secret Strength of the Frenzyheart
        [12759] = "1^1360^F350",    -- Tools of War
        [12734] = "1^740^F500",        -- Rejek: First Blood
        [12758] = "1^740^F500",        -- A Hero's Headgear
        [12741] = "1^740^F500",        -- Strength of the Tempest (check rep??)
        [12732] = "1^740^F500",        -- The Heartblood's Strength
        -- WotLK Icecrown
        [13309] = "1^740^V250^1",    -- Assault by Air
        [13284] = "1^740^V250^1",    -- Assault by Ground
        [13336] = "1^740^V250^1",    -- Blood of the Chosen
        [13323] = "1^740^^1",        -- Drag and Drop
        [13344] = "1^740^^1",        -- Not a Bug
        [13322] = "1^740^^1",        -- Retest Now
        [13404] = "1^740^^1",        -- Static Shock Troops: the Bombardment
        [13300] = "1^740^C250^1",    -- Slaves to Saronite
        [13289] = "1^740^^1",        -- That's Abominable!
        [13292] = "1^740^^1",        -- The Solution Solution
        [13333] = "1^740^^1",        -- Capture More Dispatches
        [13297] = "1^2220^^1",        -- Neutralizing the Plague
        [13350] = "1^2220^^1",        -- No Rest For The Wicked
        [13280] = "1^740^V250^1",    -- King of the Mountain
        [13233] = "1^740^^1",        -- No Mercy!
        [13310] = "1^740^W250^2",    -- Assault by Air
        [13301] = "1^740^W250^2",    -- Assault by Ground
        [13330] = "1^740^W250^2",    -- Blood of the Chosen
        [13353] = "1^740^^2",        -- Drag and Drop
        [13365] = "1^740^^2",        -- Not a Bug
        [13357] = "1^740^^2",        -- Retest Now
        [13406] = "1^740^^2",        -- Riding the Wavelength: The Bombardment
        [13302] = "1^740^C250^2",    -- Slaves to Saronite
        [13376] = "1^740^^2",        -- Total Ohmage: The Valley of Lost Hope!
        [13276] = "1^740^^2",        -- That's Abominable!
        [13331] = "1^740^W250^2",    -- Keeping the Alliance Blind
        [13261] = "1^740^^2",        -- Volatility
        [13281] = "1^2220^^2",        -- Neutralizing the Plague
        [13368] = "1^2220^^2",        -- No Rest For The Wicked
        [13283] = "1^740^W250^2",    -- King of the Mountain
        [13234] = "1^740^^2",        -- Make Them Pay!
        [12813] = "1^740^N250",        -- From Their Corpses, Rise!
        [12838] = "1^740^N250",        -- Intelligence Gathering
        [12995] = "1^740^N250",        -- Leave Our Mark
        [12815] = "1^740^N250",        -- No Fly Zone
        [13069] = "1^740^N250",        -- Shoot 'Em Up
        [13071] = "1^370^N250",        -- Vile Like Fire!
        -- WotLK Icecrown Argent Tournament
--        [13681] = "1^740",        -- A Chip Off the Ulduar Block (OLD)
--        [13627] = "1^740",        -- Jack Me Some Lumber (OLD)
        [13625] = "1^580^I250",        -- Learning The Reins (A)
        [13677] = "1^580^R250",        -- Learning The Reins (H)
        [13671] = "1^580^I250",        -- Training In The Field (A)
        [13676] = "1^580^R250",        -- Training In The Field (H)
        [13666] = "1^580^I250",        -- A Blade Fit For A Champion (A)
        [13603] = "1^740^I250",        -- A Blade Fit For A Champion
        [13741] = "1^740^I250",        -- A Blade Fit For A Champion
        [13746] = "1^740^I250",        -- A Blade Fit For A Champion
        [13752] = "1^740^I250",        -- A Blade Fit For A Champion
        [13757] = "1^740^I250",        -- A Blade Fit For A Champion
        [13673] = "1^580^R250",        -- A Blade Fit For A Champion (H)
        [13762] = "1^740^R250",        -- A Blade Fit For A Champion
        [13768] = "1^740^R250",        -- A Blade Fit For A Champion
        [13783] = "1^740^R250",        -- A Blade Fit For A Champion
        [13773] = "1^740^R250",        -- A Blade Fit For A Champion
        [13778] = "1^740^R250",        -- A Blade Fit For A Champion
        -- WotLK The Storm Peaks
        [12994] = "1^740^h350^hH",    -- Spy Hunter
        [12833] = "1^680",        -- Overstock
        [13424] = "1^740",        -- Back to the Pit (Hyldnir Spoils)
        [12977] = "1^740^h250",        -- Blowing Hodir's Horn
        [13423] = "1^740",        -- Defending Your Title (Hyldnir Spoils)
        [13046] = "1^740^h250^hR",    -- Feeding Arngrim
        [12981] = "1^740^h250",        -- Hot and Cold
        [13422] = "1^550",        -- Maintaining Discipline (Hyldnir Spoils)
        [13006] = "1^740^h250",        -- Polishing the Helm
        [12869] = "1^680^f250",        -- Pushed Too Far
        [13425] = "1^740",        -- The Aberrations Must Die (Hyldnir Spoils)
        [13003] = "1^1480^h500^hH",    -- Thrusting Hodir's Spear
        -- WotLK Wintergrasp
        [13156] = "1^740",        -- A Rare Herb
        [13195] = "1^740",        -- A Rare Herb
        [13154] = "1^740",        -- Bones and Arrows
        [13193] = "1^740",        -- Bones and Arrows
        [13196] = "1^740",        -- Bones and Arrows
        [13199] = "1^740",        -- Bones and Arrows
        [13222] = "1^740",        -- Defend the Siege
        [13223] = "1^740",        -- Defend the Siege
        [13191] = "1^740",        -- Fueling the Demolishers
        [13197] = "1^740",        -- Fueling the Demolishers
        [13200] = "1^740",        -- Fueling the Demolishers
        [13194] = "1^740",        -- Healing with Roses
        [13201] = "1^740",        -- Healing with Roses
        [13202] = "1^740",        -- Jinxing the Walls
        [13177] = "1^740",        -- No Mercy for the Merciless
        [13179] = "1^740",        -- No Mercy for the Merciless
        [13178] = "1^740",        -- Slay them all!
        [13180] = "1^740",        -- Slay them all!
        [13538] = "1^740",        -- Southern Sabotage
        [13185] = "1^740",        -- Stop the Siege
        [13186] = "1^740",        -- Stop the Siege
        [13539] = "1^740",        -- Toppling the Towers
        [13181] = "1^740",        -- Victory in Wintergrasp
        [13183] = "1^740",        -- Victory in Wintergrasp
        [13192] = "1^740",        -- Warding the Walls
        [13153] = "1^740",        -- Warding the Warriors
        [13198] = "1^740",        -- Warding the Warriors
        -- WotLK Cooking
        [13101] = "1^580^i150^C",    -- Convention at the Legerdemain
        [13113] = "1^580^i150^C",    -- Convention at the Legerdemain
        [13100] = "1^580^i150^C",    -- Infused Mushroom Meatloaf
        [13112] = "1^580^i150^C",    -- Infused Mushroom Meatloaf
        [13107] = "1^580^i150^C",    -- Mustard Dogs!
        [13116] = "1^580^i150^C",    -- Mustard Dogs!
        [13102] = "1^580^i150^C",    -- Sewer Stew
        [13114] = "1^580^i150^C",    -- Sewer Stew
        -- WotLK Jewelcrafting
        [12958] = "1^740^i 25^J375",    -- Shipment: Blood Jade Amulet
        [12962] = "1^740^i 25^J375",    -- Shipment: Bright Armor Relic
        [12959] = "1^740^i 25^J375",    -- Shipment: Glowing Ivory Figurine
        [12961] = "1^740^i 25^J375",    -- Shipment: Intricate Bone Figurine
        [12963] = "1^740^i 25^J375",    -- Shipment: Shifting Sun Curio
        [12960] = "1^740^i 25^J375",    -- Shipment: Wicked Sun Brooch
        -- WotLK Fishing
        [13833] = "1^0^i250^F",        -- Blood Is Thicker
        [13834] = "1^0^i250^F",        -- Dangerously Delicious
        [13832] = "1^0^i250^F",        -- Jewel Of The Sewers
        [13836] = "1^0^i250^F",        -- Monsterbelly Appetite
        [13830] = "1^0^i250^F",        -- The Ghostfish
    }
    self.DailyDungeonIds = {
        -- Dungeon
        [11389] = "2^1639^c250t250",    -- Wanted: Arcatraz Sentinels
        [11371] = "2^1639^c250e250",    -- Wanted: Coilfang Myrmidons
        [11376] = "2^1639^c250l250",    -- Wanted: Malicious Instructors
        [11383] = "2^1639^c250k250",    -- Wanted: Rift Lords
        [11364] = "2^1639^c250z250",    -- Wanted: Shattered Hand Centurions
        [11500] = "2^1639^c250s250",    -- Wanted: Sisters of Torment
        [11385] = "2^1639^c250t250",    -- Wanted: Sunseeker Channelers
        [11387] = "2^1639^c250t250",    -- Wanted: Tempest-Forge Destroyers
        -- Dungeon Heroic
        [11369] = "3^2460^c250e250",    -- Wanted: A Black Stalker Egg
        [11384] = "3^2460^c350t350",    -- Wanted: A Warp Splinter Clipping
        [11382] = "3^2460^c350k350",    -- Wanted: Aeonus's Hourglass
        [11363] = "3^2460^c350z350",    -- Wanted: Bladefist's Seal
        [11362] = "3^2460^c350z350",    -- Wanted: Keli'dan's Feathered Stave
        [11375] = "3^2460^c350l350",    -- Wanted: Murmur's Whisper
        [11354] = "3^2460^c350z350",    -- Wanted: Nazan's Riding Crop
        [11386] = "3^2460^c350t350",    -- Wanted: Pathaleon's Projector
        [11373] = "3^2460^c500",    -- Wanted: Shaffar's Wondrous Pendant
        [11378] = "3^2460^c350k350",    -- Wanted: The Epoch Hunter's Head
        [11374] = "3^2460^c350l350",    -- Wanted: The Exarch's Soul Gem
        [11372] = "3^2460^c350l350",    -- Wanted: The Headfeathers of Ikiss
        [11368] = "3^2460^c350e350",    -- Wanted: The Heart of Quagmirran
        [11388] = "3^2460^c350t350",    -- Wanted: The Scroll of Skyriss
        [11499] = "3^2460^c350s350",    -- Wanted: The Signet Ring of Prince Kael'thas
        [11370] = "3^2460^c350e350",    -- Wanted: The Warlord's Treatise
        -- WotLK Dungeon
        [13240] = "2^3466^i 75",    -- Timear Foresees Centrifuge Constructs in your Future!
        [13243] = "2^3466^i 75",    -- Timear Foresees Infinite Agents in your Future!
        [13244] = "2^3466^i 75",    -- Timear Foresees Titanium Vanguards in your Future!
        [13241] = "2^3466^i 75",    -- Timear Foresees Ymirjar Berserkers in your Future!
        -- WotLK Dungeon Heroic
        [13190] = "2^4200",        -- All Things in Good Time
        [13254] = "2^4866^i 75",    -- Proof of Demise: Anub'arak
        [13256] = "2^4866^i 75",    -- Proof of Demise: Cyanigosa
        [13250] = "2^4866^i 75",    -- Proof of Demise: Gal'darah
        [13255] = "2^4866^i 75",    -- Proof of Demise: Herald Volazj
        [13245] = "2^4866^i 75",    -- Proof of Demise: Ingvar the Plunderer
        [13246] = "2^4866^i 75",    -- Proof of Demise: Keristrasza
        [13248] = "2^4866^i 75",    -- Proof of Demise: King Ymiron
        [13247] = "2^4866^i 75",    -- Proof of Demise: Ley-Guardian Eregos
        [13253] = "2^4866^i 75",    -- Proof of Demise: Loken
        [13251] = "2^4866^i 75",    -- Proof of Demise: Mal'Ganis
        [13252] = "2^4866^i 75",    -- Proof of Demise: Sjonnir The Ironshaper
        [14199] = "2^4866^i 75",    -- Proof of Demise: The Black Knight
        [13249] = "2^4866^i 75",    -- Proof of Demise: The Prophet Tharon'ja
    }
    self.DailyPVPIds = {            -- For not auto watching
        [11335] = "1",            -- AV, AB, EOS, WG both sides
        [11336] = "1",
        [11337] = "1",
        [11338] = "1",
        [11339] = "1",
        [11340] = "1",
        [11341] = "1",
        [11342] = "1",
        [13405] = "1",            -- SoA
        [13407] = "1",
        [14163] = "1",            -- IoC
        [14164] = "1",
    }

    --    DEBUG for Jamie
    Nx.Quest:LoadQuestDB()
    --

    self.List:Open()
    self.Watch:Open()
    self.WQList:Open()

    -- Menu

    local menu = Nx.Menu:Create (self.Map.Frm)
    self.IconMenu = menu

    menu:AddItem (0, "Track", self.Menu_OnTrack, self)
    menu:AddItem (0, "Show Quest Log", self.Menu_OnShowQuest, self)
    self.IconMenuIWatch = menu:AddItem (0, "Watch", self.Menu_OnWatch, self)

    menu:AddItem (0, "Add Note", self.Map.Menu_OnAddNote, self.Map)

    -- Hook quests
    --
    -- We use hooksecurefunc (post-call) instead of replacing the globals.
    -- Replacing AcceptQuest / GetQuestReward meant any error inside our
    -- wrapper aborted the original Blizzard call and the quest never
    -- actually accepted/turned in. With a post-hook the user-visible
    -- action always completes; our bookkeeping is best-effort and
    -- protected by pcall so a Lua error here can never block turn-in.

    hooksecurefunc("AcceptQuest", function(...)
        local ok, err = pcall(Nx.Quest.RecordQuestAcceptOrFinish, Nx.Quest)
        if not ok then
            Nx.prtD("AcceptQuest hook error: %s", tostring(err))
        end
    end)

    hooksecurefunc("GetQuestReward", function(choice, ...)
        local ok, err = pcall(Nx.Quest.FinishQuest, Nx.Quest)
        if not ok then
            Nx.prtD("GetQuestReward hook error: %s", tostring(err))
        end
    end)

    QuestFrameDetailPanel:HookScript ("OnShow", function ()
        local auto = Nx.qdb.profile.Quest.AutoAccept
        if IsShiftKeyDown() and IsControlKeyDown() then
            auto = not auto
        end
        if auto then
            AcceptQuest()
            QuestFrame:Hide();
            QuestFrameDetailPanel:Hide()
        end
    end);

    -- Hook tooltip

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        -- Retail/DF+ secure tooltip API: avoids tainting GameTooltip layout state,
        -- which otherwise breaks Blizzard code like AddSuppressedPinsToTooltip.
        local function questPostCall(tooltip)
            if tooltip == GameTooltip then
                Nx.Quest:TooltipProcess()
            end
        end
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, questPostCall)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, questPostCall)
        if Enum.TooltipDataType.Quest then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Quest, questPostCall)
        end
    else
        local ttHooks = {
            "SetAction",
--            "SetAuctionItem",
            "SetBagItem",
            "SetGuildBankItem",
            "SetHyperlink",
            "SetInboxItem",
            "SetInventoryItem",
            "SetLootItem",
            "SetLootRollItem",
            "SetMerchantItem",
            --"SetRecipeReagentItem",
            --"SetRecipeResultItem",
            "SetQuestItem",
            "SetQuestLogItem",
            "SetTradeTargetItem",
        }

        for k, name in ipairs (ttHooks) do
                hooksecurefunc (GameTooltip, name, Nx.Quest.TooltipHook)
        end
--        GameTooltip:HookScript("OnTooltipSetUnit", Nx.Quest.TooltipHook)
    end

    local unitNames = {    -- 5 letter and shorter words are already blocked
        "Hunter", "Paladin", "Priest", "Monk",
        "Shaman", "Warlock", "Warrior", "Deathknight"
    }

    self.TTIgnore = {
        ["Attack"] = true,
        ["Lumber Mill"] = true,
        ["Stables"] = true,
        ["Blacksmith"] = true,
        ["Gold Mine"] = true,
    }

    self.TTIgnore[UnitName ("player")] = true

    for _, v in pairs (unitNames) do
        self.TTIgnore[v] = true
    end

    self.TTChange = {
        ["Bloodberry Bush"] = "Bloodberries",
        ["Erratic Sentry"] = "Erratic Sentries",
    }

    -- Quest log toggle handling - different approach for Classic vs Retail
    if QuestLogFrame then
        -- Classic: Hook the QuestLogFrame OnShow
        local func = function ()
            local testAlt = IsAltKeyDown() and not self.IgnoreAlt
            if Nx.qdb.profile.Quest.UseAltLKey then
                testAlt = not testAlt
            end
            if not testAlt then
                HideUIPanel(QuestLogFrame)
                if self.InShowUIPanel then
                    Nx.Quest:HideUIPanel(QuestMapFrame)
                    self.InShowUIPanel = false
                else
                    Nx.Quest:ShowUIPanel(QuestMapFrame)
                    self.InShowUIPanel = true
                end
            end
        end
        QuestLogFrame:HookScript("OnShow", func)
    else
        -- Retail: Override ToggleQuestLog
        Nx.Quest.OldToggleQuestLog = ToggleQuestLog
        function ToggleQuestLog(...)
            Nx.Map.WMFOnShow = false
            local orig = IsAltKeyDown() and not self.IgnoreAlt
            if Nx.qdb.profile.Quest.UseAltLKey then
                orig = not orig
            end
            if not orig then
                if self.InShowUIPanel then
                    Nx.Quest:HideUIPanel(QuestMapFrame)
                    self.InShowUIPanel = false
                else
                    Nx.Quest:ShowUIPanel(QuestMapFrame)
                    self.InShowUIPanel = true
                end
            else
                Nx.Quest.OldToggleQuestLog(...)
            end
            Nx.Map.WMFOnShow = true
        end
    end
end

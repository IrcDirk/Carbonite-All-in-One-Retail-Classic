-------------------------------------------------------------------------------
-- NxPunks - Enemy player tracking ("Punks")
-- Originally part of Carbonite.Social, extracted as a standalone module.
-- Carbonite.Social's enhanced FriendsFrame replacement and Team HUD have been
-- dropped (Blizzard's modern social UI covers that ground); this module keeps
-- only the Punks system: detect / mark / share / display enemy players on the
-- map and via a small target-button HUD.
--
-- Copyright 2007-2012 Carbon Based Creations, LLC (original)
-- Released under GPL.
-------------------------------------------------------------------------------

local _G = getfenv(0)

Nx.VERSIONPUNKS = .2

Nx.Punks = {}                       -- Main namespace
Nx.Punks.HUD = {}                   -- Target-button HUD
Nx.Punks.Cols = {}                  -- Color cache (parsed from profile strings)

CarbonitePunks = LibStub("AceAddon-3.0"):NewAddon("CarbonitePunks", "AceTimer-3.0", "AceEvent-3.0", "AceComm-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Punks", true)

-- Inline class-icon markup using Blizzard's standard class-icon atlas.
-- Returns "" when classFile is unknown so callers can concatenate freely.
local CLASS_ICON_TEX = "Interface\\TargetingFrame\\UI-Classes-Circles"
local function classIconMarkup(classFile)
	if not classFile or classFile == "" or not CLASS_ICON_TCOORDS or not CLASS_ICON_TCOORDS[classFile] then
		return ""
	end
	local c = CLASS_ICON_TCOORDS[classFile]
	return format("|T%s:0:0:0:0:256:256:%d:%d:%d:%d|t ", CLASS_ICON_TEX,
		c[1] * 256, c[2] * 256, c[3] * 256, c[4] * 256)
end

-- Returns class color escape (|cffRRGGBB) or "" when classFile is unknown.
local function classColorEsc(classFile)
	if not classFile or classFile == "" then return "" end
	local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
	if c and c.colorStr then return "|c" .. c.colorStr end
	if c and c.r then return format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255) end
	return ""
end

-------------------------------------------------------------------------------
-- DEFAULT OPTIONS
-------------------------------------------------------------------------------

local defaults = {
	profile = {
		Punks = {
			Enable = true,                       -- Enable punk tracking system
			-- Map display
			MapShowPunks = true,                 -- Show punks on map
			AreaColor = ".125|.05|.05|1",        -- Color of punk area circle
			AreaSize = 80,                       -- Size of punk area on map
			IconColor = "1|.5|.5|1",             -- Color of punk icon
			ShowInSafeArea = false,              -- Show punks in sanctuaries
			-- Other Carbonite users' punk detection
			MAreaColor = ".09|.44|.09|1",        -- Color for others' detected punks
			MAreaSize = 200,                     -- Size of others' punk area
			MAlertText = true,                   -- Show text for others' punks
			MAlertSnd = true,                    -- Play sound for others' punks
			-- Local punk detection
			NewLocalWarnChat = true,             -- Show chat message for new punks
			NewLocalWarnSnd = false,             -- Play sound for new punks
			-- Battleground settings
			ShowInBG = true,                     -- Show punks in BGs
			BGAreaColor = "24|.141|.141|1",      -- BG punk area color
			BGAreaSize = 60,                     -- BG punk area size
			-- HUD window
			HUDTitle = "Punks:",                 -- HUD window title
			HUDHide = false,                     -- Hide HUD window
			HUDLock = false,                     -- Lock HUD window
			HUDMaxButs = 5,                      -- Max target buttons in HUD
		},
	},
}

-------------------------------------------------------------------------------
-- OPTIONS CONFIG (AceConfig)
-------------------------------------------------------------------------------

local punksoptions

local function punksConfig()
	if not punksoptions then
		punksoptions = {
			type = "group",
			name = L["Punk Options"],
			args = {
				pnkenable = {
					order = 1,
					type = "toggle",
					width = "full",
					name = L["Enable the Punk System"],
					desc = L["When enabled, Carbonite allows use of the Punk system (REQUIRES RELOAD)"],
					get = function() return Nx.pkdb.profile.Punks.Enable end,
					set = function()
						Nx.pkdb.profile.Punks.Enable = not Nx.pkdb.profile.Punks.Enable
						Nx.Opts.NXCmdReload()
					end,
				},
				spacer = { order = 2, type = "description", width = "full", name = " " },
				pnkhide = {
					order = 3,
					type = "toggle",
					width = "full",
					name = L["Hide the Punk Window"],
					desc = L["When enabled, Carbonite will hide the punk window"],
					get = function() return Nx.pkdb.profile.Punks.HUDHide end,
					set = function()
						Nx.pkdb.profile.Punks.HUDHide = not Nx.pkdb.profile.Punks.HUDHide
						Nx.Window:SetAttribute("NxPunkHUD", "H", Nx.pkdb.profile.Punks.HUDHide)
					end,
				},
				pnklock = {
					order = 4,
					type = "toggle",
					width = "full",
					name = L["Lock the Punk Window"],
					desc = L["When enabled, Carbonite will lock the punk window"],
					get = function() return Nx.pkdb.profile.Punks.HUDLock end,
					set = function()
						Nx.pkdb.profile.Punks.HUDLock = not Nx.pkdb.profile.Punks.HUDLock
						Nx.Window:SetAttribute("NxPunkHUD", "L", Nx.pkdb.profile.Punks.HUDLock)
					end,
				},
				pnktitle = {
					order = 5,
					type = "input",
					width = "full",
					name = L["Punk Window Title"],
					get = function() return Nx.pkdb.profile.Punks.HUDTitle end,
					set = function(_, value)
						Nx.pkdb.profile.Punks.HUDTitle = value
						Nx.Opts.NXCmdReload()
					end,
				},
				maxtargets = {
					order = 6,
					type = "range",
					name = L["Max punk target buttons"],
					desc = L["Sets the number of punks that will show in the punk window. (REQUIRES RELOAD)"],
					min = 0, max = 15, step = 1, bigStep = 1,
					get = function() return Nx.pkdb.profile.Punks.HUDMaxButs end,
					set = function(_, value)
						Nx.pkdb.profile.Punks.HUDMaxButs = value
						Nx.Opts.NXCmdReload()
					end,
				},
				spacer2 = { order = 7, type = "description", width = "full", name = " " },
				pnkotxt = {
					order = 8, type = "toggle", width = "full",
					name = L["Show Others Punks Message"],
					desc = L["When enabled, Carbonite will show a message on other users in the zone detecting punks"],
					get = function() return Nx.pkdb.profile.Punks.MAlertText end,
					set = function() Nx.pkdb.profile.Punks.MAlertText = not Nx.pkdb.profile.Punks.MAlertText end,
				},
				pnkosnd = {
					order = 9, type = "toggle", width = "full",
					name = L["Play Others Punk Sound"],
					desc = L["When enabled, Carbonite will play a sound when another Carbonite user in the zone sees a punk"],
					get = function() return Nx.pkdb.profile.Punks.MAlertSnd end,
					set = function() Nx.pkdb.profile.Punks.MAlertSnd = not Nx.pkdb.profile.Punks.MAlertSnd end,
				},
				pnktxt = {
					order = 10, type = "toggle", width = "full",
					name = L["Show Punks Message"],
					desc = L["When enabled, Carbonite will show a message in your chat when you detect a punk"],
					get = function() return Nx.pkdb.profile.Punks.NewLocalWarnChat end,
					set = function() Nx.pkdb.profile.Punks.NewLocalWarnChat = not Nx.pkdb.profile.Punks.NewLocalWarnChat end,
				},
				pnksnd = {
					order = 11, type = "toggle", width = "full",
					name = L["Play Punk Sound"],
					desc = L["When enabled, Carbonite will play a sound when you detect a new punk"],
					get = function() return Nx.pkdb.profile.Punks.NewLocalWarnSnd end,
					set = function() Nx.pkdb.profile.Punks.NewLocalWarnSnd = not Nx.pkdb.profile.Punks.NewLocalWarnSnd end,
				},
				pnksafe = {
					order = 12, type = "toggle", width = "full",
					name = L["Show Punks In Safe Areas"],
					desc = L["When enabled, Carbonite will show punks even in sanctuary areas"],
					get = function() return Nx.pkdb.profile.Punks.ShowInSafeArea end,
					set = function() Nx.pkdb.profile.Punks.ShowInSafeArea = not Nx.pkdb.profile.Punks.ShowInSafeArea end,
				},
				spacer3 = { order = 13, type = "description", width = "full", name = " " },
				pnkshowmap = {
					order = 14, type = "toggle", width = "full",
					name = L["Show Punks On Map"],
					desc = L["When enabled, Carbonite will show punks on your map"],
					get = function() return Nx.pkdb.profile.Punks.MapShowPunks end,
					set = function() Nx.pkdb.profile.Punks.MapShowPunks = not Nx.pkdb.profile.Punks.MapShowPunks end,
				},
				pnkiconcol = {
					order = 15, type = "color", width = "full",
					name = L["Color of punk icon"], hasAlpha = true,
					get = function()
						local arr = { strsplit("|", Nx.pkdb.profile.Punks.IconColor) }
						return arr[1], arr[2], arr[3], tonumber(arr[4])
					end,
					set = function(_, r, g, b, a)
						Nx.pkdb.profile.Punks.IconColor = r .. "|" .. g .. "|" .. b .. "|" .. a
						Nx.Punks:SetCols()
					end,
				},
				pnkareacol = {
					order = 16, type = "color", width = "full",
					name = L["Color of punk map area"], hasAlpha = true,
					get = function()
						local arr = { strsplit("|", Nx.pkdb.profile.Punks.AreaColor) }
						return arr[1], arr[2], arr[3], tonumber(arr[4])
					end,
					set = function(_, r, g, b, a)
						Nx.pkdb.profile.Punks.AreaColor = r .. "|" .. g .. "|" .. b .. "|" .. a
						Nx.Punks:SetCols()
					end,
				},
				pnkareasize = {
					order = 17, type = "range",
					name = L["Punk Area Size"], desc = L["Sets the size of the punk area notify on the map."],
					min = 0, max = 5000, step = 10, bigStep = 10,
					get = function() return Nx.pkdb.profile.Punks.AreaSize end,
					set = function(_, value) Nx.pkdb.profile.Punks.AreaSize = value end,
				},
				pnkmareacol = {
					order = 18, type = "color", width = "full",
					name = L["Color of other peoples detected punks"], hasAlpha = true,
					get = function()
						local arr = { strsplit("|", Nx.pkdb.profile.Punks.MAreaColor) }
						return arr[1], arr[2], arr[3], tonumber(arr[4])
					end,
					set = function(_, r, g, b, a)
						Nx.pkdb.profile.Punks.MAreaColor = r .. "|" .. g .. "|" .. b .. "|" .. a
						Nx.Punks:SetCols()
					end,
				},
				pnkmareasize = {
					order = 19, type = "range",
					name = L["Others Punk Area Size"],
					desc = L["Sets the size of the punk area notify on the map from other carbonite users."],
					min = 0, max = 5000, step = 10, bigStep = 10,
					get = function() return Nx.pkdb.profile.Punks.MAreaSize end,
					set = function(_, value) Nx.pkdb.profile.Punks.MAreaSize = value end,
				},
				pnkmap = {
					order = 20, type = "toggle", width = "full",
					name = L["Show Battleground Punks On Map"],
					desc = L["When enabled, Carbonite will show punks on your map in battlegrounds"],
					get = function() return Nx.pkdb.profile.Punks.ShowInBG end,
					set = function() Nx.pkdb.profile.Punks.ShowInBG = not Nx.pkdb.profile.Punks.ShowInBG end,
				},
				pnkbgareacol = {
					order = 21, type = "color", width = "full",
					name = L["Battleground punk color"], hasAlpha = true,
					get = function()
						local arr = { strsplit("|", Nx.pkdb.profile.Punks.BGAreaColor) }
						return arr[1], arr[2], arr[3], tonumber(arr[4])
					end,
					set = function(_, r, g, b, a)
						Nx.pkdb.profile.Punks.BGAreaColor = r .. "|" .. g .. "|" .. b .. "|" .. a
						Nx.Punks:SetCols()
					end,
				},
				pnkbgareasize = {
					order = 22, type = "range",
					name = L["Battleground Punk Area Size"],
					desc = L["Sets the size of the punk area in BGs."],
					min = 0, max = 5000, step = 10, bigStep = 10,
					get = function() return Nx.pkdb.profile.Punks.BGAreaSize end,
					set = function(_, value) Nx.pkdb.profile.Punks.BGAreaSize = value end,
				},
			},
		}
	end
	Nx.Opts:AddToProfileMenu(L["Punks"], 5, Nx.pkdb)
	return punksoptions
end

-------------------------------------------------------------------------------
-- DATA ACCESS
-- Per-realm storage layout in profile.PunksData[realm]:
--   ["Pk"]    -> name -> "time~level~class~note" (permanent flagged punks)
--   ["PkAct"] -> name -> { MId, X, Y, Time, Lvl, Class, ... } (active sightings)
-------------------------------------------------------------------------------

function Nx:GetPunks(typ)
	local rn = GetRealmName()
	return Nx.pkdb.profile.PunksData[rn][typ]
end

function Nx:ClearPunks(typ)
	local rn = GetRealmName()
	Nx.pkdb.profile.PunksData[rn][typ] = {}
end

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------

local PunksUpdate

function CarbonitePunks:OnInitialize()
	if not Nx.Initialized then
		CarbPunksInit = Nx:ScheduleTimer(CarbonitePunks.OnInitialize, 1)
		return
	end
	Nx.pkdb = LibStub("AceDB-3.0"):New("NXPunks", defaults, true)

	-- Per-realm punk store, versioned so we can wipe legacy formats if needed
	local pdata = Nx.pkdb.profile.PunksData
	if not pdata or pdata.Version ~= Nx.VERSIONPUNKS then
		if pdata then
			Nx.prt("Reset old punk data %f", pdata.Version or -1)
		end
		pdata = {}
		Nx.pkdb.profile.PunksData = pdata
		pdata.Version = Nx.VERSIONPUNKS
	end

	local rn = GetRealmName()
	if not pdata[rn] then
		pdata[rn] = { Pk = {}, PkAct = {} }
	end
	pdata[rn]["Pk"] = pdata[rn]["Pk"] or {}
	pdata[rn]["PkAct"] = pdata[rn]["PkAct"] or {}

	Nx.Punks:Init()

	CarbonitePunks:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombat_log_event_unfiltered")
	Nx.Punks.UpdateTicker = C_Timer.NewTicker(1, function()
		CarbonitePunks:On_Event("FORCE_UPDATE")
		Nx.Punks:OnUpdateTimer()
	end)
	CarbonitePunks:RegisterComm("carbmodule", Nx.Punks.OnChat_msg_addon)

	Nx:AddToConfig("Punks Module", punksConfig(), L["Punks"])
	Nx.Punks:SetCols()

	-- Map toolbar button: same widget that hosts Guide / Notes / Warehouse / etc.
	-- Opens the Punks list/management window. (The small target-button HUD
	-- shows up automatically when punks are detected; toggling its hidden
	-- state from here was redundant, so the toolbar button now just opens
	-- the list window directly.)
	Nx.Button.TypeData["MapPunks"] = {
		Up = "$Ability_TownWatch",
		SizeUp = 22,
		SizeDn = 22,
	}
	function Nx.Punks.OnButTogglePunks(self, but)
		Nx.Punks:ToggleListWin()
	end
	tinsert(Nx.BarData, {"MapPunks", L["Punks"], Nx.Punks.OnButTogglePunks, false})
	if Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1] then
		Nx.Map.Maps[1]:CreateToolBar()
	end
end

-------------------------------------------------------------------------------
-- ADDON COMMUNICATION
-------------------------------------------------------------------------------

function Nx.Punks:OnChat_msg_addon(msg, dist, target)
	if msg == "PUNK_DECODE" then
		Nx.Punks:DecodeComRcvPunks(Nx.pTEMPname, Nx.pTEMPinfo, Nx.pTEMPmsg)
	end
end

-------------------------------------------------------------------------------
-- COLOR CACHING
-------------------------------------------------------------------------------

function Nx.Punks:SetCols()
	local p = Nx.pkdb.profile.Punks
	local c = self.Cols
	c.areaR, c.areaG, c.areaB = Nx.Util_str2rgba(p.AreaColor)
	c.iconR, c.iconG, c.iconB, c.iconA = Nx.Util_str2rgba(p.IconColor)
	c.areaRM, c.areaGM, c.areaBM = Nx.Util_str2rgba(p.MAreaColor)
	c.areaBGR, c.areaBGG, c.areaBGB = Nx.Util_str2rgba(p.BGAreaColor)
end

-------------------------------------------------------------------------------
-- EVENT HANDLING
-------------------------------------------------------------------------------

function CarbonitePunks:On_Event(event, ...)
	if event == "PLAYER_ENTERING_WORLD" or event == "FORCE_UPDATE" then
		Nx.Punks.HUD:Update()

		-- We capture both the localized class name (for display) and the
		-- English file ID (for class-color and class-icon lookups). The
		-- file ID is the second return of UnitClass.
		local targetName = UnitName("target")
		local BG = Nx.InBG
		if UnitIsPlayer("target") and UnitIsEnemy("player", "target") then
			local lvl = UnitLevel("target") or 0
			local lcls, fcls = UnitClass("target")
			if not BG then
				Nx.Com.Punks[targetName] = lvl
			end
			Nx.Punks:AddLocalPunk(targetName, nil, lvl, lcls, fcls)
		end
		if UnitIsPlayer("mouseover") and UnitIsEnemy("player", "mouseover") then
			local moName = UnitName("mouseover")
			if moName ~= targetName then
				local lvl = UnitLevel("mouseover") or 0
				local lcls, fcls = UnitClass("mouseover")
				if not BG then
					Nx.Com.Punks[moName] = lvl
				end
				Nx.Punks:AddLocalPunk(moName, nil, lvl, lcls, fcls)
			end
		end
		if Nx.ModPAction == "PUNK_DECODE" then
			Nx.ModPAction = ""
			Nx.Punks:DecodeComRcvPunks(Nx.pTEMPname, Nx.pTEMPinfo, Nx.pTEMPmsg)
		end
	end
end

-------------------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------------------

function Nx.Punks:Init()
	self.Punks = Nx:GetPunks("Pk")
	self.PunksActive = Nx:GetPunks("PkAct")

	-- Schema check: drop legacy entries missing required fields
	for k, v in pairs(self.PunksActive) do
		if not (v.MId and v.X and v.Y and v.Time) then
			Nx:ClearPunks("PkAct")
			self.PunksActive = Nx:GetPunks("PkAct")
			break
		end
	end

	if Nx.pkdb.profile.Punks.Enable then
		self.PunkNewDir = 0
		self.HUD:Create()
	end

	Nx.Window:SetAttribute("NxPunkHUD", "H", Nx.pkdb.profile.Punks.HUDHide)
	Nx.Window:SetAttribute("NxPunkHUD", "L", Nx.pkdb.profile.Punks.HUDLock)
end

-------------------------------------------------------------------------------
-- PUNK LIST OPERATIONS
-- Manage the permanent flagged-punks list (profile.PunksData[realm].Pk).
-------------------------------------------------------------------------------

-- Permanent-list record format (legacy + extended):
--   tm ~ lvl ~ class ~ note ~ classFile
-- Existing entries from older versions only have 3 or 4 fields; the
-- additional classFile field is read defensively (nil-tolerant).
function Nx.Punks:PunkAdd(name, level, class, classFile)
	local punks = Nx:GetPunks("Pk")
	name = Nx.Util_CleanName(name)

	local punk = self.PunksActive[name]
	if punk then
		level = level or punk.Lvl
		class = class or punk.Class
		classFile = classFile or punk.ClassID
	end

	-- Preserve existing note if we already have a record for this name
	local existing = punks[name]
	local existingNote = ""
	if existing then
		local _, _, _, n = strsplit("~", existing)
		existingNote = n or ""
	end

	punks[name] = format("%s~%s~%s~%s~%s", time(), level or "", class or "", existingNote, classFile or "")
end

function Nx.Punks:PunkRemove(name)
	local punks = Nx:GetPunks("Pk")
	punks[name] = nil
end

function Nx.Punks:PunkSetNote(name, note)
	local punks = Nx:GetPunks("Pk")
	local existing = punks[name]
	if not existing then return end
	local tm, lvl, class, _, classFile = strsplit("~", existing)
	punks[name] = format("%s~%s~%s~%s~%s", tm, lvl or "", class or "", note or "", classFile or "")
end

-- Slash-command entrypoints. Without the legacy social-window UI, these are
-- the user's interactive surface for managing the permanent punks list:
--   /carbpunk                  add the current target as a punk
--   /carbpunk <name>           add <name> as a punk
--   /carbpunk note <name>      open an edit box to set/edit the note for <name>
--   /carbpunk rm <name>        remove <name> from the permanent list
--   /carbpunk list             print all currently-flagged punks to chat
local function NoteAcceptCb(text, name)
	Nx.Punks:PunkSetNote(name, text or "")
end

local function PunksSlashCmd(args)
	args = args and args:match("^%s*(.-)%s*$") or ""

	-- Subcommand parse: first token + remainder
	local sub, rest = args:match("^(%S+)%s+(.*)$")
	if not sub then sub = args; rest = "" end

	if sub == "note" and rest ~= "" then
		local name = rest:match("^%s*(.-)%s*$")
		local punks = Nx:GetPunks("Pk")
		local existing = punks[name]
		if not existing then
			Nx.prt("Punk '%s' not in your list", name)
			return
		end
		local _, _, _, note = strsplit("~", existing)
		Nx:ShowEditBox(L["Set note"], note or "", name, NoteAcceptCb)
		return
	end

	if sub == "rm" and rest ~= "" then
		local name = rest:match("^%s*(.-)%s*$")
		Nx.Punks:PunkRemove(name)
		Nx.prt("Punk '%s' removed", name)
		return
	end

	if sub == "list" then
		local punks = Nx:GetPunks("Pk")
		local count = 0
		for name, data in pairs(punks) do
			count = count + 1
			local _, lvl, class, note = strsplit("~", data)
			Nx.prt("%s%s%s%s",
				name,
				(lvl and lvl ~= "") and (" L" .. lvl) or "",
				(class and class ~= "") and (" " .. class) or "",
				(note and note ~= "") and ("  -- " .. note) or "")
		end
		Nx.prt(L["Punks: %s  Active: %s"], count, 0)
		return
	end

	-- Default: add target or add by name
	if args == "" then
		local name = UnitName("target")
		if name and UnitIsPlayer("target") and UnitIsEnemy("player", "target") then
			Nx.Punks:PunkAdd(name, UnitLevel("target"), UnitClass("target"))
			Nx.prt(L["Punk %s added"], name)
		else
			Nx.prt(L["Add punk name"])
		end
	else
		Nx.Punks:PunkAdd(args)
		Nx.prt(L["Punk %s added"], args)
	end
end

SLASH_CARBPUNK1 = "/carbpunk"
SlashCmdList["CARBPUNK"] = PunksSlashCmd

-------------------------------------------------------------------------------
-- DECODE / RECEIVE PUNKS FROM OTHER CARBONITE USERS
-------------------------------------------------------------------------------

function Nx.Punks:DecodeComRcvPunks(finderName, info, punksStr)
	if not punksStr or #punksStr < 1 then return end
	local punksT = { strsplit("!", punksStr) }

	for _, v in ipairs(punksT) do
		local lvl = tonumber(strsub(v, 1, 2), 16)
		if not lvl then break end

		local name = strsub(v, 3)
		if lvl >= 0xff then
			name = strsub(v, 9)
			lvl = 0
		end
		if Nx.pkdb.profile.Punks.Enable then
			if info.MId < 1000 then
				local punk = self:GetPunk(name, nil, info.MId, info.X, info.Y)
				if punk then
					punk.FinderName = finderName
					punk.Lvl = max(lvl, punk.Lvl or 0)
					punk.Time = info.T
				end
			end
		end
	end

	if Nx:TimeLeft(PunksUpdate) == 0 then
		PunksUpdate = Nx:ScheduleTimer(self.OnUpdateTimer, 2, self)
	end
	Nx.TEMPname = nil
	Nx.TEMPinfo = nil
	Nx.TEMPmsg = nil
end

-------------------------------------------------------------------------------
-- LOCAL PUNK DETECTION
-------------------------------------------------------------------------------

function Nx.Punks:AddLocalPunk(name, plyrNear, level, class, classFile)
	if not Nx.pkdb.profile.Punks.Enable then return end
	if Nx.InBG and not plyrNear then return end

	local map = Nx.Map:GetMap(1)

	name = strmatch(name, "[^-]+")            -- strip server name
	self.LastLocalPunk = name

	local rMapId = map.UpdateMapID
	local x, y = map.PlyrRZX, map.PlyrRZY

	if plyrNear then
		plyrNear = strmatch(plyrNear, "[^-]+")
		local i = Nx.GroupMembers[plyrNear]
		if i then
			local unit = Nx.GroupType .. i
			if UnitName(unit) then
				local pX, pY = Nx.Map.GetPlayerMapPosition(unit)
				if pX ~= 0 or pY ~= 0 then
					x = pX * 100
					y = pY * 100
				end
			end
		end
	end

	local punk = self:GetPunk(name, plyrNear, rMapId, x, y)
	if not punk then return end

	if not punk.Time and not Nx.InBG and Nx.pkdb.profile.Punks.NewLocalWarnChat then
		if not Nx.InSanctuary or Nx.pkdb.profile.Punks.ShowInSafeArea then
			local typ = self.Punks[name] and L["|cffff4040Punk"] or L["Enemy"]
			Nx.prt(L["%s %s detected near you"], typ, name)
			if Nx.pkdb.profile.Punks.NewLocalWarnSnd then
				Nx:PlaySoundFile(566027)
			end
		end
	end

	punk.FinderName = "me"
	punk.Lvl = level or punk.Lvl or 0
	punk.Class = class or punk.Class
	punk.ClassID = classFile or punk.ClassID  -- English class file ID for color/icon lookup
	if not punk.Time or GetTime() - punk.Time > 2 then
		punk.Time = GetTime()
	end

	if Nx:TimeLeft(PunksUpdate) == 0 then
		PunksUpdate = Nx:ScheduleTimer(self.OnUpdateTimer, 2, self)
	end

	self.HUD:Add(name)
end

function Nx.Punks:GetPunk(name, plyrNear, mId, x, y)
	if not Nx.pkdb.profile.Punks.Enable then return end

	local punk = self.PunksActive[name]
	if not punk then
		punk = {}
		self.PunksActive[name] = punk
		punk.DrawDir = self.PunkNewDir or 0
		self.PunkNewDir = (self.PunkNewDir or 0) + 3.14159 / 4.25
		punk.CircleTime = GetTime()
	end

	if not Nx.InBG or not punk.PlyrNear or (plyrNear and plyrNear ~= punk.PlyrNear) then
		punk.PlyrNear = plyrNear
		punk.MId = mId
		punk.X = x
		punk.Y = y
	end

	if not punk.Alert and self.Punks[name] then
		self.HUD:Add(name)

		if Nx.pkdb.profile.Punks.MAlertText then
			local _, _, _, note = strsplit("~", self.Punks[name])
			if note then
				UIErrorsFrame:AddMessage(format(L["Note: %s"], note), 1, 0, 1, 1)
			end

			local map = Nx.Map:GetMap(1)
			local wx, wy = map:GetWorldPos(mId, x, y)
			local dist = ((map.PlyrX - wx) ^ 2 + (map.PlyrY - wy) ^ 2) ^ .5 * 4.575
			local s = dist < 100 and L["|cffff4000near you"] or format(L["at %d yards"], dist)
			UIErrorsFrame:AddMessage(format(L["|cffff4000%s|r detected %s!"], name, s), 1, 1, 0, 1)
		end
		if Nx.pkdb.profile.Punks.MAlertSnd then
			Nx:PlaySoundFile(568986)
		end
		punk.Alert = true
	end

	if GetTime() - punk.CircleTime > 4 then
		punk.CircleTime = GetTime()
	end

	return punk
end

-------------------------------------------------------------------------------
-- TIMER & EXPIRATION
-------------------------------------------------------------------------------

function Nx.Punks:OnUpdateTimer()
	if not Nx.pkdb.profile.Punks.Enable then return 3 end
	self:CalcPunks()
	if self.ListWin and self.ListWin:IsShown() then
		self:UpdateListWin()
	end
end

function Nx.Punks:CalcPunks()
	local punks = self.Punks
	local punksA = self.PunksActive
	local tm = GetTime() - (Nx.InBG and 30 or 90)        -- Expire window

	for pName, punk in pairs(punksA) do
		if punks[pName] then
			if tm - 240 > punk.Time then        -- 5 min for permanent punks
				punksA[pName] = nil
				self.HUD:Remove(pName)
			end
		else
			if tm > punk.Time then
				punksA[pName] = nil
				self.HUD:Remove(pName)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- MAP ICON RENDERING
-------------------------------------------------------------------------------

function Nx.Punks:UpdateIcons(map)
	if not Nx.pkdb.profile.Punks.Enable then return end

	if Nx.Tick % 120 == 4 then
		self:CalcPunks()
	end

	local math = math
	local alt = IsAltKeyDown()
	local tm = GetTime()

	local punks = self.Punks
	local punksA = self.PunksActive

	local p = Nx.pkdb.profile.Punks
	local size = p.AreaSize * map.ScaleDraw
	local sizeM = p.MAreaSize * map.ScaleDraw

	local cols = self.Cols
	local areaR, areaG, areaB = cols.areaR, cols.areaG, cols.areaB
	local iconR, iconG, iconB, iconA = cols.iconR, cols.iconG, cols.iconB, cols.iconA
	local areaRM, areaGM, areaBM = cols.areaRM, cols.areaGM, cols.areaBM

	local showInSafeArea = p.ShowInSafeArea

	local decay = .24
	local decayM = .21

	local inBG = Nx.InBG
	if inBG then
		if not p.ShowInBG or Nx.Free then return end
		size = p.BGAreaSize * map.ScaleDraw
		areaR = cols.areaBGR
		areaG = cols.areaBGG
		areaB = cols.areaBGB
	end

	local iconGlow = abs(GetTime() * 400 % 200 - 100) / 400 + .75

	if alt then
		map.Level = map.Level + 11
	end

	for pName, punk in pairs(punksA) do
		local dur = tm - punk.Time
		local circleDur = tm - punk.CircleTime
		local punkMId = punk.MId
		if punkMId < 1000 then
			local wx, wy = map:GetWorldPos(punkMId, punk.X, punk.Y)
			local x = wx + math.sin(punk.DrawDir) * 2
			local y = wy + math.cos(punk.DrawDir) * 2

			if punks[pName] then
				local sz = sizeM / (circleDur * decayM + 1)
				if sz >= 1 then
					sz = max(sz, 25)
					local f = map:GetIconNI()
					if map:ClipFrameW(f, x, y, sz, sz, 0) then
						f.texture:SetBlendMode("ADD")
						f.texture:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconCircle")
						if dur < .1 then
							f.texture:SetVertexColor(.3, 1, .3, 1)
						else
							f.texture:SetVertexColor(areaRM, areaGM, areaBM, 1)
						end
					end
				end
			else
				if not Nx.InSanctuary or showInSafeArea then
					local sz = size / (circleDur * decay + 1)
					if sz >= 1 then
						sz = max(sz, 22)
						local f = map:GetIconNI()
						if map:ClipFrameW(f, x, y, sz, sz, 0) then
							f.texture:SetBlendMode("ADD")
							f.texture:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconCircle")
							if dur < .05 then
								if inBG then
									f.texture:SetVertexColor(.15, .15, .15, 1)
								else
									f.texture:SetVertexColor(.25, .25, .25, 1)
								end
							else
								f.texture:SetVertexColor(areaR, areaG, areaB, 1)
							end
						end
					end
				end
			end

			-- Punk dot
			if punks[pName] then
				local f = map:GetIcon(2)
				if map:ClipFrameW(f, x, y, 14, 14, 0) then
					local lvl = punk.Lvl > 0 and punk.Lvl or "?"
					local mapName = Nx.Map:GetMapNameByID(punkMId) or "?"
					f.NxTip = format(L["*|cffff0000%s %s, %d:%02d ago\n%s (%d,%d)"], pName, lvl, dur / 60 % 60, dur % 60, mapName, punk.X, punk.Y)
					f.NXType = 3001
					f.NXData = pName
					f.texture:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconPlyrZ")
					f.texture:SetVertexColor(iconR, iconG, iconB, iconA * iconGlow)
					if alt then
						local txt = map:GetText(format("*|cffff0000%s|r*", pName))
						map:MoveTextToIcon(txt, f, 18, 1)
					end
				end
			else
				if not Nx.InSanctuary or showInSafeArea then
					local i = dur < 10 and 2 or 1
					local f = map:GetIcon(i)
					if map:ClipFrameW(f, x, y, 10, 10, 0) then
						local lvl = punk.Lvl > 0 and punk.Lvl or "?"
						local mapName = Nx.Map:GetMapNameByID(punkMId) or "?"
						f.NxTip = format(L["|cffff6060%s %s, %d:%02d ago\n%s (%d,%d)"], pName, lvl, dur / 60 % 60, dur % 60, mapName, punk.X, punk.Y)
						f.NXType = 3001
						f.NXData = pName
						f.texture:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\IconPlyrZ")
						if dur < 10 then
							f.texture:SetVertexColor(iconR, iconG, iconB, iconA * iconGlow)
						else
							f.texture:SetVertexColor(iconR, iconG, iconB, iconA * .6)
						end
					end
				end
			end
		end
	end

	if alt then
		map.Level = map.Level - 11
	else
		map.Level = map.Level + 3
	end
end

-------------------------------------------------------------------------------
-- MAP NAVIGATION HELPERS (called from NxMap context-menu handlers)
-------------------------------------------------------------------------------

function Nx.Punks:GotoPunk(name)
	local punk = self.PunksActive[name]
	if not punk or punk.MId >= 1000 then return end
	local map = Nx.Map:GetMap(1)
	local wx, wy = map:GetWorldPos(punk.MId, punk.X, punk.Y)
	local x = wx + math.sin(punk.DrawDir) * 2
	local y = wy + math.cos(punk.DrawDir) * 2
	map:SetTarget(L["Goto"], x, y, x, y, false, 0, name)
end

function Nx.Punks:GetPunkPasteInfo(name)
	local punk = self.PunksActive[name]
	if punk then
		local lvl = punk.Lvl > 0 and punk.Lvl or "?"
		local class = punk.Class or "?"
		return format(L["Punk: %s, %s %s at %s %d %d"], name, lvl, class, Nx.Map:GetMapNameByID(punk.MId) or "?", punk.X, punk.Y)
	end
	return ""
end

-------------------------------------------------------------------------------
-- HUD WINDOW (small target-button window)
-------------------------------------------------------------------------------

function Nx.Punks.HUD:Create()
	self.Punks = {}
	self.Buts = {}
	self.NumButs = Nx.pkdb.profile.Punks.HUDMaxButs
	self.NumButsUsed = 0
	self.Changed = true

	Nx.Window:SetCreateFade(.5, 0)

	local win = Nx.Window:Create("NxPunkHUD", nil, nil, true, 1, 1, nil, true)
	self.Win = win

	win:InitLayoutData(nil, -.6, -.1, 128, 68)
	win:SetBGAlpha(0, .5)
	win.Frm:SetToplevel(true)

	local ox, oy = win:GetClientOffset()
	local x = ox - 2
	local y = -oy

	for n = 1, self.NumButs do
		local but = CreateFrame("Button", nil, win.Frm, "SecureUnitButtonTemplate")
		self.Buts[n] = but

		but:SetPoint("TOPLEFT", x, y)
		y = y - 13

		but:SetAttribute("type1", "macro")
		but:SetAttribute("*type2", "click")
		but:SetAttribute("*clickbutton2", but)
		but["Click"] = Nx.Punks.HUD.Click
		but:RegisterForClicks("LeftButtonDown", "RightButtonDown")

		local t = but:CreateTexture()
		t:SetColorTexture(1, 1, 1, 1)
		t:SetAllPoints(but)
		but.texture = t

		but:SetWidth(125)
		but:SetHeight(12)
		but:Hide()

		local fstr = but:CreateFontString()
		but.NXFStr = fstr
		fstr:SetFontObject("GameFontNormalSmall")
		fstr:SetJustifyH("LEFT")
		fstr:SetPoint("TOPLEFT", 0, 1)
		fstr:SetWidth(125)
		fstr:SetHeight(12)
	end
end

-- HUD button right-click handler. Left-click is consumed by the secure
-- macro (`/targetexact <name>`). The secure `*type2 = "click"` mapping
-- re-enters the button's click action on right-click, which fires this
-- callback. We open a context menu — the row's name is stashed on the
-- shared HUD menu state so the menu callbacks know which punk to act on.
function Nx.Punks.HUD:Click()
	local but = self
	if not but.NXName then return end
	Nx.Punks.HUD.MenuName = but.NXName
	if not Nx.Punks.HUD.Menu then
		Nx.Punks.HUD:CreateMenu()
	end
	Nx.Punks.HUD.Menu:Open()
end

function Nx.Punks.HUD:CreateMenu()
	local menu = Nx.Menu:Create(self.Win.Frm, 220)
	self.Menu = menu

	local function addPermanent()
		local name = Nx.Punks.HUD.MenuName
		if not name then return end
		local active = Nx.Punks.PunksActive[name]
		if active then
			Nx.Punks:PunkAdd(name, active.Lvl, active.Class, active.ClassID)
		else
			Nx.Punks:PunkAdd(name)
		end
		Nx.prt(L["Punk %s added"], name)
	end

	local function removeFromHud()
		local name = Nx.Punks.HUD.MenuName
		if name then Nx.Punks.HUD:Remove(name) end
	end

	menu:AddItem(0, L["Add Character"] or "Add to permanent punks", addPermanent)
	menu:AddItem(0, "")
	menu:AddItem(0, L["Remove Character"] or "Remove from list", removeFromHud)
end

function Nx.Punks.HUD:Add(name)
	if not self.Punks[name] then
		local punks = Nx.Punks.Punks
		if punks[name] then
			tinsert(self.Punks, 1, name)
		else
			local found
			for n = 1, #self.Punks do
				if not punks[self.Punks[n]] then
					tinsert(self.Punks, n, name)
					found = true
					break
				end
			end
			if not found then
				tinsert(self.Punks, name)
			end
		end
	end
	self.Punks[name] = true
	self.Changed = true
end

function Nx.Punks.HUD:Remove(name)
	for n = 1, #self.Punks do
		if self.Punks[n] == name then
			tremove(self.Punks, n)
			break
		end
	end
	self.Punks[name] = nil
	self.Changed = true
end

function Nx.Punks.HUD:Update()
	if not self.Win then return end

	local Punks = Nx.Punks

	if self.Changed then
		local lockDown = InCombatLockdown() ~= false
		local lchanged = self.LockedDown ~= lockDown
		self.LockedDown = lockDown

		if not lockDown then
			self.Changed = false

			local punks = Punks.Punks
			local punksA = Punks.PunksActive
			local n = 1

			for _, name in ipairs(self.Punks) do
				local but = self.Buts[n]
				but:SetAttribute("macrotext1", "/targetexact " .. name)
				but.NXName = name

				-- Build label: [class icon] [* if permanent] [class-colored name][, class label]
				local actInfo = punksA[name]
				local classFile = actInfo and actInfo.ClassID
				local color = classColorEsc(classFile)

				local nameStr = name
				if punks[name] then
					nameStr = "*" .. name           -- permanent marker prefix
				end
				if color ~= "" then
					nameStr = color .. nameStr .. "|r"
				elseif punks[name] then
					nameStr = "|cffff80ff" .. nameStr  -- fallback color when no class data
				end

				local s = classIconMarkup(classFile) .. nameStr
				if actInfo and actInfo.Class then
					s = s .. ", |cffa0a0a0" .. actInfo.Class
				end

				but.NXFStr:SetText(s)
				but:Show()

				n = n + 1
				if n > self.NumButs then break end
			end

			self.NumButsUsed = n - 1

			for i = n, self.NumButs do
				self.Buts[i]:Hide()
			end

			self.Win:SetSize(120, n * 13 - 15)
		end

		if lchanged then
			-- HUDTitle defaults to the English "Punks:" — when the user
			-- hasn't customized it, substitute the localized form. Custom
			-- non-default titles are kept verbatim.
			local title = Nx.pkdb.profile.Punks.HUDTitle
			if title == nil or title == "" or title == "Punks:" then
				title = (L["Punks"] or "Punks") .. ":"
			end
			if lockDown then
				self.Win:SetTitle("|cffff2020" .. title)
			else
				self.Win:SetTitle(title)
			end
		end
	end

	-- Pulse fade for recent punks
	local punksA = Punks.PunksActive
	local tm = GetTime()
	for n = 1, self.NumButsUsed do
		local but = self.Buts[n]
		local punk = punksA[but.NXName]
		if punk then
			local dur = tm - punk.Time
			dur = dur < .3 and dur or dur * .05 + .285
			local r = min(max(1 - dur, .1), 1)
			but.texture:SetVertexColor(r, 0, 0, .5)
		end
	end
end

-------------------------------------------------------------------------------
-- COMBAT LOG: detect enemy players via aura/damage flags and add as punks
-------------------------------------------------------------------------------

function CarbonitePunks:OnCombat_log_event_unfiltered(event, ...)
	local _, _, _, _, sName, sFlags, _, _, dName, dFlags = CombatLogGetCurrentEventInfo()

	if sName and bit.band(sFlags, 0x440) == 0x440 then
		local near
		if dName and bit.band(dFlags, 0x440) == 0x400 then
			near = dName
		end
		Nx.Punks:AddLocalPunk(sName, near)
		if not Nx.InBG then
			Nx.Com.Punks[sName] = 0
		end
	end
	if dName and dName ~= sName and bit.band(dFlags, 0x440) == 0x440 then
		local near
		if sName and bit.band(sFlags, 0x440) == 0x400 then
			near = sName
		end
		Nx.Punks:AddLocalPunk(dName, near)
		if not Nx.InBG then
			Nx.Com.Punks[dName] = 0
		end
	end
end

-------------------------------------------------------------------------------
-- LIST WINDOW
-- Replaces the social-window punks tab. Shows both permanent flagged punks
-- and currently-active sightings, with right-click context menu for managing
-- entries (promote active->permanent, set note, goto, remove).
-- Opened via Shift-click on the map toolbar's Punks button.
-------------------------------------------------------------------------------

function Nx.Punks:ToggleListWin()
	if not self.ListWin then
		self:CreateListWin()
	end
	if self.ListWin:IsShown() then
		self.ListWin:Show(false)
	else
		self.ListWin:Show(true)
		self:UpdateListWin()
	end
end

function Nx.Punks:CreateListWin()
	local win = Nx.Window:Create("NxPunkList", 320, 200, nil, 1)
	self.ListWin = win
	win.Frm.NxInst = self

	win:CreateButtons(true, true)
	win:SetTitle(L["Punks"])
	win:InitLayoutData(nil, -.3, -.25, -.55, -.5)
	win.Frm:SetToplevel(true)
	win:Show(false)
	tinsert(UISpecialFrames, win.Frm:GetName())

	-- "Add by name..." button at the top
	local bw, bh = win:GetBorderSize()
	Nx.Button:Create(win.Frm, "Txt64", L["Add Character"], nil, bw + 1, -bh, "TOPLEFT", 100, 20,
		Nx.Punks.ListWin_OnAddBut, self)

	-- Main list. The character column carries an inline class icon (via WoW
	-- texture-escape markup) and class-colored name; the class column shows
	-- the class label also class-colored, so the punk is identifiable at a
	-- glance even on a name you don't recognize.
	Nx.List:SetCreateFont("Font.Medium", 14)
	local list = Nx.List:Create("PunkList", 0, 0, 1, 1, win.Frm)
	self.ListUI = list
	list:SetUser(self, self.ListWin_OnListEvent)
	list:SetLineHeight(2)
	list:ColumnAdd(L["Status"], 1, 60)
	list:ColumnAdd(L["Character"] or "Name", 2, 150)
	list:ColumnAdd(L["Lvl"] or "Lvl", 3, 40)
	list:ColumnAdd(L["Class"] or "Class", 4, 90)
	list:ColumnAdd(L["Note"], 5, 400)
	win:Attach(list.Frm, 0, 1, 22, 1)

	-- Context menu (right-click)
	local menu = Nx.Menu:Create(list.Frm, 200)
	self.ListMenu = menu
	menu:AddItem(0, L["Goto"], self.ListMenu_OnGoto, self)
	menu:AddItem(0, "")
	menu:AddItem(0, L["Add Character"], self.ListMenu_OnAddPermanent, self)
	menu:AddItem(0, L["Set note"], self.ListMenu_OnSetNote, self)
	menu:AddItem(0, "")
	menu:AddItem(0, L["Remove Character"], self.ListMenu_OnRemove, self)
end

function Nx.Punks:UpdateListWin()
	local list = self.ListUI
	if not list then return end

	list:Empty()

	local punks = Nx:GetPunks("Pk")
	local active = self.PunksActive or {}

	-- Permanent punks first (alpha-sort by name)
	local pNames = {}
	for name in pairs(punks) do pNames[#pNames + 1] = name end
	table.sort(pNames)

	for _, name in ipairs(pNames) do
		local _, lvl, class, note, classFile = strsplit("~", punks[name])
		local actInfo = active[name]
		-- Active classFile takes precedence (more current)
		if actInfo and actInfo.ClassID then classFile = actInfo.ClassID end

		local statusCol
		if actInfo then
			statusCol = "|cffff4040Punk"
		else
			statusCol = "|cffff8080Permanent"
		end

		local color = classColorEsc(classFile)
		local nameCell = classIconMarkup(classFile) .. (color ~= "" and (color .. name .. "|r") or name)
		local classCell = (color ~= "" and (color .. (class or "") .. "|r") or (class or ""))

		list:ItemAdd({ kind = "perm", name = name })
		list:ItemSet(1, statusCol)
		list:ItemSet(2, nameCell)
		list:ItemSet(3, (lvl and lvl ~= "") and lvl or "?")
		list:ItemSet(4, classCell)
		list:ItemSet(5, note or "")
	end

	-- Active sightings that aren't already in the permanent list
	local aNames = {}
	for name in pairs(active) do
		if not punks[name] then aNames[#aNames + 1] = name end
	end
	table.sort(aNames)

	for _, name in ipairs(aNames) do
		local info = active[name]
		local classFile = info.ClassID
		local color = classColorEsc(classFile)
		local nameCell = classIconMarkup(classFile) .. (color ~= "" and (color .. name .. "|r") or name)
		local classCell = (color ~= "" and (color .. (info.Class or "") .. "|r") or (info.Class or ""))

		list:ItemAdd({ kind = "active", name = name })
		list:ItemSet(1, "|cffa0c0ffActive")
		list:ItemSet(2, nameCell)
		list:ItemSet(3, (info.Lvl and info.Lvl > 0) and tostring(info.Lvl) or "?")
		list:ItemSet(4, classCell)
		list:ItemSet(5, "")
	end

	list:Update()

	self.ListWin:SetTitle(format(L["Punks: %s  Active: %s"], #pNames, #aNames))
end

-- "Add by name..." button — opens edit box, accepts a player name to
-- add to the permanent flagged list.
function Nx.Punks:ListWin_OnAddBut(but)
	local function accept(text, self)
		if text and text ~= "" then
			Nx.Punks:PunkAdd(text:match("^%s*(.-)%s*$"))
			Nx.Punks:UpdateListWin()
		end
	end
	Nx:ShowEditBox(L["Add punk name"], "", self, accept)
end

function Nx.Punks:ListWin_OnListEvent(eventName, sel, val2, click)
	local data = self.ListUI:ItemGetData(sel)
	if not data then return end

	self.ListSelData = data
	if eventName == "menu" then
		self.ListMenu:Open()
	elseif eventName == "mid" then
		-- Middle-click navigates straight to the punk
		self:GotoPunk(data.name)
	end
end

function Nx.Punks:ListMenu_OnGoto()
	if self.ListSelData then
		self:GotoPunk(self.ListSelData.name)
	end
end

function Nx.Punks:ListMenu_OnAddPermanent()
	local d = self.ListSelData
	if not d then return end
	local active = self.PunksActive[d.name]
	if active then
		self:PunkAdd(d.name, active.Lvl, active.Class)
	else
		self:PunkAdd(d.name)
	end
	self:UpdateListWin()
end

function Nx.Punks:ListMenu_OnSetNote()
	local d = self.ListSelData
	if not d then return end
	local punks = Nx:GetPunks("Pk")
	local existing = punks[d.name]
	if not existing then
		Nx.prt("Punk '%s' not in your permanent list — promote it first", d.name)
		return
	end
	local _, _, _, note = strsplit("~", existing)
	local function accept(text, name)
		Nx.Punks:PunkSetNote(name, text or "")
		Nx.Punks:UpdateListWin()
	end
	Nx:ShowEditBox(L["Set note"], note or "", d.name, accept)
end

function Nx.Punks:ListMenu_OnRemove()
	local d = self.ListSelData
	if not d then return end
	-- Remove from the permanent list (no-op if it wasn't there) AND clear
	-- the active sighting cache so the row disappears immediately. The HUD
	-- entry is removed too. If the punk is encountered again (combat log,
	-- target, etc.) it'll re-appear; that's the right behaviour.
	self:PunkRemove(d.name)
	if self.PunksActive[d.name] then
		self.PunksActive[d.name] = nil
		self.HUD:Remove(d.name)
	end
	self:UpdateListWin()
end

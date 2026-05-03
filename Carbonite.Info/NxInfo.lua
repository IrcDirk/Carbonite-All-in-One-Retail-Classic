---------------------------------------------------------------------------------------
-- NxInfo - Information window
-- Copyright 2008-2012 Carbon Based Creations, LLC
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Carbonite - Addon for World of Warcraft(tm)
-- Copyright 2007-2012 Carbon Based Creations, LLC
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------

CarboniteInfo = LibStub("AceAddon-3.0"):NewAddon("Carbonite.Info", "AceEvent-3.0", "AceComm-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Info", true)

Nx.VERSIONINFO			= .24				-- Info win data
Nx.Info = {}
Nx.InfoStats = {}
Nx.Info.Combat = {}

-- Per-flavor currency lookup. Honor/Conquest IDs and the API itself differ:
--   Wrath/Cata/MoP Classic: GetCurrencyInfo(id) global, name/amount return.
--                           Honor=392, Conquest=390 (Cata+ only).
--   Retail (Legion+):       C_CurrencyInfo.GetCurrencyInfo(id) returns table.
--                           Honor=1792, Conquest=1602 (PvP-season-bound).
--   Era / TBC:              No honor/conquest currency in this form -> 0.
local function GetCurrencyAmount(classicId, retailId)
	if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and retailId then
		local info = C_CurrencyInfo.GetCurrencyInfo(retailId)
		return info and info.quantity or 0
	end
	if classicId and _G.GetCurrencyInfo then
		local _, amount = _G.GetCurrencyInfo(classicId)
		return amount or 0
	end
	return 0
end

local function GetHonorAmount()
	return GetCurrencyAmount(392, 1792)
end

local function GetConquestAmount()
	return GetCurrencyAmount(390, 1602)
end

local defaults = {
	profile = {
		Info = {
			ListCol = "0|0|0|0.4",
			Lock = false,
			InfoFont = "Arial",
			InfoFontSize = 11,
			InfoFontSpacing = 0,
			-- Kill marker icons (skull) on the Carbonite map. PARTY_KILL events
			-- captured by the combat tracker get persisted as map events and
			-- rendered as Skull icons by Nx.UEvents:UpdateMap. Tooltip shows
			-- the kill timestamp and NPC ID, so the markers are now genuinely
			-- useful as a "where did I last kill X" reference.
			KillIcons = true,
			KillIconAutoClearSecs = 0,       -- 0 = never hide; >0 = hide after N seconds
			-- When true, the auto-clear timer only HIDES expired markers but
			-- preserves the underlying records in saved variables. Useful as
			-- a permanent kill log for later inspection. When false (default),
			-- expired markers are pruned from saved data on render.
			KillIconKeepForever = false,
		},
	},
}
local options

local function createOptions()
	if not options then
		options = {
			type = "group",
			name = L["Info Options"],
			args = {
				InfoLock = {
					order = 1,
					type = "toggle",
					width = "full",
					name = L["Lock Info Windows"],
					desc = L["Locks the location of your info windows"],
					get = function()
						return Nx.idb.profile.Info.Lock
					end,
					set = function()
						Nx.idb.profile.Info.Lock = not Nx.idb.profile.Info.Lock
						Nx.Info:OptionsUpdate()
					end,
				},
				InfoBGCol = {
					order = 2,
					type = "color",
					width = "full",
					name = L["Info Window Background Color"],
					hasAlpha = true,
					get = function()
						local arr = { strsplit("|",Nx.idb.profile.Info.ListCol) }
						local r = arr[1]
						local g = arr[2]
						local b = arr[3]
						local a = arr[4]
						return r,g,b,tonumber(a)
					end,
					set = function(_,r,g,b,a)
						Nx.idb.profile.Info.ListCol = r .. "|" .. g .. "|" .. b .. "|" .. a
						Nx.Info:OptionsUpdate()
					end,
				},
				InfoFont = {
					order = 3,
					type = "select",
					name = L["Info Font"],
					desc = L["Sets the font to be used for info windows"],
					get	= function()
						local vals = Nx.Opts:CalcChoices("FontFace","Get")
						for a,b in pairs(vals) do
						  if (b == Nx.idb.profile.Info.InfoFont) then
							 return a
						  end
						end
						return ""
					end,
					set	= function(info, name)
						local vals = Nx.Opts:CalcChoices("FontFace","Get")
						Nx.idb.profile.Info.InfoFont = vals[name]
						Nx.Opts:NXCmdFontChange()
					end,
					values	= function()
						return Nx.Opts:CalcChoices("FontFace","Get")
					end,
				},
				InfoFontSize = {
					order = 4,
					type = "range",
					name = L["Info Font Size"],
					desc = L["Sets the size of the info font"],
					min = 6,
					max = 14,
					step = 1,
					bigStep = 1,
					get = function()
						return Nx.idb.profile.Info.InfoFontSize
					end,
					set = function(info,value)
						Nx.idb.profile.Info.InfoFontSize = value
						Nx.Opts:NXCmdFontChange()
					end,
				},
				InfoFontSpacing = {
					order = 5,
					type = "range",
					name = L["Info Font Spacing"],
					desc = L["Sets the spacing of the info font"],
					min = -10,
					max = 20,
					step = 1,
					bigStep = 1,
					get = function()
						return Nx.idb.profile.Info.InfoFontSpacing
					end,
					set = function(info,value)
						Nx.idb.profile.Info.InfoFontSpacing = value
						Nx.Opts:NXCmdFontChange()
					end,
				},
				KillIconsHeader = {
					order = 10,
					type = "header",
					name = L["Kill Icons"] or "Kill Icons",
				},
				KillIconsEnable = {
					order = 11,
					type = "toggle",
					width = "full",
					name = L["Show kill markers on map"] or "Show kill markers on map",
					desc = L["When enabled, killed mobs leave a skull icon on your map at the kill location"]
						or "When enabled, killed mobs leave a skull icon on your map at the kill location",
					get = function() return Nx.idb.profile.Info.KillIcons end,
					set = function() Nx.idb.profile.Info.KillIcons = not Nx.idb.profile.Info.KillIcons end,
				},
				KillIconKeepForever = {
					order = 12,
					type = "toggle",
					width = "full",
					name = L["Keep kill history"] or "Keep kill history",
					desc = L["When enabled, the auto-clear timer only hides expired markers but keeps the kill records in saved variables. Useful as a permanent kill log."]
						or "When enabled, the auto-clear timer only hides expired markers but keeps the kill records in saved variables. Useful as a permanent kill log.",
					get = function() return Nx.idb.profile.Info.KillIconKeepForever end,
					set = function() Nx.idb.profile.Info.KillIconKeepForever = not Nx.idb.profile.Info.KillIconKeepForever end,
				},
				KillIconAutoClearSecs = {
					order = 13,
					type = "range",
					name = L["Auto-clear kill markers after"] or "Auto-clear kill markers after",
					desc = L["Seconds before a kill marker disappears automatically. 0 = never (manual clear only)"]
						or "Seconds before a kill marker disappears automatically. 0 = never (manual clear only)",
					min = 0,
					max = 180,
					step = 5,
					bigStep = 15,
					get = function() return Nx.idb.profile.Info.KillIconAutoClearSecs end,
					set = function(_, value) Nx.idb.profile.Info.KillIconAutoClearSecs = value end,
				},
			},
		}
	end
	Nx.Opts:AddToProfileMenu(L["Info"],2,Nx.idb)	
	return options
end

function CarboniteInfo:OnInitialize()
	if not Nx.Initialized then
		CarbInfoInit = Nx:ScheduleTimer(CarboniteInfo.OnInitialize,1)
		return
	end
	Nx.idb = LibStub("AceDB-3.0"):New("NXInfo",defaults, true)
	Nx.Font:ModuleAdd("Info.InfoFont",{ "NxFontI", "GameFontNormal","idb" })
	Nx.Info:Init()
	Nx.Info.Combat:Init()
	-- Combat:Open() defers its own first-time setup through C_Timer.After
	-- so the frame is born outside any tainted caller (AceTimer chain,
	-- minimap menu callback, etc.) — safe to call directly.
	Nx.Info.Combat:Open()
	CarboniteInfo:PLAYER_LOGIN()
	local function func ()
		Nx.Info:ToggleShow()
	end
	Nx.NXMiniMapBut.Menu:AddItem(0, L["Show Info Windows"], func, Nx.NXMiniMapBut)
	local function func ()
		Nx.Info.Combat:Open()
	end
	Nx.NXMiniMapBut.Menu:AddItem(0, L["Show Combat Graph"], func, Nx.NXMiniMapBut)
	CarboniteInfo:RegisterEvent("PLAYER_LOGIN")
	CarboniteInfo:RegisterComm("carbmodule",Nx.Info.OnChat_msg_addon)

	-- Periodically nudge UEvents:UpdateMap so kill/death events past their
	-- auto-clear threshold actually get pruned + redrawn. UpdateMap is normally
	-- only called on zone change, which isn't enough when the user is standing
	-- around expecting markers to fade after N seconds. Cheap call (just walks
	-- the events list and re-acquires icons), so a 5s cadence is fine.
	Nx.Info.KillExpireTicker = C_Timer.NewTicker(5, function()
		local secs = Nx.idb and Nx.idb.profile.Info and Nx.idb.profile.Info.KillIconAutoClearSecs
		if secs and secs > 0 and Nx.UEvents and Nx.UEvents.UpdateMap then
			Nx.UEvents:UpdateMap()
		end
	end)
	tinsert(Nx.BrokerMenuTemplate,{ text = L["Toggle Info Windows"], func = function() Nx.Info:ToggleShow()end })
	tinsert(Nx.BrokerMenuTemplate,{ text = L["Toggle Combat Graph"], func = function() Nx.Info.Combat:Open() end })

	-- Map toolbar button: same widget that hosts Guide / Notes / Warehouse / etc.
	Nx.Button.TypeData["MapInfo"] = {
		Up = "$INV_Misc_Note_05",
		SizeUp = 22,
		SizeDn = 22,
	}
	function Nx.Info.OnButToggleInfo(self, but)
		Nx.Info:ToggleShow()
	end
	tinsert(Nx.BarData, {"MapInfo", L["Info"], Nx.Info.OnButToggleInfo, false})
	if Nx.Map and Nx.Map.Maps and Nx.Map.Maps[1] then
		Nx.Map.Maps[1]:CreateToolBar()
	end
end

function CarboniteInfo:PLAYER_LOGIN()
	local ch = Nx.CurCharacter
	local xprest = GetXPExhaustion() or 0
	local xpmax = UnitXPMax ("player")
	Nx.InfoStats["ArenaPts"] = GetConquestAmount()
	Nx.InfoStats["Honor"] = GetHonorAmount()
	Nx.InfoStats["XPRest%"] = xprest / xpmax * 100
end


function Nx.Info:Init()
	local info = Nx.idb.profile.InfoData

	if not info or info.Version < Nx.VERSIONINFO then
		if info then
			Nx.prt (L["Reset old info data %f"], info.Version)
		end
		info = {}
		Nx.idb.profile.InfoData = info
		info.Version = Nx.VERSIONINFO
	end

	local cls = Nx:GetUnitClass()

	if cls == "Death Knight" or cls == "Warrior" then
		self.ManaInvert = true
	end

	if cls == "Death Knight" then
		self.DeathKnight = true
	end

	self.DKRunes = {
		{ 1, "|cffff8080" },			-- Blood
		{ 2, "|cffff8080", true },
		{ 5, "|cff8080ff" },			-- Frost
		{ 6, "|cff8080ff", true },
		{ 3, "|cff80ff80" },			-- Unholy
		{ 4, "|cff80ff80" },
	}

	self.Vars = {}		-- Variables

	self.Infos = {}	-- Remember all created info windows

	self.ItemFuncs = {
		["BarH%"] = self.CalcBarHPercent,
		["Cast"] = self.CalcCast,
		["Combo"] = self.CalcComboPoints,
		["Cooldown"] = self.CalcCooldown,
		["Dur"] = self.CalcDur,
		["FPS"] = self.CalcFPS,
		["Health"] = self.CalcHealth,
		["Health%"] = self.CalcHealthPercent,
		["HealthChange"] = self.CalcHealthChange,
		["IfBG"] = self.CalcIfBG,
		["IfCombat"] = self.CalcIfCombat,
		["IfF"] = self.CalcIfFalse,
		["IfLT"] = self.CalcIfLT,
		["IfLTOrCombat"] = self.CalcIfLTOrCombat,
		["IfMana"] = self.CalcIfMana,
		["IfT"] = self.CalcIfTrue,
		["LvlTime"] = self.CalcLvlTime,
		["Mana"] = self.CalcMana,
		["Mana%"] = self.CalcManaPercent,
		["ManaChange"] = self.CalcManaChange,
		["BGQueue"] = self.CalcBGQueue,
		["BGStart"] = self.CalcBGStart,
		["BGDuration"] = self.CalcBGDuration,
		["BGHonor"] = self.CalcBGHonor,
		["BGStats"] = self.CalcBGStats,
		["BGWingWait"] = self.CalcBGWingWait,
		["Stat"] = self.CalcStat,
		["THealth"] = self.CalcTargetHealth,
		["THealth%"] = self.CalcTargetHealthPercent,
--		["THealthChange"] = self.CalcTargetHealthChange,
		["Threat%"] = self.CalcThreatPercent,
		["TMana"] = self.CalcTargetMana,
		["TMana%"] = self.CalcTargetManaPercent,
--		["TManaChange"] = self.CalcTargetManaChange,
		["Time"] = self.CalcTime,
	}

	local dinfo = Nx.idb.profile.InfoData
	self:OnTimer()
--	self:Create (1)

	for n = 1, 10 do

		local info = dinfo[n]

		if info then
			self:Create (n)
		end
	end

	self:CreateMenu()
	Nx:AddToConfig("Info Module",createOptions(),L["Info Module"])		
	self:OptionsUpdate()
end

function Nx.Info.Combat:Init()
	self.Frm = nil
	self.HitPeak = 1
	self.HitTotal = 0
	self.HitBest = 0
	self.W = 400
	self.H = 80
	self.InCombat = false
	self.AttackerName = "?"
end

function Nx.Info:OnChat_msg_addon(msg, dist, target)
	local ssplit = { strsplit("|",msg) }
	if ssplit[1] == "CMD" then
		if ssplit[2] == "c" then
			Nx.Info.Combat:Open()
		end
	end
end

---------------------------------------------------------------------------------------
-- Update all info windows
---------------------------------------------------------------------------------------

-- Retail wraps unit health/power values in opaque "secret number" types
-- when an addon's execution context is tainted (e.g., reading these APIs
-- from a timer tick that touched secure templates). The wrapped values
-- assign and pass through fine, but ANY arithmetic with a plain number
-- (h / max, h - prev, h * 100) throws "attempt to perform arithmetic on
-- a secret number value". Convert to a plain number at the boundary so
-- every downstream consumer (percentage, delta, format) sees a real
-- number. Returns 0 when conversion fails — for that tick the readout
-- snaps to 0 and recovers automatically when the taint clears.
local function _safeN (v)
	if v == nil then
		return 0
	end
	local ok, r = pcall (function () return v + 0 end)
	return ok and r or 0
end

local function _safeRatio (a, b)
	a, b = _safeN (a), _safeN (b)
	if b == 0 then
		return 0
	end
	return a / b
end

function Nx.Info:OnTimer()

	local vars = self.Vars

	self.NeedDurability = false

	local h = UnitHealth ("player")
	local m = UnitPower ("player")
	if UnitIsDeadOrGhost ("player") then
		h = 0
		m = 0
	end
	-- Normalize through _safeN so the rest of the addon never sees a
	-- secret-wrapped number on retail.
	vars["Health"] = _safeN (h)
	vars["Mana"]   = _safeN (m)

	vars["HealthMax"] = _safeN (UnitHealthMax ("player"))
	vars["ManaMax"]   = _safeN (UnitPowerMax ("player"))

	vars["Health%"] = _safeRatio (vars["Health"], vars["HealthMax"])
	vars["Mana%"]   = _safeRatio (vars["Mana"],   vars["ManaMax"])

	local h = 0
	local m = -1

	local tarName = UnitName ("target")
	vars["TName"] = tarName

	if tarName then

		m = UnitPowerMax ("target") > 0 and 0 or -1
		if not UnitIsDeadOrGhost ("target") then
			h = UnitHealth ("target")
			m = UnitPowerMax ("target") > 0 and UnitPower ("target") or -1
		end

		vars["THealthMax"] = max (_safeN (UnitHealthMax ("target")), 1)
		vars["TManaMax"]   = max (_safeN (UnitPowerMax  ("target")), 1)
	end
	vars["THealth"] = _safeN (h)
	vars["TMana"]   = (m == -1) and -1 or _safeN (m)

	vars["InBG"] = Nx.InBG

	for i, info in pairs (self.Infos) do
		if info.Data then		-- Not deleted?
			info:Update (n)
		end
	end

	return .1
end

---------------------------------------------------------------------------------------

function Nx.Info:OptionsUpdate()
	local lock = Nx.idb.profile.Info.Lock

	for i, info in pairs (self.Infos) do

		local win = info.Win
		if win then

			win:SetBGAlpha (0, 1)
			if lock then
				win:Lock (true, true)
			else
				win:Lock (false, true)
			end
			info.List:Lock (lock)
			local arr = { strsplit("|",Nx.idb.profile.Info.ListCol) }
			local cr = tonumber(arr[1])
			local cg = tonumber(arr[2])
			local cb = tonumber(arr[3])
			local ca = tonumber(arr[4])
			info.List:SetBGColor (cr, cg, cb, ca, true)
		end
	end
end

---------------------------------------------------------------------------------------

function Nx.Info:New()

	local dinfo = Nx.idb.profile.InfoData

	for n = 1, 10 do

		if not dinfo[n] then
			self:Create (n)
			self.Infos[n].Win:ResetLayout()
			break
		end
	end

	self:OptionsUpdate()
end

---------------------------------------------------------------------------------------
-- Delete the info window
---------------------------------------------------------------------------------------

function Nx.Info:Delete (index)

	Nx.idb.profile.InfoData[index] = nil

	local info = self.Infos[index]
	if info then
		info.Win:Show (false)
	end

	info.Data = nil

	Nx.Window:ClrSaveData ("NxInfo" .. index)
end

---------------------------------------------------------------------------------------
-- Create shared menu
---------------------------------------------------------------------------------------

function Nx.Info:CreateMenu()

	local menu = Nx.Menu:Create (UIParent, 160)
	self.Menu = menu

	self.MenuITitle = menu:AddItem (0, "?", nil, self)

	local item = menu:AddItem (0, L["Close"], self.Menu_OnClose, self)
	self.MenuIEdit = menu:AddItem (0, "?", self.Menu_OnEdit, self)
	menu:AddItem (0, L["Edit Item"], self.Menu_OnEditItem, self)
	menu:AddItem (0, "", nil, self)

	-- Create show sub menu

	local showMenu = Nx.Menu:Create (UIParent)
	menu:AddSubMenu (showMenu, L["Show"] .. "...")

	self.MenuIShow = {}

	for n = 1, 10 do
		local function func (self, item)
--			Nx.prt ("%s", n)
			Nx.Info.Infos[n].Win:Show()
		end
		self.MenuIShow[n] = showMenu:AddItem (0, "#" .. n, func, self)
	end

	--

	menu:AddItem (0, "", nil, self)
	local item = menu:AddItem (0, L["New Info Window"], self.Menu_OnNew, self)
	local item = menu:AddItem (0, L["Delete This Window"], self.Menu_OnDelete, self)

	--

	menu:AddItem (0, "", nil, self)

	local function func()
		Nx.Opts:Open ("Info Windows")
	end

	menu:AddItem (0, L["Options"] .. "...", func)

end

---------------------------------------------------------------------------------------
-- Create menu
---------------------------------------------------------------------------------------

function Nx.Info:OpenMenu (info)

	self.CurMenuInfo = info

	self.MenuITitle:SetText (format ("-- " .. L["Info"] .. " %d --", info.Index))
	self.MenuIEdit:SetText (info.Editing and L["Stop Edit"] or L["Edit View"])

	for n = 1, 10 do
		local info = self.Infos[n]
		local b = info and info.Data and not self.Infos[n].Win:IsShown()
		self.MenuIShow[n]:Show (b == true)
	end

	self.Menu:Open()
end

---------------------------------------------------------------------------------------

function Nx.Info:Menu_OnClose()
	self.CurMenuInfo.Win:Show (false)
end

function Nx.Info:Menu_OnEdit()
	local info = self.CurMenuInfo

	local editing = not info.Editing
	info.Editing = editing

--	info.Win:SetTitleLineH (editing and 18 or 0)
end

function Nx.Info:Menu_OnEditItem()

	local info = self.CurMenuInfo

	local function func (str, self)
		str = gsub (str, "||", "|")
		self.Data["Items"][self.SelItemIndex] = str
	end

	if info.SelItemIndex then
		local s = info.Data["Items"][info.SelItemIndex] or ""
		s = gsub (s, "|", "||")
		Nx:ShowEditBox (L["Change Text"], s, info, func)
	end
end

function Nx.Info:Menu_OnNew (item)
	self:New()
end

function Nx.Info:Menu_OnDelete (item)

	local function func()
		Nx.Info:Delete (Nx.Info.CurMenuInfo.Index)
	end

	Nx:ShowMessage (L["Delete Info Window"] .. " #" .. self.CurMenuInfo.Index .. "?", L["Delete"], func, L["Cancel"])
end

---------------------------------------------------------------------------------------
-- Create info window
---------------------------------------------------------------------------------------

function Nx.Info:Create (index)

--	Nx.prt ("Info: create %s", index)

	local info = self.Infos[index] or {}

	self.Infos[index] = info

	setmetatable (info, self)
	self.__index = self

	info:Create2 (index)
end

---------------------------------------------------------------------------------------
-- Create info window
-- self = instance
---------------------------------------------------------------------------------------

function Nx.Info:Create2 (index)

--PAIDS!

	self.Index = index

	self.Data = Nx.idb.profile.InfoData[index] or {}
	Nx.idb.profile.InfoData[index] = self.Data

	--

	local items = self.Data["Items"]

--	items = nil		-- DEBUG

	if not items then
		items = {}
		self.Data["Items"] = items

		if index == 1 then
			tinsert (items, "<IfLTOrCombat;1;Health%><Health><c>HP <t> <HealthChange><c><t> <IfCombat>|cffff4040* <Threat%;player><c><t>")
			tinsert (items, "<IfLTOrCombat;1;Health%>     <Health%><c><t>%<BarH%;G;Health%><t>")
			tinsert (items, "<IfMana><Mana><c>MP <t> <ManaChange><c><t>")
			tinsert (items, "<IfMana>     <Mana%><c><t>%<BarH%;B;Mana%><t>")
			tinsert (items, "<Combo><c><t>")
			tinsert (items, "<Cooldown><c><t>")
			tinsert (items, "<Cast><c><t>")
		elseif index == 2 then
			tinsert (items, "<THealth><c>HP <t>")
			tinsert (items, "     <THealth%><c><t>%<BarH%;G;THealth%><t>")
			tinsert (items, "<TMana><c>MP <t>")
			tinsert (items, "     <TMana%><c><t>%<BarH%;B;TMana%><t>")
			tinsert (items, "<Cast;target><c><t>")
		elseif index == 3 then
			tinsert (items, "<Dur><c>Durability <t>%")
			tinsert (items, "<LvlTime><c>Lvl <t> hours")
			tinsert (items, "")
		elseif index == 4 then
			tinsert (items, "<BGQueue;1><c><t>")
			tinsert (items, "<BGQueue;2><c><t>")
			tinsert (items, "<BGQueue;3><c><t>")
			tinsert (items, "<BGStart><c>BG start <t>")
			tinsert (items, "<BGDuration><c>BG duration <t>")
			tinsert (items, "<IfF;InBG><BGWingWait><c>Wing <t>")
			tinsert (items, "<IfBG><BGHonor><c>Honor <t>")
			tinsert (items, "<BGStats><c>Stats <t>")
		elseif index == 5 then
			tinsert (items, "<Time;%a %m/%d %I:%M %p><c><t>")
			tinsert (items, "<FPS><t>")
			tinsert (items, "")
		elseif index == 6 then
			tinsert (items, "<Stat;XPRest%><c>Rest <t>%")
			tinsert (items, "")
			tinsert (items, "")
		end
	end

	-- _safeN normalizes retail's tainted "secret number" values to plain
	-- numbers; HealthLast/ManaLast feed into arithmetic in CalcHealthChange
	-- and CalcManaChange, which can't operate on the wrapped form.
	self.HealthLast = _safeN (UnitHealth ("player"))
	self.HealthLastVal = 0
	self.ManaLast = _safeN (UnitPower ("player"))
	self.ManaLastVal = 0

	-- Show if it exists

--	Nx.Window:ClrSaveData ("NxInfo" .. index)

	if self.Win then
		self.Win:Show()
		return
	end

	-- Create Window

	local layouts = {
		[0] = { -.72, -.2, 100, 41 },
		{ 200000, -.20, 110, 80, 1.1 },
		{ 300040, -.20, 120, 80, 1.1 },
	}

	Nx.Window:SetCreateFade (1, 0)

	local win = Nx.Window:Create ("NxInfo" .. index, 50, 20, nil, 1, nil, nil, true)
	self.Win = win
	win.Frm.NxInst = self

--	win:CreateButtons (true)
	win:SetTitleLineH (3)

	local layout = layouts[index] or layouts[0]

--	Nx.prt ("#%s %s %s %s %s", index, layout[1], layout[2], layout[3], layout[4])

	local i = index <= 2 and 0 or index - 3

	local scale = layout[5] or 1
	local x = layout[3] + scale * layout[4] - layout[4]

	win:InitLayoutData (nil, layout[1], layout[2] - i * .06, x, layout[4], nil, layout[5])
	win.Frm:SetToplevel (true)

	-- Buttons

	local bw, bh = win:GetBorderSize()

--	local but = Nx.Button:Create (win.Frm, "Txt64", "Up", nil, bw, -bh, "TOPLEFT", 44, 20, self.But_OnUp, self)
--	local but = Nx.Button:Create (but.Frm, "Txt64", "Down", nil, 46, 0, "TOPLEFT", 44, 20, self.But_OnDown, self)

	-- List

	Nx.List:SetCreateFont ("Info.InfoFont", 11)

	local list = Nx.List:Create (false, 0, 0, 1, 1, win.Frm, false, true)
	self.List = list

	list:SetUser (self, self.OnListEvent)
	list:SetLineHeight (0, 0)

	list:ColumnAdd ("", 1, 900)

--	list:SetBGColor (0, 0, 0, .1)

	win:Attach (list.Frm, 0, 1, 0, 1)

	--

	self.Frms = {}		-- For health bars
	self.Frms.Next = 1

	--
	self:Update()
	self.List:FullUpdate()
--PAIDE!
end

---------------------------------------------------------------------------------------
-- Show or hide
---------------------------------------------------------------------------------------

--function Nx:NXInfoKeyToggleShow()
--	Nx.Info:ToggleShow()
--end

---------------------------------------------------------------------------------------
-- Show or hide window
---------------------------------------------------------------------------------------

function Nx.Info:ToggleShow()

	for n = 1, 2 do

		local info = self.Infos[n]

		if not info or not info.Data then		-- Deleted?
			self:Create (n)
		else
			info.Win:Show (not info.Win:IsShown())
		end
	end
end

---------------------------------------------------------------------------------------
-- On list events
---------------------------------------------------------------------------------------

function Nx.Info:OnListEvent (eventName, sel, val2, click)

--	Nx.prt ("Guide list event "..eventName)

	if eventName == "update"  then

		local listF = self.List.Frm
		local lvl = listF:GetFrameLevel() - 1

		local data = sel
		local y = val2

		local t = { strsplit ("&", data) }

		for _, str in ipairs (t) do

--			Nx.prt ("info %s", str)

			local v1, v2, v3 = strsplit ("^", str)

			local f = Nx.List:GetFrame (self.List, "Info")
			f:ClearAllPoints()

			f:SetPoint ("TOPLEFT", listF, "TOPLEFT", 0, y)
			f:SetFrameLevel (lvl)
			f.texture:SetTexture (v1)
			f:SetWidth (tonumber (v2) or 0)
			f:SetHeight (tonumber (v3) or 0)
			f:SetAlpha (.8)
			f:Show()
		end

		return
	end

	local data = self.List:ItemGetData (sel)

	if eventName == "select" or eventName == "mid" or eventName == "menu" then

		if eventName == "menu" then
			self.SelItemIndex = data
			Nx.Info:OpenMenu (self)
		end

		self:Update()
	end
end

function Nx.Info:Update()

	local Nx = Nx

	if not self.Win or not self.Win:IsVisible() then
		return
	end

	-- List

	local list = self.List

	list:Empty()

	self:UpdateItems()

	list:Update()

end

--PAIDS!

function Nx.Info:UpdateItems()

	local funcs = self.ItemFuncs

	local list = self.List
	local ch = Nx.CurCharacter

	local items = self.Data["Items"]

	for index, val in ipairs (items) do

		local data = strsplit ("^", val)

		local str = ""
		local pos = 1

		local color, text

		while true do
--			local s1, s2, cap, extra = strfind (data, "<(%a+%%?)([^>]*)>", pos)
			local s1, s2, cap = strfind (data, "<([^>]+)>", pos)
			if s1 then
				if s1 > pos then
					str = str .. strsub (data, pos, s1 - 1)
				end

--				Nx.prtCtrl ("item cap %s", cap)

				if #cap == 1 then
					if cap == "c" and color then
						str = str .. color
					elseif cap == "t" and text then
						str = str .. text
					end

				else
					local cmd, v1, v2, v3, v4 = strsplit (";", cap)	-- FIX for multiple params!
					local func = self.ItemFuncs[cmd]
					if func then
						color, text = func (self, v1, v2, v3, v4)
						if not text then
							break
						end
					end
				end

				pos = s2 + 1
			else

				str = str .. strsub (data, pos)	-- Grab end
				break
			end
		end

		if self.Editing then
			str = format ("#%d %s = ", index, gsub (data, "|", "||")) .. str
		end

		if #str > 0 then

--			Nx.prtStrHex ("Info:", str)

			list:ItemAdd (index)

			local str, extra = strsplit ("~", str)

			if extra then
				list:ItemSetFrame ("Info~" .. extra)
			end

			list:ItemSet (1, str)
		end
	end
end

--PAIDE!

---------------------------------------------------------------------------------------

function Nx.Info:CalcBarHPercent (color, perName, w, h)

	w = tonumber (w) or 50
	h = tonumber (h) or 10

	local barW = (self.Vars[perName] or 0) * w		-- perNamemax (0, min ((self.Val1 or 0) / (self.Val2 or 1), 1))

	local xo = w

	if barW >= 1 then
		return "|cffc0c0c0", format ("~Interface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBarBG^%d^%d^0&Interface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBar%s^%d^%d^%d", w, h, color, barW, h, xo)
--		return "|cffc0c0c0", format ("|TInterface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBarBG:%d:%d|t^Interface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBar%s~%d~%d~%d", h, w, color, barW, h, xo)
--		return "|cffc0c0c0", format ("|TInterface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBarBG:%d:%d|t|TInterface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBar%s:%d:%d:-%d|t", h, w, color, h, barW, xo)
	end

	return "|cffc0c0c0", format ("~Interface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBarBG^%d^%d^0", w, h)
--	return "|cffc0c0c0", format ("|TInterface\\Addons\\Carbonite\\Gfx\\Skin\\InfoBarBG:%d:%d|t", h, w)
end

function Nx.Info:CalcCast (target, w, h)

	target = target or "player"

	w = tonumber (w) or 50
	h = tonumber (h) or 10

	local spell, rank, name, icon, startTime, endTime = UnitCastingInfo (target)

	if not name then
		spell, rank, name, icon, startTime, endTime = UnitChannelInfo (target)
	end

	if name then
		local remain = endTime / 1000 - GetTime()
		local per = remain * 1000 / (endTime - startTime)
		return "|cffc0c0f0", format ("|T%s:16|t %.1f |TInterface\\BUTTONS\\gradblue:%d:%d|t", icon, remain, h, max (per * w, 1))
	end
end

function Nx.Info:CalcFPS()
	return "|cffc0c0c0", format ("%.0f", GetFramerate())
end

function Nx.Info:CalcHealth()
	return "|cffc0c0c0", format ("%d", self.Vars["Health"])
end

function Nx.Info:CalcHealthPercent()
	return "|cffe0e0e0", format ("%d", self.Vars["Health%"] * 100)
end

function Nx.Info:CalcHealthChange()

	local i = self.Vars["Health"] - self.HealthLast
	self.HealthLast = self.Vars["Health"]

	if i == 0 then
		i = self.HealthLastVal
		if i > 0 then
			return "|cff205f20", format ("+%d", i)
		end
		return "|cff5f2020", format ("%d", i)
	else
		self.HealthLastVal = i
		if i > 0 then
			return "|cff20ff20", format ("+%d", i)
		end
		return "|cffff2020", format ("%d", i)
	end
end

function Nx.Info:CalcMana()
	return "|cffc0c0c0", format ("%d", self.Vars["Mana"])
end

function Nx.Info:CalcManaPercent()
	return "|cffe0e0e0", format ("%d", self.Vars["Mana%"] * 100)
end

function Nx.Info:CalcManaChange()

	local i = self.Vars["Mana"] - self.ManaLast
	self.ManaLast = self.Vars["Mana"]

	if i == 0 then
		i = self.ManaLastVal
		if i > 0 then
			return "|cff205f20", format ("+%d", i)
		end
		return "|cff5f2020", format ("%d", i)
	else
		self.ManaLastVal = i
		if i > 0 then
			return "|cff20ff20", format ("+%d", i)
		end
		return "|cffff2020", format ("%d", i)
	end
end

function Nx.Info:CalcCooldown()

	if UnitCastingInfo ("player") or UnitChannelInfo ("player") then
		return
	end

	local GetActionCooldown = GetActionCooldown

	for n = 1, 120 do
		local start, dur = GetActionCooldown (n)
		if dur > 0 and dur <= 1.5 then
			local low = dur - (GetTime() - start)
			return "|cffc0c020", string.rep (".", low * 10)
		end
	end
end

function Nx.Info:CalcComboPoints()

	-- Per-rune typed display only works on classic flavors with the legacy
	-- DK rune system (Wrath/Cata/MoP). Retail unified runes after Legion and
	-- removed GetRuneType entirely; fall back to the regular combo-point path
	-- there so DKs at least see something useful.
	if self.DeathKnight and _G.GetRuneType and _G.GetRuneCooldown then

		if self.Vars["TName"] then

			local s = ""

			for _, data in ipairs (self.DKRunes) do

				local n = data[1]
				s = s .. (GetRuneType (n) ~= 4 and data[2] or "|cff606060")
				local start, duration, ready = GetRuneCooldown (n)
				s = s .. (ready and "+" or "-")

				if data[3] then
					s = s .. " "
				end
			end

			return "|cffff8080", s
		end

	else
		-- Retail requires the two-arg form (unit + target); calling the
		-- legacy one-arg form throws "bad argument #2" there. Classic
		-- accepts both, so we always pass two args. The pcall on the
		-- second attempt is defensive in case a future API tightening
		-- rejects calling against an unset target on classic too.
		local i = GetComboPoints ("player", "target")
		if (not i or i == 0) and not Nx.isRetail then
			local ok, v = pcall (GetComboPoints, "player")
			if ok then
				i = v or 0
			end
		end
		if i and i > 0 then
			return "|cffff8080", string.rep ("*", i)
		end
	end
end

function Nx.Info:CalcTargetHealth()

	if self.Vars["TName"] then
		return "|cffc0c0c0", format ("%d", self.Vars["THealth"])
	end
end

function Nx.Info:CalcTargetHealthPercent()

	if self.Vars["TName"] then
		-- _safeRatio guards against retail's secret-number taint; see
		-- comment near _safeN at the top of this file.
		self.Vars["THealth%"] = _safeRatio (self.Vars["THealth"], self.Vars["THealthMax"])
		return "|cffe0e0e0", format ("%d", self.Vars["THealth%"] * 100)
	end
end

function Nx.Info:CalcTargetMana()

	if self.Vars["TMana"] >= 0 then
		return "|cffc0c0c0", format ("%d", self.Vars["TMana"])
	end
end

function Nx.Info:CalcTargetManaPercent()

	if self.Vars["TMana"] >= 0 then
		self.Vars["TMana%"] = _safeRatio (self.Vars["TMana"], self.Vars["TManaMax"])
		return "|cffe0e0e0", format ("%d", self.Vars["TMana%"] * 100)
	end
end

function Nx.Info:CalcTargetCast (w, h)

	w = tonumber (w) or 50
	h = tonumber (h) or 10

	local spell, rank, name, icon, startTime, endTime = UnitCastingInfo ("target")

	if not name then
		spell, rank, name, icon, startTime, endTime = UnitChannelInfo ("target")
	end

	if name then
		local remain = endTime / 1000 - GetTime()
		local per = remain * 1000 / (endTime - startTime)
		return "|cffc0c0f0", format ("|T%s:16|t %.1f |TInterface\\BUTTONS\\gradblue:%d:%d|t", icon, remain, h, max (per * w, 1))
	end
end

function Nx.Info:CalcThreatPercent (unit)

	local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation (unit, "target")

--	if status then	Nx.prt ("%s %s %s %s %s %s", unit, isTanking and "T" or "t", status, threatpct, rawthreatpct, threatvalue) end

	if threatpct then
		return "|cffc0c0c0", format ("%d%%", threatpct)
	end
end

function Nx.Info:CalcDur()
	if not Nx.Warehouse then
		return
	end
	Nx.Info.NeedDurability = true	
	local dur = Nx.Warehouse.CurCharacter["DurLowPercent"]
	if dur then	-- Can be nil on login
		if dur >= 30 then
			return "|cffa0a0a0", format ("%d", dur)
		end
		return "|cffff2020", format ("%d", dur)
	end
end

function Nx.Info:CalcLvlTime()
	if not Nx.Warehouse then
		return "|cff808080", "?"
	end
	local ch = Nx.Warehouse.CurCharacter

	local lvl = tonumber (ch["Level"] or 0)

	if lvl < MAX_PLAYER_LEVEL then

		local lvlHours = difftime (time(), ch["LvlTime"]) / 3600
		local xp = max (1, ch["XP"] - ch["LXP"])
		local lvlTime = (ch["XPMax"] - ch["XP"]) / (xp / lvlHours)

		if lvlTime < 100 then
			return "", format ("%.1f", lvlTime)
		end
		return "|cff808080", "?"
	end
end

function Nx.Info:CalcBGQueue (num)

--	Nx.prtVar ("BGQ", num)

	local n = tonumber (num) or 1
	local status, name = GetBattlefieldStatus (n)

	if status == "queued" then

		name = gsub (name, "%U", "")	-- Remove all non uppercase
		local i = (GetBattlefieldEstimatedWaitTime (n) - GetBattlefieldTimeWaited (n)) / 1000
		if i >= 0 then
			return "", format ("%s ETA %d:%02d", name, i / 60 % 60, i % 60)
		else
			return "|cffff0000", format ("%s ETA -%d:%02d", name, -i / 60 % 60, -i % 60)
		end

	elseif status == "confirm" then

		name = gsub (name, "%U", "")	-- Remove all non uppercase
		local i = GetBattlefieldPortExpiration (n)
		return "|cff00ff00", format ("%s cancel %d:%02d", name, i / 60 % 60, i % 60)
	end
end

function Nx.Info:CalcBGStart()

	local info = Nx.Info

	if Nx.InBG and info.BGStartTime then

		local i = info.BGStartSecs - (GetTime() - info.BGStartTime)
		if i >= 0 then
			return "|cff8080ff", format ("%d:%02d", i / 60 % 60, i % 60)
		else
			info.BGStartTime = nil
		end
	else
		info.BGStartTime = nil
	end
end

function Nx.Info:CalcBGDuration()

	if Nx.InBG then
		local i = GetBattlefieldInstanceRunTime() / 1000
		if i > 0 then
			return "", format ("%d:%02d", i / 60 % 60, i % 60)
		end
	end
end

function Nx.Info:CalcBGWingWait()

	local s, s2

	local _, name, active, canQueue, i, canEnter = GetWorldPVPAreaInfo (1)	-- 1 Wintergrasp

--	local i = GetWintergraspWaitTime()
	if not active and i and i > 0 then
		i = i / 60
		s = ""
		s2 = format ("%d:%02d", i / 60 % 60, i % 60)
	end

	local _, name, active, canQueue, i, canEnter = GetWorldPVPAreaInfo (2)	-- 2 Tol Barad

	if not active and i and i > 0 then
		i = i / 60
		if s2 then
			s2 = s2 .. format (", TB %d:%02d", i / 60 % 60, i % 60)
		else
			s = ""
			s2 = format ("TB %d:%02d", i / 60 % 60, i % 60)
		end
	end

	return s, s2
end

function Nx.Info:CalcIfBG()
	if Nx.InBG then
		return "", ""
	end
end

function Nx.Info:CalcIfCombat()
	if Nx.InCombat then
		return "", ""
	end
end

function Nx.Info:CalcIfTrue (varName)
	if self.Vars[varName] then
		return "", ""
	end
end

function Nx.Info:CalcIfFalse (varName)
	if not self.Vars[varName] then
		return "", ""
	end
end

function Nx.Info:CalcIfLT (val, varName)
	if (self.Vars[varName] or 0) < (tonumber (val) or 1) then
		return "", ""
	end
end

function Nx.Info:CalcIfLTOrCombat (val, varName)
	if Nx.InCombat or (self.Vars[varName] or 0) < (tonumber (val) or 1) then
		return "", ""
	end
end

function Nx.Info:CalcIfMana (val)

	if self.ManaInvert then
		if self.Vars["Mana%"] > 1 - (tonumber (val) or 1) then
			return "", ""
		end
	else
		if self.Vars["Mana%"] < (tonumber (val) or 1) then
			return "", ""
		end
	end
end

function Nx.Info:CalcBGHonor()
	return "|cffa0a0ff", format ("%d", GetHonorAmount())
end

function Nx.Info:CalcBGStats()
	if Nx.InBG then
		local cb = Nx.Combat
		return "|cffa0a0a0", format ("%d %d %d +%d", cb.KBs, cb.Deaths, cb.HKs, cb.Honor)
	end
end

function Nx.Info:CalcStat (val)
	return "|cffa0a0a0", format ("%s", Nx.InfoStats[val] or "?")
end

function Nx.Info:CalcTime (str)
--	Nx.prtVar ("", str)
	local ok, s = pcall (date, str ~= "" and str or nil)
	return "|cffa0a0a0", ok and s or "?"
end

---------------------------------------------------------------------------------------

function Nx.Info:SetBGStartTime (secs)

	self.BGStartSecs = secs
	self.BGStartTime = GetTime()
end

---------------------------------------------------------------------------------------

function Nx.Info:CreateFrame (parent)

	local f = CreateFrame ("Frame", nil, parent)

	local t = f:CreateTexture()
	f.texture = t
	t:SetAllPoints (f)

	return f
end

function Nx.Info:ResetFrames()

	local frms = self.Frms
	frms.Used = frms.Next - 1		-- Save last frame used
	frms.Next = 1
end

---------------------------------------------------------------------------------------
-- Hide extra frames
---------------------------------------------------------------------------------------

function Nx.Map:HideExtraFrames()

	local frms = self.Frms

	for n = frms.Next, frms.Used do		-- Hide up to last frames used amount
		frms[n]:Hide()
	end
end

---------------------------------------------------------------------------------------
-- Get next available frame or create one
-- ret: frame
---------------------------------------------------------------------------------------

function Nx.Info:GetFrame()

	local frms = self.Frms
	local pos = frms.Next

	local f = frms[pos]
	if not f then

		f = CreateFrame ("Frame", "NxInfo"..pos, self.Frm)
		frms[pos] = f

		local t = f:CreateTexture()
		f.texture = t
		t:SetAllPoints (f)
	end

--	f:SetFrameLevel (self.Level + (levelAdd or 0))

	frms.Next = pos + 1

	return f
end

---------------------------------------------------------------------------------------
-- Create info editor window
-- self = instance
---------------------------------------------------------------------------------------

function Nx.Info:EditorCreate (index)

--PAIDS!

	self.Index = index
	self.Data = Nx.idb.profile.InfoData[index]

	-- Create Window

	if self.Win then
		self.Win:Show()
		return
	end

--	Nx.Window:SetCreateFade (1, 0)

	local win = Nx.Window:Create ("NxInfoEdit", 50, 20, nil, 1)
	self.Win = win
	win.Frm.NxInst = self

	win:CreateButtons (true, true)
	win:SetTitleLineH (18)

	win:InitLayoutData (nil, -.3, -.2, -.5, -.6)
	win.Frm:SetToplevel (true)

	-- Buttons

	local bw, bh = win:GetBorderSize()

--	local but = Nx.Button:Create (win.Frm, "Txt64", "Up", nil, bw, -bh, "TOPLEFT", 44, 20, self.But_OnUp, self)
--	local but = Nx.Button:Create (but.Frm, "Txt64", "Down", nil, 46, 0, "TOPLEFT", 44, 20, self.But_OnDown, self)

	-- List

	Nx.List:SetCreateFont ("Font.Medium", 16)

	local list = Nx.List:Create (false, 0, 0, 1, 1, win.Frm, false, true)
	self.List = list

	list:SetUser (self, self.EditorOnListEvent)
	list:SetLineHeight (0, 0)

	list:ColumnAdd ("", 1, 900)

--	list:SetBGColor (0, 0, 0, .1)

	win:Attach (list.Frm, 0, 1, 0, 1)

	--

	self:Update()

	self.List:FullUpdate()

--PAIDE!
end

---------------------------------------------------------------------------------------
-- On list events
---------------------------------------------------------------------------------------

function Nx.Info:EditorOnListEvent (eventName, sel, val2, click)

--	Nx.prt ("Guide list event "..eventName)

	local data = self.List:ItemGetData (sel)
--[[
	if eventName == "select" or eventName == "mid" or eventName == "menu" then

		if eventName == "menu" then
			self.SelItemIndex = data
			Nx.Info:OpenMenu (self)
		end

		self:Update()
	end
--]]
end

function Nx:OnChat_msg_bg_system_neutral (event, arg1, arg2, arg3)

	-- AB: The Battle begins in 2 minutes!
	-- AB: The Battle begins in 1 minute!
	-- AB: The Battle begins in 30 seconds!
	-- AV: 1 minute until the battle for...
	-- AV: 30 seconds until the battle for...
	-- EOS: The battle begins in 30 seconds!
	-- WG: ...Warsong Gulch begins in 30 seconds.  Pre...
	-- Arena: Thirty seconds until the Arena battle begins!
	-- Arena: Fifteen seconds until the Arena battle begins!

	if Nx.Info then

		local s1, s2, secs

		if strfind (arg1, L["One minute until the Arena"]) then
			secs = 60
		end
		if strfind (arg1, L["Thirty seconds until the Arena"]) then
			secs = 30
		end
		if strfind (arg1, L["Fifteen seconds until the Arena"]) then
			secs = 15
		end

		if not secs then
			s1, s2, secs = strfind (arg1, L[" begins? in (%d+) "])
			if not secs then
				s1, s2, secs = strfind (arg1, L["(%d+) minutes? until the battle"])
			end
		end

		if secs then
			secs = tonumber (secs)
			if secs then
				if secs <= 3 then	-- Minutes?
					secs = secs * 60
				end

				Nx.Info:SetBGStartTime (secs)
			end
		end
	end
end

-- First-time UI setup for the combat window. On retail, Carbonite.Info
-- inherits taint from Carbonite parent's load context (parent owns the
-- _G.LibStub and _G.Nx globals, which flags every reader tainted-by-
-- Carbonite). That makes Frame:RegisterEvent fire ADDON_ACTION_FORBIDDEN
-- from any path inside this addon — including file scope and inside
-- securecallfunction. Until Carbonite parent stops owning those globals
-- (or a sibling addon that loads alphabetically before Carbonite/ does
-- the registration in a clean chunk), retail gets a degraded combat
-- module: the window opens, the OnTimer poll keeps the player health/
-- mana readout current via _safeN/_safeRatio, but per-hit combat-log
-- tallying, XP/honor gains, loot logs and combat-lockdown events are
-- unavailable. Classic flavors are unaffected.
function Nx.Info.Combat:_FirstTimeOpen()
	if self.Frm then
		return
	end

	self.EventTable = {
	}

	local win = Nx.Window:Create ("NxCombat", nil, nil, nil, nil, nil, true)
	self.Win = win

	win:InitLayoutData (nil, -.7, -.7, -.3, -.06)

	win:CreateButtons (true)

	-- Create frame

	local f = CreateFrame ("Frame", nil, UIParent)
	self.Frm = f
	f.NxCombat = self

	win:Attach (f, 0, 1, 0, 1)

	f:SetScript ("OnEvent", self.OnEvent)

	if not Nx.isRetail then
		f:RegisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")
		f:RegisterEvent ("CHAT_MSG_COMBAT_XP_GAIN")
		f:RegisterEvent ("CHAT_MSG_COMBAT_HONOR_GAIN")
		f:RegisterEvent ("CHAT_MSG_LOOT")
		f:RegisterEvent ("PLAYER_REGEN_DISABLED")
		f:RegisterEvent ("PLAYER_REGEN_ENABLED")

		for k, v in pairs (self.EventTable) do
			f:RegisterEvent (k)
		end

		f:RegisterEvent ("PLAYER_DEAD")
	end

	f:SetScript ("OnUpdate", self.OnUpdate)

	f:SetScript ("OnEnter", self.OnEnter)
	f:SetScript ("OnLeave", self.OnEnter)
	f:EnableMouse (true)

	f:SetFrameStrata ("MEDIUM")

	local t = f:CreateTexture()
	t:SetColorTexture (.2, .2, .2, .5)
	t:SetAllPoints (f)
	f.texture = t

	self:OpenGraph()
end

function Nx.Info.Combat:Open()

	local win = self.Win

	if win then
		if win:IsShown() then
			win:Show (false)
		else
			win:Show()
		end
		return
	end

	-- Defer the first-time setup so the frame is created in a clean
	-- Blizzard ticker scope, not inside whatever (possibly tainted)
	-- caller invoked us. _opening guards against multiple deferrals
	-- racing if Open is called several times before the first tick fires.
	if self._opening then
		return
	end
	self._opening = true
	local function setup ()
		self._opening = nil
		self:_FirstTimeOpen()
	end
	if C_Timer and C_Timer.After then
		C_Timer.After (0, setup)
	else
		setup ()
	end
end

function Nx.Info.Combat:OpenGraph()
	self.GraphHits = Nx.Graph:Create (self.W, 50, self.Frm)
	local f = self.GraphHits.MainFrm
	self.Win:Attach (f, 0, 1, 0, 1)
end

--------

function Nx.Info.Combat:OnEvent (event, ...)

	local arg1, arg2, arg3 = select (1, ...)

	local Combat = Nx.Info.Combat
	local UEvents = Nx.UEvents
	local prtD = Nx.prtD
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then

		local OBJ_AFFILIATION_MINE = 1
		local OBJ_TYPE_PET			= 0x00001000
		local OBJ_TYPE_GUARDIAN		= 0x00002000

		local time, cEvent, _hideCaster, sId, sName, sFlags, sf2, dId, dName, dFlags, df2, a1, a2, a3, a4 = select (1, unpack({CombatLogGetCurrentEventInfo()}))
		local pre, mid, post = Nx.Split ("_", cEvent)
		if not post then
			post = mid
		end

		if bit.band (sFlags, OBJ_AFFILIATION_MINE) > 0 then

			local spellId, spellName, spellSchool
			local i = 12

			if pre ~= "SWING" then
				spellId, spellName, spellSchool = select (12, unpack({CombatLogGetCurrentEventInfo()}))
				i = 15
			end

			local amount, school, resist, block, absorb, crit = select (i, unpack({CombatLogGetCurrentEventInfo()}))

			if post == "DAMAGE" then

				local v = amount

				local hitStr = crit and "|cffff00ff" .. L["crit"] or L["hit"]

				if spellName then
					hitStr = spellName
					if mid == "PERIODIC" then
						hitStr = spellName .. " dot"
					end
					if crit then
						hitStr = hitStr .. " |cffff00ff" .. L["crit"]
					end
				end
				local s = format ("|cff00ff00%s|r %s |cffff0000'%s'|r %d", sName or "?", hitStr, dName, amount)

				if bit.band (sFlags, OBJ_TYPE_PET + OBJ_TYPE_GUARDIAN) > 0 then
					if pre == "SPELL" then
						if crit then
							Combat:SetLine (v, "e0a000", s)
						else
							Combat:SetLine (v, "906000", s)
						end
					else
						if crit then
							Combat:SetLine (v, "e0a0a0", s)
						else
							Combat:SetLine (v, "806060", s)
						end
					end
				else
					if pre == "SPELL" then
						if crit then
							Combat:SetLine (v, "e0e000", s)
						else
							Combat:SetLine (v, "909000", s)
						end
					else
						if crit then
							Combat:SetLine (v, "e0e0e0", s)
						else
							Combat:SetLine (v, "808080", s)
						end
					end
				end

			elseif cEvent == "PARTY_KILL" then

				Combat:SetLine (-1, "e02020", L["Killed"] .. " " .. dName)
				-- Skip persisting a map event when kill markers are disabled.
				if Nx.idb and Nx.idb.profile.Info.KillIcons then
					-- destGUID format: Creature-0-srv-instance-zone-npcID-spawn
					-- Parse out the npcID so we can include it in the tooltip
					-- and have a stable identifier across renames / language.
					local npcId
					if dId then
						local _, _, _, _, _, id = strsplit("-", dId)
						npcId = tonumber(id)
					end
					UEvents:AddKill (dName, npcId)
				end
			end

		elseif bit.band (dFlags, OBJ_AFFILIATION_MINE) > 0 then

			if post == "DAMAGE" and sName then
				Combat.AttackerName = sName
			end
		end
	elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local s1, s2, name = strfind (arg1, "gain (%d+) ex")
		if s1 then
			Combat:SetLine (-1, "20e020", arg1)
			UEvents:AddInfo ("+"..name.." xp")
		end
	elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
		local s1, s2, val = strfind (arg1, "(%d*%.%d+) %aonor")	--V4
		if s1 then
			UEvents:AddHonor ("+".. val .." " .. L["honor"])
			return
		end

		local s1, s2, name = strfind (arg1, "(%d+) %aonor")
		if s1 and name ~= "0" then
			UEvents:AddHonor ("+"..name.." " .. L["honor"])
		end

	elseif event == "CHAT_MSG_LOOT" then
		local s1, s2 = strfind (arg1, "Honor Points%.")	--V4
		if s1 then
			UEvents:AddHonor ("+1 " .. L["honor"])
			return
		end

		local s1, s2, val = strfind (arg1, "Honor Points x(%d+)")	--V4
		if s1 then
			UEvents:AddHonor ("+" .. val .. " " .. L["honor"])
			return
		end

	elseif event == "PLAYER_REGEN_DISABLED" then
		Combat:EnterCombat()

	elseif event == "PLAYER_REGEN_ENABLED" then
		Combat.InCombat = false

	elseif event == "PLAYER_DEAD" then
		UEvents:AddDeath (Combat.AttackerName)

	else
		if Combat.EventTable[event] then
			Combat.EventTable[event] (Combat, arg1)
		end

	end
end

function Nx.Info.Combat:OnUpdate (...)

end

function Nx.Info.Combat:OnEnter (motion)

end

--------
-- Start combat

function Nx.Info.Combat:EnterCombat (value)

	if not self.InCombat then
		self.InCombat = true
		self.HitPeak = 10
		self.HitTotal = 0
		self.TimeStart = GetTime()

		self.GraphHits:Clear()
		self.GraphHits:SetPeak (self.HitPeak)
	end
end

--------
-- Set a new graph line to value

function Nx.Info.Combat:SetLine (value, colorStr, infoStr)

	self:EnterCombat()

	if value > self.HitPeak then
		self.HitPeak = value
		self.GraphHits:SetPeak (self.HitPeak)
	end

	self.HitTotal = self.HitTotal + value

	if value > self.HitBest then
		self.HitBest = value
	end

	local time = GetTime() - self.TimeStart + .001		-- Dont allow zero

	self.GraphHits:SetLine (time, value, colorStr, infoStr)

	local txt = string.format (L["Hit"] .. " %3.0f " .. L["Peak"] .. " "..self.HitPeak.." " .. L["Best"] .. " "..self.HitBest.." " .. L["Total"] .. " %.0f " .. L["Time"] .. " %.2f DPS %.1f", value, self.HitTotal, time, self.HitTotal / time)
	self.Win:SetTitle (txt)
end
---------------------------------------------------------------------------------------
-- EOF

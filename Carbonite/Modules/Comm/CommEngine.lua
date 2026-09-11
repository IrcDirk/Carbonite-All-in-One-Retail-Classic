---------------------------------------------------------------------------------------
-- NxCom - Communication System
-- Copyright 2007-2012 Carbon Based Creations, LLC
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
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Module Description:
-- The Communication module handles all inter-player communication for Carbonite.
-- This includes:
--   - Position sharing with guild members and friends
--   - Target information sharing
--   - Quest progress sharing
--   - Custom chat channels for zone-based communication
--   - Level-up notifications
--   - Enemy player (punk) alerts
--
-- Technical Notes:
-- - "\" in send data can lead to invalid escape codes
-- - Bytes 35 (#) + 57 == 92 (\)
-- - Byte 124 == |. Must be |c or creates invalid escape code (chat only, not addon channel)
-- - Byte 128 or higher == invalid UTF-8 error (chat only, not addon channel)
---------------------------------------------------------------------------------------

-- Localization library reference
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

-- Localised classic clients (RU, KR, ...) deliver player/realm strings
-- with a trailing " (RU)" / " (EN)" / ... locale tag attached: e.g.
-- arg2 from CHAT_MSG_CHANNEL = "Name-Realm (RU)" and
-- GetRealmName() = "Realm (RU)". Without stripping this, identity
-- comparisons against self.PlyrName (which is the canonical
-- "Name-Realm") fail and the player's own broadcasts get treated as
-- a separate, third-party player — rendering a Whisper/Invite icon
-- right under our own arrow.
local function _stripLocaleTag(s)
    return s and (s:gsub("%s*%(%a+%)%s*$", "")) or s
end

-- Canonicalise a sender name to the "Name-Realm" form self.PlyrName
-- uses. Handles three input shapes seen in the wild:
--   * "Name"                  - bare classic same-realm delivery
--   * "Name-Realm"            - cross-realm or already-qualified
--   * "Name-Realm (RU)"       - localised classic clients
-- and the realm GetRealmName() returns may itself carry the (RU)
-- tag, which we strip before appending.
local function _normaliseSenderName(name)
    if not name then return nil end
    name = _stripLocaleTag(name)
    if not Nx.strpos(name, "-") then
        local r = _stripLocaleTag(GetRealmName())
        if r and r ~= "" then
            name = name .. "-" .. r
        end
    end
    return name
end

-- Build a locale-safe pattern for Blizzard's "player not found" system
-- message. Escape the translated text before restoring the %s capture so
-- punctuation in any locale cannot alter the Lua pattern.
local function _buildPlayerNotFoundPattern()
    local template = ERR_CHAT_PLAYER_NOT_FOUND_S
    if type(template) ~= "string" or template == "" then
        return nil
    end

    local marker = "\1"
    local replaced
    template, replaced = template:gsub("%%1%$s", marker, 1)
    if replaced == 0 then
        template, replaced = template:gsub("%%s", marker, 1)
    end
    if replaced == 0 then
        return nil
    end

    template = template:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    template = template:gsub(marker, "(.+)", 1)
    return "^" .. template .. "$"
end

local PLAYER_NOT_FOUND_PATTERN = _buildPlayerNotFoundPattern()

---------------------------------------------------------------------------------------
-- Relocation note
---------------------------------------------------------------------------------------
-- The protocol engine, channel manager, player-status decoders and
-- punk/pal alert plumbing relocated from the legacy Carbonite/NxCom.lua.
-- All methods continue to attach to the Nx.Com table that
-- Carbonite.lua initialises (Nx.Com = {}, Nx.Com.List = {}). The
-- Modules/Comm shell (Comm.lua, CommSend.lua, CommReceive.lua,
-- WireFormat.lua, ChannelManager.lua, PositionShare.lua, etc.) wraps
-- this engine through Nx.Com references; subsequent ports will move
-- behaviour out of these methods piecemeal.

---------------------------------------------------------------------------------------
-- Version and Default Options
---------------------------------------------------------------------------------------

NxCOMOPTS_VERSION = .01

NxComOpts = {
    Version = 0
}

NxComOptsDefaults = {
    Version = NxCOMOPTS_VERSION,
}

---------------------------------------------------------------------------------------
-- Communication System Initialization
---------------------------------------------------------------------------------------

--- Initialize the communication system
-- Sets up channels, message queues, and hooks into the chat system
function Nx.Com:Init()
    -- Check and reset options if version mismatch
    if NxComOpts.Version < NxCOMOPTS_VERSION then
        if NxComOpts.Version ~= 0 then
            Nx.prt(L["Com options reset (%f, %f)"], NxComOpts.Version, NxComOptsDefaults.Version)
        end
        NxComOpts = NxComOptsDefaults
    end

    -- Initialize state
    self.Created = false
    self.Data = {}
    self.Data.Rcv = {}       -- Received messages
    self.Data.Send = {}      -- Messages to send
    self.Name = "Crb"        -- Addon message prefix

    -- Channel letter: Y for free, M for ads, B for standard
    self.ChanALetter = Nx.Free and "Y" or Nx.Ads and "M" or "B"

    self.SendRate = 1        -- Message send rate multiplier

    -- Send queue names mapping
    self.SendQNames = {
        ["Chan"] = 1,
        ["Guild"] = 2,
        ["Friend"] = 3,
        ["Zone"] = 4
    }

    -- Initialize send queues
    local sq = {}
    self.SendQ = sq
    sq[1] = {}               -- Channel queue
    sq[2] = {}               -- Guild queue
    sq[3] = {}               -- Friends queue
    sq[4] = {}               -- Zone queue
    self.SendQMode = 1

    -- Player tracking info
    self.PalsInfo = {}       -- Friends and guild member info (positions)
    self.PalsSendQ = {}      -- Queue of messages to send to pals
    self.PalNames = {}       -- Names of all pals (friends + guild)

    self.MemberNames = {}    -- Names in current party or raid

    self.Friends = {}        -- Online friends list
    self.UnavailablePals = {} -- Carbonite whisper targets rejected by server
    self.PendingWhisperTargets = {} -- Recent Carbonite addon whispers by name
    self.HandledWhisperErrors = {}  -- Short-lived filter/event correlation

    -- Zone channel info
    self.ZPInfo = {}         -- Zone player info (positions of non-pals)
    self.ZStatus = {}        -- Zone channel status, indexed by map ID
    self.ZMonitor = {}       -- Zones being monitored

    self.SendChanQ = {}      -- Queue for numbered channel sends

    self.PosSendNext = -2    -- Index for next position send
    self.SendZSkip = 1       -- Zone send skip counter

    -- Target type colors
    self.TypeColors = {
        "|cff80ff80",    -- Friendly (green)
        "|cffff4040",    -- Enemy player (red)
        "|cffffff40",    -- Enemy NPC (yellow)
        "|cffffffe0",    -- Elite/Boss (light yellow)
        "|cffc0c0ff"     -- Neutral (light blue)
    }

    -- Class names with localization
    self.ClassNames = {
        [0] = "?",
        L["Druid"], L["Hunter"], L["Mage"], L["Paladin"], L["Priest"],
        L["Rogue"], L["Shaman"], L["Warlock"], L["Warrior"], L["Deathknight"], L["Monk"]
    }

    -- Create reverse lookup for class names
    for k, v in ipairs(self.ClassNames) do
        self.ClassNames[v] = k
        self.ClassNames[strupper(v)] = k    -- Uppercase version
    end

    self.Created = true

    -- Initialize message list
    self.List.Opened = false
    self.List.Sorted = {}

    -- Debug: Bytes per second tracking
    self.SentBytes = 0
    self.SentBytesSec = 0
    self.SentBytesTime = GetTime()
    ComBytesSec = Nx:ScheduleTimer(self.OnBytesSecTimer, 1, self)

    -- Hook into chat system
    hooksecurefunc("SendChatMessage", self.SendChatHook)
    Nx:RegisterComm(self.Name, Nx.Com.OnChat_msg_addon)
end

---------------------------------------------------------------------------------------
-- Testing Functions
---------------------------------------------------------------------------------------

--- Test communication function
-- @param a1 First argument
-- @param a2 Second argument
function Nx.Com:Test(a1, a2)
    self:SendSecG("? }a", "")    -- Ask for response
end

--- Timer callback for communication testing
-- @param name Timer name
-- @return Next timer interval
function Nx.Com:OnTestTimer(name)
    self:SendPals("!" .. name)

    if random() < .5 then
        -- Could trigger level up test here
    end

    return .1 + random() * 5
end

---------------------------------------------------------------------------------------
-- Bandwidth Monitoring
---------------------------------------------------------------------------------------

--- Timer callback to calculate bytes per second
-- @param name Timer name
-- @return Next timer interval (always 1 second)
function Nx.Com:OnBytesSecTimer(name)
    local tm = GetTime()

    self.SentBytesSec = self.SentBytes / (tm - self.SentBytesTime)
    self.SentBytes = 0
    self.SentBytesTime = tm

    return 1
end

---------------------------------------------------------------------------------------
-- Event Handlers
---------------------------------------------------------------------------------------

--- Handle communication-related events
-- @param event Event name
function Nx.Com:OnEvent(event)
    local self = Nx.Com

    if event == "PLAYER_LOGIN" then
        -- Initialize player info. Localised classic clients may
        -- return the realm with a "(RU)"-style locale tag — strip
        -- it through the shared normaliser so inbound-message
        -- comparisons stay symmetric.
        local playername, realmname = UnitFullName("player")
        realmname = _stripLocaleTag(realmname)
        self.PlyrName = playername .. (realmname and realmname ~= "" and "-" .. realmname or "")
        self.PlyrMapId = Nx.Map:GetRealMapId()
        self.PlyrX = 0
        self.PlyrY = 0

        -- Get player class index
        local _, tCls = UnitClass("player")
        self.PlyrClassI = self.ClassNames[tCls] or 0

        self.List:AddInfo("", "PLAYER_LOGIN")

        -- Initialize send timers
        self.SendTime = GetTime()
        self.SendPosTime = GetTime()
        self.SendChanTime = GetTime()

        -- Leave any existing channels
        self:LeaveChan("A")
        self:LeaveChan("Z")

        -- Schedule login timer with random delay
        ComLogin = Nx:ScheduleTimer(self.OnLoginTimer, random(10, 15), self)

        -- Request guild roster update
        if IsInGuild() then
            C_GuildInfo.GuildRoster()
        end

        Nx.Com.Initialized = true

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        self.List:AddInfo("", "ZONE_CHANGED_NEW_AREA")

        -- Update channels if login timer has completed
        if Nx.TimeLeft(ComLogin) == 0 then
            self:UpdateChannels()
        end

    elseif event == "PLAYER_LEAVING_WORLD" then
        -- Clean up channels when leaving world
        self:LeaveChan("A")
        self:LeaveChan("Z")
    end

    self.List:Update()
end

--- Login timer callback
-- Handles channel joining after login/reload
function Nx.Com:OnLoginTimer()
    local redeploy = 0

    -- Check if we logged in on a taxi (channels don't join while on taxi)
    if UnitOnTaxi("player") then
        local id = GetChannelName(1)
        if id ~= 1 then
            self.WasOnTaxi = true
            redeploy = 1
        end
    end

    -- Handle post-taxi channel rejoining
    if self.WasOnTaxi then
        self.WasOnTaxi = nil
        redeploy = 3
    end

    -- Check if channels are ready
    if GetChannelName(1) ~= 1 then
        redeploy = 3
    end

    -- Retry if needed
    if redeploy > 0 then
        ComLogin = Nx:ScheduleTimer(self.OnLoginTimer, redeploy, self)
        return
    end

    -- Allow manual disable of com features with Ctrl+Alt
    if IsControlKeyDown() and IsAltKeyDown() then
        Nx.prt(L["Disabling com functions!"])
        Nx.db.profile.Comm.Global = false
        Nx.db.profile.Comm.Zone = false
    end

    -- Calculate how many channels we need
    local need = 2
    if not Nx.db.profile.Comm.Global then
        need = 1
    end
    if not Nx.db.profile.Comm.Zone then
        need = need - 1
    end

    -- Check available channel slots
    local free = max(10 - self:GetChanCount(), 0)

    if need > free then
        Nx.prt("|cffff9f5f" .. L["Need"] .. " %d " .. L["chat channel(s)!"], need - free)
        Nx.prt("|cffff9f5f" .. L["This will disable some communication features"])
        Nx.prt("|cffff9f5f" .. L["You may free channels using the chat tab"])
    end

    -- Scan and update channels
    self:ScanChans()
    self:UpdateChannels()

    -- Join addon channel
    self:JoinChan("A")
end

--- Timer callback for leaving addon channel
function Nx.Com:OnLeaveATimer()
    self:LeaveChan("A")
end

---------------------------------------------------------------------------------------
-- Level Up Handling
---------------------------------------------------------------------------------------

--- Called when player levels up
-- Broadcasts level up notification to pals
-- @param event Event name
-- @param arg1 New level
function Nx.Com:OnPlayer_level_up(event, arg1)
    if arg1 >= 1 then
        self:SendPals(format("L%s", strchar(35 + arg1)))
    end
end

---------------------------------------------------------------------------------------
-- Friends List Management
---------------------------------------------------------------------------------------

--- Called when friends or guild list updates
-- Builds list of connected non-guild friends
function Nx.Com:OnFriendguild_update()
    local self = Nx.Com

    local unavailable = self.UnavailablePals or {}
    local pending = self.PendingWhisperTargets or {}
    local handled = self.HandledWhisperErrors or {}
    local seenNames = {}

    self.UnavailablePals = unavailable
    self.PendingWhisperTargets = pending
    self.HandledWhisperErrors = handled

    -- Build normalized sets of all guild members and online guild members.
    -- Friends who are also guild members must never receive a duplicate direct
    -- whisper: the GUILD distribution already covers them, including the case
    -- where one roster temporarily reports a different online state.
    local guildNames = {}
    local gNames = {}
    local gNum = GetNumGuildMembers()

    for n = 1, gNum do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(n)
        name = _normaliseSenderName(name)

        if name then
            guildNames[name] = true
            seenNames[name] = true

            if online then
                gNames[name] = true
            else
                -- A confirmed offline observation ends the quarantine. A later
                -- offline-to-online roster transition can safely enable sends.
                unavailable[name] = nil
            end
        end
    end

    -- Build the connected character-friends list, excluding every guild member
    -- and every recipient rejected by the server during this online session.
    self.Friends = {}
    local i = 1

    for n = 1, C_FriendList.GetNumFriends() do
        local finfo = C_FriendList.GetFriendInfoByIndex(n)
        if finfo then
            local name = _normaliseSenderName(finfo.name)
            local connected = finfo.connected

            if name then
                seenNames[name] = true

                if not connected then
                    unavailable[name] = nil
                elseif not guildNames[name] and not unavailable[name] then
                    self.Friends[i] = name
                    i = i + 1
                end
            end
        end
    end

    -- Mark friends in guild names table
    for _, name in ipairs(self.Friends) do
        gNames[name] = false
    end

    -- Forget quarantine/correlation entries for players no longer present in
    -- either social roster, and bound the recent-send tables by age.
    local now = GetTime()
    for name in pairs(unavailable) do
        if not seenNames[name] then
            unavailable[name] = nil
        end
    end
    for name, sentAt in pairs(pending) do
        if not sentAt or now - sentAt > 10 then
            pending[name] = nil
        end
    end
    for name, handledAt in pairs(handled) do
        if not handledAt or now - handledAt > 2 then
            handled[name] = nil
        end
    end

    self.PalNames = gNames
end

--- Handle a Blizzard "player not found" message caused by a recent Carbonite
-- addon whisper. Returns true only when the message belongs to Carbonite, so a
-- chat filter can suppress the protocol error without hiding a player's normal
-- whisper errors.
-- @param message Localized CHAT_MSG_SYSTEM message
-- @return true when Carbonite caused and handled the error
function Nx.Com:HandleUnavailableWhisper(message)
    -- Retail 12.1 can mark CHAT_MSG_SYSTEM payloads secret while chat
    -- messaging lockdown is active.  Secret strings still report their Lua
    -- type as "string", but inspecting them with strmatch/gsub/format is
    -- forbidden from addon code.  Test accessibility before every operation
    -- that could inspect or convert the payload.
    if _G.canaccessvalue and not _G.canaccessvalue(message) then
        return false
    end

    if type(message) ~= "string" or not PLAYER_NOT_FOUND_PATTERN then
        return false
    end

    local rawName = strmatch(message, PLAYER_NOT_FOUND_PATTERN)
    local name = _normaliseSenderName(rawName)
    if not name then
        return false
    end

    local now = GetTime()
    local pending = self.PendingWhisperTargets or {}
    local handled = self.HandledWhisperErrors or {}
    local sentAt = pending[name]
    local handledAt = handled[name]

    self.PendingWhisperTargets = pending
    self.HandledWhisperErrors = handled

    if not (sentAt and now - sentAt <= 10)
            and not (handledAt and now - handledAt <= 2) then
        return false
    end

    pending[name] = nil
    handled[name] = now
    self.UnavailablePals = self.UnavailablePals or {}
    self.UnavailablePals[name] = true

    -- Remove the rejected recipient from every live social cache. Iterate in
    -- reverse so duplicate/corrupt entries are all removed safely.
    for index = #self.Friends, 1, -1 do
        if self.Friends[index] == name then
            tremove(self.Friends, index)
            if self.PosSendNext and index <= self.PosSendNext then
                self.PosSendNext = self.PosSendNext - 1
            end
        end
    end

    self.PalNames[name] = nil
    self.PalsInfo[name] = nil
    return true
end

---------------------------------------------------------------------------------------
-- Chat Event Handlers
---------------------------------------------------------------------------------------

--- Handle chat channel events (join, leave, notices)
-- @param event Event name
-- @param arg1-arg9 Event arguments
function Nx.Com:OnChatEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    local self = Nx.Com

    -- Only handle our channels
    if strsub(arg9, 1, 3) == self.Name then
        if event == "CHAT_MSG_CHANNEL_JOIN" then
            self.List:AddInfo("CJ:" .. arg9, format("%s", arg2))

        elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
            self.List:AddInfo("CN:" .. arg9, format("%s", arg1))

            local nameRoot = Nx.Split("I", arg9)    -- Drop I and #

            if arg1 == "YOU_JOINED" or arg1 == "YOU_CHANGED" then
                local typ = strupper(strsub(arg9, 4, 4))

                if typ == self.ChanALetter then
                    -- Joined addon channel
                    self.ChanAName = arg9
                    Nx:CancelTimer(ComA)

                elseif typ == "Z" then
                    -- Joined zone channel
                    local mapId = tonumber(strsub(nameRoot, 5))
                    if mapId then
                        local zs = self.ZStatus[mapId] or {}
                        zs.ChanName = arg9
                        self.ZStatus[mapId] = zs

                        Nx:CancelTimer("ComZ" .. mapId)
                        self:UpdateChannels()
                    end
                end

            elseif arg1 == "YOU_LEFT" then
                local typ = strupper(strsub(arg9, 4, 4))

                if typ == "Z" then
                    -- Left zone channel
                    local mapId = tonumber(strsub(nameRoot, 5))
                    if mapId then
                        local zs = self.ZStatus[mapId] or {}
                        zs.ChanName = nil
                        self.ZStatus[mapId] = zs
                    end
                end
            end

        elseif event == "CHAT_MSG_CHANNEL_LEAVE" then
            self.List:AddInfo("CL:" .. arg9, format("%s", arg2))
        end

        self.List:Update()
    end
end

--- Handle channel chat messages
-- Processes status messages from zone channel
-- @param event Event name
-- @param arg1-arg9 Event arguments
function Nx.Com:OnChat_msg_channel(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    local self = Nx.Com

    -- Handle system messages for player not found
    if event == "CHAT_MSG_SYSTEM" then
        self:HandleUnavailableWhisper(arg1)
        return
    end

    -- Process messages from our channels
    if type(arg9) == "string" and strsub(arg9, 1, 3) == self.Name then
        -- Canonicalise sender before the self-skip below. On RU /
        -- other localised classic clients arg2 arrives as
        -- "Name-Realm (RU)" and previously slipped past the
        -- comparison, causing our own broadcasts to be stored in
        -- ZPInfo and rendered as a Whisper/Invite/Track-Player icon
        -- under our own position arrow.
        local name = _normaliseSenderName(arg2)

        -- Ignore our own messages
        if name ~= self.PlyrName then
            local msg = self:RestoreChars(arg1)
            local id = strbyte(msg)

            if id == 83 then    -- S (status)
                -- Don't process if this is a known pal
                if not self.PalsInfo[name] then
                    if #msg >= 16 then
                        local pl = self.ZPInfo[name]

                        if not pl then
                            pl = {}
                            self.ZPInfo[name] = pl
                        end

                        self:ParsePlyrStatus(name, pl, msg)
                    end
                end

            elseif id == 86 then    -- V (Version)
                -- Version and registered name - currently unused
            end
        end
    end
end

--- Handle addon channel messages
-- Processes messages from guild, party, and whisper channels
-- @param args Message content
-- @param distribution Distribution type
-- @param target Sender name
function Nx.Com:OnChat_msg_addon(args, distribution, target)
    local self = Nx.Com

    local name = _normaliseSenderName(target)

    -- Ignore our own messages
    if name ~= self.PlyrName then
        -- Split multiple messages (separated by tab)
        local data = { Nx.Split("\t", args) }

        for k, msg in ipairs(data) do
            local id = strbyte(msg)

            if id == 83 then    -- S (status)
                -- Check if sender is a pal
                if self.PalNames[name] ~= nil then
                    if #msg >= 16 then
                        local pal = self.PalsInfo[name]

                        if not pal then
                            pal = {}
                            self.PalsInfo[name] = pal
                        end

                        self:ParsePlyrStatus(name, pal, msg)
                    end
                else
                    -- Non-pal player
                    if #msg >= 16 then
                        local pl = self.ZPInfo[name]

                        if not pl then
                            pl = {}
                            self.ZPInfo[name] = pl
                        end

                        self:ParsePlyrStatus(name, pl, msg)
                    end
                end

            elseif id == 76 then    -- L (Level up)
                if Nx.db.profile.Comm.LvlUpShow and #msg >= 2 then
                    local s = format("%s " .. L["reached level"] .. " %d!", name, strbyte(msg, 2) - 35)
                    Nx.prt(s)
                    Nx.UEvents:AddInfo(s)
                end

            elseif id == 81 then    -- Q (Quest)
                if Nx.Quest then
                    Nx.Quest:OnMsgQuest(name, msg)
                end

            elseif id == 86 then    -- V (Version)
                -- Version info - currently unused
            end
        end
    end
end

---------------------------------------------------------------------------------------
-- Player Status Parsing
---------------------------------------------------------------------------------------

--- Parse a player status message
-- Extracts position, health, target, quest, and punk data from status message
-- @param name Player name
-- @param info Info table to populate
-- @param msg Status message to parse
function Nx.Com:ParsePlyrStatus(name, info, msg)
    -- Status message flags:
    -- Bit 1: In combat
    -- Bit 2: Has target data
    -- Bit 4: Has quest data
    -- Bit 8: (retired) was punks data; no longer sent or parsed

    local flags = strbyte(msg, 2) - 35
    info.F = flags
    info.Quest = nil

    -- Parse player position info
    local mapId = tonumber(strsub(msg, 3, 6), 16)

    local winfo = Nx.Map.MapWorldInfo[mapId]
    if not winfo then
        info.T = 0    -- Mark as dead
        return
    end

    info.T = GetTime()
    info.MId = mapId
    info.EntryMId = mapId

    if winfo.EntryMId then
        info.EntryMId = winfo.EntryMId
    end

    if not msg or #msg < 7 then
        return
    end

    -- Parse coordinates (hex encoded)
    info.X = (tonumber(strsub(msg, 7, 9), 16) or 0) / 0xfff * 100
    info.Y = (tonumber(strsub(msg, 10, 13), 16) or 0) / 0xfff * 100    -- Includes dungeon level offset

    -- Parse health, level, class
    info.Health = (strbyte(msg, 14) - 48) / 20 * 100
    info.Lvl = strbyte(msg, 15) - 35
    info.Cls = self.ClassNames[strbyte(msg, 16) - 35] or "?"

    -- Build tooltip text
    info.Tip = format("%s %s%%\n  %s %s", name, info.Health, info.Lvl, info.Cls)

    local off = 17

    -- Parse target data (if present)
    -- Bytes 17-21 hold the fixed target header before the name; a truncated
    -- payload that still sets the flag would make strbyte() return nil here.
    if bit.band(flags, 2) > 0 and #msg >= 21 then
        -- Target format: Type, level, class, health, name length, name
        info.TType = strbyte(msg, 17) - 35
        local col = self.TypeColors[info.TType] or ""

        info.TLvl = strbyte(msg, 18) - 35
        info.TCls = self.ClassNames[strbyte(msg, 19) - 35] or "?"
        info.TH = (strbyte(msg, 20) - 35) / 20 * 100

        local len = strbyte(msg, 21) - 35
        info.TName = strsub(msg, 22, 22 + len - 1)

        local lvl = info.TLvl
        if lvl < 0 then
            lvl = "??"
        end

        info.TStr = format("\n%s%s %s %s %d%%", col, info.TName, lvl, info.TCls, info.TH)

        off = 22 + len
    else
        info.TType = nil
        info.TStr = nil
    end

    -- Parse quest tracking data (if present)
    if bit.band(flags, 4) > 0 then
        Nx.qTEMPinfo = info
        Nx.qTEMPmsg = strsub(msg, off)
        Nx.qTEMPname = name

        if Nx.qTEMPinfo and Nx.qTEMPmsg and Nx.qTEMPname then
            Nx.ModQAction = "QUEST_DECODE"
        end

        if Nx.qTEMPmsg and #Nx.qTEMPmsg > 7 then
            local tmp = (strbyte(Nx.qTEMPmsg, 7) - 35)
            off = off + (7 + tmp * 2)
        end
    end
end

---------------------------------------------------------------------------------------
-- Cartographer Compatibility
---------------------------------------------------------------------------------------

--- Parse Cartographer LibGuildPositions messages
-- @param name Player name
-- @param msg Position message
function Nx.Com:ParseLGP(name, msg)
    if strbyte(msg) == 0x50 then    -- P (position)
        local x, x2, y, y2, len = strbyte(msg, 2, 6)

        if len and len > 1 then
            -- Decode position
            x = ((x - 1) * 255 + x2 - 1) / (255 ^ 2) * 100
            y = ((y - 1) * 255 + y2 - 1) / (255 ^ 2) * 100
            local zoneName = strsub(msg, 7, 5 + len)

            local mapId = Nx.MapOverlayToMapId[strlower(zoneName)]

            if mapId then
                local info = self.PalsInfo[name]

                if not info then
                    info = {}
                    self.PalsInfo[name] = info
                end

                info.T = GetTime()
                info.MId = mapId
                info.EntryMId = mapId
                info.X = x
                info.Y = y
                info.F = 0
                info.Tip = name
            end
        end
    end
end

---------------------------------------------------------------------------------------
-- Channel Management
---------------------------------------------------------------------------------------

--- Schedule channel update
function Nx.Com:UpdateChannels()
    ComUC = Nx:ScheduleTimer(self.UpdateChannelsTimer, 2, self)
end

--- Timer callback for channel updates
-- Manages joining and leaving zone channels based on player location
function Nx.Com:UpdateChannelsTimer()
    if Nx:TimeLeft(ComLogin) > 0 then
        return 0
    end

    local curMapId = Nx.Map:GetRealMapId()

    -- Determine if we should be in a zone channel
    if UnitIsAFK("player") or not Nx.db.profile.Comm.Zone then
        curMapId = nil
    else
        if Nx.Map:IsNormalMap(curMapId) then
            local zs = self.ZStatus[curMapId] or {}
            zs.Join = true
            self.ZStatus[curMapId] = zs
        end
    end

    -- Process monitored zones
    for mapId, mode in pairs(self.ZMonitor) do
        if mode == 0 then
            self.ZMonitor[mapId] = 1

            local zs = self.ZStatus[mapId] or {}
            zs.Join = true
            self.ZStatus[mapId] = zs

        elseif mode == -1 then
            self.ZMonitor[mapId] = nil
        end
    end

    -- Update zone channel status (join or leave)
    for mapId, status in pairs(self.ZStatus) do
        -- Mark for leaving if not current zone and not monitored
        if status.ChanName then
            if curMapId ~= mapId and not self.ZMonitor[mapId] then
                status.Leave = true
            end
        end

        -- Process leave requests
        if status.Leave then
            status.Leave = false
            Nx:CancelTimer("ComZ")

            if status.ChanName then
                LeaveChannelByName(status.ChanName)
            end
        end

        -- Process join requests
        if status.Join then
            status.Join = false

            if not status.ChanName then
                if Nx:TimeLeft(ComZ) == 0 then
                    ComZ = Nx:ScheduleTimer(self.OnJoinChanZTimer, 2, self)
                    timer = {}
                    timer.UMapId = mapId
                    timer.UTryCnt = 0
                end
            end
        end
    end
end

--- Join a Carbonite channel
-- @param chanId Channel identifier ("A" for addon, "Z" for zone)
function Nx.Com:JoinChan(chanId)
    if chanId == "A" then
        -- Addon channel (global)
        if Nx.db.profile.Comm.Global then
            self.ChanAName = nil
            self.TryA = 0
            ComA = Nx:ScheduleTimer(self.OnJoinChanATimer, 0, self)
        end

    elseif chanId == "Z" then
        -- Zone channel
        if Nx.db.profile.Comm.Zone then
            local mapId = Nx.Map:GetRealMapId()

            if Nx.Map:IsNormalMap(mapId) then
                ComZ = Nx:ScheduleTimer(self.OnJoinChanZTimer, 0, self)
                timer = {}
                timer.UMapId = mapId
                timer.UTryCnt = 0
            end
        end
    else
        Nx.prt(L["JoinChan Err %s"], chanId)
    end
end

--- Timer callback for joining addon channel
function Nx.Com:OnJoinChanATimer()
    self.List:AddInfo("", "OnJoinChanATimer")

    -- Wait if all channels are full
    if self:GetChanCount() >= 10 then
        return 10
    end

    self.TryA = self.TryA + 1
    JoinChannelByName(self.Name .. self.ChanALetter .. self.TryA)

    return 3
end

--- Timer callback for joining zone channel
function Nx.Com:OnJoinChanZTimer()
    name = "ComZ" .. timer.UMapId
    self.List:AddInfo("", "OnJoinChanZTimer " .. name)

    -- Wait if all channels are full
    if self:GetChanCount() >= 10 then
        return 5
    end

    timer.UTryCnt = timer.UTryCnt + 1

    local name = format("%sZ%dI%d", self.Name, timer.UMapId, timer.UTryCnt)

    -- Don't rejoin if already in channel
    if self:InChan(name) then
        return
    end

    Nx.Com:LeaveChan("Z")
    JoinChannelByName(name)

    return 3
end

--- Count how many chat channels are currently in use
-- @return Number of channels in use
function Nx.Com:GetChanCount()
    local chanCnt = 0

    for n = 1, GetNumDisplayChannels() do
        local chname, header, collapsed, chanNumber, plCnt, active, category, voiceEnabled, voiceActive = GetChannelDisplayInfo(n)
        if not header then
            chanCnt = chanCnt + 1
        end
    end

    return chanCnt
end

--- Leave a Carbonite channel
-- @param chanId Channel identifier ("A" for addon, "Z" for zone)
function Nx.Com:LeaveChan(chanId)
    if chanId == "A" then
        self.ChanAName = nil
        self:LeaveChans(self.ChanALetter)

    elseif chanId == "Z" then
        self:LeaveChans(chanId)
    end
end

--- Leave all channels of a specific type
-- @param typeName Type letter to match
function Nx.Com:LeaveChans(typeName)
    for n = 1, 10 do
        local id, name = GetChannelName(n)

        if id > 0 and name then
            local name3 = strsub(name, 1, 3)

            if name3 == self.Name then
                local typ = strupper(strsub(name, 4, 4))

                if typ == typeName then
                    if typ == "Z" then
                        -- Don't leave monitored zone channels
                        local nameRoot = Nx.Split("I", name)
                        local id = tonumber(strsub(nameRoot, 5))

                        if not self.ZMonitor[id] then
                            LeaveChannelByName(name)
                        end
                    else
                        LeaveChannelByName(name)
                    end
                end
            end
        end
    end
end

--- Scan existing channels and update status
function Nx.Com:ScanChans()
    local baseName = self.Name .. "Z"

    for n = 1, 10 do
        local id, name = GetChannelName(n)

        if id > 0 and name then
            local name4 = strsub(name, 1, 4)

            if name4 == baseName then
                local nameRoot = Nx.Split("I", name)
                local mapId = tonumber(strsub(nameRoot, 5))

                if mapId then
                    local zs = self.ZStatus[mapId] or {}
                    zs.ChanName = name
                    self.ZStatus[mapId] = zs
                end
            end
        end
    end
end

--- Check if player is in a specific channel type
-- @param typeName Type letter to check
-- @return true if in channel of that type
function Nx.Com:InChanType(typeName)
    for n = 1, 10 do
        local _, name = GetChannelName(n)

        if name then
            local name3 = strsub(name, 1, 3)

            if name3 == self.Name then
                local typ = strsub(name, 4, 4)

                if typ == typeName then
                    return true
                end
            end
        end
    end
end

--- Check if player is in a specific named channel
-- @param chanName Channel name to check
-- @return true if in that channel
function Nx.Com:InChan(chanName)
    for n = 1, 10 do
        local _, name = GetChannelName(n)

        if chanName == name then
            return true
        end
    end
end

---------------------------------------------------------------------------------------
-- Message Sending
---------------------------------------------------------------------------------------

--- Set the send pals mask (called by options)
-- @param mask Bitmask for send targets
function Nx.Com:SetSendPalsMask(mask)
    self.SendPMask = mask
end

--- Queue a message to send to pals
-- @param msg Message to send
function Nx.Com:SendPals(msg)
    assert(msg)
    self.PalsSendQ[#self.PalsSendQ + 1] = msg
end

--- Send a secure message to the global addon channel
-- @param pre Message prefix/type
-- @param msg Message body
function Nx.Com:SendSecG(pre, msg)
    if self.ChanAName then
        local num = GetChannelName(self.ChanAName)

        if num ~= 0 then
            local cs = self:Chksum(msg)
            local str = self:Encode(format("%s%c%c%s", pre, floor(cs / 16) + 65, bit.band(cs, 15) + 65, msg))

            self:SendChan(num, str)
        else
            Nx.prt(L["SendSecG Error: %s"], pre)
        end
    end
end

--- Send a secure message via addon whisper
-- @param pre Message prefix/type
-- @param msg Message body
-- @param plName Target player name
function Nx.Com:SendSecW(pre, msg, plName)
    local cs = self:Chksum(msg)
    local str = self:Encode(format("%s%c%c%s", pre, floor(cs / 16) + 65, bit.band(cs, 15) + 65, msg))

    -- Track bandwidth (packet overhead + WoW overhead)
    self.SentBytes = self.SentBytes + #str + 54 + 20

    Nx:SendCommMessage(self.Name, str, "WHISPER", plName)
end

--- Send a message to a channel or whisper
-- @param chanId Channel identifier
-- @param msg Message to send
-- @param plName Player name (for whispers)
function Nx.Com:Send(chanId, msg, plName)
    assert(msg)

    if chanId == "Z" then
        -- Zone chat channel
        local mapId = Nx.Map:GetRealMapId()
        local chanName = self.ZStatus[mapId] and self.ZStatus[mapId].ChanName

        if chanName then
            local num = GetChannelName(chanName)
            if num ~= 0 then
                self:SendChan(num, msg)
            end
        end

    else
        -- Track bandwidth
        self.SentBytes = self.SentBytes + #msg + 54 + 20

        if chanId == "g" then
            -- Addon guild channel
            if IsInGuild() then
                Nx:SendCommMessage(self.Name, msg, "GUILD")
            end

        elseif chanId == "p" then
            -- Addon party channel
            if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
                Nx:SendCommMessage(self.Name, msg, "INSTANCE_CHAT")
            else
                Nx:SendCommMessage(self.Name, msg, "PARTY")
            end

        elseif chanId == "W" then
            -- Addon whisper
            local name = _normaliseSenderName(plName)
            if not name or (self.UnavailablePals and self.UnavailablePals[name]) then
                return
            end

            self.PendingWhisperTargets = self.PendingWhisperTargets or {}
            self.PendingWhisperTargets[name] = GetTime()
            Nx:SendCommMessage(self.Name, msg, "WHISPER", name)

        elseif chanId == "P" then
            -- Party chat channel
            if GetNumSubgroupMembers() > 0 then
                if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
                    self:SendChatMessageFixed(msg, "INSTANCE_CHAT")
                else
                    self:SendChatMessageFixed(msg, "PARTY")
                end
            end

        else
            assert(false)
        end
    end
end

--- Queue a message for numbered channel sending
-- @param num Channel number
-- @param msg Message to send
function Nx.Com:SendChan(num, msg)
    local data = {}
    data.ChanNum = num
    data.Msg = msg
    tinsert(self.SendChanQ, data)
end

--- Hook for SendChatMessage to track timing
-- @param msg Message being sent
-- @param chanName Channel type
function Nx.Com.SendChatHook(msg, chanName)
    if chanName == "CHANNEL" then
        Nx.Com.SendChanTime = GetTime()
    end
end

---------------------------------------------------------------------------------------
-- Message Encoding/Decoding
---------------------------------------------------------------------------------------

--- Calculate a checksum for a message
-- @param msg Message to checksum
-- @return XOR checksum value
function Nx.Com:Chksum(msg)
    local v = 0
    local xor = bit.bxor

    for n = 1, #msg do
        v = xor(v, strbyte(msg, n))
    end

    return v
end

--- Verify a message checksum
-- @param msg Message to verify
-- @return true if checksum is valid
function Nx.Com:IsChksumOK(msg)
    if #msg >= 4 then
        -- Extract checksum from bytes 3-4
        local ck = (strbyte(msg, 3) - 65) * 16 + (strbyte(msg, 4) - 65)

        -- Calculate checksum of remaining message
        local v = 0
        local xor = bit.bxor

        for n = 5, #msg do
            v = xor(v, strbyte(msg, n))
        end

        return ck == v
    end
end

--- Encode a message for transmission
-- Shifts bytes to avoid invalid characters
-- @param msg Message to encode
-- @return Encoded message
function Nx.Com:Encode(msg)
    local s = {}

    s[1] = strsub(msg, 1, 2)

    for n = 3, #msg do
        s[n - 1] = strchar(strbyte(msg, n) - 1)
    end

    return table.concat(s)
end

--- Decode a received message
-- Reverses byte shifting from encoding
-- @param msg Message to decode
-- @return Decoded message
function Nx.Com:Decode(msg)
    local s = {}

    s[1] = strsub(msg, 1, 2)

    for n = 3, #msg do
        s[n - 1] = strchar(strbyte(msg, n) + 1)
    end

    return table.concat(s)
end

--- Send a chat message with character validation
-- Fixes invalid chat characters before sending
-- @param msg Message to send
-- @param typ Chat type (CHANNEL, PARTY, etc.)
-- @param num Channel number (optional)
function Nx.Com:SendChatMessageFixed(msg, typ, num)
    -- Fix invalid | character (must be |c for color codes)
    local s1 = strfind(msg, "|")
    if s1 then
        if strbyte(msg, s1 + 1) ~= 99 then    -- not 'c'
            msg = gsub(msg, "|", "\1")
        end
    end

    if typ == "CHANNEL" then
        Nx:SendCommMessage(self.Name, msg, typ, num)
    else
        local ok = pcall(SendChatMessage, msg, typ, nil, num)
    end
end

--- Restore characters that were escaped for chat transmission
-- @param msg Message with escaped characters
-- @return Message with restored characters
function Nx.Com:RestoreChars(msg)
    local s1 = strfind(msg, "\1")
    if s1 then
        return gsub(msg, "\1", "|")
    end

    return msg
end

---------------------------------------------------------------------------------------
-- Zone Monitoring
---------------------------------------------------------------------------------------

--- Enable or disable monitoring of a zone channel
-- @param mapId Map ID to monitor
-- @param enable true to enable, false to disable
function Nx.Com:MonitorZone(mapId, enable)
    local i = self.ZMonitor[mapId]

    if enable then
        if not i or i < 0 then
            if self:GetChanCount() >= 10 then
                Nx.prt("|cffff4040" .. L["Monitor Error: All 10 chat channels are in use"])
            else
                Nx.prt("|cff40ff40" .. L["Monitored:"])
            end

            self.ZMonitor[mapId] = 0

            -- List all monitored zones
            for mapId, mode in pairs(self.ZMonitor) do
                if mode >= 0 then
                    local zs = self.ZStatus[mapId]

                    if zs and zs.ChanName then
                        Nx.prt(" %s", Nx.Map:GetMapNameByID(mapId))
                    else
                        Nx.prt(" %s (pending)", Nx.Map:GetMapNameByID(mapId))
                    end
                end
            end
        end
    else
        if i and i >= 0 then
            self.ZMonitor[mapId] = -1
        end
    end

    self:UpdateChannels()
end

--- Check if a zone is being monitored
-- @param mapId Map ID to check
-- @return true if zone is monitored
function Nx.Com:IsZoneMonitored(mapId)
    local i = self.ZMonitor[mapId]
    return i and i >= 0
end

---------------------------------------------------------------------------------------
-- Main Update Loop
---------------------------------------------------------------------------------------

--- Frame update handler
-- Processes message queues and sends position updates
-- @param elapsed Time since last frame
function Nx.Com:OnUpdate(elapsed)
    if not Nx.Com.Initialized then
        return
    end

    local Nx = Nx
    local bgmap = Nx.InBG

    local targetName = UnitName("target")
    -- Retail hands back a "secret" target name inside instances; the bare
    -- `if targetName then` test (and the name broadcast) below would otherwise
    -- throw "boolean test on a secret value". This OnUpdate runs on Carbonite's
    -- own frame, so it's self-taint (it aborts the comm tick + spams the taint
    -- log, it does NOT leak onto secure frames), but we still can't encode a
    -- secret name into the pals message, so probe once and drop it to nil.
    if not pcall(function () return targetName and #targetName end) then
        targetName = nil
    end

    local tm = GetTime()
    local tdiff = tm - self.SendTime

    -- Rate limit updates
    if tdiff < .2 then
        return
    end

    -- Handle AFK state changes
    local isAFK = false
    pcall(function() if UnitIsAFK("player") then isAFK = true end end)
    if isAFK then
        if not self.AFK then
            self:UpdateChannels()
        end
        self.AFK = true
    else
        if self.AFK then
            self:UpdateChannels()
        end
        self.AFK = nil
    end

    -- Calculate position send delay based on state
    local map = Nx.Map:GetMap(1)
    local delay = 10

    if self.PlyrChange then
        if not UnitOnTaxi("player") then
            delay = 3.1
        end
    end

    if Nx.InCombat then
        delay = map.InstanceId and 4.5 or 2.2
    end

    delay = delay * self.SendRate

    if bgmap then
        delay = 25
    end

    if self.AFK then
        delay = 120
    end

    -- Send position update if enough time has passed
    if tm - self.SendPosTime >= delay then
        self.SendPosTime = tm
        self.PlyrChange = false

        local flgs = 0

        -- Set combat flag
        if Nx.InCombat then
            flgs = 1
        end

        -- Get player position
        local x, y = Nx.Map.GetPlayerMapPosition("player")

        if x ~= 0 or y ~= 0 then
            self.PlyrMapId = map:GetCurrentMapId()
            self.PlyrX = x
            self.PlyrY = y + max(map:GetCurrentMapDungeonLevel(), 1) - 1
        else
            if map.InstanceId then
                self.PlyrMapId = map.InstanceId
                if not Nx.Map.InstanceInfo[self.PlyrMapId] then
                    self.PlyrX = 0
                    self.PlyrY = 0
                end
            end
        end

        -- Clamp position values
        x = max(min(self.PlyrX, .999), 0) * 0xfff
        y = max(min(self.PlyrY, 9.999), 0) * 0xfff

        -- Calculate health percentage
        local h = UnitHealth("player")
        if UnitIsDeadOrGhost("player") then
            h = 0
        end
        local hm = UnitHealthMax("player")
        if hm < 1 then
            hm = 1
        end
	local hper = 1
	if not Nx.MidMaps then
            hper = h / hm * 20
        end
        if hper > 0 then
            hper = max(hper, 1)
        end
        hper = floor(hper + .5)

        local plyrLvl = min(UnitLevel("player"), 90)

        -- Build target info string
        local tStr = ""
        if targetName then
            flgs = flgs + 2

            -- Determine target type
            local tType = 5
            if UnitIsFriend("player", "target") then
                tType = 1
            else
                if UnitIsPlayer("target") then
                    tType = 2
                elseif UnitIsEnemy("player", "target") then
                    tType = 3
                    if Nx:UnitIsPlusMob("target") then
                        tType = 4
                    end
                end
            end

            local tLvl = min(UnitLevel("target"), 90)
            local _, tCls = UnitClass("target")
            tCls = self.ClassNames[tCls] or 0

            -- Calculate target health
            local h = UnitHealth("target")
            if UnitIsDeadOrGhost("target") then
                h = 0
            end
            local hm = UnitHealthMax("target")
            local hper = 1
	    if not Nx.MidMaps then
                hper = h / hm * 20
		hm = max(UnitHealthMax("target"), 1)
            end
            if hper > 0 then
                hper = max(hper, 1)
            end
            hper = min(floor(hper + .5), 20)

            local nameLen = 0
            local nameOk = pcall(function() nameLen = #targetName end)
            if nameOk then
                tStr = format("%c%c%c%c%c%s", tType + 35, tLvl + 35, tCls + 35, hper + 35, nameLen + 35, targetName)
            end
        end

        -- Build quest string
        qStr = ""
        if Nx.Quest then
            local qStr, qFlg = Nx.Quest:BuildComSend()
            flgs = flgs + qFlg
        end

        -- Send status message
        self:SendPals(format("S%c%4x%3x%4x%c%c%c%s%s",
            flgs + 35, self.PlyrMapId, x, y, hper + 48, plyrLvl + 35, self.PlyrClassI + 35, tStr, qStr))
    end

    -- Check for queued pals messages
    if not self.PalsSendMsg then
        if #self.PalsSendQ > 0 then
            -- Combine all queued messages
            self.PalsSendMsg = self.PalsSendQ[1]
            self.PalsSendQ[1] = nil

            for n = 2, #self.PalsSendQ do
                self.PalsSendMsg = self.PalsSendMsg .. "\t" .. self.PalsSendQ[n]
                self.PalsSendQ[n] = nil
            end

            self.PosSendNext = -2
        end
    end

    -- Send pals message to next recipient
    if tdiff >= .25 then
        local msg = self.PalsSendMsg

        if msg then
            self.PosSendNext = self.PosSendNext + 1

            if self.PosSendNext > #self.Friends then
                -- Done sending to all recipients
                self.PosSendNext = -2
                self.PalsSendMsg = nil
            else
                if self.PosSendNext == -1 then
                    -- Send to guild
                    if bit.band(self.SendPMask, 2) > 0 then
                        self:Send("g", msg)
                    end

                elseif self.PosSendNext == 0 then
                    -- Send to zone channel
                    if self.SendChanQ[1] == nil and not bgmap and not Nx:FindActiveChatFrameEditBox() then
                        if bit.band(self.SendPMask, 4) > 0 then
                            local sk = self.SendZSkip - 1

                            if sk < 1 then
                                sk = 4
                                self:Send("Z", msg)
                                if Nx.Quest then
                                    Nx.Quest.QLastChanged = nil
                                end
                            end

                            self.SendZSkip = sk
                        end
                    end

                else
                    -- Send to individual friend
                    if bit.band(self.SendPMask, 1) > 0 then
                        self:Send("W", msg, self.Friends[self.PosSendNext])
                    end
                end

                self.SendTime = tm
            end
        end
    end

    -- Process numbered channel send queue
    if Nx:FindActiveChatFrameEditBox() then
        Nx.Com.SendChanTime = tm
    else
        if tm - self.SendChanTime >= .5 then
            if self.SendChanQ[1] then
                local data = self.SendChanQ[1]
                tremove(self.SendChanQ, 1)

                self.SentBytes = self.SentBytes + #data.Msg + 54 + 20
                self:SendChatMessageFixed(data.Msg, "CHANNEL", data.ChanNum)

                self.SendChanTime = tm
            end
        end
    end
end

---------------------------------------------------------------------------------------
-- Map Icon Rendering
---------------------------------------------------------------------------------------

--- Update communication-related map icons
-- Draws player positions from pals and zone info
-- @param map Map instance
-- @return Track name and coordinates if tracking a player
function Nx.Com:UpdateIcons(map)
    -- Update party/raid member tracking periodically
    if Nx.Tick % 20 == 1 then
        local memberNames = {}
        self.MemberNames = memberNames

        local members = MAX_PARTY_MEMBERS
        local unitName = "party"

        if IsInRaid() then
            members = MAX_RAID_MEMBERS
            unitName = "raid"
        end

        local mapId = map.MapId
        local palsInfo = self.PalsInfo

        for n = 1, members do
            local unit = unitName .. n
            local name = UnitName(unit)

            if name then
                local x, y = Nx.Map.GetPlayerMapPosition(unit)

                if x ~= 0 or y ~= 0 then
                    memberNames[name] = 1
                else
                    local info = palsInfo[name]
                    if info and info.EntryMId == mapId then
                        memberNames[name] = 1
                    end
                end
            end
        end
    end

    -- Raise icon level when Alt is held
    local alt = IsAltKeyDown()
    if alt then
        map.Level = map.Level + 3
    end

    self.TrackX = nil

    -- Draw player icons based on settings and location
    if map:GetWorldZone(map.RMapId).City then
        -- In a city
        if Nx.db.profile.Map.ShowOthersInCities then
            self:UpdatePlyrIcons(self.ZPInfo, map, "IconPlyrZ")
        end

        if Nx.db.profile.Map.ShowPalsInCities then
            self:UpdatePlyrIcons(self.PalsInfo, map, "IconPlyrG")
        end
    else
        -- Not in a city
        if Nx.db.profile.Map.ShowOthersInZone then
            self:UpdatePlyrIcons(self.ZPInfo, map, "IconPlyrZ")
        end

        if self.PalsInfo then
            self:UpdatePlyrIcons(self.PalsInfo, map, "IconPlyrG")
        end
    end

    if alt then
        map.Level = map.Level - 3
    end

    return self.TrackName, self.TrackX, self.TrackY
end

--- Draw player icons on the map
-- @param info Player info table to draw from
-- @param map Map instance
-- @param iconName Base icon texture name
function Nx.Com:UpdatePlyrIcons(info, map, iconName)
    local memberNames = self.MemberNames
    local alt = IsAltKeyDown()
    local redGlow = abs(GetTime() * 400 % 200 - 100) / 200 + .5
    local inBG = Nx.InBG

    local t = GetTime()
    local showTargetText = not Nx.Free

    for name, pl in pairs(info) do
        -- Remove stale entries
        if t - pl.T > 35 then
            info[name] = nil

        elseif not memberNames[name] and not memberNames[name:match("^([^%-]+)")] and (not inBG or map.MapId ~= pl.MId) and pl.Y then
            if pl.MId >= 10000 then
                return
            end

            local mapId = pl.MId
            local wx, wy = map:GetWorldPos(mapId, pl.X, pl.Y)

            -- Calculate icon size based on player type
            local sz = 14 * map.DotZoneScale

            if self.PalNames[name] ~= nil then
                sz = 17 * map.DotPalScale
            end

            if map.TrackPlyrs[name] then
                sz = 22 * map.DotPalScale
                self.TrackName = name
                self.TrackX, self.TrackY = wx, wy
            end

            -- Draw player icon
            local f = map:GetIcon()

            if map:ClipFrameW(f, wx, wy, sz, sz, 0) then
                f.NXType = 1000
                f.NXData2 = name

                -- Build tooltip
                local mapName = "?"
                if mapId then
                    mapName = Nx.Map:GetMapNameByID(mapId)
                end
                local tStr = pl.TStr or ""
                local qStr = pl.QStr or ""
                f.NxTip = format("%s\n  %s (%d,%d)%s%s", pl.Tip, mapName, pl.X, pl.Y, tStr, qStr)

                -- Select icon texture
                local txName = iconName

                if self.PalNames[name] == false then
                    txName = "IconPlyrF"
                end

                if bit.band(pl.F, 1) > 0 then
                    txName = txName .. "C"    -- Combat version
                end

                f.texture:SetTexture("Interface\\AddOns\\Carbonite\\Gfx\\Map\\" .. txName)

                -- Show name text when Alt is held
                if alt then
                    local s = pl.TType == 2 and showTargetText and (name .. tStr) or name
                    local txt = map:GetText(s)
                    map:MoveTextToIcon(txt, f, 15, 1)
                end
            end

            -- Draw health bar
            if pl.Health then
                f = map:GetIconNI(1)
                local per = pl.Health / 100

                if per >= .33 then
                    -- Horizontal health bar
                    local sc = map.ScaleDraw
                    map:ClipFrameTL(f, wx - 8 / sc, wy - 8 / sc, 14 * per / sc, 1 / sc)
                    f.texture:SetColorTexture(1, 1, 1, 1)
                else
                    -- Low health indicator
                    map:ClipFrameW(f, wx, wy, 8, 8, 0)

                    if per > 0 then
                        f.texture:SetColorTexture(1, .1, .1, 1 - per * 2)
                    else
                        f.texture:SetColorTexture(0, 0, 0, .5)
                    end
                end

                -- Draw target health indicator
                local tt = pl.TType

                if tt then
                    local per = pl.TH / 100
                    local f = map:GetIconNI(1)
                    local sc = map.ScaleDraw

                    if tt == 1 then
                        -- Friendly target: horizontal green bar
                        map:ClipFrameTL(f, wx - 8 / sc, wy - 2 / sc, 14 * per / sc, 1 / sc)
                        f.texture:SetColorTexture(0, 1, 0, 1)
                    else
                        -- Enemy/neutral target: vertical bar
                        map:ClipFrameTL(f, wx - 8 / sc, wy - 7 / sc, 1 / sc, 13 * per / sc)

                        if tt == 2 then
                            f.texture:SetColorTexture(redGlow, .1, 0, 1)    -- Enemy player (red glow)
                        elseif tt == 3 then
                            f.texture:SetColorTexture(1, 1, 0, 1)           -- Enemy NPC (yellow)
                        elseif tt == 4 then
                            f.texture:SetColorTexture(1, .4, 1, 1)          -- Elite (purple)
                        else
                            f.texture:SetColorTexture(.7, .7, 1, 1)         -- Neutral (blue)
                        end
                    end
                end
            end
        end
    end
end

--- Get quest string for a player
-- @param name Player name
-- @return Quest info string or nil
function Nx.Com:GetPlyrQStr(name)
    local info = self.PalsInfo[name] or self.ZPInfo[name]
    return info and info.QStr
end

---------------------------------------------------------------------------------------
-- Communication Message List Window
---------------------------------------------------------------------------------------

--- Open the communication list window (debug)
function Nx.Com.List:Open()
    -- Currently empty - list window is optional debug feature
end

--- Add info entry to the message list
-- @param type Message type
-- @param name Message content
function Nx.Com.List:AddInfo(type, name)
    -- Currently empty - list entries are optional
end

--- Update the message list display
function Nx.Com.List:Update()
    if not self.Opened then
        return
    end

    -- Update title with stats
    self.Win:SetTitle(format(L["Com %d Bytes sec %d"], #self.Sorted, Nx.Com.SentBytesSec or 0))

    -- Update list
    local list = self.List
    local isLast = list:IsShowLast()

    list:Empty()

    for k, v in pairs(self.Sorted) do
        list:ItemAdd()
        list:ItemSet(1, date("%d %H:%M:%S", v.Time))
        list:ItemSet(2, v.Type)
        list:ItemSet(3, v.Name)
    end

    list:Update(isLast)
end

--- Sort comparison function for message list
-- @param v1 First item
-- @param v2 Second item
-- @return true if v1 should come before v2
function Nx.Com.List.SortCmp(v1, v2)
    return v1.Time < v2.Time
end

--- Sort the message list
function Nx.Com.List:Sort()
    local rcv = Nx.Com.Data.Rcv

    self.Sorted = {}

    local t = self.Sorted
    local i = 1

    for k, v in pairs(rcv) do
        t[i] = v
        i = i + 1
    end

    sort(self.Sorted, self.SortCmp)
end

---------------------------------------------------------------------------------------
-- EOF
---------------------------------------------------------------------------------------

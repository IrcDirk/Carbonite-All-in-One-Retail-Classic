-- Carbonite | Modules / FriendsList
-- Wraps Carbonite's friend + guild roster cache (Nx.Com.Friends +
-- Nx.Com.PalNames). Distinct from GroupMembers because friends are
-- not necessarily in the same group; this is the "people I track
-- across the realm" surface.
--
-- Public API:
--   FriendsList:GetFriends()      -> { name -> info }
--   FriendsList:GetGuild()        -> { name -> info }
--   FriendsList:IsKnown(name)
--   FriendsList:Refresh()         - force re-read

local Carbonite = _G.Carbonite
local FriendsList = {}
Carbonite.Modules.FriendsList = FriendsList

local function com() return _G.Nx and _G.Nx.Com end

function FriendsList:GetFriends()
    local c = com()
    return c and c.Friends or {}
end

function FriendsList:GetGuild()
    local c = com()
    return c and c.GuildList or {}
end

function FriendsList:IsKnown(name)
    if not name then return false end
    local c = com()
    if not c then return false end
    return (c.PalNames and c.PalNames[name] ~= nil) or false
end

function FriendsList:Refresh()
    local c = com()
    if c and c.OnFriendguild_update then c:OnFriendguild_update() end
end

function FriendsList:Count()
    local n = 0
    for _ in pairs(self:GetFriends()) do n = n + 1 end
    return n
end

Carbonite.Core.EventBus:Subscribe("CARBONITE_ENABLE", function()
    if not Carbonite.Core.SlashCommands then return end
    Carbonite.Core.SlashCommands:Register("friends", function()
        local log = Carbonite.Core.Logger:Get("FriendsList")
        log:info("friends tracked: %d", FriendsList:Count())
    end, "show friend-list summary")
end)

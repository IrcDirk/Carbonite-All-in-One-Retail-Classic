-- Carbonite | Modules / SoundPlayer
-- Centralized sound playback. Carbonite plays sound effects for
-- login (PlaySound READY_CHECK), quest complete (custom .ogg), and
-- a handful of other cues. The legacy code calls PlaySound /
-- PlaySoundFile inline at each call site; this class is the
-- documented accessor that respects the user's master toggle.
--
-- Public API:
--   SoundPlayer:Play(soundID)
--   SoundPlayer:PlayFile(path)
--   SoundPlayer:PlayQuestComplete()
--   SoundPlayer:PlayLogin()
--   SoundPlayer:IsEnabled()        -- profile.General.TitleSoundOn
--   SoundPlayer:SetEnabled(on)
--
-- Available sound IDs are listed in Nx.OptsDataSoundsIDs in
-- NxOptions.lua; new code should look them up by index there.

local Carbonite = _G.Carbonite

local SoundPlayer = {}
Carbonite.Modules.SoundPlayer = SoundPlayer

local QUEST_COMPLETE_PATH = "Interface\\AddOns\\Carbonite\\Snd\\QuestComplete.ogg"

function SoundPlayer:IsEnabled()
    local Nx = _G.Nx
    return Nx and Nx.db and Nx.db.profile and Nx.db.profile.General
       and Nx.db.profile.General.TitleSoundOn == true or false
end

function SoundPlayer:SetEnabled(on)
    local Nx = _G.Nx
    if Nx and Nx.db and Nx.db.profile and Nx.db.profile.General then
        Nx.db.profile.General.TitleSoundOn = on and true or false
    end
end

function SoundPlayer:Play(soundID)
    if not soundID then return end
    if not self:IsEnabled() then return end
    if _G.PlaySound then _G.PlaySound(soundID) end
end

function SoundPlayer:PlayFile(path)
    if not path then return end
    if not self:IsEnabled() then return end
    if _G.PlaySoundFile then _G.PlaySoundFile(path) end
end

function SoundPlayer:PlayQuestComplete()
    self:PlayFile(QUEST_COMPLETE_PATH)
end

function SoundPlayer:PlayLogin()
    if _G.SOUNDKIT and _G.SOUNDKIT.READY_CHECK then
        self:Play(_G.SOUNDKIT.READY_CHECK)
    end
end

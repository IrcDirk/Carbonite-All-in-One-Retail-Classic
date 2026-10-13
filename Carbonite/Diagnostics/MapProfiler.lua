-- Maps exposes a scoped view of the shared measurement source.
local Carbonite, Nx = _G.Carbonite, _G.Nx
if not Carbonite or not Nx or not Carbonite.CreateDiagnosticProfiler then return end
local map = Carbonite.CreateDiagnosticProfiler("map")
Nx.MapProfiler = map
Carbonite.Modules.MapProfiler = map

-- The main profiler owns /carb dispatch. Preserve native /help except for
-- the existing profiler shortcut; installing this bridge never wraps timings.
local function InstallNativeHelp()
    if not SlashCmdList or type(SlashCmdList.HELP) ~= "function" or map.nativeHelpInstalled then return end
    local original = SlashCmdList.HELP
    SlashCmdList.HELP = function(message, ...)
        if tostring(message or ""):match("^%s*(.-)%s*$"):lower() == "profiler" then
            return Nx.QuestProfiler:PrintHelp()
        end
        return original(message, ...)
    end
    map.nativeHelpInstalled = true
end
InstallNativeHelp()
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", InstallNativeHelp)

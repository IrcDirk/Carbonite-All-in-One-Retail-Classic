-- Quest profiler belongs to Carbonite.Quests; core supplies shared diagnostics.
local Carbonite = _G.Carbonite
if not Carbonite or not Carbonite.CreateDiagnosticProfiler then return end
local profiler = Carbonite.CreateDiagnosticProfiler("quest")

-- Add diagnostics to the existing quest-module page, retaining its options.
local quest = Carbonite.Quest
if quest and type(quest.GetOptionsConfig) == "function" then
    local original = quest.GetOptionsConfig
    quest.GetOptionsConfig = function(self, ...)
        local options = original(self, ...)
        if options and options.args then
            options.args.profilerDiagnostics = options.args.profilerDiagnostics or profiler:GetOptions()
        end
        return options
    end
    quest:GetOptionsConfig()
end

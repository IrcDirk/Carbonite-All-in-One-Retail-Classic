-- Compatibility entry point for older TOCs. Both scopes use the single
-- measurement source loaded through Modules.xml; no extra hooks are installed.
local Carbonite, Nx = _G.Carbonite, _G.Nx
if not Carbonite or not Nx or not Nx.QuestProfiler then return end
local source = Nx.QuestProfiler
local proxies = {}

function Carbonite.CreateDiagnosticProfiler(scope)
    scope = scope == "map" and "map" or "quest"
    if proxies[scope] then return proxies[scope] end
    local proxy = {}
    function proxy:GetOptions() return source:GetOptionsConfig(scope) end
    function proxy:GetOptionsConfig() return source:GetOptionsConfig(scope) end
    function proxy:IsEnabled() return source:IsEnabled(scope) end
    function proxy:SetEnabled(enabled) return source:SetEnabled(enabled, scope) end
    function proxy:BuildReport() return source:BuildReport(scope) end
    function proxy:OpenReport(view) return source:OpenReport(scope, view) end
    function proxy:PrintStatus() return source:PrintStatus(scope) end
    function proxy:PrintHelp() return source:PrintHelp(scope) end
    function proxy:HandleCommand(argument) return source:HandleCommand(argument, scope) end
    function proxy:Clear() return source:Clear(scope) end
    function proxy:CaptureBaseline(label) return source:CaptureBaseline(label, scope) end
    function proxy:ClearBaseline() return source:ClearBaseline(scope) end
    function proxy:SetLimit(limit) return source:SetLimit(limit) end
    function proxy:RunSelfTest() return source:RunSelfTest() end
    proxies[scope] = proxy
    return proxy
end

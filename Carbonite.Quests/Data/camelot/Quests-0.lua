---------------------------------------------------------------------------------------
-- Carbonite - Quest Data Level 0-0 (Special / Unbucketed)
---------------------------------------------------------------------------------------

if not Nx.ModQuests then
    Nx.ModQuests = {}
end

function Nx.ModQuests:Data0()
    local ModQuests = {
    }
    return ModQuests
end

function Nx.ModQuests:Load0()
    local ModQuests = Nx.ModQuests:Data0()
    local count = 0
    for key, val in pairs(ModQuests) do
        Nx.Quests[key] = val
        count = count + 1
    end
    ModQuests = {}
    return count
end

function Nx.ModQuests:Clear0()
    --ModQuests = {}
end

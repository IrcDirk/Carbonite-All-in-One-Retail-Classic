---------------------------------------------------------------------------------------
-- Carbonite - Quest Data Level 0-0 (Special / Unbucketed)
---------------------------------------------------------------------------------------

if not Nx.ModQuests then
    Nx.ModQuests = {}
end

function Nx.ModQuests:Data0()
    local ModQuests = {
        [7790] = {
            Quest = [=[quest:7790|3|0|0|8152|0|0]=],
            Start = "270191|1422|32|70.08|44.16",
            End = "668183|1423|32|4.04|32.99",
        },
        [8152] = {
            Quest = [=[quest:8152|3|0|0|97986|0|0]=],
            Start = "668183|1423|32|4.04|32.99",
        },
        [60860] = {
            Quest = [=[Your Reward has Arrived!|3|0|0|0|0|0]=],
            Start = "5111|1455|32|18.15|51.45",
            End = "5111|1455|32|18.15|51.45",
        },
        [60870] = {
            Quest = [=[A Special Gift|3|0|0|0|0|0]=],
            Start = "17249|1434|32|28.13|75.9",
            End = "17249|1434|32|28.13|75.9",
        },
        [86747] = {
            Quest = [=[Legashi Horns|3|0|0|0|0|0]=],
            End = "235903|1447|32|42.0|38.88",
        },
        [92067] = {
            Quest = [=[Feeding Time!|3|0|0|0|0|0]=],
        },
        [93162] = {
            Quest = [=[Head of the Obliterator|3|0|0|0|0|0]=],
        },
        [93925] = {
            Quest = [=[Beads for Brerufa|3|0|0|0|0|0]=],
            Start = "256978|2482|32|20.56|71.73",
            End = "256978|2482|32|20.56|71.73",
        },
        [96246] = {
            Quest = [=[Blackmaw Pouches|3|0|0|0|0|0]=],
        },
        [96379] = {
            Quest = [=[State Secrets|3|0|0|0|0|0]=],
            Start = "214954|1434|32|28.51|75.77",
            End = "214954|1434|32|28.51|75.77",
        },
        [96602] = {
            Quest = [=[More Unstable Magic|1|0|0|0|0|0]=],
            Start = "252085|1416|32|14.15|60.05",
            End = "252085|1416|32|14.15|60.05",
        },
        [97271] = {
            Quest = [=[Maul or Nothing!|3|0|0|0|0|0]=],
        },
        [98476] = {
            Quest = [=[More Unstable Magic|2|0|0|0|0|0]=],
            Start = "272633|1412|32|33.54|22.66",
            End = "272633|1412|32|33.54|22.66",
        },
        [98898] = {
            Quest = [=[Darkspear Islands Clash|3|0|0|0|0|0]=],
        },
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

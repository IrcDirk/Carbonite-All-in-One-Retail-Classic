if ( GetLocale() ~= "zhTW" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "zhTW")
if not L then return end

-- General Nodes
L["Artifact"] = "考古學文物"
L["Everfrost"] = "永霜屑片"
L["Gas"] = "氣雲"
L["Ooze Covered"] = "軟泥覆蓋的"

-- Timber (WoD Lumber Mill)
L["Small Timber"] = true
L["Medium Timber"] = true
L["Large Timber"] = true
L["Timber"] = "中型木料"
L["Logging"] = true

-- Herbs - Classic
L["Peacebloom"] = "寧神花"
L["Silverleaf"] = "銀葉草"
L["Earthroot"] = "地根草"
L["Mageroyal"] = "魔皇草"
L["Briarthorn"] = "石南草"
L["Stranglekelp"] = "荊棘藻"
L["Bruiseweed"] = "跌打草"
L["Wild Steelbloom"] = "野鋼花"
L["Grave Moss"] = "墓地苔"
L["Kingsblood"] = "皇血草"
L["Liferoot"] = "活根草"
L["Fadeleaf"] = "枯葉草"
L["Goldthorn"] = "金棘草"
L["Khadgar's Whisker"] = "卡德加的鬍鬚"
L["Dragon's Teeth"] = "龍齒草"
L["Firebloom"] = "火焰花"
L["Purple Lotus"] = "紫蓮花"
L["Arthas' Tears"] = "阿薩斯之淚"
L["Sungrass"] = "太陽花"
L["Blindweed"] = "盲目草"
L["Ghost Mushroom"] = "鬼魂菇"
L["Gromsblood"] = "格羅姆之血"
L["Golden Sansam"] = "黃金蓼"
L["Dreamfoil"] = "夢葉草"
L["Mountain Silversage"] = "山鼠草"
L["Plaguebloom"] = "瘟疫花"
L["Sorrowmoss"] = "悲傷苔蘚"
L["Icecap"] = "冰蓋草"
L["Black Lotus"] = "黑蓮花"

-- Herbs - TBC
L["Felweed"] = "魔獄草"
L["Dreaming Glory"] = "譽夢草"
L["Ragveil"] = "拉格維花"
L["Flame Cap"] = "火帽花"
L["Terocone"] = "泰魯草"
L["Ancient Lichen"] = "古老青苔"
L["Netherbloom"] = "虛空花"
L["Netherdust Bush"] = "虛空之塵灌木"
L["Nightmare Vine"] = "夢魘根"
L["Mana Thistle"] = "法力薊"
L["Bloodthistle"] = "血薊"
L["Glowcap"] = "白閃菇"

-- Herbs - WotLK
L["Goldclover"] = "金黃苜蓿"
L["Firethorn"] = "火棘"
L["Tiger Lily"] = "虎百合"
L["Talandra's Rose"] = "泰蘭卓的玫瑰"
L["Adder's Tongue"] = "奎蛇之舌"
L["Frozen Herb"] = "冰凍草藥"
L["Lichbloom"] = "巫妖之華"
L["Icethorn"] = "冰棘"
L["Frost Lotus"] = "冰霜蓮花"

-- Herbs - Cataclysm
L["Cinderbloom"] = "燼花"
L["Stormvine"] = "風暴藤"
L["Azshara's Veil"] = "艾薩拉的帷紗"
L["Heartblossom"] = "心綻花"
L["Whiptail"] = "鞭尾蜥草"
L["Twilight Jasmine"] = "暮光茉莉"

-- Herbs - MoP
L["Green Tea Leaf"] = "綠茶葉"
L["Rain Poppy"] = "雨罌粟"
L["Silkweed"] = "絲草"
L["Snow Lily"] = "雪百合"
L["Golden Lotus"] = "金蓮會"
L["Fool's Cap"] = "丑帽菇"
L["Sha-Touched Herb"] = "煞化的藥草"
L["Chameleon Lotus"] = "變色蓮花"

-- Herbs - WoD
L["Frostweed"] = "霜草"
L["Fireweed"] = "火草"
L["Gorgrond Flytrap"] = "格古隆德捕蠅草"
L["Starflower"] = "星辰花"
L["Nagrand Arrowbloom"] = "納葛蘭箭矢花"
L["Talador Orchid"] = "塔拉多爾蘭花"
L["Withered Herb"] = true

-- Herbs - Legion
L["Aethril"] = "紫地根草"
L["Dreamleaf"] = "幻夢草"
L["Foxflower"] = "狐花"
L["Fjarnskaggl"] = "鬼燈果"
L["Starlight Rose"] = "星輝玫瑰"
L["Felwort"] = "魔草"
L["Astral Glory"] = "暗星之芒"

-- Herbs - BfA
L["Akunda's Bite"] = "亞昆達之噬"
L["Anchor Weed"] = "錨草"
L["Riverbud"] = "河芽草"
L["Sea Stalks"] = "海莖草"
L["Siren's Sting"] = "海妖之棘"
L["Star Moss"] = "星苔"
L["Winter's Kiss"] = "冬吻花"

-- Herbs - Shadowlands
L["Death Blossom"] = "亡喪花"
L["Marrowroot"] = "髓根"
L["Nightshade"] = "夜影花"
L["Rising Glory"] = "榮騰"
L["Vigil's Torch"] = "守夜火炬"
L["Widowbloom"] = "寡婦花"

-- Herbs - Dragonflight
L["Hochenblume"] = "荷芡花"
L["Decayed Hochenblume"] = "腐朽荷芡花"
L["Frigid Hochenblume"] = "嚴寒荷芡花"
L["Infurious Hochenblume"] = true
L["Lush Hochenblume"] = "茂盛荷芡花"
L["Titan-Touched Hochenblume"] = "泰坦之觸荷芡花"
L["Windswept Hochenblume"] = "風捲荷芡花"
L["Bubble Poppy"] = "泡沫罌粟"
L["Decayed Bubble Poppy"] = "腐朽泡沫罌粟"
L["Frigid Bubble Poppy"] = "嚴寒泡沫罌粟"
L["Infurious Bubble Poppy"] = true
L["Lush Bubble Poppy"] = "茂盛泡沫罌粟"
L["Titan-Touched Bubble Poppy"] = "泰坦之觸泡沫罌粟"
L["Windswept Bubble Poppy"] = "風捲泡沫罌粟"
L["Saxifrage"] = "虎耳草"
L["Decayed Saxifrage"] = "腐朽虎耳草"
L["Frigid Saxifrage"] = "嚴寒虎耳草"
L["Infurious Saxifrage"] = true
L["Lush Saxifrage"] = "茂盛虎耳草"
L["Titan-Touched Saxifrage"] = "泰坦之觸虎耳草"
L["Windswept Saxifrage"] = "風捲虎耳草"
L["Writhebark"] = "攀纏樹皮"
L["Decayed Writhebark"] = "腐朽攀纏樹皮"
L["Frigid Writhebark"] = "嚴寒攀纏樹皮"
L["Infurious Writhebark"] = true
L["Lush Writhebark"] = "茂盛攀纏樹皮"
L["Titan-Touched Writhebark"] = "泰坦之觸攀纏樹皮"
L["Windswept Writhebark"] = "風捲攀纏樹皮"

-- Herbs - The War Within
L["Mycobloom"] = "真菌花"
L["Altered Mycobloom"] = "變異真菌花"
L["Crystallized Mycobloom"] = "結晶真菌花"
L["Irradiated Mycobloom"] = "輻射真菌花"
L["Lush Mycobloom"] = "茂盛真菌花"
L["Sporefused Mycobloom"] = "含孢真菌花"
L["Luredrop"] = "誘滴草"
L["Altered Luredrop"] = "變異誘滴草"
L["Crystallized Luredrop"] = "結晶誘滴草"
L["Irradiated Luredrop"] = "輻射誘滴草"
L["Lush Luredrop"] = "茂盛誘滴草"
L["Sporefused Luredrop"] = "含孢誘滴草"
L["Arathor's Spear"] = "阿拉索之矛"
L["Crystallized Arathor's Spear"] = "結晶阿拉索之矛"
L["Irradiated Arathor's Spear"] = "輻射阿拉索之矛"
L["Lush Arathor's Spear"] = "茂盛阿拉索之矛"
L["Sporefused Arathor's Spear"] = "注孢阿拉索之矛"
L["Blessing Blossom"] = "祝綻花"
L["Crystallized Blessing Blossom"] = "結晶祝綻花"
L["Irradiated Blessing Blossom"] = "輻射祝綻花"
L["Lush Blessing Blossom"] = "茂盛祝綻花"
L["Sporefused Blessing Blossom"] = "含孢祝綻花"
L["Orbinid"] = "錐頭草"
L["Altered Orbinid"] = "變異錐頭草"
L["Crystallized Orbinid"] = "結晶錐頭草"
L["Irradiated Orbinid"] = "輻射錐頭草"
L["Lush Orbinid"] = "茂盛錐頭草"
L["Sporefused Orbinid"] = "注孢錐頭草"

-- Herbs - Midnight
L["Argentleaf"] = true
L["Lush Argentleaf"] = true
L["Lightfused Argentleaf"] = true
L["Primal Argentleaf"] = true
L["Voidbound Argentleaf"] = true
L["Wild Argentleaf"] = true
L["Azeroot"] = true
L["Lush Azeroot"] = true
L["Lightfused Azeroot"] = true
L["Primal Azeroot"] = true
L["Voidbound Azeroot"] = true
L["Wild Azeroot"] = true
L["Mana Lily"] = true
L["Lush Mana Lily"] = true
L["Lightfused Mana Lily"] = true
L["Primal Mana Lily"] = true
L["Voidbound Mana Lily"] = true
L["Wild Mana Lily"] = true
L["Sanguithorn"] = true
L["Lush Sanguithorn"] = true
L["Lightfused Sanguithorn"] = true
L["Primal Sanguithorn"] = true
L["Voidbound Sanguithorn"] = true
L["Wild Sanguithorn"] = true
L["Tranquility Bloom"] = true
L["Lush Tranquility Bloom"] = true
L["Lightfused Tranquility Bloom"] = true
L["Primal Tranquility Bloom"] = true
L["Voidbound Tranquility Bloom"] = true
L["Wild Tranquility Bloom"] = true

-- Mines - Classic
L["Copper Vein"] = "銅礦脈"
L["Tin Vein"] = "錫礦脈"
L["Silver Vein"] = "銀礦脈"
L["Incendicite Mineral Vein"] = "火岩礦脈"
L["Lesser Bloodstone Deposit"] = "次級血石礦床"
L["Iron Deposit"] = "鐵礦床"
L["Indurium Mineral Vein"] = "精鐵礦脈"
L["Gold Vein"] = "金礦脈"
L["Mithril Deposit"] = "秘銀礦床"
L["Truesilver Deposit"] = "真銀礦床"
L["Dark Iron Deposit"] = "黑鐵礦床"
L["Small Thorium Vein"] = "瑟銀礦脈"
L["Thorium Vein"] = "瑟銀礦脈"
L["Rich Thorium Vein"] = "富瑟銀礦脈"
L["Small Obsidian Chunk"] = "小黑曜石塊"
L["Large Obsidian Chunk"] = "大黑曜石塊"

-- Mines - TBC
L["Fel Iron Deposit"] = "魔鐵礦床"
L["Adamantite Deposit"] = "堅鋼礦床"
L["Rich Adamantite Deposit"] = "豐沃的堅鋼礦床"
L["Khorium Vein"] = "克銀礦脈"
L["Nethercite Deposit"] = "虛空聚晶礦床"
L["Ancient Gem Vein"] = "遠古寶石礦脈"

-- Mines - WotLK
L["Cobalt Deposit"] = "鈷藍礦床"
L["Rich Cobalt Deposit"] = "豐沃的鈷藍礦床"
L["Saronite Deposit"] = "薩鋼礦床"
L["Rich Saronite Deposit"] = "豐沃的薩鋼礦床"
L["Titanium Vein"] = "泰坦鋼礦脈"

-- Mines - Cataclysm
L["Obsidium Deposit"] = "黑曜石塊"
L["Rich Obsidium Deposit"] = "豐沃的黑曜石塊"
L["Elementium Vein"] = "源質礦脈"
L["Rich Elementium Vein"] = "豐沃的源質礦脈"
L["Pyrite Deposit"] = "黃鐵礦床"
L["Rich Pyrite Deposit"] = "豐沃的黃鐵礦床"

-- Mines - MoP
L["Ghost Iron Deposit"] = "鬼鐵礦床"
L["Rich Ghost Iron Deposit"] = "豐沃的鬼鐵礦脈"
L["Kyparite Deposit"] = "奇帕利礦床"
L["Rich Kyparite Deposit"] = "豐沃的奇帕利礦床"
L["Trillium Vein"] = "延齡礦脈"
L["Rich Trillium Vein"] = "豐沃的延齡礦脈"

-- Mines - WoD
L["True Iron Deposit"] = "真鐵礦床"
L["Rich True Iron Deposit"] = "豐沃的真鐵礦床"
L["Smoldering True Iron Deposit"] = "陰燃的真鐵礦脈"
L["Blackrock Deposit"] = "黑石礦床"
L["Rich Blackrock Deposit"] = "豐沃的黑石礦床"

-- Mines - Legion
L["Leystone Deposit"] = true
L["Leystone Seam"] = true
L["Living Leystone"] = true
L["Felslate Deposit"] = true
L["Felslate Seam"] = true
L["Living Felslate"] = true
L["Empyrium Deposit"] = true
L["Rich Empyrium Deposit"] = true
L["Empyrium Seam"] = true

-- Mines - BfA
L["Monelite Deposit"] = "蒙那萊礦床"
L["Rich Monelite Deposit"] = "豐沃的蒙那萊礦床"
L["Monelite Seam"] = "蒙那萊礦層"
L["Platinum Deposit"] = "白金礦床"
L["Rich Platinum Deposit"] = "豐沃的白金礦床"
L["Storm Silver Deposit"] = "風暴白銀礦床"
L["Rich Storm Silver Deposit"] = "豐沃的風暴白銀礦床"
L["Storm Silver Seam"] = "風暴白銀礦層"

-- Mines - Shadowlands
L["Laestrite Deposit"] = "雷瑟瑞礦床"
L["Rich Laestrite Deposit"] = "豐沃的雷瑟瑞礦床"
L["Elethium Deposit"] = "艾雷希礦床"
L["Rich Elethium Deposit"] = "豐沃的艾雷希礦床"
L["Solenium Deposit"] = "陽炎金礦床"
L["Rich Solenium Deposit"] = "豐沃的陽炎金礦床"
L["Oxxein Deposit"] = "奧辛礦床"
L["Rich Oxxein Deposit"] = "豐沃的奧辛礦床"
L["Phaedrum Deposit"] = "菲卓姆礦床"
L["Rich Phaedrum Deposit"] = "豐沃的菲卓姆礦床"
L["Sinvyr Deposit"] = "鋅維爾礦床"
L["Rich Sinvyr Deposit"] = "豐沃的鋅維爾礦床"

-- Mines - Dragonflight
L["Serevite Deposit"] = "賽若拜岩礦床"
L["Hardened Serevite Deposit"] = "硬化賽若拜岩礦床"
L["Infurious Serevite Deposit"] = true
L["Molten Serevite Deposit"] = "熔火賽若拜岩礦床"
L["Primal Serevite Deposit"] = "洪荒賽若拜岩礦床"
L["Rich Serevite Deposit"] = "豐沃的賽若拜岩礦床"
L["Titan-Touched Serevite Deposit"] = "泰坦之觸賽若拜岩礦床"
L["Draconium Deposit"] = "龍金礦床"
L["Hardened Draconium Deposit"] = "硬化龍金礦床"
L["Infurious Draconium Deposit"] = true
L["Molten Draconium Deposit"] = "熔火龍金礦床"
L["Primal Draconium Deposit"] = "洪荒龍金礦床"
L["Rich Draconium Deposit"] = "豐沃的龍金礦床"
L["Titan-Touched Draconium Deposit"] = "泰坦之觸龍金礦床"

-- Mines - The War Within
L["Bismuth"] = "鉍礦"
L["Crystallized Bismuth"] = "結晶鉍礦"
L["EZ-Mine Bismuth"] = "簡易礦坑鉍礦"
L["Rich Bismuth"] = "豐沃鉍礦"
L["Weeping Bismuth"] = "哀泣鉍礦"
L["Ironclaw"] = "鐵爪礦"
L["Crystallized Ironclaw"] = "結晶鐵爪礦"
L["EZ-Mine Ironclaw"] = "易採雷鐵爪礦"
L["Rich Ironclaw"] = "豐沃鐵爪礦"
L["Weeping Ironclaw"] = "哀泣鐵爪礦"
L["Aqirite"] = "亞基岩"
L["Crystallized Aqirite"] = "結晶亞基岩"
L["EZ-Mine Aqirite"] = true
L["Rich Aqirite"] = "豐沃亞基岩"
L["Weeping Aqirite"] = "哀泣亞基岩"
L["Webbed Ore Deposit"] = "網狀礦石礦點"

-- Mines - Midnight
L["Brilliant Silver"] = true
L["Rich Brilliant Silver"] = true
L["Lightfused Brilliant Silver"] = true
L["Primal Brilliant Silver"] = true
L["Voidbound Brilliant Silver"] = true
L["Wild Brilliant Silver"] = true
L["Refulgent Copper"] = true
L["Rich Refulgent Copper"] = true
L["Lightfused Refulgent Copper"] = true
L["Primal Refulgent Copper"] = true
L["Voidbound Refulgent Copper"] = true
L["Wild Refulgent Copper"] = true
L["Umbral Tin"] = true
L["Rich Umbral Tin"] = true
L["Lightfused Umbral Tin"] = true
L["Primal Umbral Tin"] = true
L["Voidbound Umbral Tin"] = true
L["Wild Umbral Tin"] = true

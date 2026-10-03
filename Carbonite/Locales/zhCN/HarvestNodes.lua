if ( GetLocale() ~= "zhCN" ) then
	return
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "zhCN")
if not L then return end

-- General Nodes
L["Artifact"] = "考古点"
L["Everfrost"] = "永冻薄片"
L["Gas"] = "气体"
L["Ooze Covered"] = "软泥覆盖"

-- Timber (WoD Lumber Mill)
L["Small Timber"] = true
L["Medium Timber"] = true
L["Large Timber"] = true
L["Timber"] = "木料"
L["Logging"] = true

-- Herbs - Classic
L["Peacebloom"] = "宁神花"
L["Silverleaf"] = "银叶草"
L["Earthroot"] = "地根草"
L["Mageroyal"] = "魔皇草"
L["Briarthorn"] = "石南草"
L["Stranglekelp"] = "荆棘藻"
L["Bruiseweed"] = "跌打草"
L["Wild Steelbloom"] = "野钢花"
L["Grave Moss"] = "墓地苔"
L["Kingsblood"] = "皇血草"
L["Liferoot"] = "活根草"
L["Fadeleaf"] = "枯叶草"
L["Goldthorn"] = "金棘草"
L["Khadgar's Whisker"] = "卡德加的胡须"
L["Dragon's Teeth"] = "龙齿草"
L["Firebloom"] = "火焰花"
L["Purple Lotus"] = "紫莲花"
L["Arthas' Tears"] = "阿尔萨斯之泪"
L["Sungrass"] = "太阳草"
L["Blindweed"] = "盲目草"
L["Ghost Mushroom"] = "幽灵菇"
L["Gromsblood"] = "格罗姆之血"
L["Golden Sansam"] = "黄金参"
L["Dreamfoil"] = "梦叶草"
L["Mountain Silversage"] = "山鼠草"
L["Plaguebloom"] = "瘟疫花"
L["Sorrowmoss"] = "天灾花"
L["Icecap"] = "冰盖草"
L["Black Lotus"] = "黑莲花"

-- Herbs - TBC
L["Felweed"] = "魔草"
L["Dreaming Glory"] = "梦露花"
L["Ragveil"] = "邪雾草"
L["Flame Cap"] = "烈焰菇"
L["Terocone"] = "泰罗果"
L["Ancient Lichen"] = "远古苔"
L["Netherbloom"] = "虚空花"
L["Netherdust Bush"] = "灵尘灌木"
L["Nightmare Vine"] = "噩梦藤"
L["Mana Thistle"] = "法力蓟"
L["Bloodthistle"] = "血蓟"
L["Glowcap"] = "亮顶蘑菇"

-- Herbs - WotLK
L["Goldclover"] = "金苜蓿"
L["Firethorn"] = "火叶"
L["Tiger Lily"] = "卷丹"
L["Talandra's Rose"] = "塔兰德拉的玫瑰"
L["Adder's Tongue"] = "蛇信草"
L["Frozen Herb"] = "冰冷的草药"
L["Lichbloom"] = "巫妖花"
L["Icethorn"] = "冰棘草"
L["Frost Lotus"] = "雪莲花"

-- Herbs - Cataclysm
L["Cinderbloom"] = "燃烬草"
L["Stormvine"] = "风暴藤"
L["Azshara's Veil"] = "艾萨拉雾菇"
L["Heartblossom"] = "心灵之花"
L["Whiptail"] = "鞭尾草"
L["Twilight Jasmine"] = "暮光茉莉"

-- Herbs - MoP
L["Green Tea Leaf"] = "绿茶叶"
L["Rain Poppy"] = "雨粟花"
L["Silkweed"] = "柔丝草"
L["Snow Lily"] = "雪百合"
L["Golden Lotus"] = "金莲教"
L["Fool's Cap"] = "愚人菇"
L["Sha-Touched Herb"] = "染煞草药"
L["Chameleon Lotus"] = "拟态莲"

-- Herbs - WoD
L["Frostweed"] = "寒霜草"
L["Fireweed"] = "炎火草"
L["Gorgrond Flytrap"] = "戈尔隆德捕蝇草"
L["Starflower"] = "烁星花"
L["Nagrand Arrowbloom"] = "纳格兰箭叶花"
L["Talador Orchid"] = "塔拉多幽兰"
L["Withered Herb"] = "枯萎的草药"

-- Herbs - Legion
L["Aethril"] = "安瑟瑞尔花"
L["Dreamleaf"] = "入梦叶"
L["Foxflower"] = "狐尾花"
L["Fjarnskaggl"] = "夏斯卡格草"
L["Starlight Rose"] = "星光玫瑰"
L["Felwort"] = "邪能球茎"
L["Astral Glory"] = "星辰之耀"

-- Herbs - BfA
L["Akunda's Bite"] = "阿昆达之噬"
L["Anchor Weed"] = "锚草"
L["Riverbud"] = "流波花苞"
L["Sea Stalks"] = "海潮茎杆"
L["Siren's Sting"] = "海妖之刺"
L["Star Moss"] = "星光苔"
L["Winter's Kiss"] = "凛冬之吻"

-- Herbs - Shadowlands
L["Death Blossom"] = "绽亡花"
L["Marrowroot"] = "髓根草"
L["Nightshade"] = "夜影花"
L["Rising Glory"] = "晋荣花"
L["Vigil's Torch"] = "慰魂之光"
L["Widowbloom"] = "孀花"

-- Herbs - Dragonflight
L["Hochenblume"] = "霍亨布墨花"
L["Decayed Hochenblume"] = "腐朽霍亨布墨花"
L["Frigid Hochenblume"] = "冷冽霍亨布墨花"
L["Infurious Hochenblume"] = "震怒霍亨布墨花"
L["Lush Hochenblume"] = "繁茂的霍亨布墨花"
L["Titan-Touched Hochenblume"] = "泰坦点化的霍亨布墨花"
L["Windswept Hochenblume"] = "啸风霍亨布墨花"
L["Bubble Poppy"] = "泡粟花"
L["Decayed Bubble Poppy"] = "腐朽泡粟花"
L["Frigid Bubble Poppy"] = "冷冽泡粟花"
L["Infurious Bubble Poppy"] = "熔火泡粟花"
L["Lush Bubble Poppy"] = "繁茂的泡粟花"
L["Titan-Touched Bubble Poppy"] = "泰坦点化的泡粟花"
L["Windswept Bubble Poppy"] = "啸风泡粟花"
L["Saxifrage"] = "虎耳草"
L["Decayed Saxifrage"] = "腐朽虎耳草"
L["Frigid Saxifrage"] = "冷冽虎耳草"
L["Infurious Saxifrage"] = "震怒虎耳草"
L["Lush Saxifrage"] = "繁茂的虎耳草"
L["Titan-Touched Saxifrage"] = "泰坦点化的虎耳草"
L["Windswept Saxifrage"] = "啸风虎耳草"
L["Writhebark"] = "歪扭树皮"
L["Decayed Writhebark"] = "腐朽歪扭树皮"
L["Frigid Writhebark"] = "冷冽歪扭树皮"
L["Infurious Writhebark"] = "震怒歪扭树皮"
L["Lush Writhebark"] = "繁茂的歪扭树皮"
L["Titan-Touched Writhebark"] = "泰坦点化的歪扭树皮"
L["Windswept Writhebark"] = "啸风歪扭树皮"

-- Herbs - The War Within
L["Mycobloom"] = "菌丝花"
L["Altered Mycobloom"] = "异变的菌丝花"
L["Crystallized Mycobloom"] = "晶化的菌丝花"
L["Irradiated Mycobloom"] = "辐能的菌丝花"
L["Lush Mycobloom"] = "繁茂的菌丝花"
L["Sporefused Mycobloom"] = "注孢的菌丝花"
L["Luredrop"] = "惑露堇"
L["Altered Luredrop"] = "异变的惑露堇"
L["Crystallized Luredrop"] = "晶化的惑露堇"
L["Irradiated Luredrop"] = "辐能的惑露堇"
L["Lush Luredrop"] = "繁茂的惑露堇"
L["Sporefused Luredrop"] = "注孢的惑露堇"
L["Arathor's Spear"] = "阿拉索之矛"
L["Crystallized Arathor's Spear"] = "晶化的阿拉索之矛"
L["Irradiated Arathor's Spear"] = "辐能的阿拉索之矛"
L["Lush Arathor's Spear"] = "繁茂的阿拉索之矛"
L["Sporefused Arathor's Spear"] = "注孢的阿拉索之矛"
L["Blessing Blossom"] = "圣祝棠"
L["Crystallized Blessing Blossom"] = "晶化的圣祝棠"
L["Irradiated Blessing Blossom"] = "辐能的圣祝棠"
L["Lush Blessing Blossom"] = "繁茂的圣祝棠"
L["Sporefused Blessing Blossom"] = "注孢的圣祝棠"
L["Orbinid"] = "球首兰"
L["Altered Orbinid"] = "异变的球首兰"
L["Crystallized Orbinid"] = "晶化的球首兰"
L["Irradiated Orbinid"] = "辐能的球首兰"
L["Lush Orbinid"] = "繁茂的球首兰"
L["Sporefused Orbinid"] = "注孢的球首兰"

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
L["Copper Vein"] = "铜矿"
L["Tin Vein"] = "锡矿"
L["Silver Vein"] = "银矿"
L["Incendicite Mineral Vein"] = "火岩矿脉"
L["Lesser Bloodstone Deposit"] = "次级血石矿脉"
L["Iron Deposit"] = "铁矿石"
L["Indurium Mineral Vein"] = "精铁矿脉"
L["Gold Vein"] = "金矿石"
L["Mithril Deposit"] = "秘银矿脉"
L["Truesilver Deposit"] = "真银矿石"
L["Dark Iron Deposit"] = "黑铁矿脉"
L["Small Thorium Vein"] = "瑟银矿脉"
L["Thorium Vein"] = "瑟银矿脉"
L["Rich Thorium Vein"] = "富瑟银矿"
L["Small Obsidian Chunk"] = "小型黑曜石碎块"
L["Large Obsidian Chunk"] = "大型黑曜石碎块"

-- Mines - TBC
L["Fel Iron Deposit"] = "魔铁矿脉"
L["Adamantite Deposit"] = "精金矿脉"
L["Rich Adamantite Deposit"] = "富精金矿脉"
L["Khorium Vein"] = "氪金矿脉"
L["Nethercite Deposit"] = "虚空矿脉"
L["Ancient Gem Vein"] = "上古宝石矿脉"

-- Mines - WotLK
L["Cobalt Deposit"] = "钴矿脉"
L["Rich Cobalt Deposit"] = "富钴矿脉"
L["Saronite Deposit"] = "萨隆邪铁矿脉"
L["Rich Saronite Deposit"] = "富萨隆邪铁矿脉"
L["Titanium Vein"] = "泰坦神铁矿脉"

-- Mines - Cataclysm
L["Obsidium Deposit"] = "黑曜石碎块"
L["Rich Obsidium Deposit"] = "巨型黑曜石石板"
L["Elementium Vein"] = "源质矿"
L["Rich Elementium Vein"] = "富源质矿"
L["Pyrite Deposit"] = "燃铁矿脉"
L["Rich Pyrite Deposit"] = "富燃铁矿脉"

-- Mines - MoP
L["Ghost Iron Deposit"] = "幽冥铁矿脉"
L["Rich Ghost Iron Deposit"] = "富幽冥铁矿脉"
L["Kyparite Deposit"] = "凯帕琥珀矿脉"
L["Rich Kyparite Deposit"] = "富凯帕琥珀矿脉"
L["Trillium Vein"] = "延极矿脉"
L["Rich Trillium Vein"] = "富延极矿脉"

-- Mines - WoD
L["True Iron Deposit"] = "真铁矿脉"
L["Rich True Iron Deposit"] = "富真铁矿脉"
L["Smoldering True Iron Deposit"] = "阴燃真铁矿脉"
L["Blackrock Deposit"] = "黑石矿脉"
L["Rich Blackrock Deposit"] = "富黑石矿脉"

-- Mines - Legion
L["Leystone Deposit"] = "魔石矿脉"
L["Leystone Seam"] = "魔石矿层"
L["Living Leystone"] = "活性魔石"
L["Felslate Deposit"] = "邪能页岩矿脉"
L["Felslate Seam"] = "邪能页岩矿层"
L["Living Felslate"] = "活性邪能页岩"
L["Empyrium Deposit"] = "天界金矿脉"
L["Rich Empyrium Deposit"] = "富天界金矿脉"
L["Empyrium Seam"] = "天界金矿层"

-- Mines - BfA
L["Monelite Deposit"] = "镍铜矿脉"
L["Rich Monelite Deposit"] = "富镍铜矿脉"
L["Monelite Seam"] = "镍铜矿层"
L["Platinum Deposit"] = "白金矿脉"
L["Rich Platinum Deposit"] = "富白金矿脉"
L["Storm Silver Deposit"] = "雷银矿脉"
L["Rich Storm Silver Deposit"] = "富雷银矿脉"
L["Storm Silver Seam"] = "雷银矿层"

-- Mines - Shadowlands
L["Laestrite Deposit"] = "苷铜矿脉"
L["Rich Laestrite Deposit"] = "富苷铜矿脉"
L["Elethium Deposit"] = "阴铁矿脉"
L["Rich Elethium Deposit"] = "富阴铁矿脉"
L["Solenium Deposit"] = "珀银矿脉"
L["Rich Solenium Deposit"] = "富珀银矿脉"
L["Oxxein Deposit"] = "髓硫矿脉"
L["Rich Oxxein Deposit"] = "富髓硫矿脉"
L["Phaedrum Deposit"] = "炽钴矿脉"
L["Rich Phaedrum Deposit"] = "富炽钴矿脉"
L["Sinvyr Deposit"] = "罪钒矿脉"
L["Rich Sinvyr Deposit"] = "富罪钒矿"

-- Mines - Dragonflight
L["Serevite Deposit"] = "宁铁矿脉"
L["Hardened Serevite Deposit"] = "硬化的宁铁矿脉"
L["Infurious Serevite Deposit"] = "震怒宁铁矿脉"
L["Molten Serevite Deposit"] = "熔火宁铁矿脉"
L["Primal Serevite Deposit"] = "原始宁铁矿脉"
L["Rich Serevite Deposit"] = "富宁铁矿脉"
L["Titan-Touched Serevite Deposit"] = "泰坦点化的宁铁矿脉"
L["Draconium Deposit"] = "龙银矿脉"
L["Hardened Draconium Deposit"] = "硬化龙银矿脉"
L["Infurious Draconium Deposit"] = "震怒龙银矿脉"
L["Molten Draconium Deposit"] = "熔火龙银矿脉"
L["Primal Draconium Deposit"] = "原始龙银矿脉"
L["Rich Draconium Deposit"] = "富龙银矿脉"
L["Titan-Touched Draconium Deposit"] = "泰坦点化的龙银矿脉"

-- Mines - The War Within
L["Bismuth"] = "铋矿"
L["Crystallized Bismuth"] = "晶化的铋矿"
L["EZ-Mine Bismuth"] = "\"易采\"铋矿"
L["Rich Bismuth"] = "富铋矿"
L["Weeping Bismuth"] = "低泣的铋矿"
L["Ironclaw"] = "镔爪矿"
L["Crystallized Ironclaw"] = "晶化的镔爪矿"
L["EZ-Mine Ironclaw"] = "\"易采\"镔爪矿"
L["Rich Ironclaw"] = "富镔爪矿"
L["Weeping Ironclaw"] = "低泣的镔爪矿"
L["Aqirite"] = "亚基矿"
L["Crystallized Aqirite"] = "晶化的亚基矿"
L["EZ-Mine Aqirite"] = "\"易采\"亚基矿"
L["Rich Aqirite"] = "富亚基矿"
L["Weeping Aqirite"] = "低泣的亚基矿"
L["Webbed Ore Deposit"] = "缠网矿脉"

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

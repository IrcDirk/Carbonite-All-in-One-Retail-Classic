local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Warehouse", "zhCN")
if not L then return end

L["ItemTypes"] = {
	ARMOR,
	"消耗品",
	"容器",
	"宝石",
	"雕文",
	"钥匙",
	"其他",
	"弹药",
	"任务",
	"箭袋",
	"施法材料",
	"配方",
	AUCTION_CATEGORY_TRADE_GOODS,
	"商品",
	"武器",
}

L["-Warehouse-"] = "-仓库-"
L["Warehouse Module"] = "仓库模块"
L["Warehouse Options"] = "仓库模块设置"
L["Add Warehouse Tooltip"] = "添加仓库鼠标提示"
L["When enabled, will show warehouse information in hover tooltips of items"] = "勾选时，在鼠标提示中显示仓库物品数量信息"
L["Warehouse Font"] = "仓库字体"
L["Sets the font to be used for warehouse windows"] = "设置仓库窗口的字体"
L["Warehouse Font Size"] = "仓库字体大小"
L["Sets the size of the warehouse font"] = "设置仓库窗口字体大小"
L["Warehouse Font Spacing"] = "仓库字体间距"
L["Sets the spacing of the warehouse font"] = "设置仓库窗口字体间距"
L["Toggle Warehouse"] = "切换仓库"
L["Remove Character or Guild"] = "移除角色或公会"
L["Import settings from selected character"] = "从选定角色导入信息"
L["Export current settings to all characters"] = "将当前设置导出到所有角色"
L["Sync account transfer file"] = "账号同步文件"
L["Show Lowest Equipped Rarity"] = "显示的最低装备物品稀有度"
L["Show Item Headers"] = "显示物品分类标题"
L["Sort By Rarity"] = "按稀有度排序"
L["Show Lowest Rarity"] = "显示的最低物品稀有度"
L["Sort By Slot"] = "按装备栏位排序"
L["Import %s's character data and reload?"] = "导入 %s 的角色数据并重载界面？"
L["Overwrite all character settings and reload?"] = "覆盖所有角色设置并重载？"
L["Warehouse: %d characters"] = "仓库: 共 %d 个角色"
L["DurPattern"] = "^耐久度 (%d+) / (%d+)"
L["Show Warehouse"] = "显示仓库"

L["Import"] = "导入"
L["Cancel"] = "取消"
L["Export"] = "导出"
L["Warehouse"] = "仓库"
L[" Realm:%s %s"] = " 服务器:%s %s"
L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"] = " 当前登录时长: %s%2d:%02d:%02d|r, 游戏时长: %s%s"
L[" Session Money:%s %s|r, Per Hour:%s %s"] = "收入：%s %s|r, 小时收入：%s %s"
L[" Durability: %s%d%%, lowest %d%%"] = "耐久度: %s%d%%, 最低 %d%%"
L[" Session XP:%s %s|r, Per Hour:%s %.0f"] = "经验获得:%s %s|r, 每小时:%s %.0f"
L[" Hours To Level: %s%.1f"] = "预计升级时间: %s%.1f"
L[" Last On: %s%s|r, Played: %s%s"] = "上次登录: %s%s|r, 游戏时长: %s%s"
L[" Location: %s%s (%d, %d)"] = "位置: %s%s (%d, %d)"
L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = "初始经验: %s%s/%s (%.0f%%)|r 双倍: %s%.0f%%"
L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = "经验: %s%s/%s (%.0f%%)|r 双倍: %s%.0f%%"
L[" Honor: %s%s|r  Conquest: %s%s"] = "荣誉: %s%s|r  征服: %s%s"
L[" Valor: %s%s|r  Justice: %s%s"] = "勇气: %s%s|r  正义: %s%s" -- Does not exist anymore in WoD
--L[" %s %s%s"] = ""
L["|cffafdfafAll: %s. |cffafdfafPlayed: %s%s"] = "|cffafdfaf总计: %s. |cffafdfaf游戏: %s%s"
L["%s's Items"] = "%s的物品"
L["|cffff1010No bank data - visit your bank"] = "|cffff1010无银行信息 - 去访问一次银行"
L["|cffff1010No reagent bank data - visit your bank"] = "|cffff1010无材料银行信息 - 去访问一次银行"
L["---- Equipped ----"] = "---- 已装备 ----"
L["Slot"] = "栏位"
L["---- %s Equipped ----"] = "---- %s 已装备 ----"
L["All Items"] = "所有物品"
L["%s |cffcfcfff(%s Bank)"] = "%s |cffcfcfff(银行:%s)"
L["%s |cffcfffff(%s Mail)"] = "%s |cffcfffff(邮箱:%s)"
L["%s %d (%d Worn)"] = "%s %d (装备:%d)"
L["%s (%d Bank)"] = "%s (银行:%d)"
L["%s (%d RBank)"] = "%s (材料:%d)"
L["%s (%s Mail)"] = "%s (邮箱:%s)"
L["%s (%s Pets)"] = true
L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00背包:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00装备:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00邮箱:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00银行:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00材料:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"] = true
L["%s's %s Skills"] = "%s的 %s 技能"
L["|cffff1010No data - open %s window"] = "|cffff1010无数据 - 打开 %s 窗口"
L["|cffffffffW%sarehouse:"] = "|cffffffff仓%s库:"
L["LOOT_OPENED %s (%s %s)"] = true
L["no LootTarget"] = "无拾取对象"
L["LOOT_SLOT_CLEARED #%s %s (quest)"] = "LOOT_SLOT_CLEARED #%s %s (任务)"
L["%s deleted"] = "%s 已删除"
L["enchant:(%d+)"] = "附魔:(%d+)"
L["item:(%d+)"] = "物品:(%d+)"

-- Keybinds
L["Carbonite Warehouse"] = "Carbonite 仓库模块"
L["NxTOGGLEWAREHOUSE"] = "显示/隐藏仓库窗口"

L["Guilds"] = "公会"
L["Characters"] = "角色"
L["Guild Bank"] = "公会银行"
L["Current Funds"] = "当前货币"
L["Last Updated"] = "上次更新"
L["Tab is empty or no access"] = "此银行标签无物品或无权限"
L["ago"] = "之前"
L["not opened or scanned."] = "未打开或扫描过。"
L["Tab"] = "标签"
L["All Characters"] = "所有角色"
L["AUTO-REPAIR"] = "自动修理"
L["Auto Repair"] = "自动修理"
L["GUILD WITHDRAW"] = "公会提取"
L["Not enough funds to repair."] = "没有足够的金钱进行修理。"
L["Auto Repair Gear"] = "自动修理装备"
L["When you open a merchant, will attempt to auto repair your gear"] = "当你访问商人时，尝试自动修理你的装备"
L["Use Guild Repair First"] = "优先使用公会修理"
L["Will try to use guild funds to pay for repairs before your own"] = "优先使用公会修理额度"

L["Verbose Selling"] = "详细售卖信息"
L["When enabled shows what items got sold instead of just the grand total earned."] = "启用时，除了获得总钱数之外，也会显示哪些物品被出售。"
L["Test Selling"] = "测试自动售卖"
L["Enabling this allows you to see what would get sold, without actually selling."] = "启用时，将会显示哪些物品会被出售，但并不实际出售"
L["Warehouse"] = "仓库"
L["Auto Sell"] = "自动售卖"
L["Items"] = "物品"
L["Grey"] = "灰色"
L["White"] = "白色"
L["Green"] = "绿色"
L["Blue"] = "蓝色"
L["Purple"] = "紫色"
L["Selling"] = "出售"
L["When you open a merchant, will auto sell your grey items"] = "当你访问商人时，会自动出售你包里的灰色物品"
L["When you open a merchant, will auto sell your white items."] = "当你访问商人时，会自动出售你包里的白色物品"
L["When you open a merchant, will auto sell your green items."] = "当你访问商人时，会自动出售你包里的绿色物品"
L["When you open a merchant, will auto sell your blue items."] = "当你访问商人时，会自动出售你包里的蓝色物品"
L["When you open a merchant, will auto sell your purple items."] = "当你访问商人时，会自动出售你包里的紫色物品"
L["iLevel"] = "物品等级"
L["Enable iLevel Limit"] = "开启出售物品等级限制"
L["Only sells items that are under the ilvl specified"] = "只出售低于此物品等级的物品"
L["Sets the maximum item level which will be auto sold"] = "设置可自动出售的最高物品等级"
L["Sell BOP Items"] = "出售拾取绑定物品"
L["When enabled will sell items that are BOP"] = "启用时将允许出售拾取绑定物品"
L["Sell BOE Items"] = "出售装备绑定物品"
L["When enabled will sell items that are BOE"] = "启用时将允许出售装备绑定物品"
L["Sell items based on a list"] = "根据列表出售物品"
L["If item name matches one on the list, auto-sell it"] = "如果物品名字与列表上的一致，则自动出售"
L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."] = "输入你想要自动出售的物品名称。你也可以直接把物品拖过来。"
L["New Item To Sell (Case Insensative)"] = "自动出售新物品列表"
L["AUTO-SELL: You Earned"] = "自动出售：你赚得"
L["Delete Item"] = "删除列表上的物品"
L["Delete"] = "删除"
L["Yes"] = "是"
L["No"] = "否"

L["Show coin count in warehouse list"] = "在仓库角色列表中显示金钱数量"
L["Restores the coin totals after character names in warehouse listing"] = "启用后，将在仓库角色名字之后显示该角色金钱数量"

L["Use don't display list"] = "使用物品显示黑名单"
L["If enabled, don't show listed items in tooltips"] = "开启后，黑名单中的物品将不会出现在鼠标提示中"
L["New Item To Ignore (Case Insensative)"] = "将物品添加至黑名单"
L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."] = "输入你不想在鼠标提示中追踪的物品名。你也可以从背包里把物品拖放到这里。"
L["Ignore"] = "忽略"

-- Font outline/shadow options
L["Font Outline"] = "字体描边"
L["Font Shadow"] = "字体阴影"
L["Sets the outline style of this font"] = "设置该字体的描边样式"
L["Adds a drop shadow to this font"] = "为该字体添加阴影"
L["None"] = "无"
L["Outline"] = "描边"
L["Thick Outline"] = "粗描边"

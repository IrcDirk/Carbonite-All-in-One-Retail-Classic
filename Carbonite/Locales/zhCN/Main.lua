if ( GetLocale() ~= "zhCN" ) then
	return
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "zhCN")
if not L then return end

NXClassLocToCap = {		-- Convert localized class name to generic caps
	["死亡骑士"] = "DEATHKNIGHT",
	["德鲁伊"] = "DRUID",
	["猎人"] = "HUNTER",
	["法师"] = "MAGE",
	["武僧"] = "MONK",
	["圣骑士"] = "PALADIN",
	["牧师"] = "PRIEST",
	["潜行者"] = "ROGUE",
	["萨满祭司"] = "SHAMAN",
	["术士"] = "WARLOCK",
	["战士"] = "WARRIOR",
}

-- Main Carbonite
L["Carbonite"] = true
L["CARBONITE"] = true
L["Loading"] = "载入中"
L["Loading Done"] = "载入完成"
L["None"] = true
L["Goto"] = "前往"
L["Show Player Zone"] = "显示玩家区域"
L["Menu"] = "菜单"
L["Show Selected Zone"] = "显示选择区域"
L["Add Note"] = "添加标记"
L["TopRight"] = true
L["Help"] = "帮助"
L["Options"] = "选项"
L["Toggle Map"] = "切换地图显示"
L["Toggle Combat Graph"] = "切换战斗图表"
L["Toggle Events"] = "切换事件窗口"
L["Left-Click to Toggle Map"] = "左键切换地图显示"
L["Shift Left-Click to Toggle Minimize"] = "Shift-左键最小化/还原"
L["Middle-Click to Toggle Guide"] = "中键切换百科指南窗口"
L["Right-Click for Menu"] = "右键显示菜单"
L["Carbonite requires v5.0 or higher"] = "需要v5.0或更高版本的Carbonite"
L["GUID player"] = "玩家GUID"
L["GUID NPC"] = true
L["GUID pet"] = "宠物GUID"
L["Unit map error"] = "单位地图错误"
L["Gather"] = "采集"
L["Entered"] = "进入"
L["Level"] = "等级"
L["Deaths"] = "死亡"
L["Bonus"] = "奖励"
L["Reset old data"] = "重置旧数据"
L["Reset old global options"] = "重置旧全局设置"
L["Options have been reset for the new version."] = "已为新版本重设设置。"
L["Privacy or other settings may have changed."] = "隐私或其它选项可能已发生变化。"
L["Cleaned"] = "清理"
L["items"] = "条目"
L["Reset old HUD options"] = "重置旧HUD设置"
L["Reset old travel data"] = "重置旧旅行数据"
L["Reset old gather data"] = "重置旧采集数据"
L["Missing character data!"] = "角色数据丢失！"
L["Deathknight"] = "死亡骑士"
L["Death Knight"] = "死亡骑士"
L["Version"] = "版本"
L["Maintained by"] = "维护:"
L["crit"] = "暴击"
L["hit"] = "击中"
L["Killed"] = "杀死"
L["honor"] = "荣誉"
L["Hit"] = "击中"
L["Peak"] = "峰值"
L["Best"] = "最佳"
L["Total"] = "总计"
L["Time"] = "时间"
L["Event"] = "事件"
L["Events"] = "事件"
L["Position"] = "位置"
L["Died"] = "死亡"
L["Picked"] = "拾取"
L["Mined"] = "采矿"
L["Fished"] = "钓鱼"
L["Unknown herb"] = "未知草药"
L["Unknown ore"] = "未知矿点"
L["Gathermate2_Data_Carbonite addon is not loaded!"] = "Gathermate2_Data_Carbonite没有载入！"
L["Imported"] = "导入"
L["nodes from GatherMate2_Data"] = "节点，从GatherMate2_Data中。"
L["Delete visited vendor data?"] = "删除已访问的商人数据？"
L["This will stop the attempted retrieval of items on login."] = "这会停止在角色登录时的数据获取。"
L["Delete"] = "删除"
L["Cancel"] = "取消"
L["items retrieved"] = "数据已取回"
L["Item retrieval from server complete"] = "完成从服务器取得数据"
L["Show Map"] = "显示地图"
L["Show Combat Graph"] = "显示战斗图表"
L["Show Events"] = "显示事件窗口"
L["Show Auction Buyout Per Item"] = "显示物品一口价"
L["Show Com Window"] = "显示通讯窗口"
L["Toggle Profiling"] = "切换Profiling"
L["Left click toggle Map"] = "左键切换地图显示"
L["Shift left click toggle minimize"] = "Shift左键最小化/还原"
L["Alt left click toggle Watch List"] = "Alt左键切换监视列表"
L["Middle click toggle Guide"] = "中间切换百科指南"
L["Right click for Menu"] = "右键显示菜单"
L["Shift drag to move"] = "按住Shift拖动"
L["Hide In Combat"] = "战斗中隐藏"
L["Lock"] = "锁定"
L["Fade In"] = "淡入"
L["Fade Out"] = "淡出"
L["Layer"] = "层次"
L["Scale"] = "缩放"
L["Transparency"] = "透明度"
L["Reset Layout"] = "重设布局"

-- UI Tooltips
L["Close/Menu"] = "关闭/菜单"
L["Close/Unlock"] = "关闭/解锁"
L["Pick Color"] = "选取颜色"
L["Unlock"] = "解锁"
L["Maximize"] = "最大化"
L["Restore"] = "恢复"
L["Minimize"] = "最小化"
L["Auto Scale"] = "自动缩放"

-- Stuff from old localization
L["Searching for Artifacts"] = "寻找考古点"		-- NXlARTIFACTS
L["Extract Gas"] = "精炼气体"				-- NXlEXTRACTGAS
L["Herb Gathering"] = "草药采集"			-- NXlHERBGATHERING
L["In Conflict"] = "争夺中"				-- NXlINCONFLICT
L["Opening"] = "打开"					-- NXlOpening
L["Opening - No Text"] = true				-- NXlOpeningNoText
L["Everfrost Chip"] = "永冻薄片"			-- NXlEverfrost

L["yds"] = "码"
L["secs"] = "秒"
L["mins"] = "分钟"

-- NxUI.lua
L[" Frame: %s Shown%d Vis%d P>%s"] = true
L[" EScale %f, Lvl %f"] = true
L[" LR %f, %f"] = true
L[" BT %f, %f"] = true
L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"] = true
L["%.1f days"] = "%.1f 天"
L["%.1f hours"] = "%.1f 小时"
L["%d mins"] = "%d 分钟"
L["Reset old layout data"] = "重置旧布局数据"
L["Window version mismatch!"] = "窗口版本错误！"
L["XY missing (%s)"] = "丢失XY坐标(%s)"
L["Window not found (%s)"] = "未找到窗口(%s)"
L["Detach %s"] = "分离 %s"
L["Detach found %s"] = "找到待分离窗口 %s"
L["Search: [click]"] = "搜索：[点击此处]"
L["Search: %[click%]"] = "搜索：%[点击此处%]"
L["Reset old list data"] = "重置旧列表数据"
L["!BUT %s"] = true
L["Key %s transfered to Watch List Item"] = "键 %s 已转移到监视列表"
L["CLICK (.+):"] = true
L["Key %s %s #%s %s"] = "键 %s %s #%s %s"
L["shift left/right click to change size"] = "Shift-左键或右键点击改变大小"
L["Reset old tool bar data"] = "重置旧工具栏数据"
L["|cffffff00%dg"] = true
L["%s |cffbfbfbf%ds"] = true
L["%s |cff7f7f00%dc"] = true

-- NxTravel.lua
L["Connection: %s to %s"] = "连接：%s 到 %s"
L["Fly: %s to %s"] = "飞行：%s 到 %s"

-- NxHud.lua
L[" %.1f deg"] = true
L[" %d deg"] = true
L["Remove Current Point"] = true
L["Remove All Points"] = true

-- Carbonite.Info kill-marker tooltip
L["kill"] = "击杀"
L["death"] = "死亡"
L["kills: %s"] = "击杀: %s"
L["NPC ID: %s"] = "NPC ID: %s"

-- AddonButtons toolbar tooltips (Questie / HandyNotes / RareScanner)
L["Left click"] = "左键点击"
L["Right click"] = "右键点击"
L["Toggle icons"] = "切换图标"
L["Context menu"] = "右键菜单"
L["Open settings"] = "打开设置"

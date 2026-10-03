if ( GetLocale() ~= "zhTW" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "zhTW")
if not L then return end

NXClassLocToCap = {		-- Convert localized class name to generic caps
	["死亡騎士"] = "DEATHKNIGHT",
	["德魯伊"] = "DRUID",
	["獵人"] = "HUNTER",
	["法師"] = "MAGE",
--	["??"] = "MONK",
	["聖騎士"] = "PALADIN",
	["牧師"] = "PRIEST",
	["盜賊"] = "ROGUE",
	["薩滿"] = "SHAMAN",
	["術士"] = "WARLOCK",
	["戰士"] = "WARRIOR",
}

-- Main Carbonite
L["Carbonite"] = "Carbonite"
L["CARBONITE"] = "CARBONITE"
L["Loading"] = "載入中"
L["Loading Done"] = "已載入"
L["None"] = true
L["Goto"] = true
L["Show Player Zone"] = true
L["Menu"] = true
L["Show Selected Zone"] = true
L["Add Note"] = "新增註記"
L["TopRight"] = "右上"
L["Help"] = true
L["Options"] = "選項"
L["Toggle Map"] = "切換地圖"
L["Toggle Combat Graph"] = "切換戰鬥圖表"
L["Toggle Events"] = "切換事件視窗"
L["Left-Click to Toggle Map"] = "左鍵點擊切換地圖"
L["Shift Left-Click to Toggle Minimize"] = "Shift-左鍵點擊切換最小化"
L["Middle-Click to Toggle Guide"] = "中鍵點擊切換百科指南"
L["Right-Click for Menu"] = "右鍵點擊開啟選單"
L["Carbonite requires v5.0 or higher"] = "Carbonite 需要 v5.0 或更高版本"
L["GUID player"] = "玩家 GUID"
L["GUID NPC"] = "NPC GUID"
L["GUID pet"] = "寵物 GUID"
L["Unit map error"] = "單位地圖錯誤"
L["Gather"] = "採集"
L["Entered"] = "進入"
L["Level"] = "等級"
L["Deaths"] = "死亡次數"
L["Bonus"] = "獎勵"
L["Reset old data"] = "重設舊資料"
L["Reset old global options"] = "重設舊的全域選項"
L["Options have been reset for the new version."] = "已為新版本重設選項。"
L["Privacy or other settings may have changed."] = "隱私或其他設定可能已變更。"
L["Cleaned"] = "已清理"
L["items"] = "物品"
L["Reset old HUD options"] = "重設舊的 HUD 選項"
L["Reset old travel data"] = "重設舊的旅行資料"
L["Reset old gather data"] = "重設舊的採集資料"
L["Missing character data!"] = "角色資料遺失！"
L["Deathknight"] = "死亡騎士"
L["Death Knight"] = "死亡騎士"
L["Version"] = "版本"
L["Maintained by"] = true
L["crit"] = "致命一擊"
L["hit"] = "命中"
L["Killed"] = "擊殺"
L["honor"] = "榮譽"
L["Hit"] = "命中"
L["Peak"] = "峰值"
L["Best"] = "最佳"
L["Total"] = "總計"
L["Time"] = "時間"
L["Event"] = "事件"
L["Events"] = true
L["Position"] = "位置"
L["Died"] = "死亡"
L["Picked"] = "已採草"
L["Mined"] = "已採礦"
L["Fished"] = "已釣魚"
L["Unknown herb"] = "未知草藥"
L["Unknown ore"] = "未知礦物"
L["Gathermate2_Data_Carbonite addon is not loaded!"] = "Gathermate2_Data_Carbonite 插件未載入！"
L["Imported"] = "已匯入"
L["nodes from GatherMate2_Data"] = "個採集點，來自 GatherMate2_Data"
L["Delete visited vendor data?"] = "刪除已訪問的商人資料？"
L["This will stop the attempted retrieval of items on login."] = "這將停止登入時嘗試取得物品資料。"
L["Delete"] = true
L["Cancel"] = true
L["items retrieved"] = "件物品已取得"
L["Item retrieval from server complete"] = "已完成從伺服器取得物品資料"
L["Show Map"] = "顯示地圖"
L["Show Combat Graph"] = "顯示戰鬥圖表"
L["Show Events"] = "顯示事件視窗"
L["Show Auction Buyout Per Item"] = "顯示拍賣單件直購價"
L["Show Com Window"] = "顯示通訊視窗"
L["Toggle Profiling"] = "切換效能分析"
L["Left click toggle Map"] = "左鍵點擊切換地圖"
L["Shift left click toggle minimize"] = "Shift-左鍵點擊切換最小化"
L["Alt left click toggle Watch List"] = "Alt-左鍵點擊切換監視清單"
L["Middle click toggle Guide"] = "中鍵點擊切換百科指南"
L["Right click for Menu"] = "右鍵點擊開啟選單"
L["Shift drag to move"] = "Shift-拖曳以移動"
L["Hide In Combat"] = "戰鬥中隱藏"
L["Lock"] = "鎖定"
L["Layer"] = "層級"
L["Scale"] = true
L["Transparency"] = true
L["Reset Layout"] = "重設版面配置"

-- UI Tooltips
L["Close/Menu"] = "關閉/選單"
L["Close/Unlock"] = "關閉/解鎖"
L["Pick Color"] = "選取顏色"
L["Unlock"] = "解鎖"
L["Maximize"] = "最大化"
L["Restore"] = "還原"
L["Minimize"] = "最小化"
L["Auto Scale"] = "自動縮放"

-- Stuff from old localization
L["Searching for Artifacts"] = "搜尋文物"
L["Extract Gas"] = "氣體微粒"				-- NXlEXTRACTGAS
L["Herb Gathering"] = "草點"				-- NXlHERBGATHERING
L["In Conflict"] = "戰鬥中"				-- NXlINCONFLICT
L["Opening"] = "開啟"					-- NXlOpening
L["Opening - No Text"] = "開啟 - 無文字"		-- NXlOpeningNoText
L["Everfrost Chip"] = "永霜屑片"			-- NXlEverfrost

L["yds"] = "碼"
L["secs"] = "秒"
L["mins"] = "分鍾"

-- NxUI.lua
L[" Frame: %s Shown%d Vis%d P>%s"] = " 框架：%s 顯示%d 可見%d 父>%s"
L[" EScale %f, Lvl %f"] = " 有效縮放 %f，層級 %f"
L[" LR %f, %f"] = " 左右 %f, %f"
L[" BT %f, %f"] = " 下上 %f, %f"
L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"] = "%s#%d %s ID%s (%s) 顯示%d l%d x%d y%d"
L["%.1f days"] = "%.1f 天"
L["%.1f hours"] = "%.1f 小時"
L["%d mins"] = "%d 分鐘"
L["Reset old layout data"] = "重設舊的版面配置資料"
L["Window version mismatch!"] = "視窗版本不符！"
L["XY missing (%s)"] = "缺少 XY 座標 (%s)"
L["Window not found (%s)"] = "找不到視窗 (%s)"
L["Detach %s"] = "分離 %s"
L["Detach found %s"] = "找到待分離視窗 %s"
L["Search: [click]"] = "搜尋：[點擊]"
L["Search: %[click%]"] = "搜尋：%[點擊%]"
L["Reset old list data"] = "重設舊的清單資料"
L["!BUT %s"] = "!BUT %s"
L["Key %s transfered to Watch List Item"] = "按鍵 %s 已轉移到監視清單物品"
L["CLICK (.+):"] = true
L["Key %s %s #%s %s"] = "按鍵 %s %s #%s %s"
L["shift left/right click to change size"] = "Shift-左鍵/右鍵點擊以變更大小"
L["Reset old tool bar data"] = "重設舊的工具列資料"
L["|cffffff00%dg"] = "|cffffff00%dg"
L["%s |cffbfbfbf%ds"] = "%s |cffbfbfbf%ds"
L["%s |cff7f7f00%dc"] = "%s |cff7f7f00%dc"

-- NxTravel.lua
L["Connection: %s to %s"] = "連接：%s 到 %s"
L["Fly: %s to %s"] = "飛行：%s 到 %s"

-- NxHud.lua
L[" %.1f deg"] = " %.1f 度"
L[" %d deg"] = " %d 度"
L["Remove Current Point"] = "移除目前的點"
L["Remove All Points"] = "移除所有的點"

-- Carbonite.Info kill-marker tooltip
L["kill"] = "擊殺"
L["death"] = "死亡"
L["kills: %s"] = "擊殺: %s"
L["NPC ID: %s"] = "NPC ID: %s"

-- AddonButtons toolbar tooltips (Questie / HandyNotes / RareScanner)
L["Left click"] = "左鍵點擊"
L["Right click"] = "右鍵點擊"
L["Toggle icons"] = "切換圖示"
L["Context menu"] = "右鍵選單"
L["Open settings"] = "開啟設定"
L["Whats New!"] = "新功能！"
L["Don't show for this update again"] = "此次更新不再顯示"
L["Carbonite What's New"] = "Carbonite 新功能"
L["Carbonite.Gathermate2_Data addon is not loaded!"] = "Carbonite.Gathermate2_Data 插件未載入！"
L["nodes from Carbonite.Gathermate2_Data"] = "個採集點，來自 Carbonite.Gathermate2_Data"
L["Health"] = "生命值"

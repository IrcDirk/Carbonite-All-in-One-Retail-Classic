if ( GetLocale() ~= "zhTW" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "zhTW")
if not L then return end

L["Info Options"] = "資訊選項"
L["Lock Info Windows"] = "鎖定資訊視窗"
L["Locks the location of your info windows"] = "鎖定資訊視窗的位置"
L["Info Window Background Color"] = "資訊視窗背景顏色"
L["Info Font"] = "資訊字型"
L["Sets the font to be used for info windows"] = "設定資訊視窗使用的字型"
L["Info Font Size"] = "資訊字型大小"
L["Sets the size of the info font"] = "設定資訊字型的大小"
L["Info Font Spacing"] = "資訊字型間距"
L["Sets the spacing of the info font"] = "設定資訊字型的間距"
L["Show Info Windows"] = "顯示資訊視窗"
L["Toggle Info Windows"] = "切換資訊視窗"
L["Info Module"] = "資訊模組"
L["Close"] = "關閉"
L["Edit Item"] = "編輯項目"
L["Show"] = "顯示"
L["New Info Window"] = "新資訊視窗"
L["Delete This Window"] = "刪除此視窗"
L["Options"] = "選項"
L["Info"] = true
L["Edit View"] = "編輯檢視"
L["Stop Edit"] = "停止編輯"
L["Change Text"] = "變更文字"
L["Delete Info Window"] = "刪除資訊視窗"
L["Delete"] = "刪除"
L["Cancel"] = "取消"

L["One minute until the Arena"] = "一分鐘"
L["Thirty seconds until the Arena"] = "三十秒"
L["Fifteen seconds until the Arena"] = "十五秒"

L["Reset old info data %f"] = "重置舊資訊資料 %f"
L[" begins? in (%d+) "] = "(%d+)秒"
L["(%d+) minutes? until the battle"] = "(%d+)分鐘"
L["Info"] = true
L["Info"] = "資訊"
-- Kill marker icons (Carbonite map skull/seal markers)
L["Kill Icons"] = "擊殺圖示"
L["Show kill markers on map"] = "在地圖上顯示擊殺標記"
L["When enabled, killed mobs leave a skull icon on your map at the kill location"] = "啟用後，被擊殺的怪物會在擊殺位置留下骷髏圖示"
L["Auto-clear kill markers after"] = "自動清除擊殺標記的延遲"
L["Seconds before a kill marker disappears automatically. 0 = never (manual clear only)"] = "擊殺標記自動消失前的秒數。0 = 永不（僅手動清除）"

L["Keep kill history"] = "永久保留擊殺歷史"
L["When enabled, the auto-clear timer only hides expired markers but keeps the kill records in saved variables. Useful as a permanent kill log."] = "啟用後，自動清除計時器僅隱藏過期標記，但保留擊殺記錄。可用作永久擊殺日誌。"

-- Font outline/shadow options
L["Font Outline"] = "字型描邊"
L["Font Shadow"] = "字型陰影"
L["Sets the outline style of this font"] = "設定此字型的描邊樣式"
L["Adds a drop shadow to this font"] = "為此字型加入陰影"
L["None"] = "無"
L["Outline"] = "描邊"
L["Thick Outline"] = "粗描邊"
L["Best"] = "最佳"
L["Hit"] = "命中"
L["Killed"] = "擊殺"
L["Peak"] = "峰值"
L["Show Combat Graph"] = "顯示戰鬥圖表"
L["Time"] = "時間"
L["Toggle Combat Graph"] = "切換戰鬥圖表"
L["Total"] = "總計"
L["crit"] = "致命一擊"
L["hit"] = "命中"
L["honor"] = "榮譽"

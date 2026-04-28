if ( GetLocale() ~= "zhTW" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "zhTW")
if not L then return end

L["Info Options"] = true
L["Lock Info Windows"] = true
L["Locks the location of your info windows"] = true
L["Info Window Background Color"] = true
L["Info Font"] = true
L["Sets the font to be used for info windows"] = true
L["Info Font Size"] = true
L["Sets the size of the info font"] = true
L["Info Font Spacing"] = true
L["Sets the spacing of the info font"] = true
L["Show Info Windows"] = true
L["Toggle Info Windows"] = true
L["Info Module"] = true
L["Close"] = true
L["Edit Item"] = true
L["Show"] = true
L["New Info Window"] = true
L["Delete This Window"] = true
L["Options"] = true
L["Info"] = true
L["Edit View"] = true
L["Stop Edit"] = true
L["Change Text"] = true
L["Delete Info Window"] = true
L["Delete"] = true
L["Cancel"] = true

L["One minute until the Arena"] = true
L["Thirty seconds until the Arena"] = true
L["Fifteen seconds until the Arena"] = true

L["Reset old info data %f"] = true
L[" begins? in (%d+) "] = true
L["(%d+) minutes? until the battle"] = true
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

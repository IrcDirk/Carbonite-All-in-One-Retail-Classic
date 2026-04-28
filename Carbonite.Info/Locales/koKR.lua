if ( GetLocale() ~= "koKR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "koKR")
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
L["Info"] = "정보"
-- Kill marker icons (Carbonite map skull/seal markers)
L["Kill Icons"] = "처치 아이콘"
L["Show kill markers on map"] = "지도에 처치 표시 보이기"
L["When enabled, killed mobs leave a skull icon on your map at the kill location"] = "활성화 시, 처치한 몬스터의 위치에 해골 아이콘이 지도에 표시됩니다"
L["Auto-clear kill markers after"] = "처치 표시 자동 제거 시간"
L["Seconds before a kill marker disappears automatically. 0 = never (manual clear only)"] = "처치 표시가 자동으로 사라지는 시간(초). 0 = 사용 안 함 (수동 제거만)"

L["Keep kill history"] = "처치 기록 영구 보관"
L["When enabled, the auto-clear timer only hides expired markers but keeps the kill records in saved variables. Useful as a permanent kill log."] = "활성화 시, 자동 제거 타이머는 표시만 숨기고 기록은 보존합니다. 영구 처치 일지로 유용합니다."

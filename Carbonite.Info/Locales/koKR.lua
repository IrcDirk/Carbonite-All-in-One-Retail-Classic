if ( GetLocale() ~= "koKR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Info", "koKR")
if not L then return end

L["Info Options"] = "정보 옵션"
L["Lock Info Windows"] = "정보 창 잠금"
L["Locks the location of your info windows"] = "정보 창의 위치를 잠급니다"
L["Info Window Background Color"] = "정보 창 배경 색상"
L["Info Font"] = "정보 폰트"
L["Sets the font to be used for info windows"] = "정보 창에 사용할 폰트를 설정합니다"
L["Info Font Size"] = "정보 폰트 크기"
L["Sets the size of the info font"] = "정보 폰트의 크기를 설정합니다"
L["Info Font Spacing"] = "정보 폰트 간격"
L["Sets the spacing of the info font"] = "정보 폰트의 글씨 간격을 설정합니다"
L["Show Info Windows"] = "정보 창 보기"
L["Toggle Info Windows"] = "정보 창 전환"
L["Info Module"] = "정보 모듈"
L["Close"] = "닫기"
L["Edit Item"] = "항목 편집"
L["Show"] = "보기"
L["New Info Window"] = "새 정보 창"
L["Delete This Window"] = "이 창 삭제"
L["Options"] = "옵션"
L["Info"] = true
L["Edit View"] = "보기 편집"
L["Stop Edit"] = "편집 중지"
L["Change Text"] = "텍스트 변경"
L["Delete Info Window"] = "정보 창 삭제"
L["Delete"] = "삭제"
L["Cancel"] = "취소"

L["One minute until the Arena"] = "투기장 전투 시작 1분 전"
L["Thirty seconds until the Arena"] = "투기장 전투 시작 30초 전"
L["Fifteen seconds until the Arena"] = "투기장 전투 시작 15초 전"

L["Reset old info data %f"] = "이전 정보 데이터 초기화 %f"
L[" begins? in (%d+) "] = " (%d+)초 후에 시작"
L["(%d+) minutes? until the battle"] = "(%d+)분 후에 시작"
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

-- Font outline/shadow options
L["Font Outline"] = "글꼴 외곽선"
L["Font Shadow"] = "글꼴 그림자"
L["Sets the outline style of this font"] = "이 글꼴의 외곽선 스타일을 설정합니다"
L["Adds a drop shadow to this font"] = "이 글꼴에 그림자를 추가합니다"
L["None"] = "없음"
L["Outline"] = "외곽선"
L["Thick Outline"] = "굵은 외곽선"
L["Best"] = "최고"
L["Hit"] = "명중"
L["Killed"] = "처치"
L["Peak"] = "최대치"
L["Show Combat Graph"] = "전투 그래프 보기"
L["Time"] = "시간"
L["Toggle Combat Graph"] = "전투 그래프 전환"
L["Total"] = "전체"
L["crit"] = "치명타"
L["hit"] = "명중"
L["honor"] = "명예"

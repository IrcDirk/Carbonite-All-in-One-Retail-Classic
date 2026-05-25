if ( GetLocale() ~= "koKR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "koKR")
if not L then return end

NXClassLocToCap = {		-- Convert localized class name to generic caps
	["죽음의기사"] = "DEATHKNIGHT",
	["드루이드"] = "DRUID",
	["사냥꾼"] = "HUNTER",
	["마법사"] = "MAGE",
	["수도사"] = "MONK",
	["성기사"] = "PALADIN",
	["사제"] = "PRIEST",
	["도적"] = "ROGUE",
	["주술사"] = "SHAMAN",
	["흑마법사"] = "WARLOCK",
	["전사"] = "WARRIOR",
}

	NXlItemTypes = {
		ARMOR,
		"소비 용품",
		"가방",
		"보석",
		"문양",
		"열쇠",
		"기타",
		"투사체",
		"퀘스트",
		"화살통",
		"재료",
		"제조법",
		"직업 용품",
		"무기",
	}
-- Main Carbonite
L["Carbonite"] = true
L["CARBONITE"] = true
L["Loading"] = "시작하는 중..."
L["Loading Done"] = "성공적으로 시작했습니다."
L["None"] = "없음"
L["Goto"] = "이동"
L["Show Player Zone"] = "현재 지역 보기"
L["Menu"] = "메뉴"
L["Show Selected Zone"] = "선택 지역 보기"
L["Add Note"] = "표시 추가"
L["TopRight"] = true
L["Help"] = "도움말"
L["Options"] = "옵션"
L["Toggle Map"] = "지도 전환"
L["Toggle Combat Graph"] = "전투 그래프 전환"
L["Toggle Events"] = "이벤트 전환"
L["Left-Click to Toggle Map"] = "왼쪽 클릭: 지도 전환"
L["Shift Left-Click to Toggle Minimize"] = "Shift+왼쪽 클릭: 최소화 전환"
L["Middle-Click to Toggle Guide"] = "중간버튼 클릭: 안내서 전환"
L["Right-Click for Menu"] = "오른쪽 클릭: 메뉴"
L["Carbonite requires v5.0 or higher"] = "Carbonite v5.0 이상 필요"
L["GUID player"] = "플레이어 GUID"
L["GUID NPC"] = "NPC GUID"
L["GUID pet"] = "애완동물 GUID"
L["Unit map error"] = true
L["Gather"] = "채집"
L["Entered"] = "진입"
L["Level"] = "레벨"
L["Deaths"] = "사망"
L["Bonus"] = "보너스"
L["Reset old data"] = "오래된 데이타 초기화"
L["Reset old global options"] = "이전 전역 옵션 재설정"
L["Options have been reset for the new version."] = "옵션이 새 버전으로 재설정되었습니다."
L["Privacy or other settings may have changed."] = "개인 정보 보호 정책 또는 기타 설정이 변경되었을 수 있습니다."
L["Cleaned"] = "지움"
L["items"] = "아이템"
L["Reset old HUD options"] = "이전 HUD 옵션 초기화"
L["Reset old travel data"] = "이전 여행 데이타 초기화"
L["Reset old gather data"] = "이전 채집 데이타 초기화"
L["Missing character data!"] = "캐릭터 데이터 오류!"
L["Deathknight"] = "죽음의기사"
L["Death Knight"] = "죽음의기사"
L["Version"] = "버전"
L["Maintained by"] = true
L["crit"] = "치명타"
L["hit"] = "명중"
L["Killed"] = "처치"
L["honor"] = "명예"
L["Hit"] = "명중"
L["Peak"] = "최대치"
L["Best"] = "최고"
L["Total"] = "전체"
L["Time"] = "시간"
L["Event"] = "이벤트"
L["Events"] = "이벤트"
L["Position"] = "지역"
L["Died"] = "죽음!"
L["Picked"] = "발견"
L["Mined"] = "수집"
L["Fished"] = "낚음"
L["Unknown herb"] = "알수없는 약초"
L["Unknown ore"] = "알수없는 광석"
L["Gathermate2_Data_Carbonite addon is not loaded!"] = "Gathermate2_Data_Carbonite 애드온이 로드되지 않았습니다!"
L["Imported"] = "가져오기"
L["nodes from GatherMate2_Data"] = "GatherMate2_Data의 경로"
L["Delete visited vendor data?"] = "방문한 상인 정보를 삭제할까요?"
L["This will stop the attempted retrieval of items on login."] = "이 캐릭터가 로그인할 때 아이템 검색하지 않습니다."
L["Delete"] = "삭제"
L["Cancel"] = "취소"
L["items retrieved"] = "아이템이 검색됨"
L["Item retrieval from server complete"] = "서버 전체에서 아이템 검색"
L["Show Map"] = "지도 보기"
L["Show Combat Graph"] = "전투 그래프 보기"
L["Show Events"] = "이벤트 보기"
L["Show Auction Buyout Per Item"] = "개별 가격 표시"
L["Show Com Window"] = "전투 창 보기"
L["Toggle Profiling"] = "프로필 바꾸기"
L["Left click toggle Map"] = "왼쪽 클릭: 지도 전환"
L["Shift left click toggle minimize"] = "Shift+왼쪽 클릭: 최소화"
L["Alt left click toggle Watch List"] = "Alt+왼쪽 클릭: 감시 목록 전환"
L["Middle click toggle Guide"] = "가운데 버튼 클릭: 안내서"
L["Right click for Menu"] = "오른쪽 클릭: 메뉴"
L["Shift drag to move"] = "Shift 드래그: 이동"
L["Hide In Combat"] = "전투 중 숨기기"
L["Lock"] = "잠금"
L["Fade In"] = "점점 희미하게"
L["Fade Out"] = "점점 선명하게"
L["Layer"] = "레이어"
L["Scale"] = "크기"
L["Transparency"] = "투명도"
L["Reset Layout"] = "레이아웃 초기화"

-- Are the 4 lines below used?
L["Toggle profiling? Reloads UI"] = "프로필을 전환할까요? UI 재시작"
L["Reload"] = "재시작"
L["Profiling is on. This decreases game performance. Disable?"] = "프로필이 있습니다. 게임 성능이 떨어지게 됩니다. 사용 안하시겠습니까?"
L["Disable and Reload"] ="사용안함 그리고 재시작"

-- UI Tooltips
L["Close/Menu"] = "닫기/메뉴"
L["Close/Unlock"] = "닫기/잠금 해제"
L["Pick Color"] = true
L["Unlock"] = "잠금 해제"
L["Maximize"] = "최대화"
L["Restore"] = "되돌리기"
L["Minimize"] = "최소화"
L["Auto Scale"] = "자동 크기조절"

-- Stuff from old localization
L["Searching for Artifacts"] = "유물 수색"		-- NXlARTIFACTS
L["Extract Gas"] = "가스 추출"				-- NXlEXTRACTGAS
L["Herb Gathering"] = "약초채집"			-- NXlHERBGATHERING
L["In Conflict"] = "분쟁 지역"				-- NXlINCONFLICT
L["Opening"] = true					-- NXlOpening
L["Opening - No Text"] = true				-- NXlOpeningNoText
L["Everfrost Chip"] = "영원의 서리 파편"			-- NXlEverfrost

-- Are the ones below used?
-- 울보천사 추가함..
L["%.1f days"] = "%.1f 일"
L["%.1f hours"] = "%.1f 시간"
L["%d mins"] = "%d 분"
L[" days, "] = " 일 "
L[" hours, "] = " 시간 "
L[" minutes, "] = " 분 "
L[" seconds"] = " 초"
L["Reset old layout data"] = "오래된 레이아웃 데이타 초기화"
L["Window version mismatch!"] = "윈도우 버전이 일치하지 않음!"
L["XY missing (%s)"] = "XY 좌표가 일치하지 않음 (%s)"
L["Window not found (%s)"] = "윈도우를 찾을 수 없음 (%s)"
L["Search: %[click%]"] = "검색: %[클릭%]"
L["Search: [click]"] = "검색: [클릭]"
L["Reset old list data"] = "오래된 목록 데이타 초기화"
L["Key %s transfered to Watch List Item"] = "Key %s transfered to Watch List Item"
L["shift left/right click to change size"] = "shift-왼쪽/오른쪽 클릭-크기 변경"
L["Reset old tool bar data"] = "이전 도구바 데이타 초기화"
L["Size"] = "크기"
L["Spacing"] = "줄 간격"
L["Align Bottom"] = "아래 정렬"
L["Align Right"] = "오른쪽 정렬"
L["Vertical"] = "수직"
L["Put the game minimap into the Carbonite map?\n\nThis will make one unified map. The minimap buttons will go into the Carbonite button window. This can also be changed using the Map Minimap options page."] = ""

L["yds"] = true
L["secs"] = true
L["mins"] = true

-- NxUI.lua
L[" Frame: %s Shown%d Vis%d P>%s"] = true
L[" EScale %f, Lvl %f"] = true
L[" LR %f, %f"] = true
L[" BT %f, %f"] = true
L["%s#%d %s ID%s (%s) show%d l%d x%d y%d"] = true
L["%.1f days"] = true
L["%.1f hours"] = true
L["%d mins"] = true
L["Reset old layout data"] = true
L["Window version mismatch!"] = true
L["XY missing (%s)"] = true
L["Window not found (%s)"] = true
L["Detach %s"] = true
L["Detach found %s"] = true
L["Search: [click]"] = true
L["Search: %[click%]"] = true
L["Reset old list data"] = true
L["!BUT %s"] = true
L["Key %s transfered to Watch List Item"] = true
L["CLICK (.+):"] = true
L["Key %s %s #%s %s"] = true
L["shift left/right click to change size"] = true
L["Reset old tool bar data"] = true
L["|cffffff00%dg"] = true
L["%s |cffbfbfbf%ds"] = true
L["%s |cff7f7f00%dc"] = true

-- NxTravel.lua
L["Connection: %s to %s"] = true
L["Fly: %s to %s"] = true

-- NxHud.lua
L[" %.1f deg"] = true
L[" %d deg"] = true
L["Remove Current Point"] = true
L["Remove All Points"] = true

-- Carbonite.Info kill-marker tooltip
L["kill"] = "처치"
L["death"] = "사망"
L["kills: %s"] = "처치 횟수: %s"
L["NPC ID: %s"] = "NPC ID: %s"

-- AddonButtons toolbar tooltips (Questie / HandyNotes / RareScanner)
L["Left click"] = "왼쪽 클릭"
L["Right click"] = "오른쪽 클릭"
L["Toggle icons"] = "아이콘 전환"
L["Context menu"] = "컨텍스트 메뉴"
L["Open settings"] = "설정 열기"

if ( GetLocale() ~= "koKR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Warehouse", "koKR")
if not L then return end

L["ItemTypes"] = {
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
	AUCTION_CATEGORY_TRADE_GOODS,
	"직업 용품",
	"무기",
}

L["-Warehouse-"] = "-창고-"
L["Warehouse Module"] = "창고 모듈"
L["Warehouse Options"] = "창고 옵션"
L["Add Warehouse Tooltip"] = "창고 툴팁 추가"
L["When enabled, will show warehouse information in hover tooltips of items"] = "사용할 경우, 아이템 툴팁에 창고 정보를 표시합니다"
L["Warehouse Font"] = "창고 폰트"
L["Sets the font to be used for warehouse windows"] = "창고 창에 사용할 폰트를 설정합니다"
L["Warehouse Font Size"] = "창고 폰트 크기"
L["Sets the size of the warehouse font"] = "창고 폰트의 크기를 설정합니다"
L["Warehouse Font Spacing"] = "창고 폰트 간격"
L["Sets the spacing of the warehouse font"] = "창고 폰트의 글씨 간격을 설정합니다"
L["Toggle Warehouse"] = "창고 전환"
L["Remove Character or Guild"] = "캐릭터 또는 길드 삭제"
L["Import settings from selected character"] = "선택한 캐릭터에서 설정 가져오기"
L["Export current settings to all characters"] = "현재 설정을 모든 캐릭터로 내보내기"
L["Sync account transfer file"] = "계정 이전 파일 동기화"
L["Show Lowest Equipped Rarity"] = "착용 장비 최저 등급 보기"
L["Show Item Headers"] = "아이템 머리글 보기"
L["Sort By Rarity"] = "등급순 정렬"
L["Show Lowest Rarity"] = "최저 등급 보기"
L["Sort By Slot"] = "슬롯순 정렬"
L["Import %s's character data and reload?"] = "%s의 캐릭터 데이터를 가져오고 UI를 재시작하시겠습니까?"
L["Overwrite all character settings and reload?"] = "모든 캐릭터 설정을 덮어쓰고 UI를 재시작하시겠습니까?"
L["Warehouse: %d characters"] = "창고: 캐릭터 %d명"
L["DurPattern"] = "^Durability (%d+) / (%d+)"
L["Show Warehouse"] = "창고 보기"

L["Import"] = "가져오기"
L["Cancel"] = "취소"
L["Export"] = "내보내기"
L["Warehouse"] = true
L[" Realm:%s %s"] = " 서버:%s %s"
L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"] = " 접속 시간: %s%2d:%02d:%02d|r, 플레이 시간: %s%s"
L[" Session Money:%s %s|r, Per Hour:%s %s"] = " 세션 골드:%s %s|r, 시간당:%s %s"
L[" Durability: %s%d%%, lowest %d%%"] = " 내구도: %s%d%%, 최저 %d%%"
L[" Session XP:%s %s|r, Per Hour:%s %.0f"] = " 세션 경험치:%s %s|r, 시간당:%s %.0f"
L[" Hours To Level: %s%.1f"] = " 레벨업까지 시간: %s%.1f"
L[" Last On: %s%s|r, Played: %s%s"] = " 마지막 접속: %s%s|r, 플레이 시간: %s%s"
L[" Location: %s%s (%d, %d)"] = " 위치: %s%s (%d, %d)"
L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " 시작 경험치: %s%s/%s (%.0f%%)|r 휴식: %s%.0f%%"
L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " 경험치: %s%s/%s (%.0f%%)|r 휴식: %s%.0f%%"
L[" Honor: %s%s|r  Conquest: %s%s"] = " 명예: %s%s|r  정복: %s%s"
L[" Valor: %s%s|r  Justice: %s%s"] = " 용맹: %s%s|r  정의: %s%s"
--L[" %s %s%s"] = true
L["|cffafdfafAll: %s. |cffafdfafPlayed: %s%s"] = "|cffafdfaf전체: %s. |cffafdfaf플레이 시간: %s%s"
L["%s's Items"] = "%s의 아이템"
L["|cffff1010No bank data - visit your bank"] = "|cffff1010은행 데이터 없음 - 은행을 방문하세요"
L["|cffff1010No reagent bank data - visit your bank"] = "|cffff1010재료 은행 데이터 없음 - 은행을 방문하세요"
L["---- Equipped ----"] = "---- 착용 중 ----"
L["Slot"] = "슬롯"
L["---- %s Equipped ----"] = "---- %s 착용 중 ----"
L["All Items"] = "모든 아이템"
L["%s |cffcfcfff(%s Bank)"] = "%s |cffcfcfff(%s 은행)"
L["%s |cffcfffff(%s Mail)"] = "%s |cffcfffff(%s 우편)"
L["%s %d (%d Worn)"] = "%s %d (%d 착용)"
L["%s (%d Bank)"] = "%s (%d 은행)"
L["%s (%d RBank)"] = "%s (%d 재료은행)"
L["%s (%s Mail)"] = "%s (%s 우편)"
L["%s (%s Pets)"] = "%s (%s 애완동물)"
L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00가방:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00착용:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00우편:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00은행:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00재료은행:%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00애완동물:%d|cFFFF0000]"
L["%s's %s Skills"] = "%s의 %s 기술"
L["|cffff1010No data - open %s window"] = "|cffff1010데이터 없음 - %s 창을 여세요"
L["|cffffffffW%sarehouse:"] = "|cffffffff창%s고:"
L["LOOT_OPENED %s (%s %s)"] = "LOOT_OPENED %s (%s %s)"
L["no LootTarget"] = "LootTarget 없음"
L["LOOT_SLOT_CLEARED #%s %s (quest)"] = "LOOT_SLOT_CLEARED #%s %s (퀘스트)"
L["%s deleted"] = "%s 삭제됨"
L["enchant:(%d+)"] = true
L["item:(%d+)"] = true

-- Keybinds
L["Carbonite Warehouse"] = "Carbonite Warehouse"
L["NxTOGGLEWAREHOUSE"] = "show/hide Warehouse"

L["Guilds"] = "길드"
L["Characters"] = "캐릭터"
L["Guild Bank"] = "길드 은행"
L["Current Funds"] = "현재 자금"
L["Last Updated"] = "마지막 갱신"
L["Tab is empty or no access"] = "탭이 비어 있거나 접근 권한이 없습니다"
L["ago"] = "전"
L["not opened or scanned."] = "열지 않았거나 검색되지 않았습니다."
L["Tab"] = "탭"
L["All Characters"] = "모든 캐릭터"
L["AUTO-REPAIR"] = "자동 수리"
L["Auto Repair"] = "자동 수리"
L["GUILD WITHDRAW"] = "길드 자금 인출"
L["Not enough funds to repair."] = "수리 비용이 부족합니다."
L["Auto Repair Gear"] = "장비 자동 수리"
L["When you open a merchant, will attempt to auto repair your gear"] = "상인 창을 열면 장비를 자동으로 수리합니다"
L["Use Guild Repair First"] = "길드 수리 우선 사용"
L["Will try to use guild funds to pay for repairs before your own"] = "수리 비용을 내 골드보다 길드 자금으로 먼저 지불합니다"

L["Verbose Selling"] = "판매 내역 상세 표시"
L["When enabled shows what items got sold instead of just the grand total earned."] = "사용할 경우, 총 판매 금액만이 아니라 판매된 아이템 목록을 표시합니다."
L["Test Selling"] = "판매 테스트"
L["Enabling this allows you to see what would get sold, without actually selling."] = "사용할 경우, 실제로 판매하지 않고 판매될 아이템만 확인할 수 있습니다."
L["Warehouse"] = "창고"
L["Auto Sell"] = "자동 판매"
L["Items"] = "아이템"
L["Grey"] = "회색"
L["White"] = "흰색"
L["Green"] = "녹색"
L["Blue"] = "파란색"
L["Purple"] = "보라색"
L["Selling"] = "판매"
L["When you open a merchant, will auto sell your grey items"] = "상인 창을 열면 회색 아이템을 자동으로 판매합니다"
L["When you open a merchant, will auto sell your white items."] = "상인 창을 열면 흰색 아이템을 자동으로 판매합니다."
L["When you open a merchant, will auto sell your green items."] = "상인 창을 열면 녹색 아이템을 자동으로 판매합니다."
L["When you open a merchant, will auto sell your blue items."] = "상인 창을 열면 파란색 아이템을 자동으로 판매합니다."
L["When you open a merchant, will auto sell your purple items."] = "상인 창을 열면 보라색 아이템을 자동으로 판매합니다."
L["iLevel"] = "아이템 레벨"
L["Enable iLevel Limit"] = "아이템 레벨 제한 사용"
L["Only sells items that are under the ilvl specified"] = "지정한 아이템 레벨 미만의 아이템만 판매합니다"
L["Sets the maximum item level which will be auto sold"] = "자동 판매할 최대 아이템 레벨을 설정합니다"
L["Sell BOP Items"] = "획득 시 귀속 아이템 판매"
L["When enabled will sell items that are BOP"] = "사용할 경우, 획득 시 귀속 아이템을 판매합니다"
L["Sell BOE Items"] = "착용 시 귀속 아이템 판매"
L["When enabled will sell items that are BOE"] = "사용할 경우, 착용 시 귀속 아이템을 판매합니다"
L["Sell items based on a list"] = "목록에 따라 아이템 판매"
L["If item name matches one on the list, auto-sell it"] = "아이템 이름이 목록과 일치하면 자동으로 판매합니다"
L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."] = "자동 판매할 아이템의 이름을 입력하세요. 가방에서 아이템을 끌어다 놓을 수도 있습니다."
L["New Item To Sell (Case Insensative)"] = "판매할 새 아이템 (대소문자 구분 안 함)"
L["AUTO-SELL: You Earned"] = "자동 판매: 획득 금액"
L["Delete Item"] = "항목 삭제"
L["Delete"] = "삭제"
L["Yes"] = "예"
L["No"] = "아니오"

L["Show coin count in warehouse list"] = "창고 목록에 골드 표시"
L["Restores the coin totals after character names in warehouse listing"] = "창고 목록의 캐릭터 이름 뒤에 골드 합계를 표시합니다"

L["Use don't display list"] = "표시 안 함 목록 사용"
L["If enabled, don't show listed items in tooltips"] = "사용할 경우, 목록에 있는 아이템을 툴팁에 표시하지 않습니다"
L["New Item To Ignore (Case Insensative)"] = "무시할 새 아이템 (대소문자 구분 안 함)"
L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."] = "툴팁에서 추적하지 않을 아이템의 이름을 입력하세요. 가방에서 아이템을 끌어다 놓을 수도 있습니다."
L["Ignore"] = "무시"

-- Font outline/shadow options
L["Font Outline"] = "글꼴 외곽선"
L["Font Shadow"] = "글꼴 그림자"
L["Sets the outline style of this font"] = "이 글꼴의 외곽선 스타일을 설정합니다"
L["Adds a drop shadow to this font"] = "이 글꼴에 그림자를 추가합니다"
L["None"] = "없음"
L["Outline"] = "외곽선"
L["Thick Outline"] = "굵은 외곽선"

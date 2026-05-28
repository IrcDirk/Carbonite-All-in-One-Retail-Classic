if ( GetLocale() ~= "koKR" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Notes", "koKR")
if not L then return end

L["Note Options"] = true
L["Show Notes On Map"] = true
L["Shows your notes on the carbonite map"] = true
L["Show Notes"] = true
L["-Notes-"] = true
L["Add Note"] = true
L["Notes Module"] = true
L["Toggle Notes"] = true
L["Record"] = true
L["Up"] = true
L["Down"] = true
L["Delete Item"] = true
L["Name"] = true
L["Type"] = true
L["Value"] = true
L["Location"] = true
L["Select a favorite before recording"] = true
L["Add Folder"] = true
L["Add Favorite"] = true
L["Rename"] = true
L["Cut"] = true
L["Copy"] = true
L["Paste"] = true
L["Options"] = true
L["Add Comment"] = true
L["Set Icon"] = true
L["Name"] = true
L["Nothing to paste"] = true
L["Can't paste that on the left side"] = true
L["Can't paste that on the right side"] = true
L["Note"] = true
L["Notes"] = true
L["Note Addons"] = true
L["My Notes"] = true

L["Reset old notes data"] = true
L["Display Handynotes On Map"] = true
L["If you have HandyNotes installed, allows them on the Carbonite map"] = true
L["Handnotes Icon Size"] = true

L["Display RareScanner icons On Map"] = true
L["If you have RareScanner installed, allows its icons on the Carbonite map"] = true
L["RareScanner Icon Size"] = true

L["Display RXPGuides waypoints On Map"] = "지도에 RXPGuides 경로 지점 표시"
L["If you have RXPGuides installed, mirrors its active-step waypoint pins onto the Carbonite map"] = "RXPGuides가 설치되어 있으면 활성 단계 경로 핀을 Carbonite 지도에 표시합니다"
L["RXPGuides Icon Size"] = "RXPGuides 아이콘 크기"
L["Route RXPGuides arrow through Carbonite"] = "RXPGuides 화살표를 Carbonite로 전달"
L["Step"] = "단계"
L["Replaces the RXPGuides navigation arrow with Carbonite's own HUD travel arrow, pointing at the current step"] = "RXPGuides 내비게이션 화살표를 Carbonite 자체 HUD 이동 화살표로 대체하여 현재 단계를 가리킵니다"
L["Route ZygorGuides arrow through Carbonite"] = "ZygorGuides 화살표를 Carbonite로 전달"
L["Replaces the ZygorGuides navigation arrow with Carbonite's own HUD travel arrow, pointing at the current step"] = "ZygorGuides 내비게이션 화살표를 Carbonite 자체 HUD 이동 화살표로 대체하여 현재 단계를 가리킵니다"

-- Keybinds
L["Carbonite Notes"] = "Carbonite Notes"
L["NxTOGGLEFAV"] = "show/hide Notes"

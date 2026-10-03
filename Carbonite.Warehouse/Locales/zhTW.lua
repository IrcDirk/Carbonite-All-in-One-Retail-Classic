if ( GetLocale() ~= "zhTW" ) then
	return;
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite.Warehouse", "zhTW")
if not L then return end

L["ItemTypes"] = {
	ARMOR,
	"消耗品",
	"容器",
	"寶石",
	"雕文",
	"鑰匙",
	"其他",
	"彈藥",
	"任務",
	"箭袋",
	"施法材料",
	"配方",
	AUCTION_CATEGORY_TRADE_GOODS,
	"商品",
	"武器",
}

L["-Warehouse-"] = "-倉庫-"
L["Warehouse Module"] = "倉庫模組"
L["Warehouse Options"] = "倉庫選項"
L["Add Warehouse Tooltip"] = "加入倉庫滑鼠提示"
L["When enabled, will show warehouse information in hover tooltips of items"] = "啟用後，會在物品的滑鼠提示中顯示倉庫資訊"
L["Warehouse Font"] = "倉庫字型"
L["Sets the font to be used for warehouse windows"] = "設定倉庫視窗使用的字型"
L["Warehouse Font Size"] = "倉庫字型大小"
L["Sets the size of the warehouse font"] = "設定倉庫字型的大小"
L["Warehouse Font Spacing"] = "倉庫字型間距"
L["Sets the spacing of the warehouse font"] = "設定倉庫字型的間距"
L["Toggle Warehouse"] = "切換倉庫"
L["Remove Character or Guild"] = "移除角色或公會"
L["Import settings from selected character"] = "從選取的角色匯入設定"
L["Export current settings to all characters"] = "將目前設定匯出到所有角色"
L["Sync account transfer file"] = "同步帳號轉移檔案"
L["Show Lowest Equipped Rarity"] = "顯示已裝備的最低品質"
L["Show Item Headers"] = "顯示物品標題"
L["Sort By Rarity"] = "依品質排序"
L["Show Lowest Rarity"] = "顯示最低品質"
L["Sort By Slot"] = "依欄位排序"
L["Import %s's character data and reload?"] = "要匯入 %s 的角色資料並重新載入嗎？"
L["Overwrite all character settings and reload?"] = "要覆寫所有角色設定並重新載入嗎？"
L["Warehouse: %d characters"] = "倉庫：%d 個角色"
L["DurPattern"] = "^耐久度 (%d+) / (%d+)"
L["Show Warehouse"] = "顯示倉庫"

L["Import"] = "匯入"
L["Cancel"] = "取消"
L["Export"] = "匯出"
L["Warehouse"] = true
L[" Realm:%s %s"] = " 伺服器：%s %s"
L[" Time On: %s%2d:%02d:%02d|r, Played: %s%s"] = " 上線時間：%s%2d:%02d:%02d|r，遊戲時間：%s%s"
L[" Session Money:%s %s|r, Per Hour:%s %s"] = " 本次金錢：%s %s|r，每小時：%s %s"
L[" Durability: %s%d%%, lowest %d%%"] = " 耐久度：%s%d%%，最低 %d%%"
L[" Session XP:%s %s|r, Per Hour:%s %.0f"] = " 本次經驗：%s %s|r，每小時：%s %.0f"
L[" Hours To Level: %s%.1f"] = " 升級所需時數：%s%.1f"
L[" Last On: %s%s|r, Played: %s%s"] = " 最後上線：%s%s|r，遊戲時間：%s%s"
L[" Location: %s%s (%d, %d)"] = " 位置：%s%s (%d, %d)"
L[" Start XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " 起始經驗：%s%s/%s (%.0f%%)|r 休息：%s%.0f%%"
L[" XP: %s%s/%s (%.0f%%)|r Rest: %s%.0f%%"] = " 經驗：%s%s/%s (%.0f%%)|r 休息：%s%.0f%%"
L[" Honor: %s%s|r  Conquest: %s%s"] = " 榮譽：%s%s|r  征服：%s%s"
L[" Valor: %s%s|r  Justice: %s%s"] = " 勇氣：%s%s|r  正義：%s%s"
--L[" %s %s%s"] = true
L["|cffafdfafAll: %s. |cffafdfafPlayed: %s%s"] = "|cffafdfaf全部：%s。|cffafdfaf遊戲時間：%s%s"
L["%s's Items"] = "%s 的物品"
L["|cffff1010No bank data - visit your bank"] = "|cffff1010沒有銀行資料 - 請造訪你的銀行"
L["|cffff1010No reagent bank data - visit your bank"] = "|cffff1010沒有材料銀行資料 - 請造訪你的銀行"
L["---- Equipped ----"] = "---- 已裝備 ----"
L["Slot"] = "欄位"
L["---- %s Equipped ----"] = "---- %s 已裝備 ----"
L["All Items"] = "所有物品"
L["%s |cffcfcfff(%s Bank)"] = "%s |cffcfcfff(%s 銀行)"
L["%s |cffcfffff(%s Mail)"] = "%s |cffcfffff(%s 郵件)"
L["%s %d (%d Worn)"] = "%s %d (%d 已穿戴)"
L["%s (%d Bank)"] = "%s (%d 銀行)"
L["%s (%d RBank)"] = "%s (%d 材料銀行)"
L["%s (%s Mail)"] = "%s (%s 郵件)"
L["%s (%s Pets)"] = "%s (%s 寵物)"
L["%s|cFFFF0000[|cFF00FF00Bags:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00背包：%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Worn:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00穿戴：%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Mail:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00郵件：%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Bank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00銀行：%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00RBank:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00材料銀行：%d|cFFFF0000]"
L["%s|cFFFF0000[|cFF00FF00Pets:%d|cFFFF0000]"] = "%s|cFFFF0000[|cFF00FF00寵物：%d|cFFFF0000]"
L["%s's %s Skills"] = "%s 的%s技能"
L["|cffff1010No data - open %s window"] = "|cffff1010沒有資料 - 請開啟%s視窗"
L["|cffffffffW%sarehouse:"] = "|cffffffff倉%s庫："
L["LOOT_OPENED %s (%s %s)"] = "LOOT_OPENED %s (%s %s)"
L["no LootTarget"] = "無 LootTarget"
L["LOOT_SLOT_CLEARED #%s %s (quest)"] = "LOOT_SLOT_CLEARED #%s %s (任務)"
L["%s deleted"] = "%s 已刪除"
L["enchant:(%d+)"] = true
L["item:(%d+)"] = true

-- Keybinds
L["Carbonite Warehouse"] = "Carbonite Warehouse"
L["NxTOGGLEWAREHOUSE"] = "show/hide Warehouse"

L["Guilds"] = "公會"
L["Characters"] = "角色"
L["Guild Bank"] = "公會銀行"
L["Current Funds"] = "目前資金"
L["Last Updated"] = "最後更新"
L["Tab is empty or no access"] = "此分頁為空或無權限"
L["ago"] = "前"
L["not opened or scanned."] = "尚未開啟或掃描。"
L["Tab"] = "分頁"
L["All Characters"] = "所有角色"
L["AUTO-REPAIR"] = "自動修理"
L["Auto Repair"] = "自動修理"
L["GUILD WITHDRAW"] = "公會提領"
L["Not enough funds to repair."] = "資金不足以修理。"
L["Auto Repair Gear"] = "自動修理裝備"
L["When you open a merchant, will attempt to auto repair your gear"] = "開啟商人視窗時，會嘗試自動修理你的裝備"
L["Use Guild Repair First"] = "優先使用公會修理"
L["Will try to use guild funds to pay for repairs before your own"] = "會嘗試先使用公會資金支付修理費用，再使用你自己的"

L["Verbose Selling"] = "詳細販賣訊息"
L["When enabled shows what items got sold instead of just the grand total earned."] = "啟用後會顯示賣出了哪些物品，而不只是總收入。"
L["Test Selling"] = "測試販賣"
L["Enabling this allows you to see what would get sold, without actually selling."] = "啟用後可查看將會賣出哪些物品，而不實際賣出。"
L["Warehouse"] = "倉庫"
L["Auto Sell"] = "自動販賣"
L["Items"] = "物品"
L["Grey"] = "灰色"
L["White"] = "白色"
L["Green"] = "綠色"
L["Blue"] = "藍色"
L["Purple"] = "紫色"
L["Selling"] = "販賣"
L["When you open a merchant, will auto sell your grey items"] = "開啟商人視窗時，會自動賣出你的灰色物品"
L["When you open a merchant, will auto sell your white items."] = "開啟商人視窗時，會自動賣出你的白色物品。"
L["When you open a merchant, will auto sell your green items."] = "開啟商人視窗時，會自動賣出你的綠色物品。"
L["When you open a merchant, will auto sell your blue items."] = "開啟商人視窗時，會自動賣出你的藍色物品。"
L["When you open a merchant, will auto sell your purple items."] = "開啟商人視窗時，會自動賣出你的紫色物品。"
L["iLevel"] = "物品等級"
L["Enable iLevel Limit"] = "啟用物品等級限制"
L["Only sells items that are under the ilvl specified"] = "只賣出低於指定物品等級的物品"
L["Sets the maximum item level which will be auto sold"] = "設定會被自動賣出的最高物品等級"
L["Sell BOP Items"] = "賣出拾取綁定物品"
L["When enabled will sell items that are BOP"] = "啟用後會賣出拾取後綁定的物品"
L["Sell BOE Items"] = "賣出裝備綁定物品"
L["When enabled will sell items that are BOE"] = "啟用後會賣出裝備後綁定的物品"
L["Sell items based on a list"] = "依清單賣出物品"
L["If item name matches one on the list, auto-sell it"] = "如果物品名稱符合清單中的項目，就自動賣出"
L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."] = "輸入你想自動賣出的物品名稱。你也可以從背包拖放物品到這裡。"
L["New Item To Sell (Case Insensative)"] = "新增要賣出的物品（不分大小寫）"
L["AUTO-SELL: You Earned"] = "自動販賣：你賺了"
L["Delete Item"] = "刪除項目"
L["Delete"] = "刪除"
L["Yes"] = "是"
L["No"] = "否"

L["Show coin count in warehouse list"] = "在倉庫清單中顯示金錢數量"
L["Restores the coin totals after character names in warehouse listing"] = "在倉庫清單的角色名稱後恢復顯示金錢總數"

L["Use don't display list"] = "使用不顯示清單"
L["If enabled, don't show listed items in tooltips"] = "啟用後，不在滑鼠提示中顯示清單中的物品"
L["New Item To Ignore (Case Insensative)"] = "新增要忽略的物品（不分大小寫）"
L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."] = "輸入你不想在滑鼠提示中追蹤的物品名稱。你也可以從背包拖放物品到這裡。"
L["Ignore"] = "忽略"

-- Font outline/shadow options
L["Font Outline"] = "字型描邊"
L["Font Shadow"] = "字型陰影"
L["Sets the outline style of this font"] = "設定此字型的描邊樣式"
L["Adds a drop shadow to this font"] = "為此字型加入陰影"
L["None"] = "無"
L["Outline"] = "描邊"
L["Thick Outline"] = "粗描邊"

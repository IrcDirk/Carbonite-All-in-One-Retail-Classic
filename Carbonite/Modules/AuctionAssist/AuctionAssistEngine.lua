-- Carbonite | Modules / AuctionAssist / AuctionAssistEngine
-- Auction-house browse-assistant engine extracted from
-- Carbonite.lua. Hooks AuctionFrameBrowse_Update on retail to show
-- per-item buyout cost and tag the cheapest stack.
--
-- Methods stay on Nx.AuctionAssist because Carbonite.lua's
-- InitEvents binds them via AceEvent dispatch:
--   AuctionAssist:RegisterEvent("AUCTION_HOUSE_SHOW",  "OnAuction_house_show")
--   AuctionAssist:RegisterEvent("AUCTION_HOUSE_CLOSED","OnAuction_house_closed")
--   AuctionAssist:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", "OnAuction_item_list_update")
-- Renaming would require touching every registration; the public
-- AuctionAssist module class in AuctionAssist.lua wraps these.

local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

---
-- AUCTION_HOUSE_SHOW: install our per-item buyout hook the first
-- time the AH frame is available.
--
function Nx.AuctionAssist.OnAuction_house_show()
    if IsAddOnLoaded("Blizzard_AuctionUI") then
        hooksecurefunc("AuctionFrameBrowse_Update", Nx.AuctionAssist.AuctionFrameBrowse_Update)
        Nx.AuctionAssist:Create()
    end
end

---
-- AUCTION_HOUSE_CLOSED: hide our window + clear the list.
--
function Nx.AuctionAssist.OnAuction_house_closed()
    local self = Nx.AuctionAssist
    if self.Win then
        self.Win:Show(false)
        self.ItemList:Empty()
    end
end

---
-- AUCTION_ITEM_LIST_UPDATE: refresh the assistant's display.
--
function Nx.AuctionAssist.OnAuction_item_list_update()
    Nx.AuctionAssist:Update()
end

---
-- Stub: build our companion window. Legacy code never finished the
-- frame; the hook into AuctionFrameBrowse_Update is the only piece
-- still doing real work.
--
function Nx.AuctionAssist:Create()
end

---
-- List click handler: type the clicked auction's name into the
-- browse search field and re-fire the AH search.
--
function Nx.AuctionAssist:OnListEvent(eventName, sel)
    local name = self.List:ItemGetData(sel)
    Nx.prt("%s", name)
    BrowseName:SetText(name)
    AuctionFrameBrowse_Search()
end

---
-- Stub.
--
function Nx.AuctionAssist:Update()
end

---
-- Post-hook on AuctionFrameBrowse_Update: walks the visible auction
-- rows, computes price-per-item for any stack > 1, and marks the
-- cheapest per-unit listing with a "* low" suffix. Gated on
-- Nx.AuctionShowBOPer so users can opt in.
--
function Nx.AuctionAssist.AuctionFrameBrowse_Update()
    if not Nx.AuctionShowBOPer then return end

    local low, lowName, lowIName = 99999999

    local numBatchAuctions = GetNumAuctionItems("list")
    local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
    local last   = offset + NUM_BROWSE_TO_DISPLAY

    for n = 1, NUM_AUCTION_ITEMS_PER_PAGE do
        local name, _, count, quality, _, _, minBid, minIncrement, buyoutPrice, bidAmount =
            GetAuctionItemInfo("list", n)

        local index = n + NUM_AUCTION_ITEMS_PER_PAGE * AuctionFrameBrowse["page"]
        if index > numBatchAuctions + NUM_AUCTION_ITEMS_PER_PAGE * AuctionFrameBrowse["page"] then
            break
        end

        local requiredBid = (bidAmount == 0) and minBid or (bidAmount + minIncrement)
        if requiredBid >= MAXIMUM_BID_PRICE then
            buyoutPrice = requiredBid
        end

        if buyoutPrice > 0 then
            local price1 = floor(buyoutPrice / count)

            if n > offset and n <= last then
                local buttonName = "BrowseButton" .. (n - offset)
                local itemName = _G[buttonName .. "Name"]

                if itemName then
                    if price1 < low then
                        low = price1
                        lowName  = name
                        lowIName = itemName
                    end

                    if count > 1 then
                        itemName:SetText(format("%s *", name))
                        local color = ITEM_QUALITY_COLORS[quality]
                        itemName:SetVertexColor(color.r, color.g, color.b)

                        local bf = _G[buttonName .. "BuyoutFrameMoney"]
                        if bf then
                            MoneyFrame_Update(bf:GetName(), price1)
                        end
                    end
                end
            elseif price1 < low then
                low = price1
                lowName = nil
            end
        end
    end

    if lowName then
        lowIName:SetText(format("%s * low", lowName))
    end
end

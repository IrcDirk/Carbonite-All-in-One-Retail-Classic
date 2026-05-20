-- Carbonite | UI / List
-- Modern scrolling list widget built on FauxScrollFrameTemplate so
-- it works on every WoW client back to Classic. Replaces the legacy
-- Nx.List with a clean spec-table API:
--
--   local list = Carbonite.UI.List:New {
--       parent = parentFrame,
--       width  = 200,
--       height = 240,
--       anchor = { point = "TOPLEFT", x = 10, y = -10 },
--       rowHeight = 14,
--       drawRow = function(row, dataItem, index, isSelected)
--           row.text:SetText(dataItem.name)
--       end,
--       onSelect = function(list, dataItem, index) ... end,
--   }
--
--   list:SetData(arrayOfItems)
--   list:GetSelected()                 -> data item, index
--   list:Select(index)
--   list:GetSelectedIndex()
--   list:Refresh()                      -- redraw rows without rebuilding pool
--   list:GetData()                      -- the underlying array
--   list:Count()
--
-- The legacy Nx.List with its Bar / ItemAdd / ItemSet / ItemSetFrame
-- API stays in NxUI.lua for legacy callers; new code should use this.

local Carbonite = _G.Carbonite
local List = {}
Carbonite.UI.List = List

local Methods = {}

local function rebuildRowPool(list)
    local need = list._visibleRows
    local rowH = list._rowHeight

    -- Allocate any missing rows.
    for i = #list._rows + 1, need do
        local row = CreateFrame("Button", nil, list._content)
        row:SetSize(list._content:GetWidth(), rowH)
        row:SetPoint("TOPLEFT", list._content, "TOPLEFT", 0, -((i - 1) * rowH))

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row)
        hl:SetColorTexture(1, 1, 1, 0.10)

        local sel = row:CreateTexture(nil, "BACKGROUND")
        sel:SetAllPoints(row)
        sel:SetColorTexture(0.25, 0.4, 0.7, 0.35)
        sel:Hide()
        row.selectionTex = sel

        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", row, "LEFT", 4, 0)
        fs:SetJustifyH("LEFT")
        fs:SetWidth(row:GetWidth() - 8)
        row.text = fs

        row:SetScript("OnClick", function(self_)
            if self_._index then list:Select(self_._index) end
        end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        list._rows[i] = row
    end

    -- Hide any extras.
    for i = need + 1, #list._rows do list._rows[i]:Hide() end
end

local function redraw(list)
    if not list._scrollFrame then return end
    rebuildRowPool(list)

    local rowH = list._rowHeight
    local n = #(list._data or {})

    if _G.FauxScrollFrame_Update then
        _G.FauxScrollFrame_Update(list._scrollFrame, n, list._visibleRows, rowH)
    end

    local offset = (_G.FauxScrollFrame_GetOffset and _G.FauxScrollFrame_GetOffset(list._scrollFrame)) or 0

    for i = 1, list._visibleRows do
        local row = list._rows[i]
        local idx = offset + i
        local item = list._data and list._data[idx]
        if not item then
            row:Hide()
        else
            row._index = idx
            row.selectionTex:SetShown(idx == list._selectedIndex)
            if list._drawRow then
                list._drawRow(row, item, idx, idx == list._selectedIndex)
            else
                row.text:SetText(tostring(item))
            end
            row:Show()
        end
    end
end

function Methods:SetData(arr)
    self._data = arr or {}
    self._selectedIndex = nil
    redraw(self)
end

function Methods:GetData() return self._data end

function Methods:Count() return self._data and #self._data or 0 end

function Methods:Refresh() redraw(self) end

function Methods:Select(index)
    if not self._data or not self._data[index] then return end
    self._selectedIndex = index
    redraw(self)
    if self._onSelect then self._onSelect(self, self._data[index], index) end
end

function Methods:GetSelectedIndex() return self._selectedIndex end

function Methods:GetSelected()
    local i = self._selectedIndex
    return i and self._data and self._data[i], i
end

function Methods:SetRowDrawer(fn)
    self._drawRow = fn
    redraw(self)
end

function Methods:ScrollToTop()
    if self._scrollFrame and _G.FauxScrollFrame_OnVerticalScroll then
        self._scrollFrame:SetVerticalScroll(0)
    end
    redraw(self)
end

function List:New(spec)
    spec = spec or {}
    local parent = spec.parent or UIParent
    local w = spec.width or 200
    local h = spec.height or 200

    local frame = CreateFrame("Frame", spec.name, parent)
    frame:SetSize(w, h)
    if spec.anchor then
        frame:SetPoint(spec.anchor.point or "TOPLEFT",
            spec.anchor.relativeTo or parent,
            spec.anchor.relPoint or (spec.anchor.point or "TOPLEFT"),
            spec.anchor.x or 0, spec.anchor.y or 0)
    end

    for k, v in pairs(Methods) do frame[k] = v end

    frame._rowHeight    = spec.rowHeight or 14
    frame._visibleRows  = math.max(1, math.floor(h / frame._rowHeight))
    frame._rows         = {}
    frame._data         = spec.data or {}
    frame._drawRow      = spec.drawRow
    frame._onSelect     = spec.onSelect
    frame._selectedIndex = nil

    -- ScrollFrame on FauxScrollFrameTemplate gives us the scroll bar
    -- and the OnVerticalScroll callback for free; we just redraw on
    -- offset change.
    local sf = CreateFrame("ScrollFrame", (spec.name or "CarbList") .. "Scroll", frame, "FauxScrollFrameTemplate")
    sf:SetAllPoints(frame)
    sf:SetScript("OnVerticalScroll", function(self_, delta)
        if _G.FauxScrollFrame_OnVerticalScroll then
            _G.FauxScrollFrame_OnVerticalScroll(self_, delta, frame._rowHeight, function() redraw(frame) end)
        end
    end)

    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(w - 24, h)        -- leave room for scroll bar
    content:SetPoint("TOPLEFT", sf, "TOPLEFT", 0, 0)

    frame._scrollFrame = sf
    frame._content     = content

    redraw(frame)
    return frame
end

-- Carbonite | UI / Mixins / Resizable
-- Adds bottom-right corner resizing to any Frame. Stores width/height
-- in `dbSize` so the user's resize persists across reloads.

local Carbonite = _G.Carbonite
local Resizable = {}
Carbonite.UI.Mixins = Carbonite.UI.Mixins or {}
Carbonite.UI.Mixins.Resizable = Resizable

function Resizable:EnableResizing(dbSize, minW, minH, maxW, maxH)
    self.dbSize = dbSize

    self:SetResizable(true)
    if self.SetResizeBounds then
        self:SetResizeBounds(minW or 80, minH or 60, maxW or 4096, maxH or 4096)
    else
        if self.SetMinResize then self:SetMinResize(minW or 80, minH or 60) end
        if self.SetMaxResize then self:SetMaxResize(maxW or 4096, maxH or 4096) end
    end

    local grip = CreateFrame("Button", nil, self)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() self:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        self:StopMovingOrSizing()
        if self.dbSize then
            self.dbSize.w = self:GetWidth()
            self.dbSize.h = self:GetHeight()
        end
    end)
    self.resizeGrip = grip
end

function Resizable:RestoreSize(fallback)
    local s = self.dbSize or fallback
    if s and s.w and s.h then self:SetSize(s.w, s.h) end
end

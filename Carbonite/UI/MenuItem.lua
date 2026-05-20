-- Carbonite | UI / MenuItem
-- Documented surface for the legacy Nx.MenuI menu-item object. The
-- actual menu rendering still happens through Nx.Menu in NxUI.lua;
-- this class lets new code build menu items by name and bind them
-- to data tables in a clean way:
--
--   local item = MenuItem:From(legacyItem)
--   item:SetText("Sample")
--   item:BindCheck(myDB, "ShowFoo")
--   item:BindSlider(myDB, "Opacity", 0, 1, 0.05)
--   item:Show(true)
--
-- The class is a thin object wrapper around the legacy item table.
-- We do NOT replace `setmetatable` chains because legacy code does
-- table iteration on items; we just expose well-named methods.

local Carbonite = _G.Carbonite

local MenuItem = {}
Carbonite.UI.MenuItem = MenuItem

local Methods = {}

function Methods:SetText(text)
    self.Text = text
end

function Methods:GetText() return self.Text end

function Methods:IsChecked()
    return self.Checked == true
end

function Methods:SetCheckedValue(v)
    self.Check = true
    self.Checked = v
    if self.Table and self.VarName then self.Table[self.VarName] = v end
end

-- Two-arg binding form: `item:BindCheck(table, "field")` reads the
-- current value out of the table and keeps it synced on changes.
function Methods:BindCheck(target, key)
    if type(target) ~= "table" or not key then return self end
    self.Check = true
    self.Table = target
    self.VarName = key
    self.Checked = target[key]
    return self
end

function Methods:GetSliderValue() return self.SliderPos end

function Methods:SetSliderValue(pos, minV, maxV, step)
    self.Slider = true
    if minV and maxV then
        self.SliderMin = math.min(minV, maxV)
        self.SliderMax = math.max(minV, maxV)
    end
    if step then self.Step = step end

    if self.Step then
        pos = math.floor(pos / self.Step + 0.5) * self.Step
    end
    if self.SliderMin then pos = math.max(pos, self.SliderMin) end
    if self.SliderMax then pos = math.min(pos, self.SliderMax) end
    self.SliderPos = pos

    if self.Table and self.VarName then self.Table[self.VarName] = pos end
end

-- Same as SetSliderValue but takes its initial value from a table.
function Methods:BindSlider(target, key, minV, maxV, step)
    if type(target) ~= "table" or not key then return self end
    self.Table = target
    self.VarName = key
    self:SetSliderValue(target[key] or minV or 0, minV, maxV, step)
    return self
end

-- false hides, -1 shows as disabled, any other value (or nil) shows.
function Methods:SetVisible(show)
    if show == false then self.ShowState = false
    elseif type(show) == "number" then self.ShowState = show
    else self.ShowState = 1 end
end

function Methods:IsVisible()
    return self.ShowState ~= false
end

-- Adopt an existing legacy item table and attach the new methods
-- without breaking Nx.Menu's iteration. Callers can use either the
-- new method names or the legacy ones interchangeably.
function MenuItem:From(legacyItem)
    if not legacyItem then return nil end
    for k, v in pairs(Methods) do
        if legacyItem[k] == nil then legacyItem[k] = v end
    end
    return legacyItem
end

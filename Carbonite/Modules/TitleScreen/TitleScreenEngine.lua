-- Carbonite | Modules / TitleScreen / TitleScreenEngine
-- The Carbonite splash that displays version + maintainer text on
-- login. Lifted out of Carbonite.lua; the public-facing
-- accessor TitleScreen.lua already proxies through Nx.Title.
--
-- The animation is driven by Nx.Proc tick callbacks (Init schedules
-- TickWait -> TickWait2 -> Tick). Methods stay on Nx.Title because
-- Nx.Proc dispatch and the SetupEverything callsite both expect
-- that table.

local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite")

---
-- Build the splash frame: dialog-bordered backdrop, centred logo,
-- version + "Maintained by" lines, then hand off to Nx.Proc for
-- the fade-in / fly-out animation.
--
function Nx.Title:Init()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f.NxInst = self
    self.Frm = f

    f:SetFrameStrata("HIGH")
    f:SetWidth(400)
    f:SetHeight(192)

    f:SetBackdrop({
        ["bgFile"]   = "Interface\\Buttons\\White8x8",
        ["edgeFile"] = "Interface\\DialogFrame\\UI-DialogBox-Border",
        ["tile"]     = true,
        ["tileSize"] = 16,
        ["edgeSize"] = 16,
        ["insets"]   = { ["left"] = 2, ["right"] = 2, ["top"] = 2, ["bottom"] = 2 },
    })
    f:SetBackdropColor(0, 0, .1, 1)

    -- Logo plate, centred in the splash.
    local lf = CreateFrame("Frame", nil, f, "BackdropTemplate")
    lf:SetWidth(256)
    lf:SetHeight(128)
    lf:SetPoint("CENTER", 0, 0)

    local tex = lf:CreateTexture()
    tex:SetTexture(Nx.Logo)
    tex:SetAllPoints(lf)
    lf.texture = tex

    -- Two text lines below the logo (version + maintainer credit).
    for n = 1, 2 do
        local fstr = f:CreateFontString()
        self["NXFStr" .. n] = fstr
        fstr:SetFontObject("GameFontNormal")
        fstr:SetJustifyH("CENTER")
        fstr:SetPoint("TOPLEFT", 0, -158 - (n - 1) * 14)
        fstr:SetWidth(400)
        fstr:Show()
    end

    local versionLine = format(NXTITLEFULL .. " |cffe0e0ff" .. L["Version"] .. " %d.%d Build %s",
        Nx.VERMAJOR, Nx.VERMINOR * 10, Nx.BUILD)
    self.NXFStr1:SetText(versionLine)
    self.NXFStr2:SetText("|cffe0e0ff" .. L["Maintained by"] .. " The community.")

    -- Start the animation pipeline.
    Nx.Proc:New(self, self.TickWait, 40)
end

---
-- First wait tick: kicks Map:StartupZoom and reschedules to the
-- second wait stage.
--
function Nx.Title:TickWait(proc)
    Nx.Map:StartupZoom()
    Nx.Proc:SetFunc(proc, self.TickWait2)
    return 30
end

---
-- Second wait tick: initialises animation state, optionally plays
-- the ready-check sound, then hands off to the per-frame Tick.
--
function Nx.Title:TickWait2(proc)
    self.X = 0
    self.Y = GetScreenHeight() * .4
    self.XV = 0
    self.YV = 0
    self.Scale       = .8
    self.ScaleTarget = .8
    self.Alpha       = 0
    self.AlphaTarget = 1

    if Nx.db.profile.General.TitleSoundOn then
        PlaySound(SOUNDKIT.READY_CHECK)
    end

    Nx.Proc:SetFunc(proc, self.Tick)
end

---
-- Per-frame Tick: fade in, then fly off-screen and fade out. Returns
-- -1 once finished so Nx.Proc cleans up.
--
function Nx.Title:Tick()
    local this = self.Frm

    -- The TitleOff option hides the splash but keeps the animation
    -- ticking so the rest of the SetupEverything pipeline still
    -- runs to completion.
    if not Nx.db.profile.General.TitleOff then
        this:Hide()
    end

    self.X = self.X + self.XV
    self.Y = self.Y + self.YV

    self.Scale = Nx.Util_StepValue(self.Scale, self.ScaleTarget, .8 / 60)

    this:SetPoint("CENTER", self.X / self.Scale, self.Y / self.Scale)
    this:SetScale(self.Scale)

    self.Alpha = Nx.Util_StepValue(self.Alpha, self.AlphaTarget, .8 / 60)
    this:SetAlpha(self.Alpha)

    if self.Alpha == 1 then
        -- Reached full opacity: fly to the top-right corner and fade out.
        local sw = GetScreenWidth()  / 2
        local sh = GetScreenHeight() / 2
        self.XV = (sw * .95 - self.X) / 80
        self.YV = (sh * .95 - self.Y) / 80

        self.ScaleTarget = .03
        self.AlphaTarget = 0
        return 1 * 60
    end

    if self.Alpha == 0 then
        this:Hide()
        return -1
    end
end

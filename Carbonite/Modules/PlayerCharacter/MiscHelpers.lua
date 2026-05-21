-- Carbonite | Modules / PlayerCharacter / MiscHelpers
-- Three tiny stand-alone helpers extracted from Carbonite.lua:
--
--   Nx:LootIt()          - debug helper used to auto-click the
--                          first gossip button (vendor / quest
--                          giver testing); LootHandler module
--                          dispatches to it.
--   Nx:Time()            - "monotonic" timestamp (time() * 100 + frac)
--                          used by UEvents row IDs so multiple events
--                          fired within the same wall-clock second
--                          still sort distinctly.
--   Nx:UnitIsPlusMob(u)  - true for elite / rareelite / worldboss
--                          classifications; used by Comm and the
--                          PlayerCharacter accessor.
--
-- Each stays on Nx because the external callers still go through
-- the Nx namespace.

function Nx:LootIt()
    local b = _G["GossipTitleButton1"]
    if b:IsVisible() then b:Click() end
end

function Nx:Time()
    local tm = time()

    if tm > self.TimeLast then
        self.TimeFrac = 0
    else
        self.TimeFrac = self.TimeFrac + 1
    end

    self.TimeLast = tm
    return tm * 100 + self.TimeFrac
end

function Nx:UnitIsPlusMob(target)
    local c = UnitClassification(target)
    return c == "elite" or c == "rareelite" or c == "worldboss"
end

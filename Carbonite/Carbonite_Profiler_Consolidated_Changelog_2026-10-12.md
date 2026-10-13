# Carbonite Changelog

## 2026-10-13 — Blizzard world-map shortcut hotfix

- Restored Alt+M opening and closing Blizzard's world map when Carbonite map replacement is enabled.
- Prevented an Alt-modified secondary world-map binding from overwriting the Blizzard-map shortcut. The alternate shortcut is installed after the Carbonite bindings.
- Routed the alternate shortcut through Carbonite's existing explicit Blizzard-map action, preserving the requested map when Alt is released before display handling completes.
- Made the map click handler honor Alt and the configured map preference for modified primary bindings. Disabling map replacement retains M for Blizzard and Alt+M for Carbonite.
- Preserved the shared quest-binding helper's four-argument interface and deferred binding updates during combat.

Changed source: `Carbonite/Modules/Map/MapEngine.lua`.

Validation: the complete Lua file parses under Lua 5.3; all 23 simulated binding checks pass. The previous file reproduces the reported binding failure. The changed code uses Lua 5.1-compatible syntax. Live Warcraft verification remains required.

Installation: close World of Warcraft, extract this changed-only package into `Interface/AddOns`, overwrite the included file, and restart the game. With **Use Carbonite Map instead of Blizzards** enabled, verify M opens Carbonite, Alt+M opens Blizzard, and a second Alt+M closes Blizzard.

## 2026-10-12 — Updates after the first profiler release

This changelog covers changes after `Carbonite-v12.1.0-00020-Profiler-Changed-Only.zip` through `Carbonite_Export_Hotfix_Changed_Only_vs_Master6_2026-10-12.zip`. Related updates are consolidated below, newest first.

### Latest changed-only package

- Prepared the cumulative changed-only package against `Carbonite-All-in-One-Retail-Classic-master(6).zip`, carrying the quest catalog integration, diagnostics redesign, and corrected Export/tooltip files.

### Export and tooltip hotfix

- Fixed both Export errors caused by calling `GetStringHeight()` on an EditBox.
- Sized exported reports using wrapped line count, font height, line spacing, and text insets so the complete report remains scrollable at supported text sizes.
- Fixed the diagnostic tooltip `SetText` argument error by supplying numeric alpha before the wrapping flag.

### Diagnostic interface redesign

- Added a shared diagnostic window with **Map**, **Quest**, and **Both** scopes and **Overview**, **Functions**, **Compare**, **Help**, and **Export** views.
- Put recording state, session measurements, quest activity, and suggested next steps on Overview; moved detailed comparisons, settings, and raw reports into separate views.
- Added ranked timing bars, explicit millisecond units, aligned numeric columns, and one zero-based scale within each selected view.
- Added adjustable text size, screen fitting, and stable snapshots. Refresh updates the displayed measurements; changing views keeps the same snapshot.
- Added the **Select report → Ctrl+C** workflow for copying complete reports, with client/build details, catalog counters, function timings, comparisons, and retained samples.
- Replaced competing Map profiler implementations with one measurement source shared by the scoped displays. Map and Quest recording states, references, and resets remain independent.
- Assigned quest-owned objective-area update timings to Quest diagnostics.
- Distinguished retained samples from earlier runs from current-session measurements. Earlier samples cannot become a new idle reference or silently enter current comparisons.
- Preserved earlier split Map captures within the shared sample capacity and identified older references requiring recapture.
- Kept unavailable Lua heap measurements distinct from measured zero values.
- Kept combined markers visible in both scopes and preserved the other scope's marker when clearing one scope.
- Updated `PROFILER.md` with the interface workflow, measurement definitions, comparison requirements, command reference, and measurement limits.

### Quest catalog display integration

- Integrated the supplied `QuestCatalog.lua` into every existing Quest client TOC and added the display bridge.
- Connected quest-window and Quest Watch titles and objectives to committed catalog snapshots, with Carbonite's established quest API as the fallback when catalog data is unavailable.
- Combined quest-event refresh requests and reused clean display snapshots without rescanning objectives on each read.
- Added catalog scan, refresh, and combined-request counters to Quest diagnostics and copyable reports. Catalog counters continue while optional timing capture is stopped.
- Corrected numeric objective-progress parsing and guarded restricted booleans and missing structured objective data.

### Help and addon options

- Added `/help profiler`, `/carb profiler help`, and `/carb help profiler` command guides, preserving normal native help for other arguments.
- Added options controls for recording, reports, sample capacity, markers, saved references, data clearing, and comparison self-tests.
- Separated controls from command help, grouped controls into readable sections, and replaced the dense help list with selectable topics, descriptions, examples, and a numbered capture guide.
- Restored **Maps → Diagnostics** through the Maps options provider used by modular and legacy registration. Quest diagnostics are available under **Quest Module → Diagnostics**.
- Preserved the existing Map, Minimap, Minimap Button, and 3D View options.

### Separate Map and Quest profiling

- Moved map/travel profiling into Carbonite and quest profiling into Carbonite.Quests, allowing Map capture to operate when Carbonite.Quests is disabled.
- Added scoped Map and Quest commands, reports, recording controls, saved references, and resets. The initial split used separate sample buffers; the later catalog/UI updates consolidated storage into a shared bounded buffer.
- Added quest-event counts and quest-handler timings so Quest diagnostics show quest processing alongside map activity.
- Added delayed hook-installation retries for components initialized after the profiler loads.
- Updated the affected client TOCs and profiler load order for the separate components.

### Validation

The release records document passing syntax checks, 396 simulated catalog integration checks, 743 simulated diagnostics behavior/migration checks, and focused Export/tooltip regressions. Simulated client fixtures covered Retail, Retail PTR, Forever, Mists Classic, TBC Classic, and Classic Era. Live Warcraft UI, quest-action, and taint validation remains required.


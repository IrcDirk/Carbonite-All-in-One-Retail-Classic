# Carbonite Quests Project Changelog

## 2026-09-01 — Classic quest-watch minimized-layout repair

- Completed missing `MinW` and `MinH` values when the shared quest-watch
  anchor creates its first minimized SavedVariables record.
- Added centralized validation and repair for partial or invalid saved window
  coordinates and dimensions before layout arithmetic or frame setters run.
- Preserved valid saved anchors, positions, dimensions, and scaling while
  retaining Carbonite's existing 125-by-28 minimized presentation.

### Validation

- Reproduced the reported Classic `NxQuestWatch` SavedVariables state and
  verified shared, independent, and partial normal-layout recovery paths.
- Lua parsing and three focused layout regression cases pass.

## 2026-09-01 — Carbonite minimap launcher boundary attachment

- Replaced the launcher's fixed 140x140 minimap geometry with the live Minimap
  width, height, center, scale, and shape used by each Warcraft client.
- Preserved the original visual overlap at Classic's 140x140 size while
  correctly attaching to Retail 12.1's 198x198 minimap boundary.
- Reprojects the launcher after Edit Mode resizing and Carbonite round/square
  mask changes, while preserving the user's chosen angle around the minimap.
- Added secret-value guards to the cursor and frame-coordinate drag path.
- Left Carbonite's collected minimap-button window behavior unchanged.

### Validation

- Boundary tests cover Retail and Classic sizes, round and square masks,
  saved-angle restoration, scaled cursor input, and non-Minimap parents.

## 2026-09-01 — Redundant tracked-quest destination marker removed

- Removed Carbonite's legacy `IconWayTarget` overlay while a quest is the
  active navigation target. Blizzard's live quest POI, or Carbonite's catalog
  fallback, remains the visible objective marker on both Carbonite map sizes.
- Preserved the tracked quest, route calculations, direction/distance state,
  quest blob, Blizzard-style objective pin, and full-map breadcrumb behavior.
- Left non-quest destination markers unchanged for manual waypoints and other
  navigation targets.

### Validation

- Regression coverage verifies the legacy marker is absent on combined,
  standalone, and full-size quest maps, including inside the objective blob.
- Non-quest target markers and routing remain present.

## 2026-09-01 — Blizzard-native quest-map provider compatibility

- Rechecked the implementation against the supplied Blizzard UI sources for
  Retail 12.1.0, Mists Classic 5.5.4, Burning Crusade Classic 2.5.6, and
  Classic Era 1.15.9.
- Made `C_QuestLog.GetQuestsOnMap` the shared authoritative coordinate feed,
  exactly as Blizzard does on all four clients.
- Restricted Retail's `GetNextWaypointForMap` fallback to the focused or
  super-tracked quest; watched non-active quests now use the normal map feed.
- Reproduced Retail's two-layer POIButton presentation (quest ring plus
  waypoint, in-progress, or completion glyph) on both Carbonite map sizes.
- Reproduced the legacy Blizzard numbered-POI texture and texture coordinates
  on Era, TBC, and Mists instead of attempting to use Retail-only atlases.
- Matched Blizzard's `questPOI` / legacy `questHelper` visibility gates and
  Retail map-indicator/bonus-objective filters, with feature detection rather
  than quest IDs or client-version branches.
- Probed the native `QuestPOIFrame` capability safely: Mists/Retail can use the
  native quest blob; clients without the frame retain Carbonite's catalog area
  fallback without a load-time error.
- Kept one accepted Blizzard point authoritative for its quest while retaining
  all Carbonite catalog points only when Blizzard publishes no usable point.

### Validation

- Added compatibility tests for Retail campaign/waypoint/completion POIs,
  legacy numbered POIs, CVars, map filters, and optional atlas fallback.
- Existing combined-minimap, standalone-minimap, full-map, phase projection,
  moving-arrow suppression, native-blob, scale retention, provider/renderer,
  and catalog fallback regressions remain passing.

## 2026-09-01 — Blizzard-style quest blob and single objective marker

- Mirrored Blizzard's `QuestDataProvider` model on both the full Carbonite map
  and the minimized Carbonite map: one live marker per watched quest at the
  coordinate published by `C_QuestLog`, alongside the native quest blob.
- Made a successfully projected live marker authoritative for the quest so
  repeated catalog locations (such as several possible object spawns) no
  longer create a row of duplicate objective pins.
- Kept Carbonite's catalog point and area-center markers as automatic fallbacks
  when Blizzard publishes no usable coordinate or the coordinate is rejected
  by map/instance isolation.
- Applied the behavior by API capability and quest identity; no quest name,
  objective name, or quest ID is hard-coded.

### Validation

- Regression coverage verifies identical behavior on combined, standalone,
  and full-size Carbonite maps; one live marker suppresses all repeated point
  pins while unavailable/rejected live data restores the catalog fallback.
- Parent-zone to child-phase projection, completion grouping, quest blobs,
  moving-arrow suppression, Lua parsing, and archive extraction all pass.

## 2026-08-21 — World Quest icons restricted to their owning zones

- Cross-checked every task-map result against `C_TaskQuest.GetQuestZoneID`
  before creating a Carbonite World Quest pin.
- Rejected watched, nearby, emissary, and map-indicator entries projected onto
  unrelated zone canvases by Blizzard's task feed.
- Preserved valid child-zone pins and the selected quest on its parent
  continent while removing stale cross-zone placements.
- Kept the restored World Quest List, current Ace libraries, Midnight maps,
  Delve handling, and taint-safe tracking calls unchanged.

### Validation

- Lua parsing and map-ownership regression tests passed for exact-zone,
  child-zone, continent, unrelated-zone, and projected-map-indicator cases.

## 2026-08-21 — World Quest List restored after the Ace/Midnight rebase

- Restored the Retail **Open World Quest List** entry to the Quest Watch menu.
- Restored the movable, resizable, sortable World Quest List with zone, reward,
  expiry, filtering, reward-detail tooltip, and current-zone support.
- Restored modern world-quest discovery, manual track/untrack actions, Blizzard
  watch-list synchronization, and one de-duplicated World Quest section in the
  Carbonite Quest Watch window.
- Reinstated taint-safe world-quest and super-track API wrappers required by the
  current Retail client.
- Preserved the newer Ace libraries, Midnight map/task filtering, Delve scenario
  rendering, quest-offer map icons, and packed quest-ID fixes.
- Retained feature guards so unsupported Classic clients do not expose or call
  the Retail-only World Quest List APIs.

### Validation

- Lua parsing passed for every restored source file.
- Retail/Classic availability-guard and taint-safe tracking smoke tests passed.
- Archive-scope checks confirmed the repair is limited to the quest-list code,
  its shared tracking helpers, localization, and this changelog entry.

## 2026-08-11 — Watched quest stability after quest acceptance

- Preserved the existing watched-quest set by stable `questID` while Blizzard
  re-indexes the quest log after `QUEST_ACCEPTED`.
- Rebuilt `CurQ`, `QIds`, and `RealQ` as one candidate snapshot and published
  them together only after the quest-log scan passed validation.
- Coalesced quest-accept event bursts into one delayed rebuild and removed the
  duplicate immediate/follow-up recording passes.
- Used the direct Classic `QUEST_ACCEPTED` quest ID when supplied, with legacy
  quest-log-index resolution retained as a compatibility fallback.
- Forced the completed snapshot through the watch-list refresh throttle and
  consolidated the distance/update timer so an older pass cannot suppress the
  corrected display.
- Retained the Delve scenario renderer and objective-count normalization from
  the 2026-08-10 patch unchanged.

### Validation

- Lua parsing passed for every top-level `Carbonite.Quests` source file.
- Runtime regression tests passed for transient missing watches, multiple
  quest IDs, authoritative removal, malformed/duplicate log snapshots, atomic
  publication, forced final redraw, refresh coalescing, and Retail/Classic
  `QUEST_ACCEPTED` payload selection.
- All Retail and Classic TOCs continue loading the same corrected quest source
  files; no client-specific TOC or saved-variable migration was required.

## 2026-08-10 — Intermittent duplicate objective progress

- Fixed quest objectives alternating between a single progress count and a
  duplicated count, such as `1/1 1/1 Obtain the arcane projector from Rommath`.
- Stopped the party-share serializer from rewriting the live objective text
  used by the watch window.
- Normalized count-first and count-last objective strings at the party
  communication boundary so each objective contains exactly one progress
  value.
- Preferred Blizzard's structured `numFulfilled` and `numRequired` fields,
  with legacy text parsing retained as a fallback.
- Added feature guards for clients without `C_QuestLog.GetQuestObjectives`.

### Validation

- Lua 5.1 parsing passed for all affected quest files.
- Count-first, count-last, duplicated, parenthesized, and bracketed progress
  formats passed normalization tests.
- Party serialization retained the original live objective text in a runtime
  test.
- The prior Retail Delve scenario renderer and its Classic fallback passed
  regression tests.

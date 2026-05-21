# Carbonite — Architecture notes

Living overview of the post-refactor codebase. Updated as the
codebase changes; see git history for the chronological view.

## High-level layout

```
Carbonite/                  - main addon
  Carbonite.lua             - thin entry (AceAddon lifecycle, locale init)
  Bindings.xml / *.toc      - WoW load manifests
  Compat/                   - WoW-version polyfills
  Core/                     - EventBus, DataPersistence, bootstrap
  UI/                       - reusable widgets (ToolBar, Mixin, Button)
  Data/                     - guide / flight / quest static data
  Modules/                  - functional modules; one folder per concern
    Map/                    - the map (largest module)
      MapEngine.lua         - legacy fat file (~15k lines, scheduled for breakup)
      Renderer.lua          - per-pass icon / line rendering + hover ticker
      Pin.lua               - Pin base class + Acquire/Release pool
      Layer.lua             - Layer registry (visibility groups for pins)
      MapProvider.lua       - PUBLIC API: third-party icon plug-in surface
      MapToolBar.lua        - registry layer for toolbar buttons
      AddonButtons.lua      - Questie / HandyNotes / RareScanner buttons
      Pins/<Kind>Pin.lua    - concrete Pin classes
    UI/                     - tooltips, fonts, skins, buttons
    Comm/                   - party communication
    Options/                - settings dialog
    Travel/                 - flight-path follower
    Gather/                 - gather notes overlay
    Quest/                  - quest watcher (note: QUEST data lives in
                              Carbonite.Quests subaddon, not here)
  Docs/                     - this folder

Carbonite.Notes/            - subaddon: notes plugin
Carbonite.Warehouse/        - subaddon: warehouse plugin
Carbonite.Quests/           - subaddon: quest plugin
Carbonite.Info/             - subaddon: info HUD (legacy, may be removed)
Carbonite.Punks/            - subaddon: PVP punks list (legacy, may be removed)
Carbonite.QuestExtractor/   - dev tool
```

## Plugin refactor

The three plugin subaddons were originally one giant Lua file each:

| Subaddon            | Original entry | After   | Reduction |
|---------------------|----------------|---------|-----------|
| Carbonite.Notes     | `NxFav.lua` 2401 | 82    | -97%      |
| Carbonite.Warehouse | `NxWarehouse.lua` 4017 | 231 | -94%      |
| Carbonite.Quests    | `NxQuest.lua` 14803 | 579  | -96%      |

Each was broken into named sibling files (`Init.lua`, `Options.lua`,
`MapIcons.lua`, etc.). The original file is now a thin entry holding
locale registration, the WoW-globals-as-locals block, API
compatibility shims, and namespace declarations. Concrete behavior
lives in siblings via `Nx.<Module>:Foo(...)`.

See [memory/feedback_legacy_relocate_pattern.md] in the team's auto-
memory for the validated recipe.

## Map subsystem

### Pin / Layer

The map's icon system is moving from "stamp pool icons each frame"
(legacy `Map:GetIconStatic`) to "long-lived Pin instances grouped
into named Layers" (`Map:AddIconPt` / Pin / Layer).

* **Pin** (`Modules/Map/Pin.lua`) — base class. `Pin.Define(kind, mixin)`
  registers a kind. `Pin.Acquire(kind, ...)` returns a recycled pin
  from the per-kind freelist (or allocates a fresh one). `Pin.Release`
  returns it to the freelist.
* **Layer** (`Modules/Map/Layer.lua`) — a named group of Pins.
  `Layer.Get(name)` returns the singleton. `Layer:Add(pin)`,
  `Layer:Clear()`, `Layer:SetVisible(bool)`. `Layer:Clear` is
  truncate-in-place to avoid GC pressure under heavy churn.
* **Renderer** (`Modules/Map/Renderer.lua`) — iterates every visible
  Layer each frame and stamps pin frames according to each Pin
  class's `drawMode`. Hosts the LINE-pin hover ticker that
  hit-tests cursor against drawn line segments and shows tooltips.

### MapProvider — public API

`Modules/Map/MapProvider.lua` wraps Pin / Layer in a public surface
for third-party addons. See [MapProvider.md](MapProvider.md).

### Toolbar buttons

`Modules/Map/MapToolBar.lua` is the registry layer; `AddonButtons.lua`
contains the integration buttons (Questie / HandyNotes /
RareScanner). Each:

* Left click toggles Carbonite's display flag for that integration
  + mirrors the change to the addon's own enabled state.
* Right click runs the addon-specific menu (Questie shows its
  cursor-anchored quest-type menu; HandyNotes / RareScanner open
  their Settings panel via `Settings.OpenToCategory`).
* Tooltip is rendered directly via `Nx.TooltipText:AddDoubleLine`
  rather than through `Nx:SetTooltipText`'s multi-line pipeline
  (latent bug: that pipeline silently dropped lines for some inputs
  during testing; root cause not pinned down).

The toolbar's right-click no longer always opens the bar's config
menu — buttons whose `TypeData.PassRightClick == true` receive the
right click in their handler instead.

## Integration plugins (`Carbonite.Notes/Integrations/`)

The three icon-overlay addons (HandyNotes, Questie, RareScanner)
each have a per-frame producer that walks the source addon's data
structures and emits Carbonite pins. Each maintains a small dirty-
check cache (last hash + last mapID + last pin count); a shared
helper `Nx.Notes:BustIntegrationCache(name)` knows the field layout
per integration and is used by toggle handlers + UI controls.

Patrol-path rendering: HandyNotes plugins that publish `point.routes`
arrays get drawn as line segments on the `!HandyNotesPath` layer.
Questie path data is scraped off `frame.data.lineFrames` (pixel
coords reverse-mapped from `WorldMapFrame:GetCanvas()`).

## Event bus

`Core/EventBus.lua` is a minimal subscribe / fire system. Used for
intra-addon notifications that don't make sense as Blizzard CVars
or WoW events.

Notable events:
* `CARBONITE_LOADED` — fires after all subaddon Inits run.
* `MAP_LAYER_VISIBILITY_CHANGED` — Layer:SetVisible side-effect.

## Things to be aware of

* `Nx.Map:CreateToolBar` is called multiple times during startup
  (the map module's own call, then Notes Init, then Warehouse Init).
  The reused Frm wipes orphaned `NxBut*` children on each rebuild so
  old buttons don't intercept clicks at the same positions.
* `Nx.Window:RecordLayoutData` guards against nil from `GetPoint()`
  on frames with no anchor (mid-drag edge case).
* `Renderer.lua` (line ~193) honors `pin.NXType` and `pin.NXData` when
  set on a pin instance — that's how pin-based quest icons keep
  routing through the legacy `t >= 9000` dispatcher in
  `MapEngine:IconOnEnter` / `:IconOnMouseDown` without any change to
  the dispatcher itself.
* `Renderer.lua` also runs `pin.onStamp(pin, frame)` after applying
  the standard texture / vertex color / texcoord, so pin classes
  that need per-pin custom frame setup (glow visibility, objective
  label, vertex-color overrides) don't have to bloat the renderer
  with class-specific branches. See `Carbonite.Quests/QuestProvider.lua`
  for the live example.
* Pin / Layer migration. Status:
  - Notes / HandyNotes / Questie / RareScanner integrations: pin-based.
  - Notes' selected-note pulse (`!Fav2`): legacy pool.
  - NxQuest icon producer: **fully ported**. Every POI / area /
    distance-arrow site flows through `Carbonite.Quests/QuestProvider.lua`
    via `Nx.Quest:AddPOI` / `Nx.Quest:AddArea`. Townsfolk
    (`data.Type == "manual"`) route to a smaller `!QUE_T` Carbonite
    layer matching Questie's native ~11px sizing.
  - `Nx.Quest:UpdateIcons` carries a fingerprint dirty-check at the
    top: `(mapId, super-tracked qid, hover identity, 10-tick
    bucket)`. When the fingerprint is unchanged the producer is
    skipped entirely — Renderer keeps rendering the persisted pin
    layer each frame from the previous build. `Nx.Quest:IconOnEnter`
    / `IconOnLeave` set `_iconDirty = true` so hover highlights
    redraw without waiting for the next 10-tick bucket.
* Per-pin width/height (`pin.w` / `pin.h`) is honored by the WP
  renderer. Two paths:
  - Default: `pin.w * scale` (with `wpMin` clamp). Used by any pin
    that wants a custom size on top of the renderer's icon-scale —
    integration-pin distance arrows etc.
  - `cls.rawSize = true` (class flag): pin.w / pin.h pass raw to the
    clip function and the center-anchored visibility cull is
    skipped. Used by Quest area-span pins where w/h are world units
    that get multiplied by ScaleDraw internally by ClipFrameTL.

# Carbonite Map Provider API

A small public surface for third-party addons (and Carbonite's own
plugins) to plug their icons into Carbonite's map. Wraps the internal
Pin / Layer system so callers don't have to reach into private modules.

The entry point is `Carbonite.Map:CreateProvider(name)`. Each provider
owns one named Layer and a set of Pin classes scoped to that provider,
so providers can't trample each other's pins.

---

## Quick start

```lua
local provider = Carbonite.Map:CreateProvider("MyAddon")

provider:DefinePin("Treasure", {
    tex      = "Interface\\Icons\\INV_Misc_Map02",
    w        = 16,
    h        = 16,
    drawMode = "WP",   -- "WP" world | "ZP" zone | "ZR" rect
})

function provider:OnMapChanged(mapID)
    self:Clear()
    for _, item in ipairs(myData[mapID] or {}) do
        self:Add("Treasure", item.wx, item.wy, {
            tip      = item.label,
            userData = item,
        })
    end
end
```

Carbonite invokes `OnMapChanged` when the player opens a new map or
changes dungeon level. The provider can also drive its own updates by
calling `provider:Add` / `provider:Clear` at any time.

---

## API reference

### `Carbonite.Map:CreateProvider(name)`

Returns a Provider singleton. Calling twice with the same `name`
returns the existing instance — callers don't need to cache it.

`name` must be a non-empty string. It's used as both the provider's
identity and the underlying Layer name (prefix `"Provider/"`).

### `provider:DefinePin(kind, opts)`

Register a pin class scoped to this provider. `kind` is a short string
used by `Add(...)`; internally Carbonite registers the class as
`"<providerName>:<kind>"` so providers can't collide on common names.

`opts` table:

| field      | type    | default | meaning                                                  |
|------------|---------|---------|----------------------------------------------------------|
| `tex`      | string  | nil     | Texture path used by every pin of this kind.             |
| `w`, `h`   | number  | `16`    | Pixel size at scale 1.                                   |
| `drawMode` | string  | `"WP"`  | `"WP"` world-point, `"ZP"` zone-point, `"ZR"` zone-rect, `"LINE"` two-point line. |
| `scale`    | number  | `1`     | Per-class scale multiplier.                              |
| `color`    | string  | nil     | Default `"AARRGGBB"` vertex color.                       |
| `alpha`    | number  | nil     | Base alpha.                                              |
| `alphaNear`| number  | nil     | Pulse alpha when the player is within 80yd.              |
| `frameLvl` | number  | nil     | Frame-level offset added to map base level.              |
| `clipKind` | string  | (auto)  | Clipping mode; defaults follow `drawMode`.               |
| `noDockMinimap` | bool | nil    | When true, hide pins overlapping the docked minimap.     |

Click / hover behavior is set per-pin via the `userData` plus the
provider's own `onClick` / `onEnter` overrides — see *Click routing*
below.

### `provider:Add(kind, wx, wy, opts)` → pin

Acquire a pin from the freelist (or allocate fresh), fill in fields,
add it to this provider's layer, and return it.

Required positional args: `kind` (defined via `DefinePin`), `wx`, `wy`.
For `"WP"` drawMode pass world coordinates from
`Nx.Map:GetWorldPos(mapID, x, y)`; for `"ZP"` / `"ZR"` pass zone-
percent.

`opts` is a flat table of pin fields. All optional:

| field       | meaning                                                       |
|-------------|---------------------------------------------------------------|
| `tip`       | Tooltip text. Supports `\n` for multi-line and `\t` for a right-aligned column on that line. |
| `color`     | Per-pin `"AARRGGBB"` string or `{r,g,b,a}` table.             |
| `tex`       | Per-pin texture override.                                     |
| `level`     | Per-pin frame-level offset.                                   |
| `mapID`     | The source map ID — required for some drawMode/clip combos.   |
| `userData`  | Arbitrary value carried back to onClick / onEnter callbacks.  |
| `x2`, `y2`  | Second endpoint (only for `"LINE"` drawMode).                 |

Returns the live pin. You can mutate `pin.<field>` afterwards; the
renderer reads each frame.

### `provider:Clear()`

Remove every pin from this provider's layer. Pin instances go back
into their per-kind freelist for reuse — calling `Add` again
afterwards is allocation-free.

### `provider:Each(fn)`

Iterate live pins; `fn` receives each pin in insertion order.

### `provider:Count()` → number

How many pins are currently in this provider's layer.

### `provider:SetEnabled(on)` / `provider:IsEnabled()`

Show or hide the whole provider's layer without dropping its pins.
Useful for "toggle this overlay" UI that should preserve state.

### `provider:GetLayerName()` → string

Internal layer name (`"Provider/<name>"`). Mostly useful for tests or
debug overlays.

### `provider:NotifyMapChanged(mapID)`

Tell the provider that the visible map has changed. Carbonite calls
this on every registered provider when its own `Map.MapId` flips, so
most providers won't call it themselves. Providers can call it
manually to drive updates from their own events.

If `mapID` differs from the last known value, the provider invokes
its `:OnMapChanged(mapID)` override (if defined) and updates
`self.currentMapID`.

### `provider:Refresh()`

Re-runs `:OnRefresh()` (if defined) or `:OnMapChanged(currentMapID)`
otherwise. Useful when the provider's underlying data changed
externally and it wants to rebuild without flipping the map.

---

## Hooks (define on the provider instance)

These are *not* methods on the API — define them on your provider
object after creation.

```lua
function provider:OnMapChanged(mapID)   -- map switched
function provider:OnRefresh()           -- :Refresh() explicit call
```

---

## Click routing

Pins added by providers don't get clicks for free yet — the click
dispatcher in `MapEngine:IconOnMouseDown` is currently a switch
keyed on iconType strings, with one branch per built-in integration.
Provider pins use the same `iconType` field as legacy pins (set to
the layer name); to receive clicks, the addon needs to add a branch
or hook in. A first-class `provider:DefinePin{ onClick = ... }`
callback is on the roadmap. See `Carbonite.Modules.Map.MapProvider`
source for the current state.

---

## Layering & coexistence

* Each provider's pins live in their own Layer (`"Provider/<name>"`),
  so two providers can register a `"Treasure"` kind without colliding.
* Pin classes are global to Carbonite by full kind name
  (`"<providerName>:<kind>"`), so they don't collide with built-in
  pins (`Note`, `!HandyNotesPath`, `!QuestiePath`, etc.).
* The renderer iterates every visible Layer each frame — there's no
  per-provider ordering today. Pins draw in the order their Layer is
  encountered in the registry.

---

## What's next on the roadmap

* First-class click / hover callbacks declared at `DefinePin` time
  (currently you have to plug into `MapEngine:IconOnMouseDown` by
  iconType).
* Carbonite.Quests's own icon producer should be the first internal
  consumer of this API (currently uses the legacy direct-stamp path
  via `map:GetIconStatic`).

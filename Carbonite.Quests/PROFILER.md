# Carbonite Map and Quest Diagnostics

Open **Carbonite Options → Maps → Diagnostics** or **Quest Module → Diagnostics**,
then choose **Open diagnostics window**. Chat shortcuts are
`/carb profiler map report` and `/carb profiler quest report`.

## Record and share an issue

1. Choose **Map**, **Quest**, or **Both** in the diagnostic window.
2. Click **Start recording**.
3. Reproduce the issue for about 60 seconds.
4. Click **Stop recording**.
5. Review **Overview**, **Functions**, and **Compare**.
6. Click **Select report**, then press **Ctrl+C** to copy the complete report.

Recording starts stopped after every reload. Existing saved samples remain.
The display is a snapshot; **Refresh** updates it. Changing tabs keeps the same
snapshot, so values do not change underneath the reader.

## Views

| View | What it shows |
| --- | --- |
| Overview | Recording state, measured calls, slow calls, largest call, retained samples, and a suggested next step. Quest also shows quest count, full scans, and combined refresh requests. |
| Functions | Calls, average duration, largest duration, and slow calls for each measured function. Largest calls appear first. Bars start at zero and share one scale within the selected view. Choose Both to compare all functions together. |
| Compare | A saved idle reference and adjacent recent sample windows. Values show the reference, current average, absolute change in milliseconds, and relative change. |
| Help | Capture instructions, measurement definitions, and one command with its description at a time. |
| Export | A selectable full report containing timings, comparisons, client/build details, catalog counters, installed measurements, and retained samples. |

Use **Advanced** in the options panel to adjust the diagnostic window text size,
set the shared sample capacity, or clear this view's captured data.

## Read the measurements

| Label | Meaning |
| --- | --- |
| Measured calls | Successful measured function calls since reload or this view's data reset. A parent function may include other measured functions. |
| Slow calls | Calls lasting at least 8 ms. This threshold identifies calls to examine; it does not confirm a fault. |
| Largest call | The longest observed function call this session, in milliseconds. |
| Average | Total inclusive duration divided by all successful measured calls for that function. |
| Retained samples | Saved detail from this or earlier runs. The overview separately identifies samples from this session. |
| Requests combined | Quest refresh requests combined by the catalog before work was scheduled. |
| Review increase | A comparison threshold was exceeded. Inspect the change and reproduce it before drawing a conclusion. |
| Within comparison thresholds | No configured comparison threshold was exceeded. This does not guarantee smooth frames. |
| Waiting for samples | There is insufficient evidence for that comparison. This is not a performance verdict. |
| Not available / Not measured | The metric is unavailable or has not been observed. It is not presented as a measured zero. |

Timings are inclusive: parent calls include child work. Do not sum their durations
as frame cost. Lua measurements do not measure GPU frame time.

Every successful wrapped call contributes to timing totals. Raw map samples are
retained once per function per 250 ms, plus every call lasting at least 8 ms.
Consequently, map sample-window averages favor slow calls and differ from the
all-call averages on **Functions**.

Quest catalog counters continue while optional timing capture is stopped.
Recorded Lua heap changes concern the shared Lua heap, not allocations owned
solely by a function. Map/travel heap changes, refresh counts, and duplicate
counts are not measured.

## Compare against an idle reference

1. Start recording while idle, with the same map and tracking configuration.
2. Wait until at least one function has eight retained samples from this session.
3. Open **Compare** and click **Save idle reference**.
4. Reproduce the issue and collect at least eight new samples for the function.
5. Stop recording, refresh, and review the changes.

Reference controls are also available in **Options → Diagnostics → Compare**.
Map and Quest have separate references. In **Both**, choose Map or Quest to inspect
references saved separately; an unscoped `baseline set` saves a combined reference.

A timing comparison requires both a 50% increase and an increase of at least
0.5 ms to request review. The shared Lua heap-change comparison threshold is 32 KB.
Recent-window comparisons require eight samples total per function.
Reference comparisons require eight new samples per function after the reference.
Both comparison types use this session's retained samples. Earlier samples remain
available in the export but cannot silently become a fresh idle reference.

A reference from a different client or addon build is marked incompatible.
Save a fresh idle reference on the current build.

## Chat shortcuts

Replace `map` with `quest` for quest measurements. Omitting the scope applies the
command to both views where supported. Bracketed arguments are optional.

| Command | Purpose |
| --- | --- |
| `/carb profiler map on` | Start Map recording. |
| `/carb profiler map off` | Stop Map recording. |
| `/carb profiler quest on` | Start Quest recording. |
| `/carb profiler quest off` | Stop Quest recording. |
| `/carb profiler map report` | Open the Map overview. |
| `/carb profiler quest report` | Open the Quest overview. |
| `/carb profiler map view` | Alias for `report`. |
| `/carb profiler map export` | Open the full Map report. |
| `/carb profiler map status` | Print recording state and retained sample count. |
| `/carb profiler map mark [label]` | Label a moment while recording. |
| `/carb profiler map baseline set [label]` | Save the latest idle window as a reference. |
| `/carb profiler map baseline status` | Check whether a reference is saved. |
| `/carb profiler map baseline clear` | Remove this view's reference. |
| `/carb profiler map clear` | Clear this view's samples, timing totals, and reference. Quest clear also resets catalog counters. |
| `/carb profiler limit [100-1000]` | Set the shared sample capacity. |
| `/carb profiler selftest` | Check the comparison calculations. |
| `/carb profiler map help` | Print a focused command guide. |
| `/carb profiler help` | Print the combined command guide. |
| `/carb help profiler` | Alternate command-guide shortcut. |
| `/help profiler` | Command guide through the existing native-help shortcut. |

Samples share a bounded buffer of 100–1000 entries; the default is 500.
Lowering capacity removes the oldest entries. Saved samples and references persist
across reloads. Session timing totals reset on reload or data clear.
Map capture operates with Carbonite.Quests disabled.

## Design basis

Common tasks and summary information appear first; specialized settings and raw
records are revealed in separate views. Recording and comparison states use explicit
text alongside color. Numeric columns include units, and bars share a zero baseline.
These choices apply the principles described in:

- [Nielsen Norman Group: Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/)
- [Nielsen Norman Group: Recognition and Recall](https://www.nngroup.com/articles/recognition-and-recall/)
- [W3C: Understanding Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color)

The layout preview uses example measurements and simulated fonts/button skins.
Check the final font and control layout in Warcraft.

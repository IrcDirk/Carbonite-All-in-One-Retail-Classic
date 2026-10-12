# Carbonite quest and map profiler

Integrated into Carbonite v12.1.0-00020. Install the addon folders from this
archive in Interface/AddOns, replacing the matching existing files, then reload.
Carbonite.Quests must be enabled for the profiler to load. Do not also load a
separate copy of the profiler.

Monitoring starts disabled after every login/reload.

## Capture

1. `/carb profiler clear`
2. `/carb profiler on`
3. Reproduce the behavior for 30–60 seconds with the Carbonite map visible.
4. `/carb profiler off`
5. `/carb profiler report` — select and copy the report.

For comparison, capture an idle period, run `/carb profiler baseline set idle`,
and then reproduce the issue in the same session. `/carb profiler mark [label]`
adds a marker. `/carb profiler status` shows current state;
`/carb profiler limit 1000` raises the retained-entry limit from 500 to 1000.
`/carb profiler selftest` checks the comparison analyzer.

## Measurements and limits

Quest log, watch/list windows, quest icons, map updates, tiles, overlays,
minimap, tracking, routing, and travel path calculations are measured when
the corresponding Carbonite methods exist. The report lists installed hooks.
Session summaries count every successful measured call, with average/maximum
inclusive duration and slow-call counts. Map samples are retained at most once
per boundary per 250ms, except calls taking at least 8ms are always retained
within the bounded buffer. Session summaries reset on reload or clear.
Raw samples and baselines persist in Carbonite's existing NXData saved profile
at Debug.QuestProfiler. No additional SavedVariables declaration is needed.

Nested timings overlap and must not be summed. Map memory readings, refresh
counts, and duplicate counts are not measured. Quest memory readings show
shared Lua heap changes, not attributable allocations. Timings measure Lua
work, not GPU frame time. Profiling adds overhead while enabled. Failed calls
retain their original error behavior and are not sampled. Reports are copied
manually; this component does not write text files to the WoW Logs folder.

## Validation

Archive integrity and all seven quest TOC load entries were checked. Mock
runtime checks cover disabled mode, nil return preservation, errors, sampling,
slow calls, buffer limits, baseline comparison, report output, and clearing.
In-game validation remains required for each client. No stuttering fix is
claimed by this diagnostic package. Base addon version remains v12.1.0-00020.

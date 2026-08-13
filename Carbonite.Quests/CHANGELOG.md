# Carbonite Quests Project Changelog

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

# Carbonite Quests Project Changelog

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

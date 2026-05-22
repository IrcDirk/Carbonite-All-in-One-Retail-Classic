#!/usr/bin/env python3
"""Audit (and optionally backfill) retail quest Start coords against MoP.

Carbonite.Quests/Data/retail/Quests*.lua ships with mis-extracted Start
entries for some quests -- the canonical case is 9663 "The Kessel Run"
where Start lists NPC 17069 in Eastern Plaguelands (mapId 23) but the
quest actually starts and ends at NPC 17649 in Bloodmyst (mapId 106).
The End row was correct, only Start was wrong; the extractor likely
attributed the wrong NPC.

MoP's bundled DB uses the same mapId numbering as retail and is the
known-good reference (verified during the End-backfill pass). This
script:

  1. Builds qid -> Start from both retail and MoP.
  2. For each qid present in both, classifies the diff:
       MATCH         -- byte-equal Start strings
       NPC_MISMATCH  -- different turn-in NPC ID at front of Start
       ZONE_MISMATCH -- same NPC but different zone (less common)
       COORD_DRIFT   -- same NPC + zone but x/y differ by >1.0%
       RETAIL_BROKEN -- retail Start matches the `<npc>|0|32|0.00|0.00`
                       sentinel that the End-backfill pass cleaned up,
                       but Start wasn't included in that pass.
  3. Reports counts; with --apply also rewrites retail Start to MoP's
     value for the high-confidence categories (NPC_MISMATCH and
     RETAIL_BROKEN). ZONE_MISMATCH and COORD_DRIFT are reported but not
     auto-applied -- a small zone change might be intentional (retail
     phasing) or might still be wrong; print first, decide manually.

Run from repo root:
    python3 scripts/audit_quest_starts.py             # report only
    python3 scripts/audit_quest_starts.py --apply     # backfill
    python3 scripts/audit_quest_starts.py --show-list # dump every mismatch
"""

from __future__ import annotations
import argparse, glob, os, re, sys

DATA = os.path.join(os.path.dirname(__file__), os.pardir, "Carbonite.Quests", "Data")
RETAIL_GLOB = os.path.join(DATA, "retail", "Quests*.lua")
MOP_GLOB    = os.path.join(DATA, "mop",    "Quests*.lua")

PAT_HEADER  = re.compile(r'^(?P<lead> {8})\[(?P<qid>\d+)\]\s*=\s*\{', re.M)
PAT_START   = re.compile(r'(?P<lead>\s*Start\s*=\s*")(?P<val>[^"]*)(?P<tail>")')
PAT_END     = re.compile(r'(?P<lead>\s*End\s*=\s*")(?P<val>[^"]*)(?P<tail>")')
BROKEN      = re.compile(r'^-?\d+\|0\|32\|0\.00\|0\.00$')


def iter_entries(src: str):
    """Yield (qid, body_lo, body_hi) for each top-level `[QID] = { ... }`
    block. body_lo = position of opening `{`; body_hi = one past the
    matching `}`. Mirrors backfill_quest_ends.iter_entries."""
    for m in PAT_HEADER.finditer(src):
        i = m.end() - 1
        depth = 0
        start = i
        n = len(src)
        while i < n:
            c = src[i]
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0:
                    yield int(m.group('qid')), start, i + 1
                    break
            i += 1


def parse_se(val: str):
    """`<npc>|<zone>|<typ>|<x>|<y>` -> (npc, zone, typ, x, y) or None.

    Some entries have trailing `|w|h` or other fields; we only need the
    first five. Returns None when the head doesn't parse.
    """
    if not val:
        return None
    parts = val.split('|')
    if len(parts) < 5:
        return None
    try:
        npc  = parts[0]
        zone = parts[1]
        typ  = parts[2]
        x    = float(parts[3])
        y    = float(parts[4])
    except ValueError:
        return None
    return npc, zone, typ, x, y


def build_index(glob_pat: str) -> dict[int, tuple[str | None, str | None]]:
    """qid -> (start_string_or_None, end_string_or_None)."""
    out: dict[int, tuple[str | None, str | None]] = {}
    for path in sorted(glob.glob(glob_pat)):
        with open(path) as f:
            src = f.read()
        for qid, lo, hi in iter_entries(src):
            sm = PAT_START.search(src, lo, hi)
            em = PAT_END.search(src, lo, hi)
            start_val = sm.group('val') if sm else None
            end_val   = em.group('val') if em else None
            out[qid] = (start_val, end_val)
    return out


def ends_agree(retail_end: str | None, mop_end: str | None) -> bool:
    """End rows agree on NPC + zone (ignoring sub-yard coord drift) ->
    the two DBs are talking about the same quest. The strongest signal
    for "this is a Start extraction bug, not Cata renumbering"."""
    if not retail_end or not mop_end:
        return False
    if BROKEN.match(retail_end) or BROKEN.match(mop_end):
        return False
    rp = parse_se(retail_end)
    mp = parse_se(mop_end)
    if rp is None or mp is None:
        return False
    return rp[0] == mp[0] and rp[1] == mp[1]


def classify(retail_start: str | None, mop_start: str | None,
             retail_end: str | None, mop_end: str | None) -> str:
    if retail_start is None or mop_start is None:
        return "MISSING"
    if retail_start == mop_start:
        return "MATCH"
    if BROKEN.match(retail_start) and not BROKEN.match(mop_start):
        # Sentinel that the End-backfill pass left behind in Start.
        # End agreement still distinguishes "same quest, broken Start"
        # vs "Cata renumbered into a Start-only sentinel" -- but in
        # practice almost all RETAIL_BROKEN rows do agree on End.
        return "RETAIL_BROKEN_SAME_QUEST" if ends_agree(retail_end, mop_end) else "RETAIL_BROKEN_DIFF_QUEST"
    rp = parse_se(retail_start)
    mp = parse_se(mop_start)
    if rp is None or mp is None:
        return "UNPARSEABLE"
    r_npc, r_zone, _, r_x, r_y = rp
    m_npc, m_zone, _, m_x, m_y = mp
    same_quest = ends_agree(retail_end, mop_end)
    if r_npc != m_npc:
        # Same quest with different Start NPC = extraction bug (this is
        # the 9663 case). Different End too = Cata reused the questID
        # for a new quest, both Start and End legitimately differ.
        return "NPC_MISMATCH_SAME_QUEST" if same_quest else "NPC_MISMATCH_DIFF_QUEST"
    if r_zone != m_zone:
        return "ZONE_MISMATCH_SAME_QUEST" if same_quest else "ZONE_MISMATCH_DIFF_QUEST"
    if abs(r_x - m_x) > 1.0 or abs(r_y - m_y) > 1.0:
        return "COORD_DRIFT"
    return "MATCH"


# Categories that --apply rewrites. Only the *_SAME_QUEST variants --
# diff-quest rows mean Blizzard renumbered the questID in Cata and the
# retail row is legitimately different content. RETAIL_BROKEN_SAME_QUEST
# is the leftover from the End-backfill pass that didn't touch Start.
AUTO_APPLY = {"NPC_MISMATCH_SAME_QUEST", "RETAIL_BROKEN_SAME_QUEST"}


def apply_fixes(fixes: dict[int, str]) -> int:
    """fixes: qid -> new Start string. Rewrites retail files in place
    and returns the number of rows actually changed."""
    changed = 0
    for path in sorted(glob.glob(RETAIL_GLOB)):
        with open(path) as f:
            src = f.read()
        out = []
        cursor = 0
        for qid, lo, hi in iter_entries(src):
            if qid not in fixes:
                continue
            sm = PAT_START.search(src, lo, hi)
            if not sm:
                continue
            new_val = fixes[qid]
            # Emit everything up through the old value, then the new
            # value, then continue past the closing quote.
            val_lo = sm.start('val')
            val_hi = sm.end('val')
            out.append(src[cursor:val_lo])
            out.append(new_val)
            cursor = val_hi
            changed += 1
        out.append(src[cursor:])
        with open(path, 'w') as f:
            f.write(''.join(out))
    return changed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true',
                    help='rewrite retail files for NPC_MISMATCH + RETAIL_BROKEN')
    ap.add_argument('--show-list', action='store_true',
                    help='list every non-MATCH qid')
    args = ap.parse_args()

    print("Indexing retail Quests...", file=sys.stderr)
    retail = build_index(RETAIL_GLOB)
    print(f"  {len(retail)} entries", file=sys.stderr)
    print("Indexing MoP Quests...", file=sys.stderr)
    mop = build_index(MOP_GLOB)
    print(f"  {len(mop)} entries", file=sys.stderr)

    counts: dict[str, int] = {}
    fixes: dict[int, str] = {}
    examples: dict[str, list[tuple[int, str, str]]] = {}

    for qid, (r_start, r_end) in retail.items():
        if qid not in mop:
            continue
        m_start, m_end = mop[qid]
        cat = classify(r_start, m_start, r_end, m_end)
        counts[cat] = counts.get(cat, 0) + 1
        if cat in AUTO_APPLY and m_start:
            fixes[qid] = m_start
        if cat != "MATCH":
            examples.setdefault(cat, []).append((qid, r_start or "", m_start or ""))

    print()
    print("Start coord comparison (retail vs MoP shared questIDs):")
    order = (
        "MATCH",
        "RETAIL_BROKEN_SAME_QUEST",
        "RETAIL_BROKEN_DIFF_QUEST",
        "NPC_MISMATCH_SAME_QUEST",
        "NPC_MISMATCH_DIFF_QUEST",
        "ZONE_MISMATCH_SAME_QUEST",
        "ZONE_MISMATCH_DIFF_QUEST",
        "COORD_DRIFT",
        "UNPARSEABLE",
        "MISSING",
    )
    for cat in order:
        if counts.get(cat):
            print(f"  {cat:28s} {counts[cat]:6d}")

    if args.show_list:
        for cat, rows in examples.items():
            if cat == "MATCH":
                continue
            print(f"\n--- {cat} ({len(rows)}) ---")
            for qid, r, m in rows[:200]:
                print(f"  {qid:7d}  retail={r!r}  mop={m!r}")
            if len(rows) > 200:
                print(f"  ... +{len(rows) - 200} more")
    else:
        for cat in order:
            if cat == "MATCH":
                continue
            rows = examples.get(cat) or []
            if not rows:
                continue
            print(f"\n  {cat} samples (5 of {len(rows)}):")
            for qid, r, m in rows[:5]:
                print(f"    {qid:7d}  retail={r!r}  mop={m!r}")

    if args.apply:
        n = apply_fixes(fixes)
        print(f"\nApplied: rewrote {n} Start values across retail files.")
    elif fixes:
        print(f"\n{len(fixes)} rows are candidates for --apply"
              f" (NPC_MISMATCH + RETAIL_BROKEN).")


if __name__ == '__main__':
    sys.exit(main() or 0)

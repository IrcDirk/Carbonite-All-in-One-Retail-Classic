#!/usr/bin/env python3
"""Backfill broken/missing retail quest data from MoP shards.

Carbonite.Quests/Data/retail/Quests*.lua ships with ~12.7k entries whose
End is the sentinel `<npcid>|0|32|0.00|0.00` -- a port artifact that
preserved the turn-in NPC ID but zeroed the map/x/y. A subset of retail
entries also drop the Objectives table entirely. MoP data uses the same
mapId numbering as retail and contains real coords/objectives for most
of those entries; this script copies them in.

Two passes per retail entry:
  1. End coord: if retail End matches the broken sentinel AND MoP has a
     non-broken End AND both name the same turn-in NPC, swap MoP's End
     string into the retail string.
  2. Objectives: if retail has no Objectives field AND MoP does, splice
     MoP's Objectives = { ... } block in just after the End line, with
     identical indentation.

Run from repo root:
    python3 scripts/backfill_quest_ends.py [--apply]

Without --apply the script reports counts per file but writes nothing.
With --apply it rewrites the retail data files in place.
"""

from __future__ import annotations
import argparse, glob, os, re, sys

DATA = os.path.join(os.path.dirname(__file__), os.pardir, "Carbonite.Quests", "Data")
RETAIL_GLOB = os.path.join(DATA, "retail", "Quests*.lua")
MOP_GLOB    = os.path.join(DATA, "mop",    "Quests*.lua")

# Top-level entry header. Entries sit at exactly 8 spaces of indent
# (one level inside the outer Carbonite.Quests table); nested table
# headers use deeper indents.
PAT_HEADER     = re.compile(r'^(?P<lead> {8})\[(?P<qid>\d+)\]\s*=\s*\{', re.M)
PAT_END        = re.compile(r'(?P<lead>\s*End\s*=\s*")(?P<val>[^"]*)(?P<tail>")')
PAT_OBJECTIVES = re.compile(r'^(?P<lead>\s*)Objectives\s*=\s*\{', re.M)
BROKEN         = re.compile(r'^\d+\|0\|32\|0\.00\|0\.00$')


def iter_entries(src: str):
    """Yield (qid, body_start, body_end_exclusive) for each top-level
    `[QID] = { ... }` block. body_start = position of opening `{`;
    body_end = one past the matching `}`.
    """
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


def find_objectives_block(src: str, lo: int, hi: int):
    """If the entry contains an Objectives = { ... } sub-table, return
    (block_start, block_end_exclusive) covering the full statement
    including the trailing comma and newline. None otherwise."""
    om = PAT_OBJECTIVES.search(src, lo, hi)
    if not om:
        return None
    # Walk braces from the opening `{` after `Objectives = `.
    i = om.end() - 1
    depth = 0
    n = hi
    while i < n:
        c = src[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                # Consume optional trailing comma and a single newline.
                j = i + 1
                if j < n and src[j] == ',':
                    j += 1
                if j < n and src[j] == '\n':
                    j += 1
                return om.start(), j
        i += 1
    return None


def npc_of(end: str) -> str | None:
    """First `|`-segment of an End string is the turn-in NPC id (signed
    int; negative for "object" turn-ins). Returns the raw token so the
    sign and exact characters are compared verbatim."""
    if not end:
        return None
    head = end.split('|', 1)[0]
    return head or None


def build_mop_index():
    """qid -> (end_string_or_None, objectives_text_or_None).
       end_string is None when MoP's End is itself broken. objectives_text
       is the verbatim `Objectives = { ... },\n` substring or None.
    """
    out: dict[int, tuple[str | None, str | None]] = {}
    for path in sorted(glob.glob(MOP_GLOB)):
        with open(path) as f:
            src = f.read()
        for qid, lo, hi in iter_entries(src):
            em = PAT_END.search(src, lo, hi)
            end_val = None
            if em:
                v = em.group('val')
                if not BROKEN.match(v):
                    end_val = v
            obj_text = None
            ob = find_objectives_block(src, lo, hi)
            if ob:
                obj_text = src[ob[0]:ob[1]]
            if end_val or obj_text:
                out[qid] = (end_val, obj_text)
    return out


def reindent_objectives(text: str, target_indent: str) -> str:
    """MoP's Objectives block uses some indent; retail entries use 12
    spaces (one level deeper than the entry header's 8). Rewrite the
    leading whitespace of every line to match target_indent on the
    `Objectives = {` line, preserving relative indentation."""
    lines = text.split('\n')
    # First non-empty line is `<indent>Objectives = {`
    src_indent = ''
    for ln in lines:
        if ln.strip():
            src_indent = ln[:len(ln) - len(ln.lstrip())]
            break
    if src_indent == target_indent:
        return text
    if not src_indent:
        return text
    out = []
    for ln in lines:
        if ln.startswith(src_indent):
            out.append(target_indent + ln[len(src_indent):])
        else:
            out.append(ln)
    return '\n'.join(out)


def process_retail(path: str, mop: dict, apply: bool):
    with open(path) as f:
        src = f.read()

    edits = []  # list of (start, end, replacement)
    stats = {
        'entries': 0,
        'end_patched': 0,
        'end_skip_missing_mop': 0,
        'end_skip_npc_mismatch': 0,
        'end_skip_already_ok': 0,
        'obj_patched': 0,
        'obj_skip_already_has': 0,
        'obj_skip_missing_mop': 0,
    }

    for qid, lo, hi in iter_entries(src):
        stats['entries'] += 1
        mop_end, mop_obj = mop.get(qid, (None, None))

        em = PAT_END.search(src, lo, hi)
        if em:
            val = em.group('val')
            if BROKEN.match(val):
                if not mop_end:
                    stats['end_skip_missing_mop'] += 1
                elif npc_of(val) != npc_of(mop_end):
                    stats['end_skip_npc_mismatch'] += 1
                else:
                    edits.append((em.start('val'), em.end('val'), mop_end))
                    stats['end_patched'] += 1
            else:
                stats['end_skip_already_ok'] += 1

        # Objectives backfill: only when retail has none and MoP has one.
        if find_objectives_block(src, lo, hi) is not None:
            stats['obj_skip_already_has'] += 1
        elif mop_obj is None:
            stats['obj_skip_missing_mop'] += 1
        else:
            # Splice MoP's Objectives block in just before the entry's
            # closing `}`. Retail entries use 12 spaces for body lines;
            # rewrite MoP's indent to match.
            target_indent = ' ' * 12
            obj_text = reindent_objectives(mop_obj, target_indent)
            if not obj_text.endswith('\n'):
                obj_text += '\n'
            # Find the closing `}` of the entry body. iter_entries gave
            # us hi (one past `}`); we want to insert right before the
            # line containing that `}`.
            close_pos = hi - 1  # position of `}`
            # Walk back to the start of the line holding the `}`.
            line_start = src.rfind('\n', 0, close_pos) + 1
            edits.append((line_start, line_start, obj_text))
            stats['obj_patched'] += 1

    if edits and apply:
        out = []
        cursor = 0
        for vstart, vend, repl in sorted(edits):
            out.append(src[cursor:vstart])
            out.append(repl)
            cursor = vend
        out.append(src[cursor:])
        with open(path, 'w') as f:
            f.write(''.join(out))

    return stats


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true',
                    help='Actually rewrite files (default: dry-run).')
    args = ap.parse_args()

    print("Indexing MoP data...")
    mop = build_mop_index()
    print(f"  MoP entries indexed: {len(mop)}")
    print()

    keys = ['entries', 'end_patched', 'end_skip_npc_mismatch',
            'end_skip_missing_mop', 'end_skip_already_ok',
            'obj_patched', 'obj_skip_already_has', 'obj_skip_missing_mop']
    head = ['file', 'entries', 'end+', 'end-npc', 'end-miss', 'end-ok',
            'obj+', 'obj-has', 'obj-miss']
    fmt = '{:<28}' + '{:>10}' * (len(head) - 1)
    print(fmt.format(*head))

    totals = {k: 0 for k in keys}
    for path in sorted(glob.glob(RETAIL_GLOB)):
        stats = process_retail(path, mop, args.apply)
        name = os.path.basename(path)
        print(fmt.format(name, *[stats[k] for k in keys]))
        for k in keys:
            totals[k] += stats[k]

    print()
    print(fmt.format('TOTAL', *[totals[k] for k in keys]))
    print()
    if not args.apply:
        print("Dry-run only. Re-run with --apply to write changes.")
    else:
        print("Applied. Verify with `git diff` before committing.")


if __name__ == '__main__':
    sys.exit(main())

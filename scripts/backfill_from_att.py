#!/usr/bin/env python3
"""Backfill remaining broken retail quest End coords from ATT (option b).

This runs AFTER backfill_quest_ends.py (which uses MoP). It targets the
post-MoP quests still bearing `<npcid>|0|32|0.00|0.00`.

Strict-match rule (the "option b" guard):
    Only patch when ATT's `qgs={...}` includes the SAME NPC id that
    retail's broken End names. The questgiver and turn-in NPC are the
    same person for short fetch quests, which is the case ATT's
    `coords` field describes faithfully. Quests with different start
    and end NPCs are intentionally skipped -- ATT's coord would point
    at the start, not the turn-in.

uiMapID handling: retail bundled quest data already uses Blizzard
uiMapIDs as its mapId (e.g. Azuremyst Isle = 97). ATT also uses
Blizzard uiMapIDs. So no conversion is needed; we only validate that
the target mapId is one that retail quest data is already using
elsewhere (i.e. known-good for `GetWorldPos`).

Run from repo root:
    python3 scripts/backfill_from_att.py [--apply]
"""

from __future__ import annotations
import argparse, glob, os, re, sys

DATA = "Carbonite.Quests/Data"
RETAIL_GLOB = f"{DATA}/retail/Quests*.lua"
ATT_GLOB    = "blizzard/addons/AllTheThings/db/**/*.lua"

PAT_HEADER = re.compile(r'^(?P<lead> {8})\[(?P<qid>\d+)\]\s*=\s*\{', re.M)
PAT_END    = re.compile(r'(?P<lead>\s*End\s*=\s*")(?P<val>[^"]*)(?P<tail>")')
BROKEN     = re.compile(r'^(?P<npc>-?\d+)\|0\|32\|0\.00\|0\.00$')

# `q(QID, { ... })` -- capture the QID and we'll brace-walk the body.
PAT_ATT_Q  = re.compile(r'\bq\((\d+)\s*,\s*\{')
# Inside an ATT body: coords={[mapID]={{x,y},{x,y},...}}
PAT_COORDS = re.compile(
    r'coords\s*=\s*\{\s*\[(?P<m>\d+)\]\s*=\s*\{\s*\{\s*(?P<x>[\d.]+)\s*,\s*(?P<y>[\d.]+)'
)
# qgs={NPCID,NPCID,...} -- bare integer list. Also accept qg=NPCID and
# `qgs=a[NNNN]` (alias array, which we can't resolve without ATT's
# globals; treat as opaque and skip).
PAT_QGS    = re.compile(r'qgs?\s*=\s*\{([^}]*)\}')
PAT_QG     = re.compile(r'\bqg\s*=\s*(\d+)\b')


def iter_entries(src):
    for m in PAT_HEADER.finditer(src):
        i = m.end() - 1
        depth = 0
        n = len(src)
        start = i
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


def att_brace_walk(src, start):
    """src[start] points at '{'. Return (body, end_excl)."""
    i = start
    depth = 0
    n = len(src)
    while i < n:
        if src[i] == '{':
            depth += 1
        elif src[i] == '}':
            depth -= 1
            if depth == 0:
                return src[start:i + 1], i + 1
        i += 1
    return src[start:], n


def build_att_index() -> dict[int, list[tuple[str, float, float, set[int]]]]:
    """qid -> list of (mapID_str, x, y, set_of_qg_npc_ids).

    A quest can appear in multiple ATT files (different categories);
    keep them all and let the patcher pick the first qgs-matching one.
    """
    out: dict[int, list[tuple[str, float, float, set[int]]]] = {}
    paths = glob.glob(ATT_GLOB, recursive=True)
    for path in paths:
        try:
            with open(path, encoding='utf-8', errors='replace') as f:
                src = f.read()
        except Exception:
            continue
        for m in PAT_ATT_Q.finditer(src):
            qid = int(m.group(1))
            brace = m.end() - 1
            body, _ = att_brace_walk(src, brace)
            cm = PAT_COORDS.search(body)
            if not cm:
                continue
            qgs: set[int] = set()
            qgsm = PAT_QGS.search(body)
            if qgsm:
                for tok in qgsm.group(1).split(','):
                    tok = tok.strip()
                    if tok.lstrip('-').isdigit():
                        qgs.add(int(tok))
            qgm = PAT_QG.search(body)
            if qgm:
                qgs.add(int(qgm.group(1)))
            if not qgs:
                continue
            out.setdefault(qid, []).append(
                (cm.group('m'), float(cm.group('x')), float(cm.group('y')), qgs)
            )
    return out


def collect_retail_mapids() -> set[str]:
    """Set of mapId tokens already used by retail quest data. Anything
    in here is known to resolve via GetWorldPos."""
    PAT_ANY = re.compile(r'"[^"]*\|(-?\d+)\|3[25]\|[\d.]+\|[\d.]+"')
    out: set[str] = set()
    for path in glob.glob(RETAIL_GLOB):
        with open(path) as f:
            src = f.read()
        for m in PAT_ANY.finditer(src):
            out.add(m.group(1))
    return out


def process_retail(path: str, att: dict, valid_maps: set[str], apply: bool):
    with open(path) as f:
        src = f.read()

    edits = []
    stats = {
        'entries': 0,
        'patched': 0,
        'skip_already_ok': 0,
        'skip_no_att': 0,
        'skip_no_qg_match': 0,
        'skip_unknown_mapid': 0,
    }

    for qid, lo, hi in iter_entries(src):
        stats['entries'] += 1
        em = PAT_END.search(src, lo, hi)
        if not em:
            continue
        bm = BROKEN.match(em.group('val'))
        if not bm:
            stats['skip_already_ok'] += 1
            continue
        end_npc = int(bm.group('npc'))
        cands = att.get(qid)
        if not cands:
            stats['skip_no_att'] += 1
            continue
        # Find first candidate whose qgs contains our End NPC id.
        chosen = None
        for mapid, x, y, qgs in cands:
            if end_npc in qgs:
                chosen = (mapid, x, y)
                break
        if not chosen:
            stats['skip_no_qg_match'] += 1
            continue
        mapid, x, y = chosen
        if mapid not in valid_maps:
            stats['skip_unknown_mapid'] += 1
            continue
        new_val = f"{end_npc}|{mapid}|32|{x:.2f}|{y:.2f}"
        edits.append((em.start('val'), em.end('val'), new_val))
        stats['patched'] += 1

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
    ap.add_argument('--apply', action='store_true')
    args = ap.parse_args()

    print("Indexing ATT...")
    att = build_att_index()
    print(f"  ATT quests with coords + qgs: {len(att)}")

    print("Indexing retail mapId set...")
    valid = collect_retail_mapids()
    print(f"  retail mapId tokens in use:   {len(valid)}")
    print()

    keys = ['entries', 'patched', 'skip_no_qg_match',
            'skip_unknown_mapid', 'skip_no_att', 'skip_already_ok']
    head = ['file', 'entries', 'patched', 'no_qg', 'bad_map',
            'no_att', 'already_ok']
    fmt = '{:<28}' + '{:>11}' * (len(head) - 1)
    print(fmt.format(*head))

    totals = {k: 0 for k in keys}
    for path in sorted(glob.glob(RETAIL_GLOB)):
        stats = process_retail(path, att, valid, args.apply)
        print(fmt.format(os.path.basename(path), *[stats[k] for k in keys]))
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

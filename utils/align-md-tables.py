#!/usr/bin/env python3
"""utils/align-md-tables.py

Pipe-align every GFM table in README.md so that the `|` characters line up
vertically across the header, separator row, and all body rows. Enforces
markdownlint rule MD060 (table-column-style: aligned).

Invocation:
    python3 utils/align-md-tables.py

Idempotent: running twice on a clean tree produces no diff. Tables inside
fenced code blocks (```...```) are intentionally left alone.

Used by:
    - utils/generate-docs.sh (after terraform-docs regeneration)
    - pre-commit hook chain
    - any time a heading or table is hand-edited in README.md
"""
from __future__ import annotations

import sys
from pathlib import Path

README = Path(__file__).resolve().parent.parent / "README.md"


def split_row(line: str) -> list[str]:
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|"):
        s = s[:-1]
    return [c.strip() for c in s.split("|")]


def is_table_row(line: str) -> bool:
    s = line.strip()
    return s.startswith("|") and s.endswith("|") and "|" in s[1:-1]


def is_separator_row(line: str) -> bool:
    if not is_table_row(line):
        return False
    cells = split_row(line)
    return all(c and set(c) <= set("-:") and "-" in c for c in cells)


def render_separator(widths: list[int], aligns: list[str]) -> str:
    parts = []
    for w, a in zip(widths, aligns):
        body = "-" * max(3, w)
        if a == "left":
            parts.append(":" + body[1:] if w >= 3 else ":" + body)
        elif a == "right":
            parts.append(body[:-1] + ":" if w >= 3 else body + ":")
        elif a == "center":
            parts.append(":" + body[1:-1] + ":" if w >= 3 else ":" + body + ":")
        else:
            parts.append(body)
    return "| " + " | ".join(parts) + " |"


def parse_align(cell: str) -> str:
    starts = cell.startswith(":")
    ends = cell.endswith(":")
    if starts and ends:
        return "center"
    if ends:
        return "right"
    if starts:
        return "left"
    return "default"


def align_table(rows: list[str]) -> list[str]:
    parsed = [split_row(r) for r in rows]
    n_cols = max(len(r) for r in parsed)
    parsed = [r + [""] * (n_cols - len(r)) for r in parsed]

    sep_idx = next(
        (i for i, r in enumerate(rows) if is_separator_row(r)),
        None,
    )
    if sep_idx is None:
        aligns = ["default"] * n_cols
    else:
        aligns = [parse_align(c) for c in parsed[sep_idx]]

    body_rows = [r for i, r in enumerate(parsed) if i != sep_idx]
    widths = [
        max((len(r[c]) for r in body_rows), default=3)
        for c in range(n_cols)
    ]
    widths = [max(w, 3) for w in widths]

    out: list[str] = []
    for i, r in enumerate(parsed):
        if i == sep_idx:
            out.append(render_separator(widths, aligns))
            continue
        cells = []
        for c, val in enumerate(r):
            a = aligns[c] if c < len(aligns) else "default"
            w = widths[c]
            if a == "right":
                cells.append(val.rjust(w))
            elif a == "center":
                pad = w - len(val)
                left = pad // 2
                right = pad - left
                cells.append(" " * left + val + " " * right)
            else:
                cells.append(val.ljust(w))
        out.append("| " + " | ".join(cells) + " |")
    return out


def align_tables(text: str) -> str:
    lines = text.splitlines()
    out: list[str] = []
    in_fence = False
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            out.append(line)
            i += 1
            continue
        if not in_fence and is_table_row(line):
            block = []
            j = i
            while j < len(lines) and is_table_row(lines[j]):
                block.append(lines[j])
                j += 1
            if len(block) >= 2 and is_separator_row(block[1]):
                out.extend(align_table(block))
            else:
                out.extend(block)
            i = j
            continue
        out.append(line)
        i += 1
    aligned = "\n".join(out)
    if text.endswith("\n") and not aligned.endswith("\n"):
        aligned += "\n"
    return aligned


def main() -> int:
    if not README.exists():
        print(f"ERROR: {README} not found", file=sys.stderr)
        return 1

    original = README.read_text()
    aligned = align_tables(original)

    if aligned == original:
        print(f"align-md-tables.py: {README.name} already aligned (no changes).")
        return 0

    README.write_text(aligned)
    print(f"align-md-tables.py: rewrote {README.name} with aligned GFM tables.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Convert ARIA v3 bib.yaml -> references.bib (BibTeX, UTF-8).

Usage: python3 yaml_to_bib.py
"""
from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML required: pip install pyyaml\n")
    sys.exit(1)

INPUT = Path("/Innovation/home/boyaaarya/projects/aria-2/v3/citations/bib.yaml")
OUTPUT = Path("/Innovation/home/boyaaarya/projects/aria-3/references.bib")

TYPE_MAP = {
    "paper": "article",
    "book": "book",
    "report": "techreport",
    "standard": "misc",
    "regulation": "misc",
    "blog": "misc",
    "spec": "misc",
}

CORP_HINTS = (
    "National Institute", "NIST", "European", "Commission", "OWASP",
    "MITRE", "OpenAI", "Anthropic", "Google", "Microsoft", "IBM",
    "ISO", "IEEE", "Cloud Security Alliance", "World Economic Forum",
    "U.S.", "United States", "Department", "Office", "Authority",
    "Agency", "Institute", "Council", "Organization", "Organisation",
    "Foundation", "Consortium", "Association", "Committee", "Bureau",
    "Partnership", "Center", "Centre", "Group", "Working Group",
    "White House", "UNESCO", "UN ", "OECD",
)


def looks_corporate(name: str) -> bool:
    s = name.strip()
    if not s:
        return False
    if s.lower() == "et al." or s.lower() == "et al":
        return True
    # No comma + multiple capitalized words + matches a corp hint
    if any(h in s for h in CORP_HINTS):
        return True
    # Single token that doesn't end in a single initial
    tokens = s.split()
    if len(tokens) == 1:
        return True
    return False


def normalize_author(name: str) -> str:
    """Transform 'Lewis P.' -> 'Lewis, P.'. Wrap corporate authors in braces."""
    s = name.strip().rstrip(",")
    if not s:
        return s
    if s.lower() in ("et al.", "et al"):
        return "{et al.}"
    if looks_corporate(s):
        return "{" + s + "}"
    # Already in "Last, First" form
    if "," in s:
        return s
    tokens = s.split()
    # Find the split: last name = tokens up to the first initial-like token
    # "Lewis P." -> last=Lewis, rest=P.
    # "Griffiths T. L." -> last=Griffiths, rest=T. L.
    # "Chen P.-Y." -> last=Chen, rest=P.-Y.
    # "Park J. S." -> last=Park, rest=J. S.
    # "O'Brien J. C." -> last=O'Brien, rest=J. C.
    # Heuristic: the LAST name is the leading run of tokens that don't look like initials.
    def is_initial(t: str) -> bool:
        # one letter possibly followed by . and possibly hyphenated initials
        return bool(re.match(r"^[A-Z]\.?(-[A-Z]\.?)*$", t))

    # Find first initial-looking token
    idx = None
    for i, t in enumerate(tokens):
        if is_initial(t):
            idx = i
            break
    if idx is None or idx == 0:
        # Can't parse — return as-is in braces to be safe
        return "{" + s + "}"
    last = " ".join(tokens[:idx])
    first = " ".join(tokens[idx:])
    return f"{last}, {first}"


def join_authors(authors) -> str:
    if not authors:
        return ""
    if isinstance(authors, str):
        authors = [a.strip() for a in re.split(r",(?![^\[]*\])", authors) if a.strip()]
    parts = [normalize_author(a) for a in authors if a and a.strip()]
    return " and ".join(parts)


def escape_field(value: str) -> str:
    """Escape LaTeX specials safely for BibTeX field values."""
    if value is None:
        return ""
    s = str(value)
    # Avoid double-escaping
    s = re.sub(r"(?<!\\)&", r"\\&", s)
    s = re.sub(r"(?<!\\)%", r"\\%", s)
    s = re.sub(r"(?<!\\)#", r"\\#", s)
    s = re.sub(r"(?<!\\)_", r"\\_", s)
    return s


def url_field(value: str) -> str:
    # URLs: don't escape; wrap as-is. BibTeX url package handles it.
    return str(value) if value else ""


REQUIRED = {
    "article": ["authors", "title", "year"],
    "book": ["authors", "title", "year"],
    "techreport": ["authors", "title", "year"],
    "misc": ["title", "year"],
}


def render_entry(e: dict, warnings: list) -> str:
    key = e.get("key")
    ytype = (e.get("type") or "misc").strip().lower()
    btype = TYPE_MAP.get(ytype, "misc")

    # Warn for missing required fields
    missing = []
    for r in REQUIRED.get(btype, []):
        if not e.get(r):
            missing.append(r)
    if missing:
        warnings.append(f"{key} ({ytype}): missing {missing}")

    fields = []
    authors = e.get("authors")
    if authors:
        fields.append(("author", join_authors(authors)))

    title = e.get("title")
    if title:
        fields.append(("title", "{" + escape_field(title) + "}"))

    year = e.get("year")
    if year is not None:
        fields.append(("year", str(year)))

    venue = e.get("venue")
    journal = e.get("journal")
    publisher = e.get("publisher")
    institution = None
    howpublished = None

    if btype == "article":
        j = journal or venue
        if j:
            fields.append(("journal", escape_field(j)))
    elif btype == "book":
        if publisher:
            fields.append(("publisher", escape_field(publisher)))
        elif venue:
            fields.append(("publisher", escape_field(venue)))
    elif btype == "techreport":
        institution = venue or publisher
        if institution:
            fields.append(("institution", escape_field(institution)))
    elif btype == "misc":
        howpublished = venue or publisher
        if howpublished:
            fields.append(("howpublished", "{" + escape_field(howpublished) + "}"))

    if publisher and btype not in ("book",) and ytype not in ("standard", "regulation", "blog", "spec"):
        fields.append(("publisher", escape_field(publisher)))

    doi = e.get("doi")
    if doi:
        fields.append(("doi", str(doi)))

    url = e.get("url")
    if url:
        fields.append(("url", url_field(url)))

    # Render
    lines = [f"@{btype}{{{key},"]
    for i, (k, v) in enumerate(fields):
        comma = "," if i < len(fields) - 1 else ""
        lines.append(f"  {k} = {{{v}}}{comma}")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main():
    with INPUT.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    if not isinstance(data, list):
        sys.stderr.write("Expected a top-level YAML list of entries.\n")
        sys.exit(1)

    warnings: list = []
    type_counter = Counter()
    btype_counter = Counter()
    rendered = []

    for e in data:
        if not isinstance(e, dict) or "key" not in e:
            continue
        ytype = (e.get("type") or "misc").strip().lower()
        type_counter[ytype] += 1
        btype_counter[TYPE_MAP.get(ytype, "misc")] += 1
        rendered.append(render_entry(e, warnings))

    header = (
        "% ARIA v3 references.bib — generated from bib.yaml\n"
        "% Source: /Innovation/home/boyaaarya/projects/aria-2/v3/citations/bib.yaml\n"
        "% Generator: scripts/yaml_to_bib.py\n"
        "% Style: natbib + plainnat (UTF-8)\n\n"
    )
    OUTPUT.write_text(header + "\n".join(rendered), encoding="utf-8")

    print(f"Wrote {OUTPUT}")
    print(f"Total entries: {len(rendered)}")
    print("Counts by YAML type:")
    for t, n in sorted(type_counter.items(), key=lambda kv: -kv[1]):
        print(f"  {t}: {n}")
    print("Counts by BibTeX type:")
    for t, n in sorted(btype_counter.items(), key=lambda kv: -kv[1]):
        print(f"  @{t}: {n}")
    print(f"\nWarnings ({len(warnings)}):")
    for w in warnings:
        print(f"  - {w}")

    print("\nSample (first 3 entries):\n")
    print("\n".join(rendered[:3]))


if __name__ == "__main__":
    main()

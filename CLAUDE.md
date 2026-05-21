# aria-3 — ARIA Book PDF Production

## Your job

Take the finished markdown manuscript at `/Innovation/home/boyaaarya/projects/aria-2/v3/` and produce a **simple, readable two-column LaTeX PDF** of the book. Content over polish. The goal is to get something the human can read end-to-end on paper or screen — not a print-shop-ready typeset volume.

## Hard constraints from the user

1. **Two-column layout.** Body text in two columns. Standard `multicol` is fine.
2. **Simple, not fancy.** Standard LaTeX. No custom class wrestling unless absolutely necessary. Pick a baseline (`scrbook`, `book`, or `report`) and a clean style.
3. **Parallel agents allowed and encouraged** to speed things up. Use the Agent tool with multiple sub-agents working concurrently on independent tasks (e.g., one converts each pillar in parallel; one handles bib conversion; one writes the build script).
4. **Source of truth:** `/Innovation/home/boyaaarya/projects/aria-2/v3/` — do NOT modify anything in v3. Read from it and write to `/Innovation/home/boyaaarya/projects/aria-3/`.

## Watch out: markdown-edition prose that won't suit print

The v3 manuscript was written markdown-first. A handful of passages refer to "the markdown edition," "linked chapters," "follow the links," etc. These do not make sense in a printed PDF. When copying content into aria-3, **clean these passages up** so the prose reads correctly for print.

Specific example to look for (paraphrased): *"When a chapter says 'Chapter 10 takes this up,' that is a real pointer to a real chapter, and the markdown edition links it..."* — this should become *"When a chapter references another chapter, the reference is real..."* or be cut entirely.

There may be other such artifacts. Read each chapter as you convert it and rewrite where the prose assumes a digital/linked medium that doesn't exist in print.

## What's already done for you

`/Innovation/home/boyaaarya/projects/aria-2/v3/meta/handoff-to-aria-3.md` is the handoff brief — ~4,900 words. **Read it first.** It contains:
- File inventory and reading order
- LaTeX class recommendation (Source B's `infosys-design.cls`)
- A full markdown → LaTeX conversion map
- Bibliography conversion plan (`bib.yaml` → `references.bib`)
- Figure inventory
- Cover plan
- Build pipeline
- The "first ten commits" sequence to follow

**The handoff brief recommends Source B's class. For a "simple, not fancy" target, you may prefer a lighter approach:**
- Option A: Adapt Source B's `infosys-design.cls` but simplify ruthlessly (drop magazine typography, drop semantic callout class, use plain `tcolorbox` for callouts).
- Option B: Start fresh with `\documentclass{scrbook}` + `multicol` + a small custom preamble for the callout boxes. Less inheritance baggage; faster path to a readable PDF.

Decide quickly. The user's emphasis is "content to read it out" — clarity over cleverness.

## Existing LaTeX projects for reference (READ-ONLY)

- `/Innovation/home/boyaaarya/projects/aria-2/` — Book A. Has `tn-style.sty` (clean three-color, two-column already!), 5 benchmarking infographics at `images/benchmarking/`, and a working `build.sh`. This is closest to what the user asked for.
- `/Innovation/home/boyaaarya/projects/ARIA/AgentCert/` — Book B. Has `infosys-design.cls` (heavier; magazine-style single-column). Reference only.

**Recommendation:** copy `aria-2/tn-style.sty` and `aria-2/build.sh` as your starting point, since they already provide two-column + callouts + a working build pipeline. Then adapt to v3's content and conventions.

## Source chapters to convert

23 prose files in `v3/chapters/` (foreword + about + exec summary + 20 chapters) and 5 in `v3/back-matter/` (synthesis, glossary, crosswalk, further reading, references). Listed in reading order in the handoff brief.

## Callout types to render

From `v3/00-framing/markdown-conventions.md`:
- `> **ABSTRACT:** ...` (chapter opener)
- `> **DEFINITION:** *Term* — ...`
- `> **IN PRACTICE — Name:** ...`
- `> **WARNING:** ...`
- `> **KEY TAKEAWAYS** > - ...`
- `> **PRACTITIONER CHECKLIST** > - [ ] ...`

For simplicity, all six can render as `tcolorbox` blocks with a bold label prefix. Don't bother with semantic color coding unless trivial.

## Citations

`v3/citations/bib.yaml` has 135 entries. Convert to BibTeX (one-pass script). The handoff brief outlines the Python conversion approach. Use `\cite{}` or `\citep{}` (`natbib` is fine).

## Figures

Most figures aren't yet commissioned. Use `\imgplaceholder{width}{height}` (from `aria-2/tn-style.sty`) wherever a figure is referenced but the asset doesn't exist. Copy Book A's 5 benchmarking infographics from `aria-2/images/benchmarking/` for Chapters 9, 10, 11, 12.

## Definition of done

A `main.pdf` that:
1. Builds cleanly via `bash build.sh` (3 latex passes + bibtex).
2. Renders all 23 chapters + 5 back-matter files in two-column layout.
3. Has a working ToC.
4. Has callouts that are visually distinct from body prose.
5. Has a bibliography that resolves.
6. Reads correctly as print — no orphaned "the markdown edition links it"-style passages.

Stretch goals (skip if time-constrained): cover page, index, figure list.

## Recommended first moves

1. Read the handoff brief at `aria-2/v3/meta/handoff-to-aria-3.md`.
2. Copy `aria-2/tn-style.sty` and `aria-2/build.sh` as the starting skeleton.
3. Write a small Python script: `bib.yaml` → `references.bib`.
4. Spawn 3-5 parallel agents, each converting one pillar (markdown → LaTeX `\input{}` files), with explicit instructions to fix any "markdown edition" / "linked" / "see file X.md" prose during conversion.
5. Wire up `main.tex` and run `build.sh` early to catch issues fast.
6. Iterate.

Good luck.

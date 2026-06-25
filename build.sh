#!/bin/bash
# Build script for the Tech Navigator-style book.
# Produces both:
#   main.pdf              — normal edition
#   main-highlighted.pdf  — reviewer edition with new content tinted green
# Run: bash build.sh
set -e

MAIN="main"

# ── Normal edition ───────────────────────────────────────────
echo "==> Cleaning stale aux files (normal edition)..."
rm -f "${MAIN}".{aux,toc,bbl,blg,out,log,lof,lot}

echo "==> Normal Pass 1 (structure + labels)..."
pdflatex -interaction=nonstopmode -halt-on-error "${MAIN}.tex"

echo "==> Normal Bibliography..."
bibtex "${MAIN}" || true

echo "==> Normal Pass 2 (bibliography + cross-refs)..."
pdflatex -interaction=nonstopmode "${MAIN}.tex"

echo "==> Normal Pass 3 (final cross-refs)..."
pdflatex -interaction=nonstopmode "${MAIN}.tex"

echo "✓ Normal edition → ${MAIN}.pdf"

# ── Highlighted edition ──────────────────────────────────────
HL="${MAIN}-highlighted"
echo ""
echo "==> Building highlighted edition (new content tinted green)..."
rm -f "${HL}".{aux,toc,bbl,blg,out,log,lof,lot}

# Use a wrapper .tex that defines \highlightnew before loading main.
cat > "${HL}.tex" <<EOF
\def\highlightnew{}
\input{${MAIN}.tex}
EOF

echo "==> Highlighted Pass 1..."
pdflatex -interaction=nonstopmode -halt-on-error -jobname="${HL}" "${HL}.tex"

echo "==> Highlighted Bibliography..."
bibtex "${HL}" || true

echo "==> Highlighted Pass 2..."
pdflatex -interaction=nonstopmode -jobname="${HL}" "${HL}.tex"

echo "==> Highlighted Pass 3..."
pdflatex -interaction=nonstopmode -jobname="${HL}" "${HL}.tex"

echo ""
echo "✓ Normal edition       → ${MAIN}.pdf"
echo "✓ Highlighted edition  → ${HL}.pdf"

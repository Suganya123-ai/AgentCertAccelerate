#!/bin/bash
# Build script for the Tech Navigator-style book
# Run: bash build.sh
set -e

MAIN="main"

echo "==> Pass 1 (structure + labels)..."
pdflatex -interaction=nonstopmode -halt-on-error "${MAIN}.tex"

echo "==> Bibliography..."
bibtex "${MAIN}" || true

echo "==> Pass 2 (bibliography + cross-refs)..."
pdflatex -interaction=nonstopmode "${MAIN}.tex"

echo "==> Pass 3 (final cross-refs)..."
pdflatex -interaction=nonstopmode "${MAIN}.tex"

echo ""
echo "✓ Build complete → ${MAIN}.pdf"

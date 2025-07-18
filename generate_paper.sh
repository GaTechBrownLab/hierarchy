#!/bin/zsh
# Shell script to convert source files into a MS-Word
# document. Most of the heavy lifting done by pandoc:
#   https://pandoc.org
# Last tested with v3.1.
#
# Equation, Figure, and Table numbering/cross references
# handled by pandoc-crossref:
#   https://lierdakil.github.io/pandoc-crossref/#citeproc-and-pandoc-crossref
# Last tested with v0.3.15.1.

# Cleanup markdown before passing to pandoc
# - missing italics for genes and QS systems
# - unicode glyphs to markdown subscripts
# - GitHub-friendly subscripts/superscripts to real markdown

cat paper.md | sed \
    -e 's/ lasB/ _lasB_/g' \
    -e 's/ lasI/ _lasI_/g' \
    -e 's/ lasR/ _lasR_/g' \
    -e 's/ rhlI/ _rhlI_/g' \
    -e 's/ rhlR/ _rhlR_/g' \
    -e 's/ las/ _las_/g' \
    -e 's/ rhl/ _rhl_/g' \
    -e 's/C₄‑HSL/C~4~‑HSL/g' \
    -e 's/3‑oxo‑C₁₂‑HSL/3‑oxo‑C~12~‑HSL/g' \
    -e 's/<\/\{0,1\}sub>/~/g' \
    -e 's/<\/\{0,1\}sup>/^/g' \
| pandoc \
    --from markdown \
    --filter pandoc-crossref \
    --citeproc \
    --csl plos-biology.csl \
    --bibliography "Bibliography (BibTeX).bib" \
    --reference-doc=reference.docx \
    --output "paper.docx"

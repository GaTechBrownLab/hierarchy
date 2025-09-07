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

cat supporting.md | sed \
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
    --to gfm \
    --metadata "tableEqns:false" \
    --metadata "figLabels:alpha A" \
    --metadata "eqLabels:alpha A" \
    --metadata "tblLabels:alpha A" \
    --wrap=preserve \
    --filter pandoc-crossref \
    --citeproc \
    --csl plos-biology.csl \
    --bibliography "Supporting (BibTeX).bib" \
| sed -E "s/\<\/{0,1}figure.*\>//" \
| sed -E "s/\<\/{0,1}p.*\>//" \
| sed -E "s/\<\/{0,1}span.*\>//" \
| sed -E "s/\<\/{0,1}div.*\>//" \
| sed -E "s/^Table [A-Z]?:.*//" \
| sed -E "s/\\\$\\\$/\n\$\$/" \
| sed -E "s/^\<div.*//" \
| sed -E "s/^entry-spacing=\"0\"\>//" \
| sed -e "/./b" -e :n -e "N;s/\n$//;tn" \
| sed -E "s/\<figcaption.*\>//" \
    > S1_Text.md

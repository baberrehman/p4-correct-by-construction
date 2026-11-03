# Grammatical specifications for P4 parsers and tables

Research record and an ECOOP 2026 (LIPIcs) draft that develops the idea in Yuan and Rehman, *Formal Specifications for Data Plane Programs*, FMANO 2025, [doi:10.1145/3750022.3750458](https://doi.org/10.1145/3750022.3750458). The source PDF is `baberrehman.github.io/files/formal_specs_fmano2024.pdf`.

## What is in this folder

- `research/findings.md` records the reading of the short paper, the semantic choices that the examples force, the gap relative to existing P4 verifiers, and what this study does not establish.
- `research/formal-model.md` is the working formalism: syntax, trace semantics, extraction from a P4 fragment, and the inclusion check.
- `research/related-work.md` is the literature map with the sources actually used.
- `research/p4c-comparison.md` compares p4c commit `98fbc63` with the model. `research/examples/` holds the programs that p4c accepts and the model rejects.
- `paper/` is a LIPIcs v2021.1.3 draft (`main.tex`, `refs.bib`, and the official class files). ECOOP 2026 proceedings use this format. The draft’s author is Baber Rehman. The class option `anonymous` is the double-anonymous submission switch.
- `lean/` is a Lean 4 mechanization of the calculus: header and table languages, inclusion, skeletons, and the examples from the draft. It is not a p4c pass.

Build the Lean development from `lean/`:

```bash
lake build
```

## What this study is

A pen-and-paper design. The short paper says an implementation in p4c is future work. Nothing here is a compiler pass, a measured evaluation, or a bug-finding campaign. Case studies are the examples from the short paper, checked by hand against the definitions.

Build the draft from `paper/`:

```bash
pdflatex main.tex && bibtex main && pdflatex main.tex && pdflatex main.tex
```

# Findings

Source: Keyu Yuan and Baber Rehman, “Formal Specifications for Data Plane Programs,” FMANO 2025, 3 pages. DOI `10.1145/3750022.3750458`. Local PDF: `baberrehman.github.io/files/formal_specs_fmano2024.pdf`. The filename says 2024; the PDF’s ACM reference block says FMANO ’25, 8–11 September 2025, Coimbra.

## What the short paper actually proposes

P4 programmers write a second, smaller description next to the program.

1. A parser specification is a grammar over header names. Sequential composition is written `∧` or `&`. Alternation is `|`. A terminal is a header extraction. A nonterminal is a sub-parser. The suggested shape is `Ether & (IPV4 | IPV6) & (TCP | UDP)`, and the factored form `L2 & L3 & L4`.
2. A table specification uses three relations found by inspecting public P4 projects (the Princeton Cabernet collection):
   - consecutive, written `A ⇒ B`: B is applied after A;
   - default-on-miss, written `A → B`: B is applied only if A misses;
   - alternative, written `A | B`: one of the two is applied.
   The composed example is `(A | B) ⇒ C → D`.
3. A compile-time check should reject an implementation path that is outside the specification. Two illustrated failures:
   - a parser arm that extracts TCP immediately after Ethernet;
   - an apply block that applies D when C hits, rather than when C misses.
4. Header validity is a corollary of the grammar. If no accepted word contains both `IPV4` and `IPV6`, a control block that reads fields of both headers is rejected.
5. The last sentence of the paper states the implementation plan and its limit: the analysis is future work in p4c, and no tool is evaluated.

Correctness-by-construction is cited (Dijkstra, Morgan, Kourie and Watson) but the workflow in the examples is retrospective checking. The grammar is not compiled into the parser. The select keys that choose `IPV4` rather than `IPV6` are not part of the grammar.

## Semantic choices forced by the examples

The note never defines the operators. The counterexamples pick one reading and rule out others.

- The check is language inclusion of implementation traces in the specification, not equivalence. A missing optional branch is not shown as an error. An extra branch is.
- `A → B` is a miss guard, not an obligation. The rejected program applies D on C’s hit. The prose says D should be applied only if C missed. It does not require that a miss of C be followed by D. Allowed traces are therefore “C hits” and “C misses, then D”.
- In `(A | B) ⇒ C → D`, `⇒` behaves like sequencing, the same role `&` plays for headers. “After” in the filtering-then-modification example is consistent with concatenation of trace languages. It is not yet a temporal-logic eventually operator, and the paper gives no example that would separate “immediately after” from “somewhere later”.
- `|` is union of trace sets. The apply example accepts A and B on opposite branches of one conditional.
- Select arms are not constrained by values. The grammar says which header may follow which header. It does not say which ether-type selects IPv4. A sound checker must therefore treat every select arm as possible. That over-approximation is sound for inclusion and can raise an alarm on an arm that is dead in practice.
- The grammar in the note has concatenation and union only. It cannot describe a repeating header stack or a parser loop. A P4 parser that loops while extracting is outside the fragment unless a repetition operator is added.
- Sub-parsers are nonterminals. The examples are non-recursive. Recursive nonterminals would make the language context-free and are not illustrated.

## What is worth developing into a full paper

The programmable-data-plane literature already verifies functional properties (p4v, Vera, ASSERT-P4), header typing (SafeP4 and the later dependently typed calculus), parser equivalence (Leapfrog), and compiler bugs (Gauntlet). Petr4 supplies a semantics. None of these ask the programmer for a small grammar of the intended header sequences and the intended table pipeline, then decide inclusion inside the compiler with no solver.

That is a programming-language problem of the kind ECOOP publishes: a specification notation, a semantics, a static analysis, and a statement of what the analysis guarantees on a defined fragment. It is not a drop-in replacement for p4v. It does not talk about table entries, register state, deparsing, multicast, or recirculation.

A second, smaller result falls out of the same semantics. On the acyclic fragment one can compile a grammar to a parser skeleton whose extracted language equals the grammar. The skeleton cannot invent select discriminators. Those remain obligations on the programmer. This is the correctness-by-construction direction the short paper points at and does not define.

## What this study does not establish

- No p4c pass was written.
- No corpus was measured. The Princeton Cabernet citation in the short paper is a motivation for the three table relations, not a count of how often they occur.
- No bug is claimed beyond the two illustrative mistakes already in the FMANO note, plus the same mistakes re-checked against the definitions below.
- The acyclic fragment, its metatheory, and the workshop examples are mechanized in Lean 4 under `lean/`. The proofs are not an embedding in Petr4, and there is no p4c pass.
- Header stacks, `lookahead`, `verify`, parser exceptions, value sets, direct application of tables from actions, and control-plane constraints are out of scope. Each one changes either the trace alphabet or the control-flow graph.

## Consequences for the draft

The ECOOP draft in `paper/` states inclusion as the conformance relation, defines `→` as a miss guard, limits the metalanguage to acyclic concatenation and union, and treats select as nondeterministic. Section `Mechanization in Lean` is the Lean development. The case studies are the examples module, discharged by computation. A p4c pass is still future work.

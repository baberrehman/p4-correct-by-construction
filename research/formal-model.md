# Formal model

Working definitions used by the draft in `paper/`. Operators match the FMANO note: `&` (also written `∧`) sequences headers, `|` is choice, `⇒` sequences tables, and `→` admits the continuation only on a miss.

## Parser specifications

```
P ::= H | P & P | P | P | N
```

`H` is a header type name. `N` is a nonterminal bound to one specification, with no recursive cycles in the binding graph. The language `L(P)` is a finite set of header words:

- `L(H) = { H }`
- `L(P1 & P2) = { uv | u in L(P1), v in L(P2) }`
- `L(P1 | P2) = L(P1) ∪ L(P2)`
- `L(N) = L(P)` when `N` is bound to `P`

Example. `Ether & (IPV4 | IPV6) & (TCP | UDP)` denotes the four words `Ether IPV4 TCP`, `Ether IPV4 UDP`, `Ether IPV6 TCP`, `Ether IPV6 UDP`.

A word validates a set of headers: those that occur in it. Two headers are exclusive when no word contains both. `IPV4` and `IPV6` are exclusive in the example. `Ether` co-occurs with every word.

## Table specifications

An event is `hit(t)` or `miss(t)` for a table name `t`.

```
T ::= t | T ⇒ T | T → T | T | T
```

- `L(t) = { hit(t), miss(t) }`
- `L(T1 ⇒ T2) = { uv | u in L(T1), v in L(T2) }`
- `L(T1 | T2) = L(T1) ∪ L(T2)`
- `L(T1 → T2) = Hits(T1) ∪ { uv | u in Misses(T1), v in L(T2) }`

`Hits` keeps only traces of `T1` whose last event is a hit, and only when that hit is the outcome of the rightmost table application in the trace. For an atom this is just `{ hit(t) }`. `Misses` is the analogous set ending in a miss. For a sequential composition the outcome that matters is the outcome of the rightmost atom, which matches the FMANO reading that D is gated by C, not by A or B.

Example. `(A | B) ⇒ (C → D)` allows:

- `hit(A) hit(C)`, `miss(A) hit(C)`, and the same with B
- `hit(A) miss(C) hit(D)`, `hit(A) miss(C) miss(D)`, and the same with B

It does not allow `hit(A) hit(C) hit(D)`.

## Programs in the fragment

A parser fragment is a directed graph. Edges are labeled by a header extraction or by `ε`. A `select` becomes one `ε` edge per arm, plus the extraction that the destination state performs. Accepting states end a word. The path language is regular. On the fragment we require that every cycle is either absent or reported as outside the star-free specification. With that restriction the path language is finite and can be enumerated by depth-first search.

An apply fragment is a graph whose edges are labeled `hit(t)` or `miss(t)`. The two successors of `t.apply()` are those two labels. A conditional that does not apply a table is an `ε` edge. Loops are rejected for the same reason as parser loops.

Conformance of a parser (respectively an apply block) is `L(graph) ⊆ L(spec)`.

## Why over-approximating select is the sound direction

If the graph contains an edge for an arm that no packet can take, `L(graph)` is larger than the true packet language. Inclusion of the larger set still implies inclusion of the true set. The checker may reject a program whose only offending arm is dead. It does not accept a program that has a feasible offending arm, provided every feasible arm was given an edge.

## Header use

At a control-flow point, the headers that may be valid are the union of the validation sets of the specification words that the parser can have produced. A field read `h.f` is illegal when `h` is absent from that set. A pair of reads `h1.f` and `h2.g` with no sequencing dependency is illegal when no word validates both. This is the IPv4/IPv6 example. It uses the specification language, not a data-flow fact discovered from an unchecked parser. If the parser itself has already failed inclusion, header-use results are not meaningful.

## Skeleton translation

On the acyclic fragment:

- `H` becomes a state that extracts `H` and accepts.
- `P1 & P2` concatenates the graphs by wiring every accept state of `P1` to the start of `P2`.
- `P1 | P2` adds a fresh start with `ε` edges into both starts. In P4 those `ε` edges must become a `select`. The grammar does not contain the selector expression, so the translation emits a hole.

By construction, the language of extracts in the skeleton, once holes are read as nondeterministic choice, equals `L(P)`. Filling a hole can only shrink the language. A later inclusion check against the same grammar rejects a filler that adds a forbidden arm and accepts a filler that deletes an arm. Deletion is allowed because conformance is inclusion, not equivalence.

## Arguments, not a mechanized proof

1. Enumeration of an acyclic parser graph computes `L(graph)`. Inclusion in a finite `L(P)` is then direct.
2. The same holds for apply graphs and `L(T)`.
3. If `L(graph)` over-approximates the packet language, acceptance implies every concrete packet trace is in the specification.
4. The skeleton’s nondeterministic language equals `L(P)`; every deterministic filling is a subset.

These are arguments about the definitions. They assume the graph was built from the fragment and that no P4 construct outside the fragment was ignored in silence. A compiler pass would still have to reject, not skip, `lookahead`, header stacks, parser `verify`, value sets, and tables applied from actions.

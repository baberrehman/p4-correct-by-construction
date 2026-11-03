# Related work used for the draft

Each item is a source the draft cites. The comparison is about the question each paper answers, not about re-running their experiments.

## The idea being extended

- Yuan and Rehman, FMANO 2025. DOI `10.1145/3750022.3750458`. Three-page proposal: BNF-style header grammars, three table operators, compile-time consistency, future implementation in p4c.

## P4 and its semantics

- Bosshart et al., “P4: Programming Protocol-Independent Packet Processors,” SIGCOMM CCR 2014. DOI `10.1145/2656877.2656890`. The language and the parse-graph plus match-action model. The original P4 specification also uses BNF, but as concrete syntax of parser declarations, not as a packet-format specification.
- The P4 Language Consortium, P4_16 language specification, <https://p4.org/p4-spec/docs/P4-16-spec.html>. Parser state machines, `extract`, `select`, header validity, and `apply().hit`.
- P4.org Architecture Working Group, P4C, <https://github.com/p4lang/p4c>. The compiler the short paper names as the intended host.
- Doenges et al., “Petr4: Formal Foundations for P4 Data Planes,” PACMPL POPL 2021. DOI `10.1145/3434322`. A definitional interpreter and a core calculus. This is the semantic baseline a future mechanization should sit on. Petr4 does not take a programmer-written pipeline grammar.
- P4.org, Portable Switch Architecture and Portable NIC Architecture, the two architecture documents cited by the short paper. They fix ingress and egress structure; they do not fix the programmer’s header sequence.
- Kreutz et al., “Software-Defined Networking: A Comprehensive Survey,” Proc. IEEE 2015. DOI `10.1109/JPROC.2014.2371999`. Background for the control-plane / data-plane split. Not a verification technique.

## Verification and typing of P4

- Liu et al., “p4v: Practical Verification for Programmable Data Planes,” SIGCOMM 2018. DOI `10.1145/3230543.3230582`. Translates P4 to guarded commands and checks assertions, including parser and table safety, with control-plane annotations and an SMT solver. Stronger properties, heavier specification, different failure mode.
- Stoenescu et al., “Debugging P4 Programs with Vera,” SIGCOMM 2018. DOI `10.1145/3230543.3230548`. Symbolic execution into SEFL. Aimed at bug finding rather than a grammatical architectural spec.
- Freire et al., “Uncovering Bugs in P4 Programs with Assertion-based Verification” (ASSERT-P4), SOSR 2018. DOI `10.1145/3185467.3185499`. Assertions, translation to C, symbolic execution. Again a property language embedded in the program, not a grammar of traces.
- Eichholz, Campbell, Foster, Salvaneschi, and Mezini, “How to Avoid Making a Billion-Dollar Mistake: Type-Safe Data Plane Programming with SafeP4,” ECOOP 2019. DOI `10.4230/LIPIcs.ECOOP.2019.12`. The closest ECOOP ancestor: types for headers and masks. SafeP4 rejects unsafe bit-level manipulation. It does not specify the legal sequence of headers or the legal order of tables.
- Eichholz, Campbell, Krebs, Foster, and Mezini, “Dependently Typed Data Plane Programming,” PACMPL POPL 2022. DOI `10.1145/3498701`. Refines the SafeP4 line with dependency. Still a type system for packet values, not a pipeline grammar.
- Doenges, Kappé, Sarracino, Foster, and Morrisett, “Leapfrog: Certified Equivalence for Protocol Parsers,” PLDI 2022. DOI `10.1145/3519939.3523715`. Proves two parsers equivalent. That is the right tool when a reference parser already exists. A grammar is useful precisely when the reference is a short specification rather than a second implementation.

## Compilers, not program specifications

- Ruffy, Wang, and Sivaraman, “Gauntlet: Finding Bugs in Compilers for Programmable Packet Processing,” OSDI 2020. <https://www.usenix.org/conference/osdi20/presentation/ruffy>. Finds compiler bugs. Orthogonal: a grammatical spec is a property of the program, not of p4c.

## Correctness-by-construction, as cited by the short paper

- Dijkstra, *A Discipline of Programming*, 1977.
- Morgan, *Programming from Specifications*, 2nd ed., 1994.
- Kourie and Watson, *The Correctness-by-Construction Approach to Programming*, 2012.

These support deriving a program from a specification. The FMANO examples check an existing program. The skeleton translation in the formal model is the piece that actually follows this line, and only up to select-holes.

## Deliberately not cited as if they had been re-read in full

Later production verifiers in the p4v family, including systems that infer table constraints or validate large switch programs, answer a broader functional question with solvers. They are discussed only in aggregate in the findings, because this pass did not re-establish their author lists from a primary bibliographic record. They are not required for the distinction the draft draws.

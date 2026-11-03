# p4c compared with the grammatical model

Source read: [p4lang/p4c](https://github.com/p4lang/p4c) commit `98fbc63` (2 November 2026), directories `frontends/p4` and `midend`. p4c is not installed on this machine, so the verdicts below are from those passes, not from a local compile. The example programs in `examples/` are the inputs the passes would see.

p4c is a compiler for the P4 language. The model is a second specification, written beside a P4 program, of the header words and the hit/miss traces that program is allowed to produce. They disagree in two different ways.

- On architectural mistakes (a TCP header immediately after Ethernet, a fallback table applied on a hit, IPv4 and IPv6 fields used together), p4c accepts a program the model rejects. That is p4c having no check, not p4c mis-compiling P4.
- On header validity, p4c does have a warning, and the warning is wrong on its own terms. Calling `isValid()` suppresses it on both branches of the test, including the branch where the header is invalid. `packet_in.extract`, the operation that makes a header valid, is not treated as a validity update.

## What p4c actually runs

The front end (`frontends/p4/frontend.cpp`) type-checks, folds constants, and then:

- `SimplifyParsers` deletes parser states that cannot reach `accept` or `reject`. If neither is reachable it is a hard error. A reachable but unintended arm is kept.
- `RemoveParserControlFlow` turns a parser `if` into a `select` with one arm per branch. Both arms survive. That matches the model's decision to keep every `select` arm.
- `CheckCoreMethods` checks that `extract` is called on a header and that a varbit header uses the two-argument form. It does not look at which header may follow which.
- `SimplifyDefUse` is the only pass that talks about invalid headers. It emits `WARN_INVALID_HEADER`. A warning does not stop compilation.
- Nothing in the front end builds a language of header words, and nothing compares table-apply traces with a pipeline grammar. `tableApply.h` only desugars `apply().hit`, `apply().miss`, and `apply().action_run`.

The mid-end pass `ParserUnroll` symbolically executes parser loops so that header-stack indexes become constants. When it cannot count the iterations it warns `WARN_INVALID` ("Parser cycle can't be unrolled") and then clears its error flag and continues (`parserUnroll.cpp`, `checkLoops` and the caller that sets `wasError = false`). The program is not rejected. The model rejects the same loop because the grammar has no repetition.

## Where a program passes p4c and fails the model

### 1. A forbidden parser arm

Specification: `Ether & (IPV4 | IPV6) & (TCP | UDP)`.

`examples/tcp_after_ethernet.p4` extracts Ethernet and then, on the default arm, extracts TCP. The state is reachable, so `SimplifyParsers` keeps it. `CheckCoreMethods` accepts the `extract`. The front end has no grammar to test the word `Ether TCP` against. The model rejects it: that word is not in the language.

p4c is compiling the state machine the programmer wrote. The bug is that the state machine is not the architecture. Only a specification check can see that.

### 2. A fallback table on the hit branch

Specification: `(A | B) ⇒ (C → D)`.

`examples/fallback_on_hit.p4` applies D when C hits. p4c type-checks `apply().hit` and leaves the control flow alone. The trace `hit(A) hit(C) hit(D)` is outside the model. The trace that applies D only on a miss is inside it. No p4c pass distinguishes those two programs.

### 3. IPv4 and IPv6 used together

Under the same header grammar, no word contains both `IPV4` and `IPV6`, so an unguarded read of both fields is unjustified in the model.

p4c never computes co-occurrence. `SimplifyDefUse` tracks each header's validity bit separately, with three values: yes, no, and maybe. The default when a bit was not set on this path is maybe, and maybe produces a warning, not an error (`simplifyDefUse.cpp`, `reportWarningIfInvalidHeader`). Two maybe-headers are not a special case. A program that reads `hdr.ipv4.src` and `hdr.ipv6.src` on one straight-line path is still a legal P4 program.

There is a second, sharper failure in the same pass, described next. It can silence even the per-header warning.

## Where p4c's own validity warning is wrong

`HeaderDefinitions::find` returns "yes" whenever the header is in the set `notReport`, without looking at the validity bit (`simplifyDefUse.cpp`):

```cpp
if (notReport.count(storage)) return TernaryBool::Yes;
```

A call to `isValid()` puts the receiver into that set. The comment above the set says why: `isValid()` in a condition is not interpreted, so every header mentioned by `isValid()` is stored until the end of the block. The `if` visitor visits the condition first, then both branches, and only afterwards restores `notReport` to the state from before the condition. Both branches therefore see the header as not worth reporting.

Consequences, all visible in `examples/isvalid_suppresses_warning.p4`:

- `if (hdr.ipv4.isValid()) { use ipv4 } else { use ipv4 }` warns on neither use. The else use is a read of an invalid header. p4c's warning claims to catch "accessing a field of an invalid header" and then does not, because the test mentioned the header.
- `if (!hdr.ipv4.isValid()) { use ipv4 }` is the same. The pass never looks at the polarity of the test.
- `hdr.ipv4.isValid(); use ipv4.src;` in a straight-line block also suppresses the warning. `notReport` stays until `setValid` or `setInvalid`, which are the calls that erase it.

The model does not have this hole. A field read is justified only when every word of the grammar that can reach that point contains the header. Mentioning `isValid` is not evidence that the header was extracted.

A related gap is `extract` itself. On an extern call, including `packet_in.extract`, `SimplifyDefUse` skips the arguments:

```cpp
// We assume control and parser apply calls and
// extern methods set all output headers to valid
if (isControlOrParserApply || mi->is<ExternMethod>() || mi->is<ExternFunction>())
    continue;
```

The comment describes an assumption the code does not implement: the `continue` happens before any update of the out header. `extract`, which is what makes a header valid in P4, is not a validity update in this analysis. `setValid` is. So the warning pass is not a model of the parser. The grammatical model is: validity is the set of names in the accepted word.

## Parser loops

The grammar in the model is star-free. A parser cycle is outside the fragment and must be rejected, not unrolled a guessed number of times. An under-approximation would hide a forbidden header on a later iteration.

`ParserUnroll` tries to count stack-index iterations. On a cycle whose bound it cannot see, `checkLoops` warns and sets `wasError`. The caller then clears `wasError` and continues with the other states. Compilation does not stop. That is the wrong failure mode for an architectural check, and it is a weak failure mode for unrolling: the compiler has decided the loop has no detectable bound and still emits a program.

## Where p4c and the model agree

- Unreachable parser states are not part of the language. `SimplifyParsers` deletes them. Inclusion allows a missing alternative, so deleting an unreachable arm does not by itself violate the model.
- Both branches of a parser `if` are real. `RemoveParserControlFlow` keeps them, and the model keeps every `select` arm so that a feasible forbidden arm cannot be dropped.
- `extract` on a non-header is a real type error in p4c (`CheckCoreMethods`). The model assumes extracts are header names, so it never had to restate that check.

## Where p4c is not failing the model

P4 itself allows any well-typed parse graph and any order of `apply`. A compiler that rejected `Ether TCP` with no specification to point at would be rejecting a legal program. The model's extra refusals are refusals of the specification, and they are only as good as the grammar the programmer wrote. A grammar that omits a header the protocol really needs will reject a correct parser. That is a bad specification, not a p4c bug.

p4c also does a great deal the model does not: constant folding, action inlining, header-stack unrolling, checksums, deparsers, and target backends. A miscompilation in those passes is invisible to the grammar. Gauntlet's compiler bugs are in that class. The model does not replace them.

## Summary

| Program shape | p4c at `98fbc63` | Model |
| --- | --- | --- |
| TCP extracted immediately after Ethernet | Accepted. The arm is reachable. | Rejected. `Ether TCP` is not in the grammar. |
| Fallback table applied on a hit | Accepted. No pipeline grammar exists. | Rejected. `hit(C)` then `hit(D)` is outside `C → D`. |
| Unguarded use of IPv4 and IPv6 fields | Compiles. At most a per-header "potentially invalid" warning. | Rejected after the parser conforms. No word contains both. |
| `isValid()` true-branch and false-branch both use the header | Warning suppressed on both branches. | The false branch is not justified by the grammar. |
| Discarded `isValid()` before a field read | Warning suppressed for the rest of the block. | Mentioning `isValid` does not validate the header. |
| `extract` as the source of validity | Not recorded. Extern calls are skipped. | The extracted name is the symbol in the word. |
| Parser cycle | Warning, then compilation continues. | Rejected. The fragment has no repetition. |
| Unreachable parser state | Deleted. | Allowed. Inclusion does not demand every specified word. |
| `select` keeps both arms | Yes, after `RemoveParserControlFlow`. | Yes. Dead arms may cause a false alarm; feasible arms may not be dropped. |

import P4Spec.Basic

/-!
Header specifications.

`HExpr` is the acyclic fragment. A nonterminal node stores the body `Γ(N)`,
so a cyclic binding is not a term. `Raw` is the surface syntax of the workshop
note. `compile` resolves variables; a cycle exhausts the fuel and returns `none`.
-/

namespace P4Spec

inductive HExpr where
  | hdr : Name → HExpr
  | seq : HExpr → HExpr → HExpr
  | alt : HExpr → HExpr → HExpr
  | nonterm : Name → HExpr → HExpr
  deriving DecidableEq, Repr

def lang : HExpr → Lang Name
  | .hdr h => [[h]]
  | .seq a b => concatLang (lang a) (lang b)
  | .alt a b => lang a ++ lang b
  | .nonterm _ b => lang b

def rank : HExpr → Nat
  | .hdr _ => 1
  | .seq a b => rank a + rank b
  | .alt a b => max (rank a) (rank b)
  | .nonterm _ b => rank b

theorem lang_rank {e : HExpr} {w : List Name} (h : w ∈ lang e) : w.length ≤ rank e := by
  induction e generalizing w with
  | hdr _ =>
      simp [lang] at h
      simp [h, rank]
  | seq a b iha ihb =>
      rw [lang] at h
      rcases mem_concatLang.mp h with ⟨u, hu, v, hv, rfl⟩
      simp [rank, List.length_append]
      exact Nat.add_le_add (iha hu) (ihb hv)
  | alt a b iha ihb =>
      simp [lang, List.mem_append] at h
      cases h with
      | inl hw => exact Nat.le_trans (iha hw) (Nat.le_max_left _ _)
      | inr hw => exact Nat.le_trans (ihb hw) (Nat.le_max_right _ _)
  | nonterm _ b ih =>
      rw [lang] at h
      exact ih h

def exclusive (L : Lang Name) (a b : Name) : Prop :=
  ∀ w ∈ L, ¬ (a ∈ w ∧ b ∈ w)

def allContain (L : Lang Name) (h : Name) : Prop :=
  ∀ w ∈ L, h ∈ w

def exclusiveB (L : Lang Name) (a b : Name) : Bool :=
  L.all fun w => !(w.elem a && w.elem b)

def allContainB (L : Lang Name) (h : Name) : Bool :=
  L.all fun w => w.elem h

theorem elem_true_iff (a : Name) (w : List Name) : w.elem a = true ↔ a ∈ w := by
  rw [List.elem_eq_mem, decide_eq_true_iff]

theorem exclusive_iff {L : Lang Name} {a b : Name} :
    exclusiveB L a b = true ↔ exclusive L a b := by
  simp only [exclusiveB, exclusive, List.all_eq_true]
  constructor
  · intro h w hw ⟨ha, hb⟩
    have hnot := h w hw
    rw [(elem_true_iff a w).mpr ha, (elem_true_iff b w).mpr hb] at hnot
    simp at hnot
  · intro h w hw
    by_cases ha : a ∈ w <;> by_cases hb : b ∈ w
    · exact False.elim (h w hw ⟨ha, hb⟩)
    · have heb : w.elem b = false := by
        apply Bool.eq_false_iff.mpr
        intro ht
        exact hb ((elem_true_iff b w).mp ht)
      rw [heb, Bool.and_false]
      rfl
    · have hea : w.elem a = false := by
        apply Bool.eq_false_iff.mpr
        intro ht
        exact ha ((elem_true_iff a w).mp ht)
      rw [hea, Bool.false_and]
      rfl
    · have hea : w.elem a = false := by
        apply Bool.eq_false_iff.mpr
        intro ht
        exact ha ((elem_true_iff a w).mp ht)
      rw [hea, Bool.false_and]
      rfl

theorem allContain_iff {L : Lang Name} {h : Name} :
    allContainB L h = true ↔ allContain L h := by
  simp only [allContainB, allContain, List.all_eq_true, elem_true_iff]

def namesOf : List Name → List Name
  | [] => []
  | h :: hs =>
      let rest := namesOf hs
      if h ∈ rest then rest else h :: rest

/-- `V(P)`: the names validated by each accepted word. -/
def mayValid (L : Lang Name) : List (List Name) :=
  L.map namesOf

inductive Raw where
  | hdr : Name → Raw
  | seq : Raw → Raw → Raw
  | alt : Raw → Raw → Raw
  | var : Name → Raw
  deriving DecidableEq, Repr

abbrev HEnv := List (Name × Raw)

/-- Resolve nonterminals. `fuel` bounds unfolding. A cycle returns `none`. -/
def compile (fuel : Nat) (Γ : HEnv) (e : Raw) : Option HExpr :=
  match fuel with
  | 0 => none
  | fuel + 1 =>
      match e with
      | .hdr h => some (.hdr h)
      | .seq a b => do
          let a ← compile fuel Γ a
          let b ← compile fuel Γ b
          some (.seq a b)
      | .alt a b => do
          let a ← compile fuel Γ a
          let b ← compile fuel Γ b
          some (.alt a b)
      | .var n =>
          match Γ.lookup n with
          | none => none
          | some body => do
              let body ← compile fuel Γ body
              some (.nonterm n body)

end P4Spec

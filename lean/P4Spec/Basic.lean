/-!
Finite languages of words, represented as lists. Membership is set membership:
order and duplicates do not matter. `EqLang` and `SubsetL` are the equalities
used in the theorems.
-/

namespace P4Spec

abbrev Name := String

abbrev Lang (α : Type) := List (List α)

def EqLang {α : Type} (A B : Lang α) : Prop :=
  ∀ w, w ∈ A ↔ w ∈ B

def SubsetL {α : Type} (A B : Lang α) : Prop :=
  ∀ w, w ∈ A → w ∈ B

theorem SubsetL.trans {α : Type} {A B C : Lang α}
    (h₁ : SubsetL A B) (h₂ : SubsetL B C) : SubsetL A C :=
  fun w hw => h₂ w (h₁ w hw)

theorem EqLang.subset {α : Type} {A B : Lang α} (h : EqLang A B) : SubsetL A B :=
  fun w hw => (h w).mp hw

theorem EqLang.trans {α : Type} {A B C : Lang α}
    (h₁ : EqLang A B) (h₂ : EqLang B C) : EqLang A C :=
  fun w => (h₁ w).trans (h₂ w)

def concatLang {α : Type} (A B : Lang α) : Lang α :=
  A.flatMap fun u => B.map fun v => u ++ v

theorem mem_concatLang {α : Type} {A B : Lang α} {w : List α} :
    w ∈ concatLang A B ↔ ∃ u ∈ A, ∃ v ∈ B, u ++ v = w := by
  simp [concatLang, List.mem_flatMap, List.mem_map]

theorem mem_concat_append {α : Type} {A B C : Lang α} {w : List α} :
    w ∈ concatLang (A ++ B) C ↔ w ∈ concatLang A C ∨ w ∈ concatLang B C := by
  constructor
  · intro hw
    rcases mem_concatLang.mp hw with ⟨u, hu, v, hv, heq⟩
    rw [List.mem_append] at hu
    cases hu with
    | inl hu => exact Or.inl (mem_concatLang.mpr ⟨u, hu, v, hv, heq⟩)
    | inr hu => exact Or.inr (mem_concatLang.mpr ⟨u, hu, v, hv, heq⟩)
  · intro hw
    rcases hw with hw | hw
    · rcases mem_concatLang.mp hw with ⟨u, hu, v, hv, heq⟩
      exact mem_concatLang.mpr ⟨u, List.mem_append.mpr (Or.inl hu), v, hv, heq⟩
    · rcases mem_concatLang.mp hw with ⟨u, hu, v, hv, heq⟩
      exact mem_concatLang.mpr ⟨u, List.mem_append.mpr (Or.inr hu), v, hv, heq⟩

theorem concatLang_congr {α : Type} {A A' B B' : Lang α}
    (hA : EqLang A A') (hB : EqLang B B') :
    EqLang (concatLang A B) (concatLang A' B') := by
  intro w
  constructor
  · intro hw
    rcases mem_concatLang.mp hw with ⟨u, hu, v, hv, heq⟩
    exact mem_concatLang.mpr ⟨u, (hA u).mp hu, v, (hB v).mp hv, heq⟩
  · intro hw
    rcases mem_concatLang.mp hw with ⟨u, hu, v, hv, heq⟩
    exact mem_concatLang.mpr ⟨u, (hA u).mpr hu, v, (hB v).mpr hv, heq⟩

def memB {α : Type} [BEq α] (w : List α) (L : Lang α) : Bool :=
  L.any fun v => v == w

def subB {α : Type} [BEq α] (A B : Lang α) : Bool :=
  A.all fun w => memB w B

theorem memB_iff {α : Type} [DecidableEq α] {w : List α} {L : Lang α} :
    memB w L = true ↔ w ∈ L := by
  simp [memB, List.any_eq_true, beq_iff_eq]

theorem subB_iff {α : Type} [DecidableEq α] {A B : Lang α} :
    subB A B = true ↔ SubsetL A B := by
  simp [subB, SubsetL, List.all_eq_true, memB_iff]

instance {α : Type} [DecidableEq α] (A B : Lang α) : Decidable (SubsetL A B) :=
  decidable_of_iff (subB A B = true) subB_iff

end P4Spec

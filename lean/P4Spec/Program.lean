import P4Spec.Header
import P4Spec.Table

/-!
Acyclic parser and apply graphs. `choose` is a `select` with the key
discarded, so every arm is kept. There is no cycle constructor: a loop is
outside the fragment rather than unrolled.
-/

namespace P4Spec

inductive Parser where
  | accept
  | reject
  | extract : Name → Parser → Parser
  | choose : List Parser → Parser
  deriving Repr

mutual
def plang : Parser → Lang Name
  | .accept => [[]]
  | .reject => []
  | .extract h k => (plang k).map (fun w => h :: w)
  | .choose arms => plangs arms

def plangs : List Parser → Lang Name
  | [] => []
  | p :: ps => plang p ++ plangs ps
end

theorem mem_plangs {w : List Name} {ps : List Parser} :
    w ∈ plangs ps ↔ ∃ p ∈ ps, w ∈ plang p := by
  induction ps with
  | nil => simp [plangs]
  | cons p ps ih =>
      simp [plangs, List.mem_append, ih, List.mem_cons]

/-- `Trim g g'` means `g'` is `g` with edges deleted. Arms may be dropped. -/
inductive Trim : Parser → Parser → Prop where
  | accept : Trim .accept .accept
  | reject : Trim .reject .reject
  | extract {h k k'} : Trim k k' → Trim (.extract h k) (.extract h k')
  | chooseNil : Trim (.choose []) (.choose [])
  | chooseDrop {p ps ps'} : Trim (.choose ps) (.choose ps') →
      Trim (.choose (p :: ps)) (.choose ps')
  | chooseKeep {p p' ps ps'} : Trim p p' → Trim (.choose ps) (.choose ps') →
      Trim (.choose (p :: ps)) (.choose (p' :: ps'))

theorem trim_sub {g g' : Parser} (h : Trim g g') : SubsetL (plang g') (plang g) := by
  induction h with
  | accept => intro w hw; exact hw
  | reject => intro w hw; exact hw
  | extract _ ih =>
      intro w hw
      simp [plang, List.mem_map] at hw ⊢
      rcases hw with ⟨t, ht, rfl⟩
      exact ⟨t, ih t ht, rfl⟩
  | chooseNil => intro w hw; exact hw
  | chooseDrop _ ih =>
      intro w hw
      exact List.mem_append.mpr (Or.inr (ih w hw))
  | chooseKeep _ _ ihp ihs =>
      intro w hw
      simp only [plang, plangs, List.mem_append] at hw ⊢
      cases hw with
      | inl hw => exact Or.inl (ihp w hw)
      | inr hw => exact Or.inr (ihs w hw)

inductive AGraph where
  | exit
  | branch : Name → AGraph → AGraph → AGraph
  | either : AGraph → AGraph → AGraph
  deriving DecidableEq, Repr

def alang : AGraph → Lang Event
  | .exit => [[]]
  | .branch t onHit onMiss =>
      (alang onHit).map (fun w => Event.hit t :: w) ++
        (alang onMiss).map (fun w => Event.miss t :: w)
  | .either a b => alang a ++ alang b

abbrev conformsH (g : Parser) (spec : HExpr) : Prop :=
  SubsetL (plang g) (lang spec)

abbrev conformsT (g : AGraph) (spec : TExpr) : Prop :=
  SubsetL (alang g) (tlang spec)

/-- If the path language covers every concrete trace, inclusion yields those
traces. A dead arm is still in the path language and can cause a false alarm. -/
theorem soundH {concrete : Lang Name} {g : Parser} {spec : HExpr}
    (hover : SubsetL concrete (plang g)) (hconf : conformsH g spec) :
    SubsetL concrete (lang spec) :=
  SubsetL.trans hover hconf

theorem soundT {concrete : Lang Event} {g : AGraph} {spec : TExpr}
    (hover : SubsetL concrete (alang g)) (hconf : conformsT g spec) :
    SubsetL concrete (tlang spec) :=
  SubsetL.trans hover hconf

theorem monoH {g g' : Parser} {spec : HExpr}
    (htrim : Trim g g') (hconf : conformsH g spec) : conformsH g' spec :=
  SubsetL.trans (trim_sub htrim) hconf

end P4Spec

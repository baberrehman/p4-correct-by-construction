import P4Spec.Basic

/-!
Table specifications. `seq` is `⇒`, `guard` is `→` (the continuation is
admitted only on a miss), and `alt` is `|`.
-/

namespace P4Spec

inductive Event where
  | hit : Name → Event
  | miss : Name → Event
  deriving DecidableEq, Repr

inductive TExpr where
  | atom : Name → TExpr
  | seq : TExpr → TExpr → TExpr
  | guard : TExpr → TExpr → TExpr
  | alt : TExpr → TExpr → TExpr
  deriving DecidableEq, Repr

def endsHit : List Event → Bool
  | [] => false
  | [.hit _] => true
  | [.miss _] => false
  | _ :: es => endsHit es

def endsMiss : List Event → Bool
  | [] => false
  | [.miss _] => true
  | [.hit _] => false
  | _ :: es => endsMiss es

def hits (s : Lang Event) : Lang Event :=
  s.filter endsHit

def misses (s : Lang Event) : Lang Event :=
  s.filter endsMiss

def tlang : TExpr → Lang Event
  | .atom t => [[.hit t], [.miss t]]
  | .seq a b => concatLang (tlang a) (tlang b)
  | .alt a b => tlang a ++ tlang b
  | .guard a b => hits (tlang a) ++ concatLang (misses (tlang a)) (tlang b)

def trank : TExpr → Nat
  | .atom _ => 1
  | .seq a b => trank a + trank b
  | .alt a b => max (trank a) (trank b)
  | .guard a b => trank a + trank b

theorem tlang_rank {e : TExpr} {w : List Event} (h : w ∈ tlang e) : w.length ≤ trank e := by
  induction e generalizing w with
  | atom _ =>
      simp [tlang, List.mem_cons] at h
      cases h <;> simp [trank, *]
  | seq a b iha ihb =>
      rw [tlang] at h
      rcases mem_concatLang.mp h with ⟨u, hu, v, hv, rfl⟩
      simp [trank, List.length_append]
      exact Nat.add_le_add (iha hu) (ihb hv)
  | alt a b iha ihb =>
      simp [tlang, List.mem_append] at h
      cases h with
      | inl hw => exact Nat.le_trans (iha hw) (Nat.le_max_left _ _)
      | inr hw => exact Nat.le_trans (ihb hw) (Nat.le_max_right _ _)
  | guard a b iha ihb =>
      rw [tlang, List.mem_append] at h
      cases h with
      | inl hw =>
          have hmem : w ∈ tlang a := (List.mem_filter.mp hw).1
          exact Nat.le_trans (iha hmem) (Nat.le_add_right _ _)
      | inr hw =>
          rcases mem_concatLang.mp hw with ⟨u, hu, v, hv, rfl⟩
          have humem : u ∈ tlang a := (List.mem_filter.mp hu).1
          simp [trank, List.length_append]
          exact Nat.add_le_add (iha humem) (ihb hv)

end P4Spec

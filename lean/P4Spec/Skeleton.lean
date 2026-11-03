import P4Spec.Program

/-!
Parser skeletons. A hole is an `ε` edge that a later `select` must fill.
Filling a hole keeps or deletes branches. It does not invent an extraction.
-/

namespace P4Spec

inductive Skel where
  | accept
  | extract : Name → Skel → Skel
  | hole : Skel → Skel → Skel
  deriving DecidableEq, Repr

def slang : Skel → Lang Name
  | .accept => [[]]
  | .extract h k => (slang k).map (fun w => h :: w)
  | .hole a b => slang a ++ slang b

def Skel.cat : Skel → Skel → Skel
  | .accept, s2 => s2
  | .extract h k, s2 => .extract h (cat k s2)
  | .hole a b, s2 => .hole (cat a s2) (cat b s2)

def toSkel : HExpr → Skel
  | .hdr h => .extract h .accept
  | .seq a b => Skel.cat (toSkel a) (toSkel b)
  | .alt a b => .hole (toSkel a) (toSkel b)
  | .nonterm _ b => toSkel b

theorem mem_map_cons_append {α : Type} {h : α} {A B : Lang α} {w : List α} :
    w ∈ concatLang (A.map (fun t => h :: t)) B ↔
      ∃ z, z ∈ concatLang A B ∧ h :: z = w := by
  constructor
  · intro hw
    rcases mem_concatLang.mp hw with ⟨u, hu, v, hv, heq⟩
    rcases List.mem_map.mp hu with ⟨t, ht, hu⟩
    subst hu
    refine ⟨t ++ v, mem_concatLang.mpr ⟨t, ht, v, hv, rfl⟩, ?_⟩
    simpa [List.cons_append] using heq
  · intro ⟨z, hz, heq⟩
    rcases mem_concatLang.mp hz with ⟨t, ht, v, hv, hzEq⟩
    subst hzEq
    apply mem_concatLang.mpr
    refine ⟨h :: t, List.mem_map.mpr ⟨t, ht, rfl⟩, v, hv, ?_⟩
    simpa [List.cons_append] using heq

theorem slang_cat (s1 s2 : Skel) :
    EqLang (slang (Skel.cat s1 s2)) (concatLang (slang s1) (slang s2)) := by
  induction s1 with
  | accept =>
      intro w
      simp [Skel.cat, slang, mem_concatLang, List.nil_append]
  | extract h k ih =>
      intro w
      simp only [Skel.cat, slang]
      constructor
      · intro hw
        rcases List.mem_map.mp hw with ⟨z, hz, heq⟩
        exact mem_map_cons_append.mpr ⟨z, (ih z).mp hz, heq⟩
      · intro hw
        rcases mem_map_cons_append.mp hw with ⟨z, hz, heq⟩
        exact List.mem_map.mpr ⟨z, (ih z).mpr hz, heq⟩
  | hole a b iha ihb =>
      intro w
      simp only [Skel.cat, slang, List.mem_append]
      constructor
      · intro hw
        rcases hw with hw | hw
        · exact mem_concat_append.mpr (Or.inl ((iha w).mp hw))
        · exact mem_concat_append.mpr (Or.inr ((ihb w).mp hw))
      · intro hw
        rcases mem_concat_append.mp hw with hw | hw
        · exact Or.inl ((iha w).mpr hw)
        · exact Or.inr ((ihb w).mpr hw)

theorem lang_skel (e : HExpr) : EqLang (slang (toSkel e)) (lang e) := by
  induction e with
  | hdr h =>
      intro w
      simp [toSkel, slang, lang]
  | seq a b iha ihb =>
      intro w
      have hcat := slang_cat (toSkel a) (toSkel b) w
      have hcong := concatLang_congr iha ihb w
      simp only [toSkel, lang]
      exact hcat.trans hcong
  | alt a b iha ihb =>
      intro w
      simp only [toSkel, slang, lang, List.mem_append]
      constructor
      · intro hw
        rcases hw with hw | hw
        · exact Or.inl ((iha w).mp hw)
        · exact Or.inr ((ihb w).mp hw)
      · intro hw
        rcases hw with hw | hw
        · exact Or.inl ((iha w).mpr hw)
        · exact Or.inr ((ihb w).mpr hw)
  | nonterm _ b ih =>
      intro w
      simpa [toSkel, lang] using ih w

mutual
inductive Fill : Skel → Parser → Prop where
  | accept : Fill .accept .accept
  | extract {h k p} : Fill k p → Fill (.extract h k) (.extract h p)
  | select {a b ps} : Arms a b ps → Fill (.hole a b) (.choose ps)

inductive Arms : Skel → Skel → List Parser → Prop where
  | nil {a b} : Arms a b []
  | consL {a b p ps} : Fill a p → Arms a b ps → Arms a b (p :: ps)
  | consR {a b p ps} : Fill b p → Arms a b ps → Arms a b (p :: ps)
end

mutual
theorem fill_sub {s : Skel} {p : Parser} (h : Fill s p) : SubsetL (plang p) (slang s) := by
  cases h with
  | accept =>
      intro w hw
      simpa [plang, slang] using hw
  | extract hp =>
      intro w hw
      simp [plang, slang, List.mem_map] at hw ⊢
      rcases hw with ⟨t, ht, rfl⟩
      exact ⟨t, fill_sub hp t ht, rfl⟩
  | select hps =>
      exact arms_sub hps

theorem arms_sub {a b : Skel} {ps : List Parser} (h : Arms a b ps) :
    SubsetL (plangs ps) (slang a ++ slang b) := by
  cases h with
  | nil =>
      intro w hw
      simp [plangs] at hw
  | consL hp hs =>
      intro w hw
      simp only [plangs, List.mem_append] at hw
      cases hw with
      | inl hw => exact List.mem_append.mpr (Or.inl (fill_sub hp w hw))
      | inr hw => exact arms_sub hs w hw
  | consR hp hs =>
      intro w hw
      simp only [plangs, List.mem_append] at hw
      cases hw with
      | inl hw => exact List.mem_append.mpr (Or.inr (fill_sub hp w hw))
      | inr hw => exact arms_sub hs w hw
end

theorem fill_conform {e : HExpr} {p : Parser} (h : Fill (toSkel e) p) :
    SubsetL (plang p) (lang e) :=
  fun w hw => (lang_skel e w).mp (fill_sub h w hw)

end P4Spec

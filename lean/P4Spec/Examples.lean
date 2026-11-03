import P4Spec.Skeleton

/-!
The examples from the paper, checked by computation against the definitions.
-/

namespace P4Spec

def l3 : Raw := .alt (.hdr "IPV4") (.hdr "IPV6")

def topRaw : Raw :=
  .seq (.hdr "Ether") (.seq (.var "L3") (.alt (.hdr "TCP") (.hdr "UDP")))

def topEnv : HEnv := [("L3", l3)]

def four : HExpr :=
  .seq (.hdr "Ether")
    (.seq (.nonterm "L3" (.alt (.hdr "IPV4") (.hdr "IPV6")))
      (.alt (.hdr "TCP") (.hdr "UDP")))

theorem compile_four : compile 6 topEnv topRaw = some four := by decide

def fourWords : Lang Name :=
  [ ["Ether", "IPV4", "TCP"],
    ["Ether", "IPV4", "UDP"],
    ["Ether", "IPV6", "TCP"],
    ["Ether", "IPV6", "UDP"] ]

theorem lang_four : lang four = fourWords := by decide

theorem ipv4_ipv6_exclusive : exclusive (lang four) "IPV4" "IPV6" := by
  rw [← exclusive_iff]
  decide

theorem ether_tcp_not_exclusive : ¬ exclusive (lang four) "Ether" "TCP" := by
  rw [← exclusive_iff]
  decide

theorem ether_always_valid : allContain (lang four) "Ether" := by
  rw [← allContain_iff]
  decide

/-- TCP is not on every word, so an unguarded TCP read is not justified. -/
theorem tcp_not_always_valid : ¬ allContain (lang four) "TCP" := by
  rw [← allContain_iff]
  decide

/-- The parser the compiler accepts: the default arm extracts TCP after Ethernet. -/
def etherThenTcp : Parser :=
  .extract "Ether" (.choose [
    .extract "IPV4" .accept,
    .extract "TCP" .accept
  ])

theorem ether_tcp_extracted : ["Ether", "TCP"] ∈ plang etherThenTcp := by decide

theorem ether_tcp_forbidden : ["Ether", "TCP"] ∉ lang four := by decide

theorem etherThenTcp_rejected : ¬ conformsH etherThenTcp four := by decide

def etherThenIp : Parser :=
  .extract "Ether" (.choose [.extract "IPV4" .accept])

theorem drop_tcp_arm : Trim etherThenTcp etherThenIp :=
  .extract (.chooseKeep (.extract .accept) (.chooseDrop .chooseNil))

/-- A parser that reaches TCP and UDP only after an IP header. -/
def goodParser : Parser :=
  .extract "Ether" (.choose [
    .extract "IPV4" (.choose [.extract "TCP" .accept, .extract "UDP" .accept]),
    .extract "IPV6" (.choose [.extract "TCP" .accept, .extract "UDP" .accept])
  ])

theorem goodParser_conforms : conformsH goodParser four := by decide

def tcpOnly : Parser :=
  .extract "Ether" (.choose [
    .extract "IPV4" (.choose [.extract "TCP" .accept]),
    .extract "IPV6" (.choose [.extract "TCP" .accept])
  ])

theorem drop_udp : Trim goodParser tcpOnly :=
  .extract
    (.chooseKeep
      (.extract (.chooseKeep (.extract .accept) (.chooseDrop .chooseNil)))
      (.chooseKeep
        (.extract (.chooseKeep (.extract .accept) (.chooseDrop .chooseNil)))
        .chooseNil))

theorem tcpOnly_conforms : conformsH tcpOnly four :=
  monoH drop_udp goodParser_conforms

def pipe : TExpr :=
  .seq (.alt (.atom "A") (.atom "B")) (.guard (.atom "C") (.atom "D"))

theorem hitA_hitC_allowed :
    [Event.hit "A", Event.hit "C"] ∈ tlang pipe := by decide

theorem miss_then_D_allowed :
    [Event.hit "A", Event.miss "C", Event.hit "D"] ∈ tlang pipe := by decide

theorem D_on_hit_forbidden :
    [Event.hit "A", Event.hit "C", Event.hit "D"] ∉ tlang pipe := by decide

theorem A_and_B_forbidden :
    [Event.hit "A", Event.hit "B", Event.hit "C"] ∉ tlang pipe := by decide

def afterC : AGraph :=
  .branch "C" .exit (.branch "D" .exit .exit)

def goodPipe : AGraph :=
  .either (.branch "A" afterC afterC) (.branch "B" afterC afterC)

theorem goodPipe_conforms : conformsT goodPipe pipe := by decide

/-- `D` runs on the hit branch of `C`. -/
def badPipe : AGraph :=
  .branch "A" (.branch "C" (.branch "D" .exit .exit) .exit) .exit

theorem badPipe_rejected : ¬ conformsT badPipe pipe := by decide

def cycle : HEnv := [("A", .var "A")]

theorem cycle_rejected : compile 4 cycle (.var "A") = none := by decide

end P4Spec

// Specification: (A | B) => (C -> D)
// D is applied when C hits. p4c accepts apply().hit with no pipeline check.
// The model rejects hit(A) hit(C) hit(D). D is allowed only after miss(C).
#include <core.p4>
#include <v1model.p4>

header ethernet_t { bit<48> dstAddr; bit<48> srcAddr; bit<16> etherType; }
struct headers { ethernet_t eth; }
struct metadata { }

parser MyParser(packet_in pkt, out headers hdr, inout metadata meta, inout standard_metadata_t sm) {
    state start { pkt.extract(hdr.eth); transition accept; }
}

control MyVerify(inout headers hdr, inout metadata meta) { apply { } }
control MyCompute(inout headers hdr, inout metadata meta) { apply { } }
control MyDeparser(packet_out pkt, in headers hdr) { apply { pkt.emit(hdr.eth); } }

control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t sm) {
    action nop() { }
    table A { key = { hdr.eth.etherType: exact; } actions = { nop; } default_action = nop; }
    table B { key = { hdr.eth.etherType: exact; } actions = { nop; } default_action = nop; }
    table C { key = { hdr.eth.dstAddr: exact; } actions = { nop; } default_action = nop; }
    table D { key = { hdr.eth.srcAddr: exact; } actions = { nop; } default_action = nop; }
    apply {
        if (hdr.eth.etherType == 0x0800) A.apply();
        else B.apply();
        if (C.apply().hit) D.apply();
    }
}
control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t sm) { apply { } }

V1Switch(MyParser(), MyVerify(), MyIngress(), MyEgress(), MyCompute(), MyDeparser()) main;

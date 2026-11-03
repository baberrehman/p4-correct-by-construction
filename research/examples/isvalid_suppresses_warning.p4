// SimplifyDefUse puts a header into notReport when isValid() is called,
// and both branches of the if are visited while that set is still active.
// The else branch reads ipv4 when the test failed. p4c's WARN_INVALID_HEADER
// is suppressed there. The model does not treat a mention of isValid as validity.
#include <core.p4>
#include <v1model.p4>

header ethernet_t { bit<48> dstAddr; bit<48> srcAddr; bit<16> etherType; }
header ipv4_t { bit<32> srcAddr; bit<32> dstAddr; }
struct headers { ethernet_t eth; ipv4_t ipv4; }
struct metadata { bit<32> x; bit<32> y; }

parser MyParser(packet_in pkt, out headers hdr, inout metadata meta, inout standard_metadata_t sm) {
    state start { pkt.extract(hdr.eth); transition accept; }
}

control MyVerify(inout headers hdr, inout metadata meta) { apply { } }
control MyCompute(inout headers hdr, inout metadata meta) { apply { } }
control MyDeparser(packet_out pkt, in headers hdr) { apply { pkt.emit(hdr.eth); } }

control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t sm) {
    apply {
        if (hdr.ipv4.isValid()) meta.x = hdr.ipv4.srcAddr;
        else meta.y = hdr.ipv4.srcAddr;

        hdr.ipv4.isValid();
        meta.x = hdr.ipv4.dstAddr;
    }
}
control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t sm) { apply { } }

V1Switch(MyParser(), MyVerify(), MyIngress(), MyEgress(), MyCompute(), MyDeparser()) main;

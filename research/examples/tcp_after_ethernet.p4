// Specification: Ether & (IPV4 | IPV6) & (TCP | UDP)
// The default arm extracts TCP immediately after Ethernet.
// p4c keeps the arm: it is reachable and extract() type-checks.
// The model rejects the word Ether TCP.
#include <core.p4>
#include <v1model.p4>

header ethernet_t { bit<48> dstAddr; bit<48> srcAddr; bit<16> etherType; }
header ipv4_t { bit<4> version; bit<4> ihl; bit<8> diffserv; bit<16> totalLen;
                bit<16> identification; bit<3> flags; bit<13> fragOffset;
                bit<8> ttl; bit<8> protocol; bit<16> hdrChecksum;
                bit<32> srcAddr; bit<32> dstAddr; }
header tcp_t { bit<16> srcPort; bit<16> dstPort; bit<32> seqNo; bit<32> ackNo;
               bit<4> dataOffset; bit<3> res; bit<3> ecn; bit<6> ctrl;
               bit<16> window; bit<16> checksum; bit<16> urgentPtr; }

struct headers { ethernet_t eth; ipv4_t ipv4; tcp_t tcp; }
struct metadata { }

parser MyParser(packet_in pkt, out headers hdr, inout metadata meta, inout standard_metadata_t sm) {
    state start {
        pkt.extract(hdr.eth);
        transition select(hdr.eth.etherType) {
            0x0800: parse_ipv4;
            default: parse_tcp;
        }
    }
    state parse_ipv4 { pkt.extract(hdr.ipv4); transition accept; }
    state parse_tcp  { pkt.extract(hdr.tcp);  transition accept; }
}

control MyVerify(inout headers hdr, inout metadata meta) { apply { } }
control MyCompute(inout headers hdr, inout metadata meta) { apply { } }
control MyDeparser(packet_out pkt, in headers hdr) { apply { pkt.emit(hdr.eth); } }

control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t sm) {
    apply { sm.egress_spec = 0; }
}
control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t sm) { apply { } }

V1Switch(MyParser(), MyVerify(), MyIngress(), MyEgress(), MyCompute(), MyDeparser()) main;

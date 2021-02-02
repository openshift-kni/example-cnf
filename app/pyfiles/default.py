from trex_stl_lib.api import *
import os
import sys

class STLS1(object):

    def __init__ (self):
        packet_size = os.getenv("PACKET_SIZE") or os.getenv("packet_size") or 64
        self.fsize = int(packet_size)
        self.pg_id = 0
        self.pkt_type = "ether"
        self.num_streams = 1

    def create_vm(self, direction=0):
        ip_range = {'src': {'start': "18.0.0.1", 'end': "18.0.0.254"},
                    'dst': {'start': "8.0.0.1",  'end': "8.0.0.254"}}

        if (direction == 0):
            src = ip_range['src']
            dst = ip_range['dst']
        else:
            src = ip_range['dst']
            dst = ip_range['src']

        vm = [
            # src                                                            (4)
            STLVmFlowVar(name="src",
                         min_value=src['start'],
                         max_value=src['end'],
                         size=4,op="inc"),
            STLVmWrFlowVar(fv_name="src",pkt_offset= "IP.src"),

            # dst
            STLVmFlowVar(name="dst",
                         min_value=dst['start'],
                         max_value=dst['end'],
                         size=4,op="inc"),
            STLVmWrFlowVar(fv_name="dst",pkt_offset= "IP.dst"),

            # checksum
            STLVmFixIpv4(offset = "IP")
            ]
        return vm

    def get_dest_mac(self, direction):
        lb_macs = os.environ.get('LB_MACS')
        if not lb_macs:
            print("LB_MACS environment variable is not set")
            sys.exit(1)
        macs = lb_macs.split(',')
        return macs[direction]

    def create_stream (self, direction=0):
        size = self.fsize - 4; # HW will add 4 bytes ethernet CRC

        dest_mac = self.get_dest_mac(direction)
        ethr_base = Ether(dst=dest_mac) / IP() / UDP()

        pad = max(0, size - len('ether')) * 'x'
        vm = self.create_vm(direction)
        pkt = STLPktBuilder(pkt=ethr_base/pad, vm=vm)

        streams = []
        for pg_id_add in range(0, self.num_streams):
            streams.append(STLStream(packet = pkt, mode = STLTXCont(pps=1), flow_stats = STLFlowStats(pg_id = self.pg_id + pg_id_add)))
        return STLProfile(streams).get_streams()

    def get_streams (self, direction = 0, **kwargs):
        return self.create_stream(direction=direction) 


# dynamic load - used for trex console or simulator
def register():
    return STLS1()


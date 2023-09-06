import json
from datetime import datetime
from threading import Thread

from logger import log
import trexevent

class TRexAppStats(object):
    def __init__(self, ports):
        self.ipack = [0] * len(ports)
        self.opack = [0] * len(ports)
        self.first_packet_match = False
        self.miss = []
        self.event_notified_miss = None

    def stats(self, stat, ports):
        for i in ports:
            if  stat[i]['ipackets'] < 0 or  stat[i]['opackets'] <= 0:
                log.info(f"invalid packet count - port({i}) out({stat[i]['opackets']}) id({stat[i]['ipackets']})")
                return

        ipack = 0
        opack = 0
        for i in ports:
            ipack += stat[i]['ipackets'] - self.ipack[i]
            opack += stat[i]['opackets'] - self.opack[i]
            self.ipack[i] = stat[i]['ipackets']
            self.opack[i] = stat[i]['opackets']

        if ipack < 0 or opack < 0:
            log.info(f"invalid packet count - out({opack}) id({ipack})")
            return

        if not self.first_packet_match:
            if ipack >= opack and opack != 0:
                self.first_packet_match = True
            else:
                log.info(f"still waiting for first packet match - out({opack}) > in({ipack})")
                return

        if ipack >= opack:
            log.info(f"MATCH: out({opack}) > in({ipack})")
            self.notify_event(False)
            if self.miss and not self.miss[-1].get('end'):
                self.miss[-1]['end'] = datetime.now()
                log.info(f"Loss recovery: {self.miss[-1]['end'] - self.miss[-1]['start']}")
        else:
            log.info(f"MISS:  out({opack}) > in({ipack})")
            self.notify_event(True)
            if self.miss and not self.miss[-1].get('end'):
                self.miss.append({'start': datetime.now()})

    def notify_event(self, miss=False):
        if self.event_notified_miss != miss:
            data = {}
            now = datetime.now()
            data['microtime'] = now.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
            data['time'] = now.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
            if miss:
                data['msg'] = ("Packet miss started")
                data['reason'] = 'PacketDropped'
            else:
                data['msg'] = ("Packet miss recovered")
                data['reason'] = 'PacketMatched'
            log.info("%s at %s" % (data['reason'], data['microtime']))
            Thread(target=trexevent.create_event, args=[data]).start()
            self.event_notified_miss = miss

force_exit = False
stats_period = os.getenv("STATS_PERIOD") or 5
stats_period = int(stats_period)

def watch(client, ports):
    stats_obj = TRexAppStats(ports)
    count = 0
    while True:
        if force_exit:
            break
        count += 1
        if (count % stats_period == 0):
            stats_obj.stats(client.get_stats(), ports=ports)
            count = 0
        time.sleep(1)


def started(profile, packet_rate, duration):
    if not profile:
        profile = "default"
    data = {}
    now = datetime.now()
    data['microtime'] = now.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    data['time'] = now.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    data['msg'] = ("Started streams with profile ({0}) at rate ({1}) "
                    "for ({2})s ".format(profile, packet_rate, duration))
    data['reason'] = 'TestStarted'
    trexevent.create_event(data)

def completed_stats(stats, warnings, port_a, port_b, profile, rate, duration):
    size = os.getenv("PACKET_SIZE")
    data = {}
    now = datetime.now()
    data['microtime'] = now.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    data['time'] = now.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    if profile:
        msg = (f"Profile ({profile}) ")
    else:
        msg = (f"Profile (default) with size ({size}) ")
    msg += (f"with rate ({rate}) for ({duration})s have completed")
    data['msg'] = msg
    data['reason'] = 'TestCompleted'
    trexevent.create_event(data)

    passed = False
    log.info(json.dumps(stats[port_a], indent = 4, separators=(',', ': '), sort_keys = True))
    log.info(json.dumps(stats[port_b], indent = 4, separators=(',', ': '), sort_keys = True))

    lost_a = stats[port_a]["opackets"] - stats[port_b]["ipackets"]
    percentage_lost_a = lost_a * 100.0 / stats[port_a]["opackets"]
    lost_b = stats[port_b]["opackets"] - stats[port_a]["ipackets"]
    percentage_lost_b = lost_b * 100.0 / stats[port_b]["opackets"]
    lost = lost_a + lost_b
    packets = stats[port_a]["opackets"] + stats[port_b]["opackets"]
    total_lost = lost * 100.0 / packets

    log.info(f"\nPackets lost from {port_a} to {port_b}:   {lost_a} packets, which is {percentage_lost_a}% packet loss")
    log.info(f"Packets lost from {port_b} to {port_a}:   {lost_b} packets, which is {percentage_lost_b}% packet loss")
    log.info(f"Total packets lost: {lost} packets, which is {total_lost}% packet loss")

    if warnings:
        log.info("\n\n*** test had warnings ****\n\n")
        for w in warnings:
            log.info(w)

    if lost <= 0 and not warnings:
        passed = True
        data['msg'] = (f"Test has passed with no packet loss, total packets: {packets}")
        data['reason'] = 'TestPassed'
    else:
        data['msg'] = (f"Test has failed with {lost} packets lost, resulting in {total_lost}% packet loss")
        data['reason'] = 'TestFailed'

    trexevent.create_event(data)
    return passed

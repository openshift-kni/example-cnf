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
                log.info("invalid packet count - port(%s) out(%s) id(%s)" % (i,
                         stat[i]['opackets'], stat[i]['ipackets']))
                return

        ipack = 0
        opack = 0
        for i in ports:
            ipack += stat[i]['ipackets'] - self.ipack[i]
            opack += stat[i]['opackets'] - self.opack[i]
            self.ipack[i] = stat[i]['ipackets']
            self.opack[i] = stat[i]['opackets']

        if ipack < 0 or opack < 0:
            log.info("invalid packet count - out(%s) id(%s)" % (opack, ipack))
            return

        if not self.first_packet_match:
            if ipack >= opack and opack != 0:
                self.first_packet_match = True
            else:
                log.info("still waiting for first packet match - out(%s) > in(%s)" % (opack, ipack))
                return

        if ipack >= opack:
            log.info("MATCH: out(%s) > in(%s)" % (opack, ipack))
            self.notify_event(False)
            if self.miss and not self.miss[-1].get('end'):
                self.miss[-1]['end'] = datetime.now()
                log.info("Loss recovery: %s" % (self.miss[-1]['end'] - self.miss[-1]['start']))
        else:
            log.info("MISS:  out(%s) > in(%s)" % (opack, ipack))
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
        msg = ("Profile (%s) " % profile)
    else:
        msg = ("Profile (default) with size (%s) " % size)
    msg += ("with rate (%s) for (%s)s have completed" % (rate, duration))
    data['msg'] = msg
    data['reason'] = 'TestCompleted'
    trexevent.create_event(data)

    passed = False
    log.info(json.dumps(stats[port_a], indent = 4, separators=(',', ': '), sort_keys = True))
    log.info(json.dumps(stats[port_b], indent = 4, separators=(',', ': '), sort_keys = True))

    lost_a = stats[port_a]["opackets"] - stats[port_b]["ipackets"]
    lost_b = stats[port_b]["opackets"] - stats[port_a]["ipackets"]
    lost = lost_a + lost_b

    log.info("\npackets lost from {0} --> {1}:   {2} pkts".format(port_a, port_b, lost_a))
    log.info("packets lost from {0} --> {1}:   {2} pkts".format(port_b, port_a, lost_b))
    log.info("packet lost total: {} pkts".format(lost))

    if warnings:
        log.info("\n\n*** test had warnings ****\n\n")
        for w in warnings:
            log.info(w)

    if lost <= 0 and not warnings:
        passed = True
        packets = stats[port_a]["opackets"] + stats[port_b]["opackets"]
        data['msg'] = ("Test has Passed with no loss, total packets {}".format(packets))
        data['reason'] = 'TestPassed'
    else:
        data['msg'] = ("Test has failed with packets loss of {} pkts".format(lost))
        data['reason'] = 'TestFailed'

    trexevent.create_event(data)
    return passed

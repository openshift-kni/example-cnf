# cnfapp

Container image that allows you to configure Grout in a container and prepare it to launch it.

## What is it executed?

The same container image is used for the `grout` and `frr` containers and for their two init containers, `grout-init` and `frr-init`. The entrypoint is [`/grout-wrapper`](scripts/grout-wrapper). The argument selects the role.

### grout-init

`generate-grout-config` writes `/run/grout/cfg/grout.init`, later mounted in the `grout` container at `/etc/grout.init`. It needs `NETWORK_NAME_LIST` and reads `rx_queues`. PCI addresses come from the `PCIDEVICE_OPENSHIFT_IO_*` variables injected for those resources. IP addresses come from the pod network annotations at `/etc/podnetinfo/annotations`.

### frr-init

`generate-frr-config` writes `/run/frr/cfg/daemons` and `/run/frr/cfg/frr.conf`. The `frr` container mounts those files at `/etc/frr/daemons` and `/etc/frr/frr.conf`.

### grout

The `grout` argument is the image default. It starts the HTTP probe server on port 8095, then runs Grout. When `run_deployment` is `1` (the default), Grout stays in the background and the wrapper prints software statistics to `/var/log/grout/app.log`.

When Grout starts, the following logs are printed. The EAL CPU list comes from the node the pod landed on:

```
NOTICE: GROUT: main: starting grout version v0.9.1-0-g755f158c
NOTICE: GROUT: main: License available at https://git.dpdk.org/apps/grout/plain/LICENSE
INFO: GROUT: dpdk_init: DPDK 24.11.1
INFO: GROUT: dpdk_init: EAL arguments: -l 3 -a 0000:00:00.0 --in-memory
NOTICE: EAL: 8000 hugepages of size 2097152 reserved, but no mounted hugetlbfs found for that size
INFO: GROUT: dpdk_init: running control plane on CPU 3
INFO: GROUT: dpdk_init: datapath workers allowed on CPUs 5,51,53
INFO: GROUT: api_socket_start: listening on API socket /run/grout/api.sock
```

That socket is `/run/grout/api.sock` (`GROUT_SOCK_PATH`). `grcli` uses it to talk to Grout without keeping an interactive session open. The `frr` container uses the same socket.

The config file to be used to inject the network information is saved under `/etc/grout.init`, and it includes:

- The PCI addresses to be used for each interface. The MAC addresses are automatically injected by Grout once you create the interface.
- The IP address to be used per interface. These are retrieved from the pod annotations saved in the container's context.

This is an example of what we could find in that config file:

```
sh-4.4$ cat /etc/grout.init
interface add port p0 devargs 0000:86:02.1 rxqs 2
interface add port p1 devargs 0000:86:03.3 rxqs 2
address add 192.168.16.60/26 iface p0
address add 192.168.16.100/26 iface p1
```

To deploy that config, we use the `grcli` command. If using `-f` argument, we will run all the commands that are defined in the file. This is handled in fact by `/grout-wrapper` command with `poststart-grout` argument.

If just using `grcli`, we'll open a CLI session with Grout and we can start interacting with the service. And also, we can use `grcli` followed by a Grout command to perform a particular action.

For example, we can print statistics in the following way:

```
# clear statistics
$ grcli stats reset

# print statistics
$ grcli stats show software
NODE                            CALLS  PACKETS  PKTS/CALL  CYCLES/CALL     CYCLES/PKT
port_rx                  109805489408     2104        0.0         49.2   2567088141.0
control_input            109805489408       39        0.0         22.6  63637321574.4
ndp_na_input                     1130     1130        1.0   10250215.9     10250215.9
arp_input_reply                   573      573        1.0   10597720.0     10597720.0
arp_input_request                  43       53        1.2   12147116.4      9855207.6
eth_input                        2079     2104        1.0       1830.7         1808.9
control_output                    320      320        1.0       9132.7         9132.7
ndp_na_input_drop                1130     1130        1.0       1938.0         1938.0
ip6_input                        1232     1232        1.0       1678.0         1678.0
arp_input_reply_drop              283      283        1.0       2200.5         2200.5
icmp6_input                      1232     1232        1.0        470.0          470.0
arp_input                         616      626        1.0        675.6          664.8
port_tx                           209      209        1.0       1714.8         1714.8
ip6_input_local                  1232     1232        1.0        290.2          290.2
ip_input                          194      194        1.0       1571.1         1571.1
icmp6_input_unsupported           102      102        1.0       2354.5         2354.5
ip_output                         196      194        1.0        792.7          800.9
eth_output                        209      209        1.0        451.4          451.4
icmp_output                        53       53        1.0       1466.5         1466.5
arp_input_request_drop             37       47        1.3       2011.1         1583.2
ip_forward                        141      141        1.0        398.3          398.3
icmp_local_send                    22       22        1.0       2478.4         2478.4
eth_input_unknown_vlan             38       52        1.4       1428.6         1044.0
icmp_input                         53       53        1.0        996.2          996.2
arp_output_request                  9        9        1.0       2596.2         2596.2
ip_input_local                     53       53        1.0        392.8          392.8
arp_output_reply                    6        6        1.0        680.0          680.0
ip_hold                             2        2        1.0        275.0          275.0
```

Also, you can trace the traffic received by Grout with the following configuration.

> Note trace should not be used during performance testing, since it impacts performance. Just use it for troubleshooting purposes.

```
# enter in grout CLI
$ grcli
grout# trace enable all

# if you get the latest N traces of traffic managed by Grout, you
# will be able to see traffic details.
grout# trace show count 50
...
--------- 08:25:08.558489191 cpu 2 ---------
port_rx: port=0 queue=1
eth_input: 20:04:0f:f1:89:01 > 00:11:22:33:00:01 type=IP(0x0800) iface=p0                   
ip_input: 192.168.56.61 > 192.168.56.101 ttl=64 proto=UDP(17)                               
ip_forward:
ip_output: 192.168.56.61 > 192.168.56.101 ttl=63 proto=UDP(17)                              
eth_output: 00:11:22:33:00:02 > 20:04:0f:f1:89:02 type=IP(0x0800) iface=p1                  
port_tx: port=1 queue=1

# you can clear the trace in this way
grout# trace clear

# you can remove the trace in this way
grout# trace disable all
```

### frr

The `frr` argument waits for `/run/grout/api.sock`, then starts the FRR daemons with `watchfrr`. `daemons` and `frr.conf` are the files written by `frr-init`. `vtysh.conf` comes from the FRR package in the image.

```
sh-5.2$ ls /etc/frr           
daemons  frr.conf  vtysh.conf
sh-5.2$ cat /etc/frr/daemons 
bgpd=yes
vtysh_enable=yes
zebra_options="--limit-fds 100000 -F traditional -A 127.0.0.1 -s 90000000 --log file:/var/log/grout/frr-zebra.log -M dplane_grout"
mgmtd_options="--limit-fds 100000 -F traditional -A 127.0.0.1 --log file:/var/log/grout/frr-mgmtd.log"
staticd_options="--limit-fds 100000 -F traditional -A 127.0.0.1 --log file:/var/log/grout/frr-staticd.log"
sh-5.2$ cat /etc/frr/frr.conf 
frr defaults traditional
!
vrf main
exit-vrf
!
```

With the following command, you can check the status of all FRR-related services:

```
$ sudo /usr/libexec/frr/frrinit.sh status
Status of watchfrr: running
Status of mgmtd: running
Status of zebra: running
Status of bgpd: running
Status of staticd: running
```

With `vtysh`, you can interact with the FRR through a CLI:

```
$ vtysh

Hello, this is FRRouting (version 10.7.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

grout-app-b677b8944-qgzbt#
```

Finally, in the `zebra.log` file, you should see that Grout is connected to the Zebra module from FRR:

```
$ sudo cat /var/log/grout/frr-zebra.log 
2026/10/23 15:36:41 ZEBRA: [SAPXX-HP5B5][EC 4043309108] Extended Error: failed to retrieve link settings
2026/10/23 15:36:41 ZEBRA: [WVJCK-PPMGD][EC 4043309093] generic-netlink-cmd (NS 0) error: Operation not supported, type=RTM_GETADDR(22), seq=3, pid=21
2026/10/23 15:36:41 ZEBRA: [QBKSZ-0KHCW][EC 4043309138] Disabling MPLS support (no kernel support)
2026/10/23 15:36:41 ZEBRA: [T83RR-8SM5G] zebra 10.7.1 starting: vty@2601
2026/10/23 15:36:41 ZEBRA: [SWBGA-5162C][EC 100663342] nb_op_ys_finalize_node_info: list entry lookup failed
2026/10/23 15:36:41 ZEBRA: GROUT: zebra_grout_connect: connected, monitoring route/nexthop events
2026/10/23 15:36:41 ZEBRA: GROUT: dplane_grout_connect: connected, monitoring iface/ip events
2026/10/23 15:36:41 ZEBRA: [K55SV-YMF8X] Sweeping the RIB for stale routes...
2026/10/23 15:36:41 ZEBRA: [V98V0-MTWPF] client 19 says hello and bids fair to announce only bgp routes vrf=0
2026/10/23 15:36:41 ZEBRA: [V98V0-MTWPF] client 37 says hello and bids fair to announce only vnc routes vrf=0
2026/10/23 15:36:41 ZEBRA: [V98V0-MTWPF] client 45 says hello and bids fair to announce only static routes vrf=0
2026/10/23 15:36:41 ZEBRA: [VTVCM-Y2NW3] Configuration Read in Took: 00:00:00
2026/10/23 15:36:41 ZEBRA: [G6NKK-8C6DV] end_config: VTY:0x55b3750c6ba0, pending SET-CFG: 0
2026/10/23 15:36:42 ZEBRA: [V98V0-MTWPF] client 52 says hello and bids fair to announce only bgp routes vrf=0
```

## What to update if bumping container version

Apart from the modifications you have to do, you also need to update the container version in these files:

- [Containerfile](Containerfile).
- [build.sh](../build.sh) (from parent folder).
- [Makefile](../Makefile) (from parent folder).

Here's an [example](https://github.com/openshift-kni/example-cnf/pull/111) where this is done.

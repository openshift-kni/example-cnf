# cnfapp

Container image that allows you to configure Grout in a container and prepare it to launch it.

## What is it executed?

This container runs `/usr/local/bin/example-cnf/grout-wrapper`. [This script](scripts/grout-wrapper) starts running `grout` in background mode, and then it retrieves context information to build the command to run `grcli` command-line tool to inject all the network configuration that is required for the tests.

When calling to `grout` service, the following logs are printed, showing you that it already takes some EAL parameters from the running execution context:

```
NOTICE: GROUT: main: starting grout version v0.9.1-0-g755f158c
NOTICE: GROUT: main: License available at https://git.dpdk.org/apps/grout/plain/LICENSE
INFO: GROUT: dpdk_init: DPDK 24.11.1
INFO: GROUT: dpdk_init: EAL arguments: -l 3 -a 0000:00:00.0 --in-memory
NOTICE: EAL: 8000 hugepages of size 2097152 reserved, but no mounted hugetlbfs found for that size
INFO: GROUT: dpdk_init: running control plane on CPU 3
INFO: GROUT: dpdk_init: datapath workers allowed on CPUs 5,51,53
INFO: GROUT: api_socket_start: listening on API socket grout.sock
```

This creates an abstract API socket, `grout.sock`, that allows us to interact with Grout through CLI, but not requiring to maintain an interactive session to make it work, like it happened with TestPMD.

The config file to be used to inject the network information is saved under `/usr/local/bin/example-cnf/run/grout.init`, and it includes:

- The PCI addresses to be used for each interface. The MAC addresses are automatically injected by Grout once you create the interface.
- The IP address to be used per interface. These are retrieved by [this script](scripts/retrieve-grout-ip-addresses), which is placed on `/usr/local/bin/example-cnf/retrieve-grout-ip-addresses`

This is an example of what we could find in that config file:

```
sh-4.4$ cat /usr/local/bin/example-cnf/run/grout.init
interface add port p0 devargs 0000:86:02.1 rxqs 2
interface add port p1 devargs 0000:86:03.3 rxqs 2

address add 172.16.16.60/24 iface p0
address add 172.16.21.60/24 iface p1
```

The file created by the automation to launch the Grout configuration is saved under `/usr/local/bin/example-cnf/run/grout.sock`, and it has the following content:

```
sh-4.4$ cat config-grout
grcli -f /usr/local/bin/example-cnf/run/grout.init -s /usr/local/bin/example-cnf/run/grout.sock 2>&1 | tee /var/log/grout/app.log
```

To deploy that config, we use the `grcli` command. If using `-f` argument, we will run all the commands that are defined in the file. If just using `grcli`, we'll open a CLI session with Grout and we can start interacting with the service. And also, we can use `grcli` followed by a Grout command to perform a particular action.

We use `-s` argument to refer to a specific location of the Grout socket API file.

For example, we can print statistics in the following way:

```
# clear statistics
$ sudo grcli -s /usr/local/bin/example-cnf/run/grout.sock stats reset

# print statistics
$ sudo grcli -s /usr/local/bin/example-cnf/run/grout.sock stats show software
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
$ grcli -s /usr/local/bin/example-cnf/run/grout.sock
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

## What to update if bumping container version

Apart from the modifications you have to do, you also need to update the container version in these files:

- [Dockerfile](Dockerfile).
- [build.sh](../build.sh) (from parent folder).
- [Makefile](../Makefile) (from parent folder).

Here's an [example](https://github.com/openshift-kni/example-cnf/pull/111) where this is done.

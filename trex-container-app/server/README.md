# server

Container image that configures TRex and launches it.

## What is it executed?

PID 1 is `catatonit`, which runs [`/trex-wrapper`](scripts/trex-wrapper). The container argument selects the command. The default is `trex`.

`trex` starts the HTTP probe server on port 8096, then builds the TRex config. [`/trex-cfg-configure`](scripts/trex-cfg-configure) reads the CPU list of this container (`taskset -pc 1`) and writes `/tmp/trex/trex_cfg.yaml`. The file is written here, in the server container: the CPU manager pins this container to the `cpu` exclusive CPUs, and an init container would be pinned to a different set. `c` in the file is that list minus the master and latency threads. `TREX_CPU`, set from the `cpu` request, must equal `c + 2`. An optional `trex_core_count` environment variable overrides `c` after the file is written.

When `run_deployment` is `1` (the default), the wrapper starts TRex:

```
sudo -E /opt/trex/trex-core/scripts/_t-rex-64 --cfg /tmp/trex/trex_cfg.yaml --no-ofed-check -i --no-hw-flow-stat -c <c>
```

`-i` is interactive mode. The server accepts traffic profiles from the TRexApp job and prints statistics. It does not generate the traffic. `poststart-trex` waits until port 4500 accepts connections.

When `run_deployment` is `0`, the config file is still written and the process sleeps. Start TRex later with the command above. The `-c` argument is the `c` value in the yaml.

This is an example of a TRex configuration file for L2 configuration:

```
sh-4.4$ cat /tmp/trex/trex_cfg.yaml 
- c: 4
  interfaces:
  - '86:02.3'
  - '86:03.2'
  platform:
    dual_if:
    - socket: 1
      threads:
      - 7
      - 51
      - 53
      - 55
    latency_thread_id: 5
    master_thread_id: 3
  port_info:
  - dest_mac: 80:04:0f:f1:89:01
    src_mac: 20:04:0f:f1:89:01
  - dest_mac: 80:04:0f:f1:89:02
    src_mac: 20:04:0f:f1:89:02
  version: 2
```

You can see it saves in the config file the following information, among others:

- PCI addresses to use.
- NUMA socket and the CPU list for the master thread, the latency thread, and the worker threads.
- Pair of destination and source MAC addresses for each port. L3 adds the local IP and the gateway.

And here, you have a TRex configuration file for L3 configuration, where the IP address of both TRex and the endpoint is added for each port:

```
sh-4.4$ cat /tmp/trex/trex_cfg.yaml 
- c: 4
  interfaces:
  - '37:02.6'
  - '37:03.4'
  platform:
    dual_if:
    - socket: 0
      threads:
      - 3
      - 41
      - 42
      - 43
    latency_thread_id: 2
    master_thread_id: 1
  port_info:
  - default_gw: 192.168.16.60
    dest_mac: 80:04:0f:f1:89:01
    ip: 192.168.16.61
    src_mac: 20:04:0f:f1:89:01
  - default_gw: 192.168.16.100
    dest_mac: 80:04:0f:f1:89:02
    ip: 192.168.16.101
    src_mac: 20:04:0f:f1:89:02
  version: 2
```

`c: 4` is the value passed to `_t-rex-64 -c`. Traffic generation is done by the TRexApp job, not by this container.

You have more details about testing this feature in the [testing docs](../../documentation/testing.md).

## What to update if bumping container version

Apart from the modifications you have to do, you also need to update the container version in these files:

- [Containerfile](Containerfile).
- [build.sh](../build.sh) (from parent folder).
- [Makefile](../Makefile) (from parent folder).

Here's an [example](https://github.com/openshift-kni/example-cnf/pull/111) where this is done.

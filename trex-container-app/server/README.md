# server

Container image that allows you to configure TRex in a container and prepare it to launch it.

## What is it executed?

This container runs `/usr/local/bin/trex-wrapper`. [This script](scripts/trex-wrapper) takes also some context information to build a config file for TRex, such as this one:

```
sh-4.4$ pwd
/usr/local/bin/example-cnf
sh-4.4$ ls
trex-server-run  trex_cfg.yaml
sh-4.4$ cat trex_cfg.yaml 
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
- Number of sockets.
- CPUs to be used.
- Pair of destination-source MAC addresses for each port.

Then, it builds a script file, placed in `/usr/local/bin/example-cnf/trex-server-run`, with the following content:

```
sh-4.4$ cat /usr/local/bin/example-cnf/trex-server-run
/usr/local/bin/trex-server 4
```

This calls to [trex-server](scripts/trex-server) script, passing 4 as argument which represents the number of coures to use, which launches `_t-rex-64` binary using the generated config file (`--cfg` argument), using interactive mode (`-i` argument), which allows to print statistics regularly. This does not launch the traffic generation, since this is done with the TRexApp job.

You have more details about testing this feature in the [testing docs](../../documentation/testing.md).

## What to update if bumping container version

Apart from the modifications you have to do, you also need to update the container version in these files:

- [Dockerfile](Dockerfile).
- [build.sh](../build.sh) (from parent folder).
- [Makefile](../Makefile) (from parent folder).

Here's an [example](https://github.com/openshift-kni/example-cnf/pull/111) where this is done.

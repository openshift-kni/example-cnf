# cnfapp

Container image that allows you to configure TestPMD in a container and prepare it to launch it.

## What is it executed?

This container runs `/usr/local/bin/example-cnf/testpmd-wrapper`. [This script](scripts/testpmd-wrapper) retrieves context information to build the command to run `testpmd` command-line tool. Then, depending on the selected mode to launch Example CNF, `testpmd` will be executed in auto-start mode (baseline scenario), or, if launching the troubleshooting scenario, you can select between that mode and the interactive mode.

The scripts (generated by `testpmd-wrapper`) to deploy each mode are placed in the same directory:

```
sh-4.4$ pwd
/usr/local/bin/example-cnf/run
sh-4.4$ ls
testpmd-interactive  testpmd-run
```

They present some differences:

- `testpmd-run`: runs `testpmd` in auto-start mode.

```
sh-4.4$ cat testpmd-run
/usr/local/bin/example-cnf/testpmd -l 3,5,53 --in-memory  -a 0000:86:02.2  -a 0000:86:03.0  --socket-mem 0,1024 -n 6 --proc-type auto --file-prefix pg -- --nb-cores=2 --rxq=1 --txq=1 --rxd=2048 --txd=2048 --auto-start  --eth-peer 0,20:04:0f:f1:89:01 --eth-peer 1,20:04:0f:f1:89:02 --forward-mode=mac --stats-period 1 2>&1 | tee /var/log/testpmd/app.log
```

The call to `testpmd` receives, as arguments (remember we have to differentiate between [EAL parameters](https://doc.dpdk.org/guides/linux_gsg/linux_eal_parameters.html) and [TestPMD parameters](https://doc.dpdk.org/guides/testpmd_app_ug/run_app.html), they're separated by `--`), the following parameters:

- CPU cores to bind to `testpmd`. This matches with the number of cores assigned for the pod that is launching this container. If using reduced mode, only three cores are used: first CPU for the console, and second core CPU (two siblings) for `testpmd` execution. This modification is managed by `testpmd-wrapper`.
- Option to not create any shared data structures and run entirely in memory.
- PCI addresses.
- Preallocation of specific amounts of memory per socket. Depending on the NUMA node that is used, `testpmd-wrapper` will tune this value.
- Number of memory channels to use.
- Type of current process as `auto`.
- Shared data file prefix for DPDK process named as `pg`
- Number of forwarding cores.
- Number of TX/RX queues.
- Number of descriptors in the TX/RX rings. These values are doubled if using reduced mode, everything managed by `testpmd-wrapper`.
- Enable auto-start mode.
- Provide the pair of port-MAC address for each port.
- Enable MAC forwarding mode.
- Print the statistics every minute.

Finally, redirect the logs to `/var/log/testpmd/app.log`

- `testpmd-interactive`: runs `testpmd` in interactive mode.

```
sh-4.4$ cat testpmd-interactive 
/usr/local/bin/example-cnf/testpmd -l 3,5,53 --in-memory  -a 0000:86:02.2  -a 0000:86:03.0  --socket-mem 0,1024 -n 6 --proc-type auto --file-prefix pg -- --nb-cores=2 --rxq=1 --txq=1 --rxd=2048 --txd=2048 --i  --eth-peer 0,20:04:0f:f1:89:01 --eth-peer 1,20:04:0f:f1:89:02 --forward-mode=mac
```

Parameters are mostly similar than in the previous case, but with the following differences:

- Use interactive mode (`--i`) instead of auto-start mode (`--auto-start`).
- Do not print statistics, since they can be retrieved manually.

You have more details about testing this feature in the [testing docs](../../documentation/testing.md).

## What to update if bumping container version

Apart from the modifications you have to do, you also need to update the container version in these files:

- [Dockerfile](Dockerfile).
- [build.sh](../build.sh) (from parent folder).
- [Makefile](../Makefile) (from parent folder).

Here's an [example](https://github.com/openshift-kni/example-cnf/pull/111) where this is done.

# app

Container image that allows you to configure a traffic profile for TRex and deploy it in a running TRex instance.

## What is it executed?

PID 1 is `catatonit`, which runs [`/trex-wrapper`](scripts/trex-wrapper). This is a different script from the [server](../server) image.

The wrapper starts the HTTP probe server on port 8095 and waits until `TREX_SERVER_URL` (the job sets `trex-server`) accepts connections on port 4500. When `run_deployment` is `1`, it waits 10 seconds and runs [`/run-trex`](scripts/run-trex). That script builds the traffic profile from the job variables (`DURATION`, `PACKET_SIZE`, `PACKET_RATE`, `trex_ip_list`, `cnfapp_ip_list`, `arp_resolution`) and starts sending traffic. When `run_deployment` is `0`, the process sleeps after the server is ready. Run `/run-trex` to start the profile.

If using IP addresses, the TRex profile will use them. We can also set up an ARP resolution process, so that TRex send one ARP request through each interface to resolve the MAC-IP association of the endpoint.

If defining a duration, a timeout will be enabled to stop the execution after the given duration, and then statistics will be printed and packet loss will be calculated. If packet loss is equal or less than 0, this means there's no packet loss, else, packet loss is present and the pod status will be different than Completed.

You have more details about testing this feature in the [testing docs](../../documentation/testing.md).

## What to update if bumping container version

Apart from the modifications you have to do, you also need to update the container version in these files:

- [Containerfile](Containerfile).
- [build.sh](../build.sh) (from parent folder).
- [Makefile](../Makefile) (from parent folder).

Here's an [example](https://github.com/openshift-kni/example-cnf/pull/111) where this is done.

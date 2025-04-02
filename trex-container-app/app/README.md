# app

Container image that allows you to configure a traffic profile for TRex and deploy it in a running TRex instance.

## What is it executed?

This container runs `/usr/local/bin/trex-wrapper` (but a different one compared to `server`). [This script](scripts/trex-wrapper) triggers a [custom Python script](scripts/run-trex) that builds the traffic profile, according to the TRex variables provided in the pipeline (duration of the job, packet size, data rate, etc.), and start sending the traffic.

If using IP addresses, the TRex profile will use them. We can also set up an ARP resolution process, so that TRex send one ARP request through each interface to resolve the MAC-IP association of the endpoint.

If defining a duration, a timeout will be enabled to stop the execution after the given duration, and then statistics will be printed and packet loss will be calculated. If packet loss is equal or less than 0, this means there's no packet loss, else, packet loss is present and the pod status will be different than Completed.

You have more details about testing this feature in the [testing docs](../../documentation/testing.md).

## What to update if bumping container version

Apart from the modifications you have to do, you also need to update the container version in these files:

- [Dockerfile](Dockerfile).
- [build.sh](../build.sh) (from parent folder).
- [Makefile](../Makefile) (from parent folder).

Here's an [example](https://github.com/openshift-kni/example-cnf/pull/111) where this is done.

# Grout Ansible Role

This Ansible role (`grout`) is designed to deploy and manage the Grout application in a Kubernetes/OpenShift environment. It automates the creation of necessary Kubernetes resources, parses network definitions, and configures the Grout deployment according to user-specified parameters.

## Default Variables

The following variables are defined in [`defaults/main.yml`](defaults/main.yml):

| Variable              | Default Value                                                                                                         | Description                                                                                                 |
|-----------------------|------------------------------------------------------------------------------------------------------------------     |-------------------------------------------------------------------------------------------------------------|
| `image_grout`         | quay.io/rh-nfv-int/grout-container-app-cnfapp@sha256:112bed772707280de16a64eb4fb3c3c0ec027fa030372dff05927d105bc822fd | Container image for the Grout application.                                                                  |
| `size`                | 1                                                                                                                     | Number of replicas for the Grout deployment.                                                                |
| `skip_annot`          | false                                                                                                                 | Whether to skip annotation steps.                                                                           |
| `networks`            | []                                                                                                                    | List of network definitions (see below for structure).                                                      |
| `image_pull_policy`   | IfNotPresent                                                                                                          | Image pull policy for the Grout container (`Always`, `IfNotPresent`, or `Never`).                           |
| `privileged`          | false                                                                                                                 | Whether to run the frr container in privileged mode (grout already runs in privileged mode).                |
| `hugepage_1gb_count`  | 4Gi                                                                                                                   | Amount of 1Gi hugepages to allocate.                                                                        |
| `memory`              | 1000Mi                                                                                                                | Memory request for the Grout container.                                                                     |
| `cpu`                 | 4                                                                                                                     | CPU request for the Grout container.                                                                        |
| `network_resources`   | {}                                                                                                                    | Internal variable for tracking network resource usage.                                                      |
| `resources`           | []                                                                                                                    | List of additional resources to be used.                                                                    |
| `environments`        | {}                                                                                                                    | Environment variables to set in the container.                                                              |
| `rx_queues`           | 2                                                                                                                     | Number of RX queues.                                                                                        |
| `trex_maclist`        | []                                                                                                                    | TRex MAC address for each local interface, in the same order as `networks`. CR field `trexMaclist`.         |
| `trex_iplist`         | []                                                                                                                    | TRex IP address (with prefix) for each local interface, same order. CR field `trexIplist`.                  |

### Example `networks` Variable Structure

The `networks` variable is a list of dictionaries, each describing a network attachment. Example:

```
"networks": [
    {
        "count": 1,
        "ip": [
            "192.168.36.60/26"
        ],
        "mac": [
            "80:03:0f:f1:89:01"
        ],
        "name": "example-cnf-net1"
    },
    {
        "count": 1,
        "ip": [
            "192.168.36.100/26"
        ],
        "mac": [
            "80:03:0f:f1:89:02"
        ],
        "name": "example-cnf-net2"
    }
]
```

## How the Ansible Tasks Work

The Grout role uses a series of Ansible tasks (see [`tasks/main.yml`](tasks/main.yml)) to automate the deployment and configuration of the Grout application. Here is an overview of the main steps:

1. **Initialization**:  
   The role initializes internal variables such as `network_resources` (to track network resource usage) and `network_name_list` (to keep a list of network names).

2. **Input Validation**:  
   The role checks that at least one of the `networks` or `resources` variables is provided. If both are empty, the playbook fails with an error.

3. **Network Parsing**:  
   If the `networks` variable is defined and not empty, the role loops through each network entry and includes the `network-parse.yaml` task file. This subtask:
   - Extracts the network name and details.
   - Looks up the corresponding `NetworkAttachmentDefinition` in the cluster.
   - Gathers resource names, counts, and updates the `network_resources` dictionary accordingly.
   - Handles duplicate resources by incrementing their counts.
   - Collects a list of all network names used.

4. **Resource Parsing**:  
   If `resources` are defined and `networks` is empty, the role populates `network_resources` directly from the `resources` list.

5. **Debugging and Output**:  
   Throughout the process, the role prints debug information for variables like `networks`, `resources`, `network_resources`, and `network_name_list` to aid troubleshooting.

6. **Kubernetes Resource Creation**:  
   The role then creates the necessary Kubernetes resources for the Grout application:
   - **ServiceAccount**: For the Grout pod to interact with the cluster.
   - **Role and RoleBinding**: To grant the required permissions.
   - **Deployment**: To launch the Grout application pods using the specified configuration.
   - **PodDisruptionBudget**: To ensure high availability during node maintenance or upgrades.

These tasks ensure that the Grout application is deployed with the correct network attachments, resource allocations, and permissions, based on the variables you provide to the role.

## Deployment Details

The Grout role creates a Kubernetes `Deployment` resource to manage the lifecycle of the Grout application pods. This deployment is defined using a Jinja2 template (`deployment.yml`) and is rendered with the variables you provide to the role.

Each pod runs two init containers, then two application containers, all from `image_grout` (`image_pull_policy` sets the pull policy). The same image covers every role; the container argument selects which one runs. See the cnfapp [README](../../../grout-container-app/cnfapp/README.md#what-is-it-executed). The pod runs as non-root (`runAsUser` 56560) under the `grout-account` ServiceAccount. The init containers write configuration into shared `emptyDir` volumes that the application containers mount.

### Init containers

- **`grout-init`** (`generate-grout-config`): Builds `grout.init` from the SR-IOV PCI devices and the pod network annotations. It requests the same network resources as the dataplane container so those devices are visible, and reads `NETWORK_NAME_LIST` and `rx_queues`. The annotations come from a downward API volume (`grout-podnetinfo`). `TREX_MAC_LIST` and `TREX_IP_LIST` are the CR fields `trexMaclist` and `trexIplist`. For each local interface, in that same order, it writes a static nexthop and a host route for the TRex peer. The generated file is written to the `grout-cfg` volume and later mounted at `/etc/grout.init`.
- **`frr-init`** (`generate-frr-config`): Writes the FRR daemon list (`daemons`) and `frr.conf` into the `frr-cfg` volume. The `frr` container mounts those files at `/etc/frr/daemons` and `/etc/frr/frr.conf`.

### Application containers

- **`grout`**: Runs the Grout dataplane. It requests CPU (`cpu`), memory (`memory`), 1Gi hugepages (`hugepage_1gb_count`), and the network resources derived from `networks` or `resources`. It always runs privileged, because Grout itself writes per-interface sysctls under `/proc/sys` when it creates each control-plane TAP: `rp_filter=2` when `GROUT_OVERRIDE_RP_FILTER` is set, and `keep_addr_on_down=1` so IPv6 addresses survive an admin-down. The default container `/proc/sys` mount is read-only, so those writes fail with `Read-only file system` and kernel ping and BGP break. Making the image root writable does not unmask `/proc/sys`. Unmasking it with `procMount: Unmasked` requires `hostUsers: false`, and that user namespace cannot idmap the `/dev/net/tun` hostPath Grout needs for the TAPs. Privileged mode is what leaves `/proc/sys` writable. The `privileged` role variable does not apply to this container. It exposes port 8095 (HTTP probes) and port 9111 (Grout API), and mounts hugepages, the DPDK runtime directory, `/dev/net/tun`, and the generated `grout.init`. Custom environment variables from `environments` are injected here. The container publishes the API socket at `/run/grout/api.sock` on the shared `grout-run` volume. `GROUT_OVERRIDE_DEFAULT_ROUTE` and `GROUT_OVERRIDE_RP_FILTER` are set to `true` so kernel traffic uses the Grout VRF loopback and replies are not dropped by strict reverse-path filtering.
- **`frr`**: Runs FRR, including zebra with the Grout dataplane plugin. It requests CPU and memory, and mounts the config produced by `frr-init` plus the shared `grout-run` volume so it can reach the Grout socket. When `privileged` is `true`, this container runs privileged. Otherwise it adds `NET_ADMIN`, `AUDIT_WRITE`, `NET_RAW`, `NET_BIND_SERVICE`, and `SYS_ADMIN`, and uses the `spc_t` SELinux type.

When `run_deployment` is `1`, both application containers use a read-only root filesystem, startup, readiness, and liveness probes on port 8095, and `postStart` hooks. The Grout hook applies `grout.init` through `grcli`. The FRR hook waits until the Grout socket and the FRR daemons are ready.

### Other pod settings

- **Replica Count**: The number of pod replicas is controlled by the `size` variable.
- **Network Attachments**: Unless `skip_annot` is `true`, the pod annotation `k8s.v1.cni.cncf.io/networks` attaches the networks from the `networks` variable, including optional MAC addresses and IPs.
- **RuntimeClass**: If `runtime_class_name` is set, it is applied to the pod, and CRI-O IRQ and CPU load-balancing annotations are disabled.
- **PodDisruptionBudget**: A PodDisruptionBudget is also created to help maintain pod availability during node drains or upgrades.

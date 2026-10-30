
# TRexConfig Ansible Role

This Ansible role (`trexconfig`) is designed to deploy and manage the TRex traffic generator application in a Kubernetes/OpenShift environment. It automates the creation of necessary Kubernetes resources, parses network definitions, and configures the TRex deployment according to user-specified parameters.

## Default Variables

The following variables are defined in [`defaults/main.yml`](defaults/main.yml):

| Variable              | Default Value                                                                                                    | Description                                                                                                 |
|-----------------------|------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| `image_server`        | quay.io/rh-nfv-int/trex-container-server@sha256:190d69aef293d1719952969edcca8042d99e17b0d62d1a085cdd7b01cb5e1f1d | Container image for the TRex server.                                                                        |
| `size`                | 1                                                                                                                | Number of replicas for the TRex server deployment.                                                          |
| `skip_annot`          | false                                                                                                            | Whether to skip annotation steps.                                                                           |
| `networks`            | []                                                                                                               | List of network definitions to attach to the TRex server pod (SR-IOV/CNI).                                  |
| `image_pull_policy`   | IfNotPresent                                                                                                     | Image pull policy for the TRex server container (`Always`, `IfNotPresent`, or `Never`).                     |
| `privileged`          | false                                                                                                            | Whether to run the container in privileged mode.                                                            |
| `hugepage_1gb_count`  | 4Gi                                                                                                              | Amount of 1Gi hugepages to allocate.                                                                        |
| `memory`              | 1000Mi                                                                                                           | Memory request for the TRex server container.                                                               |
| `cpu`                 | 6                                                                                                                | CPU request for the TRex server container. Injected as `TREX_CPU`. `c` in the generated config is this value minus 2. |
| `network_resources`   | {}                                                                                                               | Internal variable for tracking network resource usage.                                                      |
| `environments`        | {}                                                                                                               | Extra environment variables. `trex_core_count` overrides `c` from the generated config.                     |
| `run_deployment`      | Not set (the image defaults to `1`)                                                                              | `1` starts TRex after writing the config. `0` writes the config and sleeps.                                |
| `deployment_type`     | Not set                                                                                                          | `multi-node` adds a pod anti-affinity so the server is not scheduled on the same node as the CNF app.       |
| `runtime_class_name`  | Not set                                                                                                          | Optional RuntimeClass. When set, CPU and IRQ load-balancing annotations are disabled.                       |
| `numa_aware_topology` | Not set                                                                                                          | Optional scheduler name for NUMA-aware placement.                                                           |


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

The `trexconfig` role automates the deployment and configuration of the TRex traffic generator by orchestrating a series of Ansible tasks. Here’s an overview of the main steps and logic:

1. **Initialization and Validation**
   - The role starts by initializing internal variables such as `network_resources` and `network_name_list`.
   - It checks that the `networks` variable is not empty, failing early if no network definitions are provided.

2. **Network Parsing**
   - For each network defined in the `networks` list, the role includes the `network-parse.yaml` task file.
   - This sub-task:
     - Extracts the network name and parses it to determine the correct resource.
     - Looks up the corresponding `NetworkAttachmentDefinition` in the target namespace.
     - Retrieves the resource name from the network definition’s annotations.
     - Updates the `network_resources` dictionary to track which resources are already in use.
     - Handles the number of ports, MAC addresses, and IP addresses as specified in the network definition.

3. **Debugging and State Reporting**
   - Throughout the process, the role uses debug tasks to print the current state of variables such as `networks`, `network_resources`, and `network_name_list`. This helps with troubleshooting and understanding how the input is being processed.

4. **Kubernetes Resource Creation**
   - The role creates the necessary Kubernetes resources for TRex operation:
     - **ServiceAccount**: Grants the TRex pod the required permissions.
     - **Role** and **RoleBinding**: Define and bind permissions for the ServiceAccount.
     - **Deployment**: Launches the TRex server pod(s) with the specified configuration, including network attachments, resource requests, and environment variables.
     - **PodDisruptionBudget**: Ensures high availability during node maintenance or upgrades.
     - **Service**: Exposes the TRex server for communication, defining the required ports.

5. **Template Rendering**
   - The deployment and other Kubernetes resources are rendered from Jinja2 templates, which dynamically incorporate variables such as `networks`, `size`, `image_server`, and more.
   - The network attachments are injected into the pod annotations, supporting multiple interfaces, MAC/IP assignment, and namespace scoping.

6. **Customization and Extensibility**
   - The role supports customization through variables (see the table above), allowing users to control aspects like image, resource requests, privileged mode, and environment variables.
   - Advanced users can extend or override the default behavior by providing their own values for these variables.

**Summary:**  
The `trexconfig` role provides a robust, automated way to deploy TRex in a Kubernetes/OpenShift environment, handling network attachment parsing, resource creation, and configuration in a repeatable and customizable manner.

## Deployment Details

The role creates one `Deployment`. The pod runs a single `trex-server` container from `image_server`, as uid 56560, with args `trex`. PID 1 is `catatonit`, which runs `/trex-wrapper`. See the server [README](../../../trex-container-app/server/README.md#what-is-it-executed).

The wrapper reads this container's CPU list and writes `/tmp/trex/trex_cfg.yaml` on the `trex-cfg` emptyDir. Hugepages are mounted at `/dev/hugepages` and the DPDK runtime directory at `/var/run/dpdk`. `NETWORK_NAME_LIST` is the SR-IOV resource names from `network_resources`, so `/trex-cfg-configure` can read the `PCIDEVICE_OPENSHIFT_IO_*` variables. `TREX_CPU` is `cpu`.

When `run_deployment` is `1`, the root filesystem is read-only and probes hit port 8096. The wrapper starts `_t-rex-64` with the generated file. `postStart` runs `/trex-wrapper poststart-trex` and waits until port 4500 accepts connections. When `run_deployment` is `0`, the config file is still written and the process sleeps, so TRex can be started by hand.

Other pod settings:

- **Replicas:** `size`.
- **Network attachments:** Unless `skip_annot` is true, `k8s.v1.cni.cncf.io/networks` is built from `networks`, including optional MAC addresses and IPs.
- **Affinity:** When `deployment_type` is `multi-node`, the pod is kept off nodes that already run a `cnf-app` pod.
- **RuntimeClass:** `runtime_class_name`, when set, is applied and CRI-O IRQ and CPU load-balancing annotations are disabled.
- **Scheduler:** `numa_aware_topology`, when set, is the pod scheduler name.
- **Privileged mode:** `privileged` selects a privileged container. Otherwise the container adds `IPC_LOCK`, `NET_ADMIN`, and `AUDIT_WRITE`.
- **Service:** A `trex-server` Service exposes TCP 4500 and 4501.
- **PodDisruptionBudget:** Created for the server pod.

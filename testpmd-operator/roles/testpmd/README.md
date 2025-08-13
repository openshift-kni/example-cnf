# TestPMD Ansible Role

This Ansible role (`testpmd`) is designed to deploy and manage the TestPMD application in a Kubernetes/OpenShift environment. It automates the creation of necessary Kubernetes resources, parses network definitions, and configures the TestPMD deployment according to user-specified parameters.

## Default Variables

The following variables are defined in [`defaults/main.yml`](defaults/main.yml):

| Variable              | Default Value                                                                                                    | Description                                                                                                 |
|-----------------------|------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| `image_testpmd`       | quay.io/rh-nfv-int/testpmd-container-app-cnfapp@sha256:c0cbe35d7e97034b5f2243d12e84408864cb90ce3c3953328e4295e9efe48eef | Container image for the TestPMD application.                                                                |
| `size`                | 1                                                                                                                | Number of replicas for the TestPMD deployment.                                                              |
| `skip_annot`          | false                                                                                                            | Whether to skip annotation steps.                                                                           |
| `networks`            | []                                                                                                               | List of network definitions (see below for structure).                                                      |
| `image_pull_policy`   | IfNotPresent                                                                                                     | Image pull policy for the TestPMD container (`Always`, `IfNotPresent`, or `Never`).                         |
| `privileged`          | false                                                                                                            | Whether to run the container in privileged mode.                                                            |
| `hugepage_1gb_count`  | 4Gi                                                                                                              | Amount of 1Gi hugepages to allocate.                                                                        |
| `memory`              | 1000Mi                                                                                                           | Memory request for the TestPMD container.                                                                   |
| `cpu`                 | 6                                                                                                                | CPU request for the TestPMD container.                                                                      |
| `network_resources`   | {}                                                                                                               | Internal variable for tracking network resource usage.                                                      |
| `resources`           | []                                                                                                               | List of additional resources to be used.                                                                    |
| `ethpeer_maclist`     | []                                                                                                               | List of MAC addresses for peer interfaces.                                                                  |
| `environments`        | {}                                                                                                               | Environment variables to set in the container.                                                              |
| `forwarding_cores`    | 2                                                                                                                | Number of cores dedicated to packet forwarding (must be less than total CPU count).                         |
| `memory_channels`     | 6                                                                                                                | Number of memory channels used by DPDK.                                                                     |
| `socket_memory`       | 1024                                                                                                             | Socket memory size in MB for DPDK.                                                                          |
| `rx_queues`           | 1                                                                                                                | Number of RX queues.                                                                                        |
| `rx_descriptors`      | 1024                                                                                                             | Number of RX descriptors per queue.                                                                         |
| `tx_queues`           | 1                                                                                                                | Number of TX queues.                                                                                        |
| `tx_descriptors`      | 1024                                                                                                             | Number of TX descriptors per queue.                                                                         |

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

The TestPMD role uses a series of Ansible tasks (see [`tasks/main.yml`](tasks/main.yml)) to automate the deployment and configuration of the TestPMD application. Here is an overview of the main steps:

1. **Initialization**:  
   The role initializes internal variables such as `network_resources` (to track network resource usage), `network_name_list` (to keep a list of network names), and `ethpeer_maclist` (to store MAC addresses for peer interfaces).

2. **Input Validation**:  
   The role checks that at least one of the `networks` or `resources` variables is provided. If both are empty, the playbook fails with an error.

3. **Network Parsing**:  
   If the `networks` variable is defined and not empty, the role loops through each network entry and includes the `network-parse.yaml` task file. This subtask:
   - Extracts the network name and details.
   - Looks up the corresponding `NetworkAttachmentDefinition` in the cluster.
   - Gathers resource names, counts, and updates the `network_resources` dictionary accordingly.
   - Handles duplicate resources by incrementing their counts.
   - Collects a list of all network names used.
   - Extracts and stores peer MAC addresses in `ethpeer_maclist` for use in the deployment.

4. **Resource Parsing**:  
   If `resources` are defined and `networks` is empty, the role populates `network_resources` directly from the `resources` list.

5. **Deployment Rendering**:  
   The role uses the collected variables and network/resource information to render the Kubernetes Deployment manifest from the Jinja2 template (`templates/deployment.yml`), which is then applied to the cluster. The `ethpeer_maclist` is also passed as an environment variable to the container for use by the TestPMD application.

## Deployment Details

The TestPMD role creates a Kubernetes `Deployment` resource to manage the TestPMD application pods. The deployment is rendered from a Jinja2 template and includes the following main components:

- **Replicas**: The number of pod replicas is controlled by the `size` variable.
- **Pod Labels and Affinity**: Pods are labeled for identification and may use anti-affinity rules to avoid scheduling on the same node as other specific workloads.
- **Security Context**: The container runs as a non-root user by default, with the option to enable privileged mode via the `privileged` variable.
- **Service Account and Runtime Class**: The deployment uses a dedicated service account (`testpmd-account`). Optionally, a custom runtime class and scheduler can be specified.
- **Resource Requests and Limits**: CPU, memory, and hugepage resources are set according to the role variables. Additional network resources are included as needed from `network_resources`.
- **Network Attachments**: The deployment attaches to the specified networks using Multus, based on the `networks` variable.
- **Environment Variables**: Various environment variables are injected into the container to configure TestPMD runtime parameters, such as CPU count, memory channels, socket memory, RX/TX queues and descriptors, and any custom environment variables defined in `environments`. The `ethpeer_maclist` is also provided to the container to facilitate peer interface configuration.
- **Volume Mounts**: The container mounts several directories for hugepages, logs, DPDK runtime, and temporary files.
- **Lifecycle Hooks and Probes**: If enabled, the deployment includes lifecycle hooks (`postStart`, `preStop`) and health/readiness/startup probes for monitoring the application.
- **Termination Policy**: The deployment uses `FallbackToLogsOnError` for the termination message policy to aid in troubleshooting.

This approach ensures that the TestPMD application is deployed in a flexible, configurable, and production-ready manner, suitable for CNF (Cloud-Native Network Function) validation and testing scenarios.

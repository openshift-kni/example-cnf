# Grout Ansible Role

This Ansible role (`grout`) is designed to deploy and manage the Grout application in a Kubernetes/OpenShift environment. It automates the creation of necessary Kubernetes resources, parses network definitions, and configures the Grout deployment according to user-specified parameters.

## Default Variables

The following variables are defined in [`defaults/main.yml`](defaults/main.yml):

| Variable              | Default Value                                                                                                    | Description                                                                                                 |
|-----------------------|------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| `image_grout`         | quay.io/rh-nfv-int/grout-container-app-cnfapp@sha256:112bed772707280de16a64eb4fb3c3c0ec027fa030372dff05927d105bc822fd | Container image for the Grout application.                                                                  |
| `size`                | 1                                                                                                                | Number of replicas for the Grout deployment.                                                                |
| `skip_annot`          | false                                                                                                            | Whether to skip annotation steps.                                                                           |
| `networks`            | []                                                                                                               | List of network definitions (see below for structure).                                                      |
| `image_pull_policy`   | IfNotPresent                                                                                                     | Image pull policy for the Grout container (`Always`, `IfNotPresent`, or `Never`).                           |
| `privileged`          | false                                                                                                            | Whether to run the container in privileged mode.                                                            |
| `hugepage_1gb_count`  | 4Gi                                                                                                              | Amount of 1Gi hugepages to allocate.                                                                        |
| `memory`              | 1000Mi                                                                                                           | Memory request for the Grout container.                                                                     |
| `cpu`                 | 4                                                                                                                | CPU request for the Grout container.                                                                        |
| `network_resources`   | {}                                                                                                               | Internal variable for tracking network resource usage.                                                      |
| `resources`           | []                                                                                                               | List of additional resources to be used.                                                                    |
| `environments`        | {}                                                                                                               | Environment variables to set in the container.                                                              |
| `rx_queues`           | 2                                                                                                                | Number of RX queues.                                                                                        |

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

The Grout role creates a Kubernetes `Deployment` resource to manage the lifecycle of the Grout application pods. This deployment is defined using a Jinja2 template (`deployment.yml`) and is rendered with the variables you provide to the role. The deployment includes the following key features:

- **Replica Count**: The number of pod replicas is controlled by the `size` variable.
- **Container Image**: The Grout container image is specified by the `image_grout` variable, with the pull policy set by `image_pull_policy`.
- **Network Attachments**: The deployment attaches the specified networks to the pods using the `networks` variable, enabling SR-IOV or other CNI-based networking as required.
- **Resource Requests and Limits**: CPU, memory, and hugepage resources are set according to the role defaults or your overrides.
- **Security Context**: The pod can be run in privileged mode if `privileged` is set to `true`.
- **RuntimeClass**: If a high-performance runtime is specified (via `runtime_class_name`), it is set on the pod for advanced scheduling or isolation.
- **Environment Variables**: Any custom environment variables can be injected using the `environments` variable.
- **Service Account**: The deployment uses a dedicated ServiceAccount created by the role to ensure proper permissions.
- **PodDisruptionBudget**: A PodDisruptionBudget is also created to help maintain pod availability during node drains or upgrades.

This deployment ensures that the Grout application is robustly managed by Kubernetes, with flexible configuration for networking, resources, and security to suit a variety of CNF (Cloud-Native Network Function) scenarios.

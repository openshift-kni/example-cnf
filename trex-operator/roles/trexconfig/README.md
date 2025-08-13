
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
| `cpu`                 | 6                                                                                                                | CPU request for the TRex server container.                                                                  |
| `network_resources`   | {}                                                                                                               | Internal variable for tracking network resource usage.                                                      |
| `environments`        | {}                                                                                                               | Environment variables to set in the container (e.g., trexCoreCount).                                        |


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

The TRex deployment is defined using a Jinja2-based Kubernetes Deployment template (`templates/deployment.yml`). This template is rendered dynamically by Ansible, incorporating the variables and network definitions provided by the user. Below are the key aspects of the deployment:

- **Replicas:** The number of TRex server pods is controlled by the `size` variable.
- **Metadata:** The deployment and pod metadata include labels and annotations. Notably, the pod annotations are used to attach multiple networks using the `k8s.v1.cni.cncf.io/networks` key, which is constructed from the `networks` variable. If `runtime_class_name` is set, additional annotations are added to disable CPU and IRQ load balancing.
- **Pod Specification:**  
  - **Affinity:** Pod anti-affinity rules ensure that TRex pods are not scheduled on the same node as CNF application pods, improving resource isolation.
  - **Security Context:** The pod runs as a non-root user by default, with the option to enable privileged mode via the `privileged` variable.
  - **Service Account:** The pod uses a dedicated ServiceAccount for permissions.
  - **Resource Requests:** CPU, memory, and hugepage allocations are set according to the variables `cpu`, `memory`, and `hugepage_1gb_count`.
  - **Environment Variables:** Any custom environment variables can be injected via the `environments` variable.
- **Network Attachments:** The template supports attaching multiple SR-IOV or CNI networks to the pod. Each network can specify the number of interfaces, MAC addresses, and (optionally) static IP addresses. The template logic ensures that the correct number of interfaces and their properties are rendered in the pod annotations.
- **Image and Pull Policy:** The TRex container image and pull policy are configurable via `image_server` and `image_pull_policy`.
- **Extensibility:** The deployment template is designed to be flexible, allowing users to override or extend its behavior by adjusting the variables in their playbook or inventory.

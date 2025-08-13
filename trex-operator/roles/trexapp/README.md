# TRexApp Ansible Role

The `trexapp` Ansible role is designed to automate the deployment and execution of TRex traffic generator jobs as Kubernetes Jobs in an OpenShift or Kubernetes environment. It provides a flexible and customizable way to run TRex workloads, supporting custom profiles, environment variables, and integration with CNF applications.

Key features:

- Deploys TRex as a Kubernetes Job.
- Supports custom TRex profiles via ConfigMap.
- Allows injection of environment variables and runtime parameters.
- Configurable resource requests and limits.
- Optional health probes and lifecycle hooks.
- Integrates with CNF application IPs and ARP resolution.

## Default Variables

The following variables are defined in [`defaults/main.yml`](defaults/main.yml):

| Variable                  | Default Value                                                                 | Description                                                                                   |
|---------------------------|-------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `image_app`               | quay.io/rh-nfv-int/trex-container-app@sha256:...                             | TRex application container image.                                                             |
| `image_pull_policy`       | IfNotPresent                                                                  | Image pull policy (`Always`, `IfNotPresent`, `Never`).                                        |
| `memory`                  | `1024Mi`                                                                       | Amount of memory to request/limit for the job container.                                      |
| `cpu`                     | `4`                                                                            | Number of CPUs to request/limit for the job container.                                        |
| `environments`            | `{}`                                                                          | Extra environment variables to inject into the job container.                                  |
| `trex_profile_config_map` | `''`                                                                          | Name of the ConfigMap with TRex profiles to mount.                                            |
| `trex_profile_name`       | `''`                                                                          | Name of the TRex profile to run from the mounted ConfigMap.                                   |
| `duration`                | `None`                                                                        | Duration in seconds for the job; use `-1` for continuous mode.                                |
| `packet_size`             | `''`                                                                          | Packet size in bytes.                                                                         |
| `packet_rate`             | `''`                                                                          | Packet rate (e.g., `10kpps`).                                                                 |
| `run_deployment`          | Not set                                                                       | Whether to enable deployment automation (0 to disable, 1 to enable).                          |
| `trex_ip_list`            | Not set                                                                       | List of TRex server IPs by interface (comma-separated string).                                |
| `cnfapp_ip_list`          | Not set                                                                       | List of CNF app IPs by interface (comma-separated string).                                    |
| `arp_resolution`          | Not set                                                                       | Whether to resolve ARP (1 to enable, 0 to disable).                                           |
| `resources`               | `{cpu: 4, memory: 1024Mi}`                                                    | Resource requests and limits for the job container.                                           |

## How the Ansible Tasks Work

1. **Job Template Rendering**
   - The role uses a Jinja2-based Kubernetes Job template (`templates/job.yml`).
   - Variables are injected to customize the job's command, environment, resources, and mounted volumes.

2. **Profile and Environment Injection**
   - If `trex_profile_config_map` is set, the specified ConfigMap is mounted and the selected profile is used.
   - Any key-value pairs in `environments` are added as environment variables in the container.

3. **Runtime Parameters**
   - Parameters such as `duration`, `packet_size`, `packet_rate`, and others are passed as environment variables to the TRex container.
   - Lists like `trex_ip_list` and `cnfapp_ip_list` are passed as comma-separated strings.

4. **Lifecycle and Probes**
   - If `run_deployment` is set to `1`, lifecycle hooks (`postStart`, `preStop`) and health probes (`livenessProbe`, `readinessProbe`, `startupProbe`) are enabled for the job pod.

5. **Resource Management**
   - CPU and memory requests/limits are set according to the `resources` variable.

## Deployment Details

- **Job Specification:** The role creates a Kubernetes Job with a single pod running the TRex application. The pod mounts necessary volumes, sets environment variables, and can optionally mount a ConfigMap with TRex profiles.
- **Volumes:**  
  - `/var/log/trex`, `/tmp`, `/var/run/dpdk` are mounted as emptyDirs.
  - If a profile ConfigMap is specified, it is mounted at `/opt/trexprofile`.
- **Environment Variables:**  
  - Standard variables such as `MODE`, `CR_NAME`, `NODE_NAME`, and `TREX_SERVER_URL` are set.
  - User-specified variables from `environments` and runtime parameters are injected.
- **Lifecycle and Probes:**  
  - Optional lifecycle hooks and health probes are included if `run_deployment` is enabled.
- **Resource Requests:**  
  - Default CPU and memory requests/limits are set to 4 CPUs and 1024Mi memory, but can be customized.

### Customization and Extensibility

- **Custom Profiles:** Mount your own TRex profile ConfigMap and specify the profile name to use.
- **Environment Variables:** Use the `environments` variable to inject any additional environment variables required by your workload.
- **Runtime Parameters:** Set `duration`, `packet_size`, `packet_rate`, and other parameters to control the TRex job's behavior.
- **Resource Tuning:** Adjust CPU and memory requests/limits as needed for your environment.
- **Health Probes and Lifecycle:** Enable or disable lifecycle hooks and health probes via the `run_deployment` variable.

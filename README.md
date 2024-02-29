Example CNF
==============

[![PR Validation](https://github.com/openshift-kni/example-cnf/actions/workflows/push.yaml/badge.svg)](https://github.com/openshift-kni/example-cnf/actions/workflows/push.yaml)

Example CNF is an OpenShift workload to exercice an SRIOV setup, such as the following:

![Schema](documentation/schema.png)

It is providing the following operators:

* trex-operator
    * It provides TRex Traffic Generator, decomposed in two components: a TRex server, deployed as `trexconfig-<x>` pod, which takes care of deploying and configuring a TRex server instance, and a TRex application, deplayed as `trex-app` job, that starts TRex server, generating traffic towards the system under test.
    * In `trexconfig-<x>` logs, you can see the trex statistics printed periodically. The summary of the test execution can be seen at the end of the `trex-app` job logs.
    * In our case, as we will see later on, the `trexconfig-<x>` pod has two interfaces connected to the same SRIOV network.
* testpmd-lb-operator
    * Its main component is a modified TestPMD instance, implementing a custom load balancing forwarding module, which is eventually used to perform load balancing between the ports of the deployed pod, called `loadbalancer-<x>`.
    * This pod is composed by two containers: `loadbalancer`, which performs the load balancing forwarding, and `listener`, an auxiliary module that is listening to the CNFAppMac component created by the cnf-app-mac-operator to retrieve the MAC addresses of the TestPMD instances launched by the testpmd-operator (i.e. the CNF Applications), then serving this information to the `loadbalancer` container.
    * To see the TestPMD statistics printed periodically for this module, you can rely on `loadbalancer` container logs.
    * The `loadbalancer-<x>` pod has four network interfaces; in our case, two of them connected to the same SRIOV network than TRex, and the other two connected to the same SRIOV network than the CNF Application.
    * The `loadbalancer-<x>` pod is not currently replicated; only one instance is deployed. It's supposed that, up to now, it's not belonging to any update-upgrade process of the example-cnf, so that it has to be deployed in an isolated worker node, whereas the other components of this CNF (TRex and CNF Application) have to be deployed in a different worker node.
* testpmd-operator
    * Final application, also known as CNF Application, which is a standard TestPMD instance using the default MAC forwarding module. Two replica pods are deployed, called `testpmd-app-<x>`, having each of them, in our case, two ports connected to the same SRIOV network, but different than the SRIOV network used by TRex.
    * To see the TestPMD statistics printed periodically for this module, you can rely on `testpmd-app-<x>` container logs. Each log will offer you the statistics of each replica pod.
* cnf-app-mac-operator
    * Auxiliary operator used to deploy a resource called CNFAppMac, which is a wrapper created for each `testpmd-app-<x>` and linked to them, and that are used to extract the network information of these pods (MAC and PCI addresses), to be offered to other components of the solution, such as the TestPMD Load Balancer.

You can use them from the [Example CNF Catalog](https://quay.io/repository/rh-nfv-int/nfv-example-cnf-catalog?tab=tags).

How operators are created
------------------------

The four operators defined in this repository are built with [Operator SDK tool](https://sdk.operatorframework.io/docs/building-operators/).

We can differentiate between these two cases:

**Ansible-based operators:**

This is the case of testpmd-operator, trex-operator and testpmd-lb-operator.

Base structure for each case is achieved with the following commands, then it's just a matter of accommodating the required code for each operator in the corresponding files and folders:

- testpmd-operator

```
$ mkdir testpmd-operator; cd testpmd-operator
$ operator-sdk init --domain openshift.io --plugins ansible
$ operator-sdk create api --version v1 --generate-role --group examplecnf --kind TestPMD
```

- trex-operator

TBD

- testpmd-lb-operator

```
$ mkdir testpmd-lb-operator; cd testpmd-lb-operator
$ operator-sdk init --domain openshift.io --plugins ansible
$ operator-sdk create api --version v1 --generate-role --group examplecnf --kind LoadBalancer
```

**Go-based operators:**

This is the case of cnf-app-mac-operator.

Base structure for this case is achieved with the following commands, then it's just a matter of accommodating the required code for the operator in the corresponding files and folders:

- cnf-app-mac-operator

For operator-sdk v1.33.0, you need to have installed the same Go version used in operator-sdk, which is go 1.22.5.

```
$ operator-sdk version
operator-sdk version: "v1.33.0", commit: "542966812906456a8d67cf7284fc6410b104e118", kubernetes version: "1.27.0", go version: "go1.21.5", GOOS: "linux", GOARCH: "amd64"
```

Create the project structure and the CNFAppMac API:

```
$ mkdir cnf-app-mac-operator; cd cnf-app-mac-operator
$ operator-sdk init --domain openshift.io --repo github.com/openshift-kni/example-cnf/tree/main/cnf-app-mac-operator
$ operator-sdk create api --version v1 --group examplecnf --kind CNFAppMac --controller --resource
```

At this point, remove RBAC resource creation in Makefile > manifests task. Then, review cmd/main.go and api/v1/cnfappmac_types.go, then run:

```
$ make generate
$ make manifests 
```

Create webhook and certmanager:

```
$ operator-sdk create webhook --version v1 --group examplecnf --kind CNFAppMac --defaulting --programmatic-validation
```

Review the generated files properly, then:

```
$ make manifests
```

Comment webhook references in PROJECT and cmd/main.go files (older versions were not using this), review internal/controller/cnfappmac_controller.go and review the rest of files.

To conclude, build the main.go file to check it's working fine:

```
$ go build cmd/main.go
```

Ansible based automation
------------------------

You can use the Ansible playbooks and roles at <https://github.com/rh-nfv-int/nfv-example-cnf-deploy> to automate the use of the Example CNF.

Load balancer mode vs. direct mode
------------------------

There are two different ways of deploying example-cnf, depending on the `enable_lb` flag (default to `true`):

- Load balancer mode (`enable_lb: true`):
    - Represents the behavior described above, with a TestPMD instance acting as load balancer between TRex and the CNF Applications.
- Direct mode (`enable_lb: false`):
    - The TestPMD instance is not used, then testpmd-lb-operator is not deployed.
    - In this case, there's a direct connection between TRex and CNF Application.
    - The CNF Application only uses one replica pod, instead of two.

Pod affinity rules
------------------------

There are different, possible affinity rules for the deployed pods, depending whether testpmd-lb-operator is deployed (load balancer mode) or not (direct mode):

- Load balancer mode:
    - The `loadbalancer-<x>` pod is deployed in a different worker than `trexconfig-<x>` and `testpmd-app-<x>`.
    - There are no constraints for the location of `trexconfig-<x>` and `testpmd-app-<x>` pods, so they may live in the same worker.
- Direct mode:
    - Since load balancer is not used, in this scenario, `trexconfig-<x>` and `testpmd-app-<x>` pods are placed in different worker nodes.

SRIOV networks
------------------------

There are two SRIOV networks created for this CNF, and they are called `intel-numa0-net1` and `intel-numa0-net2`.

We will see that, in fact, it is followed a different setup than the one presented in the first, simplified diagram showed at the beginning of this README file, where we have two SRIOV Networks (1 and 2), but both used in the communication between TRex and TestPMD Load Balancer, and between TestPMD Load Balancer and CNF Applications.

However, here, according to [these two variables](https://github.com/dci-labs/example-cnf-config/blob/master/testpmd/hooks/pre-run.yml#L3-L11), we will see the first SRIOV network is used for the CNF Application network, and the second one is used for TRex network (in both cases, as long as the TestPMD load balancer is deployed):

```
    cnf_app_networks:
      - name: intel-numa0-net1
        count: 2
    packet_generator_networks:
      - name: intel-numa0-net2
        count: 2
```

According to the configuration applied in example-cnf hooks, and also depending on the mode in which example-cnf is launched, the distribution of these two SRIOV networks may be different:

**Load balancer mode:**

According to [this code](https://github.com/rh-nfv-int/nfv-example-cnf-deploy/blob/master/roles/example-cnf-app/tasks/app.yaml#L64-L76):

```
- name: create packet gen network list for lb with hardcoded macs
  set_fact:
    pack_nw: "{{ pack_nw + [ item | combine({ 'mac': lb_gen_port_mac_list[idx:idx+item.count] }) ] }}"
  loop: "{{ packet_generator_networks }}"
  loop_control:
    index_var: idx

- name: create cnf app network list for lb with hardcoded macs
  set_fact:
    cnf_nw: "{{ cnf_nw + [ item | combine({ 'mac': lb_cnf_port_mac_list[idx:idx+item.count] }) ] }}"
  loop: "{{ cnf_app_networks }}"
  loop_control:
    index_var: idx
```

- `pack_nw` corresponds to `packet_generator_networks` and uses `lb_gen_port_mac_list`, having two MAC addresses starting with `40:...`, and correspond to the interfaces that connect the TestPMD Load Balancer with TRex. It uses `intel-numa0-net2`.
- `cnf_nw` corresponds to `cnf_app_networks` and uses `lb_cnf_port_mac_list`, having two MAC addresses starting with `60:...`, and correspond to the interfaces that connect the TestPMD Load Balancer with the CNF Applications. It uses `intel-numa0-net1`.

So, network schema is as follows (which was already depicted in the flow diagram):

```
trex -- (intel-numa0-net2) -- lb -- (intel-numa0-net1) -- cnfapp
```

Here's an example of network interfaces created for each component of the scenario, to confirm that this is what is really happening:

- TRex: it has two interfaces connected to `intel-numa0-net2`

```
$ oc describe pod trexconfig-6b747d779-ld7fw | less
                    },{
                        "name": "example-cnf/intel-numa0-net2",
                        "interface": "net1",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:0a.2"
                            }
                        }
                    },{
                        "name": "example-cnf/intel-numa0-net2",
                        "interface": "net2",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:0a.7"
                            }
                        }
                    }]
```

- TestPMD Load Balancer has four interfaces, two connected to `intel-numa0-net1`, and other two connected to `intel-numa0-net2`:

```
$ oc describe pods loadbalancer-5c47c445f7-vf6b9 | less
                    },{
                        "name": "example-cnf/intel-numa0-net2",
                        "interface": "net1",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:0a.0"
                            }
                        }
                    },{
                        "name": "example-cnf/intel-numa0-net2",
                        "interface": "net2",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:0b.2"
                            }
                        }
                    },{
                        "name": "example-cnf/intel-numa0-net1",
                        "interface": "net3",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:03.5"
                            }
                        }
                    },{
                        "name": "example-cnf/intel-numa0-net1",
                        "interface": "net4",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:03.0"
                            }
                        }
                    }]
```

And finally, each of CNF Application pods have two interfaces, both connected to `intel-numa0-net1`:

```
$ oc describe pod testpmd-app-646d7bb697-6f7m5 | less
                    },{
                        "name": "example-cnf/intel-numa0-net1",
                        "interface": "net1",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:03.4"
                            }
                        }
                    },{
                        "name": "example-cnf/intel-numa0-net1",
                        "interface": "net2",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:03.2"
                            }
                        }
                    }]

$ oc describe pod testpmd-app-646d7bb697-zgsdb | less 
                    },{
                        "name": "example-cnf/intel-numa0-net1",
                        "interface": "net1",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:03.7"
                            }
                        }
                    },{
                        "name": "example-cnf/intel-numa0-net1",
                        "interface": "net2",
                        "dns": {},
                        "device-info": {
                            "type": "pci",
                            "version": "1.0.0",
                            "pci": {
                                "pci-address": "0000:37:02.4"
                            }
                        }
                    }]
```

**Direct mode:**

In this case, the network used by TRex varies, according to [this code](https://github.com/rh-nfv-int/nfv-example-cnf-deploy/blob/master/roles/example-cnf-app/tasks/trex/app.yaml#L5): `packet_gen_net: "{{ packet_generator_networks if enable_lb|bool else cnf_app_networks }}"`

This says that, if load balancer is not enabled, then TRex is connected to the `cnf_app_networks`, which is, in fact, `intel-numa0-net1`, so it doesn't use `intel-numa0-net2` in this case.

The network schema would be as follows:

```
trex -- (intel-numa0-net1) -- cnfapp
```

Traffic Flow
------------------------

Here, we will depict the traffic flow for the case of the load balancer mode (since the direct mode is quite simple), including the SRIOV setup already described above.

![Flow](documentation/trex_flow_4_ports_bi_directional.png)

Traffic Flow (just considering one CNF Application as target, but the same flow applies to all CNF Applications deployed in the scenario):

- TRex (Traffic Generator) generates and sends traffic from Port 0 to TestPMD.

- TestPMD (Packet Manipulation Daemon), configured as a load balancer, receives incoming traffic on Ports 0 and 1.

- TestPMD load balances the incoming traffic between its Ports 2 and 3.

- TestPMD forwards the load-balanced traffic to the CNF Application.

- The CNF Application receives incoming traffic from TestPMD on one of its ports.

- The CNF Application processes the received traffic and passes it back to TRex for evaluation, using the TestPMD MAC forwarding mode.

- TRex receives the processed traffic on Port 1.

- TRex calculates statistics by comparing the incoming traffic on Port 1 (processed traffic) with the outgoing traffic on Port 0 (original traffic sent by TRex) and vice versa.

This configuration simulates a traffic flow from TRex to TestPMD, then to the CNF Application, and finally back to TRex for evaluation. TestPMD serves as a load balancer to distribute traffic between its ports, and the CNF Application processes and loops back the traffic to TRex for analysis using the TestPMD MAC forwarding mode. TestPMD LB ensures zero traffic loss throughout the rolling update process.

Utils
------------------------

Under [utils](utils) folder, you can find some utilities included in example-cnf to extend the functionalities offered by the tool.

- [webserver.go](utils/webserver.go): a Golang-based webserver to implement liveness, readiness and startup probes in the container images offered in [testpmd-container-app](testpmd-container-app) and [trex-container-app](trex-container-app) folders. The Makefiles offered in these directories take care of copying the webserver code from the utils directory to each image's directory.

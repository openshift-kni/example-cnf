# Example CNF

[![PR Validation](https://github.com/openshift-kni/example-cnf/actions/workflows/push.yaml/badge.svg)](https://github.com/openshift-kni/example-cnf/actions/workflows/push.yaml)

Example CNF is an OpenShift workload to exercice an SRIOV setup, based on [TestPMD](https://doc.dpdk.org/guides/testpmd_app_ug/intro.html) for traffic forwarding and [TRex](https://trex-tgn.cisco.com/) for traffic generation, such as the following:

![Flow](documentation/network_setup.png)

It is providing the following operators:

* trex-operator
    * It provides TRex Traffic Generator, decomposed in three components:
        * TRexConfig CR, pinning the config of the TRex server instance. Related pod is `trexconfig-<x>` pod.
        * TRexApp CR, setting up the job that launches TRex execution to generate traffic towards the system under test. Related pod is `trex-app` pod.
        * TRex Operator, ensuring CR reconciliation via controller-manager pod. Related pod is `trex-operator-controller-manager-<x>` pod.
    * Following information can be extracted from pod logs:
        * In `trexconfig-<x>` pod logs, you can see the trex statistics printed periodically.
        * The summary of the test execution can be seen at the end of the `trex-app` job logs.
        * In `trex-operator-controller-manager-<x>` pod, you can see the execution of the Ansible playbooks that ensures the reconciliation loop of the operator.

![Operator behavior](documentation/trex-operator.png)

* testpmd-operator
    * Final application, also known as CNF Application, which is a standard TestPMD instance using the default MAC forwarding module. It uses two components:
        * TestPMD CR, which creates a pod to implement the MAC forwarding module as final application. Related pod is `testpmd-app-<x>` pod (only one replica is used).
        * TestPMD Operator, ensuring CR reconciliation via controller-manager pod. Related pod is `testpmd-operator-controller-manager-<x>` pod.
    * Following information can be extracted from pod logs:
        * To see the TestPMD statistics printed periodically for this module, you can rely on `testpmd-app-<x>` pod logs.
        * In `testpmd-operator-controller-manager-<x>` pod, you can see the execution of the Ansible playbooks that ensures the reconciliation loop of the operator.

![Operator behavior](documentation/testpmd-operator.png)

* cnf-app-mac-operator
    * Auxiliary operator just composed by one component, which is CNFAppMac Operator, a Golang-based operator in charge of ensuring reconciliation for CNFAppMac CR, which is a wrapper created for the `testpmd-app-<x>` pod and linked to it, and that is used to extract the network information of the pods (network, MAC and PCI addresses), to be offered to other components of the solution.

![Operator behavior](documentation/cnf-app-mac-operator.png)

You can use them from the [Example CNF Catalog](https://quay.io/repository/rh-nfv-int/nfv-example-cnf-catalog?tab=tags). Image generation is automated with [Github workflows](.github/workflows) in this repo.

## Pre-requirements

To run Example CNF, you need to fulfil the following infrastructure-related pre-requirements:

- OpenShift cluster with +3 worker nodes.
- SR-IOV network operator.
- SriovNetworkNodePolicy and SriovNetwork CRDs.
- Proper configuration in network devices to match the SR-IOV resources definition.
- Performance Profile (Hugepages, CPU Isolation, etc.)

## How operators are created

The three operators defined in this repository are built with [Operator SDK tool](https://sdk.operatorframework.io/docs/building-operators/). [Here](https://youtu.be/imF9VGJ1Dd4) you can see how CRD-to-pod conversion works for this kind of operators.

We can differentiate between these two cases:

### Ansible-based operators

This is the case of testpmd-operator and trex-operator.

Base structure for each case is achieved with the following commands, then it's just a matter of accommodating the required code for each operator in the corresponding files and folders:

- testpmd-operator

```
$ mkdir testpmd-operator; cd testpmd-operator
$ operator-sdk init --domain openshift.io --plugins ansible
$ operator-sdk create api --version v1 --generate-role --group examplecnf --kind TestPMD
```

- trex-operator

```
$ mkdir trex-operator; cd trex-operator
$ operator-sdk init --domain openshift.io --plugins ansible
$ operator-sdk create api --version v1 --generate-role --group examplecnf --kind TRexApp
$ operator-sdk create api --version v1 --generate-role --group examplecnf --kind TRexConfig
```

### Go-based operators

This is the case of cnf-app-mac-operator.

Base structure for this case is achieved with the following commands, then it's just a matter of accommodating the required code for the operator in the corresponding files and folders:

- cnf-app-mac-operator

For operator-sdk v1.38.0, you need to have installed the same Go version used in operator-sdk, which is at least Go 1.22.5+.

```
$ operator-sdk version
operator-sdk version: "v1.38.0", commit: "0735b20c84e5c33cda4ed87daa3c21dcdc01bb79", kubernetes version: "1.30.0", go version: "go1.22.5", GOOS: "linux", GOARCH: "amd64"
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

## Pod affinity rules

There are some affinity rules for the deployed pods. In particular, `trexconfig-<x>` and `testpmd-app-<x>` pods are placed in different worker nodes.

## SRIOV networks

SRIOV networks are required for the setup. In our case, we are using a different SRIOV network per connection, using a different VLAN for each network.

In our [example-cnf-config automation](https://github.com/dci-labs/example-cnf-config/tree/master), in the [pre-run stage](https://github.com/dci-labs/example-cnf-config/blob/master/testpmd/hooks/pre-run.yml), we are setting the following networks:

```
    ecd_sriov_networks:
      - name: example-cnf-net1
        count: 1
      - name: example-cnf-net2
        count: 1
```

The `ecd_sriov_networks` represents the connection between TRex and CNF Application. There are two links per connection, each link using a different SRIOV network.

TRex uses static MAC addresses starting with `20:...`, and the CNF Application uses static MAC addresses starting with `80:...`, and the addresses, together with the PCI addresses, are eventually gathered by the CNFAppMac CR.

The network schema would be as follows:

```
TRex -- (example-cnf-net1|2) -- CNF Application
```

## Traffic Flow

Traffic flow is the following:

- TRex (Traffic Generator) generates and sends traffic from Port 0 to the CNF Application.

- The CNF Application receives incoming traffic from TRex on one of its ports.

- The CNF Application processes the received traffic and passes it back to TRex for evaluation, using the TestPMD MAC forwarding mode.

- TRex receives the processed traffic on Port 1.

- TRex calculates statistics by comparing the incoming traffic on Port 1 (processed traffic) with the outgoing traffic on Port 0 (original traffic sent by TRex) and vice versa.

## Testing

Please refer to [the testing docs](documentation/testing.md) to check how to test Example CNF using [Distributed-CI (DCI)](https://docs.distributed-ci.io/).

## Network troubleshooting

Apart from the logs offered by the resources deployed by Example CNF, the `ip` command can also offer some useful network information regarding the statistics of the network interfaces used in the tests.

For example, by accessing to the worker node where the resources are deployed, and checking the interface where the VFs are created, you can see information like this:

```
$ ip -s -d link show dev ens2f0
6: ens2f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 3c:fd:fe:bb:1e:10 brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 68 maxmtu 9702 addrgenmode none numtxqueues 80 numrxqueues 80 gso_max_size 65536 gso_max_segs 65535 tso_max_size 65536 tso_max_segs 65535 gro_max_size 65536 portid 3cfdfebb1e10 parentbus pci parentdev 0000:37:00.0
    RX:  bytes packets errors dropped  missed   mcast
        670348    9563      0       0       0    3372
    TX:  bytes packets errors dropped carrier collsns
        225778    1382      0       0       0       0
    vf 0     link/ether 92:be:3c:24:4a:7d brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 1     link/ether be:c8:8b:88:a2:15 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        505712     6392       0    6392        0
    TX: bytes  packets   dropped
             0        0        0
    vf 2     link/ether 7a:e8:f7:1d:5c:cc brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 3     link/ether 5e:c2:8b:ef:87:a4 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        346464     4374       0    4374        0
    TX: bytes  packets   dropped
             0        0        0
    vf 4     link/ether 9a:40:99:d1:cd:32 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        408944     5177       0    5177        0
    TX: bytes  packets   dropped
             0        0        0
    vf 5     link/ether da:a7:e7:e6:b8:79 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 6     link/ether 2a:1e:c7:55:18:60 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 7     link/ether 86:79:8c:3f:b2:5b brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 8     link/ether ce:7c:63:c0:fc:c4 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 9     link/ether ea:b3:47:1c:e4:d9 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        505968     6396       0    6396        0
    TX: bytes  packets   dropped
             0        0        0
    vf 10     link/ether 66:6e:b8:01:df:4d brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 11     link/ether b2:ed:fb:92:67:1d brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 12     link/ether 96:37:81:12:30:83 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 13     link/ether 02:1d:21:a3:81:e4 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        346336     4372       0    4372        0
    TX: bytes  packets   dropped
             0        0        0
    vf 14     link/ether c2:76:dd:b0:03:60 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        519160     6565       0    6565        0
    TX: bytes  packets   dropped
             0        0        0
    vf 15     link/ether 3a:24:a8:4a:9b:75 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off
    RX: bytes  packets  mcast   bcast   dropped
        430208     5435       0    5435        0
    TX: bytes  packets   dropped
             0        0        0
    altname enp55s0f0
```

## Utils

Under [utils](utils) folder, you can find some utilities included in Example CNF to extend the functionalities offered by the tool.

- [webserver.go](utils/webserver.go): a Golang-based webserver to implement liveness, readiness and startup probes in the container images offered in [testpmd-container-app](testpmd-container-app) and [trex-container-app](trex-container-app) folders. The Makefiles offered in these directories take care of copying the webserver code from the utils directory to each image's directory.
- [required-annotations.yaml](utils/required-annotations.yaml): annotations to be appended to the CSVs to pass Preflight's RequiredAnnotations tests. They are appended automatically thanks to the Makefile tasks from each operator.
- [support-images](support_images): projects where you can find the Dockerfile required to build some of the images used as build images by the Example CNF images. These images can be found on quay.io/rh-nfv-int and they are publicly available, you only need credentials to access quay.io. The images can be built with the following commands (you need to run it in a RHEL host with a valid RHEL subscription to be able to download the packages installed in the images, and you need a valid quay.io credentials to push it to quay.io):

```
# build images
$ cd utils/support-images
$ podman build dpdk-23.11 -f dpdk-23.11/Dockerfile -t "quay.io/rh-nfv-int/dpdk-23.11:v0.0.1"
$ podman build ubi8-base-testpmd -f ubi8-base-testpmd/Dockerfile -t "quay.io/rh-nfv-int/ubi8-base-testpmd:v0.0.1"
$ podman build ubi8-base-trex -f ubi8-base-trex/Dockerfile -t "quay.io/rh-nfv-int/ubi8-base-trex:v0.0.1"

# push images (to quay.io/rh-nfv-int)
$ podman push quay.io/rh-nfv-int/dpdk-23.11:v0.0.1
$ podman push quay.io/rh-nfv-int/ubi8-base-testpmd:v0.0.1
$ podman push quay.io/rh-nfv-int/ubi8-base-trex:v0.0.1
```

## Acknowledgements

Please write to telcoci@redhat.com in case you need more information for using and testing Example CNF in the scenarios that have been proposed in this repository.
